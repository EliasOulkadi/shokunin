# PowerShell Mastery Reference

## 1. Profile Locations

`$PROFILE` resolves to different paths depending on scope. The `$PROFILE` variable is an automatic variable pointing to the **current user, current host** profile.

| Variable                      | Path                                                              | Scope      |
|-------------------------------|-------------------------------------------------------------------|------------|
| `$PROFILE`                    | `$HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1`     | Current user, PowerShell 7 |
| `$PROFILE.CurrentUserAllHosts` | `$HOME\Documents\PowerShell\profile.ps1`                         | Current user, all hosts    |
| `$PROFILE.AllUsersCurrentHost`  | `$PROGRAMFILES\PowerShell\7\Microsoft.PowerShell_profile.ps1`   | All users, PowerShell 7    |
| `$PROFILE.AllUsersAllHosts`     | `$PROGRAMFILES\PowerShell\7\profile.ps1`                        | All users, all hosts       |

Windows PowerShell (5.1) paths use `$HOME\Documents\WindowsPowerShell\` instead.

```powershell
# Create profile if missing
if (-not (Test-Path $PROFILE)) {
  New-Item -Path $PROFILE -ItemType File -Force
}
```

## 2. Module Management

```powershell
# List installed modules
Get-Module -ListAvailable

# Install from PowerShell Gallery
Install-Module -Name Pester -Force -Scope CurrentUser

# Install for all users (admin)
Install-Module -Name Pester -Force -Scope AllUsers

# Import module
Import-Module -Name Pester -Force

# Auto-load (PSModulePath)
$env:PSModulePath -split ';'

# Create module manifest
New-ModuleManifest -Path .\MyModule.psd1 -RootModule MyModule.psm1

# Find modules
Find-Module -Name "*azure*"
```

## 3. Remoting

### One-to-One (Interactive)

```powershell
# Enter interactive session
Enter-PSSession -ComputerName SERVER01 -Credential (Get-Credential)

# Uses WinRM (HTTP: 5985, HTTPS: 5986)
# Requires PSRemoting enabled on target:
Enable-PSRemoting -Force
```

### One-to-Many (Fan-out)

```powershell
# Run command on multiple machines
Invoke-Command -ComputerName SRV01, SRV02 -ScriptBlock { Get-Service -Name BITS }

# With credentials
Invoke-Command -ComputerName SRV01 -Credential (Get-Credential) -FilePath C:\script.ps1

# Pass arguments
Invoke-Command -ComputerName SRV01 -ArgumentList 'arg1', 'arg2' -ScriptBlock {
  param($a, $b)
  "$a $b"
}

# Session re-use
$s = New-PSSession -ComputerName SRV01, SRV02
Invoke-Command -Session $s -ScriptBlock { Get-Process }
Remove-PSSession $s
```

### Security / Configuration

```powershell
# Trusted hosts (for workgroup)
Set-Item WSMan:\localhost\Client\TrustedHosts -Value "SRV01,SRV02"

# Test connectivity
Test-WSMan -ComputerName SRV01

# HTTPS listener
New-Item -Path WSMan:\localhost\Listener -Transport HTTPS -Address * -CertificateThumbprint $thumb
```

## 4. Background Jobs

```powershell
# Start a job
$job = Start-Job -ScriptBlock { Get-Process | Sort-Object WorkingSet64 -Descending }

# Wait for completion
$job | Wait-Job

# Get results
$job | Receive-Job

# Get jobs in session
Get-Job

# Remove completed jobs
Get-Job | Where-Object State -EQ 'Completed' | Remove-Job

# Thread-based jobs (faster, no remoting overhead)
$threadJob = Start-ThreadJob -ScriptBlock { 1..10 | ForEach-Object { $_ * 2 } }

# Requires: Install-Module -Name ThreadJob -Force
```

## 5. Scheduled Jobs

```powershell
# Create scheduled job (PS v3+)
$trigger = New-JobTrigger -Daily -At '03:00'
Register-ScheduledJob -Name DailyBackup -ScriptBlock { .\backup.ps1 } -Trigger $trigger

# Manage
Get-ScheduledJob
Enable-ScheduledJob -Id 1
Disable-ScheduledJob -Id 1
Unregister-ScheduledJob -Id 1

# View task in Task Scheduler
Get-ScheduledTask -TaskName DailyBackup | Start-ScheduledTask
```

Alternative (recommended): `Register-ScheduledTask` with `New-ScheduledTaskAction` for full control.

## 6. Error Handling

```powershell
# ErrorActionPreference controls unhandled errors
$ErrorActionPreference = 'Stop'      # Stop on error
$ErrorActionPreference = 'Continue'  # Default
$ErrorActionPreference = 'SilentlyContinue'
$ErrorActionPreference = 'Ignore'

# Try / Catch / Finally
try {
  Get-Item 'C:\nonexistent.txt' -ErrorAction Stop
} catch [System.IO.FileNotFoundException] {
  Write-Warning "File not found: $_"
} catch {
  Write-Error "Unhandled: $_"
} finally {
  Write-Host "Cleanup runs always"
}

# $Error automatic variable (collection of recent errors)
$Error[0]         # Most recent
$Error.Count      # Number of errors
$Error.Clear()    # Clear

# Trap (legacy — prefer try/catch)
trap { Write-Error $_; continue }

# Investigating errors
$Error[0] | Format-List * -Force
$Error[0].Exception | Get-Member
$Error[0].InvocationInfo.PositionMessage
```

## 7. Event Logs

```powershell
# Windows Event Log (PowerShell 7+ / Windows PowerShell)
Get-WinEvent -LogName Application -MaxEvents 50

# Filter by level (1=critical, 2=error, 3=warning, 4=info)
Get-WinEvent -FilterHashtable @{ LogName='System'; Level=1,2; StartTime=(Get-Date).AddHours(-1) }

# Filter by provider
Get-WinEvent -FilterHashtable @{ ProviderName='PowerShell'; Id=4100 }

# Create custom event log (admin)
New-EventLog -LogName MyApp -Source MySource
Write-EventLog -LogName MyApp -Source MySource -EntryType Error -EventId 100 -Message "Something failed"

# Modern: Unified Logging (ETW)
# Use wevtutil.exe for advanced management:
#   wevtutil enum-logs
#   wevtutil cl Application
```

## 8. Registry Access

Registry is exposed as a PSDrive with five root keys:

| Path               | Root Key               |
|--------------------|------------------------|
| `HKLM:\`           | `HKEY_LOCAL_MACHINE`   |
| `HKCU:\`           | `HKEY_CURRENT_USER`    |
| `HKCR:\`           | `HKEY_CLASSES_ROOT`    |
| `HKU:\`            | `HKEY_USERS`           |
| `HKCC:\`           | `HKEY_CURRENT_CONFIG`  |

```powershell
# Read
Get-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion'
Get-ItemPropertyValue -Path 'HKLM:\...' -Name 'ProgramFilesDir'

# Create key
New-Item -Path 'HKCU:\Software\MyApp'

# Set value
Set-ItemProperty -Path 'HKCU:\Software\MyApp' -Name 'Setting' -Value 'value'

# Remove
Remove-ItemProperty -Path 'HKCU:\Software\MyApp' -Name 'Setting'
Remove-Item -Path 'HKCU:\Software\MyApp'

# Remote registry (requires Remote Registry service)
$reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $computer)
$key = $reg.OpenSubKey('Software\Microsoft\Windows')
$key.GetValue('CurrentVersion')
```

## 9. CIM / WMI

WMI is deprecated; **CIM** (WS-Management) is the modern replacement.

```powershell
# CIM (recommended)
Get-CimInstance -ClassName Win32_OperatingSystem
Get-CimInstance -ClassName Win32_Process -Filter 'Name LIKE "powershell%"'
Get-CimInstance -ClassName Win32_Service | Where-Object State -EQ 'Running'

# CIM with remote computers
Get-CimInstance -ComputerName SRV01 -ClassName Win32_ComputerSystem

# WMI (legacy, still works)
Get-WmiObject -Class Win32_LogicalDisk -Filter 'DriveType=3'

# Common classes
#   Win32_OperatingSystem      OS info
#   Win32_Processor            CPU
#   Win32_ComputerSystem       System / RAM
#   Win32_LogicalDisk          Drives
#   Win32_Process              Processes
#   Win32_Service              Services
#   Win32_NetworkAdapter       Network
#   Win32_Product              Installed software (slow!)
#   Win32_QuickFixEngineering  Installed KBs
#   CIM_Process                Cross-platform process
```

## 10. Performance Counters

```powershell
# List all counter sets
Get-Counter -ListSet '*' | Select-Object CounterSetName

# Get specific counters
Get-Counter '\Memory\Available MBytes'
Get-Counter '\Processor(_Total)\% Processor Time'

# Sample multiple counters
Get-Counter -Counter @(
  '\Processor(_Total)\% Processor Time',
  '\Memory\Available MBytes',
  '\PhysicalDisk(_Total)\% Disk Time'
)

# Continuous sampling
Get-Counter -Counter '\Network Interface(*)\Bytes Total/sec' -SampleInterval 2 -MaxSamples 10

# With CIM (alternative)
Get-CimInstance Win32_PerfFormattedData_PerfOS_Processor | Select-Object Name, PercentProcessorTime
Get-CimInstance Win32_PerfFormattedData_PerfOS_Memory | Select-Object AvailableMBytes

# Common counters
#   \Processor(_Total)\% Processor Time
#   \Memory\Available MBytes
#   \Memory\Pages/sec
#   \PhysicalDisk(_Total)\% Disk Time
#   \PhysicalDisk(_Total)\Avg. Disk Queue Length
#   \Network Interface(*)\Bytes Total/sec
#   \PowerShell Core(*)\PowerShell Runspace Count
```
