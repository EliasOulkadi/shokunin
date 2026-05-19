#!/usr/bin/env pwsh
#Requires -Version 5.1
<#
.SYNOPSIS
    Wrapper for opencode CLI with session tracking, checkpointing, buffer capture, and ChromaDB saving.
#>
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

$CHECKPOINT_INTERVAL_MS = 300000
$BUFFER_MAX_LINES = 9999
$BUFFER_READ_LINES = 5000
$REAL_OPENCODE = if (Get-Command opencode -CommandType Application -ErrorAction SilentlyContinue) { (Get-Command opencode -CommandType Application).Source } else { "opencode" }
$SHOKUNIN_DIR = "$env:USERPROFILE\.shokunin"
$LOG_DIR = "$SHOKUNIN_DIR\memory\sessions"
$HELPER_PY = "$SHOKUNIN_DIR\scripts\chroma-helper.py"
$READER_PS1 = "$SHOKUNIN_DIR\scripts\read-transcript.ps1"
$SESSION_FILE = "$SHOKUNIN_DIR\current-session.json"

function Get-Timestamp { Get-Date -Format 'yyyyMMdd-HHmmss' }
function Get-SessionId { "session-$(Get-Timestamp)-$(Get-Random -Minimum 1000 -Maximum 9999)" }
function Get-IsoTimestamp { Get-Date -Format 'yyyy-MM-dd HH:mm:ss' }
function Write-Done { Write-Host "  done" -ForegroundColor Green }

$sessionId = Get-SessionId
New-Item -ItemType Directory -Path $LOG_DIR -Force | Out-Null

$env:SHOKUNIN_SESSION_ID = $sessionId
$env:SHOKUNIN_PROJECT = (Get-Location).Path

$sessionInfo = @{ session_id = $sessionId; project = $env:SHOKUNIN_PROJECT; start_time = Get-IsoTimestamp; pid = $PID } | ConvertTo-Json
$sessionInfo | Out-File -FilePath $SESSION_FILE -Encoding UTF8 -Force

$mcpHealthy = $false
try {
    $mcpRequest = '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}'
    $mcpResponse = $mcpRequest | python "$SHOKUNIN_DIR\memory\mcp-server.py" 2>&1
    $mcpHealthy = $mcpResponse -match '"name"\s*:\s*"store_context"'
} catch {}
$env:SHOKUNIN_MCP_HEALTHY = if ($mcpHealthy) { "1" } else { "0" }

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Shokunin - Session: $sessionId" -ForegroundColor Cyan
if ($mcpHealthy) { Write-Host "  MCP Server: active" -ForegroundColor Green } else { Write-Host "  MCP Server: fallback mode" -ForegroundColor Yellow }
Write-Host "  Project: $($env:SHOKUNIN_PROJECT)" -ForegroundColor DarkGray
Write-Host "==========================================" -ForegroundColor Cyan

$oldBufferSize = $host.UI.RawUI.BufferSize
try {
    $newWidth = [Math]::Max($oldBufferSize.Width, 120)
    $host.UI.RawUI.BufferSize = New-Object System.Management.Automation.Host.Size($newWidth, $BUFFER_MAX_LINES)
} catch {
    Write-Host "  (buffer resize not supported)" -ForegroundColor DarkGray
}

$checkpointTimer = [System.Timers.Timer]::new($CHECKPOINT_INTERVAL_MS)
$checkpointTimer.AutoReset = $true
$capturedSessionId = $sessionId
$timerEvent = Register-ObjectEvent -InputObject $checkpointTimer -EventName Elapsed -Action {
    $ts = Get-IsoTimestamp
    $msg = "CHECKPOINT: Session $using:capturedSessionId active at $ts"
    try {
        python $HELPER_PY save "$msg" $using:capturedSessionId "checkpoint" "auto-checkpoint,system" "$(Get-Location)" 2>&1 | Out-Null
        "$(Get-Date -Format 'HH:mm:ss') CHECKPOINT saved" | Out-File -FilePath "$LOG_DIR\$using:capturedSessionId-checkpoints.log" -Append
    } catch {
        "$(Get-Date -Format 'HH:mm:ss') CHECKPOINT (md only)" | Out-File -FilePath "$LOG_DIR\$using:capturedSessionId-checkpoints.log" -Append
    }
}
$checkpointTimer.Start()

$startTime = Get-Date
Write-Host "  Starting opencode..." -ForegroundColor DarkGray

try {
    & $REAL_OPENCODE
} catch {
    Write-Host "  opencode exited with error: $_" -ForegroundColor Yellow
    try { & opencode.exe } catch { Write-Host "  Fallback also failed" -ForegroundColor Red }
}

$endTime = Get-Date
$duration = $endTime - $startTime

$checkpointTimer.Stop()
$checkpointTimer.Dispose()
Unregister-Event -SourceIdentifier $timerEvent.Name -ErrorAction SilentlyContinue

Write-Host "  Session ended ($($duration.ToString()))" -ForegroundColor DarkGray
Write-Host "  Saving context..." -ForegroundColor Cyan
Write-Host "    reading console buffer..." -NoNewline

$bufferText = ""
$bufferOk = $false

try {
    $cursor = $host.UI.RawUI.CursorPosition
    $bufW = $host.UI.RawUI.BufferSize.Width
    $bufH = $cursor.Y
    if ($bufH -gt 0 -and $bufW -gt 0) {
        $linesToRead = [Math]::Min($bufH, $BUFFER_READ_LINES)
        $startLine = [Math]::Max(0, $bufH - $linesToRead)
        $rect = New-Object System.Management.Automation.Host.Rectangle(0, $startLine, $bufW - 1, $bufH)
        $cells = $host.UI.RawUI.GetBufferContents($rect)
        if ($cells) {
            $rows = $cells.GetLength(0)
            $cols = $cells.GetLength(1)
            $lines = @()
            for ($y = 0; $y -lt $rows; $y++) {
                $line = ""
                for ($x = 0; $x -lt $cols; $x++) {
                    $line += $cells.GetValue($y, $x).Character
                }
                $lines += $line
            }
            $bufferText = $lines -join "`n"
            if ($bufferText.Length -gt 50) { $bufferOk = $true }
        }
    }
} catch {
    Write-Host "(not supported) " -NoNewline -ForegroundColor DarkGray
}

if (-not $bufferOk) {
    Write-Host "trying history fallback..." -NoNewline
    try {
        $history = Get-History -Count 500 -ErrorAction SilentlyContinue
        if ($history) {
            $lines = @()
            foreach ($cmd in $history) {
                $lines += "> $($cmd.CommandLine)"
                if ($cmd.ExecutionStatus -eq "Completed" -and $cmd.EndExecutionTime) {
                    $lines += "[done at $($cmd.EndExecutionTime.ToString('HH:mm:ss'))]"
                }
            }
            $bufferText = $lines -join "`n"
            if ($bufferText.Length -gt 50) { $bufferOk = $true }
        }
    } catch {}
}

if (-not $bufferOk) {
    try {
        $logFiles = Get-ChildItem "$LOG_DIR\$sessionId*.log" -ErrorAction SilentlyContinue
        if ($logFiles) {
            $bufferText = Get-Content $logFiles[0].FullName -Raw
            if ($bufferText.Length -gt 50) { $bufferOk = $true }
        }
    } catch {}
}

try { $host.UI.RawUI.BufferSize = $oldBufferSize } catch {}

if ($bufferOk) { Write-Done } else { Write-Host "  (no data captured)" -ForegroundColor Yellow }

$summaryText = "Session: $sessionId`nDuration: $($duration.ToString())`nDate: $(Get-IsoTimestamp)`nProject: $($env:SHOKUNIN_PROJECT)"

if ($bufferOk -and $bufferText.Length -gt 100) {
    Write-Host "    processing buffer..." -NoNewline
    try {
        $parsedMd = & $READER_PS1 -RawText $bufferText -SessionId $sessionId
        $summaryText = $parsedMd
        Write-Done
    } catch {
        $summaryText += "`n`n$bufferText"
        Write-Host "  (raw only)" -ForegroundColor DarkGray
    }
}

Write-Host "    saving raw log..." -NoNewline
try {
    $bufferText | Out-File -FilePath "$LOG_DIR\$sessionId.log" -Encoding UTF8
    Write-Done
} catch { Write-Host "  fail" -ForegroundColor Red }

Write-Host "    saving to ChromaDB..." -NoNewline
$chromaOk = $false
try {
    $result = python $HELPER_PY save "$summaryText" $sessionId "session_end" "auto-save,session-end" "$($env:SHOKUNIN_PROJECT)" 2>&1
    if ($result -match "stored") { $chromaOk = $true }
} catch {}

if ($chromaOk) {
    Write-Done
} else {
    Write-Host "fallback to file..." -NoNewline
    try {
        $summaryText | Out-File -FilePath "$LOG_DIR\$sessionId-summary.md" -Encoding UTF8
        Write-Host "done" -ForegroundColor Green
    } catch { Write-Host "fail" -ForegroundColor Red }
}

Write-Host "------------------------------------------" -ForegroundColor Cyan
Write-Host "  Session: $sessionId" -ForegroundColor DarkGray
Write-Host "  Duration: $($duration.ToString())" -ForegroundColor DarkGray
Write-Host "  Buffer: $(if ($bufferOk) { "$($bufferText.Length) chars" } else { 'no data' })" -ForegroundColor DarkGray
Write-Host "  ChromaDB: $(if ($chromaOk) { 'saved' } else { 'failed' })" -ForegroundColor $(if ($chromaOk) { 'Green' } else { 'Red' })
Write-Host "------------------------------------------" -ForegroundColor Cyan

$env:SHOKUNIN_LAST_SESSION = $sessionId
