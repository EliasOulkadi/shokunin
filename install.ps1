<#
.SYNOPSIS
    Shokunin AI Ecosystem Installer v3.1
.DESCRIPTION
    One-command installer for the complete Shokunin AI ecosystem:
    36 skills, MCP servers, ChromaDB memory, Telegram bot, terminal configs
.NOTES
    Requires: Windows 10/11, PowerShell 5.1+, Node.js 18+, Python 3.11+
    Run: irm https://raw.githubusercontent.com/EliasOulkadi/shokunin/master/install.ps1 | iex
#>

$ErrorActionPreference = "Stop"
$Host.UI.RawUI.WindowTitle = "Shokunin AI Ecosystem Installer v3.1"
$script:version = "3.1.0"
$script:installDir = "$env:USERPROFILE\.shokunin"
$script:skillsDir = "$env:USERPROFILE\.config\opencode\skills"
$script:startupDir = [Environment]::GetFolderPath('Startup')
$script:logFile = "$env:TEMP\shokunin-install-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

# ============================================================
# SECTION 1: LOGGING & DISPLAY
# ============================================================
function Write-Log { param([string]$Msg, [string]$Color = "White") Write-Host "  $Msg" -ForegroundColor $Color }
function Write-Step { param([string]$Msg) Write-Host "`n[$($script:step++)] $Msg" -ForegroundColor Cyan }
function Write-OK { Write-Host "    OK" -ForegroundColor Green }
function Write-Skip { Write-Host "    SKIP (ya existe)" -ForegroundColor Yellow }
function Write-Fail { Write-Host "    FAIL" -ForegroundColor Red }

# ============================================================
# SECTION 2: PREREQUISITES CHECK
# ============================================================
function Test-Prerequisites {
    Write-Step "Verificando requisitos..."
    $allOk = $true

    # Windows
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        Write-Log "PowerShell 5+ requerido" Red; $allOk = $false
    } else { Write-Log "PowerShell $($PSVersionTable.PSVersion.ToString())" Green }

    # Node.js
    try {
        $nodeVer = node --version
        $verNum = [int]($nodeVer -replace '[v.]','').Substring(0,2)
        if ($verNum -lt 18) { throw "version too low" }
        Write-Log "Node.js $nodeVer" Green
    } catch { Write-Log "Node.js 18+ requerido (https://nodejs.org)" Red; $allOk = $false }

    # Python
    try {
        $pyVer = python3 --version 2>$null
        if (-not $pyVer) { $pyVer = python --version 2>$null }
        if ($pyVer -match '(\d+)\.(\d+)') {
            $major = [int]$Matches[1]; $minor = [int]$Matches[2]
            if ($major -ge 3 -and $minor -ge 11) { Write-Log "Python $major.$minor+" Green }
            else { throw "version too low" }
        } else { throw "not found" }
    } catch { Write-Log "Python 3.11+ requerido (https://python.org)" Red; $allOk = $false }

    # Git
    try { git --version 2>$null | Out-Null; Write-Log "Git instalado" Green }
    catch { Write-Log "Git requerido (winget install Git.Git)" Red; $allOk = $false }

    # OpenCode
    try {
        $ocVer = opencode --version 2>$null
        if ($ocVer) { Write-Log "OpenCode $ocVer" Green }
        else { throw "not found" }
    } catch {
        Write-Log "OpenCode no detectado. Instalando..." Yellow
        try {
            npm install -g opencode 2>&1 | Out-Null
            Write-Log "OpenCode instalado" Green
        } catch { Write-Log "No se pudo instalar OpenCode. npm install -g opencode manualmente" Red; $allOk = $false }
    }

    if (-not $allOk) {
        Write-Host "`n  Requisitos no cumplidos. Instala lo que falta y vuelve a ejecutar." -ForegroundColor Red
        exit 1
    }
}

# ============================================================
# SECTION 3: INSTALL DEPENDENCIES
# ============================================================
function Install-Dependencies {
    Write-Step "Instalando dependencias Python..."
    pip install chromadb python-telegram-bot 2>&1 | Out-Null
    Write-OK

    Write-Step "Instalando MCP servers (npx)..."
    npx -y @modelcontextprotocol/server-filesystem --version 2>&1 | Out-Null
    npx -y @modelcontextprotocol/server-fetch --version 2>&1 | Out-Null
    Write-OK
}

# ============================================================
# SECTION 4: INSTALL SKILLS
# ============================================================
function Install-Skills {
    Write-Step "Instalando 36 skills..."
    $repoSkills = Join-Path $PSScriptRoot "skills"
    if (-not (Test-Path $repoSkills)) { $repoSkills = Join-Path $PSScriptRoot "." }

    if (-not (Test-Path $script:skillsDir)) {
        New-Item -ItemType Directory -Path $script:skillsDir -Force | Out-Null
    }

    $count = 0
    Get-ChildItem $repoSkills -Directory | Where-Object { Test-Path (Join-Path $_.FullName "SKILL.md") } | ForEach-Object {
        $target = Join-Path $script:skillsDir $_.Name
        if (-not (Test-Path $target)) {
            New-Item -ItemType Directory -Path $target -Force | Out-Null
        }
        Copy-Item -Recurse -Force "$($_.FullName)\*" "$target\" -ErrorAction SilentlyContinue
        $count++
    }

    if ($count -gt 0) { Write-Log "$count skills instaladas en $script:skillsDir" Green }
    else {
        Write-Log "No se encontraron skills en el repositorio. Clonando..." Yellow
        git clone https://github.com/EliasOulkadi/shokunin.git "$env:TEMP\shokunin-tmp" 2>&1 | Out-Null
        Get-ChildItem "$env:TEMP\shokunin-tmp" -Directory | Where-Object { Test-Path (Join-Path $_.FullName "SKILL.md") } | ForEach-Object {
            $target = Join-Path $script:skillsDir $_.Name
            if (-not (Test-Path $target)) { New-Item -ItemType Directory -Path $target -Force | Out-Null }
            Copy-Item -Recurse -Force "$($_.FullName)\*" "$target\" -ErrorAction SilentlyContinue
            $count++
        }
        Remove-Item -Recurse -Force "$env:TEMP\shokunin-tmp" -ErrorAction SilentlyContinue
        Write-Log "$count skills instaladas" Green
    }
}

# ============================================================
# SECTION 5: MEMORY SYSTEM (ChromaDB)
# ============================================================
function Install-MemorySystem {
    Write-Step "Instalando sistema de memoria (ChromaDB)..."

    # Create directories
    @("memory","memory\chroma_db","memory\sessions","telegram","backups","scripts","logs") | ForEach-Object {
        $d = Join-Path $script:installDir $_
        if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
    }
    Write-Log "Directorios creados en $script:installDir" Green

    # Copy MCP server
    $mcpSrc = Join-Path $PSScriptRoot ".pack\memory\mcp-server.py"
    if (Test-Path $mcpSrc) {
        Copy-Item $mcpSrc (Join-Path $script:installDir "memory\mcp-server.py") -Force
    } else {
        # Download from GitHub
        $url = "https://raw.githubusercontent.com/EliasOulkadi/shokunin/master/.pack/memory/mcp-server.py"
        Invoke-WebRequest -Uri $url -OutFile (Join-Path $script:installDir "memory\mcp-server.py") -ErrorAction SilentlyContinue
    }

    # Copy Telegram bot
    $tgSrc = Join-Path $PSScriptRoot ".pack\telegram\bot.py"
    if (Test-Path $tgSrc) {
        Copy-Item $tgSrc (Join-Path $script:installDir "telegram\bot.py") -Force
    } else {
        $url = "https://raw.githubusercontent.com/EliasOulkadi/shokunin/master/.pack/telegram/bot.py"
        Invoke-WebRequest -Uri $url -OutFile (Join-Path $script:installDir "telegram\bot.py") -ErrorAction SilentlyContinue
    }

    # Copy healthcheck script
    $hcSrc = Join-Path $PSScriptRoot ".pack\scripts\weekly-healthcheck.ps1"
    if (Test-Path $hcSrc) {
        Copy-Item $hcSrc (Join-Path $script:installDir "scripts\weekly-healthcheck.ps1") -Force
    }

    Write-Log "Sistema de memoria instalado" Green
}

# ============================================================
# SECTION 6: TELEGRAM BOT SETUP
# ============================================================
function Setup-TelegramBot {
    Write-Step "Configurando Telegram bot..."

    $existingToken = [Environment]::GetEnvironmentVariable('TELEGRAM_BOT_TOKEN','User')
    if ($existingToken) {
        Write-Log "Token ya configurado (usando existente)" Green
        return
    }

    Write-Host @"

  Para el bot de Telegram necesitas crear uno gratis:
  1. Abre Telegram y busca @BotFather
  2. Envia /newbot y sigue las instrucciones
  3. COPIA EL TOKEN QUE TE DE (algo como 123456:ABCdef...)
  4. Pegalo abajo

"@ -ForegroundColor Yellow

    $token = Read-Host "  Token de Telegram (deja vacio para saltar)"
    if ($token) {
        [Environment]::SetEnvironmentVariable('TELEGRAM_BOT_TOKEN', $token, 'User')
        Write-Log "Token guardado" Green

        # Create startup shortcut
        $vbsPath = Join-Path $script:installDir "start-bot.vbs"
        @"
Set WshShell = CreateObject("WScript.Shell")
WshShell.Run "cmd /c python `"$(Join-Path $script:installDir "telegram\bot.py")`"", 0, False
"@ | Out-File -FilePath $vbsPath -Encoding ASCII -Force

        $shortcutPath = Join-Path $script:startupDir "ShokuninBot.lnk"
        $wshell = New-Object -ComObject WScript.Shell
        $shortcut = $wshell.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = "wscript.exe"
        $shortcut.Arguments = "`"$vbsPath`""
        $shortcut.Save()
        Write-Log "Auto-start creado (inicia con Windows)" Green
    } else {
        Write-Log "Telegram bot saltado. Ejecuta .shokunin\setup-telegram.ps1 mas tarde" Yellow
    }
}

# ============================================================
# SECTION 7: OPENCODE CONFIGURATION
# ============================================================
function Setup-OpenCodeConfig {
    Write-Step "Configurando OpenCode..."

    $configDir = "$env:USERPROFILE\.config\opencode"
    if (-not (Test-Path $configDir)) { New-Item -ItemType Directory -Path $configDir -Force | Out-Null }

    $configFile = Join-Path $configDir "opencode.json"
    if (Test-Path $configFile) {
        $backup = "$configFile.shokunin-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        Copy-Item $configFile $backup
        Write-Log "Backup de config existente: $backup" Green
    }

    # Generate config with proper paths
    $template = Get-Content (Join-Path $PSScriptRoot ".pack\opencode.json") -Raw
    $template = $template -replace "{{USERNAME}}", $env:USERNAME
    $template = $template -replace "YOUR_NVIDIA_API_KEY", "YOUR_NVIDIA_API_KEY"

    # Check for NVIDIA API key
    $nvKey = [Environment]::GetEnvironmentVariable('NVIDIA_API_KEY','User')
    if (-not $nvKey) {
        Write-Host @"

  Para la IA necesitas una API key gratis de NVIDIA:
  1. Ve a https://build.nvidia.com/ (registro gratis)
  2. Genera una API key
  3. Pegala abajo (o deja vacio para configurar despues)

"@ -ForegroundColor Yellow
        $nvKeyInput = Read-Host "  NVIDIA API Key (deja vacio para despues)"
        if ($nvKeyInput) {
            [Environment]::SetEnvironmentVariable('NVIDIA_API_KEY', $nvKeyInput, 'User')
            $template = $template -replace "YOUR_NVIDIA_API_KEY", $nvKeyInput
        }
    } else {
        $template = $template -replace "YOUR_NVIDIA_API_KEY", $nvKey
    }

    $template | Set-Content $configFile -Force
    Write-Log "Config generada: $configFile" Green
}

# ============================================================
# SECTION 8: POWERSSHELL PROFILE
# ============================================================
function Setup-PowerShellProfile {
    Write-Step "Configurando PowerShell profile..."

    $profileContent = @'
# Shokunin AI Ecosystem — PowerShell Profile
# Documentation: https://github.com/EliasOulkadi/shokunin

# Aliases — Git
Set-Alias -Name gst -Value "git status"
Set-Alias -Name ga -Value "git add -A"
Set-Alias -Name gc -Value "git commit -m"
Set-Alias -Name gp -Value "git push"
Set-Alias -Name gl -Value "git pull --ff-only"
Set-Alias -Name gb -Value "git branch"
Set-Alias -Name gco -Value "git checkout"

# Aliases — npm
Set-Alias -Name ni -Value "npm install"
Set-Alias -Name nrd -Value "npm run dev"
Set-Alias -Name nrb -Value "npm run build"
Set-Alias -Name nt -Value "npm test"

# Aliases — Docker
Set-Alias -Name dps -Value "docker ps"
Set-Alias -Name dlog -Value "docker logs -f"
Set-Alias -Name dstop -Value "docker stop"

# Aliases — Utils
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
    $token = [Environment]::GetEnvironmentVariable('TELEGRAM_BOT_TOKEN', 'User')
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

Write-Host "Shokunin AI Ecosystem loaded" -ForegroundColor Cyan
'@

    if (Test-Path $PROFILE) {
        $backup = "$PROFILE.shokunin-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        Copy-Item $PROFILE $backup
        Write-Log "Backup de perfil existente: $backup" Green

        # Append if not already installed
        $existing = Get-Content $PROFILE -Raw
        if ($existing -notmatch "Shokunin") {
            Add-Content $PROFILE "`n# Shokunin AI Ecosystem`n" -Encoding UTF8
            Add-Content $PROFILE $profileContent -Encoding UTF8
            Write-Log "Perfil actualizado (Shokunin anadido al final)" Green
        } else { Write-Log "Shokunin ya existe en el perfil" Yellow }
    } else {
        $profileDir = Split-Path $PROFILE -Parent
        if (-not (Test-Path $profileDir)) { New-Item -ItemType Directory -Path $profileDir -Force | Out-Null }
        $profileContent | Set-Content $PROFILE -Encoding UTF8 -Force
        Write-Log "Nuevo perfil creado" Green
    }
}

# ============================================================
# SECTION 9: CLAUDE.md / AGENTS.md
# ============================================================
function Setup-Instructions {
    Write-Step "Configurando instrucciones globales..."

    # CLAUDE.md
    $claudeDir = "$env:USERPROFILE\.claude"
    if (-not (Test-Path $claudeDir)) { New-Item -ItemType Directory -Path $claudeDir -Force | Out-Null }

    $claudeTemplate = Join-Path $PSScriptRoot ".pack\CLAUDE.md"
    if (Test-Path $claudeTemplate) {
        $claudeContent = Get-Content $claudeTemplate -Raw
        if (Test-Path "$claudeDir\CLAUDE.md") {
            $backup = "$claudeDir\CLAUDE.md.shokunin-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
            Copy-Item "$claudeDir\CLAUDE.md" $backup
        }
        $claudeContent | Set-Content "$claudeDir\CLAUDE.md" -Force -Encoding UTF8
        Write-Log "CLAUDE.md configurado" Green
    }

    # AGENTS.md
    $agentsTemplate = Join-Path $PSScriptRoot ".pack\AGENTS.md"
    if (Test-Path $agentsTemplate) {
        $agentsContent = Get-Content $agentsTemplate -Raw
        $agentsContent | Set-Content "$env:USERPROFILE\AGENTS.md" -Force -Encoding UTF8
        Write-Log "AGENTS.md configurado" Green
    }
}

# ============================================================
# SECTION 10: SCHEDULED TASKS
# ============================================================
function Setup-ScheduledTasks {
    Write-Step "Configurando tareas programadas..."

    $healthcheckScript = Join-Path $script:installDir "scripts\weekly-healthcheck.ps1"
    $taskName = "ShokuninWeeklyMaintenance"

    $existing = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if (-not $existing) {
        $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -File `"$healthcheckScript`""
        $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 21:00
        $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -RunLevel Limited
        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Force | Out-Null
        Write-Log "Tarea '$taskName' creada (domingos 21:00)" Green
    } else {
        Write-Log "Tarea '$taskName' ya existe" Yellow
    }
}

# ============================================================
# SECTION 11: EXTRAS (WezTerm, bookmarklet, dashboard)
# ============================================================
function Setup-Extras {
    Write-Step "Instalando herramientas adicionales..."

    # WezTerm config
    $weztermSrc = Join-Path $PSScriptRoot ".pack\wezterm.lua"
    if (Test-Path $weztermSrc) {
        if (-not (Test-Path "$env:USERPROFILE\.wezterm.lua")) {
            Copy-Item $weztermSrc "$env:USERPROFILE\.wezterm.lua" -Force
            Write-Log "WezTerm config: .wezterm.lua" Green
        } else { Write-Log "WezTerm config ya existe" Yellow }
    }

    # Bookmarklet
    $bmSrc = Join-Path $PSScriptRoot ".pack\bookmarklet.html"
    if (Test-Path $bmSrc) {
        Copy-Item $bmSrc "$env:USERPROFILE\shokunin-bookmarklet.html" -Force
        Write-Log "Bookmarklet: shokunin-bookmarklet.html" Green
    }

    # Dashboard
    $dbSrc = Join-Path $PSScriptRoot ".pack\dashboard.html"
    if (Test-Path $dbSrc) {
        Copy-Item $dbSrc "$env:USERPROFILE\shokunin-dashboard.html" -Force
        Write-Log "Dashboard: shokunin-dashboard.html" Green
    }
}

# ============================================================
# SECTION 12: FINAL SUMMARY
# ============================================================
function Show-Summary {
    Write-Host @"

╔══════════════════════════════════════════════════╗
║        Shokunin AI Ecosystem — Instalado         ║
╚══════════════════════════════════════════════════╝

  Skills:       $((Get-ChildItem $script:skillsDir -Directory).Count) instaladas
  Memoria:      ChromaDB en $script:installDir\memory
  Telegram:     $(if ([Environment]::GetEnvironmentVariable('TELEGRAM_BOT_TOKEN','User')) { 'Configurado' } else { 'PENDIENTE' })
  NVIDIA API:   $(if ([Environment]::GetEnvironmentVariable('NVIDIA_API_KEY','User')) { 'Configurada' } else { 'PENDIENTE' })
  PowerShell:   Perfil personalizado con aliases
  MCP:          filesystem, fetch, memory
  Auto-start:   Telegram bot al iniciar Windows
  Mantenimiento: Domingos 21:00 (backup + limpieza)
  Bookmarklet:  $env:USERPROFILE\shokunin-bookmarklet.html
  Dashboard:    $env:USERPROFILE\shokunin-dashboard.html

  COMANDOS RAPIDOS:
  opencode                    Iniciar OpenCode
  gst, ga, gc, gp, gl        Git aliases
  ni, nrd, nrb, nt           npm aliases
  dps, dlog, dstop           Docker aliases
  mkcd, touch, which, admin  Utilidades

  SIGUIENTES PASOS:
  1. Si dejaste la API de NVIDIA pendiente:
     [Environment]::SetEnvironmentVariable('NVIDIA_API_KEY','tu-key','User')
     y edita ~\.config\opencode\opencode.json con tu key

  2. Si dejaste Telegram pendiente:
     Crea un bot en @BotFather y guarda el token:
     [Environment]::SetEnvironmentVariable('TELEGRAM_BOT_TOKEN','tu-token','User')

  3. Abre un NUEVO terminal para cargar el perfil

  4. Ejecuta: opencode

  Mas informacion: https://github.com/EliasOulkadi/shokunin
"@ -ForegroundColor Cyan
}

# ============================================================
# MAIN
# ============================================================
Clear-Host
Write-Host @"
╔══════════════════════════════════════════════════╗
║         Shokunin AI Ecosystem v$script:version       ║
║         One-command installer                    ║
║         github.com/EliasOulkadi/shokunin         ║
╚══════════════════════════════════════════════════╝

  Este instalador configura tu PC como estacion de trabajo
  AI Engineer con 36 skills, memoria persistente, bot de
  Telegram, y automatizaciones — todo gratis y open source.

  Requiere: Windows 10/11, Node.js 18+, Python 3.11+
  Tiempo estimado: 2-5 minutos

"@ -ForegroundColor Cyan

$confirm = Read-Host "  Continuar? (s/n)"
if ($confirm -ne "s") { Write-Host "  Instalacion cancelada."; exit 0 }

$script:step = 1
Test-Prerequisites
Install-Dependencies
Install-Skills
Install-MemorySystem
Setup-OpenCodeConfig
Setup-TelegramBot
Setup-PowerShellProfile
Setup-Instructions
Setup-ScheduledTasks
Setup-Extras
Show-Summary

Write-Host "  Log de instalacion: $script:logFile" -ForegroundColor DarkGray
Write-Log "Instalacion completada. Abre un NUEVO terminal." Green
