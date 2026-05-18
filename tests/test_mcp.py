from __future__ import annotations

import json
import os
import subprocess
import sys
from typing import Any

MCP_SERVER = os.path.join(os.path.expanduser("~"), ".shokunin", "memory", "mcp-server.py")
PYTHON = sys.executable


def _mcp_request(method: str, params: dict[str, Any]) -> dict[str, Any]:
    payload = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}) + "\n"
    result = subprocess.run(
        [PYTHON, MCP_SERVER],
        input=payload,
        capture_output=True,
        text=True,
        timeout=15,
    )
    if not result.stdout.strip():
        raise RuntimeError(f"MCP server returned empty stdout. stderr: {result.stderr}")
    return json.loads(result.stdout.strip())


def test_list_tools() -> None:
    data = _mcp_request("tools/list", {})
    tools = data["result"]["tools"]
    tool_names = [t["name"] for t in tools]
    assert "store_context" in tool_names
    assert "search_context" in tool_names
    assert "get_session_summary" in tool_names
    assert len(tools) == 9


def test_invalid_method() -> None:
    data = _mcp_request("nonexistent", {})
    assert "error" in data
    assert data["error"]["code"] == -32601


def test_tool_not_found() -> None:
    data = _mcp_request("tools/call", {"name": "nonexistent", "arguments": {}})
    assert "error" in data
    assert data["error"]["code"] == -32601
