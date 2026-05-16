<#
.SYNOPSIS
    Generates a PR description from git log since branching off base.
.DESCRIPTION
    Analyzes commits on the current branch against a base branch,
    groups them by conventional commit type, and outputs a formatted
    PR body with ## Summary, ## Changes, ## Testing sections.
.PARAMETER Base
    Base branch to compare against. Defaults to the default branch.
.PARAMETER Clipboard
    Copy output to clipboard (default: stdout).
.PARAMETER OutputPath
    Write PR body to a file instead of stdout.
.PARAMETER Emoji
    Include emoji prefixes for commit types.
.EXAMPLE
    .\pr-body.ps1
    Generates PR body comparing against main.
.EXAMPLE
    .\pr-body.ps1 -Base develop -Clipboard
    Compares against develop and copies to clipboard.
.EXAMPLE
    .\pr-body.ps1 -OutputPath .pr-body.md
    Writes PR body to .pr-body.md.
#>

param(
    [string]$Base,
    [switch]$Clipboard,
    [string]$OutputPath,
    [switch]$Emoji
)

$ErrorActionPreference = 'Stop'
$env:GIT_PAGER = 'cat'

# ---- Helpers ----

$EMOJI_MAP = @{
    feat     = '✨'
    fix      = '🐛'
    docs     = '📝'
    refactor = '♻️'
    test     = '✅'
    chore    = '🔧'
    style    = '💄'
    perf     = '⚡'
    ci       = '👷'
    revert   = '⏪'
}

function Concat-Emoji {
    param([string]$Type)
    if (-not $Emoji) { return $Type }
    $e = $EMOJI_MAP[$Type]
    return if ($e) { "$e $Type" } else { $Type }
}

function Get-DefaultBase {
    $branches = @('main', 'master', 'develop')
    foreach ($b in $branches) {
        $exists = git show-ref --verify "refs/heads/$b" 2>$null
        if ($exists) { return $b }
    }
    return 'main'
}

function Get-CommitsSinceBase {
    param([string]$Base)

    $baseBranch = if ($Base) { $Base } else { Get-DefaultBase }

    # Find the merge-base
    $forkPoint = git merge-base "origin/$baseBranch" HEAD 2>$null
    if (-not $forkPoint) {
        $forkPoint = git merge-base $baseBranch HEAD 2>$null
    }
    if (-not $forkPoint) {
        Write-Warning "Could not find merge-base with $baseBranch. Falling back to diff with $baseBranch..HEAD"
        $forkPoint = $baseBranch
    }

    return git log "$forkPoint..HEAD" --format='%s|||%b|||%an|||%h' --reverse
}

function Format-Commits {
    param([string[]]$RawCommits)

    $grouped = @{}
    $uncategorized = @()

    foreach ($line in $RawCommits) {
        if (-not $line.Trim()) { continue }
        $parts = $line -split '\|\|\|'
        $subject = $parts[0].Trim()
        $body = $parts[1].Trim()
        $author = $parts[2].Trim()
        $hash = $parts[3].Trim()

        # Check for BREAKING CHANGE
        $isBreaking = $subject -match '^.*!' -or $body -match 'BREAKING CHANGE'

        # Try to parse conventional commit
        if ($subject -match '^(\w+)(\([^)]+\))?(!)?:\s*(.*)') {
            $type = $matches[1]
            $scope = $matches[2] -replace '^\(|\)$', ''
            $description = $matches[4]
            $breaking = $isBreaking -or ($matches[3] -eq '!')

            $key = if ($breaking) { "BREAKING $type" } else { $type }
            if (-not $grouped[$key]) { $grouped[$key] = @() }

            $entry = "- $description"
            if ($scope) { $entry += " ($scope)" }
            $entry += " ($hash)"

            $grouped[$key] += @{ Entry = $entry; Type = $type; Breaking = $breaking }
        } else {
            $uncategorized += "- $subject ($hash)"
        }
    }

    return @{ Grouped = $grouped; Uncategorized = $uncategorized }
}

function Build-PrBody {
    param(
        [hashtable]$Data,
        [string]$BaseBranch,
        [int]$CommitCount,
        [string[]]$Files
    )

    $lines = @()

    # ---- Summary ----
    $lines += "## Summary"
    $lines += ""
    $lines += "**$CommitCount commits** across **$($Files.Count) files**"
    $lines += ""

    if ($Data.Uncategorized.Count -gt 0 -and ($Data.Grouped.Keys -join ' ') -match '^(feat|fix)') {
        $lines += "> **Why:** "
        # pick first feat or fix description
        $firstMeaningful = $null
        if ($Data.Grouped['feat']) { $firstMeaningful = $Data.Grouped['feat'][0].Entry -replace '^- ', '' }
        elseif ($Data.Grouped['fix']) { $firstMeaningful = $Data.Grouped['fix'][0].Entry -replace '^- ', '' }
        if ($firstMeaningful) { $lines += "$firstMeaningful" }
    }
    $lines += ""

    # ---- Changes ----
    $lines += "## Changes"
    $lines += ""

    $typeOrder = @('BREAKING feat', 'BREAKING fix', 'BREAKING', 'feat', 'fix', 'refactor', 'perf', 'test', 'docs', 'style', 'chore', 'ci', 'revert')

    foreach ($type in $typeOrder) {
        if ($Data.Grouped[$type]) {
            $displayType = if ($type -match '^BREAKING (.+)') {
                $t = $matches[1]
                "$(Concat-Emoji $t) (BREAKING)"
            } else {
                Concat-Emoji $type
            }
            $lines += "### $displayType"
            $lines += ""
            foreach ($entry in $Data.Grouped[$type]) {
                $prefix = if ($entry.Breaking) { '**BREAKING:** ' } else { '' }
                $lines += "$prefix$($entry.Entry)"
            }
            $lines += ""
        }
    }

    if ($Data.Uncategorized) {
        $lines += "### Other"
        $lines += ""
        $lines += $Data.Uncategorized
        $lines += ""
    }

    # ---- Changed files ----
    $lines += "### Files Changed"
    $lines += ""
    foreach ($file in $Files) {
        $lines += "- \`$file\`"
    }
    $lines += ""

    # ---- Testing ----
    $lines += "## Testing"
    $lines += ""
    $lines += "1. [ ] Verified locally"
    if ($Data.Grouped['test']) {
        $lines += "2. [ ] Tests added/updated"
        $lines += "3. [ ] All tests pass"
    } else {
        $lines += "2. [ ] Existing tests pass"
    }
    $lines += "4. [ ] Lint/typecheck clean"
    $lines += ""
    $lines += "---"
    $lines += "> Generated by pr-body.ps1"

    return $lines -join "`r`n"
}

# ---- Main ----

Write-Host "=== PR Body Generator ===" -ForegroundColor Cyan

$baseBranch = if ($Base) { $Base } else { Get-DefaultBase }

# Check we're on a branch
$currentBranch = git rev-parse --abbrev-ref HEAD
if ($currentBranch -eq 'HEAD') {
    Write-Error "Detached HEAD — cannot determine PR context."
    exit 1
}

Write-Host "  Base:     $baseBranch" -ForegroundColor Gray
Write-Host "  Head:     $currentBranch" -ForegroundColor Gray

# Fetch latest base to get accurate comparison
git fetch origin $baseBranch --prune -q 2>$null

# Get commits
$rawCommits = Get-CommitsSinceBase -Base $baseBranch
if (-not $rawCommits) {
    Write-Host "No new commits since $baseBranch." -ForegroundColor Yellow
    exit 0
}

# Get changed files
$forkPoint = git merge-base "origin/$baseBranch" HEAD 2>$null
if (-not $forkPoint) { $forkPoint = $baseBranch }
$changedFiles = git diff "$forkPoint..HEAD" --name-only

# Format
$parsed = Format-Commits $rawCommits
$commitCount = $rawCommits.Count

$prBody = Build-PrBody -Data $parsed -BaseBranch $baseBranch -CommitCount $commitCount -Files $changedFiles

Write-Host "  Commits:  $commitCount" -ForegroundColor Gray
Write-Host "  Files:    $($changedFiles.Count)" -ForegroundColor Gray

if ($Clipboard) {
    Set-Clipboard -Value $prBody
    Write-Host "`nCopied to clipboard." -ForegroundColor Green
}

if ($OutputPath) {
    $prBody | Out-File -FilePath $OutputPath -Encoding utf8
    Write-Host "Written to $OutputPath" -ForegroundColor Green
}

if (-not $Clipboard -and -not $OutputPath) {
    Write-Host "`n$('=' * 60)" -ForegroundColor Cyan
    Write-Host $prBody
    Write-Host "$('=' * 60)" -ForegroundColor Cyan
}
