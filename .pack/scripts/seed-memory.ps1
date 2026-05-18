<#
.SYNOPSIS
    Imports session markdown files from disk into ChromaDB for the first time.
#>
param(
    [CmdletBinding()]
    [switch]$Force
)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$HELPER = "$env:USERPROFILE\.shokunin\scripts\chroma-helper.py"
$SESSIONS = "$env:USERPROFILE\.shokunin\memory\sessions"
$IMPORTED = 0; $SKIPPED = 0

if (-not (Test-Path $SESSIONS)) { Write-Host "No sessions directory found." -ForegroundColor Yellow; return }

$mdFiles = Get-ChildItem "$SESSIONS\*.md" -ErrorAction SilentlyContinue
if ($mdFiles.Count -eq 0) { Write-Host "No session markdown files to import." -ForegroundColor Yellow; return }

foreach ($file in $mdFiles) {
    $sessionId = $file.BaseName
    $content = Get-Content $file.FullName -Raw

    if ([string]::IsNullOrWhiteSpace($content)) { $SKIPPED++; continue }

    # Check if already in ChromaDB (skip unless -Force)
    if (-not $Force) {
        $existing = python $HELPER search "$sessionId" "" 1 2>$null
        if ($existing -and $existing -match $sessionId) { $SKIPPED++; continue }
    }

    try {
        $firstLine = ($content -split "`n" | Where-Object { $_.Trim() -ne "" } | Select-Object -First 1).Trim()
        $result = python $HELPER save "$firstLine`n`n$content" $sessionId "session_seed" "imported,seeded" "shokunin" 2>$null
        if ($result -match "stored") { $IMPORTED++ } else { $SKIPPED++ }
    } catch { $SKIPPED++ }
}

Write-Host "Memory updated: $IMPORTED imported, $SKIPPED skipped" -ForegroundColor $(if($IMPORTED -gt 0){'Green'}else{'Yellow'})
