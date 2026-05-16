#!/usr/bin/env bash
set -euo pipefail

POD="${1:?Usage: $0 <pod-name> [namespace]}"
NS="${2:-default}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()  { echo -e "${CYAN}[$(date +%H:%M:%S)]${NC} $*"; }
pass() { echo -e "${GREEN}  ✓${NC} $*"; }
fail() { echo -e "${RED}  ✗${NC} $*"; }
warn() { echo -e "${YELLOW}  ⚠${NC} $*"; }

echo -e "\n${CYAN}══════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  Debugging pod ${POD} in namespace ${NS}${NC}"
echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}\n"

# ── Step 1: Check pod exists ──────────────────────────────────────────────
log "Step 1/5: Checking pod status..."
if ! kubectl get pod "$POD" -n "$NS" &>/dev/null; then
  fail "Pod '$POD' not found in namespace '$NS'"
  echo "  Try: kubectl get pods -n $NS | grep -i '$POD'"
  exit 1
fi

PHASE=$(kubectl get pod "$POD" -n "$NS" -o jsonpath='{.status.phase}')
case "$PHASE" in
  Running)  pass "Phase: $PHASE" ;;
  Pending)  warn "Phase: $PHASE — waiting for resources/init" ;;
  Failed)   fail "Phase: $PHASE — container exited with error" ;;
  Unknown)  fail "Phase: $PHASE — node may be unreachable" ;;
  Succeeded) warn "Phase: $PHASE — pod completed (batch job)" ;;
esac

# ── Step 2: kubectl describe ─────────────────────────────────────────────
log "Step 2/5: Describing pod..."
kubectl describe pod "$POD" -n "$NS" 2>&1 | head -80
echo "..."

# ── Step 3: Container statuses ───────────────────────────────────────────
log "Step 3/5: Container states..."
kubectl get pod "$POD" -n "$NS" -o json | jq -r '
  .status.containerStatuses[] // [] | 
  "  Name:    \(.name)\n  Ready:   \(.ready)\n  State:   \(.state | keys[0])\n  Restart: \(.restartCount)\n" +
  if .state.waiting?.reason then "  Reason:  \(.state.waiting.reason)\n  Message: \(.state.waiting.message // "")\n" else "" end
' 2>/dev/null || {
  kubectl get pod "$POD" -n "$NS" -o jsonpath='{range .status.containerStatuses[*]}  {.name}  ready={.ready}  restart={.restartCount}{"\n"}{end}'
}

# ── Step 4: Logs (current + previous) ────────────────────────────────────
log "Step 4/5: Capturing logs..."

CONTAINERS=$(kubectl get pod "$POD" -n "$NS" -o jsonpath='{.spec.containers[*].name}')
for c in $CONTAINERS; do
  echo ""
  warn "--- Container: $c ---"
  if LOGS=$(kubectl logs "$POD" -n "$NS" -c "$c" --tail=100 2>&1); then
    echo "$LOGS" | tail -50
  else
    warn "No current logs"
  fi

  if PREV=$(kubectl logs "$POD" -n "$NS" -c "$c" --previous --tail=50 2>&1); then
    echo ""
    warn "--- Previous logs ($c) ---"
    echo "$PREV"
  fi
done

# ── Step 5: Events sorted by time ────────────────────────────────────────
log "Step 5/5: Related events..."
kubectl get events -n "$NS" --sort-by=.lastTimestamp 2>&1 | grep -i "$POD" | tail -30 || fail "No matching events"

# ── Quick diagnostics ────────────────────────────────────────────────────
echo ""
log "Diagnostic summary:"
case "$PHASE" in
  Pending)
    EVENTS=$(kubectl get events -n "$NS" --sort-by=.lastTimestamp 2>&1 | grep "$POD" | tail -5)
    if echo "$EVENTS" | grep -qi "insufficient\|cpu\|memory\|nodes available\|FailedScheduling"; then
      warn "SUSPECT: Resource constraints — check cluster capacity"
    fi
    if echo "$EVENTS" | grep -qi "ImagePullBackOff\|ErrImagePull\|BackOff"; then
      warn "SUSPECT: Image pull failure — check registry credentials and image name"
    fi
    if echo "$EVENTS" | grep -qi "MatchNodeSelector\|NoNodeWithLabels\|node affinity"; then
      warn "SUSPECT: Node selector/affinity — no matching nodes"
    fi
    if echo "$EVENTS" | grep -qi "PersistentVolumeClaim\|MountVolume\|VolumeBinding\|PodExceedsFreeResource"; then
      warn "SUSPECT: PVC binding or volume mount issue"
    fi
    if echo "$EVENTS" | grep -qi "failed to start container\|failed to create\|InvalidImage\|registry"; then
      warn "SUSPECT: Container runtime error — check image and container config"
    fi
    ;;
  Running)
    RESTARTS=$(kubectl get pod "$POD" -n "$NS" -o jsonpath='{.status.containerStatuses[0].restartCount}')
    if [ "$RESTARTS" -gt 0 ]; then
      EXIT_CODE=$(kubectl get pod "$POD" -n "$NS" -o jsonpath='{.status.containerStatuses[0].lastState.terminated.exitCode}')
      warn "SUSPECT: Container restarting (exit $EXIT_CODE) — check previous logs above"
      if [ "$EXIT_CODE" = "137" ]; then
        warn "  Exit 137 = OOMKilled — consider increasing memory limits"
      elif [ "$EXIT_CODE" = "139" ]; then
        warn "  Exit 139 = SIGSEGV — segmentation fault in application"
      elif [ "$EXIT_CODE" = "143" ]; then
        warn "  Exit 143 = SIGTERM — pod being evicted or shut down"
      fi
    fi
    ;;
  Failed)
    fail "Container exited — see 'Reason' above and previous logs"
    ;;
esac

echo ""
log "Next steps:"
echo "  # Port-forward for local testing"
echo "  kubectl port-forward pod/$POD 8080:PORT -n $NS"
echo ""
echo "  # Ephemeral debug container"
echo "  kubectl debug -it $POD --image=nicolaka/netshoot:latest -- /bin/bash -n $NS"
echo ""
echo "  # Exec into container (if running)"
echo "  kubectl exec -it $POD -n $NS -- /bin/sh"
