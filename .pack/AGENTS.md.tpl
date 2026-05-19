# AGENTS.md Shokunin AI Ecosystem

## Profile
Senior full-stack dev / indie-hacker. I build backend, frontend, mobile, content, business. Windows 11.

## Skills available (62 v4.2.3)
They activate automatically based on what you ask. You don't need to name them.

### Infrastructure
- **docker**: Containerizes any project. Multi-stage, multi-arch, compose, security.
- **kubernetes**: Manifests, Gateway API, service mesh, debugging.
- **terraform**: Infrastructure as code, Stacks, state management.
- **ci-cd**: Pipelines GitHub Actions / GitLab CI / CircleCI, rollback, OIDC.
- **db-admin**: Backup, restore, monitoring, PostgreSQL replication.

### Backend
- **api-forge**: REST/GraphQL APIs with OpenAPI 3.1, webhooks, rate limiting, sub-commands.
- **auth-architect**: OAuth2, JWT, WebAuthn, RBAC, OWASP security, sub-commands.
- **db-sculptor**: Prisma/Drizzle schemas, indexes, EXPLAIN ANALYZE, migrations.
- **error-handler**: OpenTelemetry, error budgets, circuit breaker, logging.

### Frontend (v4.2.3 enhanced with Emil Kowalski + Impeccable patterns)
- **component-forge**: React/Vue/Svelte components with all states, a11y, tactile buttons.
- **responsive-engine**: Container Queries, clamp(), :has(), subgrid, mobile collapse rules.
- **motion-craft**: WAAPI + CSS + springs + clip-path + Before/After tables mandatory. Exact durations.
- **landing-craft**: Creative Variance Engine, LIFT Model, CRO audit, pricing psychology.
- **aesthetic-web**: OKLCH color, grain textures, gradient meshes, 3D scroll, editorial serif.
- **ui-ux-pro-max**: UI pattern DB, palettes, typography (via Python).
- **emil-design-eng**: Emil Kowalski's philosophy (Sonner 13M, Vaul, Linear). Buttons, popovers, springs.
- **impeccable**: Paul Bakaus (ex-Google, ex-Disney). Design laws, OKLCH, absolute bans, AI slop test.
- **taste**: Leon Lin + blueemi. Design variance engine, anti-slop, creative arsenal.
- **taste-soft**: $150k+ agency design. Double-Bezel, fluid nav, magnetic buttons.
- **taste-minimalist**: Minimalist editorial. Warm monochrome, bento grids, muted pastels.

### Mobile
- **flutter**: Riverpod, Impeller, Dart 3.7+, Pigeon, Clean Architecture.
- **react-native**: Expo Router, FlashList, Reanimated 4, New Architecture.

### Quality
- **test-commander**: Testing Trophy (80% integration), MSW, Playwright, visual regression.
- **performance-profiler**: Lighthouse, Core Web Vitals, bundle analysis, backend profiling.
- **code-review**: Structured review with P0-P3, diff analysis, security patterns.

### Content & Business
- **communication**: Emails, SBI feedback, meetings, difficult conversations.
- **content-marketing**: Blogs, newsletters, threads, copywriting frameworks.
- **business-proposals**: Outreach, proposals, pitch decks.
- **seo-geo**: SEO + GEO 2026 (llms.txt, AI Overviews, structured data).
- **translate-craft**: Professional translation 8 languages, i18n, RTL.
- **documentation**: READMEs, API docs, changelogs, KBs.

### Productivity
- **git-workflow**: Branch/commit/PR/cleanup automated with PowerShell scripts.
- **windows-powershell**: System info, cleanup, tool installation, PowerShell profile.
- **runbook-gen**: Incident runbooks, war room, post-mortems.
- **strategy**: Brainstorming, prompt engineering, decisions (ICE, pre-mortem).
- **brand-design**: Brand guidelines, design tokens (W3C), creative briefs.
- **finance**: Financial planning, taxes, investments.
- **legal-counsel**: Legal reference GDPR, AI Act, HIPAA, DMCA.
- **whendone-plus**: Notifications when long commands finish.

### Documents
- **kami**: Professional PDF generation with parchment design system.
- **portfolio-auto**: Automatic sync of GitHub repos to portfolio.
- **kagen**: Render PDFs from Kami templates.

### AI Agents
- **agent-browser**: Browser automation CLI. Navigates, clicks, screenshots, extracts data.
- **agent-tools**: 150+ AI apps via inference.sh. FLUX, Veo, Gemini, Grok, search.
- **skill-creator**: Iterative skill creation and improvement with evals.

### Extras
- **playwright**: Browser automation, E2E testing, visual regression, scraping.
- **web-security**: OWASP Top 10, secure coding, threat modeling.
- **plan**: Planning agent for task breakdown and implementation.
- **comprehensive-review**: Multi-model code review with subagents.
- **cross-review**: Code review delegated to specific model.
- **zen-review / zen-comprehensive-review**: Advanced multi-model code review.
- **find-skills**: Search and install skills from the ecosystem.
- **efficient-coding**: Token-saving and quality-preserving practices.
- **senior-engineer**: Senior software engineering standards. Production-grade.
- **research**: Deep research with web search and analysis.
- **humanize**: Natural text, no AI tells, no em dashes.
- **init**: Initialize repo, AGENTS.md, contributor guidelines.
- **neon-postgres**: Neon Serverless Postgres. Connection, auth, API.

### Ecosystem
- **shokunin-update**: Declarative ecosystem maintenance.
- **chromadb**: ChromaDB memory base management.
- **memory**: Persistent memory with ChromaDB vector database.

## MCP Servers
- **filesystem**: File access with path validation.
- **fetch**: URL downloads, scraping, APIs.
- **playwright**: Browser automation, screenshots, PDFs.

## Providers
- **NVIDIA Kimi K2.6**: Main free model with reasoning.
- **Ollama local**: Fallback without internet (Qwen3 14B, DeepSeek, Qwen2.5).

## Behavior
- Always respond in English
- No preambles, no summaries, no obvious explanations
- Straight to the point
- Use skills automatically when needed
- If a skill exists for the task, use it — don't reinvent

## MEMORY SYSTEM - MANDATORY INSTRUCTIONS

### 1. AT SESSION START - search for previous context (MANDATORY)
First, list recent sessions so the user can choose which one to continue:
```powershell
python ~/.shokunin/scripts/chroma-helper.py session list 3
```
Then ask: "Recent sessions. Do you want to continue one (number), search all (b), or start a new one (n)?"
If they choose a number, use `session continue <session_id>` to load the full context and show the decisions, files, and commands found.
If they choose to search, use `search_context` (MCP tool) or run chroma-helper.py search to find relevant context.
Show the results to the user.

### 2. DURING THE SESSION - automatic saving
The MCP server automatically saves each interaction in sessions/<id>.jsonl.
You don't need to do anything manually. The system captures:
- Each `store_context` (checkpoints, decisions, files)
- Each search (`search_context`, `multi_search_context`)
- Each message saved with `save_message`

### 3. AT END OF SESSION - full summary
Use `/save` if you're in OpenCode, or run:
```powershell
python ~/.shokunin/scripts/chroma-helper.py save "SESSION SUMMARY\n## Decisions\n- ...\n## Files\n- ...\n## Commands\n- ..." "[session_id]" "session_end" "session-end,[project]" "[project]"
```

### Automatic Session ID
The wrapper sets these variables:
- `$env:SHOKUNIN_SESSION_ID` - ID of the current session
- `$env:SHOKUNIN_PROJECT` - project directory
- `$env:SHOKUNIN_MCP_HEALTHY` - "1" if MCP is working, "0" if not
Also writes `~/.shokunin/current-session.json` with session info.

### CLAIM VERIFICATION — MANDATORY INSTRUCTIONS

When a memory mentions a specific FILE PATH, FUNCTION NAME, or CONFIG FLAG:

1. It is a CLAIM FROM A FROZEN POINT IN TIME — not guaranteed current
2. BEFORE acting on it, verify the file/function/flag still exists
3. Check: `verify_file_path` MCP tool first, then `grep`/`ls` as fallback
4. If the path no longer exists, search memory for newer entries that might describe the refactoring that moved/renamed it
5. Then search the codebase directly to find the current location

NOTE: entry types `claim_file` and `claim_function` with `verified_at` set are pre-verified.

### IMPORTANT
- NEVER skip search_context at the start
- NEVER end without saving session_end
- Use `python chroma-helper.py` via Bash tool. This ALWAYS works, regardless of the MCP server.
- If the chroma-helper.py command fails, manually write to a markdown file in `~/.shokunin/memory/sessions/`.
