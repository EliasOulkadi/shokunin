<#
.SYNOPSIS
    Creates a feature branch from the latest default branch.
.DESCRIPTION
    Detects the default branch (main/master), fetches and updates it,
    then creates a new branch with conventional naming: type/description.
.PARAMETER Name
    Short kebab-case description of the branch purpose.
.PARAMETER Type
    Conventional commit type: feat, fix, docs, refactor, chore, test, style.
.PARAMETER Base
    Optional base branch. Defaults to detected default branch.
.EXAMPLE
    .\create-feature-branch.ps1 -Name "add-login-form" -Type feat
    Creates feat/add-login-form from latest main.
.EXAMPLE
    .\create-feature-branch.ps1 -Name "fix-auth-timeout" -Type fix -Base develop
    Creates fix/auth-timeout from latest develop.
#>

param(
    [Parameter(Mandatory)]
    [string]$Name,

    [Parameter(Mandatory)]
    [ValidateSet('feat', 'fix', 'docs', 'refactor', 'chore', 'test', 'style')]
    [string]$Type,

    [string]$Base
)

$ErrorActionPreference = 'Stop'

function Get-DefaultBranch {
    $branches = @('main', 'master')
    foreach ($b in $branches) {
        $exists = git show-ref --verify "refs/remotes/origin/$b" 2>$null
        if ($exists) { return $b }
    }
    # fallback: ask remote
    $remoteHead = git symbolic-ref refs/remotes/origin/HEAD 2>$null
    if ($remoteHead) {
        return $remoteHead -replace '^refs/remotes/origin/', ''
    }
    throw "Could not detect default branch. Specify -Base explicitly."
}

function Confirm-CleanWorkingTree {
    $status = git status --porcelain
    if ($status) {
        Write-Warning "Working tree is not clean. Stash or commit before branching."
        $choice = Read-Host "Continue anyway? [y/N]"
        if ($choice -ne 'y') { exit 1 }
    }
}

function Invoke-Step {
    param([string]$Message, [scriptblock]$Block)
    Write-Host "==> $Message" -ForegroundColor Cyan
    & $Block
    if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
        throw "Step failed: $Message"
    }
}

$branchName = "$Type/$Name"
$baseBranch = if ($Base) { $Base } else { Get-DefaultBranch }
$remote = 'origin'

Write-Host "=== Creating branch: $branchName from $baseBranch ===" -ForegroundColor Green

Confirm-CleanWorkingTree

Invoke-Step "Fetching latest from $remote" {
    git fetch $remote --prune
}

Invoke-Step "Checking out $baseBranch" {
    git checkout $baseBranch
}

Invoke-Step "Pulling latest $baseBranch" {
    git pull $remote $baseBranch --ff-only
}

Invoke-Step "Creating and switching to $branchName" {
    git checkout -b $branchName
}

Invoke-Step "Setting upstream tracking" {
    git push -u $remote $branchName
}

Write-Host "=== Done: $branchName (based on $baseBranch) ===" -ForegroundColor Green
Write-Host "Next: make changes, then stage and commit." -ForegroundColor Yellow
