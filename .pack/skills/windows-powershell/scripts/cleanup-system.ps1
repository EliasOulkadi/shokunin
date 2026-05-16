<#
.SYNOPSIS
  Cleans up Windows temporary files, caches, and reclaims disk space.
.DESCRIPTION
  Targets: temp files, recycle bin, Windows update cache, npm/yarn cache,
  Docker unused data, old Windows versions, prefetch.
  Shows space recovered per step.
.EXAMPLE
  .\cleanup-system.ps1
  .\cleanup-system.ps1 -DryRun
.PARAMETER DryRun
  Show what would be deleted without actually deleting.
#>

param(
  [switch]$DryRun
)

$ErrorActionPreference = 'Continue'
$totalRecovered = [long]0

function Write-Phase {
  param([string]$Title)
  Write-Host "`n" ("─" * 50) -ForegroundColor DarkGray
  Write-Host "  $Title" -ForegroundColor Cyan
  Write-Host ("─" * 50) -ForegroundColor DarkGray
}

function Export-Space {
  param([long]$Bytes)
  if ($Bytes -ge 1TB) { return '{0:N2} GB' -f ($Bytes / 1TB) }
  return '{0:N2} MB' -f ($Bytes / 1MB)
}

function Remove-WithSize {
  param(
    [string]$Path,
    [string]$Label
  )
  if (-not (Test-Path $Path)) {
    Write-Host "  $Label : not found" -ForegroundColor DarkGray
    return
  }
  $size = (Get-ChildItem $Path -Recurse -Force -ErrorAction SilentlyContinue |
    Measure-Object -Property Length -Sum).Sum
  $sizeStr = Export-Space $size
  Write-Host "  $Label : $sizeStr" -ForegroundColor Yellow
  if (-not $DryRun) {
    try {
      Remove-Item "$Path\*" -Recurse -Force -ErrorAction SilentlyContinue
      $totalRecovered += $size
      Write-Host "    → cleaned" -ForegroundColor Green
    } catch {
      Write-Host "    → error (files in use)" -ForegroundColor Red
    }
  } else {
    Write-Host "    → would remove $sizeStr" -ForegroundColor DarkGray
  }
}

Write-Host "╔══════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║        SYSTEM CLEANUP UTILITY                   ║" -ForegroundColor Cyan
Write-Host "║        $(if ($DryRun) {'DRY RUN'} else {'LIVE MODE'})                        ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════╝" -ForegroundColor Cyan

# 1. Windows Temp
Write-Phase "[1 / 7] Windows Temporary Files"
Remove-WithSize -Path "$env:TEMP" -Label "User Temp"

# 2. Windows Temp (system)
Remove-WithSize -Path "$env:SystemRoot\Temp" -Label "System Temp"

# 3. Recycle Bin
Write-Phase "[2 / 7] Recycle Bin"
if (-not $DryRun) {
  try {
    $rbSize = (Get-CimInstance Win32_LogicalDisk | ForEach-Object {
      $d = $_.DeviceID
      $s = (Get-CimInstance -ClassName Win32_Volume -Filter "DriveLetter='$d'" -ErrorAction SilentlyContinue |
        Select-Object -ExpandProperty Size -ErrorAction SilentlyContinue)
      if (-not $s) { $s = 0 }
      [long]$s
    } | Measure-Object -Sum).Sum
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
    Write-Host "  → recycled cleared" -ForegroundColor Green
  } catch {
    Write-Host "  → requires admin or nothing to clear" -ForegroundColor DarkGray
  }
} else {
  Write-Host "  → would empty Recycle Bin" -ForegroundColor DarkGray
}

# 4. Windows Update cache
Write-Phase "[3 / 7] Windows Update Cache"
$wuPath = "$env:SystemRoot\SoftwareDistribution\Download"
Remove-WithSize -Path $wuPath -Label "Update Cache"

# 5. npm / yarn / pnpm cache
Write-Phase "[4 / 7] npm / yarn / pnpm Cache"
Remove-WithSize -Path "$env:USERPROFILE\.npm" -Label "npm cache"
Remove-WithSize -Path "$env:LOCALAPPDATA\Yarn\Cache" -Label "Yarn cache"
Remove-WithSize -Path "$env:LOCALAPPDATA\pnpm\store" -Label "pnpm store"

# 6. Docker unused data
Write-Phase "[5 / 7] Docker Unused Data"
if (Get-Command 'docker' -ErrorAction SilentlyContinue) {
  if (-not $DryRun) {
    try {
      $output = docker system df --format '{{.Size}}' 2>$null
      $output = docker system prune -f 2>$null
      Write-Host "  → docker prune completed" -ForegroundColor Green
    } catch {
      Write-Host "  → docker not running" -ForegroundColor DarkGray
    }
  } else {
    Write-Host "  → would run docker system prune -f" -ForegroundColor DarkGray
  }
} else {
  Write-Host "  → Docker not installed" -ForegroundColor DarkGray
}

# 7. Old Windows versions (Windows.old)
Write-Phase "[6 / 7] Old Windows Versions"
$oldWin = "$env:SystemDrive\Windows.old"
if (Test-Path $oldWin) {
  $sizeOld = (Get-ChildItem $oldWin -Recurse -Force -ErrorAction SilentlyContinue |
    Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
  $sizeStr = Export-Space $sizeOld
  Write-Host "  Windows.old : $sizeStr" -ForegroundColor Yellow
  if (-not $DryRun) {
    try {
      # Uses DISM to remove Windows.old properly
      & dism /online /Remove-Package /PackagePath:$oldWin /Quiet /NoRestart 2>$null
      Write-Host "  → Windows.old removal initiated" -ForegroundColor Green
    } catch {
      Write-Host "  → requires admin elevation" -ForegroundColor Red
    }
  }
} else {
  Write-Host "  Windows.old : not found" -ForegroundColor DarkGray
}

# 8. Prefetch
Write-Phase "[7 / 7] Prefetch Cache"
Remove-WithSize -Path "$env:SystemRoot\Prefetch" -Label "Prefetch"

# Summary
Write-Phase "SUMMARY"
if ($DryRun) {
  Write-Host "  Dry run complete — no files were deleted." -ForegroundColor Yellow
} else {
  Write-Host "  Cleanup complete." -ForegroundColor Green
  Write-Host "  Estimated space recovered: $(Export-Space $totalRecovered)" -ForegroundColor Green
}

Write-Host "`n  Restart recommended for full effect." -ForegroundColor DarkGray
