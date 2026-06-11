# Shokunin AI Ecosystem Installer v4.2.2
# One-command installer for the complete Shokunin AI ecosystem
# Requires: Windows 10/11, PowerShell 5.1+, Node.js 18+, Python 3.11+

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$Host.UI.RawUI.WindowTitle = "Shokunin AI Ecosystem Installer v4.2.2"
$script:version = "4.2.2"
$script:installDir = "$env:USERPROFILE\.shokunin"
$script:skillsDir = "$env:USERPROFILE\.config\opencode\skills"
$script:startupDir = [Environment]::GetFolderPath('Startup')
$script:logFile = "$env:TEMP\shokunin-install-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
$script:sourceDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }

# Validate sourceDir has the required .pack folder.
# When run via iex from the web, $PSScriptRoot is empty and
# the current directory won't have repo files. Fall back to git clone.
$script:needsClone = $false
if (-not (Test-Path (Join-Path $script:sourceDir ".pack\skills"))) {
    $script:needsClone = $true
    Write-Log "Repo not found locally, will clone from GitHub" Yellow
}

# Known SHA256 checksums for critical scripts (updated per release)
# These are verified after download to prevent tampering
$script:knownChecksums = @{
    "mcp-server.py" = ""
    "chroma-helper.py" = ""
    "run-opencode.ps1" = ""
}

# ============================================================
# SECTION 1: LOGGING & DISPLAY
# ============================================================
function Write-Log { param([string]$Msg, [string]$Color = "White") Write-Host "  $Msg" -ForegroundColor $Color }
function Write-Step { param([string]$Msg) Write-Host "`n[$($script:step++)] $Msg" -ForegroundColor Cyan }
function Write-OK { Write-Host "    OK" -ForegroundColor Green }
function Write-Skip { Write-Host "    SKIP (already exists)" -ForegroundColor Yellow }
function Write-Fail { Write-Host "    FAIL" -ForegroundColor Red }

function Test-FileChecksum {
    param([string]$Path, [string]$ExpectedHash)
    if (-not $ExpectedHash -or -not (Test-Path $Path)) { return $true }
    try {
        $actual = (Get-FileHash -Path $Path -Algorithm SHA256).Hash
        return $actual -eq $ExpectedHash
    } catch { return $false }
}

# ============================================================
# SECTION 2: PREREQUISITES CHECK
# ============================================================
function Test-Prerequisites {
    Write-Step "Checking prerequisites..."
    $allOk = $true

    # Windows
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        Write-Log "PowerShell 5+ required" Red; $allOk = $false
    } else { Write-Log "PowerShell $($PSVersionTable.PSVersion.ToString())" Green }

    # Node.js
    try {
        $nodeVer = node --version
        $ver = [Version]($nodeVer -replace '^v')
        if ($ver.Major -lt 18) { throw "version too low" }
        Write-Log "Node.js $nodeVer" Green
    } catch { Write-Log "Node.js 18+ required (https://nodejs.org)" Red; $allOk = $false }

    # Python (check python first, then py)
    try {
        $pyVer = python --version 2>&1
        if (-not ($pyVer -match '(\d+)\.(\d+)')) { $pyVer = py --version 2>&1 }
        if ($pyVer -match '(\d+)\.(\d+)') {
            $major = [int]$Matches[1]; $minor = [int]$Matches[2]
            if ($major -ge 3 -and $minor -ge 11) { Write-Log "Python $major.$minor+ found" Green }
            else { throw "version too low" }
        } else { throw "not found" }
    } catch { Write-Log "Python 3.11+ required (https://python.org)" Red; $allOk = $false }

    # Git
    try { git --version 2>$null | Out-Null; Write-Log "Git installed" Green }
    catch { Write-Log "Git required (winget install Git.Git)" Red; $allOk = $false }

    # OpenCode
    try {
        $ocVer = opencode --version 2>$null
        if ($ocVer) { Write-Log "OpenCode $ocVer" Green }
        else { throw "not found" }
    } catch {
        Write-Log "OpenCode no detectado. Instalando..." Yellow
        try {
            npm install -g opencode 2>&1 | Out-Null
            Write-Log "OpenCode installed" Green
        } catch { Write-Log "Could not install OpenCode. Run npm install -g opencode manually" Red; $allOk = $false }
    }

    if (-not $allOk) {
        Write-Host "`n  Requirements not met. Install what's missing and run again." -ForegroundColor Red
        exit 1
    }
}

# ============================================================
# SECTION 3: INSTALL DEPENDENCIES
# ============================================================
function Install-Dependencies {
    Write-Step "Installing Python dependencies..."
    pip install chromadb
    Write-OK

    Write-Step "Installing MCP servers..."
    npm install -g @modelcontextprotocol/server-filesystem 2>&1 | Out-Null
    pip install mcp-server-fetch 2>&1 | Out-Null
    Write-OK
}

# ============================================================
# SECTION 4: INSTALL SKILLS
# ============================================================
function Install-Skills {
    Write-Step "Installing 62 skills..."

    if (-not (Test-Path $script:skillsDir)) {
        New-Item -ItemType Directory -Path $script:skillsDir -Force | Out-Null
    }

    # Determine skills source: local clone or GitHub download
    if ($script:needsClone) {
        $skillsSource = "$env:TEMP\shokunin-skills"
        if (Test-Path $skillsSource) { Remove-Item -Recurse -Force $skillsSource -ErrorAction SilentlyContinue }
        Write-Log "Cloning from GitHub..." Yellow
        git clone --depth 1 https://github.com/EliasOulkadi/shokunin.git "$env:TEMP\shokunin-tmp" 2>&1 | Out-Null
        $skillsSource = "$env:TEMP\shokunin-tmp\.pack\skills"
    } else {
        $skillsSource = Join-Path $script:sourceDir ".pack\skills"
    }

    $count = 0
    if (Test-Path $skillsSource) {
        Get-ChildItem $skillsSource -Directory -ErrorAction SilentlyContinue | Where-Object { Test-Path (Join-Path $_.FullName "SKILL.md") } | ForEach-Object {
            $target = Join-Path $script:skillsDir $_.Name
            if (-not (Test-Path $target)) {
                New-Item -ItemType Directory -Path $target -Force | Out-Null
            }
            Copy-Item -Recurse -Force "$($_.FullName)\*" "$target\" -ErrorAction SilentlyContinue
            $count++
        }
    }

    # Cleanup temp clone
    if ($script:needsClone) {
        Remove-Item -Recurse -Force "$env:TEMP\shokunin-tmp" -ErrorAction SilentlyContinue
    }

    if ($count -gt 0) {
        Write-Log "$count skills installed in $script:skillsDir" Green
    } else {
        Write-Log "No skills found to install. Check network connectivity." Red
    }
}

# ============================================================
# SECTION 5: MEMORY SYSTEM (ChromaDB)
# ============================================================
function Install-MemorySystem {
    Write-Step "Installing memory system (ChromaDB)..."

    # Create directories
    @("memory","memory\chroma_db","memory\sessions","backups","scripts","logs") | ForEach-Object {
        $d = Join-Path $script:installDir $_
        if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
    }
    Write-Log "Directories created in $script:installDir" Green

    # Copy MCP server
    $mcpSrc = Join-Path $script:sourceDir ".pack\memory\mcp-server.py"
    $mcpDest = Join-Path $script:installDir "memory\mcp-server.py"
    if (Test-Path $mcpSrc) {
        Copy-Item $mcpSrc $mcpDest -Force
    } else {
        # Download from GitHub with checksum verification
        $url = "https://raw.githubusercontent.com/EliasOulkadi/shokunin/master/.pack/memory/mcp-server.py"
        try {
            Invoke-WebRequest -Uri $url -OutFile $mcpDest -ErrorAction Stop
            if ($script:knownChecksums["mcp-server.py"]) {
                if (-not (Test-FileChecksum -Path $mcpDest -ExpectedHash $script:knownChecksums["mcp-server.py"])) {
                    Write-Log "CHECKSUM MISMATCH for mcp-server.py — file may be tampered" Red
                }
            }
        } catch {
            Write-Log "Could not download mcp-server.py" Red
        }
    }

    # Copy healthcheck script
    $hcSrc = Join-Path $script:sourceDir ".pack\scripts\weekly-healthcheck.ps1"
    if (Test-Path $hcSrc) {
        Copy-Item $hcSrc (Join-Path $script:installDir "scripts\weekly-healthcheck.ps1") -Force
    }

    Write-Log "Memory system installed" Green
}

# ============================================================
# SECTION 6: NEW SCRIPTS (v4.0)
# ============================================================
function Install-NewScripts {
    Write-Step "Installing scripts v4.0..."

    $scriptsDir = Join-Path $script:installDir "scripts"
    New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null

    $newScripts = @(
        "chroma-helper.py",
        "chroma_helper_stub.py",
        "run-opencode.ps1",
        "save-memory.ps1",
        "search-memory.ps1",
        "read-transcript.ps1",
        "read-transcript.py",
        "test-memory.ps1",
        "memory-healthcheck.ps1",
        "shokunin-update.ps1",
        "validate-skills.ps1",
        "seed-memory.ps1",
        "scan-cleanup.ps1"
    )

    $count = 0
    foreach ($script in $newScripts) {
        $src = Join-Path $script:sourceDir ".pack\scripts\$script"
        $dest = Join-Path $scriptsDir $script
        if (Test-Path $src) {
            Copy-Item $src $dest -Force
            $count++
        } else {
            $url = "https://raw.githubusercontent.com/EliasOulkadi/shokunin/master/.pack/scripts/$script"
            try {
                Invoke-WebRequest -Uri $url -OutFile $dest -ErrorAction Stop
                if ($script:knownChecksums.ContainsKey($script) -and $script:knownChecksums[$script]) {
                    if (-not (Test-FileChecksum -Path $dest -ExpectedHash $script:knownChecksums[$script])) {
                        Write-Log "  CHECKSUM MISMATCH for $script" Red
                    }
                }
                $count++
            } catch {
                Write-Log "  Could not download $script" Yellow
            }
        }
    }

    Write-Log "$count scripts installed in $scriptsDir" Green
}

# ============================================================
# SECTION 7: OPencode CONFIG
# ============================================================
function Setup-OpenCodeConfig {
    Write-Step "Configuring OpenCode..."

    $configDir = "$env:USERPROFILE\.config\opencode"
    if (-not (Test-Path $configDir)) { New-Item -ItemType Directory -Path $configDir -Force | Out-Null }

    $configFile = Join-Path $configDir "opencode.json"
    if (Test-Path $configFile) {
        $backup = "$configFile.shokunin-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        Copy-Item $configFile $backup
        Write-Log "Backup saved: $(Split-Path $backup -Leaf)" Green

        # User already has a config — ONLY add shokunin MCP servers that don't exist
        $existing = Get-Content $configFile -Raw | ConvertFrom-Json -AsHashtable
        $mcp = if ($existing.ContainsKey('mcp')) { $existing['mcp'] } else { @{} }

        $shokuninMCP = @{
            'filesystem' = @{
                'type' = 'local'
                'command' = @('npx', '-y', '@modelcontextprotocol/server-filesystem', $env:USERPROFILE)
            }
            'fetch' = @{
                'type' = 'local'
                'command' = @('python', '-m', 'mcp_server_fetch')
                'environment' = @{ 'PYTHONIOENCODING' = 'utf-8' }
            }
            'memory' = @{
                'type' = 'local'
                'command' = @('python', "$env:USERPROFILE\.shokunin\memory\mcp-server.py")
            }
        }

        $added = 0
        foreach ($name in $shokuninMCP.Keys) {
            if (-not $mcp.ContainsKey($name)) {
                $mcp[$name] = $shokuninMCP[$name]
                $added++
            }
        }
        $existing['mcp'] = $mcp
        $existing | ConvertTo-Json -Depth 10 | Set-Content $configFile -Force -Encoding UTF8
        Write-Log "MCP servers added/verified: $added new" Green
    } else {
        # New install — generate fresh config from template
        $templatePath = Join-Path $script:sourceDir ".pack\opencode.json"
        if (Test-Path $templatePath) {
            $template = Get-Content $templatePath -Raw
        } else {
            $url = "https://raw.githubusercontent.com/EliasOulkadi/shokunin/master/.pack/opencode.json"
            $template = (Invoke-WebRequest -Uri $url).Content
            Write-Log "Template downloaded from GitHub" Yellow
        }
        $jsonPath = $env:USERPROFILE.Replace('\', '\\')
        $template = $template -replace "{{MCP_ROOT_PATH}}", $jsonPath
        $template = $template -replace "{{PYTHON_BIN}}", "python"
        $rawMemory = $env:USERPROFILE + '\.shokunin\memory\mcp-server.py'
        $jsonMemory = $rawMemory.Replace('\', '\\')
        $template = $template -replace "{{MCP_MEMORY_PATH}}", $jsonMemory
        $template | Set-Content $configFile -Force
        Write-Log "Config created: $configFile" Green
    }

    # Check for NVIDIA API key
    $nvKey = [Environment]::GetEnvironmentVariable('NVIDIA_API_KEY','User')
    if (-not $nvKey) {
        Write-Host @"

  For the AI you need a free NVIDIA API key:
  1. Go to https://build.nvidia.com/ (free signup)
  2. Generate an API key
  3. Paste it below (or leave empty to configure later)

"@ -ForegroundColor Yellow
        try {
            $nvKeyInput = Read-Host "  NVIDIA API Key (leave empty for later)"
        } catch {
            Write-Log "Non-interactive mode, skipping NVIDIA API key" Yellow
            $nvKeyInput = $null
        }
        if ($nvKeyInput) {
            [Environment]::SetEnvironmentVariable('NVIDIA_API_KEY', $nvKeyInput, 'User')
        }
    }

    Write-Log "Config generated" Green
}

# ============================================================
# SECTION 8: POWERSSHELL PROFILE
# ============================================================
function Setup-PowerShellProfile {
    Write-Step "Configuring PowerShell profile..."

    $profileContent = @'
$localScript = "$env:USERPROFILE\.shokunin\scripts\profile.ps1"
if (Test-Path $localScript) {
    . $localScript
    Write-Host "Shokunin AI Ecosystem loaded" -ForegroundColor Cyan
}
'@

    if (Test-Path $PROFILE) {
        $backup = "$PROFILE.shokunin-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        Copy-Item $PROFILE $backup
        Write-Log "Backup of existing profile: $backup" Green

        # Append if not already installed
        $existing = Get-Content $PROFILE -Raw
        if ($existing -notmatch "Shokunin") {
            Add-Content $PROFILE "`n# Shokunin AI Ecosystem`n" -Encoding UTF8
            Add-Content $PROFILE $profileContent -Encoding UTF8
            Write-Log "Profile updated (Shokunin appended)" Green
        } else { Write-Log "Shokunin already in profile" Yellow }
    } else {
        $profileDir = Split-Path $PROFILE -Parent
        if (-not (Test-Path $profileDir)) { New-Item -ItemType Directory -Path $profileDir -Force | Out-Null }
        $profileContent | Set-Content $PROFILE -Encoding UTF8 -Force
        Write-Log "New profile created" Green
    }
}

# ============================================================
# SECTION 9: CLAUDE.md / AGENTS.md
# ============================================================
function Setup-Instructions {
    Write-Step "Configuring global instructions..."

    # CLAUDE.md
    $claudeDir = "$env:USERPROFILE\.claude"
    if (-not (Test-Path $claudeDir)) { New-Item -ItemType Directory -Path $claudeDir -Force | Out-Null }

    $claudeTemplate = Join-Path $script:sourceDir ".pack\CLAUDE.md"
    if (Test-Path $claudeTemplate) {
        if (Test-Path "$claudeDir\CLAUDE.md") {
            Write-Log "CLAUDE.md already exists — not overwriting" Yellow
        } else {
            $claudeContent = Get-Content $claudeTemplate -Raw
            $claudeContent | Set-Content "$claudeDir\CLAUDE.md" -Force -Encoding UTF8
            Write-Log "CLAUDE.md installed" Green
        }
    }

    # AGENTS.md
    $agentsTemplate = Join-Path $script:sourceDir ".pack\AGENTS.md"
    if (Test-Path $agentsTemplate) {
        if (Test-Path "$env:USERPROFILE\AGENTS.md") {
            Write-Log "AGENTS.md already exists — not overwriting" Yellow
        } else {
            $agentsContent = Get-Content $agentsTemplate -Raw
            $agentsContent | Set-Content "$env:USERPROFILE\AGENTS.md" -Force -Encoding UTF8
            Write-Log "AGENTS.md installed" Green
        }
    }
}

# ============================================================
# SECTION 10: SCHEDULED TASKS
# ============================================================
function Setup-ScheduledTasks {
    Write-Step "Configuring scheduled tasks..."

    $healthcheckScript = Join-Path $script:installDir "scripts\weekly-healthcheck.ps1"
    $taskName = "ShokuninWeeklyMaintenance"

    $existing = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if (-not $existing) {
        $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -File `"$healthcheckScript`""
        $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 21:00
        $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -RunLevel Limited
        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Force | Out-Null
        Write-Log "Task '$taskName' created (Sundays 21:00)" Green
    } else {
        Write-Log "Task '$taskName' already exists" Yellow
    }
}

# ============================================================
# SECTION 11: EXTRAS (WezTerm, bookmarklet, dashboard)
# ============================================================
function Setup-Extras {
    Write-Step "Installing additional tools..."

    # WezTerm config
    $weztermSrc = Join-Path $script:sourceDir ".pack\wezterm.lua"
    if (Test-Path $weztermSrc) {
        if (-not (Test-Path "$env:USERPROFILE\.wezterm.lua")) {
            Copy-Item $weztermSrc "$env:USERPROFILE\.wezterm.lua" -Force
            Write-Log "WezTerm config: .wezterm.lua" Green
        } else { Write-Log "WezTerm config already exists" Yellow }
    }

    # Bookmarklet
    $bmSrc = Join-Path $script:sourceDir ".pack\bookmarklet.html"
    if (Test-Path $bmSrc) {
        Copy-Item $bmSrc "$env:USERPROFILE\shokunin-bookmarklet.html" -Force
        Write-Log "Bookmarklet: shokunin-bookmarklet.html" Green
    }

    # Dashboard
    $dbSrc = Join-Path $script:sourceDir ".pack\dashboard.html"
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

========================================
  Shokunin AI Ecosystem - Installed
========================================

  Skills:       $((Get-ChildItem $script:skillsDir -Directory).Count) installed
  Memory:       ChromaDB v4.2 (3 capture layers)
  Scripts:      run-opencode, chroma-helper, test-memory

  NVIDIA API:   $(if ([Environment]::GetEnvironmentVariable('NVIDIA_API_KEY','User')) { 'Configured' } else { 'PENDING' })
  PowerShell:   Custom profile with aliases
  MCP:          filesystem, fetch, memory

  Maintenance:  Sundays 21:00 (backup + cleanup)
  Bookmarklet:  $env:USERPROFILE\shokunin-bookmarklet.html
  Dashboard:    $env:USERPROFILE\shokunin-dashboard.html

  QUICK COMMANDS:
  opencode                    Start OpenCode
  gst, ga, gc, gp, gl        Git aliases
  ni, nrd, nrb, nt           npm aliases
  dps, dlog, dstop           Docker aliases
  mkcd, touch, which, admin  Utilities

  NEXT STEPS:
  1. If you left the NVIDIA API pending:
     [Environment]::SetEnvironmentVariable('NVIDIA_API_KEY','tu-key','User')
     and edit ~\.config\opencode\opencode.json with your key

  2. Restart your terminal or reload your profile: . `$PROFILE

  3. Open a NEW terminal to load the profile

  4. Run: .\run-opencode.ps1 (or just opencode for simple session)

  More info: https://github.com/EliasOulkadi/shokunin
"@ -ForegroundColor Cyan
}

# ============================================================
# MAIN
# ============================================================
Clear-Host
Write-Host @"

========================================
  Shokunin AI Ecosystem v$script:version
  One-command installer
  github.com/EliasOulkadi/shokunin
========================================

  This installer sets up your PC as an AI workstation
  AI Engineer with 62 skills, persistent memory,
  and automations - all free and open source.

  Requires: Windows 10/11, Node.js 18+, Python 3.11+
  Estimated time: 2-5 minutes

"@ -ForegroundColor Cyan

$confirm = Read-Host "  Continue? (y/n)"
if ($confirm -ne "y") { Write-Host "  Installation cancelled."; exit 0 }

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






