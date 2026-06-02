#!/usr/bin/env bash
set -euo pipefail

CORES_DIR="$HOME/.shokunin"
LOG_DIR="$CORES_DIR/memory/sessions"
HELPER="$CORES_DIR/scripts/chroma-helper.py"
CHECKPOINT_INTERVAL=300

SESSION_ID="session-$(date +%Y%m%d-%H%M%S)-$((RANDOM % 9000 + 1000))"
mkdir -p "$LOG_DIR"

export SHOKUNIN_SESSION_ID="$SESSION_ID"
export SHOKUNIN_PROJECT="$(pwd)"
export SHOKUNIN_MCP_HEALTHY="0"

echo "{\"session_id\":\"$SESSION_ID\",\"project\":\"$(pwd)\",\"start_time\":\"$(date -Iseconds)\",\"pid\":$$}" > "$CORES_DIR/current-session.json"

timeout 3 python3 "$CORES_DIR/memory/mcp-server.py" <<< '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}' 2>/dev/null | grep -q store_context && SHOKUNIN_MCP_HEALTHY="1" || true

echo "=========================================="
echo "  Shokunin - Session: $SESSION_ID"
if [ "$SHOKUNIN_MCP_HEALTHY" = "1" ]; then
    echo "  MCP Server: active"
else
    echo "  MCP Server: fallback mode"
fi
echo "  Project: $(pwd)"
echo "=========================================="

(
    while true; do
        sleep $CHECKPOINT_INTERVAL
        TS=$(date -Iseconds)
        python3 "$HELPER" save "CHECKPOINT: Session $SESSION_ID active at $TS" "$SESSION_ID" "checkpoint" "auto-checkpoint,system" "$(pwd)" 2>/dev/null || true
    done
) &
TIMER_PID=$!

START_TIME=$(date +%s)

opencode
OPENCODE_EXIT=$?

kill $TIMER_PID 2>/dev/null || true

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo ""
echo "  Saving session context..."

SUMMARY="Session: $SESSION_ID
Duration: ${DURATION}s
Date: $(date -Iseconds)
Project: $(pwd)"

SAVED=false
for attempt in 1 2; do
    if python3 "$HELPER" save "$SUMMARY" "$SESSION_ID" "session_end" "auto-save,session-end" "$(pwd)" 2>/dev/null | grep -q stored; then
        SAVED=true; break
    fi
    sleep 0.5
done

if $SAVED; then
    echo "  Memory saved (ChromaDB)"
else
    echo "$SUMMARY" > "$LOG_DIR/$SESSION_ID-summary.md" 2>/dev/null || true
    echo "  Memory saved to: $LOG_DIR/$SESSION_ID-summary.md"
fi

echo "  Duration: ${DURATION}s"
echo "  Session ID: $SESSION_ID"
echo "=========================================="

export SHOKUNIN_LAST_SESSION="$SESSION_ID"
