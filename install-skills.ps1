# Shokunin Skills-Only Installer v4.2.2
# Installs only the 62 skills without the full ecosystem
# Use when you already have OpenCode + ChromaDB but want updated skills
# Run: irm https://raw.githubusercontent.com/EliasOulkadi/shokunin/master/install-skills.ps1 | iex

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$script:sourceDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$script:skillsDir = "$env:USERPROFILE\.config\opencode\skills"
$script:targets = @($script:skillsDir)

if (Test-Path "$env:USERPROFILE\.agents\skills") {
    $script:targets += "$env:USERPROFILE\.agents\skills"
}

Write-Host "`n  Shokunin Skills Installer v4.2.2" -ForegroundColor Cyan
Write-Host "  62 skills across 10 domains" -ForegroundColor DarkGray
Write-Host ""

$repoSkills = Join-Path $script:sourceDir ".pack\skills"
$count = 0
$sourceExists = Test-Path $repoSkills

if (-not $sourceExists) {
    Write-Host "  Downloading skills from GitHub..." -ForegroundColor Yellow
    $tmpDir = "$env:TEMP\shokunin-skills"
    Remove-Item -Recurse -Force $tmpDir -ErrorAction SilentlyContinue
    git clone --depth 1 https://github.com/EliasOulkadi/shokunin.git $tmpDir 2>&1 | Out-Null
    $repoSkills = "$tmpDir\.pack\skills"
}

foreach ($targetDir in $script:targets) {
    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }
}

Get-ChildItem $repoSkills -Directory | Where-Object { Test-Path (Join-Path $_.FullName "SKILL.md") } | ForEach-Object {
    foreach ($targetDir in $script:targets) {
        $target = Join-Path $targetDir $_.Name
        if (-not (Test-Path $target)) {
            New-Item -ItemType Directory -Path $target -Force | Out-Null
        }
        Copy-Item -Recurse -Force "$($_.FullName)\*" "$target\" -ErrorAction SilentlyContinue
    }
    $count++
}

if (-not $sourceExists) {
    Remove-Item -Recurse -Force $tmpDir -ErrorAction SilentlyContinue
}

Write-Host "  $count skills installed" -ForegroundColor Green
Write-Host "  Target: $($script:targets -join ', ')" -ForegroundColor DarkGray
Write-Host ""
