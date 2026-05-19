"""Shokunin Memory MCP Server — JSON-RPC 2.0 over stdin/stdout."""
from __future__ import annotations

import importlib.util
import json
import logging
import math
import os
import re
import sys
import threading
import uuid
from datetime import datetime, timezone
from typing import Any

import chromadb
from chromadb.config import Settings

_HOME = os.getenv("USERPROFILE") or os.getenv("HOME") or os.path.expanduser("~")
BASE_DIR = os.path.join(_HOME, ".shokunin", "memory")
CHROMA_PATH = os.path.join(BASE_DIR, "chroma_db")
SESSIONS_PATH = os.path.join(BASE_DIR, "sessions")
LOG_PATH = os.path.join(BASE_DIR, "mcp-server.log")
COLLECTION_NAME = "shokunin_memory"

os.makedirs(BASE_DIR, exist_ok=True)

logging.basicConfig(
    filename=LOG_PATH,
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    force=True,
)

_LOGGER = logging.getLogger("shokunin.memory")

_client: chromadb.PersistentClient | None = None
_collection: chromadb.Collection | None = None
_lock = threading.Lock()

def _get_db() -> chromadb.Collection:
    global _client, _collection
    if _client is None:
        with _lock:
            if _client is None:
                _client = chromadb.PersistentClient(
                    path=CHROMA_PATH,
                    settings=Settings(anonymized_telemetry=False),
                )
                _collection = _client.get_or_create_collection(name=COLLECTION_NAME)
    return _collection

_ch_stub = None
def _get_ch() -> Any:
    global _ch_stub
    if _ch_stub is None:
        stub_path = os.path.join(os.path.dirname(BASE_DIR), "scripts", "chroma_helper_stub.py")
        spec = importlib.util.spec_from_file_location("chroma_helper_stub", stub_path)
        if spec is None or spec.loader is None:
            raise RuntimeError(f"Cannot load chroma_helper_stub from {stub_path}")
        _ch_stub = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(_ch_stub)
    return _ch_stub

def _safe_id(sid: str) -> str:
    safe = re.sub(r'\.\.', '', sid).replace(":", "-").replace("/", "-").replace("\\", "-")
    return re.sub(r'[<>"|?*\0]', '-', safe)

def _log_jsonl(session_id: str, entry_type: str, content: str, role: str | None = None) -> None:
    if not session_id:
        return
    safe = _safe_id(session_id)
    fpath = os.path.join(SESSIONS_PATH, f"{safe}.jsonl")
    try:
        os.makedirs(SESSIONS_PATH, exist_ok=True)
        record = {
            "t": entry_type,
            "ts": datetime.now(timezone.utc).isoformat(),
            "session_id": session_id,
            "content": content[:500],
        }
        if role:
            record["role"] = role
        with open(fpath, "a", encoding="utf-8") as f:
            f.write(json.dumps(record, ensure_ascii=False) + "\n")
    except Exception as e:
        _LOGGER.warning(f"Failed to log jsonl for {session_id}: {e}")

VALID_TYPES = {"decision", "file", "command", "preference", "checkpoint", "session_end", "general", "claim_file", "claim_function", "claim_flag", "claim_api", "consolidated"}

_TOOLS = {
    "tools": [
        {
            "name": "store_context",
            "description": "Store a text entry with type, tags, project, and session_id into persistent memory",
            "inputSchema": {
                "type": "object",
                "required": ["text", "session_id"],
                "properties": {
                    "text": {"type": "string", "description": "The text content to store"},
                    "type": {
                        "type": "string",
                        "description": f"Entry type: {', '.join(sorted(VALID_TYPES))}",
                        "enum": list(VALID_TYPES),
                    },
                    "tags": {
                        "type": "array",
                        "items": {"type": "string"},
                        "description": "Tags to categorize this entry",
                    },
                    "project": {"type": "string", "description": "Project name this context belongs to"},
                    "session_id": {"type": "string", "description": "Session identifier"},
                },
            },
        },
        {
            "name": "search_context",
            "description": "Search through stored memory for relevant past context",
            "inputSchema": {
                "type": "object",
                "required": ["query"],
                "properties": {
                    "query": {"type": "string", "description": "Search query text"},
                    "project": {"type": "string", "description": "Filter by project"},
                    "type": {"type": "string", "description": "Filter by entry type"},
                    "tags": {
                        "type": "array",
                        "items": {"type": "string"},
                        "description": "Filter by tags",
                    },
                    "n_results": {"type": "integer", "description": "Number of results (default 10)"},
                    "freshness_boost": {"type": "number", "description": "Blend between vector similarity (0.0) and recency (1.0). Default 0.0."},
                },
            },
        },
        {
            "name": "get_session_summary",
            "description": "Get a summary of all context stored in a given session",
            "inputSchema": {
                "type": "object",
                "required": ["session_id"],
                "properties": {
                    "session_id": {"type": "string", "description": "Session identifier to summarize"},
                },
            },
        },
        {
            "name": "multi_search_context",
            "description": "Search memory using vector + BM25 + temporal filtering with result fusion",
            "inputSchema": {
                "type": "object",
                "required": ["query"],
                "properties": {
                    "query": {"type": "string", "description": "Search query text"},
                    "project": {"type": "string", "description": "Filter by project"},
                    "n_results": {"type": "integer", "description": "Number of results (default 10)"},
                    "freshness_boost": {"type": "number", "description": "Blend between vector similarity (0.0) and recency (1.0). Default 0.0."},
                    "from_date": {"type": "string", "description": "Filter from ISO date (YYYY-MM-DD)"},
                    "to_date": {"type": "string", "description": "Filter to ISO date (YYYY-MM-DD)"},
                },
            },
        },
        {
            "name": "consolidate_memories",
            "description": "Consolidate old memory entries into summarized entries per project",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "project": {"type": "string", "description": "Project to consolidate (all if empty)"},
                },
            },
        },
        {
            "name": "list_sessions",
            "description": "List recent sessions with metadata (project, entry count, summary)",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "limit": {"type": "integer", "description": "Max sessions to list (default 5)"},
                    "project": {"type": "string", "description": "Filter by project"},
                },
            },
        },
        {
            "name": "continue_session",
            "description": "Load full context from a specific session to continue where it left off",
            "inputSchema": {
                "type": "object",
                "required": ["session_id"],
                "properties": {
                    "session_id": {"type": "string", "description": "Session identifier to continue"},
                },
            },
        },
        {
            "name": "save_message",
            "description": "Record an individual message exchange (user or assistant) into the session transcript",
            "inputSchema": {
                "type": "object",
                "required": ["text", "session_id"],
                "properties": {
                    "text": {"type": "string", "description": "Message content"},
                    "session_id": {"type": "string", "description": "Session identifier"},
                    "role": {"type": "string", "description": "user or assistant"},
                },
            },
        },
        {
            "name": "verify_file_path",
            "description": "Verify whether a file or directory path exists on the local filesystem. Supports ~ expansion and relative paths. Use this to validate claims about file locations from old memory entries before acting on them.",
            "inputSchema": {
                "type": "object",
                "required": ["path"],
                "properties": {
                    "path": {"type": "string", "description": "File or directory path to verify. Supports ~ for home directory and relative paths."},
                },
            },
        },
    ],
}

def handle_tools_list() -> dict[str, list[dict[str, Any]]]:
    return _TOOLS


def _save_to_markdown(text: str, session_id: str, entry_type: str, tags: list[str], project: str) -> None:
    try:
        os.makedirs(SESSIONS_PATH, exist_ok=True)
        safe_id = _safe_id(session_id)
        filepath = os.path.join(SESSIONS_PATH, f"{safe_id}.md")
        ts = datetime.now(timezone.utc).isoformat()
        entry = (
            f"## {ts} | type: {entry_type}\n"
            f"- **project:** {project}\n"
            f"- **tags:** {json.dumps(tags)}\n\n"
            f"{text}\n\n"
            f"---\n"
        )
        with open(filepath, "a", encoding="utf-8") as f:
            f.write(entry)
    except Exception as e:
        _LOGGER.warning(f"Failed to save markdown fallback: {e}")


def handle_store_context(args: dict[str, Any]) -> dict[str, Any]:
    if not args:
        return {"error": "args required", "stored": False}
    text = args.get("text", "")
    entry_type = args.get("type", "general")
    if entry_type not in VALID_TYPES:
        entry_type = "general"
    tags = args.get("tags", [])
    project = args.get("project", "")
    session_id = args.get("session_id", "unknown")
    _log_jsonl(session_id, "store", text[:500])
    entry_id = str(uuid.uuid4())
    timestamp = datetime.now(timezone.utc).isoformat()

    metadata = {
        "type": entry_type,
        "tags": json.dumps(tags),
        "project": project,
        "session_id": session_id,
        "timestamp": timestamp,
    }

    try:
        _get_db().add(
            documents=[text],
            metadatas=[metadata],
            ids=[entry_id],
        )
    except Exception as e:
        _LOGGER.error(f"Failed to store in ChromaDB: {e}")

    _save_to_markdown(text, session_id, entry_type, tags, project)

    _LOGGER.info(f"Stored {entry_type} | session={session_id} | project={project} | tags={tags} | id={entry_id}")
    return {"id": entry_id, "type": entry_type, "stored": True}


def handle_search_context(args: dict[str, Any]) -> list[dict[str, Any]]:
    if not args:
        return []
    query = args.get("query", "")
    project = args.get("project")
    session_id = args.get("session_id", "")
    if session_id:
        _log_jsonl(session_id, "search", query)
    entry_type = args.get("type")
    tags = args.get("tags")
    n_results = min(args.get("n_results", 10), 50)
    freshness_boost = min(max(args.get("freshness_boost", 0.0), 0.0), 1.0)

    where_filter = {}
    if project:
        where_filter["project"] = project

    try:
        results = _get_db().query(
            query_texts=[query],
            n_results=n_results,
            where=where_filter if where_filter else None,
        )
    except Exception as e:
        _LOGGER.error(f"Search query failed: {e}")
        return []

    entries: list[dict[str, Any]] = []
    if not results.get("ids") or not results["ids"][0]:
        return entries

    for i, doc_id in enumerate(results["ids"][0]):
        metadata = results["metadatas"][0][i]
        document = results["documents"][0][i]
        distance = results["distances"][0][i]

        try:
            entry_tags = json.loads(metadata.get("tags", "[]"))
        except (json.JSONDecodeError, TypeError):
            entry_tags = []
        entry_type_value = metadata.get("type", "general")

        if entry_type and entry_type_value != entry_type:
            continue
        if tags and not any(t in entry_tags for t in tags):
            continue

        entries.append({
            "text": document[:500],
            "type": entry_type_value,
            "tags": entry_tags,
            "project": metadata.get("project", ""),
            "session_id": metadata.get("session_id", ""),
            "timestamp": metadata.get("timestamp", ""),
            "similarity": round(1.0 / (1.0 + distance), 4),
        })

    if freshness_boost > 0:
        now = datetime.now(timezone.utc)
        for entry in entries:
            ts_str = entry.get("timestamp", "")
            if ts_str:
                try:
                    ts = datetime.fromisoformat(ts_str.replace("Z", "+00:00"))
                    days = (now - ts).total_seconds() / 86400.0
                    recency = math.exp(-days / 30.0)
                    entry["similarity"] = round((1.0 - freshness_boost) * entry["similarity"] + freshness_boost * recency, 4)
                except (ValueError, TypeError):
                    pass
        entries.sort(key=lambda entry: entry["similarity"], reverse=True)

    return entries[:n_results]


def handle_get_session_summary(args: dict[str, Any] | None) -> dict[str, Any]:
    if not args:
        return {"error": "args required", "session_id": "", "entry_count": 0, "entries": [], "summary": "No args provided."}
    session_id = args.get("session_id", "")

    all_results = _get_db().get(
        where={"session_id": session_id},
    )

    ids = all_results.get("ids", [])
    if not ids:
        return {
            "session_id": session_id,
            "entry_count": 0,
            "entries": [],
            "summary": "No entries found for this session.",
        }

    entries = []
    for i in range(min(len(ids), 100)):
        metadata = all_results["metadatas"][i]
        document = all_results["documents"][i]
        truncated = document[:200] + "..." if len(document) > 200 else document
        try:
            entry_tags = json.loads(metadata.get("tags", "[]"))
        except (json.JSONDecodeError, TypeError):
            entry_tags = []
        entries.append({
            "text": truncated,
            "type": metadata.get("type", "general"),
            "tags": entry_tags,
            "project": metadata.get("project", ""),
            "timestamp": metadata.get("timestamp", ""),
        })

    tags_used = set()
    projects_used = set()
    types_used = set()
    for e in entries:
        tags_used.update(e["tags"])
        if e["project"]:
            projects_used.add(e["project"])
        types_used.add(e["type"])

    summary = (
        f"Session {session_id}: {len(entries)} entries, "
        f"{len(tags_used)} tags, "
        f"{len(projects_used)} projects, "
        f"types: {', '.join(sorted(types_used))}."
    )

    return {
        "session_id": session_id,
        "entry_count": len(entries),
        "entries": entries,
        "summary": summary,
    }


def handle_multi_search_context(args: dict[str, Any]) -> dict[str, Any]:
    if not args:
        return {"error": "args required", "entries": [], "count": 0}
    query = args.get("query", "")
    project = args.get("project")
    session_id = args.get("session_id", "")
    if session_id:
        _log_jsonl(session_id, "search", query)
    n_results = min(args.get("n_results", 10), 50)
    freshness_boost = min(max(args.get("freshness_boost", 0.0), 0.0), 1.0)
    from_date = args.get("from_date")
    to_date = args.get("to_date")
    try:
        ch = _get_ch()
        results = ch.recall(query, project, n_results, from_date, to_date, freshness_boost)
        return {"entries": results, "count": len(results)}
    except Exception as e:
        _LOGGER.exception("multi_search_context failed")
        return {"error": str(e), "entries": []}

def handle_consolidate_memories(args: dict[str, Any]) -> dict[str, Any]:
    if not args:
        args = {}
    project = args.get("project")
    try:
        ch = _get_ch()
        result = ch.consolidate(project)
        return result
    except Exception as e:
        _LOGGER.exception("consolidate_memories failed")
        return {"error": str(e), "consolidated": 0}

def handle_list_sessions(args: dict[str, Any]) -> dict[str, Any]:
    if not args:
        args = {}
    limit = min(args.get("limit", 5), 20)
    project = args.get("project")
    try:
        ch = _get_ch()
        return {"sessions": ch.session_list(limit, project)}
    except Exception as e:
        _LOGGER.exception("list_sessions failed")
        return {"error": str(e), "sessions": []}

def handle_continue_session(args: dict[str, Any]) -> dict[str, Any]:
    if not args:
        return {"error": "args required", "entries": []}
    session_id = args.get("session_id", "")
    try:
        ch = _get_ch()
        return ch.session_continue(session_id)
    except Exception as e:
        _LOGGER.exception("continue_session failed")
        return {"error": str(e), "entries": []}

def handle_save_message(args: dict[str, Any]) -> dict[str, Any]:
    if not args:
        return {"error": "args required", "stored": False}
    text = args.get("text", "")
    session_id = args.get("session_id", "")
    role = args.get("role", "user")
    _log_jsonl(session_id, "msg", text, role=role)
    try:
        ch = _get_ch()
        return ch.session_save(text, session_id, role)
    except Exception as e:
        _LOGGER.exception("save_message failed")
        return {"error": str(e), "stored": False}

def handle_verify_file_path(args: dict[str, Any]) -> dict[str, Any]:
    """Verify whether a file or directory path exists on the local filesystem."""
    if not args:
        return {"exists": False, "error": "args required"}
    path = args.get("path", "")
    if not path:
        return {"exists": False, "error": "path required"}
    expanded = os.path.expanduser(path) if path.startswith("~") else path
    if not os.path.isabs(expanded):
        expanded = os.path.join(os.getcwd(), expanded)
    exists = os.path.isfile(expanded) or os.path.isdir(expanded)
    mtime = None
    if exists:
        try:
            mtime = datetime.fromtimestamp(os.path.getmtime(expanded), tz=timezone.utc).isoformat()
        except OSError:
            mtime = None
    kind = None
    if os.path.isfile(expanded):
        kind = "file"
    elif os.path.isdir(expanded):
        kind = "dir"
    return {"exists": exists, "path": expanded, "last_modified": mtime, "kind": kind}


TOOL_HANDLERS = {
    "store_context": handle_store_context,
    "search_context": handle_search_context,
    "get_session_summary": handle_get_session_summary,
    "multi_search_context": handle_multi_search_context,
    "consolidate_memories": handle_consolidate_memories,
    "list_sessions": handle_list_sessions,
    "continue_session": handle_continue_session,
    "save_message": handle_save_message,
    "verify_file_path": handle_verify_file_path,
}


def _dispatch(request: dict[str, Any]) -> dict[str, Any] | None:
    method = request.get("method", "")
    params = request.get("params", {})
    req_id = request.get("id")

    if req_id is None:
        return None  # notifications must not receive a response

    if method == "initialize":
        return {
            "jsonrpc": "2.0",
            "id": req_id,
            "result": {
                "protocolVersion": "2024-11-05",
                "capabilities": {"tools": {}},
                "serverInfo": {"name": "shokunin-memory", "version": "1.0.0"},
            },
        }

    if method == "notifications/initialized":
        return None

    if method == "tools/list":
        result = handle_tools_list()
        return {"jsonrpc": "2.0", "id": req_id, "result": result}

    if method == "tools/call":
        tool_name = params.get("name", "")
        arguments = params.get("arguments", {})
        handler = TOOL_HANDLERS.get(tool_name)
        if handler:
            try:
                tool_result = handler(arguments)
                return {
                    "jsonrpc": "2.0",
                    "id": req_id,
                    "result": {"content": [{"type": "text", "text": json.dumps(tool_result)}]},
                }
            except Exception:
                _LOGGER.exception(f"Error handling tool {tool_name}")
                return {"jsonrpc": "2.0", "id": req_id, "error": {"code": -32000, "message": "Internal server error"}}
        else:
            return {"jsonrpc": "2.0", "id": req_id, "error": {"code": -32601, "message": f"Tool not found: {tool_name}"}}

    return {"jsonrpc": "2.0", "id": req_id, "error": {"code": -32601, "message": f"Method not found: {method}"}}


def main() -> None:
    _LOGGER.info("MCP Memory Server started")
    try:
        for line in sys.stdin:
            line = line.strip()
            if not line:
                continue

            try:
                request = json.loads(line)
            except json.JSONDecodeError:
                continue

            response = _dispatch(request)
            if response is not None:
                sys.stdout.write(json.dumps(response) + "\n")
                sys.stdout.flush()
    except KeyboardInterrupt:
        pass
    finally:
        _LOGGER.info("MCP Memory Server stopped")


if __name__ == "__main__":
    main()
