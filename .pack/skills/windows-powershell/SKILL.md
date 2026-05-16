---
name: windows-powershell
description: Windows 11 system administration with PowerShell — system info reporting, hardware monitoring, package management (winget/scoop), disk cleanup, performance optimization, environment configuration, PowerShell profile setup with aliases and autocomplete, and Task Scheduler automation. Use when user asks to check system info, install tools on Windows, clean up disk space, set up PowerShell profile, or automate Windows tasks. Do NOT use for Linux administration, cross-platform scripting, or network infrastructure management.
license: MIT
compatibility: opencode
metadata:
  workflow: operations
  audience: developers
  version: "3.0"
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
Copy-Item "$env:USERPROFILE\.config\opencode\skills\windows-powershell\assets\Microsoft.PowerShell_profile.ps1" $PROFILE

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
schtasks /Create /SC WEEKLY /D SUN /TN "SystemCleanup" /TR "powershell.exe -File '$env:USERPROFILE\.config\opencode\skills\windows-powershell\scripts\cleanup-system.ps1'" /ST 21:00 /RL HIGHEST
```

## Windows Utilities Reference

See [references/powershell-mastery.md](references/powershell-mastery.md) for complete reference.

| Task | Command |
|------|---------|
| Find large files | `Get-ChildItem -Recurse | Sort-Object Length -Descending | Select-Object -First 20` |
| Kill process by port | `Get-Process -Id (Get-NetTCPConnection -LocalPort 3000).OwningProcess | Stop-Process` |
| Check disk health | `Get-PhysicalDisk | Get-HealthStatus` |
| Export installed programs | `Get-WmiObject Win32_Product | Export-Csv installed.csv` |
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

## Sources

- Microsoft PowerShell docs (learn.microsoft.com/powershell)
- Oh My Posh docs (ohmyposh.dev)
- PSReadLine docs (learn.microsoft.com)
- Windows Package Manager (winget) docs
- Scoop package manager (scoop.sh)
- SS64 PowerShell commands reference
