#!/usr/bin/env bash
set -euo pipefail

# analyze-landing-page.sh
# Usage: ./analyze-landing-page.sh <url>
# Analyzes a landing page for basic CRO factors:
#   - Load time & resource weight
#   - Meta & heading structure
#   - CTA presence & visibility
#   - Mobile viewport & responsive setup
#   - Social proof signals
#   - Performance recommendations

url="${1:-}"
[ -z "$url" ] && echo "Usage: $0 <url>" && exit 1

# Ensure url has scheme
[[ "$url" =~ ^https?:// ]] || url="https://$url"

echo "═══════════════════════════════════════════════"
echo "  Landing Page CRO Analyzer"
echo "  Target: $url"
echo "═══════════════════════════════════════════════"
echo ""

# ── Fetch & time ──────────────────────────────────────
echo "── Fetching page ──"
timing_file=$(mktemp)
status_code=$(curl -sL -o /tmp/_lp_analysis.html \
  -w "%{http_code}" \
  --connect-timeout 10 \
  --max-time 30 \
  -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" \
  "$url" 2>/dev/null) || true

# Check if download succeeded
if [ ! -s /tmp/_lp_analysis.html ] || [ "$status_code" != "200" ]; then
  echo "  FAILED: HTTP $status_code (or empty response)"
  rm -f /tmp/_lp_analysis.html "$timing_file"
  exit 1
fi

page_size=$(wc -c < /tmp/_lp_analysis.html)
page_size_kb=$(( page_size / 1024 ))

echo "  HTTP Status: $status_code"
echo "  HTML Size:   ${page_size_kb}KB"
echo ""

# ── Timings via curl (re-request) ─────────────────────
echo "── Load timing ──"
curl_timing=$(curl -sL -o /dev/null \
  -w "  DNS:        %{time_namelookup}s\n  TCP:        %{time_connect}s\n  TLS:        %{time_appconnect}s\n  First byte: %{time_starttransfer}s\n  Total:      %{time_total}s\n  Speed:      %{speed_download} B/s" \
  --connect-timeout 10 \
  --max-time 30 \
  -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" \
  "$url" 2>/dev/null) || true
echo "$curl_timing"
echo ""

total_time=$(echo "$curl_timing" | grep 'Total:' | grep -oP '[\d.]+')
if [ -n "$total_time" ]; then
  if awk "BEGIN {exit !($total_time > 3)}"; then
    echo "  ⚠  Total load > 3s — likely exceeding LCP budget"
  fi
fi
echo ""

# ── Read HTML ─────────────────────────────────────────
html=$(cat /tmp/_lp_analysis.html)

# ── Title ──────────────────────────────────────────────
echo "── Meta & headings ──"
title=$(echo "$html" | grep -oP '<title>[^<]+</title>' | sed 's/<title>//;s/<\/title>//')
if [ -n "$title" ]; then
  echo "  Title:      $title"
  tw=${#title}
  if [ "$tw" -lt 10 ]; then
    echo "  ⚠  Title too short (<10 chars) — low SEO/relevance"
  elif [ "$tw" -gt 70 ]; then
    echo "  ⚠  Title too long (>70 chars) — may truncate in SERP"
  fi
else
  echo "  ✗  Missing <title>"
fi

# Meta description
meta_desc=$(echo "$html" | grep -oP '<meta[^>]+name="description"[^>]*>' | grep -oP 'content="[^"]*"' | sed 's/content="//;s/"//')
if [ -n "$meta_desc" ]; then
  mdl=${#meta_desc}
  echo "  Meta desc:  ${meta_desc:0:60}..."
  if [ "$mdl" -lt 50 ]; then
    echo "  ⚠  Meta description short — potential CRO opportunity"
  fi
else
  echo "  ✗  Missing meta description"
fi

# H1
h1_count=$(echo "$html" | grep -coP '<h1[^>]*>' || true)
if [ "$h1_count" -eq 0 ]; then
  echo "  ✗  No <h1> found — critical for SEO & clarity"
elif [ "$h1_count" -gt 1 ]; then
  echo "  ⚠  Multiple <h1> tags ($h1_count) — should be exactly one"
else
  h1_text=$(echo "$html" | grep -oP '<h1[^>]*>[^<]+</h1>' | sed 's/<[^>]*>//g')
  echo "  H1:         ${h1_text:0:80}"
  h1w=${#h1_text}
  if [ "$h1w" -gt 70 ]; then
    echo "  ⚠  H1 too long (>70 chars) — consider tightening value prop"
  fi
fi

# H2s
h2_count=$(echo "$html" | grep -coP '<h2[^>]*>' || true)
echo "  H2 count:   $h2_count (expect 4-7 for well-structured pages)"
echo ""

# ── CTA Analysis ──────────────────────────────────────
echo "── CTA signals ──"

# Look for button patterns
button_count=$(echo "$html" | grep -coP '<button[^>]*>' || true)
cta_keywords=("sign up" "signup" "subscribe" "get started" "try free" "buy now" "purchase"
              "book" "demo" "watch" "learn more" "download" "claim" "start free"
              "get access" "join" "create account" "register")
cta_found=0
cta_labels=""
for kw in "${cta_keywords[@]}"; do
  matches=$(echo "$html" | grep -ioP "(value|aria-label|alt|placeholder|data-cta)=\"[^\"]*${kw}[^\"]*\"" || true)
  btn_text=$(echo "$html" | grep -ioP "<button[^>]*>[^<]*${kw}[^<]*</button>" || true)
  link_text=$(echo "$html" | grep -ioP "<a[^>]*>[^<]*${kw}[^<]*</a>" || true)
  if [ -n "$matches" ] || [ -n "$btn_text" ] || [ -n "$link_text" ]; then
    cta_found=1
    cta_labels="$cta_labels    • $kw\n"
  fi
done

if [ "$cta_found" -eq 1 ]; then
  echo "  ✓  CTA keywords detected:"
  echo -e "$cta_labels"
else
  echo "  ✗  No clear CTA found — visitors don't know what to do"
fi
echo "  Total <button> tags: $button_count"
if [ "$button_count" -gt 3 ]; then
  echo "  ⚠  Many buttons — competing CTAs dilute conversion"
fi
echo ""

# ── Social proof ──────────────────────────────────────
echo "── Social proof signals ──"
sp_count=0
if echo "$html" | grep -qiP '(testimonial|review|rating|star[s]?\s*[45]\s*/\s*[5]|★)'; then
  echo "  ✓  Testimonials / reviews"
  ((sp_count++))
fi
if echo "$html" | grep -qiP '(log[o]s?[^"]*"[^>]*src=|client[s]?["\s]*logo|as seen in|featured in|trusted by)'; then
  echo "  ✓  Logo cloud / trust badges"
  ((sp_count++))
fi
if echo "$html" | grep -qiP '(\d[\d,.]*\s*\+?\s*(user|customer|download|member|install|signups?|client|subscriber))'; then
  echo "  ✓  Social metrics (user counts)"
  ((sp_count++))
fi
if echo "$html" | grep -qiP '(money.back|guarantee|warranty|secure checkout|ssl|no risk|satisfaction)'; then
  echo "  ✓  Guarantee / trust signals"
  ((sp_count++))
fi

if [ "$sp_count" -eq 0 ]; then
  echo "  ✗  No social proof detected — major CRO gap"
elif [ "$sp_count" -lt 2 ]; then
  echo "  ⚠  Only $sp_count social proof type — add more above the fold"
fi
echo ""

# ── Mobile / responsive ───────────────────────────────
echo "── Mobile & responsive ──"
if echo "$html" | grep -qiP '<meta[^>]+name=["\']viewport["\']'; then
  vp=$(echo "$html" | grep -oP '<meta[^>]+name=["\']viewport["\'].*?>')
  echo "  ✓  Viewport meta: ${vp:0:70}"
else
  echo "  ✗  No viewport meta — not mobile-friendly"
fi

if echo "$html" | grep -qiP '@media\s*(\(|only screen)'; then
  echo "  ✓  Media queries detected (responsive CSS)"
else
  echo "  ⚠  No @media queries found — may not be responsive"
fi

touch_targets=$(echo "$html" | grep -coP '<button|<a[^>]+href=' || true)
# Rough: at least some links/buttons for navigation
if [ "$touch_targets" -lt 3 ]; then
  echo "  ⚠  Very few interactive elements — check for mobile nav"
fi
echo ""

# ── Performance recommendations ───────────────────────
echo "── Quick checks ──"

# Render-blocking (inline scripts without defer/async near top)
if echo "$html" | head -100 | grep -P '<script[^>]+src=' | grep -qvP '(defer|async)'; then
  echo "  ⚠  Render-blocking scripts detected near top of page"
fi

# Font display
if echo "$html" | grep -qiP '@font-face'; then
  if echo "$html" | grep -qiP 'font-display:\s*swap'; then
    echo "  ✓  font-display: swap configured"
  else
    echo "  ⚠  @font-face without font-display: swap — may cause FOIT"
  fi
fi

# Lazy loading
lazy_count=$(echo "$html" | grep -coP 'loading=["\']lazy["\']' || true)
img_count=$(echo "$html" | grep -coP '<img[^>]*>' || true)
if [ "$img_count" -gt 0 ]; then
  echo "  Images:     $img_count total, $lazy_count with lazy loading"
  if [ "$lazy_count" -lt "$((img_count / 2))" ] && [ "$img_count" -gt 2 ]; then
    echo "  ⚠  Few images use lazy loading — consider adding"
  fi
fi

# Alt text
alt_missing=0
img_tags=$(echo "$html" | grep -oP '<img[^>]*>' || true)
while IFS= read -r tag; do
  if ! echo "$tag" | grep -qiP 'alt\s*='; then
    ((alt_missing++))
  fi
done <<< "$img_tags"
if [ "$alt_missing" -gt 0 ]; then
  echo "  ⚠  $alt_missing images missing alt text — accessibility issue"
else
  echo "  ✓  All images have alt text"
fi

# ── Summary ───────────────────────────────────────────
echo ""
echo "───────────────────────────────────────────────"
echo "  Improvement suggestions"
echo "───────────────────────────────────────────────"
suggestions=()

if echo "$title" | grep -qiP '^\s*$'; then
  suggestions+=("Add a descriptive <title> tag (10-70 chars)")
elif [ "$tw" -gt 70 ]; then
  suggestions+=("Shorten <title> to under 70 chars")
fi

if [ -z "$meta_desc" ]; then
  suggestions+=("Add <meta name='description'> — appears in SERP, boosts CTR")
fi

if [ "$h1_count" -ne 1 ]; then
  suggestions+=("Use exactly one <h1> — it's the primary value proposition")
fi

if [ "$cta_found" -eq 0 ]; then
  suggestions+=("Add a clear primary CTA button above the fold")
fi

if [ "$sp_count" -eq 0 ]; then
  suggestions+=("Add social proof near the top (logos, testimonials, or metrics)")
fi

if echo "$html" | grep -qiP '@font-face'; then
  if ! echo "$html" | grep -qiP 'font-display:\s*swap'; then
    suggestions+=("Add font-display: swap to @font-face declarations")
  fi
fi

if [ "$lazy_count" -eq 0 ] && [ "$img_count" -gt 3 ]; then
  suggestions+=("Add loading='lazy' to below-the-fold images")
fi

if [ -n "$total_time" ]; then
  if awk "BEGIN {exit !($total_time > 2.5)}"; then
    suggestions+=("Improve load time ($total_time s) — optimize images, minify CSS/JS, enable CDN")
  fi
fi

if [ ${#suggestions[@]} -eq 0 ]; then
  echo "  No obvious issues found — validate with Lighthouse & real user testing"
else
  for s in "${suggestions[@]}"; do
    echo "  • $s"
  done
fi

echo ""
echo "───────────────────────────────────────────────"
echo "  Next steps: run Lighthouse CLI, hotjar/heap recordings, A/B test 1 element"
echo "───────────────────────────────────────────────"

rm -f /tmp/_lp_analysis.html "$timing_file"
