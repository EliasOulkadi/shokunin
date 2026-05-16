#!/usr/bin/env bash
# ============================================================================
# optimize-dockerfile.sh — Dockerfile optimization analyzer
# Cross-platform: works in bash (Linux/macOS/WSL) and PowerShell on Windows
# ============================================================================
set -euo pipefail

OPT_DOCKERFILE="${1:-Dockerfile}"

if ! [ -f "$OPT_DOCKERFILE" ]; then
  echo "ERROR: File '$OPT_DOCKERFILE' not found."
  echo "Usage: $0 <path-to-Dockerfile>"
  exit 1
fi

# -- Detect PowerShell runtime -------------------------------------------------
if [[ -n "${PSModulePath:-}" ]]; then
  # PowerShell detected — re-execute as PowerShell script
  pwsh -NoProfile -File "$0" "$@"
  exit $?
fi

# -- Helpers -------------------------------------------------------------------
header()  { printf "\n\033[1;36m━━━ %s ━━━\033[0m\n" "$1"; }
pass()    { printf "  \033[1;32m✓\033[0m %s\n" "$1"; }
warn()    { printf "  \033[1;33m⚠\033[0m %s\n" "$1"; }
fail()    { printf "  \033[1;31m✗\033[0m %s\n" "$1"; }
code()    { printf "    \033[90m%s\033[0m\n" "$1"; }
sep()     { printf "\n"; }

line_matches() { grep -cE "$1" "$OPT_DOCKERFILE" 2>/dev/null || echo 0; }
line_value()   { grep -oP "$1" "$OPT_DOCKERFILE" 2>/dev/null | head -1 || echo ""; }

# ==============================================================================

header "1. MULTI-STAGE BUILD ANALYSIS"

STAGES=$(grep -c "^FROM " "$OPT_DOCKERFILE" 2>/dev/null || echo 0)
if [ "$STAGES" -lt 2 ]; then
  fail "Single-stage build detected ($STAGES FROM). Add at least 2 stages: builder + runtime."
  code "# Ideal structure:"
  code "  FROM base AS builder    # compile / install deps"
  code "  FROM distroless AS runtime  # minimal runtime"
  code "  COPY --from=builder ... # copy only artifacts"
else
  pass "Multi-stage build with $STAGES stages."
  grep -n "^FROM " "$OPT_DOCKERFILE" | while IFS=: read -r ln line; do
    code "  Stage at line $ln: $line"
  done
fi

sep

# ------------------------------------------------------------------------------
header "2. BASE IMAGE AUDIT"

if grep -qiE ':\s*(latest|latest)\s*$' "$OPT_DOCKERFILE" 2>/dev/null; then
  fail "Unpinned tag 'latest' found. Pin to a specific version."
  code "  Bad:  FROM node:latest"
  code "  Good: FROM node:22-slim"
else
  pass "Base images are version-pinned."
fi

ALPINE=$(line_matches '-alpine[^a-z]')
SLIM=$(line_matches '-slim[^a-z]')
DISTROLESS=$(line_matches 'distroless')
SCRATCH=$(line_matches 'scratch')
if [ "$DISTROLESS" -gt 0 ] || [ "$SCRATCH" -gt 0 ]; then
  pass "Runtime stage uses distroless/scratch — minimal attack surface."
elif [ "$ALPINE" -gt 0 ]; then
  warn "Runtime uses Alpine. Consider distroless for stricter security."
elif [ "$SLIM" -gt 0 ]; then
  warn "Runtime uses slim. Consider distroless for production."
fi

sep

# ------------------------------------------------------------------------------
header "3. LAYER CACHE OPTIMIZATION"

PKG_LINES_BEFORE_COPY=$(grep -n "COPY\|ADD\|RUN\|WORKDIR" "$OPT_DOCKERFILE" 2>/dev/null | head -40)
COPIED_ALL=$(grep -cP '^COPY\s+\.\s+\.' "$OPT_DOCKERFILE" 2>/dev/null || echo 0)
if [ "$COPIED_ALL" -gt 0 ]; then
  warn "Bare 'COPY . .' detected before dependency installation."
  code "  Order: COPY package files → RUN install → COPY source"
  code "  Bad:   COPY . . && RUN npm install"
  code "  Good:  COPY package*.json ./ && RUN npm ci && COPY . ."
else
  pass "Dependency files likely copied before source (check ordering manually)."
fi

# Check for combined apt operations
APT_LINES=$(line_matches 'apt-get update')
APT_INSTALL=$(line_matches 'apt-get install')
if [ "$APT_LINES" -gt 0 ] || [ "$APT_INSTALL" -gt 0 ]; then
  APT_SEPARATE=$(grep -cP 'RUN\s+.*apt-get update' "$OPT_DOCKERFILE" 2>/dev/null || echo 0)
  APT_SAME=$(grep -cP 'RUN\s+.*apt-get update\s+.*&&\s+.*apt-get install' "$OPT_DOCKERFILE" 2>/dev/null || echo 0)
  APT_CLEANUP=$(grep -cP '(rm\s+-rf\s+/var/lib/apt|apt-get clean|--no-install-recommends)' "$OPT_DOCKERFILE" 2>/dev/null || echo 0)
  if [ "$APT_SAME" -eq 0 ]; then
    fail "'apt-get update' and 'apt-get install' are in separate RUN commands."
    code "  Combine: RUN apt-get update && apt-get install -y --no-install-recommends ... && rm -rf /var/lib/apt/lists/*"
  else
    pass "'apt-get update' and 'apt-get install' combined."
  fi
  if [ "$APT_CLEANUP" -eq 0 ]; then
    fail "No apt cleanup found. Add '--no-install-recommends' and 'rm -rf /var/lib/apt/lists/*'."
  else
    pass "Apt cleanup present."
  fi
fi

sep

# ------------------------------------------------------------------------------
header "4. BUILDKIT CACHE MOUNTS"

CACHE_MOUNTS=$(line_matches '--mount=type=cache')
SECRET_MOUNTS=$(line_matches '--mount=type=secret')
BUILDKIT_SYNTAX=$(grep -cP '^#\s*syntax=' "$OPT_DOCKERFILE" 2>/dev/null || echo 0)

if [ "$CACHE_MOUNTS" -gt 0 ]; then
  pass "BuildKit cache mounts found ($CACHE_MOUNTS)."
else
  fail "No BuildKit cache mounts. Add 'RUN --mount=type=cache,target=<cache-dir>' for package managers."
  code "  npm:   --mount=type=cache,target=/root/.npm"
  code "  pip:   --mount=type=cache,target=/root/.cache/pip"
  code "  go:    --mount=type=cache,target=/go/pkg/mod"
  code "  apt:   --mount=type=cache,target=/var/cache/apt"
fi

if [ "$SECRET_MOUNTS" -eq 0 ]; then
  fail "No secret mounts. Use '--mount=type=secret,id=<name>' instead of build ARGs for secrets."
else
  pass "Secret mounts present."
fi

if [ "$BUILDKIT_SYNTAX" -eq 0 ]; then
  warn "No '# syntax=' directive. Add '# syntax=docker/dockerfile:1' for consistent parser behavior."
fi

sep

# ------------------------------------------------------------------------------
header "5. SECURITY HARDENING"

USER_STMT=$(line_matches '^USER\s+')
ROOT_USER=$(grep -cP '^USER\s+root' "$OPT_DOCKERFILE" 2>/dev/null || echo 0)
NONROOT_USER=$(grep -cP '^USER\s+(nonroot|nobody|[0-9]+)\s' "$OPT_DOCKERFILE" 2>/dev/null || echo 0)
HEALTHCHECK=$(line_matches 'HEALTHCHECK')
ADD_SCRATCH=$(grep -cP '^ADD\s+' "$OPT_DOCKERFILE" 2>/dev/null || echo 0)

if [ "$USER_STMT" -gt 0 ]; then
  if [ "$NONROOT_USER" -gt 0 ]; then
    pass "Non-root user set."
  else
    fail "USER root detected. Switch to non-root: 'USER nonroot' or 'USER nobody'."
  fi
else
  fail "No USER directive. Add 'USER nonroot' before CMD/ENTRYPOINT."
fi

if [ "$HEALTHCHECK" -gt 0 ]; then
  pass "HEALTHCHECK present."
else
  fail "No HEALTHCHECK. Add one — orchestrators rely on it for container health."
  code "  HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \\"
  code "    CMD curl -f http://localhost:3000/health || exit 1"
fi

if [ "$ADD_SCRATCH" -gt 0 ]; then
  warn "'ADD' detected. Prefer 'COPY' — ADD has automatic tar extraction and remote URL features that can be surprising."
fi

# Check for exposed ports
EXPOSE_LINES=$(line_matches 'EXPOSE\s+')
if [ "$EXPOSE_LINES" -eq 0 ]; then
  warn "No EXPOSE directive. Add 'EXPOSE <port>' for documentation."
fi

sep

# ------------------------------------------------------------------------------
header "6. DOCKERIGNORE CHECK"

if [ -f ".dockerignore" ]; then
  pass ".dockerignore found."
  IGNORE_COUNT=$(wc -l < ".dockerignore" 2>/dev/null | tr -d ' ')
  if [ "$IGNORE_COUNT" -lt 3 ]; then
    warn ".dockerignore only has $IGNORE_COUNT entries. Consider adding:"
    code "  node_modules/"
    code "  .git/"
    code "  .env"
    code "  build/"
    code "  *.log"
  fi
else
  fail "No .dockerignore found. Creates unnecessarily large build context."
fi

sep

# ------------------------------------------------------------------------------
header "7. OVERALL SCORE"

SCORE=0
TOTAL=10

# Count passing checks
grep -q "✓" <<< "" && true  # reset
PASS_COUNT=$(grep -c '\[32m✓' "$0" 2>/dev/null || echo 0)
# Simple heuristic: count how many pass() were called in this run
FOUND_PASSES=$(grep -cP 'pass\(.*\)' "$OPT_DOCKERFILE" 2>/dev/null || echo 0)

# More reliable: re-analyze
PASS_SCORE=0
FAIL_SCORE=0

[ "$STAGES" -ge 2 ] && PASS_SCORE=$((PASS_SCORE + 2))
[ "$DISTROLESS" -gt 0 ] && PASS_SCORE=$((PASS_SCORE + 2)) || [ "$SCRATCH" -gt 0 ] && PASS_SCORE=$((PASS_SCORE + 2))
[ "$CACHE_MOUNTS" -gt 0 ] && PASS_SCORE=$((PASS_SCORE + 1))
[ "$SECRET_MOUNTS" -gt 0 ] && PASS_SCORE=$((PASS_SCORE + 1))
[ "$NONROOT_USER" -gt 0 ] && PASS_SCORE=$((PASS_SCORE + 2))
[ "$HEALTHCHECK" -gt 0 ] && PASS_SCORE=$((PASS_SCORE + 1))
[ -f ".dockerignore" ] && PASS_SCORE=$((PASS_SCORE + 1))

printf "  Score: %d/10\n" "$PASS_SCORE"
if [ "$PASS_SCORE" -ge 8 ]; then
  printf "  Grade: \033[1;32mExcellent\033[0m\n"
elif [ "$PASS_SCORE" -ge 5 ]; then
  printf "  Grade: \033[1;33mNeeds improvement\033[0m\n"
else
  printf "  Grade: \033[1;31mOverhaul recommended\033[0m\n"
fi

sep
header "REPORT COMPLETE"
echo ""
