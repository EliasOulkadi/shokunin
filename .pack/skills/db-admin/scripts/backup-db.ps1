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
    [string]$OutputDir = ".\backups",

    [Parameter(Mandatory = $false)]
    [string[]]$ExcludeTables,

    [Parameter(Mandatory = $false)]
    [int]$CompressionLevel = 9,

    [Parameter(Mandatory = $false)]
    [string]$PgDumpPath = "C:\Program Files\PostgreSQL\16\bin\pg_dump.exe",

    [Parameter(Mandatory = $false)]
    [string]$PsqlPath = "C:\Program Files\PostgreSQL\16\bin\psql.exe",

    [Parameter(Mandatory = $false)]
    [string]$PgRestorePath = "C:\Program Files\PostgreSQL\16\bin\pg_restore.exe",

    [Parameter(Mandatory = $false)]
    [switch]$SkipVerification
)

$ErrorActionPreference = "Stop"
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupDir = Resolve-Path -Path $OutputDir -ErrorAction SilentlyContinue
if (-not $backupDir) {
    $backupDir = New-Item -ItemType Directory -Path $OutputDir -Force | Select-Object -ExpandProperty FullName
}

$backupFile = Join-Path -Path $backupDir -ChildPath "$Database`_$timestamp.dump"
$logFile = Join-Path -Path $backupDir -ChildPath "$Database`_$timestamp.log"

$env:PGPASSWORD = $null

$excludeArgs = @()
if ($ExcludeTables -and $ExcludeTables.Count -gt 0) {
    $ExcludeTables | ForEach-Object { $excludeArgs += "--exclude-table=$_" }
}

try {
    $secPwd = Read-Host -Prompt "Enter PostgreSQL password for $Username" -AsSecureString
    $credential = New-Object System.Management.Automation.PSCredential($Username, $secPwd)
    $plainPwd = $credential.GetNetworkCredential().Password
    $env:PGPASSWORD = $plainPwd

    Write-Host "[$timestamp] Starting backup of $Database on $Host`:$Port" -ForegroundColor Cyan

    $dumpArgs = @(
        "--host=$Host"
        "--port=$Port"
        "--username=$Username"
        "--dbname=$Database"
        "--format=custom"
        "--compress=$CompressionLevel"
        "--verbose"
        "--no-owner"
        "--no-privileges"
    ) + $excludeArgs

    $dumpResult = & $PgDumpPath $dumpArgs --file=$backupFile 2>&1
    $dumpResult | Out-File -FilePath $logFile -Encoding utf8

    if ($LASTEXITCODE -ne 0) {
        throw "pg_dump failed with exit code $LASTEXITCODE. Check log: $logFile"
    }

    $fileInfo = Get-Item -LiteralPath $backupFile
    $sizeMB = [math]::Round($fileInfo.Length / 1MB, 2)
    Write-Host "Backup written: $backupFile ($sizeMB MB)" -ForegroundColor Green

    if (-not $SkipVerification) {
        Write-Host "Verifying backup integrity..." -ForegroundColor Yellow
        $verifyDb = "verify_$($Database)_$timestamp"

        try {
            # Create temp DB on same server for verification
            & $PsqlPath --host=$Host --port=$Port --username=$Username --dbname="postgres" --command="CREATE DATABASE `"$verifyDb`";" 2>&1 | Out-Null

            # Restore to temp DB (data-only, no blobs initially)
            $restoreArgs = @(
                "--host=$Host"
                "--port=$Port"
                "--username=$Username"
                "--dbname=$verifyDb"
                "--format=custom"
                "--verbose"
                "--exit-on-error"
                "--no-owner"
                "--no-privileges"
            )
            $restoreResult = & $PgRestorePath $restoreArgs $backupFile 2>&1
            $restoreResult | Out-File -FilePath "$logFile.restore" -Encoding utf8

            if ($LASTEXITCODE -ne 0) {
                throw "pg_restore verification failed with exit code $LASTEXITCODE"
            }

            # Run check query to validate data
            $checkQuery = @"
SELECT COUNT(*)::text AS total_tables
FROM information_schema.tables
WHERE table_schema NOT IN ('pg_catalog', 'information_schema');
"@
            $checkResult = & $PsqlPath --host=$Host --port=$Port --username=$Username --dbname=$verifyDb --tuples-only --command=$checkQuery 2>&1
            $checkResult = $checkResult.Trim()

            if ($LASTEXITCODE -eq 0 -and $checkResult -match '^\d+$') {
                Write-Host "Verification OK — $checkResult tables restored successfully" -ForegroundColor Green
            } else {
                Write-Warning "Verification warning — restore completed but check query returned: $checkResult"
            }
        }
        finally {
            # Cleanup temp DB
            & $PsqlPath --host=$Host --port=$Port --username=$Username --dbname="postgres" --command="SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$verifyDb' AND pid <> pg_backend_pid();" 2>&1 | Out-Null
            & $PsqlPath --host=$Host --port=$Port --username=$Username --dbname="postgres" --command="DROP DATABASE IF EXISTS `"$verifyDb`";" 2>&1 | Out-Null
        }
    }
}
catch {
    Write-Error "Backup failed: $_"
    if (Test-Path -LiteralPath $backupFile) {
        Remove-Item -LiteralPath $backupFile -Force
    }
    exit 1
}
finally {
    # Clear password from environment
    $env:PGPASSWORD = $null
}

Write-Host "[$(Get-Date -Format 'yyyyMMdd_HHmmss')] Backup completed successfully" -ForegroundColor Cyan
exit 0
