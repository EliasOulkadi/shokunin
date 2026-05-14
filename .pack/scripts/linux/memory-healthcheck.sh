#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0

check() {
    if eval "$1" 2>/dev/null; then
        echo "  PASS  $2"
        PASS=$((PASS + 1))
    else
        echo "  FAIL  $2"
        FAIL=$((FAIL + 1))
    fi
}

echo ""
echo "Shokunin Memory Healthcheck"
echo "=========================================="
echo ""

echo "[Environment]"
check "python3 --version" "Python available"
check "python3 -c 'import chromadb; print(\"ok\")'" "chromadb importable"
check "[ -d \"$HOME/.shokunin/memory\" ]" "Data directory exists"

echo "[chroma-helper]"
HELPER="$HOME/.shokunin/scripts/chroma-helper.py"
TEST_ID="healthcheck-$(date +%s)"
check "python3 \"$HELPER\" save 'Healthcheck test' '$TEST_ID' test healthcheck healthcheck 2>&1 | grep -q stored" "save entry"
check "python3 \"$HELPER\" search 'Healthcheck test' healthcheck 2>&1 | grep -q \"$TEST_ID\"" "search entry"
check "python3 $HELPER count 2>&1 | grep -q count" "count entries"

echo "[MCP Server]"
MCP="$HOME/.shokunin/memory/mcp-server.py"
check "echo '{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/list\",\"params\":{}}' | python3 $MCP 2>&1 | grep -q store_context" "tools/list responds"

echo "[Configuration]"
check "grep -q 'MEMORY SYSTEM' \"$HOME/.claude/CLAUDE.md\" 2>/dev/null || grep -q 'MEMORY SYSTEM' \"$HOME/AGENTS.md\" 2>/dev/null" "Instructions have memory section"

echo "[Storage]"
check "touch \"$HOME/.shokunin/memory/sessions/.write-test\" && rm -f \"$HOME/.shokunin/memory/sessions/.write-test\"" "sessions dir writable"
# check disabled - would overwrite active session file

echo ""
echo "=========================================="
if [ $FAIL -eq 0 ]; then
    echo "  ALL PASSED ($PASS passed)"
else
    echo "  $FAIL FAILED, $PASS passed"
    exit 1
fi
echo "=========================================="
