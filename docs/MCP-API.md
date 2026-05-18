# Shokunin Memory MCP Server API

Protocol version: `2024-11-05` (JSON-RPC 2.0 over stdin/stdout)

## Overview

The Shokunin Memory MCP Server provides 9 tools for persistent AI memory. It runs locally as a stdin/stdout JSON-RPC process — no HTTP server, no cloud dependency, no API keys.

**Storage**: ChromaDB (SQLite-backed, file-based) at `~/.shokunin/memory/chroma_db/`
**Session logs**: `~/.shokunin/memory/sessions/<id>.jsonl`
**Markdown fallback**: `~/.shokunin/memory/sessions/<id>.md`

## Lifecycle

```
Client                    Server
  |                         |
  |--- initialize ---------->|
  |<-- capabilities ---------|
  |                         |
  |--- tools/list ---------->|   (discover available tools)
  |<-- tool definitions -----|
  |                         |
  |--- tools/call ---------->|   (invoke any tool)
  |<-- result ---------------|
  |                         |
  |--- notifications/initialized --->|  (optional, no response)
```

## Initialize Response

```json
{
  "protocolVersion": "2024-11-05",
  "capabilities": { "tools": {} },
  "serverInfo": { "name": "shokunin-memory", "version": "1.0.0" }
}
```

## Error Handling

| Code | Meaning |
|------|---------|
| `-32601` | Method not found |
| `-32000` | Internal server error |

---

## Tools Reference

### store_context

Store a text entry with type, tags, project, and session_id into persistent memory.

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `text` | string | Yes | The text content to store |
| `session_id` | string | Yes | Session identifier |
| `type` | string | No | Entry type (default: `"general"`) |
| `tags` | string[] | No | Tags for categorization |
| `project` | string | No | Project name |

**Valid types:** `decision`, `file`, `command`, `preference`, `checkpoint`, `session_end`, `general`, `claim_file`, `claim_function`, `claim_flag`, `claim_api`

**Returns:**
```json
{ "id": "uuid-v4", "type": "decision", "stored": true }
```

**Side effects:**
- Writes to ChromaDB collection
- Appends to `<session_id>.jsonl`
- Appends to `<session_id>.md` (markdown fallback)

**Example:**
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "tools/call",
  "params": {
    "name": "store_context",
    "arguments": {
      "text": "Decision: Use PostgreSQL instead of MongoDB for the catalog service",
      "session_id": "session-20260518-143000-abcd",
      "type": "decision",
      "tags": ["decision", "backend", "catalog"],
      "project": "ecommerce-api"
    }
  }
}
```

---

### search_context

Vector similarity search across stored memory entries.

**Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `query` | string | Yes | — | Search query text |
| `project` | string | No | — | Filter by project name |
| `type` | string | No | — | Filter by entry type |
| `tags` | string[] | No | — | Filter by tags (any match) |
| `n_results` | int | No | 10 | Number of results (max 50) |
| `freshness_boost` | float | No | 0.0 | Blend between vector similarity (0.0) and recency (1.0) |

**Freshness boost formula:**
```
final_score = (1 - freshness_boost) × similarity + freshness_boost × e^(-days_since / 30)
```
A 30-day half-life means entries from 30 days ago get 37% weight, 60 days get 14%.

**Returns:**
```json
[
  {
    "text": "First 500 chars of stored content...",
    "type": "decision",
    "tags": ["backend", "catalog"],
    "project": "ecommerce-api",
    "session_id": "session-20260518-143000-abcd",
    "timestamp": "2026-05-18T14:30:00+00:00",
    "similarity": 0.8923
  }
]
```

**Similarity calculation:** `1 / (1 + chroma_distance)`, giving a 0-1 range where higher is more relevant.

---

### multi_search_context

Combined vector + BM25 + temporal filter search with Reciprocal Rank Fusion (RRF). This is the primary recall tool for finding the most relevant context.

**Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `query` | string | Yes | — | Search query text |
| `project` | string | No | — | Filter by project name |
| `n_results` | int | No | 10 | Number of results (max 50) |
| `freshness_boost` | float | No | 0.0 | Blend between vector similarity (0.0) and recency (1.0) |
| `from_date` | string | No | — | Filter from ISO date (YYYY-MM-DD) |
| `to_date` | string | No | — | Filter to ISO date (YYYY-MM-DD) |

**Returns:**
```json
{
  "entries": [
    {
      "text": "...",
      "type": "checkpoint",
      "tags": ["backend", "session-end"],
      "project": "ecommerce-api",
      "session_id": "session-20260518-143000-abcd",
      "timestamp": "2026-05-18T14:30:00+00:00",
      "score": 0.0345
    }
  ],
  "count": 3
}
```

**Fusion algorithm (RRF with k=60):**
```
score(doc) = Σ 1/(k + rank_i)
```
Applied across vector results and BM25 results, then merged and sorted by fused score. Temporal date filters are applied before fusion.

**When to use:** Always prefer `multi_search_context` over `search_context`. The BM25 component catches exact keyword matches that vector search misses (function names, file paths, version numbers). The temporal filter lets you narrow to recent sessions.

---

### consolidate_memories

Consolidate old memory entries into summarized entries per project. Reduces db size and groups related context.

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `project` | string | No | Project to consolidate. Consolidates all projects if empty. |

**Returns:**
```json
{ "consolidated": 15, "projects_affected": ["ecommerce-api", "frontend"] }
```

---

### list_sessions

List recent sessions with metadata (project, entry count, summary).

**Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `limit` | int | No | 5 | Max sessions to return (max 20) |
| `project` | string | No | — | Filter by project name |

**Returns:**
```json
{
  "sessions": [
    {
      "session_id": "session-20260518-143000-abcd",
      "project": "ecommerce-api",
      "entry_count": 23,
      "latest_type": "session_end",
      "latest_timestamp": "2026-05-18T16:00:00+00:00",
      "summary": "Implemented catalog API..."
    }
  ]
}
```

---

### continue_session

Load full context from a specific session. Parses text from session_end entries to extract decisions, files modified, and commands.

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `session_id` | string | Yes | Session identifier to continue |

**Returns:**
```json
{
  "session_id": "session-20260518-143000-abcd",
  "decisions": ["Use PostgreSQL for catalog service"],
  "files": ["src/catalog/model.ts", "src/catalog/routes.ts"],
  "commands": ["npm run migrate", "npm test"],
  "entries": [...]
}
```

---

### save_message

Record a message exchange (user or assistant) in the session JSONL transcript.

**Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `text` | string | Yes | — | Message content |
| `session_id` | string | Yes | — | Session identifier |
| `role` | string | No | `"user"` | `"user"` or `"assistant"` |

**Returns:**
```json
{ "stored": true, "session_id": "session-20260518-143000-abcd" }
```

---

### verify_file_path

Verify whether a file or directory path exists on the local filesystem. Use this to validate claims about file locations from old memory entries before acting on them.

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `path` | string | Yes | File or directory path. Supports `~` for home directory and relative paths. |

**Returns:**
```json
{
  "exists": true,
  "path": "C:\\Users\\dev\\project\\src\\index.ts",
  "last_modified": "2026-05-18T14:30:00+00:00",
  "kind": "file"
}
```

```json
{
  "exists": false,
  "path": "C:\\Users\\dev\\project\\src\\old-module.ts"
}
```

**When to use:** Memory entries are claims from a frozen point in time. Always verify file paths before acting on them. Entry types `claim_file` and `claim_function` with `verified_at` set are pre-verified.

---

## Architecture

```
AI Runtime (OpenCode, Claude Code, Cursor, Cline, Continue, Windsurf)
    │
    │  JSON-RPC 2.0 over stdin/stdout
    │
    ▼
MCP Server (mcp-server.py)
    │
    ├──► ChromaDB (vector + metadata)
    │      Storage: ~/.shokunin/memory/chroma_db/
    │      Collection: shokunin_memory
    │      Embedding: all-MiniLM-L6-v2 (384-dim)
    │
    ├──► Session JSONL (append-only log)
    │      Location: ~/.shokunin/memory/sessions/<id>.jsonl
    │      Fields: t (type), ts (timestamp), session_id, content, role?
    │
    └──► Session Markdown (human-readable fallback)
           Location: ~/.shokunin/memory/sessions/<id>.md
```

## Configuration

### OpenCode (native)

Add to `~/.config/opencode/opencode.json`:

```json
{
  "mcpServers": {
    "memory": {
      "command": "python",
      "args": ["~/.shokunin/memory/mcp-server.py"]
    }
  }
}
```

### Claude Code / Cline / Cursor / Continue / Windsurf

Template configs are in `.pack/templates/`. Copy the appropriate template for your runtime.

## Data Retention

- ChromaDB entries persist until explicitly removed or consolidated
- Session JSONL files persist between sessions (never auto-deleted)
- Consolidation groups old entries into summaries, reducing noise
- No cloud sync, no telemetry, no external API calls

## Error Handling

All tool errors return:
```json
{
  "jsonrpc": "2.0",
  "id": <request_id>,
  "error": {
    "code": -32000,
    "message": "Internal server error"
  }
}
```

Unknown methods return code `-32601`. Unknown tool names return the same code with `"Tool not found: <name>"`.

## Testing

```powershell
# Full test suite
.\test-memory.ps1

# Health check
.\memory-healthcheck.ps1

# Manual test
echo '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}' | python ~/.shokunin/memory/mcp-server.py
```

## CLI Companion

The `chroma-helper.py` CLI provides the same functionality outside the MCP protocol:

```bash
# Search memory
python ~/.shokunin/scripts/chroma-helper.py recall "my project" --project myapp

# List sessions
python ~/.shokunin/scripts/chroma-helper.py session list 5

# Continue a session
python ~/.shokunin/scripts/chroma-helper.py session continue <session_id>

# Save a checkpoint
python ~/.shokunin/scripts/chroma-helper.py save "Decision: use X" <session_id> checkpoint "checkpoint,backend" "myapp"
```