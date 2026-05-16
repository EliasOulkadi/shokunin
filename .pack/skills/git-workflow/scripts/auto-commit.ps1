<#
.SYNOPSIS
    Stages all changes and commits with an auto-generated conventional message.
.DESCRIPTION
    Analyzes the working tree diff to generate a conventional commit message
    (type(scope): description) using heuristics on changed files.
.PARAMETER Amend
    Amend the last commit instead of creating a new one.
.PARAMETER NoVerify
    Bypass pre-commit and commit-msg hooks.
.PARAMETER Scope
    Optional scope for the conventional commit message.
.PARAMETER Message
    Override auto-generated message with a custom one.
.PARAMETER DryRun
    Show what would be committed without actually committing.
.EXAMPLE
    .\auto-commit.ps1
    Stages all changes and commits with an auto-generated message.
.EXAMPLE
    .\auto-commit.ps1 -Amend -NoVerify
    Amends the last commit, skipping hooks.
.EXAMPLE
    .\auto-commit.ps1 -Scope "auth" -Message "add rate limiting"
    Commits with message "feat(auth): add rate limiting".
#>

param(
    [switch]$Amend,
    [switch]$NoVerify,
    [string]$Scope,
    [string]$Message,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$env:GIT_PAGER = 'cat'

# ---- Helpers ----

function Get-ChangeType {
    param([string[]]$Files)

    $filesStr = $Files -join ' '
    # detect refactoring or restructuring
    if ($Files.Count -gt 20) { return 'chore' }

    # check diff content for patterns
    if ($Files | Where-Object { $_ -match '\.(test|spec|cy)\.(ts|tsx|js|jsx)$' -or $_ -match '__tests__|tests/' }) {
        return 'test'
    }

    if ($filesStr -match '\.md$|docs/|readme|changelog') { return 'docs' }

    if ($filesStr -match '^\d{4}-\d{2}-\d{2}_') { return 'chore' }

    if ($filesStr -match 'docker|\.github/|\.gitlab|ci/|Jenkinsfile') { return 'ci' }

    if ($filesStr -match 'package(-lock)?\.json|\.nvmrc|\.tool-versions|tsconfig|\.eslint|\.prettier|biome') { return 'chore' }

    if ($filesStr -match '\.(css|scss|less|tailwind|unocss)') { return 'style' }

    return 'feat'
}

function Get-ChangeScope {
    param([string[]]$Files)

    $dirs = $Files |
        ForEach-Object {
            $parts = $_ -split '[/\\]'
            if ($parts.Count -ge 2) { $parts[0] }
            else { 'root' }
        } |
        Group-Object |
        Sort-Object Count -Descending

    if ($dirs -and $dirs[0].Count -gt ($Files.Count * 0.4)) {
        return $dirs[0].Name
    }
    return ''
}

function Get-FileSummary {
    param([string[]]$Files)

    $additions = (git diff --cached --numstat |
        ForEach-Object { ($_ -split '\s+')[0] } |
        Measure-Object -Sum).Sum

    $deletions = (git diff --cached --numstat |
        ForEach-Object { ($_ -split '\s+')[1] } |
        Measure-Object -Sum).Sum

    return @{
        Files      = $Files.Count
        Additions  = [math]::Max(0, $additions)
        Deletions  = [math]::Max(0, $deletions)
    }
}

function Get-DiffSummaryLine {
    param([string[]]$Files)

    $summary = Get-FileSummary $Files
    $parts = @()
    $parts += "$($summary.Files) files"
    if ($summary.Additions -gt 0) { $parts += "+$($summary.Additions)" }
    if ($summary.Deletions -gt 0) { $parts += "-$($summary.Deletions)" }
    return $parts -join ', '
}

# ---- Main ----

Write-Host "=== Auto-Commit ===" -ForegroundColor Cyan

# Stage all
git add -A
$staged = git diff --cached --name-only
if (-not $staged) {
    Write-Host "Nothing to commit. Working tree is clean." -ForegroundColor Yellow
    if (-not $Amend) { exit 0 }
}

$files = @($staged -split "`n" | Where-Object { $_ })

if ($Message) {
    $commitMsg = if ($Scope) { "$($tmpType)($Scope): $Message" } else { "feat: $Message" }
    # replace placeholder
    $commitMsg = $commitMsg -replace '^\$\(.*?\)', 'feat'
} else {
    $type = Get-ChangeType $files
    $detectedScope = Get-ChangeScope $files
    $finalScope = if ($Scope) { $Scope } elseif ($detectedScope) { $detectedScope } else { '' }

    # Build description from changed files
    if ($type -eq 'feat') {
        $desc = "add " + ($files |
            Where-Object { $_ -notmatch '\.(test|spec)\.' } |
            ForEach-Object {
                $_.Split('/')[-1] -replace '\.[^.]+$', '' -replace '[-_]', ' '
            } |
            Select-Object -First 3) -join ', '
    } elseif ($type -eq 'fix') {
        $desc = "fix " + ($files |
            ForEach-Object {
                $_.Split('/')[-1] -replace '\.[^.]+$', '' -replace '[-_]', ' '
            } |
            Select-Object -First 2) -join ', '
    } else {
        $desc = ($files |
            Select-Object -First 1 |
            ForEach-Object { $_ -replace '/', '/' } )
    }

    if ($desc.Length -gt 72) { $desc = $desc.Substring(0, 69) + '...' }

    $commitMsg = if ($finalScope) {
        "$type($finalScope): $desc"
    } else {
        "$type: $desc"
    }
}

$diffLine = Get-DiffSummaryLine $files

Write-Host "  Message: $commitMsg" -ForegroundColor White
Write-Host "  Diff:    $diffLine" -ForegroundColor Gray
Write-Host "  Files:   $($files.Count) changed" -ForegroundColor Gray

if ($DryRun) {
    # show the staged diff
    git diff --cached --stat
    Write-Host "`n[Dry Run] Would commit with message:" -ForegroundColor Yellow
    Write-Host "  $commitMsg" -ForegroundColor Cyan
    exit 0
}

# Build commit args
$commitArgs = @('commit', '-m', $commitMsg)
if ($Amend) { $commitArgs += '--amend' }
if ($NoVerify) { $commitArgs += '--no-verify' }

Write-Host "`nCommitting..." -ForegroundColor Cyan
git @commitArgs
if ($LASTEXITCODE -eq 0) {
    Write-Host "=== Commit successful ===" -ForegroundColor Green
} else {
    Write-Host "=== Commit failed ===" -ForegroundColor Red
    exit 1
}
