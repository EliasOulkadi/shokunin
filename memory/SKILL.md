---
name: memory
description: Persistent memory across AI sessions using ChromaDB vector database. Stores and retrieves context from past conversations, decisions, and code. Use when user asks to remember something, search past conversations, recall what was done before, save context for later, or find information from previous sessions. Do NOT use for git history or file-based notes.
license: MIT
compatibility: opencode
metadata:
  workflow: productivity
  audience: developers
  version: "1.0"
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

## Commands

```
/remember [text]     → Save an important piece of context
/search [query]      → Search past memory
/whatdidwe [topic]   → What did we discuss about X before?
/forget [id]         → Remove a specific memory entry
```

## Production Checklist

Before saving context, verify:
- [ ] **Text**: descriptive, includes what was done, why, and result
- [ ] **Tags**: project-relevant tags applied
- [ ] **Type**: correct type used (decision, file, command, checkpoint, session_end)
- [ ] **Project**: project name set for filtering
- [ ] **Session ID**: current session ID used
- [ ] **Redundancy**: saved via chroma-helper.py AND wrote markdown fallback
- [ ] **Cleanup**: test entries removed from production collection

## Anti-Patterns

| Anti-Pattern | Why It Fails | Fix |
|--------------|--------------|-----|
| Saving raw terminal output without structure | Useless for semantic search | Summarize with type, tags, project context |
| No tags on entries | Impossible to filter later | Always add at least project + content tags |
| Saving everything indiscriminately | Noise drowns signal | Only save decisions, file changes, key commands |
| Relying only on MCP server | Fails when MCP not connected | Always use chroma-helper.py as primary |
| Never cleaning old sessions | DB grows unbounded | Archive sessions older than 90 days |
| Mixed project entries | Cross-project pollution | Always set project field |

## Sources

- ChromaDB documentation (docs.trychroma.com)
- OpenAI text-embedding-ada-002 (or local ONNX embedder)
- MCP Protocol (modelcontextprotocol.io)
