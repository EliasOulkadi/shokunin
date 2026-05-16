#!/usr/bin/env bash
# ============================================================================
# scan-image.sh — Docker image vulnerability scanner
# Cross-platform: auto-detects bash/PowerShell, wraps docker scout + trivy
# ============================================================================
set -euo pipefail

# -- Detect PowerShell & re-execute -------------------------------------------
if [[ -n "${PSModulePath:-}" ]] && [[ -z "${_PWSH_REEXEC:-}" ]]; then
  export _PWSH_REEXEC=1
  pwsh -NoProfile -File "$0" "$@"
  exit $?
fi

# -- Configuration ------------------------------------------------------------
IMAGE="${1:-}"
OUTPUT="${2:-terminal}"  # terminal, json, sarif
SCANNER="${SCAN_SCANNER:-scout}"  # scout, trivy, both

# -- Colors -------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# -- Help ---------------------------------------------------------------------
usage() {
  cat <<EOF
Usage: $0 <image> [output-format]

Scans a Docker image for vulnerabilities and outputs a summary report.

Arguments:
  image          Docker image reference (e.g., node:22-slim, myapp:latest)
  output-format  terminal | json | sarif  (default: terminal)

Environment:
  SCAN_SCANNER   scout | trivy | both     (default: scout)

Examples:
  $0 node:22-slim
  $0 myapp:latest json
  SCAN_SCANNER=both $0 myapp:latest
EOF
  exit 1
}

# -- Prerequisites ------------------------------------------------------------
check_dep() {
  if ! command -v "$1" &>/dev/null; then
    echo -e "${RED}[FATAL]${NC} '$1' not found. Install it first."
    case "$1" in
      docker)   echo "  → https://docs.docker.com/get-docker/" ;;
      scout)    echo "  → https://docs.docker.com/scout/" ;;
      trivy)    echo "  → https://aquasecurity.github.io/trivy/" ;;
    esac
    return 1
  fi
}

# -- Report functions ---------------------------------------------------------
print_summary() {
  local image="$1" scanner="$2" critical="$3" high="$4" medium="$5" low="$6" total="$7"
  echo ""
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}  SCAN RESULT${NC}"
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "  ${BOLD}Image:${NC}    $image"
  echo -e "  ${BOLD}Scanner:${NC}  $scanner"
  echo -e "  ${BOLD}Total:${NC}    $total"
  echo ""
  printf "  ${RED}%-10s${NC}  %s\n" "CRITICAL" "$critical"
  printf "  ${YELLOW}%-10s${NC}  %s\n" "HIGH"     "$high"
  printf "  ${BOLD}%-10s${NC}  %s\n" "MEDIUM"   "$medium"
  printf "  ${GREEN}%-10s${NC}  %s\n" "LOW"      "$low"
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

  if [ "$critical" -gt 0 ] || [ "$high" -gt 5 ]; then
    echo -e "  ${RED}⚠  Action recommended — address high/critical CVEs.${NC}"
  else
    echo -e "  ${GREEN}✓  Clean image.${NC}"
  fi
  echo ""
}

# -- Docker Scout scan --------------------------------------------------------
scan_scout() {
  local image="$1" fmt="$2"
  echo -e "${CYAN}[scout]${NC} Scanning $image ..."

  case "$fmt" in
    json)
      docker scout cves "$image" --format json 2>/dev/null || {
        echo -e "${YELLOW}[scout]${NC} Fallback: trying docker scout quickview ..."
        docker scout quickview "$image" 2>/dev/null || return 1
      }
      ;;
    sarif)
      docker scout cves "$image" --format sarif 2>/dev/null || return 1
      ;;
    terminal)
      # Parse summary, then show details
      local raw output
      raw=$(docker scout cves "$image" 2>/dev/null) || {
        echo -e "${YELLOW}[scout]${NC} No CVE data found. Trying quickview..."
        raw=$(docker scout quickview "$image" 2>/dev/null) || return 1
      }

      # Extract severity counts
      local critical=0 high=0 medium=0 low=0 total=0
      critical=$(echo "$raw" | grep -oP 'Critical:\s*\K\d+' || echo 0)
      high=$(echo "$raw" | grep -oP 'High:\s*\K\d+' || echo 0)
      medium=$(echo "$raw" | grep -oP 'Medium:\s*\K\d+' || echo 0)
      low=$(echo "$raw" | grep -oP 'Low:\s*\K\d+' || echo 0)
      total=$((critical + high + medium + low))

      print_summary "$image" "Docker Scout" "$critical" "$high" "$medium" "$low" "$total"

      # Print top CVEs
      echo -e "${BOLD}Top CVEs by severity:${NC}"
      echo "$raw" | grep -P '^\s*(CVE|GHSA)' | head -15 | while IFS= read -r line; do
        echo "  $line"
      done
      [ "$(echo "$raw" | grep -cP '^\s*(CVE|GHSA)')" -gt 15 ] && echo "  ... and more"
      ;;
  esac
}

# -- Trivy scan ---------------------------------------------------------------
scan_trivy() {
  local image="$1" fmt="$2"
  echo -e "${CYAN}[trivy]${NC} Scanning $image ..."

  case "$fmt" in
    json)    trivy image --format json --quiet "$image" 2>/dev/null || return 1 ;;
    sarif)   trivy image --format sarif --quiet "$image" 2>/dev/null || return 1 ;;
    terminal)
      # Get JSON output for parsing, then print summary
      local raw
      raw=$(trivy image --format json --quiet "$image" 2>/dev/null) || return 1

      local critical high medium low total
      critical=$(echo "$raw" | python3 -c "import sys,json;r=json.load(sys.stdin);print(sum(v['Severity']=='CRITICAL' for r in r['Results'] for v in r.get('Vulnerabilities',[])))" 2>/dev/null || echo 0)
      high=$(echo "$raw" | python3 -c "import sys,json;r=json.load(sys.stdin);print(sum(v['Severity']=='HIGH' for r in r['Results'] for v in r.get('Vulnerabilities',[])))" 2>/dev/null || echo 0)
      medium=$(echo "$raw" | python3 -c "import sys,json;r=json.load(sys.stdin);print(sum(v['Severity']=='MEDIUM' for r in r['Results'] for v in r.get('Vulnerabilities',[])))" 2>/dev/null || echo 0)
      low=$(echo "$raw" | python3 -c "import sys,json;r=json.load(sys.stdin);print(sum(v['Severity']=='LOW' for r in r['Results'] for v in r.get('Vulnerabilities',[])))" 2>/dev/null || echo 0)
      total=$((critical + high + medium + low))

      print_summary "$image" "Trivy" "$critical" "$high" "$medium" "$low" "$total"

      # Print top CVEs
      echo -e "${BOLD}Top CVEs by severity:${NC}"
      echo "$raw" | python3 -c "
import sys, json
r = json.load(sys.stdin)
vulns = []
for res in r.get('Results', []):
  for v in res.get('Vulnerabilities', []):
    vulns.append(v)
vulns.sort(key=lambda v: {'CRITICAL':0,'HIGH':1,'MEDIUM':2,'LOW':3,'UNKNOWN':4}.get(v.get('Severity'),5))
for v in vulns[:15]:
  print(f'  {v[\"VulnerabilityID\"]} ({v.get(\"Severity\",\"?\")}) — {v.get(\"PkgName\",\"?\")} {v.get(\"InstalledVersion\",\"?\")} → {v.get(\"FixedVersion\",\"?\")}')
" 2>/dev/null
      [ "$total" -gt 15 ] && echo "  ... and more"
      ;;
  esac
}

# -- Main ---------------------------------------------------------------------
main() {
  if [ -z "$IMAGE" ]; then
    echo -e "${RED}[ERROR]${NC} No image specified."
    usage
  fi

  # Validate image exists locally or pull
  if ! docker image inspect "$IMAGE" &>/dev/null; then
    echo -e "${YELLOW}[INFO]${NC} Image not found locally. Pulling $IMAGE ..."
    docker pull "$IMAGE" || {
      echo -e "${RED}[ERROR]${NC} Failed to pull $IMAGE"
      exit 1
    }
  fi

  case "$SCANNER" in
    scout)
      check_dep docker
      scan_scout "$IMAGE" "$OUTPUT"
      ;;
    trivy)
      check_dep docker
      check_dep trivy
      scan_trivy "$IMAGE" "$OUTPUT"
      ;;
    both)
      check_dep docker
      check_dep trivy
      scan_scout "$IMAGE" "$OUTPUT"
      echo ""
      scan_trivy "$IMAGE" "$OUTPUT"
      ;;
    *)
      echo -e "${RED}[ERROR]${NC} Unknown scanner '$SCANNER'. Use: scout, trivy, both"
      exit 1
      ;;
  esac
}

main "$@"
