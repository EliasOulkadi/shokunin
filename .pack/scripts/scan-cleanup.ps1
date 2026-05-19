<#
.SYNOPSIS
    Scans Downloads, Desktop, and Temp for files to classify (keep/review/trash) and optionally move to Recycle Bin.
#>
param(
    [CmdletBinding()]
    [switch]$Scan,
    [string[]]$Clean,
    [string]$LogDir = "$env:USERPROFILE\.shokunin\logs"
)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

New-Item -ItemType Directory -Path $LogDir -Force | Out-Null

function Get-FileInfo {
    param([string]$Path)
    try {
        $item = Get-Item -LiteralPath $Path -ErrorAction Stop
        $now = Get-Date
        $result = New-Object PSObject
        $result | Add-Member NoteProperty Name $item.Name
        $result | Add-Member NoteProperty FullName $item.FullName
        $result | Add-Member NoteProperty Extension $item.Extension
        $result | Add-Member NoteProperty SizeKB ([math]::Round($item.Length / 1KB, 1))
        $result | Add-Member NoteProperty SizeMB ([math]::Round($item.Length / 1MB, 2))
        $result | Add-Member NoteProperty Created ($item.CreationTime.ToString("yyyy-MM-dd"))
        $result | Add-Member NoteProperty Modified ($item.LastWriteTime.ToString("yyyy-MM-dd"))
        $result | Add-Member NoteProperty LastAccess ($item.LastAccessTime.ToString("yyyy-MM-dd"))
        $result | Add-Member NoteProperty DaysSinceModified ([math]::Round(($now - $item.LastWriteTime).TotalDays))
        $result | Add-Member NoteProperty DaysSinceAccess ([math]::Round(($now - $item.LastAccessTime).TotalDays))
        $result | Add-Member NoteProperty Directory $item.Directory.Name
        $result | Add-Member NoteProperty IsPdf ($item.Extension -eq ".pdf")
        return $result
    } catch { return $null }
}

function Scan-Directory {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return @() }
    $results = @()
    try {
        $items = Get-ChildItem -Path $Path -File -ErrorAction SilentlyContinue
        foreach ($item in $items) {
            $info = Get-FileInfo -Path $item.FullName
            if ($info) { $results += $info }
        }
    } catch {}
    return $results
}

function Classify-File {
    param($Info)
    $name = $Info.Name.ToLower()
    $ext = $Info.Extension.ToLower()

    if ($Info.FullName -match "(memory|chroma_db|sessions)\\") { return @("protect","KEEP","Protected path") }

    $isAiPdf = $false
    if ($Info.IsPdf) {
        $patterns = @("shokunin","kami","changelog","ecosystem","quickstart","v4.")
        foreach ($p in $patterns) { if ($name -match $p) { $isAiPdf = $true; break } }
    }
    $isInstaller = @(".exe",".msi",".dmg",".AppImage",".deb",".rpm") -contains $ext
    $isArchive = @(".zip",".rar",".7z",".tar.gz",".tar",".gz") -contains $ext

    if ($isAiPdf) {
        if ($Info.DaysSinceModified -le 1) { return @("review","REVIEW","AI-generated, recent") }
        return @("safe","TRASH","AI-generated, on GitHub")
    }
    if ($isInstaller) {
        if ($Info.DaysSinceModified -gt 30) { return @("safe","TRASH","Outdated installer") }
        return @("review","REVIEW","Recent installer")
    }
    if ($isArchive) {
        if ($Info.DaysSinceModified -gt 60) { return @("safe","TRASH","Old compressed file") }
        return @("review","REVIEW","Recent compressed file")
    }
    if ($Info.Directory -eq (Split-Path -Leaf ([Environment]::GetFolderPath('Desktop')))) {
        if ($Info.DaysSinceModified -gt 30) { return @("review","REVIEW","Loose file on Desktop") }
        return @("keep","KEEP","On Desktop, recent")
    }
    if ($Info.FullName -match "\\Temp\\") {
        if ($Info.DaysSinceModified -gt 7) { return @("safe","TRASH","Old temp file") }
        return @("review","REVIEW","Recent temp file")
    }
    if ($Info.DaysSinceModified -le 3) { return @("keep","KEEP","Recent") }
    return @("review","REVIEW","Unclassified")
}

function Write-Report {
    param($Groups)
    $g = [System.Char]::ConvertFromUtf32(0x1F7E2); $y = [System.Char]::ConvertFromUtf32(0x1F7E1); $r = [System.Char]::ConvertFromUtf32(0x1F534)
    if ($Groups.Keys.Count -eq 0) { Write-Host "Nothing to clean." -ForegroundColor Green; return }

    Write-Host "Scanning $env:USERPROFILE..." -ForegroundColor Cyan
    foreach ($dir in ($Groups.Keys | Sort-Object)) {
        $files = $Groups[$dir]
        if ($files.Count -eq 0) { continue }
        Write-Host ""
        Write-Host "--- $dir ($($files.Count) files) ---" -ForegroundColor Yellow
        foreach ($f in $files) {
            $verdict = Classify-File -Info $f
            $v = $verdict[0]
            $emoji = if ($v -eq "safe") { $g } elseif ($v -eq "review") { $y } elseif ($v -eq "keep") { $r } else { $r }
            $color = if ($v -eq "safe") { "Green" } elseif ($v -eq "review") { "Yellow" } elseif ($v -eq "keep") { "Red" } else { "White" }
            $size = if ($f.SizeKB -gt 1024) { "$($f.SizeMB) MB" } else { "$($f.SizeKB) KB" }
            $date = $f.Modified.Substring(5)
            Write-Host "  -> $($f.Name) ($date, $size) -> $($verdict[2]) $emoji $($verdict[1])" -ForegroundColor $color
        }
    }
    Write-Host ""
    Write-Host "--- END ---" -ForegroundColor Cyan
}

function Do-Cleanup {
    param($Ids)
    $logFile = "$LogDir/cleanup.log"
    $moved = 0
    $totalBytes = 0
    $header = "=== CLEANUP $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ==="
    Add-Content -Path $logFile -Value $header

    Add-Type -AssemblyName Microsoft.VisualBasic
    $allowedDirs = @(
        [Environment]::GetFolderPath('Desktop'),
        (Join-Path $env:USERPROFILE "Downloads"),
        $env:TEMP,
        (Join-Path $env:USERPROFILE ".shokunin\docs")
    ) | Where-Object { $_ }

    foreach ($id in $Ids) {
        $parts = $id -split "\|"
        $path = $parts[0]
        $reason = if ($parts.Count -gt 1) { $parts[1] } else { "User request" }

        if (-not (Test-Path $path)) { continue }

        $resolved = (Get-Item -LiteralPath $path).FullName
        $isAllowed = $false
        foreach ($allowed in $allowedDirs) {
            $resolvedAllowed = (Get-Item -LiteralPath $allowed -ErrorAction SilentlyContinue).FullName
            if ($resolvedAllowed -and $resolved.StartsWith($resolvedAllowed, [System.StringComparison]::OrdinalIgnoreCase)) {
                $isAllowed = $true
                break
            }
        }
        if (-not $isAllowed) {
            Write-Host "  SKIPPED $($path) - outside allowed directories" -ForegroundColor Yellow
            continue
        }

        try {
            $item = Get-Item -LiteralPath $path
            [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($path, "OnlyErrorDialogs", "SendToRecycleBin")
            $entry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | MOVED | $path | $($item.Length) | $reason"
            Add-Content -Path $logFile -Value $entry
            $moved = $moved + 1
            $totalBytes = $totalBytes + $item.Length
            Write-Host "  Moved $($item.Name)" -ForegroundColor Green
        } catch {
            $entry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | FAILED | $path | $_"
            Add-Content -Path $logFile -Value $entry
            Write-Host "  Failed $path - $_" -ForegroundColor Red
        }
    }
    $totalMB = [math]::Round($totalBytes / 1MB, 1)
    $footer = "=== END: $moved files, $totalMB MB ==="
    Add-Content -Path $logFile -Value $footer
    Write-Host "Done: $moved files to Recycle Bin ($totalMB MB)" -ForegroundColor Green
    Write-Host "Log: $logFile" -ForegroundColor DarkGray
}

if ($Scan) {
    $groups = @{}
    $targets = @{
        "DESKTOP" = [Environment]::GetFolderPath('Desktop')
        "DOWNLOADS" = Join-Path $env:USERPROFILE "Downloads"
    }
    $tempTarget = "$env:TEMP"
    if (Test-Path $tempTarget) { $targets["TEMP"] = $tempTarget }
    $docsTarget = "$env:USERPROFILE\.shokunin\docs"
    if (Test-Path $docsTarget) { $targets["SHOKUNIN_DOCS"] = $docsTarget }

    foreach ($label in $targets.Keys) {
        $files = Scan-Directory -Path $targets[$label]
        if ($files.Count -gt 0) { $groups[$label] = $files }
    }

    Write-Report -Groups $groups
    return
}

if ($Clean.Count -gt 0) {
    Do-Cleanup -Ids $Clean
    return
}

Write-Host "Usage: scan-cleanup.ps1 -Scan | -Clean id1,id2,..." -ForegroundColor Yellow

