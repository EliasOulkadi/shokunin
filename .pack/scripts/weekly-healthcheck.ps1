# Tarea semanal: Sunday Health Check
# Corre cada domingo a las 21:00 via Task Scheduler

Write-Host "=== Shokunin Sunday Health Check ===" -ForegroundColor Cyan
$date = Get-Date -Format "yyyy-MM-dd HH:mm"

# 1. Check disk space
$disks = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -gt 0 }
Write-Host "`n[STORAGE]" -ForegroundColor Yellow
foreach ($d in $disks) {
    $pct = [math]::Round($d.Used / $d.Used * 100 / ($d.Used / $d.Used), 0)
    $freeGB = [math]::Round($d.Free / 1GB, 1)
    $totalGB = [math]::Round(($d.Used + $d.Free) / 1GB, 1)
    Write-Host "  $($d.Name) $freeGB GB free / $totalGB GB total"
    if ($freeGB -lt 10) { Write-Host "    ⚠️ Low disk space!" -ForegroundColor Red }
}

# 2. Memory backup
$memDir = "$env:USERPROFILE\.shokunin\memory"
$backupDir = "$env:USERPROFILE\.shokunin\backups"
if (Test-Path $memDir) {
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    $dateStr = Get-Date -Format "yyyy-MM-dd"
    $zip = "$backupDir\memory-$dateStr.zip"
    if (!(Test-Path $zip)) {
        Compress-Archive -Path $memDir -DestinationPath $zip -Force
        Write-Host "`n[MEMORY] Backup: $zip" -ForegroundColor Yellow
    } else {
        Write-Host "`n[MEMORY] Backup already exists for today" -ForegroundColor Green
    }
}

# 3. Check memory size
if (Test-Path "$memDir\chroma_db") {
    $size = (Get-ChildItem -Recurse "$memDir\chroma_db" | Measure-Object -Property Length -Sum).Sum
    Write-Host "  ChromaDB size: $([math]::Round($size/1KB, 1)) KB" -ForegroundColor Green
}

# 4. Check skills count
$skillsCount = (Get-ChildItem "$env:USERPROFILE\.config\opencode\skills" -Directory).Count
Write-Host "`n[SKILLS] $skillsCount installed" -ForegroundColor Yellow

# 5. Check OpenCode config
if (Test-Path "$env:USERPROFILE\.config\opencode\opencode.json") {
    Write-Host "[OPENCODE] Config OK" -ForegroundColor Green
}

# 6. Check Telegram bot status
$startupFolder = [Environment]::GetFolderPath('Startup')
if (Test-Path "$startupFolder\ShokuninBot.lnk") {
    Write-Host "[TELEGRAM] Bot startup shortcut OK" -ForegroundColor Green
}

Write-Host "`n=== Health check complete: $date ===" -ForegroundColor Cyan

# Log to file
$logDir = "$env:USERPROFILE\.shokunin\logs"
New-Item -ItemType Directory -Path $logDir -Force | Out-Null
$log = Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$logDir\healthcheck.log" -Append
