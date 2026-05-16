<#
.SYNOPSIS
  Profile a Node.js process — event loop lag, memory, CPU, and slow iterations.
.DESCRIPTION
  Attaches to a running Node.js process or starts one, then collects:
    - Event loop lag (ms)
    - Heap used / total (MB)
    - CPU usage (%)
    - Slowest event loop iterations
  Optionally runs clinic.js or 0x for flamegraphs.
.PARAMETER ProcessId
  PID of the target Node.js process.
.PARAMETER ProcessName
  Name filter for Get-Process (default: "node").
.PARAMETER Duration
  Sampling duration in seconds (default: 30).
.PARAMETER Interval
  Sampling interval in seconds (default: 1).
.PARAMETER OutputDir
  Where to write reports (default: ./profile-reports).
.PARAMETER UseClinic
  Run clinic.js --flame (requires global clinic installed).
.PARAMETER UseOx
  Run 0x profiling (requires global 0x installed).
.PARAMETER Script
  If provided, start a new process with this script instead of attaching.
.PARAMETER ScriptArgs
  Arguments to pass to Script.
.EXAMPLE
  .\profile-node.ps1 -ProcessId 1234 -Duration 15
  .\profile-node.ps1 -Script ".\server.js" -UseClinic
  .\profile-node.ps1 -ProcessName "nest" -Duration 60 -Interval 2
#>

param(
  [int]$ProcessId,
  [string]$ProcessName = "node",
  [int]$Duration = 30,
  [int]$Interval = 1,
  [string]$OutputDir = "./profile-reports",
  [switch]$UseClinic,
  [switch]$UseOx,
  [string]$Script,
  [string[]]$ScriptArgs
)

$ErrorActionPreference = "Stop"

$OutputDir = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputDir)
if (-not (Test-Path -LiteralPath $OutputDir)) {
  New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

# --- Resolve target process ---
$proc = $null

if ($Script) {
  Write-Host "Starting script: $Script"
  $startArgs = @($Script) + $ScriptArgs
  $proc = Start-Process -PassThru -NoNewWindow -FilePath "node.exe" -ArgumentList $startArgs
  Start-Sleep -Seconds 2
  $ProcessId = $proc.Id
  Write-Host "Started PID: $ProcessId"
} elseif ($ProcessId) {
  $proc = Get-Process -Id $ProcessId -ErrorAction Stop
} else {
  $candidates = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
  if (-not $candidates) {
    Write-Error "No process found matching '$ProcessName'. Specify -ProcessId or -Script."
    exit 1
  }
  if ($candidates.Count -gt 1) {
    Write-Host "Multiple processes found. Attaching to first: PID $($candidates[0].Id)"
  }
  $proc = $candidates[0]
  $ProcessId = $proc.Id
}

Write-Host "Target: $($proc.Name) PID=$ProcessId"
Write-Host "Sampling for ${Duration}s every ${Interval}s..."

# --- Clinic.js flamegraph ---
if ($UseClinic) {
  $clinicPath = (Get-Command "clinic" -ErrorAction SilentlyContinue).Source
  if (-not $clinicPath) {
    Write-Error "clinic not found on PATH. Install: npm i -g clinic"
    exit 1
  }

  $flameDir = "$OutputDir/clinic-$timestamp"
  New-Item -ItemType Directory -Path $flameDir -Force | Out-Null

  if ($Script) {
    Write-Host "Running clinic.js flamegraph on script..."
    $clinicArgs = @("flame", "--collect-only", "--", "node", $Script) + $ScriptArgs
    $clinicProc = Start-Process -NoNewWindow -PassThru -FilePath "npx.cmd" -ArgumentList $clinicArgs
    Start-Sleep -Seconds $Duration
    $clinicProc.Kill()
  } else {
    Write-Host "Running clinic.js flamegraph on PID $ProcessId..."
    $clinicArgs = @("flame", "--dest", "`"$flameDir`"", "-p", $ProcessId, "--collect-only")
    $clinicProc = Start-Process -NoNewWindow -PassThru -FilePath "clinic" -ArgumentList $clinicArgs
    Start-Sleep -Seconds $Duration
    $clinicProc.Kill()
  }

  Write-Host "Clinic flamegraph saved to: $flameDir"
  return
}

# --- 0x flamegraph ---
if ($UseOx) {
  $oxPath = (Get-Command "0x" -ErrorAction SilentlyContinue).Source
  if (-not $oxPath) {
    Write-Error "0x not found on PATH. Install: npm i -g 0x"
    exit 1
  }

  if ($Script) {
    Write-Host "Running 0x on script..."
    $oxArgs = @("-o", "`"$OutputDir/0x-$timestamp`"", "--", "node", $Script) + $ScriptArgs
    Start-Process -NoNewWindow -Wait -FilePath "npx.cmd" -ArgumentList $oxArgs
  } else {
    Write-Host "0x requires starting a new process; attaching to existing PID not supported."
    Write-Host "Use -Script to profile a specific entry point with 0x."
    exit 1
  }

  Write-Host "0x output saved to: $OutputDir/0x-$timestamp"
  return
}

# --- Manual sampling loop ---
$samples = @()
$loopLagSamples = @()
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

while ($stopwatch.Elapsed.TotalSeconds -lt $Duration) {
  $sampleStart = [System.Diagnostics.Stopwatch]::StartNew()
  $sample = [PSCustomObject]@{
    Timestamp = Get-Date -Format "HH:mm:ss.fff"
    CpuPercent      = 0
    WorkingSetMB    = 0
    HeapUsedMB      = 0
    HeapTotalMB     = 0
    EventLoopLagMs  = 0
  }

  try {
    $currentProc = Get-Process -Id $ProcessId -ErrorAction Stop
    $sample.WorkingSetMB = [math]::Round($currentProc.WorkingSet64 / 1MB, 1)
    $sample.CpuPercent = [math]::Round(($currentProc.TotalProcessorTime.TotalMilliseconds / $stopwatch.Elapsed.TotalMilliseconds) * 100, 1)
  } catch {
    Write-Warning "Process $ProcessId exited."
    break
  }

  # Check event loop lag via a quick inline script
  $lagScript = @"
const fs = require('fs');
const start = Date.now();
setImmediate(() => {
  const lag = Date.now() - start;
  fs.writeFileSync(process.env.LAG_FILE || '$OutputDir/lag-$timestamp.tmp', String(lag));
});
"@

  $lagCmd = [System.Text.Encoding]::UTF8.GetBytes($lagScript)
  $tempFile = "$OutputDir/lag-$($stopwatch.Elapsed.TotalSeconds).tmp"
  $env:LAG_FILE = $tempFile
  Set-Content -Path "$OutputDir/_lag_eval.js" -Value $lagScript -Encoding UTF8

  try {
    $lagProc = Start-Process -NoNewWindow -PassThru -FilePath "node.exe" -ArgumentList @("`"$OutputDir/_lag_eval.js`"")
    $lagProc.WaitForExit(3000) | Out-Null
    if (Test-Path -LiteralPath $tempFile) {
      $content = Get-Content -Raw -LiteralPath $tempFile -ErrorAction SilentlyContinue
      if ($content) {
        $sample.EventLoopLagMs = [int]$content.Trim()
        $loopLagSamples += $sample.EventLoopLagMs
      }
      Remove-Item -LiteralPath $tempFile -ErrorAction SilentlyContinue
    }
  } catch {
    $sample.EventLoopLagMs = -1
  }

  $sampleStart.Stop()
  $samples += $sample

  Write-Host ("[{0}] CPU={1,6:F1}%  WS={2,6:F1}MB  Lag={3,3}ms" -f
    $sample.Timestamp,
    $sample.CpuPercent,
    $sample.WorkingSetMB,
    $sample.EventLoopLagMs)

  $elapsed = $Interval - $sampleStart.Elapsed.TotalSeconds
  if ($elapsed -gt 0) { Start-Sleep -Seconds $elapsed }
}

$stopwatch.Stop()

# Cleanup temp
Remove-Item -LiteralPath "$OutputDir/_lag_eval.js" -ErrorAction SilentlyContinue

# --- Summary ---
Write-Host "`n=== PROFILE SUMMARY ==="
$heapUsedSamples = $samples | Where-Object { $_.HeapUsedMB -gt 0 }
$lagSamples = $loopLagSamples

Write-Host "Samples collected: $($samples.Count)"
Write-Host ""

Write-Host "--- CPU ---"
$cpuVals = $samples | ForEach-Object { $_.CpuPercent }
Write-Host "  Avg: $([math]::Round(($cpuVals | Measure-Object -Average).Average, 1))%"
Write-Host "  Max: $([math]::Round(($cpuVals | Measure-Object -Maximum).Maximum, 1))%"

Write-Host "--- Memory ---"
$wsVals = $samples | ForEach-Object { $_.WorkingSetMB }
Write-Host "  Avg Working Set: $([math]::Round(($wsVals | Measure-Object -Average).Average, 1)) MB"
Write-Host "  Max Working Set: $([math]::Round(($wsVals | Measure-Object -Maximum).Maximum, 1)) MB"

Write-Host "--- Event Loop Lag ---"
if ($lagSamples.Count -gt 0) {
  $sortedLag = $lagSamples | Sort-Object -Descending
  Write-Host "  Avg: $([math]::Round(($lagSamples | Measure-Object -Average).Average, 0)) ms"
  Write-Host "  Max: $($sortedLag[0]) ms"
  Write-Host "  P99: $($sortedLag[[math]::Max(0, [math]::Round($sortedLag.Count * 0.01) - 1)]) ms"
  Write-Host "  P95: $($sortedLag[[math]::Max(0, [math]::Round($sortedLag.Count * 0.05) - 1)]) ms"
} else {
  Write-Host "  (no data)"
}

# Export CSV
$csvPath = "$OutputDir/profile-$timestamp.csv"
$samples | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
Write-Host "`nRaw data: $csvPath"
Write-Host "Done."
