#requires -Version 7.0

# ==============================================================================
#  Microsoft.PowerShell_profile.ps1 — Premium PowerShell Profile
#  Prompt: oh-my-posh  |  Autocomplete: PSReadLine  |  Aliases & Utilities
# ==============================================================================

# ── Imports ──────────────────────────────────────────────────────────────────
$modules = @(
  @{ Name = 'PSReadLine';           MinVer = '2.2.0' }
  @{ Name = 'Terminal-Icons';       MinVer = '0.10.0' }
  @{ Name = 'PSFzf';                MinVer = '2.5.0' }
)
foreach ($m in $modules) {
  if (-not (Get-Module -ListAvailable -Name $m.Name | Where-Object Version -ge $m.MinVer)) {
    Install-Module -Name $m.Name -MinimumVersion $m.MinVer -Force -Scope CurrentUser -AllowClobber
  }
  Import-Module -Name $m.Name -ErrorAction SilentlyContinue
}

# ── Oh My Posh ───────────────────────────────────────────────────────────────
if (Get-Command 'oh-my-posh' -ErrorAction SilentlyContinue) {
  try {
    $theme = if (Test-Path "$env:POSH_THEMES_PATH\montys.omp.json") {
      "$env:POSH_THEMES_PATH\montys.omp.json"
    } else {
      oh-my-posh --init --shell pwsh --config "$env:POSH_THEMES_PATH\powerlevel10k_rainbow.omp.json"
    }
    oh-my-posh init pwsh --config $theme | Invoke-Expression
  } catch {
    Write-Warning "oh-my-posh init failed: $_"
  }
}

# ── PSReadLine ───────────────────────────────────────────────────────────────
$psrl = Get-Module PSReadLine
if ($psrl) {
  Set-PSReadLineOption -EditMode Windows
  Set-PSReadLineOption -PredictionSource History
  Set-PSReadLineOption -PredictionViewStyle ListView
  Set-PSReadLineOption -HistoryNoDuplicates
  Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
  Set-PSReadLineKeyHandler -Key Ctrl+r -Function ReverseSearchHistory
  Set-PSReadLineKeyHandler -Key Ctrl+f -Function ForwardSearchHistory
  Set-PSReadLineKeyHandler -Key Ctrl+w -Function KillRegion
  Set-PSReadLineKeyHandler -Key Ctrl+Backspace -Function BackwardKillWord
  Set-PSReadLineKeyHandler -Key Alt+d -Function DeleteCharOrExit
}

# ── FZF ──────────────────────────────────────────────────────────────────────
if (Get-Module PSFzf -ErrorAction SilentlyContinue) {
  Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t'
  Set-PsFzfOption -PSReadlineChordReverseHistory 'Ctrl+r'
  Set-PsFzfOption -GitKeyBindings
}

# ── Utility Functions ────────────────────────────────────────────────────────
function touch { New-Item -ItemType File -Path $args[0] -Force }
function which { Get-Command -Name $args[0] -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source }
function ll    { Get-ChildItem -Force $args }
function la    { Get-ChildItem -Force -Hidden $args }
function mkcd  { param([string]$Path) New-Item -ItemType Directory -Path $Path -Force; Set-Location $Path }
function grep  { $args | Select-String -Pattern $args[0] }
function head  { param([int]$n = 10) $input | Select-Object -First $n }
function tail  { param([int]$n = 10) $input | Select-Object -Last $n }
function npx   { & "node_modules\.bin\$args" }
function reload-profile { . $PROFILE }

# ── Git Aliases ──────────────────────────────────────────────────────────────
Set-Alias -Name g      -Value git
function gs    { git status }
function ga    { git add $args }
function gc    { git commit -m $args }
function gcm   { git commit -m ($args -join ' ') }
function gp    { git push }
function gpf   { git push --force-with-lease }
function gpl   { git pull --rebase }
function gco   { git checkout $args }
function gb    { git branch }
function gl    { git log --oneline --graph --decorate -20 }
function gd    { git diff }
function gst   { git stash }
function gsta  { git stash apply }
function gcl   { git clone $args }
function gcb   { param([string]$b) git checkout -b $b }
function gba   { git branch -a }
function grh   { git reset --hard HEAD }
function grs   { git reset --soft HEAD~1 }
function gaac  { git add --all; git commit -m $args }

# ── npm / Node Shortcuts ─────────────────────────────────────────────────────
function ni    { npm install }
function nid   { npm install --save-dev $args }
function nig   { npm install --global $args }
function nr    { npm run $args }
function nrd   { npm run dev }
function nrb   { npm run build }
function nrs   { npm run start }
function nrt   { npm run test }
function nup   { npm update }
function nout  { npm outdated }
function nu    { npx npm-check-updates -u }
function yi    { yarn install }
function yr    { yarn run $args }
function yb    { yarn build }
function pi    { pnpm install }
function pr    { pnpm run $args }
function pd    { pnpm run dev }
function pb    { pnpm run build }

# ── Docker Aliases ───────────────────────────────────────────────────────────
Set-Alias -Name d       -Value docker
function di    { docker images }
function dps   { docker ps }
function dpsa  { docker ps -a }
function drm   { docker rm $args }
function drmi  { docker rmi $args }
function dlog  { docker logs -f $args }
function dex   { docker exec -it $args }
function dcup  { docker compose up -d }
function dcdn  { docker compose down }
function dcps  { docker compose ps }
function dclog { docker compose logs -f $args }
function dcb   { docker compose build }
function dcr   { docker compose run --rm $args }
function dprune { docker system prune -af --volumes }
function dstop { docker stop $(docker ps -q) }

# ── System Shortcuts ─────────────────────────────────────────────────────────
function admin {
  Start-Process wt -Verb RunAs -ArgumentList "-d `"$(Get-Location)`""
}
function uptime {
  $os = Get-CimInstance Win32_OperatingSystem
  $up = (Get-Date) - $os.LastBootUpTime
  Write-Host "$($up.Days)d $($up.Hours)h $($up.Minutes)m" -ForegroundColor Green
}
function env    { Get-ChildItem Env: | Out-GridView }
function path   { $env:Path -split ';' | Out-GridView }
function killp  { param([string]$n) Get-Process -Name $n -ErrorAction SilentlyContinue | Stop-Process -Force }

# ── Temp / Cleanup ───────────────────────────────────────────────────────────
function scratch {
  $dir = "$env:TEMP\scratch-$(Get-Random)"
  New-Item -ItemType Directory -Path $dir -Force | Out-Null
  Set-Location $dir
  Write-Host "Working in $dir"
}

# ── Prompt Customization Hooks ───────────────────────────────────────────────
# These run AFTER oh-my-posh — useful for extra context
$global:__LastDir = (Get-Location).Path
function prompt {
  # If working directory changed (e.g. via oh-my-posh), update title
  if ((Get-Location).Path -ne $global:__LastDir) {
    $global:__LastDir = (Get-Location).Path
  }
}

# ── Conda / Python (optional) ────────────────────────────────────────────────
# Uncomment if you use Miniconda/Anaconda:
# if (Test-Path "$env:USERPROFILE\miniconda3\shell\condabin\conda-hook.ps1") {
#   . "$env:USERPROFILE\miniconda3\shell\condabin\conda-hook.ps1"
#   conda activate "$env:USERPROFILE\miniconda3"
# }

# ── Welcome Message ──────────────────────────────────────────────────────────
$psVer = $PSVersionTable.PSVersion.ToString()
Write-Host "PowerShell $psVer  |  $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -ForegroundColor DarkGray
