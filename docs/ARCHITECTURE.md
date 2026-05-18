# Shokunin Architecture

## Overview
Shokunin is an AI coding ecosystem for Windows and Linux. It provides persistent memory (ChromaDB), 62 skills (all with Workflow, Error Handling, Sources, and Anti-Patterns sections), MCP servers, freshness decay, claim verification, and automation scripts.

## Directory Structure
- `.shokunin/` — Installed ecosystem (runtime)
  - `memory/mcp-server.py` — MCP JSON-RPC server (stdin/stdout)
  - `memory/chroma_db/` — ChromaDB persistent vector store
  - `memory/sessions/` — Session logs (jsonl + md)
  - `scripts/chroma-helper.py` — CLI for memory operations
  - `templates/*.tpl` — Templates for update system
- `.pack/` — Distribution source (GitHub repo)
  - `skills/*/SKILL.md` — 62 AI skills
  - `scripts/` — Installable scripts
  - `memory/` — Production Python files
- `.config/opencode/skills/` — OpenCode skill installation target
- `.agents/skills/` — Alternative skill location

## Data Flow
1. User runs opencode → session wrapper captures context
2. MCP server persists to ChromaDB (vector) + sessions/ (jsonl + md)
3. chroma-helper.py CLI coordinates save/search/recall
4. Skills provide domain-specific instructions to AI agents

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

## Data Flow (expanded)

**Session Lifecycle:** opencode wrapper sets `SHOKUNIN_SESSION_ID`, `SHOKUNIN_PROJECT`, and `SHOKUNIN_MCP_HEALTHY`. The MCP server writes each interaction to `sessions/<id>.jsonl`. On session end, `chroma-helper.py save` persists a final summary to ChromaDB.

**Search Pipeline:** `multi_search_context` combines vector similarity (ChromaDB), BM25 keyword matching, temporal date filtering, and Reciprocal Rank Fusion (RRF) to merge results from multiple strategies.

**Freshness Decay:** search results blend vector relevance with exponential recency weighting (30-day half-life) via the `freshness_boost` parameter.

**Claim Verification:** `verify_file_path` MCP tool validates file paths from old memory entries before agents act on them.

**Session Management:** session continuation loads full context with decisions, files, commands, and checkpoint summaries.
