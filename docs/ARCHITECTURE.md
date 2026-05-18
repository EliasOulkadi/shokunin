# Shokunin Architecture

## Overview
Shokunin is an AI coding ecosystem for Windows and Linux. It provides persistent memory (ChromaDB), 62 skills (all with Workflow, Error Handling, Sources, and Anti-Patterns sections), MCP servers, freshness decay, claim verification, and automation scripts.

## Directory Structure
- `.shokunin/` — Installed ecosystem (runtime)
  - `memory/mcp-server.py` — MCP JSON-RPC server (stdin/stdout, 572 lines)
  - `memory/chroma_db/` — ChromaDB persistent vector store (SQLite-backed)
  - `memory/sessions/` — Session logs (JSONL + markdown)
  - `scripts/chroma-helper.py` — CLI for memory operations (22 KB)
  - `scripts/chroma_helper_stub.py` — Lightweight helper for MCP server imports
  - `templates/*.tpl` — Templates for update system
  - `shokunin.json` — Declarative manifest for drift detection
- `.pack/` — Distribution source (GitHub repo)
  - `skills/*/SKILL.md` — 62 AI skills with YAML frontmatter
  - `scripts/` — Installable scripts (Windows + Linux)
  - `memory/` — Production Python files (mcp-server.py)
  - `templates/` — MCP config templates per runtime
  - `rules/` — Runtime-specific instruction files
- `.config/opencode/skills/` — OpenCode skill installation target
- `.agents/skills/` — Alternative skill location

## Data Flow
1. User runs opencode → session wrapper captures context
2. MCP server persists to ChromaDB (vector) + sessions/ (JSONL + markdown)
3. chroma-helper.py CLI coordinates save/search/recall
4. Skills provide domain-specific instructions to AI agents

## MCP Tools (9 total)

| Tool | Purpose | Key Parameters |
|------|---------|---------------|
| `store_context` | Store text with type, tags, project, session | text, session_id, type, tags, project |
| `search_context` | Vector similarity search | query, project, type, tags, n_results, freshness_boost |
| `multi_search_context` | Vector + BM25 + temporal + RRF fusion | query, project, n_results, from_date, to_date, freshness_boost |
| `consolidate_memories` | Summarize old entries per project | project |
| `list_sessions` | Recent sessions with metadata | limit, project |
| `continue_session` | Load full session context | session_id |
| `save_message` | Record message in session transcript | text, session_id, role |
| `get_session_summary` | Summarize all entries in a session | session_id |
| `verify_file_path` | Validate file/dir path exists | path |

## Entry Types

| Type | Purpose | Example |
|------|---------|---------|
| `decision` | Architectural or design choices | "Use PostgreSQL for catalog service" |
| `file` | Files created, modified, deleted | "Modified src/auth/middleware.ts" |
| `command` | CLI commands and results | "npm run migrate → 3 migrations" |
| `preference` | User preferences discovered | "User prefers tabs over spaces" |
| `checkpoint` | Progress markers | "Completed auth, starting payments" |
| `session_end` | Full session summary | "Decisions: X. Files: A. Next: C" |
| `general` | Default entry type | "Research note on webhooks" |
| `claim_file` | Verified file path | "src/auth/login.ts (verified 2026-05-18)" |
| `claim_function` | Verified function signature | "handleLogin(req, res)" |
| `claim_flag` | Verified config flag | "FEATURE_FLAGS.auth=true" |
| `claim_api` | Verified API endpoint | "GET /api/v2/users" |

## Freshness Decay

v4.2.2 introduces exponential recency blending with a 30-day half-life:

```
final_score = (1 - freshness_boost) × vector_similarity + freshness_boost × e^(-days_since / 30)
```

- `freshness_boost = 0.0` → pure vector similarity (default)
- `freshness_boost = 1.0` → pure recency
- Old entries fade over 30 days so stale claims don't drown recent context

## Claim Verification

Memory entries are claims from a frozen point in time. The `verify_file_path` MCP tool validates file paths before the agent acts on them:

1. Agent retrieves a memory entry mentioning a file path
2. Agent calls `verify_file_path` to check if the path still exists
3. If path exists → mark with `verified_at` timestamp
4. If path gone → search newer memory or the codebase directly

Entry types `claim_file` and `claim_function` with `verified_at` set are pre-verified.

## Search Pipeline

`multi_search_context` combines three strategies:

1. **Vector search** — ChromaDB with all-MiniLM-L6-v2 (384-dim) embeddings
2. **BM25 keyword matching** — Exact phrase and term matching (k1=1.5, b=0.75)
3. **Temporal date filtering** — ISO date range filters (from_date, to_date)

Results merged via **Reciprocal Rank Fusion** (RRF, k=60):

```
score(doc) = Σ 1/(k + rank_i) across all strategies
```

## Session Lifecycle

- `SHOKUNIN_SESSION_ID` env var set by wrapper on startup
- Every MCP tool call auto-logged to `sessions/<id>.jsonl`
- `session list N` — show N recent sessions with metadata
- `session continue <id>` — load full context, parse decisions/files/commands
- `save` at session end → ChromaDB + markdown fallback

## Update System

shokunin-update.ps1 uses shokunin.json manifest to:
- Check status of all components
- Apply template-based updates
- Roll back from backups

## Drift Model

- `.pack/` = distribution base (canonical)
- `templates/` = templates used by update system to regenerate
- `.shokunin/` = local install (expected to drift)
- No automated sync — `install.ps1` does one-time deploy