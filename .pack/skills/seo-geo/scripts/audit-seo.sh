param(
  [Parameter(Mandatory=$true)]
  [string]$Url
)

$ErrorActionPreference = "Stop"
$results = @()

Write-Host "=== SEO Audit: $Url ===" -ForegroundColor Cyan
Write-Host ""

function Pass($check, $detail) {
  $results += [PSCustomObject]@{ Check = $check; Status = "PASS"; Detail = $detail }
  Write-Host "  [PASS] $check - $detail" -ForegroundColor Green
}

function Warn($check, $detail) {
  $results += [PSCustomObject]@{ Check = $check; Status = "WARN"; Detail = $detail }
  Write-Host "  [WARN] $check - $detail" -ForegroundColor Yellow
}

function Fail($check, $detail) {
  $results += [PSCustomObject]@{ Check = $check; Status = "FAIL"; Detail = $detail }
  Write-Host "  [FAIL] $check - $detail" -ForegroundColor Red
}

try {
  $response = Invoke-WebRequest -Uri $Url -TimeoutSec 30 -ErrorAction Stop
  $html = $response.Content
  $statusCode = $response.StatusCode

  if ($statusCode -eq 200) {
    Pass "HTTP Status" "200 OK"
  } else {
    Warn "HTTP Status" "Expected 200, got $statusCode"
  }
} catch {
  Fail "Page Fetch" "Could not fetch URL: $_"
  Write-Host "`n=== AUDIT SUMMARY ===" -ForegroundColor Cyan
  $passed = ($results | Where-Object { $_.Status -eq "PASS" }).Count
  $failed = ($results | Where-Object { $_.Status -eq "FAIL" }).Count
  $warnings = ($results | Where-Object { $_.Status -eq "WARN" }).Count
  Write-Host "Passed: $passed | Failed: $failed | Warnings: $warnings"
  exit 1
}

# --- Page Title ---
if ($html -match '<title[^>]*>(.*?)</title>') {
  $title = $matches[1].Trim()
  if ($title.Length -eq 0) {
    Fail "Page Title" "Title tag is empty"
  } elseif ($title.Length -gt 60) {
    Warn "Page Title" "Title is $($title.Length) chars (recommended: 50-60). Title: '$title'"
  } else {
    Pass "Page Title" "$($title.Length) chars. Title: '$title'"
  }
} else {
  Fail "Page Title" "No <title> tag found"
}

# --- Meta Description ---
if ($html -match '<meta[^>]+name=["\']description["\'][^>]+content=["\']([^"\']*)["\']') {
  $desc = $matches[1].Trim()
  if ($desc.Length -eq 0) {
    Fail "Meta Description" "Content attribute is empty"
  } elseif ($desc.Length -gt 160) {
    Warn "Meta Description" "$($desc.Length) chars (recommended: max 160)"
  } else {
    Pass "Meta Description" "$($desc.Length) chars"
  }
} else {
  Fail "Meta Description" "No meta description tag found"
}

# --- H1 Tag ---
$h1Matches = [regex]::Matches($html, '<h1[^>]*>(.*?)</h1>', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
if ($h1Matches.Count -eq 0) {
  Fail "H1 Tag" "No <h1> found on page"
} elseif ($h1Matches.Count -gt 1) {
  Warn "H1 Tag" "$($h1Matches.Count) H1 tags found (recommended: exactly 1)"
  foreach ($h1 in $h1Matches) {
    $text = $h1.Groups[1].Value -replace '<[^>]+>', ''
    Write-Host "         H1 content: '$($text.Trim())'" -ForegroundColor Gray
  }
} else {
  $text = $h1Matches[0].Groups[1].Value -replace '<[^>]+>', ''
  Pass "H1 Tag" "'$($text.Trim())'"
}

# --- Image Alt Attributes ---
$imgMatches = [regex]::Matches($html, '<img[^>]+src=["\']([^"\']+)["\'][^>]*>', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
$images = @()
$altless = @()
foreach ($img in $imgMatches) {
  $src = $img.Groups[1].Value
  $fullTag = $img.Groups[0].Value
  $images += $src
  if ($fullTag -notmatch 'alt\s*=') {
    $altless += $src
  }
}
if ($images.Count -eq 0) {
  Warn "Image Alt Attributes" "No images found on page"
} elseif ($altless.Count -gt 0) {
  Fail "Image Alt Attributes" "$($altless.Count)/$($images.Count) images missing alt text"
  foreach ($a in $altless) { Write-Host "         Missing alt: $a" -ForegroundColor Gray }
} else {
  Pass "Image Alt Attributes" "All $($images.Count) images have alt text"
}

# --- Open Graph Tags ---
$ogTags = @{}
$ogMatches = [regex]::Matches($html, '<meta[^>]+property=["\'](og:[^"\']+)["\'][^>]+content=["\']([^"\']*)["\']', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
foreach ($m in $ogMatches) { $ogTags[$m.Groups[1].Value] = $m.Groups[2].Value }
$requiredOG = @('og:title', 'og:description', 'og:image', 'og:url')
$missingOG = $requiredOG | Where-Object { -not $ogTags.ContainsKey($_) }
if ($missingOG.Count -gt 0) {
  Fail "Open Graph" "Missing OG tags: $($missingOG -join ', ')"
} else {
  Pass "Open Graph" "All core OG tags present (title, description, image, url)"
}

# --- Twitter Card ---
$twMatches = [regex]::Matches($html, '<meta[^>]+name=["\']twitter:([^"\']+)["\'][^>]+content=["\']([^"\']*)["\']', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
if ($twMatches.Count -ge 2) {
  Pass "Twitter Card" "$($twMatches.Count) twitter tags found"
} else {
  Warn "Twitter Card" "Less than 2 twitter card tags (recommended: card, title, description, image)"
}

# --- Hreflang ---
$hreflangMatches = [regex]::Matches($html, '<link[^>]+rel=["\']alternate["\'][^>]+hreflang=["\']([^"\']+)["\']', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
if ($hreflangMatches.Count -gt 0) {
  $langs = $hreflangMatches | ForEach-Object { $_.Groups[1].Value }
  if ($langs -contains 'x-default') {
    Pass "Hreflang" "$($hreflangMatches.Count) hreflang tags (includes x-default)"
  } else {
    Warn "Hreflang" "$($hreflangMatches.Count) tags but no x-default fallback. Langs: $($langs -join ', ')"
  }
} else {
  Warn "Hreflang" "No hreflang tags found (ok if single-language site)"
}

# --- Canonical ---
if ($html -match '<link[^>]+rel=["\']canonical["\'][^>]+href=["\']([^"\']+)["\']') {
  $canonical = $matches[1]
  Pass "Canonical" $canonical
} else {
  Fail "Canonical" "No canonical tag found"
}

# --- Robots Meta ---
if ($html -match '<meta[^>]+name=["\']robots["\'][^>]+content=["\']([^"\']+)["\']') {
  $robots = $matches[1]
  if ($robots -match 'noindex') {
    Fail "Robots Meta" "Page is set to noindex: '$robots'"
  } else {
    Pass "Robots Meta" $robots
  }
} else {
  Warn "Robots Meta" "No robots meta tag found (default: index, follow)"
}

# --- Structured Data (JSON-LD) ---
$jsonLdMatches = [regex]::Matches($html, '<script[^>]+type=["\']application/ld\+json["\'][^>]*>(.*?)</script>', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor [System.Text.RegularExpressions.RegexOptions]::Singleline)
if ($jsonLdMatches.Count -gt 0) {
  $validCount = 0
  $invalidCount = 0
  foreach ($match in $jsonLdMatches) {
    $json = $match.Groups[1].Value.Trim()
    try {
      $parsed = $json | ConvertFrom-Json
      if ($parsed.'@type') { $validCount++ } else { $invalidCount++ }
    } catch {
      $invalidCount++
    }
  }
  if ($invalidCount -gt 0) {
    Warn "JSON-LD" "$validCount valid, $invalidCount invalid JSON-LD blocks"
  } else {
    Pass "JSON-LD" "$validCount valid JSON-LD block(s)"
  }
} else {
  Fail "JSON-LD" "No structured data (JSON-LD) found"
}

# --- Render Blocking Resources ---
$cssLinks = [regex]::Matches($html, '<link[^>]+rel=["\']stylesheet["\'][^>]+href=["\']([^"\']+)["\']', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
$syncScripts = [regex]::Matches($html, '<script[^>]+src=["\']([^"\']+)["\'][^>]*>', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase) | Where-Object { $_.Groups[0].Value -notmatch 'async|defer' }
if ($syncScripts.Count -gt 5) {
  Warn "Render Blocking" "$($syncScripts.Count) sync render-blocking scripts, $($cssLinks.Count) CSS files"
} else {
  Pass "Render Blocking" "$($syncScripts.Count) sync scripts, $($cssLinks.Count) CSS files"
}

# --- Viewport ---
if ($html -match '<meta[^>]+name=["\']viewport["\'][^>]+content=["\']([^"\']+)["\']') {
  $vp = $matches[1]
  if ($vp -match 'width=device-width') {
    Pass "Viewport" "Responsive viewport meta set"
  } else {
    Warn "Viewport" "Viewport present but may not be responsive: '$vp'"
  }
} else {
  Fail "Viewport" "No viewport meta tag found"
}

# --- Language Attribute ---
if ($html -match '<html[^>]+lang=["\']([^"\']+)["\']') {
  Pass "HTML Lang" "lang='$($matches[1])'"
} else {
  Warn "HTML Lang" "No lang attribute on <html>"
}

# --- Summary ---
Write-Host ""
Write-Host "=== AUDIT SUMMARY ===" -ForegroundColor Cyan
$passed = ($results | Where-Object { $_.Status -eq "PASS" }).Count
$failed = ($results | Where-Object { $_.Status -eq "FAIL" }).Count
$warnings = ($results | Where-Object { $_.Status -eq "WARN" }).Count
$total = $results.Count
$score = [math]::Round(($passed / $total) * 100, 1)

Write-Host "Score:     $score% ($passed/$total passed)" -ForegroundColor $(if ($score -ge 80) { "Green" } elseif ($score -ge 50) { "Yellow" } else { "Red" })
Write-Host "Passed:    $passed" -ForegroundColor Green
Write-Host "Warnings:  $warnings" -ForegroundColor Yellow
Write-Host "Failed:    $failed" -ForegroundColor Red
Write-Host ""

# --- Suggestions ---
if ($failed -gt 0 -or $warnings -gt 0) {
  Write-Host "=== SUGGESTIONS ===" -ForegroundColor Cyan
  $failedItems = $results | Where-Object { $_.Status -ne "PASS" }
  foreach ($item in $failedItems) {
    Write-Host "  [$($item.Status)] $($item.Check): $($item.Detail)" -ForegroundColor $(if ($item.Status -eq "FAIL") { "Red" } else { "Yellow" })
  }
}

exit $(if ($failed -gt 0) { 1 } else { 0 })
