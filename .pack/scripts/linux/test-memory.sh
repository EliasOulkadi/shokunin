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
echo "Shokunin Memory Tests"
echo "====================="
echo ""

echo "[1/5] Environment"
check "python3 --version" "Python available"
check "python3 -c 'import chromadb; print(\"ok\")'" "chromadb importable"

echo "[2/5] chroma-helper"
HELPER="$HOME/.shokunin/scripts/chroma-helper.py"
TEST_ID="test-$(date +%s)"
check "python3 $HELPER save 'Linux test entry' '$TEST_ID' test test memory linux-test 2>&1 | grep -q stored" "save entry"
check "python3 $HELPER search 'Linux test' linux-test 2>&1 | grep -q '$TEST_ID'" "search entry"
check "python3 $HELPER count 2>&1 | grep -q count" "count entries"

echo "[3/5] MCP Server"
MCP="$HOME/.shokunin/memory/mcp-server.py"
check "echo '{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/list\",\"params\":{}}' | timeout 3 python3 $MCP 2>&1 | grep -q store_context" "tools/list responds"
SID="mcp-test-$(date +%s)"
check "echo '{\"jsonrpc\":\"2.0\",\"id\":2,\"method\":\"tools/call\",\"params\":{\"name\":\"store_context\",\"arguments\":{\"text\":\"MCP Linux test\",\"session_id\":\"$SID\",\"type\":\"test\",\"tags\":[\"ci\"]}}}' | timeout 3 python3 $MCP 2>&1 | grep -q stored" "store via MCP"

echo "[4/5] Scripts"
for script in "$HOME/.shokunin/scripts/linux/"*.sh; do
    check "bash -n \"$script\"" "$(basename $script) parses"
done

echo "[5/5] Config"
check "grep -q 'MEMORY SYSTEM' \"$HOME/.claude/CLAUDE.md\" 2>/dev/null || grep -q 'MEMORY SYSTEM' \"$HOME/AGENTS.md\" 2>/dev/null" "Instructions have memory section"

echo ""
echo "====================="
if [ $FAIL -eq 0 ]; then
    echo "  ALL PASSED ($PASS passed)"
else
    echo "  $FAIL FAILED, $PASS passed"
    exit 1
fi
echo "====================="
