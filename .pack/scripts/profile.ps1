<#
.SYNOPSIS
    PowerShell profile for the Shokunin AI Ecosystem - aliases, PSReadLine, Telegram bot, Oh My Posh.
#>
# Profile should not use StrictMode or Stop — it must degrade gracefully
$ErrorActionPreference = "Continue"

# Shokunin AI Ecosystem - PowerShell Profile
# Documentation: https://github.com/EliasOulkadi/shokunin

# Aliases - Git
function gst { git status }
function ga { git add -A }
function gcm { param($m) git commit -m "$m" }
function gp { git push }
function gl { git pull --ff-only }
function gb { git branch }
function gco { git checkout }

# Aliases - npm
function ni { npm install }
function nrd { npm run dev }
function nrb { npm run build }
function nt { npm test }

# Aliases - Docker
function dps { docker ps }
function dlog { docker logs -f }
function dstop { docker stop }

# Aliases - Utils
Set-Alias -Name ll -Value "Get-ChildItem"
function mkcd { param($Path) New-Item -ItemType Directory -Path $Path -Force | Set-Location }
function touch { param($File) New-Item -ItemType File -Path $File -Force }
function which { param($Cmd) Get-Command $Cmd -ErrorAction SilentlyContinue | Select-Object Source }
function admin { Start-Process powershell -Verb RunAs }

# PSReadLine autocomplete (optional - skip if PSReadLine < 2.x)
try {
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -PredictionViewStyle Inline -ErrorAction Stop
    Set-PSReadLineKeyHandler -Key Ctrl+Space -Function MenuComplete -ErrorAction Stop
} catch {}

# Oh My Posh prompt
# Windows-only path — uses backslash convention for Windows executables
$ompPath = "$env:LOCALAPPDATA\Programs\oh-my-posh\bin\oh-my-posh.exe"
if (Test-Path $ompPath) {
    try { & $ompPath init pwsh --config "$env:POSH_THEMES_PATH\atomic.omp.json" | Invoke-Expression } catch {}
}

# Shadow opencode to always use run-opencode.ps1 wrapper
function global:opencode {
    $wrapper = "$env:USERPROFILE\.shokunin\scripts\run-opencode.ps1"
    if (Test-Path $wrapper) {
        & $wrapper @args
    } else {
        $realOpencode = Get-Command opencode.exe -ErrorAction SilentlyContinue
        if ($realOpencode) {
            & $realOpencode.Source @args
        } else {
            Write-Host "opencode not found. Install with: npm install -g opencode" -ForegroundColor Red
        }
    }
}

Write-Host "Shokunin AI Ecosystem loaded" -ForegroundColor Cyan
