<#
.SYNOPSIS
  Run Lighthouse performance audit via Chrome headless or Lighthouse CLI.
.DESCRIPTION
  Audits a URL using Google Lighthouse and outputs structured JSON/HTML reports
  with Core Web Vitals scores (LCP, INP, CLS, TBT, FCP).
.PARAMETER Url
  Target URL to audit (required).
.PARAMETER OutputDir
  Directory to write reports into (default: ./lighthouse-reports).
.PARAMETER Device
  Emulated device: "mobile" or "desktop" (default: mobile).
.PARAMETER ChromePath
  Path to Chrome/Chromium executable. Auto-detected if omitted.
.PARAMETER LighthousePath
  Path to lighthouse CLI. Defaults to "lighthouse.cmd" on PATH.
.PARAMETER ExtraFlags
  Extra flags to pass through to Lighthouse CLI (string).
.EXAMPLE
  .\audit-lighthouse.ps1 -Url "https://example.com"
  .\audit-lighthouse.ps1 -Url "https://example.com" -Device desktop -OutputDir "C:\reports"
#>

param(
  [Parameter(Mandatory = $true)]
  [string]$Url,

  [string]$OutputDir = "./lighthouse-reports",

  [ValidateSet("mobile", "desktop")]
  [string]$Device = "mobile",

  [string]$ChromePath,

  [string]$LighthousePath,

  [string]$ExtraFlags
)

$ErrorActionPreference = "Stop"

# --- Resolve paths ---
$OutputDir = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputDir)
if (-not (Test-Path -LiteralPath $OutputDir)) {
  New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$safeHost = ($Url -replace 'https?://', '' -replace '[^\w.-]', '_').TrimStart('_')
$reportPrefix = "lighthouse-$safeHost-$Device-$timestamp"

# --- Resolve Chrome ---
if (-not $ChromePath) {
  $candidates = @(
    "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
    "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
    "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe",
    "$env:ProgramFiles\Chromium\Application\chrome.exe",
    (Get-Command "chrome" -ErrorAction SilentlyContinue).Source
  )
  $ChromePath = $candidates | Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Select-Object -First 1

  if (-not $ChromePath) {
    Write-Error "Chrome not found. Provide -ChromePath or install Chrome."
    exit 1
  }
}

Write-Host "Chrome: $ChromePath"

# --- Resolve Lighthouse CLI ---
if (-not $LighthousePath) {
  $LighthousePath = (Get-Command "lighthouse" -ErrorAction SilentlyContinue).Source
  if (-not $LighthousePath) {
    $LighthousePath = (Get-Command "lighthouse.cmd" -ErrorAction SilentlyContinue).Source
  }
  if (-not $LighthousePath) {
    Write-Host "Lighthouse CLI not found on PATH. Trying npx..."
    $LighthousePath = "npx.cmd"
    $npxPrefix = "lighthouse"
  } else {
    $npxPrefix = ""
  }
} else {
  $npxPrefix = ""
}

# --- Build flags ---
$deviceFlag = if ($Device -eq "desktop") { "--preset=desktop" } else { "--preset=experimental" }

$outputFlags = @(
  "--output=json",
  "--output=html",
  "--output-path=`"$OutputDir/$reportPrefix`"",
  "--chrome-flags=`"--headless=new --no-sandbox --disable-gpu`"",
  "--port=0"
)

if ($ChromePath) {
  $outputFlags += "--chrome-path=`"$ChromePath`""
}

if ($ExtraFlags) {
  $outputFlags += $ExtraFlags
}

$allFlags = @($deviceFlag) + $outputFlags

# --- Run ---
Write-Host "Auditing $Url (device=$Device) ..."
Write-Host "Report prefix: $reportPrefix"

if ($npxPrefix) {
  $proc = Start-Process -NoNewWindow -Wait -PassThru -FilePath "npx.cmd" -ArgumentList @("lighthouse", "`"$Url`"") + $allFlags
} else {
  $proc = Start-Process -NoNewWindow -Wait -PassThru -FilePath $LighthousePath -ArgumentList @("`"$Url`"") + $allFlags
}

if ($proc.ExitCode -ne 0) {
  Write-Error "Lighthouse exited with code $($proc.ExitCode)."
  exit $proc.ExitCode
}

# --- Parse JSON report for key metrics ---
$jsonReportPath = "$OutputDir/$reportPrefix.report.json"
if (Test-Path -LiteralPath $jsonReportPath) {
  $report = Get-Content -Raw -LiteralPath $jsonReportPath | ConvertFrom-Json

  $audits = $report.audits
  $categories = $report.categories

  Write-Host "`n=== PERFORMANCE SUMMARY ==="
  Write-Host "Performance: $($categories.performance.score * 100)" | Out-Host
  Write-Host "Accessibility: $($categories.accessibility.score * 100)" | Out-Host
  Write-Host "Best Practices: $($categories.'best-practices'.score * 100)" | Out-Host
  Write-Host "SEO: $($categories.seo.score * 100)" | Out-Host

  function Get-AuditScore([string]$id) {
    $a = $audits.$id
    if (-not $a) { return "N/A" }
    if ($a.numericValue -ne $null) { return [math]::Round($a.numericValue, 2) }
    return $a.displayValue
  }

  Write-Host "`n--- Core Web Vitals ---"
  Write-Host "LCP (Largest Contentful Paint): $(Get-AuditScore 'largest-contentful-paint')"
  Write-Host "INP (Interaction to Next Paint): $(Get-AuditScore 'interaction-to-next-paint')"
  Write-Host "CLS (Cumulative Layout Shift):  $(Get-AuditScore 'cumulative-layout-shift')"
  Write-Host "TBT (Total Blocking Time):      $(Get-AuditScore 'total-blocking-time')"
  Write-Host "FCP (First Contentful Paint):   $(Get-AuditScore 'first-contentful-paint')"
  Write-Host "SI  (Speed Index):              $(Get-AuditScore 'speed-index')"

  Write-Host "`n--- Opportunities ---"
  $opportunities = $report.audits.PSObject.Properties |
    Where-Object { $_.Value.details -and $_.Value.details.type -eq "opportunity" } |
    Sort-Object { $_.Value.numericValue } -Descending |
    Select-Object -First 10

  foreach ($opp in $opportunities) {
    Write-Host "  [$([math]::Round($opp.Value.numericValue, 0)) ms] $($opp.Value.title)"
  }

  # Write a compact summary CSV
  $summaryPath = "$OutputDir/$reportPrefix-summary.csv"
  @"
url,device,timestamp,performance,lcp,inp,cls,tbt,fcp
$Url,$Device,$timestamp,$($categories.performance.score * 100),$(Get-AuditScore 'largest-contentful-paint'),$(Get-AuditScore 'interaction-to-next-paint'),$(Get-AuditScore 'cumulative-layout-shift'),$(Get-AuditScore 'total-blocking-time'),$(Get-AuditScore 'first-contentful-paint')
"@ | Set-Content -Path $summaryPath -Encoding UTF8

  Write-Host "`nReports saved to: $OutputDir"
  Write-Host "HTML: $OutputDir/$reportPrefix.report.html"
  Write-Host "JSON: $jsonReportPath"
  Write-Host "CSV:  $summaryPath"
} else {
  Write-Warning "JSON report not found at $jsonReportPath"
}

Write-Host "`nDone."
