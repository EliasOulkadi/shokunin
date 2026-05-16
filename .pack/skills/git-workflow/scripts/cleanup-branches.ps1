<#
.SYNOPSIS
    Deletes local and remote branches that have been merged.
.DESCRIPTION
    Lists all merged branches (excluding main/master/develop),
    asks for confirmation, then deletes them locally and remotely.
.PARAMETER Force
    Skip confirmation prompt.
.PARAMETER Remote
    Also delete remote tracking branches (default: $true).
.PARAMETER Exclude
    Additional branch patterns to exclude (comma-separated).
.EXAMPLE
    .\cleanup-branches.ps1
    Shows merged branches and prompts before deleting.
.EXAMPLE
    .\cleanup-branches.ps1 -Force
    Deletes without prompting.
.EXAMPLE
    .\cleanup-branches.ps1 -Remote:$false
    Only deletes local branches, leaves remote intact.
#>

param(
    [switch]$Force,
    [bool]$Remote = $true,
    [string]$Exclude
)

$ErrorActionPreference = 'Stop'

$protected = @('main', 'master', 'develop')
if ($Exclude) {
    $protected += $Exclude -split ','
}

# Disable pager to avoid hangs
$env:GIT_PAGER = 'cat'

function Get-MergedBranches {
    $currentBranch = git rev-parse --abbrev-ref HEAD
    $mergeBase = git merge-base HEAD $(git branch -r --merged | ForEach-Object { $_.Trim() } | Select-Object -First 1)

    git branch --merged |
        ForEach-Object { $_.Trim() } |
        Where-Object {
            $_ -and
            $_ -notin $protected -and
            $_ -ne $currentBranch -and
            $_ -notmatch '^\*'
        } |
        Sort-Object
}

function Get-MergedRemoteBranches {
    git branch -r --merged |
        ForEach-Object { $_.Trim() } |
        Where-Object {
            $_ -match '^origin/(.+)$' -and
            $matches[1] -notin $protected -and
            $matches[1] -notmatch '^(HEAD|gh-pages)$'
        } |
        ForEach-Object { $_.Trim() } |
        Sort-Object
}

function Confirm-AndDelete {
    param([string[]]$Branches, [string]$Scope)

    if (-not $Branches) {
        Write-Host "No merged $Scope branches to clean up." -ForegroundColor Green
        return
    }

    Write-Host "`nMerged $Scope branches:" -ForegroundColor Yellow
    $Branches | ForEach-Object { Write-Host "  - $_" }

    if (-not $Force) {
        $confirm = Read-Host "`nDelete these $($Branches.Count) $Scope branches? [y/N]"
        if ($confirm -ne 'y') {
            Write-Host "Skipped $Scope cleanup." -ForegroundColor Gray
            return
        }
    }

    $deleted = 0
    $failed = 0
    foreach ($branch in $Branches) {
        try {
            if ($Scope -eq 'local') {
                git branch -d $branch 2>$null
            } else {
                git push origin --delete $branch 2>$null
            }
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  [ok] $branch" -ForegroundColor Green
                $deleted++
            } else {
                Write-Host "  [!!] $branch (failed)" -ForegroundColor Red
                $failed++
            }
        } catch {
            Write-Host "  [!!] $branch ($($_.Exception.Message))" -ForegroundColor Red
            $failed++
        }
    }

    Write-Host "`n$Scope: $deleted deleted, $failed failed" -ForegroundColor $(if ($failed -eq 0) { 'Green' } else { 'Red' })
}

Write-Host "=== Branch Cleanup ===" -ForegroundColor Cyan

# Fetch latest remote state
Write-Host "Fetching from origin..." -ForegroundColor Gray
git fetch --prune -q

$localMerged = Get-MergedBranches
Confirm-AndDelete -Branches $localMerged -Scope 'local'

if ($Remote) {
    $remoteMerged = Get-MergedRemoteBranches
    Confirm-AndDelete -Branches $remoteMerged -Scope 'remote'
}

# Prune local remote-tracking refs
Write-Host "`nPruning stale remote-tracking refs..." -ForegroundColor Gray
git remote prune origin -q

Write-Host "=== Cleanup complete ===" -ForegroundColor Cyan
