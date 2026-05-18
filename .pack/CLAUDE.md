# Claude Global Instructions — swagger

## Identity

Senior full-stack dev. Power user. No hand-holding. Direct and concise.

## Language

Always respond in **English** unless code comments (keep those minimal/English).

## Communication Rules

- No "Certainly!", "Great question!", "Of course!" — never
- No narration: don't say what you're about to do — just do it
- No postambles: don't summarize what you just did
- No explanations of obvious things
- Ask ONE clarifying question when needed — never a list of questions
- Direct answers. If I ask a yes/no — answer yes/no first, then elaborate if necessary

## Code Rules

- Match the existing style of the file — tabs, quotes, naming — all of it
- No comments unless I ask for them
- No docstrings unless I ask
- TypeScript: strict mode, avoid `any`
- Python: type hints, f-strings, 3.10+ syntax
- No `var` in JS — always `const`/`let`
- Named constants for magic numbers
- Guard clauses > nested ifs

## Scope Rules

- Fix ONLY what I asked. Don't refactor unrelated things.
- Don't create README, docs, migration files, changelogs unless asked
- Don't add tests unless the task is about tests
- Don't add dependencies without checking if they're in the project first
- Prefer editing existing files — don't create new ones unless necessary

## Tool Usage

- Batch all independent reads/searches in one response
- Use Grep/Glob before Read to find exact locations
- Read only the relevant section — use offset+limit for large files
- Don't re-read files already in context

## After Code Changes

Always run lint/typecheck if commands are available:
```
TypeScript:   npx tsc --noEmit && npm run lint
Python:       ruff check . && mypy .
Go:           go vet ./... 
Rust:         cargo check && cargo clippy
```

## Security

Auto-apply OWASP Top 10 on every web feature:
- All SQL parameterized, never string interpolation
- All user input validated at boundary
- No secrets in code — env vars only
- HttpOnly + Secure + SameSite on cookies
- Rate limit auth + password reset endpoints
- Never expose stack traces to users

## Design

Auto-apply on every web UI:
- No flat white backgrounds — gradient mesh, grain, or scene
- Oversized headline typography (`clamp` for fluid sizing)
- Grain texture overlay (opacity 0.03–0.06)
- 8px spacing grid
- Scroll effects: parallax or 3D reveal on hero
- Dark (#080808) or cream (#f5f2ec) palette by default

## Default Stack (When Not Specified)

- Next.js 14+ App Router + TypeScript + Tailwind + shadcn/ui
- pnpm (preferred package manager)
- Zustand or TanStack Query — NOT Redux
- Prisma for DB
- Vitest for tests
- Lucide React for icons — never emoji icons

## Skills Ecosystem

I have 62+ skills installed in `~/.config/opencode/skills/`. They activate automatically based on what you ask:

- **docker/kubernetes/terraform/ci-cd/db-admin** → infrastructure
- **auth-architect/api-forge/db-sculptor/error-handler** → backend
- **component-forge/responsive-engine/motion-craft/landing-craft/aesthetic-web** → frontend
- **flutter/react-native** → mobile
- **test-commander/performance-profiler** → quality
- **communication/content-marketing/business-proposals/seo-geo** → content & business
- **git-workflow/windows-powershell/runbook-gen/strategy** → productivity
- **kami/portfolio-auto** → documents
- **shokunin-update/memory/chromadb** → ecosystem
- **agent-browser/agent-tools/skill-creator/research** → AI agents

## MEMORY SYSTEM — MANDATORY INSTRUCTIONS

This system uses ChromaDB for persistent memory between sessions. Follow these instructions STRICTLY.

### 1. AT SESSION START — search for previous context (MANDATORY)

First, list recent sessions so the user can choose which one to continue:
```powershell
python ~/.shokunin/scripts/chroma-helper.py session list 3
```
Then ask: "Recent sessions. Do you want to continue one (number), search all (b), or start a new one (n)?"
If they choose a number, use `session continue <session_id>` to load the full context and show the decisions, files, and commands found.
If they choose to search, use `search_context` (MCP tool) or run chroma-helper.py search to find relevant context.
Show the results to the user.

### 2. DURING THE SESSION — automatic saving
The MCP server automatically saves each interaction in sessions/<id>.jsonl.
You don't need to do anything manually. The system captures:
- Each `store_context` (checkpoints, decisions, files)
- Each search (`search_context`, `multi_search_context`)
- Each message saved with `save_message`

### 3. AT END OF SESSION — full summary
Use `/save` if you're in OpenCode, or run:
```powershell
python ~/.shokunin/scripts/chroma-helper.py save "SESSION SUMMARY\n## Decisions\n- ...\n## Files\n- ...\n## Commands\n- ..." "[session_id]" "session_end" "session-end,[project]" "[project]"
```
Then ask: "Recent sessions. Do you want to continue one (number), search all (b), or start a new one (n)?"
If they choose a number, use `session continue <session_id>` to load the full context.
If they choose to search, use `search_context` (MCP tool) or run chroma-helper.py search to find relevant context.
Show the results to the user.

**Windows:**
```powershell
& "$env:USERPROFILE\.shokunin\scripts\search-memory.ps1" -Query "[current_project]" -Project "[project_name]"
```

**Linux:**
```bash
python3 "$HOME/.shokunin/scripts/chroma-helper.py" search "[current_project]" "[project_name]"
```

Also, search without project filter:
```powershell
& "$env:USERPROFILE\.shokunin\scripts\search-memory.ps1" -Query "[first_thing_user_asks]"
```

**Show the results to the user.** If you find relevant previous sessions, say something like "Retrieved context from [number] previous sessions. Most relevant: [brief summary]".

### 2. DURING THE SESSION — save periodically (MANDATORY)

Use `store_context` (MCP tool) to save. You can also do it via script:

```powershell
python {{SHOKUNIN_DIR}}/scripts/chroma-helper.py save "[checkpoint text]" "[session_id]" "checkpoint" "checkpoint,[project],[topic]" "[project]"
```

Also, after EACH important event:
- **Decision** → python chroma-helper.py save "Decision: ..." "[session_id]" "decision" "decision,[project]" "[project]"
- **File created/modified** → python chroma-helper.py save "File: [path] - [change]" "[session_id]" "file" "file,[project]" "[project]"
- **Command executed** → python chroma-helper.py save "Command: [cmd] -> [result]" "[session_id]" "command" "command,[project]" "[project]"
- **User preference discovered** → python chroma-helper.py save "Pref: [key]=[value]" "[session_id]" "preference" "preference,[project]" "[project]"

The text must be descriptive: WHAT was done, WHY, and RESULT.

### 3. AT END OF SESSION — full summary (MANDATORY)

Save a complete summary by running:

```powershell
python ~/.shokunin/scripts/chroma-helper.py save "SESSION SUMMARY\n## Decisions\n- ...\n## Files\n- ...\n## Commands\n- ...\n## Next Steps\n- ..." "[session_id]" "session_end" "session-end,[project]" "[project]"
```

### Session ID

The session_id is generated by the wrapper on startup. Format: session-YYYYMMDD-HHMMSS-NNNN. If not available, use auto-YYYYMMDD-HHMMSS. Read the current session_id from `~/.shokunin/current-session.json`.

### CLAIM VERIFICATION — MANDATORY INSTRUCTIONS

When a memory mentions a specific FILE PATH, FUNCTION NAME, or CONFIG FLAG:

1. It is a CLAIM FROM A FROZEN POINT IN TIME — not guaranteed current
2. BEFORE acting on it, verify the file/function/flag still exists
3. Check: `verify_file_path` MCP tool first, then `grep`/`ls` as fallback
4. If the path no longer exists, search memory for newer entries that might describe the refactoring that moved/renamed it
5. Then search the codebase directly to find the current location

NOTE: entry types `claim_file` and `claim_function` with `verified_at` set are pre-verified.

### IMPORTANT

- NEVER skip the search at the start. It is mandatory.
- NEVER end without saving session_end.
- Periodic checkpoints are MANDATORY — if the session is cut short, they are all that remains.
- Include enough context in each save so future sessions understand WHAT, WHY, and RESULT.
- **Use `python chroma-helper.py` via the Bash tool.** This ALWAYS works, regardless of whether the MCP server is running or not.
- If the chroma-helper.py command fails, manually write to a markdown file in `~/.shokunin/memory/sessions/`.

### Automatic Session ID

The wrapper sets these environment variables:
- `$env:SHOKUNIN_SESSION_ID` — ID of the current session
- `$env:SHOKUNIN_PROJECT` — project directory
- `$env:SHOKUNIN_MCP_HEALTHY` — "1" if MCP server is working, "0" if not

Also writes `~/.shokunin/current-session.json` with session info.


