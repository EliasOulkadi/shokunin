"""Shokunin Memory MCP Server — JSON-RPC 2.0 over stdin/stdout."""
from __future__ import annotations

import importlib.util
import json
import logging
import os
import re
import sys
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

def _get_db() -> chromadb.Collection:
    global _client, _collection
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
        spec = importlib.util.spec_from_file_location("chroma_helper_stub", stub_path)  # type: ignore[arg-type]
        _ch_stub = importlib.util.module_from_spec(spec)  # type: ignore[arg-type]
        spec.loader.exec_module(_ch_stub)  # type: ignore[union-attr]
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
        pass

VALID_TYPES = {"decision", "file", "command", "preference", "checkpoint", "session_end", "general"}

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
                        "description": "Entry type: decision, file, command, preference, checkpoint, session_end, general",
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
    text = args.get("text", "")
    entry_type = args.get("type", "general")
    if entry_type not in VALID_TYPES:
        entry_type = "general"
    tags = args.get("tags", [])
    project = args.get("project", "")
    session_id = args.get("session_id", "unknown")
    _log_jsonl(session_id, "store", text[:500], role=entry_type)
    entry_id = str(uuid.uuid4())
    timestamp = datetime.now(timezone.utc).isoformat()

    metadata = {
        "type": entry_type,
        "tags": json.dumps(tags),
        "project": project,
        "session_id": session_id,
        "timestamp": timestamp,
    }

    _get_db().add(
        documents=[text],
        metadatas=[metadata],
        ids=[entry_id],
    )

    _save_to_markdown(text, session_id, entry_type, tags, project)

    _LOGGER.info(f"Stored {entry_type} | session={session_id} | project={project} | tags={tags} | id={entry_id}")
    return {"id": entry_id, "type": entry_type, "stored": True}


def handle_search_context(args: dict[str, Any]) -> list[dict[str, Any]]:
    query = args.get("query", "")
    project = args.get("project")
    session_id = args.get("session_id", "")
    _log_jsonl(session_id, "search", query)
    entry_type = args.get("type")
    tags = args.get("tags")
    n_results = min(args.get("n_results", 10), 50)

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

        entry_tags = json.loads(metadata.get("tags", "[]"))
        entry_type = metadata.get("type", "general")

        if entry_type and tags and not any(t in entry_tags for t in tags):
            continue

        entries.append({
            "text": document[:500],
            "type": entry_type,
            "tags": entry_tags,
            "project": metadata.get("project", ""),
            "session_id": metadata.get("session_id", ""),
            "timestamp": metadata.get("timestamp", ""),
            "similarity": round(1.0 / (1.0 + distance), 4),
        })

    return entries[:5]


def handle_get_session_summary(args: dict[str, Any]) -> dict[str, Any]:
    session_id = args["session_id"]

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
    for i in range(len(ids)):
        metadata = all_results["metadatas"][i]
        document = all_results["documents"][i]
        truncated = document[:200] + "..." if len(document) > 200 else document
        entries.append({
            "text": truncated,
            "type": metadata.get("type", "general"),
            "tags": json.loads(metadata.get("tags", "[]")),
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
    query = args.get("query", "")
    project = args.get("project")
    session_id = args.get("session_id", "")
    _log_jsonl(session_id, "search", query)
    n_results = min(args.get("n_results", 10), 50)
    from_date = args.get("from_date")
    to_date = args.get("to_date")
    try:
        ch = _get_ch()
        results = ch.recall(query, project, n_results, from_date, to_date)
        return {"entries": results, "count": len(results)}
    except Exception as e:
        _LOGGER.exception("multi_search_context failed")
        return {"error": str(e), "entries": []}

def handle_consolidate_memories(args: dict[str, Any]) -> dict[str, Any]:
    project = args.get("project")
    try:
        ch = _get_ch()
        result = ch.consolidate(project)
        return result
    except Exception as e:
        _LOGGER.exception("consolidate_memories failed")
        return {"error": str(e), "consolidated": 0}

def handle_list_sessions(args: dict[str, Any]) -> dict[str, Any]:
    limit = min(args.get("limit", 5), 20)
    project = args.get("project")
    try:
        ch = _get_ch()
        return {"sessions": ch.session_list(limit, project)}
    except Exception as e:
        _LOGGER.exception("list_sessions failed")
        return {"error": str(e), "sessions": []}

def handle_continue_session(args: dict[str, Any]) -> dict[str, Any]:
    session_id = args.get("session_id", "")
    try:
        ch = _get_ch()
        return ch.session_continue(session_id)
    except Exception as e:
        _LOGGER.exception("continue_session failed")
        return {"error": str(e), "entries": []}

def handle_save_message(args: dict[str, Any]) -> dict[str, Any]:
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

TOOL_HANDLERS = {
    "store_context": handle_store_context,
    "search_context": handle_search_context,
    "get_session_summary": handle_get_session_summary,
    "multi_search_context": handle_multi_search_context,
    "consolidate_memories": handle_consolidate_memories,
    "list_sessions": handle_list_sessions,
    "continue_session": handle_continue_session,
    "save_message": handle_save_message,
}


def _dispatch(request: dict[str, Any]) -> dict[str, Any] | None:
    method = request.get("method", "")
    params = request.get("params", {})
    req_id = request.get("id")

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
            except Exception as e:
                _LOGGER.exception(f"Error handling tool {tool_name}")
                return {"jsonrpc": "2.0", "id": req_id, "error": {"code": -32000, "message": "Internal server error"}}
        else:
            return {"jsonrpc": "2.0", "id": req_id, "error": {"code": -32601, "message": f"Tool not found: {tool_name}"}}

    return {"jsonrpc": "2.0", "id": req_id, "error": {"code": -32601, "message": f"Method not found: {method}"}}


def main() -> None:
    _LOGGER.info("MCP Memory Server started")
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

    _LOGGER.info("MCP Memory Server stopped")


if __name__ == "__main__":
    main()
