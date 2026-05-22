---
name: memory
description: Persistent memory across AI sessions using ChromaDB vector database. Stores and retrieves context from past conversations, decisions, and code. Use when user asks to remember something, search past conversations, recall what was done before, save context for later, or find information from previous sessions. Do NOT use for git history or file-based notes.
triggers:
  - "remember"
  - "search past"
  - "recall"
  - "what was done"
  - "previous session"
  - "save context"
  - "remember that"
  - "memory"
  - "ChromaDB"
  - "vector memory"
  - "persistent memory"
negatives:
  - "git history"
  - "file system"
  - "file notes"
  - "backup"
  - "database"
  - "memory admin (use chromadb)"
  - "backup memory (use chromadb)"
license: MIT
compatibility: opencode
metadata:
  workflow: productivity
  audience: developers
  version: "1.0.0"
  author: shokunin
allowed-tools: Read Bash Write
---


# Memory

Persistent memory across sessions using ChromaDB vector search. Every conversation is stored and retrievable.

## How It Works

The memory system uses ChromaDB (local vector database, no server needed) to store conversation context as embeddings. When you start a new session, the agent searches past memory for relevant context.

- **Storage**: `~/.shokunin/memory/chroma_db/` (ChromaDB persistent files)
- **Sessions**: `~/.shokunin/memory/sessions/` (markdown summaries per session)
- **MCP Server**: `~/.shokunin/memory/mcp-server.py`

## Workflow

### Step 1: Start memory server (if not running)

The memory MCP server is configured in opencode.json. It starts automatically when OpenCode connects to it.

### Step 2: Save context during session

At the end of each significant task, save context:

```
store_context with:
  text: "Summary of what was done, key decisions, code patterns"
  tags: ["project-name", "feature", "language"]
  project: "project-name"
  session_id: "current-session-id"
```

### Step 3: Search past memory at session start

When starting a new session, search for relevant context:

```
search_context with:
  query: "what we discussed about auth"
  project: "current-project"
```

### Step 4: Get full session summary

```
get_session_summary with:
  session_id: "session-id"
```

## Automatic Session Save

The agent should automatically:
1. At the end of the session, save a summary of key decisions and context
2. At the start of a new session, search for relevant past context
3. Present relevant past context to the user naturally

## Error Handling

| Error | Cause | Fix |
|-------|-------|-----|
| ChromaDB not found | Not installed | `pip install chromadb` |
| Collection not found | First run | Creates automatically on first store |
| Slow first query | Downloading ONNX model | First run downloads ~79MB. Subsequent runs are instant. |
| Memory not returning results | No data stored yet | Normal on first use. Start by saving something. |
| Embedding model fails to download | Network blocked or proxy required | Set `CHROMADB_EMBEDDING_MODEL` env var. Fall back to `all-MiniLM-L6-v2` which is smaller (~23MB). |
| Duplicate or stale entries flooding results | Auto-save firing too frequently during rapid iteration | Apply 5-second debounce before storing context. Consolidate entries with `memory_consolidate_memories` periodically. |
| Collection corrupted after crash | Write interrupted during power loss or force-quit | Restore from latest backup in `~/.shokunin/memory/backups/`. Run `memory-healthcheck.ps1` to verify integrity. |
| Search returns irrelevant results for short queries | Under-2-word queries have poor vector signal | Use 3+ word queries. Include project name, topic, and a descriptive verb phrase. |
| Session ID collision or reuse | Wrapper failed to generate unique ID, or manual copy-paste | Check `~/.shokunin/current-session.json`. Run `python chroma-helper.py session list` to verify uniqueness.

## Commands

```
/remember [text]     → Save an important piece of context
/search [query]      → Search past memory
/whatdidwe [topic]   → What did we discuss about X before?
/forget [id]         → Remove a specific memory entry
```

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| Storing secrets or tokens in memory entries | Plaintext memory is readable by any process with filesystem access | Never store API keys, passwords, or tokens. Use environment variables or a dedicated secret manager. |
| Saving every single message instead of checkpoints | Floods the vector DB with near-duplicate embeddings, degrading search quality | Save only decisions, file changes, and commands. Debounce rapid successive saves to 5 seconds. |
| Using memory as a key-value store | ChromaDB is optimized for semantic similarity, not exact-match lookups | Use the file system or a config file for deterministic data. Reserve memory for fuzzy, contextual recall. |
| Searching with overly broad queries like "what did we do" | Returns too many low-relevance results, wasting tokens and attention | Narrow the query: project name + topic + timeframe. Example: "auth refactoring decisions May 2026". |
| Not consolidating old sessions | Vector DB grows unbounded, slowing queries and increasing disk usage | Run `memory_consolidate_memories` weekly. Archive sessions older than 90 days. |
| Assuming memory entries are immutable truth | Entries represent frozen-in-time claims. Code may have changed since then. | Always verify file paths and function names before acting. Use `verify_file_path` or grep to confirm. |
| Skipping session search at conversation start | Loses all context from prior work, forcing the agent to re-discover already-solved problems | Mandatory step: always run `session list` and search before responding to any task. |

## Advanced ChromaDB Patterns

### Collection Management
```python
# List collections
collections = client.list_collections()
for c in collections: print(c.name, c.count())

# Create collection with custom embedding function
from chromadb.utils import embedding_functions
ef = embedding_functions.OpenAIEmbeddingFunction(api_key="...", model_name="text-embedding-3-small")
collection = client.create_collection(name="custom", embedding_function=ef)

# Delete by metadata filter
collection.delete(where={"project": "test-project"})

# Peek at stored data
sample = collection.peek(limit=5)
```

### Embedding Model Selection

| Model | Dimensions | Speed | Accuracy |
|-------|-----------|-------|----------|
| all-MiniLM-L6-v2 (default/ONNX) | 384 | Fastest | Good for short text |
| text-embedding-3-small (OpenAI) | 1536 | API-dependent | Excellent |
| text-embedding-3-large (OpenAI) | 3072 | API-dependent | Best (expensive) |

Default ONNX model (`all-MiniLM-L6-v2`) runs locally, no API key needed. Downloads once (~79MB).

### Performance Tuning

```python
# Batch inserts (100x faster than single inserts)
batch_size = 100
for i in range(0, len(documents), batch_size):
    collection.add(
        documents=documents[i:i+batch_size],
        metadatas=metadatas[i:i+batch_size],
        ids=ids[i:i+batch_size]
    )

# Limit query results
results = collection.query(query_texts=["query"], n_results=10)

# Get with limit (prevents OOM)
all_data = collection.get(limit=500, include=["documents", "metadatas"])
```

### Storage Monitoring
```python
import os

db_path = "~/.shokunin/memory/chroma_db"
size = sum(os.path.getsize(os.path.join(root, f)) for root, _, files in os.walk(db_path) for f in files)
print(f"Database size: {size / 1024 / 1024:.1f} MB")
print(f"Collection count: {collection.count()}")
```

## Related Scripts

- `~/.shokunin/scripts/seed-memory.ps1` — Imports session markdown files into ChromaDB for first-time population
- `~/.shokunin/scripts/memory-healthcheck.ps1` — Verifies ChromaDB collection integrity and reports health status
- `~/.shokunin/scripts/read-transcript.py` — Parses MCP session transcripts and extracts structured decisions and sections

## Checklist

- [ ] Session ID is unique before storing (check with `session list`)
- [ ] Entry text is descriptive: what, why, and result (not just what)
- [ ] Type matches VALID_TYPES in MCP server config
- [ ] Tags align with previous entries for consistent search
- [ ] Session_end saved at end of every session

## Sources

- ChromaDB documentation (docs.trychroma.com) — vector database setup, embedding models, and query best practices
- OpenAI text-embedding-ada-002 documentation (platform.openai.com/docs/guides/embeddings) — production embedding model benchmarks
- MCP Protocol specification (modelcontextprotocol.io) — agent-to-tool communication protocol
- Sentence Transformers all-MiniLM-L6-v2 (sbert.net/docs/pretrained_models.html) — lightweight local embedding alternative
- ONNX Runtime documentation (onnxruntime.ai) — cross-platform model inference for local embeddings
- "Designing Data-Intensive Applications" by Martin Kleppmann (O'Reilly, 2017) — durability, replication, and consistency patterns relevant to local DB design
