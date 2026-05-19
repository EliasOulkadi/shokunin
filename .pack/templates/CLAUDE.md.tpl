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

Tengo 62+ skills instaladas en `~/.config/opencode/skills/`. Se activan solas según lo que pida:

- **docker/kubernetes/terraform/ci-cd/db-admin** → infraestructura
- **auth-architect/api-forge/db-sculptor/error-handler** → backend
- **component-forge/responsive-engine/motion-craft/landing-craft/aesthetic-web** → frontend
- **flutter/react-native** → mobile
- **test-commander/performance-profiler/code-review** → calidad
- **communication/content-marketing/business-proposals/seo-geo** → contenido y negocio
- **git-workflow/windows-powershell/runbook-gen/strategy** → productividad
- **kami/portfolio-auto** → documentos
- **shokunin-update/memory/chromadb** → ecosistema
- **agent-browser/agent-tools/skill-creator/research** → agentes IA

## MEMORY SYSTEM — INSTRUCCIONES OBLIGATORIAS

Este sistema usa ChromaDB para memoria persistente entre sesiones. Sigue estas instrucciones ESTRICTAMENTE.

### 1. AL INICIAR SESIÓN — buscar contexto previo (OBLIGATORIO)

Primero, lista las sesiones recientes para que el usuario elija cuál continuar:
```powershell
python ~/.shokunin/scripts/chroma-helper.py session list 3
```
Luego pregunta: "Sesiones recientes. ¿Quieres continuar alguna (número), buscar en todas (b) o empezar una nueva (n)?"
Si elige un número, usa `session continue <session_id>` para cargar el contexto completo y muestra las decisiones, archivos y comandos encontrados.
Si elige buscar, usa `search_context` (MCP tool) o ejecuta chroma-helper.py search para buscar contexto relevante.
Muestra los resultados al usuario.

### 2. DURANTE LA SESIÓN — guardado automático
El MCP server guarda automáticamente cada interacción en sessions/<id>.jsonl.
No necesitas hacer nada manualmente. El sistema captura:
- Cada `store_context` (checkpoints, decisiones, archivos)
- Cada búsqueda (`search_context`, `multi_search_context`)
- Cada mensaje guardado con `save_message`

### 3. AL FINAL DE LA SESIÓN — resumen completo
Usa `/save` si estás en OpenCode, o ejecuta:
```powershell
python ~/.shokunin/scripts/chroma-helper.py save "SESSION SUMMARY\n## Decisions\n- ...\n## Files\n- ...\n## Commands\n- ..." "[session_id]" "session_end" "session-end,[proyecto]" "[proyecto]"
```

### Session ID automático
El wrapper setea estas variables:
- `$env:SHOKUNIN_SESSION_ID` — ID de la sesión actual
- `$env:SHOKUNIN_PROJECT` — directorio del proyecto
- `$env:SHOKUNIN_MCP_HEALTHY` — "1" si MCP funciona, "0" si no
También escribe `~/.shokunin/current-session.json` con la info de sesión.

### IMPORTANTE
- NUNCA te saltes search_context al inicio
- NUNCA termines sin guardar session_end
- Usa `python chroma-helper.py` mediante Bash tool. Esto funciona SIEMPRE, independientemente del MCP server.
- Si el comando chroma-helper.py falla, escribe manualmente a un archivo markdown en `~/.shokunin/memory/sessions/`.
