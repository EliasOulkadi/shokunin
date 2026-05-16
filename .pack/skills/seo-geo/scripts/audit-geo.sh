param(
  [Parameter(Mandatory=$true)]
  [string]$Url,
  [string]$BrandName = ""
)

$ErrorActionPreference = "Stop"
$results = @()

Write-Host "=== GEO Audit (Generative Engine Optimization): $Url ===" -ForegroundColor Magenta
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

function Info($msg) {
  Write-Host "  [INFO] $msg" -ForegroundColor Blue
}

try {
  $baseUri = $Url.TrimEnd('/')
  $response = Invoke-WebRequest -Uri $baseUri -TimeoutSec 30 -ErrorAction Stop
  $html = $response.Content
  $statusCode = $response.StatusCode

  if ($statusCode -eq 200) {
    Pass "HTTP Status" "200 OK"
  } else {
    Warn "HTTP Status" "Expected 200, got $statusCode"
  }
} catch {
  Fail "Page Fetch" "Could not fetch URL: $_"
  Write-Host "`n=== GEO AUDIT SUMMARY ===" -ForegroundColor Magenta
  exit 1
}

# --- 1. llms.txt ---
$llmsUrls = @(
  "$baseUri/llms.txt",
  "$baseUri/llms.txt"
)
$llmsFound = $false
foreach ($u in $llmsUrls) {
  try {
    $llmsResp = Invoke-WebRequest -Uri $u -TimeoutSec 10 -ErrorAction Stop
    if ($llmsResp.StatusCode -eq 200) {
      Pass "llms.txt" "Found at $u ($($llmsResp.Content.Length) bytes)"
      $llmsFound = $true
      break
    }
  } catch { }
}
if (-not $llmsFound) {
  Fail "llms.txt" "Not found at $baseUri/llms.txt. AI crawlers use this to understand site structure."
}

# --- 2. robots.txt ---
try {
  $robotsResp = Invoke-WebRequest -Uri "$baseUri/robots.txt" -TimeoutSec 10 -ErrorAction Stop
  if ($robotsResp.StatusCode -eq 200) {
    $robotsContent = $robotsResp.Content
    $hasLLM = $robotsContent -match 'llms\.txt'
    $hasChatGPT = $robotsContent -match 'ChatGPT-User|GPTBot'
    $hasCCBot = $robotsContent -match 'CCBot'
    $hasClaude = $robotsContent -match 'Claude-Web|anthropic-ai'
    $aiBots = @()
    if ($hasChatGPT) { $aiBots += "GPTBot/ChatGPT-User" }
    if ($hasCCBot) { $aiBots += "CCBot (Perplexity)" }
    if ($hasClaude) { $aiBots += "Claude-Web" }
    if ($aiBots.Count -gt 0) {
      Info "robots.txt explicitly references AI crawlers: $($aiBots -join ', ')"
    } else {
      Warn "robots.txt AI Crawlers" "robots.txt exists but no explicit AI crawler directives found"
    }
    if ($hasLLM) { Pass "llms.txt in robots.txt" "Referenced in robots.txt" }
  } else {
    Warn "robots.txt" "Could not fetch: $($robotsResp.StatusCode)"
  }
} catch {
  Warn "robots.txt" "Not found at $baseUri/robots.txt"
}

# --- 3. well-known/ai-plugin.json ---
$aiPluginUrls = @(
  "$baseUri/.well-known/ai-plugin.json",
  "$baseUri/ai-plugin.json"
)
$aiPluginFound = $false
foreach ($u in $aiPluginUrls) {
  try {
    $aiResp = Invoke-WebRequest -Uri $u -TimeoutSec 10 -ErrorAction Stop
    if ($aiResp.StatusCode -eq 200 -and $aiResp.Content.Trim().StartsWith('{')) {
      Pass "AI Plugin" "Found at $u"
      $aiPluginFound = $true
      break
    }
  } catch { }
}
if (-not $aiPluginFound) {
  Warn "AI Plugin" "No ai-plugin.json found (used by ChatGPT plugins and AI tool integrations)"
}

# --- 4. Structured Data for AI ---
$jsonLdMatches = [regex]::Matches($html, '<script[^>]+type=["\']application/ld\+json["\'][^>]*>(.*?)</script>', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor [System.Text.RegularExpressions.RegexOptions]::Singleline)
$hasFAQ = $false
$hasHowTo = $false
$hasArticle = $false
$hasOrganization = $false
$hasProduct = $false
$hasPerson = $false
$hasBreadcrumb = $false
$hasQA = $false
$entityTypes = @()

foreach ($match in $jsonLdMatches) {
  $json = $match.Groups[1].Value.Trim()
  try {
    $parsed = $json | ConvertFrom-Json
    $types = @()
    if ($parsed.'@type') { $types += $parsed.'@type' }
    if ($parsed.'@graph') { foreach ($g in $parsed.'@graph') { if ($g.'@type') { $types += $g.'@type' } } }
    $entityTypes += $types
    foreach ($t in $types) {
      $typeStr = $t -as [string]
      if ($typeStr -eq 'FAQPage') { $hasFAQ = $true }
      if ($typeStr -eq 'HowTo') { $hasHowTo = $true }
      if ($typeStr -eq 'Article' -or $typeStr -eq 'NewsArticle' -or $typeStr -eq 'BlogPosting') { $hasArticle = $true }
      if ($typeStr -eq 'Organization') { $hasOrganization = $true }
      if ($typeStr -eq 'Product') { $hasProduct = $true }
      if ($typeStr -eq 'Person') { $hasPerson = $true }
      if ($typeStr -eq 'BreadcrumbList') { $hasBreadcrumb = $true }
      if ($typeStr -eq 'QAPage') { $hasQA = $true }
    }
  } catch { }
}

if ($entityTypes.Count -gt 0) {
  Pass "Entity Types" "$($entityTypes -join ', ')"
} else {
  Fail "Entity Types" "No structured data found"
}

# --- 5. FAQ Schema (critical for AI answers) ---
if ($hasFAQ) {
  Pass "FAQ Schema" "Present - AI assistants pull FAQ content directly into answers"
} else {
  Warn "FAQ Schema" "Missing. FAQPage schema significantly increases chance of being quoted in AI answers."
}

# --- 6. Organization/Person Schema ---
if ($hasOrganization -or $hasPerson) {
  Pass "Authority Entity" "Organization/Person schema present - helps AI attribute sources"
} else {
  Warn "Authority Entity" "No Organization or Person schema. AI engines need clear entity attribution."
}

# --- 7. BreadcrumbList ---
if ($hasBreadcrumb) {
  Pass "BreadcrumbList" "Present - helps AI understand site structure and entity relationships"
} else {
  Warn "BreadcrumbList" "Missing. Helps AI crawlers understand content hierarchy."
}

# --- 8. Clear Entity Definitions ---
$entityScore = 0
$entityNotes = @()
if ($hasArticle) { $entityScore += 10; $entityNotes += "Article/BlogPosting" }
if ($hasOrganization) { $entityScore += 15; $entityNotes += "Organization" }
if ($hasPerson) { $entityScore += 10; $entityNotes += "Person" }
if ($hasProduct) { $entityScore += 10; $entityNotes += "Product" }
if ($hasBreadcrumb) { $entityScore += 10; $entityNotes += "BreadcrumbList" }
if ($hasFAQ) { $entityScore += 15; $entityNotes += "FAQPage" }
if ($hasHowTo) { $entityScore += 10; $entityNotes += "HowTo" }
if ($hasQA) { $entityScore += 10; $entityNotes += "QAPage" }

if ($entityScore -ge 40) {
  Pass "Entity Definition Score" "$entityScore/80 ($($entityNotes -join ', '))"
} else {
  Warn "Entity Definition Score" "$entityScore/80. Add more entity types for better AI comprehension."
}

# --- 9. Author/Attribution ---
$hasAuthor = $html -match 'itemprop=["\']author["\']|<meta[^>]+name=["\']author["\']'
if ($hasAuthor) {
  Pass "Author Attribution" "Author meta/property found - helps AI establish citability"
} else {
  Warn "Author Attribution" "No explicit author markup. AI engines prefer attributed content."
}

# --- 10. Brand Mentions (Mock Check) ---
if ($BrandName) {
  $brandPattern = [regex]::Escape($BrandName)
  $mentions = [regex]::Matches($html, $brandPattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase).Count
  if ($mentions -ge 3) {
    Pass "Brand Mentions" "'$BrandName' mentioned $mentions times on page - strong brand signal"
  } elseif ($mentions -gt 0) {
    Warn "Brand Mentions" "'$BrandName' mentioned only $mentions times. Aim for 3+ mentions with context."
  } else {
    Fail "Brand Mentions" "'$BrandName' not found on page content"
  }
} else {
  Info "Brand Mentions" "Skipped (no brand name provided). Use -BrandName to check."
}

# --- 11. Content Readability & Answer Format ---
$textContent = $html -replace '<script[^>]*>.*?</script>', '' -replace '<style[^>]*>.*?</style>', '' -replace '<[^>]+>', ' ' -replace '\s+', ' '
$wordCount = ($textContent -split '\s+' | Where-Object { $_ -ne '' }).Count
$questionCount = [regex]::Matches($textContent, '\?').Count
$listCount = [regex]::Matches($html, '<(?:ul|ol)[^>]*>', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase).Count

if ($wordCount -ge 300) {
  Pass "Content Depth" "$wordCount words - sufficient for AI context extraction"
} else {
  Fail "Content Depth" "$wordCount words - AI engines prefer 300+ words for meaningful extraction"
}

if ($questionCount -ge 2) {
  Pass "Question Format" "$questionCount questions found - Q&A format improves AI answer extraction"
} else {
  Warn "Question Format" "Only $questionCount questions. Add explicit Q&A content for AI answer optimization."
}

if ($listCount -ge 1) {
  Pass "Structured Lists" "$listCount lists found - bullet/numbered lists improve AI answer parsing"
} else {
  Warn "Structured Lists" "No lists found. Lists are preferred by AI for extractive answers."
}

# --- 12. Internal Linking ---
$internalLinks = [regex]::Matches($html, '<a[^>]+href=["\'](?:https?://[^"\']*)?["\']', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase).Count
if ($internalLinks -ge 3) {
  Pass "Internal Links" "$internalLinks links - helps AI establish entity relationships"
} else {
  Warn "Internal Links" "Only $internalLinks internal links. More links help AI understand content relationships."
}

# --- Summary ---
Write-Host ""
Write-Host "=== GEO AUDIT SUMMARY ===" -ForegroundColor Magenta
$passed = ($results | Where-Object { $_.Status -eq "PASS" }).Count
$failed = ($results | Where-Object { $_.Status -eq "FAIL" }).Count
$warnings = ($results | Where-Object { $_.Status -eq "WARN" }).Count
$total = $results.Count
$score = [math]::Round(($passed / $total) * 100, 1)

Write-Host "GEO Readiness Score: $score% ($passed/$total passed)" -ForegroundColor $(if ($score -ge 80) { "Green" } elseif ($score -ge 50) { "Yellow" } else { "Red" })
Write-Host "Passed:    $passed" -ForegroundColor Green
Write-Host "Warnings:  $warnings" -ForegroundColor Yellow
Write-Host "Failed:    $failed" -ForegroundColor Red
Write-Host ""

if ($failed -gt 0 -or $warnings -gt 0) {
  Write-Host "=== PRIORITY ACTIONS ===" -ForegroundColor Magenta
  $failedItems = $results | Where-Object { $_.Status -ne "PASS" }
  foreach ($item in $failedItems) {
    Write-Host "  [$($item.Status)] $($item.Check): $($item.Detail)" -ForegroundColor $(if ($item.Status -eq "FAIL") { "Red" } else { "Yellow" })
  }
}

exit $(if ($failed -gt 0) { 1 } else { 0 })
