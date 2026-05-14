#!/usr/bin/env pwsh
param()

function Get-Timestamp { Get-Date -Format 'yyyyMMdd-HHmmss' }
function Get-SessionId { "session-$(Get-Timestamp)-$(Get-Random -Minimum 1000 -Maximum 9999)" }

$sessionId = Get-SessionId
$logDir = "$env:USERPROFILE\.shokunin\memory\sessions"
$helperPy = "$env:USERPROFILE\.shokunin\scripts\chroma-helper.py"
$readerPs1 = "$env:USERPROFILE\.shokunin\scripts\read-transcript.ps1"

New-Item -ItemType Directory -Path $logDir -Force | Out-Null

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Shokunin - Session: $sessionId" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

$oldBufferSize = $host.UI.RawUI.BufferSize
try {
    $newWidth = [Math]::Max($oldBufferSize.Width, 120)
    $host.UI.RawUI.BufferSize = New-Object System.Management.Automation.Host.Size($newWidth, 9999)
} catch {}

$startTime = Get-Date
opencode
$endTime = Get-Date
$duration = $endTime - $startTime

Write-Host "`n==========================================" -ForegroundColor Cyan
Write-Host "  Saving session context..." -ForegroundColor Cyan

# Read console buffer
$bufferText = ""
try {
    $cursor = $host.UI.RawUI.CursorPosition
    $bufW = $host.UI.RawUI.BufferSize.Width
    $bufH = $cursor.Y
    if ($bufH -gt 0 -and $bufW -gt 0) {
        $linesToRead = [Math]::Min($bufH, 5000)
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
        }
    }
} catch {}

# Restore buffer
try { $host.UI.RawUI.BufferSize = $oldBufferSize } catch {}

# Build summary
$summaryText = @"
Session: $sessionId
Duration: $($duration.ToString())
Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Project: $(Get-Location)
"@

if ($bufferText.Length -gt 100) {
    try {
        $parsedMd = & $readerPs1 -RawText $bufferText -SessionId $sessionId
        $summaryText = $parsedMd
    } catch {
        $summaryText += "`n`n$bufferText"
    }
}

# Save raw log
$bufferText | Out-File -FilePath "$logDir\$sessionId.log" -Encoding UTF8

# Save to ChromaDB
try {
    $result = python $helperPy save "$summaryText" $sessionId "session_end" "auto-save,session-end" "$(Get-Location)" 2>$null
    $result | Out-Null
    Write-Host "  Memory saved (ChromaDB + md)" -ForegroundColor Green
} catch {
    $textFile = "$logDir\$sessionId-summary.md"
    $summaryText | Out-File -FilePath $textFile -Encoding UTF8
    Write-Host "  Saved to: $textFile" -ForegroundColor Yellow
}

Write-Host "  Duration: $($duration.ToString())" -ForegroundColor DarkGray
Write-Host "  Session ID: $sessionId" -ForegroundColor DarkGray
Write-Host "==========================================" -ForegroundColor Cyan

$env:SHOKUNIN_LAST_SESSION = $sessionId
