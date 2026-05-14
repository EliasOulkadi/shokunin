<#
.SYNOPSIS
    Shokunin AI Ecosystem Installer v3.1
.DESCRIPTION
    One-command installer for the complete Shokunin AI ecosystem:
    35 skills, MCP servers, ChromaDB memory, terminal configs
.NOTES
    Requires: Windows 10/11, PowerShell 5.1+, Node.js 18+, Python 3.11+
    Run: irm https://raw.githubusercontent.com/EliasOulkadi/shokunin/master/install.ps1 | iex
#>

$ErrorActionPreference = "Stop"
$Host.UI.RawUI.WindowTitle = "Shokunin AI Ecosystem Installer v4.0"
$script:version = "4.0.0"
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

    # Python (check python first, then py)
    try {
        $pyVer = python --version 2>&1
        if (-not ($pyVer -match '(\d+)\.(\d+)')) { $pyVer = py --version 2>&1 }
        if ($pyVer -match '(\d+)\.(\d+)') {
            $major = [int]$Matches[1]; $minor = [int]$Matches[2]
            if ($major -ge 3 -and $minor -ge 11) { Write-Log "Python $major.$minor+ encontrado" Green }
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
    pip install chromadb
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
    @("memory","memory\chroma_db","memory\sessions","backups","scripts","logs") | ForEach-Object {
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
# SECTION 6: NEW SCRIPTS (v4.0)
# ============================================================
function Install-NewScripts {
    Write-Step "Instalando scripts v4.0..."

    $scriptsDir = Join-Path $script:installDir "scripts"
    New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null

    $newScripts = @(
        "chroma-helper.py",
        "run-opencode.ps1",
        "save-memory.ps1",
        "search-memory.ps1",
        "read-transcript.ps1",
        "test-memory.ps1"
    )

    $count = 0
    foreach ($script in $newScripts) {
        $src = Join-Path $PSScriptRoot ".pack\scripts\$script"
        if (Test-Path $src) {
            Copy-Item $src (Join-Path $scriptsDir $script) -Force
            $count++
        } else {
            $url = "https://raw.githubusercontent.com/EliasOulkadi/shokunin/master/.pack/scripts/$script"
            try {
                Invoke-WebRequest -Uri $url -OutFile (Join-Path $scriptsDir $script) -ErrorAction SilentlyContinue
                $count++
            } catch {
                Write-Log "  No se pudo descargar $script" Yellow
            }
        }
    }

    Write-Log "$count scripts instalados en $scriptsDir" Green
}

# ============================================================
# SECTION 7: OPencode CONFIG
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
# Shokunin AI Ecosystem â€” PowerShell Profile
# Documentation: https://github.com/EliasOulkadi/shokunin

# Aliases â€” Git
Set-Alias -Name gst -Value "git status"
Set-Alias -Name ga -Value "git add -A"
Set-Alias -Name gc -Value "git commit -m"
Set-Alias -Name gp -Value "git push"
Set-Alias -Name gl -Value "git pull --ff-only"
Set-Alias -Name gb -Value "git branch"
Set-Alias -Name gco -Value "git checkout"

# Aliases â€” npm
Set-Alias -Name ni -Value "npm install"
Set-Alias -Name nrd -Value "npm run dev"
Set-Alias -Name nrb -Value "npm run build"
Set-Alias -Name nt -Value "npm test"

# Aliases â€” Docker
Set-Alias -Name dps -Value "docker ps"
Set-Alias -Name dlog -Value "docker logs -f"
Set-Alias -Name dstop -Value "docker stop"

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

â•”â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•—
â•‘        Shokunin AI Ecosystem â€” Instalado         â•‘
â•šâ•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  Skills:       $((Get-ChildItem $script:skillsDir -Directory).Count) instaladas
  Memoria:      ChromaDB v4.0 (3 capas de captura)
  Scripts:      run-opencode, chroma-helper, test-memory

  NVIDIA API:   $(if ([Environment]::GetEnvironmentVariable('NVIDIA_API_KEY','User')) { 'Configurada' } else { 'PENDIENTE' })
  PowerShell:   Perfil personalizado con aliases
  MCP:          filesystem, fetch, memory

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


     Crea un bot en @BotFather y guarda el token:
     

  3. Abre un NUEVO terminal para cargar el perfil

  4. Ejecuta: .\run-opencode.ps1 (o solo opencode para sesion simple)

  Mas informacion: https://github.com/EliasOulkadi/shokunin
"@ -ForegroundColor Cyan
}

# ============================================================
# MAIN
# ============================================================
Clear-Host
Write-Host @"
â•”â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•—
â•‘         Shokunin AI Ecosystem v$script:version       â•‘
â•‘         One-command installer                    â•‘
â•‘         github.com/EliasOulkadi/shokunin         â•‘
â•šâ•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  Este instalador configura tu PC como estacion de trabajo
  AI Engineer con 36 skills, memoria persistente, bot de
  Telegram, y automatizaciones â€” todo gratis y open source.

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
Install-NewScripts
Setup-OpenCodeConfig
Setup-PowerShellProfile
Setup-Instructions
Setup-ScheduledTasks
Setup-Extras
Show-Summary



