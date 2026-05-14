# Shokunin AI Ecosystem â€” PowerShell Profile
# Documentation: https://github.com/EliasOulkadi/shokunin

# Aliases â€” Git
function gst { git status }
function ga { git add -A }
function gc { param($m) git commit -m $m }
function gp { git push }
function gl { git pull --ff-only }
function gb { git branch }
function gco { git checkout }

# Aliases â€” npm
function ni { npm install }
function nrd { npm run dev }
function nrb { npm run build }
function nt { npm test }

# Aliases â€” Docker
function dps { docker ps }
function dlog { docker logs -f }
function dstop { docker stop }

# Aliases â€” Utils
Set-Alias -Name ll -Value "Get-ChildItem"
function mkcd { param($Path) New-Item -ItemType Directory -Path $Path -Force | Set-Location }
function touch { param($File) New-Item -ItemType File -Path $File -Force }
function which { param($Cmd) Get-Command $Cmd -ErrorAction SilentlyContinue | Select-Object Source }
function admin { Start-Process powershell -Verb RunAs }

# PSReadLine autocomplete
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle Inline
Set-PSReadLineKeyHandler -Key Ctrl+Space -Function MenuComplete

# Telegram Bot auto-start
$botJob = Get-Job -Name "ShokuninBot" -ErrorAction SilentlyContinue
if (-not $botJob) {
    $token = [Environment]::GetEnvironmentVariable('TELEGRAM_BOT_TOKEN','User')
    if ($token) {
        $botScript = "$env:USERPROFILE\.shokunin\telegram\bot.py"
        if (Test-Path $botScript) {
            Start-Job -Name "ShokuninBot" -ScriptBlock {
                param($t, $s) $env:TELEGRAM_BOT_TOKEN = $t; python $s
            } -ArgumentList $token, $botScript | Out-Null
        }
    }
}

# Oh My Posh prompt
$ompPath = "$env:LOCALAPPDATA\Programs\oh-my-posh\bin\oh-my-posh.exe"
if (Test-Path $ompPath) {
    try { & $ompPath init pwsh --config "$env:POSH_THEMES_PATH\atomic.omp.json" | Invoke-Expression } catch {}
}

# Shadow opencode to always use run-opencode.ps1 wrapper
function global:opencode {
    $wrapper = "$env:USERPROFILE\.shokunin\scripts\run-opencode.ps1"
    if (Test-Path $wrapper) {
        & $wrapper
    } else {
        & "$env:USERPROFILE\AppData\Roaming\npm\opencode.ps1"
    }
}

Write-Host "Shokunin AI Ecosystem loaded" -Fo
