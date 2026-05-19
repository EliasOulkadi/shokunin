---
name: windows-powershell
description: Windows 11 system administration with PowerShell — system info reporting, hardware monitoring, package management (winget/scoop), disk cleanup, performance optimization, environment configuration, PowerShell profile setup with aliases and autocomplete, and Task Scheduler automation. Use when user asks to check system info, install tools on Windows, clean up disk space, set up PowerShell profile, or automate Windows tasks. Do NOT use for Linux administration, cross-platform scripting, or network infrastructure management.
triggers:
  - "PowerShell"
  - "Windows"
  - "system info"
  - "winget"
  - "scoop"
  - "Chocolatey"
  - "disk cleanup"
  - "Windows optimization"
  - "environment variables"
  - "Windows profile"
  - "PowerShell profile"
  - "Task Scheduler"
  - "Windows 11"
  - "install tool Windows"
negatives:
  - "Linux"
  - "macOS"
  - "bash"
  - "cross-platform"
  - "WSL"
  - "Linux administration"
license: MIT
compatibility: opencode
metadata:
  workflow: operations
  audience: developers
  version: "3.0.0"
  author: shokunin
allowed-tools: Read Bash Write
---


# Windows PowerShell

Windows 11 system administration and automation with PowerShell 7.

## Workflow

### Step 1: System health check

```powershell
scripts/system-info.ps1
```

Outputs:
- **OS**: Windows 11 build, edition, install date
- **CPU**: Model, cores, current usage %
- **RAM**: Total, used, free, usage %
- **Disk**: Per drive: total, used, free, usage %
- **Top 5 processes** by memory usage
- **Network**: Adapters, IP addresses
- **Uptime**: Days since last restart
- **Windows Updates**: Pending update count

**If RAM usage > 80%** or **disk usage > 90%**: proceed to Step 2.

### Step 2: System cleanup

```powershell
# Preview what would be cleaned
scripts/cleanup-system.ps1 -DryRun

# Clean everything
scripts/cleanup-system.ps1
```

Cleans:
- Windows temporary files
- Recycle Bin
- Windows Update cache
- npm/yarn/pnpm cache
- Docker unused data
- Windows.old (if present)
- Prefetch files

Reports total space recovered.

### Step 3: Install development tools

```powershell
# Install everything
scripts/install-tools.ps1

# Install specific categories only
scripts/install-tools.ps1 -Scope dev  # Git, Node, Python, VS Code
scripts/install-tools.ps1 -Scope tools  # 7-Zip, Windows Terminal, Oh My Posh
```

The script checks if each tool is already installed before attempting. Uses `winget` as primary, falls back to `scoop`.

### Step 4: Set up PowerShell profile

Copy the premium profile template:
```powershell
# Install the premium profile
Copy-Item "~\\.config\\opencode\\skills\\windows-powershell\\assets\\Microsoft.PowerShell_profile.ps1" $PROFILE

# Reload profile
. $PROFILE
```

The profile includes:
- **Oh My Posh** prompt with git status
- **PSReadLine** with autocomplete and syntax highlighting
- **Git aliases**: `gst` (status), `ga` (add), `gc` (commit), `gp` (push), `gl` (pull), `gb` (branch)
- **npm aliases**: `ni` (install), `nrd` (run dev), `nrb` (run build), `nt` (test)
- **Docker aliases**: `dps` (ps), `dlog` (logs), `dstop` (stop), `drm` (rm)
- **Utils**: `touch`, `which`, `ll` (ls -la), `mkcd` (mkdir + cd), `admin` (runas admin)

### Step 5: Schedule recurring maintenance

```powershell
# Weekly cleanup every Sunday at 9 PM
schtasks /Create /SC WEEKLY /D SUN /TN "SystemCleanup" /TR "powershell.exe -File '~\\.config\\opencode\\skills\\windows-powershell\\scripts\\cleanup-system.ps1'" /ST 21:00 /RL HIGHEST
```

## Windows Utilities Reference

See [references/powershell-mastery.md](references/powershell-mastery.md) for complete reference.

| Task | Command |
|------|---------|
| Find large files | `Get-ChildItem -Recurse | Sort-Object Length -Descending | Select-Object -First 20` |
| Kill process by port | `Get-Process -Id (Get-NetTCPConnection -LocalPort 3000).OwningProcess | Stop-Process` |
| Check disk health | `Get-PhysicalDisk | Get-HealthStatus` |
| Export installed programs | `Get-Package | Export-Csv installed.csv` |
| Check battery health | `powercfg /batteryreport` |
| Network speed test | `Invoke-WebRequest -Uri "http://speedtest.url"` |
| Windows activation status | `slmgr /xpr` |

## Error Handling

| Scenario | Cause | Fix |
|----------|-------|-----|
| `winget` not found | Outdated Windows or missing App Installer | Install from Microsoft Store or use scoop |
| Script execution blocked | PowerShell execution policy | `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser` |
| Permission denied running script | Not admin for system operations | Run `admin` (from profile) or `Start-Process powershell -Verb RunAs` |
| Cleanup shows 0 bytes | No temp files to clean | That's fine. Run again in a week. |
| Tool installation fails | winget source out of date | `winget source update` |

## Production Checklist

- [ ] PowerShell 7 installed (`$PSVersionTable.PSVersion`)
- [ ] Execution policy set to RemoteSigned
- [ ] PowerShell profile installed with aliases
- [ ] Dev tools installed via winget/scoop
- [ ] Weekly cleanup scheduled
- [ ] System info script run monthly
- [ ] Battery report generated (laptops)
- [ ] Windows Updates checked

## Anti-Patterns

| Anti-pattern | Fix |
|-------------|-----|
| Installing tools manually every time | Use winget/scoop with install-tools script |
| Ignoring temp file buildup | Schedule weekly cleanup |
| Default PowerShell prompt | Customize with Oh My Posh |
| No aliases for common commands | Use the profile template |
| Running without admin when needed | Use `admin` alias for elevated commands |

## Advanced Patterns

### Desired State Configuration (DSC)

```powershell
Configuration WebServer {
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Node "localhost" {
        WindowsFeature IIS { Name = "Web-Server"; Ensure = "Present" }
        File WebContent {
            Ensure = "Present"
            SourcePath = "C:\inetpub\wwwroot"
            DestinationPath = "C:\inetpub\wwwroot"
            DependsOn = "[WindowsFeature]IIS"
        }
    }
}
WebServer -OutputPath C:\DSC
Start-DscConfiguration -Path C:\DSC -Wait -Verbose
```

### Just Enough Administration (JEA)

```powershell
# Create a restricted endpoint that only allows Get-Service + Restart-Service
New-PSSessionConfigurationFile -Path .\HelpDesk.pssc -SessionType RestrictedRemoteServer `
    -VisibleCmdlets @{ Name = 'Get-Service'; Parameters = @{ Name = 'Name' }},
                    @{ Name = 'Restart-Service'; Parameters = @{ Name = 'Name' }}
Register-PSSessionConfiguration -Name HelpDesk -Path .\HelpDesk.pssc -Force
```

### PSRemoting

```powershell
# Enable on target machine (admin)
Enable-PSRemoting -Force
Set-Item WSMan:\localhost\Client\TrustedHosts -Value "192.168.1.100"

# Connect from source
$session = New-PSSession -ComputerName 192.168.1.100 -Credential (Get-Credential)
Invoke-Command -Session $session -ScriptBlock { Get-Process }
Remove-PSSession $session
```

### Script Signing

```powershell
# Generate self-signed certificate
$cert = New-SelfSignedCertificate -Subject "CN=PowerShell Code Signing" -Type CodeSigningCert -CertStoreLocation Cert:\CurrentUser\My

# Sign a script
Set-AuthenticodeSignature -FilePath .\script.ps1 -Certificate $cert

# Verify
Get-AuthenticodeSignature .\script.ps1

# Enforce in session
Set-ExecutionPolicy AllSigned -Scope Process
```

### Module Manifests

```powershell
New-ModuleManifest -Path .\MyModule.psd1 -RootModule MyModule.psm1 -Author "YourName" `
    -CompanyName "Company" -Description "Module description" -PowerShellVersion "5.1" `
    -FunctionsToExport @("Get-Data","Set-Data") -RequiredModules @("Az","SqlServer")
```

### Error Handling Patterns

```powershell
# Pattern 1: Try/Catch/Finally with resource cleanup
try {
    $conn = New-Object System.Data.SqlClient.SqlConnection($connString)
    $conn.Open()
    # Work
} catch [System.Data.SqlClient.SqlException] {
    Write-Error "Database error: $_"
} catch {
    Write-Error "Unexpected: $_"
} finally {
    if ($conn) { $conn.Dispose() }
}

# Pattern 2: -ErrorAction with $ErrorActionPreference
Get-ChildItem -Path $path -ErrorAction Stop
# or globally
$ErrorActionPreference = "Stop"

# Pattern 3: $LASTEXITCODE for native commands
& python script.py
if ($LASTEXITCODE -ne 0) {
    throw "Python script failed with exit code $LASTEXITCODE"
}

# Pattern 4: $? for PowerShell commands
Get-Item $path -ErrorAction SilentlyContinue
if (-not $?) {
    Write-Warning "Path not found, using default"
}
```

## Related Scripts

- `~/.shokunin/scripts/scan-cleanup.ps1` — Scans Downloads, Desktop, and Temp for files to classify (keep/review/trash) and optionally clean

## Sources

- Microsoft PowerShell docs (learn.microsoft.com/powershell)
- Oh My Posh docs (ohmyposh.dev)
- PSReadLine docs (learn.microsoft.com)
- Windows Package Manager (winget) docs
- Scoop package manager (scoop.sh)
- SS64 PowerShell commands reference

## Checklist

- [ ] Skill loads without errors in the AI agent
- [ ] YAML frontmatter is valid (description, compatibility, audience)
- [ ] Workflow section provides clear step-by-step instructions
- [ ] Error handling section covers common failure modes
- [ ] All referenced files (references/, scripts/, assets/) exist
- [ ] Skill triggers correctly for intended use cases
- [ ] No broken links or missing resources
