<#
.SYNOPSIS
    Validates all installed skills for required sections, size, and referenced script existence.
#>
param(
    [CmdletBinding()]
    [switch]$CI
)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$SKILLS_DIR = "$env:USERPROFILE\.config\opencode\skills"
$BASE_DIR = "$env:USERPROFILE\AppData\Local\Temp\opencode\shokunin"
$PASS = 0; $FAIL = 0; $WARN = 0

function Check($Name, $ScriptBlock) {
    try { & $ScriptBlock; Write-Host "  PASS $Name" -ForegroundColor Green; $script:PASS++ }
    catch { Write-Host "  FAIL $Name : $_" -ForegroundColor Red; $script:FAIL++ }
}

function Warn($Name, $Msg) { Write-Host "  WARN $Name : $Msg" -ForegroundColor Yellow; $script:WARN++ }

# Scan both locations
$skillDirs = @()
if (Test-Path $SKILLS_DIR) { $skillDirs += Get-ChildItem $SKILLS_DIR -Directory | Where-Object { Test-Path (Join-Path $_.FullName "SKILL.md") } }
if (Test-Path $BASE_DIR) { $skillDirs += Get-ChildItem $BASE_DIR -Directory | Where-Object { Test-Path (Join-Path $_.FullName "SKILL.md") } }
$skillDirs = $skillDirs | Sort-Object Name -Unique

Write-Host ""
Write-Host "Skills Validation - $($skillDirs.Count) skills" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Check 1: Required sections
Write-Host "`n[Required sections]" -ForegroundColor Yellow
foreach ($d in $skillDirs) {
    $content = Get-Content "$($d.FullName)\SKILL.md" -Raw
    Check "$($d.Name) has YAML frontmatter" { if ($content -notmatch "^---") { throw "missing frontmatter" } }
    Check "$($d.Name) has description" { if ($content -notmatch "description:") { throw "missing description" } }
    Check "$($d.Name) has workflow" { if ($content -notmatch "## Workflow|## Procedural Workflow|## The Structure") { throw "missing workflow" } }
    Check "$($d.Name) has error handling" { if ($content -notmatch "## Error") { throw "missing error handling" } }
    Check "$($d.Name) has sources" { if ($content -notmatch "## Sources|## Fuentes") { throw "missing sources" } }
}

# Check 2: Line count min
Write-Host "`n[Size check]" -ForegroundColor Yellow
foreach ($d in $skillDirs) {
    $lines = (Get-Content "$($d.FullName)\SKILL.md").Count
    if ($lines -lt 50) { Warn "$($d.Name)" "only $lines lines (min 50 recommended)" }
}

# Check 3: Referenced scripts exist
Write-Host "`n[Scripts referenced]" -ForegroundColor Yellow
foreach ($d in $skillDirs) {
    $content = Get-Content "$($d.FullName)\SKILL.md" -Raw
    $refs = [regex]::Matches($content, 'scripts/[\w.-]+') | ForEach-Object { $_.Value -replace '/', '\' }
    foreach ($ref in $refs) {
        $scriptPath = Join-Path $d.FullName $ref
        if (-not (Test-Path $scriptPath)) {
            Warn "$($d.Name)" "referenced script not found: $ref"
        }
    }
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  $PASS passed, $FAIL failed, $WARN warnings" -ForegroundColor $(if($FAIL -eq 0){'Green'}else{'Red'})
Write-Host "==========================================" -ForegroundColor Cyan
if ($CI -and $FAIL -gt 0) { exit 1 }
