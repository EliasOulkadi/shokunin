import os
import json
import sys
import uuid
from datetime import datetime, timezone

import chromadb
from chromadb.config import Settings

CHROMA_PATH = r"os.path.join(os.environ["USERPROFILE"], ".shokunin", "memory", "chroma_db")"
COLLECTION_NAME = "shokunin_memory"

client = chromadb.PersistentClient(
    path=CHROMA_PATH,
    settings=Settings(anonymized_telemetry=False),
)
collection = client.get_or_create_collection(name=COLLECTION_NAME)


def handle_tools_list():
    return {
        "tools": [
            {
                "name": "store_context",
                "description": "Store a text entry with tags, project, and session_id into persistent memory",
                "inputSchema": {
                    "type": "object",
                    "required": ["text", "session_id"],
                    "properties": {
                        "text": {
                            "type": "string",
                            "description": "The text content to store",
                        },
                        "tags": {
                            "type": "array",
                            "items": {"type": "string"},
                            "description": "Tags to categorize this entry",
                        },
                        "project": {
                            "type": "string",
                            "description": "Project name this context belongs to",
                        },
                        "session_id": {
                            "type": "string",
                            "description": "Session identifier",
                        },
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
                        "query": {
                            "type": "string",
                            "description": "Search query text",
                        },
                        "project": {
                            "type": "string",
                            "description": "Filter by project",
                        },
                        "tags": {
                            "type": "array",
                            "items": {"type": "string"},
                            "description": "Filter by tags",
                        },
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
                        "session_id": {
                            "type": "string",
                            "description": "Session identifier to summarize",
                        },
                    },
                },
            },
        ],
    }


def handle_store_context(args):
    text = args["text"]
    tags = args.get("tags", [])
    project = args.get("project", "")
    session_id = args["session_id"]
    entry_id = str(uuid.uuid4())
    timestamp = datetime.now(timezone.utc).isoformat()

    metadata = {
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

    return {"id": entry_id, "stored": True}


def handle_search_context(args):
    query = args["query"]
    project = args.get("project")
    tags = args.get("tags")

    where_filter = {}
    if project:
        where_filter["project"] = project

    results = collection.query(
        query_texts=[query],
        n_results=10,
        where=where_filter if where_filter else None,
    )

    entries = []
    if not results["ids"][0]:
        return entries

    for i, doc_id in enumerate(results["ids"][0]):
        metadata = results["metadatas"][0][i]
        document = results["documents"][0][i]
        distance = results["distances"][0][i]

        entry_tags = json.loads(metadata.get("tags", "[]"))

        if tags and not any(t in entry_tags for t in tags):
            continue

        entries.append({
            "text": document,
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
            "tags": json.loads(metadata.get("tags", "[]")),
            "project": metadata.get("project", ""),
            "timestamp": metadata.get("timestamp", ""),
        })

    tags_used = set()
    projects_used = set()
    for e in entries:
        tags_used.update(e["tags"])
        if e["project"]:
            projects_used.add(e["project"])

    summary = (
        f"Session {session_id}: {len(entries)} entries, "
        f"{len(tags_used)} unique tags, "
        f"{len(projects_used)} projects."
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


if __name__ == "__main__":
    main()

