<#
.SYNOPSIS
  Checks for and installs common Windows dev tools via winget or scoop.
.DESCRIPTION
  Supports: Git, Node.js, Python, VS Code, Docker Desktop, 7-Zip, PowerShell 7,
  Windows Terminal, Oh My Posh, Postman (or alternatives).
  Skips already-installed tools. Logs all actions.
.EXAMPLE
  .\install-tools.ps1
  .\install-tools.ps1 -Verbose
.PARAMETER Scope
  'user' (default) or 'machine' – affects winget --scope parameter.
.PARAMETER PackageManager
  'winget' (default). Future: 'scoop'.
#>

param(
  [ValidateSet('user', 'machine')]
  [string]$Scope = 'user',
  [ValidateSet('winget', 'scoop')]
  [string]$PackageManager = 'winget'
)

$ErrorActionPreference = 'Continue'
$log = @()

function Write-Log {
  param([string]$Message)
  $timestamp = Get-Date -Format 'HH:mm:ss'
  $line = "[$timestamp] $Message"
  $log += $line
  Write-Host $line
}

function Test-CommandAvailable {
  param([string]$Command)
  return [bool](Get-Command $Command -ErrorAction SilentlyContinue)
}

function Install-WithWinget {
  param(
    [string]$Id,
    [string]$Name
  )
  if (Test-CommandAvailable 'winget') {
    Write-Log "Installing $Name ($Id) via winget..."
    & winget install --id $Id --silent --accept-package-agreements --scope $Scope 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
      Write-Log "  $Name installed successfully."
    } else {
      Write-Log "  $Name install returned exit code $LASTEXITCODE (may already be installed)."
    }
  } else {
    Write-Log "  winget not available. Skipping $Name."
  }
}

# ---- Prerequisites ----
Write-Log "=== Dev Tools Installer ==="
Write-Log "Scope: $Scope | Manager: $PackageManager"

if (-not (Test-CommandAvailable 'winget')) {
  Write-Log "WARNING: winget not found. Install App Installer from the Microsoft Store first."
}

# ---- Tools to install ----
$tools = @(
  @{ Id = 'Git.Git';                Name = 'Git' }
  @{ Id = 'OpenJS.NodeJS';          Name = 'Node.js' }
  @{ Id = 'Python.Python.3.13';     Name = 'Python 3' }
  @{ Id = 'Microsoft.VisualStudioCode';  Name = 'VS Code' }
  @{ Id = 'Docker.DockerDesktop';    Name = 'Docker Desktop' }
  @{ Id = '7zip.7zip';              Name = '7-Zip' }
  @{ Id = 'Microsoft.PowerShell';    Name = 'PowerShell 7' }
  @{ Id = 'Microsoft.WindowsTerminal'; Name = 'Windows Terminal' }
  @{ Id = 'JanDeDobbeleer.OhMyPosh'; Name = 'Oh My Posh' }
  @{ Id = 'Postman.Postman';        Name = 'Postman' }
)

Write-Log ""
Write-Log "Checking installed tools..."

foreach ($tool in $tools) {
  $name = $tool.Name
  $id   = $tool.Id
  $exeName = switch ($name) {
    'Git'            { 'git' }
    'Node.js'        { 'node' }
    'Python 3'       { 'python' }
    'VS Code'        { 'code' }
    'Docker Desktop' { 'docker' }
    '7-Zip'          { '7z' }
    'PowerShell 7'   { 'pwsh' }
    'Windows Terminal' { 'wt' }
    'Oh My Posh'     { 'oh-my-posh' }
    'Postman'        { 'postman' }
    default          { $null }
  }
  if ($exeName -and (Test-CommandAvailable $exeName)) {
    Write-Log "  $name already installed."
  } else {
    Install-WithWinget -Id $id -Name $name
  }
}

# ---- Post-install reminders ----
Write-Log ""
Write-Log "=== Summary ==="
Write-Log "Installation complete. Reminders:"
Write-Log "  - Restart terminals to update PATH"
Write-Log "  - For Oh My Posh: add 'oh-my-posh init pwsh | Invoke-Expression' to `$PROFILE"
Write-Log "  - For Docker Desktop: a restart may be required"

# Return log for pipeline use
return $log
