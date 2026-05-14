import os
import json
import sys
import uuid
import logging
from datetime import datetime, timezone

import chromadb
from chromadb.config import Settings

BASE_DIR = os.path.join(os.environ["USERPROFILE"], ".shokunin", "memory")
CHROMA_PATH = os.path.join(BASE_DIR, "chroma_db")
SESSIONS_PATH = os.path.join(BASE_DIR, "sessions")
LOG_PATH = os.path.join(BASE_DIR, "mcp-server.log")
COLLECTION_NAME = "shokunin_memory"

logging.basicConfig(
    filename=LOG_PATH,
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    force=True,
)

client = chromadb.PersistentClient(
    path=CHROMA_PATH,
    settings=Settings(anonymized_telemetry=False),
)
collection = client.get_or_create_collection(name=COLLECTION_NAME)

VALID_TYPES = {"decision", "file", "command", "preference", "checkpoint", "session_end", "general"}


def handle_tools_list():
    return {
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
        ],
    }


def _save_to_markdown(text, session_id, entry_type, tags, project):
    try:
        os.makedirs(SESSIONS_PATH, exist_ok=True)
        safe_id = session_id.replace(":", "-").replace("/", "-")
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
        logging.warning(f"Failed to save markdown fallback: {e}")


def handle_store_context(args):
    text = args.get("text", "")
    entry_type = args.get("type", "general")
    if entry_type not in VALID_TYPES:
        entry_type = "general"
    tags = args.get("tags", [])
    project = args.get("project", "")
    session_id = args.get("session_id", "unknown")
    entry_id = str(uuid.uuid4())
    timestamp = datetime.now(timezone.utc).isoformat()

    metadata = {
        "type": entry_type,
        "tags": json.dumps(tags),
        "project": project,
        "session_id": session_id,
        "timestamp": timestamp,
    }

    collection.add(
        documents=[text],
        metadatas=[metadata],
        ids=[entry_id],
    )

    _save_to_markdown(text, session_id, entry_type, tags, project)

    logging.info(f"Stored {entry_type} | session={session_id} | project={project} | tags={tags} | id={entry_id}")
    return {"id": entry_id, "type": entry_type, "stored": True}


def handle_search_context(args):
    query = args.get("query", "")
    project = args.get("project")
    entry_type = args.get("type")
    tags = args.get("tags")
    n_results = min(args.get("n_results", 10), 50)

    where_filter = {}
    if project:
        where_filter["project"] = project

    try:
        results = collection.query(
            query_texts=[query],
            n_results=n_results,
            where=where_filter if where_filter else None,
        )
    except Exception as e:
        logging.error(f"Search query failed: {e}")
        return {"error": str(e), "entries": []}

    entries = []
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
            "similarity": round(1.0 - distance, 4),
        })

    return entries[:5]


def handle_get_session_summary(args):
    session_id = args["session_id"]

    all_results = collection.get(
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


TOOL_HANDLERS = {
    "store_context": handle_store_context,
    "search_context": handle_search_context,
    "get_session_summary": handle_get_session_summary,
}


def main():
    logging.info("MCP Memory Server started")
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue

        try:
            request = json.loads(line)
        except json.JSONDecodeError:
            continue

        req_id = request.get("id")
        method = request.get("method", "")
        params = request.get("params", {})

        if method == "tools/list":
            result = handle_tools_list()
            response = {"jsonrpc": "2.0", "id": req_id, "result": result}

        elif method == "tools/call":
            tool_name = params.get("name", "")
            arguments = params.get("arguments", {})

            handler = TOOL_HANDLERS.get(tool_name)
            if handler:
                try:
                    tool_result = handler(arguments)
                    response = {
                        "jsonrpc": "2.0",
                        "id": req_id,
                        "result": {
                            "content": [
                                {"type": "text", "text": json.dumps(tool_result)}
                            ]
                        },
                    }
                except Exception as e:
                    logging.exception(f"Error handling tool {tool_name}")
                    response = {
                        "jsonrpc": "2.0",
                        "id": req_id,
                        "error": {"code": -32000, "message": str(e)},
                    }
            else:
                response = {
                    "jsonrpc": "2.0",
                    "id": req_id,
                    "error": {"code": -32601, "message": f"Tool not found: {tool_name}"},
                }
        else:
            response = {
                "jsonrpc": "2.0",
                "id": req_id,
                "error": {"code": -32601, "message": f"Method not found: {method}"},
            }

        sys.stdout.write(json.dumps(response) + "\n")
        sys.stdout.flush()

    logging.info("MCP Memory Server stopped")


if __name__ == "__main__":
    main()
