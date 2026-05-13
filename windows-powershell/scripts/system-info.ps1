<#
.SYNOPSIS
  Gathers comprehensive Windows system information and outputs a clean report.
.DESCRIPTION
  Reports OS version, CPU (model/cores/usage%), RAM (total/used/free%),
  disk (per drive), top 5 processes by memory, network adapters, uptime,
  and pending Windows updates.
.EXAMPLE
  .\system-info.ps1
#>

$ErrorActionPreference = 'Stop'
$output = @()

# Header
$output += "=" * 60
$output += "  SYSTEM INFORMATION REPORT"
$output += "  Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$output += "  Hostname:  $env:COMPUTERNAME"
$output += "=" * 60
$output += ""

# OS Version
$os = Get-CimInstance Win32_OperatingSystem
$output += "[OS]"
$output += "  Edition:    $($os.Caption)"
$output += "  Version:    $($os.Version)"
$output += "  Build:      $($os.BuildNumber)"
$output += "  Arch:       $env:PROCESSOR_ARCHITECTURE"
$output += "  Install:    $($os.InstallDate.ToString('yyyy-MM-dd'))"
$output += "  Last Boot:  $($os.LastBootUpTime.ToString('yyyy-MM-dd HH:mm:ss'))"
$output += ""

# Uptime
$uptime = (Get-Date) - $os.LastBootUpTime
$output += "[UPTIME]"
$output += "  $($uptime.Days) days, $($uptime.Hours) hours, $($uptime.Minutes) minutes"
$output += ""

# CPU
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
$cores = (Get-CimInstance Win32_Processor).NumberOfCores
$logical = (Get-CimInstance Win32_Processor).NumberOfLogicalProcessors
$cpuLoad = Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average
$output += "[CPU]"
$output += "  Model:   $($cpu.Name)"
$output += "  Cores:   $cores physical / $logical logical"
$output += "  Usage:   $([math]::Round($cpuLoad.Average, 1))%"
$output += "  Max MHz: $($cpu.MaxClockSpeed)"
$output += ""

# RAM
$ramTotal = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
$ramFree  = [math]::Round($os.FreePhysicalMemory / 1MB, 1)
$ramUsed  = $ramTotal - $ramFree
$ramPct   = if ($ramTotal -gt 0) { [math]::Round(($ramUsed / $ramTotal) * 100, 1) } else { 0 }
$output += "[RAM]"
$output += "  Total:  $ramTotal GB"
$output += "  Used:   $ramUsed GB"
$output += "  Free:   $ramFree GB ($([math]::Round(($ramFree/$ramTotal)*100, 1))%)"
$output += "  Usage:  $ramPct%"
$output += ""

# Disk — per drive
$output += "[DISK]"
Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' | ForEach-Object {
  $total = [math]::Round($_.Size / 1GB, 1)
  $free  = [math]::Round($_.FreeSpace / 1GB, 1)
  $used  = $total - $free
  $pct   = if ($total -gt 0) { [math]::Round(($used / $total) * 100, 1) } else { 0 }
  $output += "  $($_.DeviceID)  Total: ${total}G  Used: ${used}G  Free: ${free}G ($([math]::Round(($free/$total)*100, 1))%)  [$pct% used]"
}
$output += ""

# Top 5 processes by memory
$output += "[TOP 5 PROCESSES (by Working Set)]"
Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 5 | ForEach-Object {
  $mb = [math]::Round($_.WorkingSet64 / 1MB, 1)
  $output += "  {0,-6} {1,-20} {2,8} MB" -f $_.Id, $_.ProcessName, $mb
}
$output += ""

# Network adapters
$output += "[NETWORK ADAPTERS]"
Get-NetAdapter | Where-Object Status -EQ 'Up' | ForEach-Object {
  $ip = Get-NetIPAddress -InterfaceIndex $_.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
  $ipStr = if ($ip) { $ip.IPAddress } else { 'N/A' }
  $output += "  {0,-20} {1,-15}  {2}" -f $_.Name, $ipStr, $_.LinkSpeed
}
$output += ""

# Pending Windows Updates
$output += "[WINDOWS UPDATES PENDING]"
try {
  $session = New-Object -ComObject Microsoft.Update.Session
  $searcher = $session.CreateUpdateSearcher()
  $result = $searcher.Search("IsInstalled=0")
  if ($result.Updates.Count -eq 0) {
    $output += "  None pending"
  } else {
    $result.Updates | ForEach-Object { $output += "  - $($_.Title)" }
  }
} catch {
  $output += "  Could not query Windows Update (may require admin)"
}
$output += ""

# Footer
$output += "=" * 60
$output += "  END OF REPORT"
$output += "=" * 60

$output -join "`r`n" | Write-Output
