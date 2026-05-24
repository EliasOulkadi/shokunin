# Shokunin Fix Plan — All Bugs Fixed

## Summary of fixes applied (12 total, 0 regressions)

### [x] Fix 1: Version consistency
- `install.ps1`, `install.sh`, `install-skills.ps1`, `install-skills.sh`, `AGENTS.md.tpl` → v4.2.3

### [x] Fix 2: install.ps1 — profile.ps1 + normalize-eol.ps1 not installed
- Added both to `$newScripts` array
- Added `$script:cloneDir` tracking so Install-Templates can find the clone
- Added `Install-Templates` function (Section 11) that copies `.pack/templates/` → `~/.shokunin/templates/`
- Added non-interactive mode via `SHOKUNIN_YES` env var

### [x] Fix 3: install.sh — double curl + missing templates install
- Removed pre-loop curl (was duplicated before the retry loop)
- Added templates dir installation step before cleanup

### [x] Fix 4: .pack/CLAUDE.md — garbled duplicate sections
- Removed the duplicate short sections 2 and 3 that had section 1 content pasted into section 3
- Moved Windows/Linux search-memory.ps1 commands into section 1 where they belong
- Fixed `{{SHOKUNIN_DIR}}` placeholder → `~/.shokunin`

### [x] Fix 5: .pack/templates/CLAUDE.md.tpl — Spanish memory section
- Translated entire memory section from Spanish to English
- Aligned structure with fixed `.pack/CLAUDE.md`

### [x] Fix 6: .pack/AGENTS.md — playwright listed as MCP server
- Removed `playwright` from MCP Servers section (it's a skill, not an MCP server)

### [x] Fix 7: .pack/templates/AGENTS.md.tpl — same playwright bug
- Removed `playwright` from MCP Servers section in template

### [x] Fix 8: .pack/templates/mcp-server.py.tpl — outdated vs actual mcp-server.py
- Added `import logging.handlers`
- Replaced `basicConfig(filename=...)` with `RotatingFileHandler` (5MB, 3 backups)

### [x] Fix 9: shokunin-update.ps1 — static files created empty when missing
- Changed `New-Item` empty file creation to a warning + skip (no data loss)

### [x] Fix 10: memory-healthcheck.ps1 — fresh install failure
- Changed `current-session.json` check from `Check` to `Warn` (file doesn't exist on fresh install)

### [x] Fix 11: tests/test_chroma.py — module-level expanduser bypasses monkeypatch
- Replaced module-level `CHROMA` constant with `_chroma_path()` function reading env at call time
- Added missing `import json`

### [x] Fix 12: tests/test_mcp.py — same module-level path issue
- Replaced module-level `MCP_SERVER` constant with `_mcp_server_path()` function

---

## Original plan template below (not applicable to this task)

## Configuration
- **Artifacts Path**: {@artifacts_path} → `.zenflow/tasks/{task_id}`

## Agent Instructions

Ask the user questions when anything is unclear or needs their input. This includes:
- Ambiguous or incomplete requirements
- Technical decisions that affect architecture or user experience
- Trade-offs that require business context

Do not make assumptions on important decisions — get clarification first.

**Debug requests, questions, and investigations:** answer or investigate first. Do not create a plan upfront — the user needs an answer, not a plan. A plan may become relevant later once the investigation reveals what needs to change.

**For all other tasks**, before writing any code, assess the scope of the actual change (not the prompt length — a one-sentence prompt can describe a large feature). Scale your approach:

- **Trivial** (typo, config tweak, single obvious change): implement directly, no plan needed.
- **Small** (a few files, clear what to do): write 2–3 sentences in `plan.md` describing what and why, then implement. No substeps.
- **Medium** (multiple components, design decisions, edge cases): write a plan in `plan.md` with requirements, affected files, key decisions, verification. Break into 3–5 steps.
- **Large** (new feature, cross-cutting, unclear scope): gather requirements and write a technical spec first (`requirements.md`, `spec.md` in `{@artifacts_path}/`). Then write `plan.md` with concrete steps referencing the spec.

**Skip planning and implement directly when** the task is trivial, or the user explicitly asks to "just do it" / gives a clear direct instruction.

To reflect the actual purpose of the first step, you can rename it to something more relevant (e.g., Planning, Investigation). Do NOT remove meta information like comments for any step.

Rule of thumb for step size: each step = a coherent unit of work (component, endpoint, test suite). Not too granular (single function), not too broad (entire feature). Unit tests are part of each step, not separate.

Update `{@artifacts_path}/plan.md` if it makes sense to have a plan and task has more than 1 big step.
