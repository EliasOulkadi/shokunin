<#
.SYNOPSIS
  Template for scheduled PostgreSQL backup with retention policy.
  Designed to be registered in Windows Task Scheduler.
.DESCRIPTION
  Runs daily/weekly/monthly backup rotation:
  - Daily:    keep last 7
  - Weekly:   keep last 4 (Saturday)
  - Monthly:  keep last 3 (1st of month)
.NOTES
  Author: db-admin skill
  Schedule examples:
    Daily at 02:00:       schtasks /Create /SC DAILY /TN "PG-Backup-Daily" /TR "powershell.exe -File \"D:\scripts\backup-schedule-template.ps1\"" /ST 02:00 /RU SYSTEM
    Weekly (Sat 03:00):   schtasks /Create /SC WEEKLY /D SAT /TN "PG-Backup-Weekly" /TR "..." /ST 03:00 /RU SYSTEM
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$Database,

    [Parameter(Mandatory = $false)]
    [string]$Host = "localhost",

    [Parameter(Mandatory = $false)]
    [int]$Port = 5432,

    [Parameter(Mandatory = $false)]
    [string]$Username = "postgres",

    [Parameter(Mandatory = $false)]
    [string]$BackupRoot = "D:\Backups\$Database",

    [Parameter(Mandatory = $false)]
    [string]$PgDump = "C:\Program Files\PostgreSQL\16\bin\pg_dump.exe",

    [Parameter(Mandatory = $false)]
    [string]$Psql = "C:\Program Files\PostgreSQL\16\bin\psql.exe",

    # Retention counts
    [Parameter(Mandatory = $false)]
    [int]$KeepDaily = 7,

    [Parameter(Mandatory = $false)]
    [int]$KeepWeekly = 4,

    [Parameter(Mandatory = $false)]
    [int]$KeepMonthly = 3,

    [Parameter(Mandatory = $false)]
    [string]$PgPassword
)

$ErrorActionPreference = "Stop"

# --- Determine backup type ---
$today = Get-Date
$isSaturday = ($today.DayOfWeek -eq [DayOfWeek]::Saturday)
$isFirstOfMonth = ($today.Day -eq 1)

if ($isFirstOfMonth) {
    $backupType = "monthly"
}
elseif ($isSaturday) {
    $backupType = "weekly"
}
else {
    $backupType = "daily"
}

# --- Paths ---
$timestamp = $today.ToString("yyyyMMdd")
$typeDir = Join-Path -Path $BackupRoot -ChildPath $backupType
$backupDir = Join-Path -Path $typeDir -ChildPath $timestamp

# Ensure directory exists
$null = New-Item -ItemType Directory -Path $backupDir -Force

$backupFile = Join-Path -Path $backupDir -ChildPath "${Database}_${backupType}_${timestamp}.dump"
$logFile = Join-Path -Path $backupDir -ChildPath "${Database}_${backupType}_${timestamp}.log"

# --- Execute backup ---
$env:PGPASSWORD = $PgPassword
$dumpArgs = @(
    "--host=$Host"
    "--port=$Port"
    "--username=$Username"
    "--dbname=$Database"
    "--format=custom"
    "--compress=9"
    "--verbose"
    "--file=$backupFile"
)

Write-Host "[$timestamp] Starting $backupType backup of $Database to $backupFile"
$result = & $PgDump $dumpArgs 2>&1
$result | Out-File -FilePath $logFile -Encoding utf8

if ($LASTEXITCODE -ne 0) {
    Write-Error "[$timestamp] Backup FAILED — exit code $LASTEXITCODE. See $logFile"
    exit 1
}

$fileInfo = Get-Item -LiteralPath $backupFile
$sizeMB = [math]::Round($fileInfo.Length / 1MB, 2)
Write-Host "[$timestamp] Backup OK — ${sizeMB}MB written" -ForegroundColor Green

# --- Record backup metadata ---
$metaFile = Join-Path -Path $backupDir -ChildPath "${Database}_${backupType}_${timestamp}.meta"
@"
Database: $Database
Type: $backupType
Host: $Host`:$Port
Timestamp: $(Get-Date -Format "o")
File: $backupFile
SizeMB: $sizeMB
"@ | Out-File -FilePath $metaFile -Encoding utf8

# --- Retention cleanup ---

function Remove-OldBackups {
    param([string]$Type, [int]$Keep)
    $typePath = Join-Path -Path $BackupRoot -ChildPath $Type
    if (-not (Test-Path -LiteralPath $typePath)) { return }

    $existing = Get-ChildItem -LiteralPath $typePath -Directory |
        Where-Object { $_.Name -match '^\d{8}$' } |
        Sort-Object Name -Descending

    if ($existing.Count -le $Keep) { return }

    $toRemove = $existing | Select-Object -Skip $Keep
    foreach ($dir in $toRemove) {
        Write-Host "  Removing old $Type backup: $($dir.FullName)" -ForegroundColor DarkYellow
        Remove-Item -LiteralPath $dir.FullName -Recurse -Force
    }

    # Remove emptied parent if no subdirs
    $typeDirInfo = Get-Item -LiteralPath $typePath
    if ((Get-ChildItem -LiteralPath $typePath -Directory).Count -eq 0) {
        $typeDirInfo | Remove-Item -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "[$timestamp] Applying retention policy..."
Remove-OldBackups -Type "daily"   -Keep $KeepDaily
Remove-OldBackups -Type "weekly"  -Keep $KeepWeekly
Remove-OldBackups -Type "monthly" -Keep $KeepMonthly

# --- Optional: Verify most recent daily backup ---
$latestDaily = Get-ChildItem -LiteralPath (Join-Path -Path $BackupRoot -ChildPath "daily") -Directory |
    Sort-Object Name -Descending |
    Select-Object -First 1

if ($latestDaily) {
    $dumpToCheck = Get-ChildItem -LiteralPath $latestDaily.FullName -Filter "*.dump" | Select-Object -First 1
    if ($dumpToCheck) {
        Write-Host "[$timestamp] Verifying latest daily backup..." -ForegroundColor Yellow
        $listResult = & "$([System.IO.Path]::GetDirectoryName($PgDump))\pg_restore.exe" --list $dumpToCheck.FullName 2>$null
        if ($LASTEXITCODE -eq 0 -and $listResult) {
            $objCount = ($listResult | Select-String -Pattern "^[0-9]+; ").Count
            Write-Host "  Integrity check OK — $objCount objects in $($dumpToCheck.Name)" -ForegroundColor Green
        }
        else {
            Write-Warning "  Integrity check yielded no results (may be normal for empty DB)"
        }
    }
}

Write-Host "[$timestamp] Backup schedule complete" -ForegroundColor Cyan
exit 0
