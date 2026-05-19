<#
.SYNOPSIS
    Manage Shokunin ecosystem: status, plan, apply, rollback, init.
#>
param(
  [ValidateSet("status","plan","apply","rollback","init")]
  [string]$Command = "status",
  [string]$Timestamp = "",
  [switch]$Confirm,
  [switch]$Quiet
)

$SHOKUNIN_DIR = "{{SHOKUNIN_DIR}}"
$MANIFEST = "$SHOKUNIN_DIR\shokunin.json"
$BACKUP_DIR = "$SHOKUNIN_DIR\backups"
$TEMPLATES_DIR = "$SHOKUNIN_DIR\templates"
$CHROMA_HELPER = "{{CHROMA_HELPER_PATH}}"

$PASS = 0; $FAIL = 0; $WARN = 0; $PROTECTED = 0

function Log { if (-not $Quiet) { Write-Host "$args" -ForegroundColor $args[1] } }

function Get-Hash($path) {
  if (-not (Test-Path $path)) { return $null }
  try {
    $resolvedPath = Microsoft.PowerShell.Management\Resolve-Path -LiteralPath $path -ErrorAction Stop
    $bytes = [System.IO.File]::ReadAllBytes($resolvedPath.Path)
    $hasher = [System.Security.Cryptography.SHA256]::Create()
    $hash = $hasher.ComputeHash($bytes)
    return ($hash | ForEach-Object { $_.ToString("x2") }) -join ""
  } catch { return $null }
}

function Resolve-Vars($text, $vars) {
  $result = $text
  foreach ($v in $vars.GetEnumerator()) {
    $result = $result.Replace("{{" + $v.Key + "}}", $v.Value)
  }
  return $result
}

function Resolve-ShokuninPath($relative) {
  $r = $relative
  if ($r.StartsWith("~/") -or $r -eq "~") {
    $r = $env:USERPROFILE + $r.Substring(1)
  }
  $r = $r.Replace("/", "\")
  if ($r.StartsWith(".") -and (-not [System.IO.Path]::IsPathRooted($r))) {
    $r = [System.IO.Path]::GetFullPath((Join-Path $SHOKUNIN_DIR $r))
  }
  return $r
}

function Load-Manifest {
  if (-not (Test-Path $MANIFEST)) {
    Write-Host "ERROR: Manifest not found at $MANIFEST" -ForegroundColor Red
    exit 1
  }
  $json = Get-Content $MANIFEST -Raw | ConvertFrom-Json
  return $json
}

function Flatten-Components($manifest) {
  $flat = @()
  $vars = @{}
  $manifest.vars.PSObject.Properties | ForEach-Object { $vars[$_.Name] = $_.Value }
  $manifest.vars.PSObject.Properties | ForEach-Object { $vars[$_.Name] = Resolve-Vars $vars[$_.Name] $vars }

  foreach ($group in $manifest.components.PSObject.Properties) {
    $g = $group.Value
    $groupPath = if ($g.PSObject.Properties['path']) { Resolve-Vars $g.path $vars } else { $null }
    $groupBackup = if ($g.PSObject.Properties['backup']) { $true } else { $false }
    $groupRule = if ($g.PSObject.Properties['rule']) { $g.rule } else { "MODIFY" }
    $entries = if ($g.PSObject.Properties['entries']) { $g.entries.PSObject.Properties } else { @() }
    foreach ($entry in $entries) {
      $e = $entry.Value
      $relPath = if ($e.PSObject.Properties['path']) { $e.path } elseif ($groupPath) { "$groupPath/$($entry.Name)" } else { $entry.Name }
      $fullPath = Resolve-ShokuninPath (Resolve-Vars $relPath $vars)
      $flat += [PSCustomObject]@{
        Key = $entry.Name
        FullPath = $fullPath
        Type = if ($e.PSObject.Properties['type']) { $e.type } else { "static" }
        Runtime = if ($e.PSObject.Properties['runtime']) { $e.runtime } else { "none" }
        Template = if ($e.PSObject.Properties['template']) { $e.template } else { $null }
        Rule = $groupRule
        Backup = $groupBackup
      }
    }
  }
  return $flat
}

function Get-Status($flat) {
  $results = @()
  foreach ($c in $flat) {
    $isDir = (Test-Path $c.FullPath -PathType Container)
    $hash = if ($isDir) { "DIRECTORY" } else { Get-Hash $c.FullPath }
    $exists = $hash -ne $null
    $status = if ($c.Rule -eq "NEVER_MODIFY") {
      $script:PROTECTED++
      if ($exists) { "PROTECTED" } else { "PROTECTED_EMPTY" }
    } elseif (-not $exists) {
      "MISSING"
    } else {
      "OK"
    }
    $results += [PSCustomObject]@{
      Key = $c.Key
      Path = $c.FullPath
      Status = $status
      Hash = $hash
      Type = $c.Type
      Rule = $c.Rule
    }
  }
  return $results
}

function Write-StatusReport($results) {
  $allResults = @($results)
  $ok = (@($allResults | Where-Object { $_.Status -eq "OK" })).Count
  $missing = (@($allResults | Where-Object { $_.Status -eq "MISSING" })).Count
  $protected = (@($allResults | Where-Object { $_.Status -eq "PROTECTED" })).Count

  Write-Host "`nShokunin Ecosystem Status" -ForegroundColor Cyan
  Write-Host "==========================================" -ForegroundColor Cyan
  Write-Host ""
  Write-Host "Components: $($allResults.Count) total" -ForegroundColor White
  Write-Host "  $ok OK" -ForegroundColor Green
  if ($missing -gt 0) { Write-Host "  $missing MISSING" -ForegroundColor Red }
  Write-Host "  $protected PROTECTED (data - never modified)" -ForegroundColor DarkGray
  Write-Host ""

  if ($missing -gt 0) {
    Write-Host "Missing components:" -ForegroundColor Yellow
    $allResults | Where-Object { $_.Status -eq "MISSING" } | ForEach-Object {
      Write-Host "  - $($_.Key): $($_.Path)" -ForegroundColor Red
    }
    Write-Host ""
  }
}

function Get-Plan($results) {
  $plan = @()
  foreach ($r in $results) {
    if ($r.Status -eq "PROTECTED") { continue }
    if ($r.Status -eq "MISSING") {
      $plan += [PSCustomObject]@{ Action = "CREATE"; Key = $r.Key; Path = $r.Path; Template = $r.Template; Type = $r.Type }
    }
  }
  return $plan
}

function Write-PlanReport($plan) {
  if ($plan.Count -eq 0) {
    Write-Host "`nPlan: No changes needed." -ForegroundColor Green
    return
  }
  Write-Host "`nPlan:" -ForegroundColor Cyan
  $plan | Group-Object Action | ForEach-Object {
    Write-Host "  $($_.Name) $($_.Count) files" -ForegroundColor Yellow
    $_.Group | ForEach-Object { Write-Host "    $($_.Key): $($_.Path)" -ForegroundColor DarkGray }
  }
  $backup = ($plan | Where-Object { $_.Action -match "MODIFY|CREATE" }).Count
  Write-Host "  Backup: $backup file(s)" -ForegroundColor DarkGray
  Write-Host "  Data: $PROTECTED paths excluded" -ForegroundColor DarkGray
}

function Backup-File($path) {
  if (-not (Test-Path $path)) { return }
  $ts = Get-Date -Format "yyyyMMdd-HHmmss"
  $backupDir = "$BACKUP_DIR\$ts"
  New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
  $leaf = Split-Path $path -Leaf
  Copy-Item -Path $path -Destination "$backupDir\$leaf.bak" -Force
  $manifest = @{ $leaf = $path } | ConvertTo-Json
  $manifest | Out-File "$backupDir\manifest.json" -Encoding UTF8 -Force
  return $backupDir
}

function Apply-Plan($plan, $manifest) {
  if ($plan.Count -eq 0) { Write-Host "Nothing to apply." -ForegroundColor Green; return }

  $vars = @{}
  $manifest.vars.PSObject.Properties | ForEach-Object { $vars[$_.Name] = $_.Value }
  $manifest.vars.PSObject.Properties | ForEach-Object { $vars[$_.Name] = Resolve-Vars $vars[$_.Name] $vars }

  $TEMPLATES_DIR = "$SHOKUNIN_DIR\templates"

  Write-Host "`nApplying $($plan.Count) changes..." -ForegroundColor Cyan
  $applied = 0; $errors = 0

  foreach ($item in $plan) {
    Write-Host "  [$($item.Action)] $($item.Key)..." -NoNewline

    try {
      Backup-File $item.Path | Out-Null
      if ($item.Action -eq "CREATE" -and $item.Template) {
        $templatePath = "$TEMPLATES_DIR\$($item.Template)"
        if (Test-Path $templatePath) {
          $content = Get-Content $templatePath -Raw
          $content = Resolve-Vars $content $vars
          if (-not (Split-Path $item.Path -Parent | Test-Path)) {
            New-Item -ItemType Directory -Path (Split-Path $item.Path -Parent) -Force | Out-Null
          }
          $content | Set-Content -Path $item.Path -Encoding UTF8 -NoNewline
        } else {
          New-Item -ItemType File -Path $item.Path -Force | Out-Null
          Write-Host " (template not found)" -NoNewline
        }
      } elseif ($item.Action -eq "CREATE") {
        New-Item -ItemType File -Path $item.Path -Force | Out-Null
      }
      Write-Host "OK" -ForegroundColor Green
      $applied++
    } catch {
      Write-Host "FAILED: $_" -ForegroundColor Red
      $errors++
    }
  }

  Write-Host ""
  Write-Host "Applied: $applied, Errors: $errors" -ForegroundColor $(if($errors -eq 0){'Green'}else{'Red'})
}

function Do-Rollback($timestamp) {
  $backupPath = "$BACKUP_DIR\$timestamp"
  if (-not (Test-Path $backupPath)) {
    Write-Host "No backup found for timestamp: $timestamp" -ForegroundColor Red
    $backups = Get-ChildItem "$BACKUP_DIR" -Directory | Sort-Object LastWriteTime -Descending
    if ($backups) {
      Write-Host "Available backups:" -ForegroundColor Yellow
      $backups | ForEach-Object { Write-Host "  $($_.Name) ($($_.LastWriteTime))" }
    }
    return
  }

  Write-Host "Rolling back from $timestamp..." -ForegroundColor Cyan
  $manifestPath = "$backupPath\manifest.json"
  $manifest = @{}
  if (Test-Path $manifestPath) {
    $manifestRaw = Get-Content $manifestPath -Raw | ConvertFrom-Json
    $manifest = @{}
    $manifestRaw.PSObject.Properties | ForEach-Object { $manifest[$_.Name] = $_.Value }
  }
  Get-ChildItem $backupPath -Filter "*.bak" | ForEach-Object {
    $origPath = if ($manifest.ContainsKey($_.BaseName)) { $manifest[$_.BaseName] } else { Join-Path $SHOKUNIN_DIR $_.BaseName }
    New-Item -ItemType Directory -Path (Split-Path $origPath -Parent) -Force | Out-Null
    Copy-Item -Path $_.FullName -Destination $origPath -Force
    Write-Host "  Restored: $($_.BaseName)" -ForegroundColor Green
  }
  Write-Host "Rollback complete." -ForegroundColor Green
}

### MAIN ###

$manifest = Load-Manifest
$flat = Flatten-Components $manifest

switch ($Command) {

  "status" {
    $results = Get-Status $flat
    Write-StatusReport $results
  }

  "plan" {
    $results = Get-Status $flat
    $plan = Get-Plan $results
    Write-PlanReport $plan
  }

  "apply" {
    if (-not $Confirm) {
      Write-Host "WARNING: Use -Confirm to proceed." -ForegroundColor Yellow
      Write-Host "Run 'plan' first to see what will change." -ForegroundColor DarkGray
      exit 0
    }
    $results = Get-Status $flat
    $plan = Get-Plan $results

    if ($plan.Count -eq 0) {
      Write-Host "Nothing to apply." -ForegroundColor Green
      exit 0
    }

    Write-PlanReport $plan
    Write-Host ""
    Write-Host "Proceeding with backup..." -ForegroundColor Cyan

    try {
      python $CHROMA_HELPER save "Update started: $($plan.Count) changes" auto session_end update shokunin 2>&1 | Out-Null
    } catch {}

    Apply-Plan $plan $manifest

    try {
      python $CHROMA_HELPER save "Update complete" auto session_end update shokunin 2>&1 | Out-Null
    } catch {}

    Write-Host ""
    Write-Host "Running verification..." -ForegroundColor Cyan
    & "$SHOKUNIN_DIR\scripts\memory-healthcheck.ps1" -CI 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
      Write-Host "Verification: PASSED" -ForegroundColor Green
    } else {
      Write-Host "Verification: FAILED - check output" -ForegroundColor Red
    }
  }

  "rollback" {
    Do-Rollback $Timestamp
  }

  "init" {
    Write-Host "Writing initial manifest for all discovered files..." -ForegroundColor Yellow
    Write-Host "This feature will scan the ecosystem and generate the manifest."
    Write-Host "For now, edit shokunin.json manually to add components."
  }
}
