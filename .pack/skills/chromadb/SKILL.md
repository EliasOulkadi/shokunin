---
name: chromadb
description: Manage the ChromaDB vector database that stores the ecosystem's persistent memory. Use when user asks to check memory storage, backup memory, search stored entries, delete entries, or reset the vector database. Do NOT use for general question answering about past sessions (use the memory skill for that).
triggers:
  - "manage memory"
  - "memory status"
  - "memory backup"
  - "memory delete"
  - "memory reset"
  - "ChromaDB status"
  - "check storage"
  - "delete entry"
  - "backup database"
  - "reset database"
negatives:
  - "search memory"
  - "query context"
  - "save context"
  - "verify file"
  - "context recall"
  - "remember past"
license: MIT
compatibility: opencode
metadata:
  workflow: administration
  audience: developers
  version: "4.2.2"
---

# chromadb · Memory Storage

**ChromaDB** is the vector database that powers Shokunin's persistent AI memory. It stores embeddings for semantic search across sessions. Built on SQLite with an ONNX embedding model for local-first, offline-capable operation.

## Workflow

### Step 1: Check storage status

```powershell
python ~/.shokunin/scripts/chroma-helper.py count
```

Output: total entries, collection count, disk size on disk, last write timestamp.

```powershell
python ~/.shokunin/scripts/chroma-helper.py stats
```

Output: entries per type (decision, file, command, checkpoint, session_end), per project, per date range.

### Step 2: Search stored entries

```powershell
python ~/.shokunin/scripts/chroma-helper.py search "query text" "project-name" 10
```

Searches via vector similarity + BM25 keyword hybrid. Results sorted by relevance with metadata attached.

```powershell
python ~/.shokunin/scripts/chroma-helper.py search "error handling" "" 20 --type decision
```

Filter by entry type. Leave project empty to search all projects.

### Step 3: List recent entries

```powershell
python ~/.shokunin/scripts/chroma-helper.py recent 10
```

Shows the 10 most recently inserted entries across all projects. Use for quick audit.

```powershell
python ~/.shokunin/scripts/chroma-helper.py recent 50 --project myproject
```

Filter recent entries to a specific project.

### Step 4: Backup the database

```powershell
$backupDir = "$env:USERPROFILE\.shokunin\backups\chroma-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
Compress-Archive -Path "$env:USERPROFILE\.shokunin\memory\chroma_db" -DestinationPath "$backupDir\chroma_db.zip" -Force
```

Also back up session logs:

```powershell
Compress-Archive -Path "$env:USERPROFILE\.shokunin\memory\sessions" -DestinationPath "$backupDir\sessions.zip" -Force
```

Verify backup integrity:

```powershell
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::OpenRead("$backupDir\chroma_db.zip").Entries.Count
```

### Step 5: Delete entries by session prefix

```powershell
python ~/.shokunin/scripts/chroma-helper.py delete "session-prefix"
```

Deletes all entries whose session_id starts with the given prefix. Non-reversible. Backup first.

```powershell
python ~/.shokunin/scripts/chroma-helper.py delete --project "old-project"
```

Delete all entries for a project. Useful when archiving finished projects.

### Step 6: Full reset (requires confirmation)

```powershell
Remove-Item -Recurse -Force "$env:USERPROFILE\.shokunin\memory\chroma_db"
# Restart MCP server to recreate the database
```

The database is auto-created on next MCP server startup. All sessions, embeddings, and metadata are permanently lost. Only do this when migrating or recovering from corruption.

## Storage Details

| Location | Purpose |
|----------|---------|
| `~/.shokunin/memory/chroma_db/` | ChromaDB persistent files (SQLite + embeddings) |
| `~/.shokunin/memory/sessions/` | Per-session JSONL logs and Markdown summaries |
| `~/.shokunin/memory/mcp-server.log` | MCP server log file (auto-rotated at 5MB) |
| `~/.shokunin/backups/` | Timestamped backup archives |
| `~/.shokunin/scripts/chroma-helper.py` | CLI management script |

## Data Model

| Concept | Description |
|---------|-------------|
| Collection | ChromaDB namespace for embeddings (one per project by default) |
| Embedding | Vector representation of text for semantic similarity search |
| Metadata | Key-value pairs attached to each entry (type, tags, project, session_id, timestamp) |
| Document | The raw text content stored alongside the embedding |
| BM25 Index | Sparse retrieval index that complements vector search (keyword matching) |
| Result Fusion | Merges vector + BM25 results for higher recall (reciprocal rank fusion) |
| Entry Types | decision, file, command, preference, checkpoint, session_end, general |

## Session Management

| Command | Description |
|---------|-------------|
| `python ~/.shokunin/scripts/chroma-helper.py session list [N]` | List recent sessions with metadata |
| `python ~/.shokunin/scripts/chroma-helper.py session continue <id>` | Load full session context |
| `python ~/.shokunin/scripts/chroma-helper.py session summary <id>` | Show session summary |
| `python ~/.shokunin/scripts/chroma-helper.py save "<text>" "<id>" "<type>" "<tags>" "<project>"` | Save entry |

## Error Handling

| Error | Cause | Fix |
|-------|-------|-----|
| ChromaDB not found | Package not installed | `pip install chromadb` |
| Collection empty | No data stored yet | Normal on first use. Start storing context. |
| Slow first query | Downloading ONNX model | First query downloads ~79MB. Subsequent queries are instant. |
| Permission denied | File locked by another process | Close other MCP server instances |
| Corrupted database | Unexpected shutdown or disk full | Restore from backup or delete and let the system reinitialize |
| Memory usage high | Large collection over time | Run `consolidate_memories` to merge old entries |
| Embedding dimension mismatch | Model was upgraded or changed | Delete chroma_db/ and reindex from session logs |
| UUID collision | Race condition in parallel writes | ChromaDB handles this internally; retry the insert |
| SQLite disk I/O error | Filesystem full or read-only | Free disk space (need ~2x DB size); check permissions |

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| Deleting `chroma_db/` without backup | Permanent data loss | Always backup first (Step 4) |
| Running multiple MCP servers | Database locked, data corruption | Only one MCP server instance at a time |
| Manual SQL manipulation | Breaks ChromaDB invariants | Use chroma-helper.py CLI or MCP tools only |
| Ignoring session_list filters | Seeing test/healthcheck entries | session_list automatically filters noise |
| Storing extremely large text | Bloating vector index | ChromaDB truncates at 500 chars |
| Never consolidating | Database grows indefinitely | Run `consolidate_memories` periodically |
| Skipping backups | No recovery from disk failure | Weekly backup is configured via Task Scheduler |
| Using raw SQLite instead of ChromaDB API | Schema and index corruption | Always go through ChromaDB's Python client |
| Searching without project filter for broad queries | Too many irrelevant results | Always filter by project when context is known |

## Automation

Weekly backup every Sunday via Windows Task Scheduler (pre-configured). Manual backup via Step 4 above. Logs auto-rotate at 5MB to prevent unbounded growth. The `consolidate_memories` function runs automatically when entry count exceeds 10,000 per project.

## Recovery Procedures

### Restore from backup

```powershell
$backup = Get-ChildItem "$env:USERPROFILE\.shokunin\backups" -Directory | Sort-Object LastWriteTime -Descending | Select-Object -First 1
Expand-Archive -Path "$backup\chroma_db.zip" -DestinationPath "$env:USERPROFILE\.shokunin\memory\chroma_db" -Force
```

### Rebuild from session logs

If backups are unavailable, session JSONL logs contain all raw text. Replay them:

```powershell
python ~/.shokunin/scripts/chroma-helper.py rebuild --from-sessions
```

### Verify database health

```powershell
python ~/.shokunin/scripts/chroma-helper.py verify
```

Checks: SQLite integrity, embedding count vs document count, orphan metadata, collection schema version.

## Checklist

- [ ] ChromaDB client initialized lazily (not at import time)
- [ ] Collection name sanitized (alphanumeric + hyphens only)
- [ ] Embedding dimension matches between writes and queries
- [ ] Backups configured before destructive operations (delete/reset)
- [ ] Search results validated — empty results handled gracefully

## Sources

- ChromaDB documentation (docs.trychroma.com)
- OpenAI text-embedding-ada-002 (or local ONNX embedder)
- SQLite documentation (sqlite.org)
- DuckDB (ChromaDB's internal query engine)
- MCP Protocol (modelcontextprotocol.io)
- Shokunin Memory System Architecture (ARCHITECTURE.md)
