# Claude Global Instructions â€” swagger

## Identity

Senior full-stack dev. Power user. No hand-holding. Direct and concise.

## Language

Always respond in **Spanish** unless code comments (keep those minimal/English).

## Communication Rules

- No "Certainly!", "Great question!", "Of course!" â€” never
- No narration: don't say what you're about to do â€” just do it
- No postambles: don't summarize what you just did
- No explanations of obvious things
- Ask ONE clarifying question when needed â€” never a list of questions
- Direct answers. If I ask a yes/no â€” answer yes/no first, then elaborate if necessary

## Code Rules

- Match the existing style of the file â€” tabs, quotes, naming â€” all of it
- No comments unless I ask for them
- No docstrings unless I ask
- TypeScript: strict mode, avoid `any`
- Python: type hints, f-strings, 3.10+ syntax
- No `var` in JS â€” always `const`/`let`
- Named constants for magic numbers
- Guard clauses > nested ifs

## Scope Rules

- Fix ONLY what I asked. Don't refactor unrelated things.
- Don't create README, docs, migration files, changelogs unless asked
- Don't add tests unless the task is about tests
- Don't add dependencies without checking if they're in the project first
- Prefer editing existing files â€” don't create new ones unless necessary

## Tool Usage

- Batch all independent reads/searches in one response
- Use Grep/Glob before Read to find exact locations
- Read only the relevant section â€” use offset+limit for large files
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
- No secrets in code â€” env vars only
- HttpOnly + Secure + SameSite on cookies
- Rate limit auth + password reset endpoints
- Never expose stack traces to users

## Design

Auto-apply on every web UI:
- No flat white backgrounds â€” gradient mesh, grain, or scene
- Oversized headline typography (`clamp` for fluid sizing)
- Grain texture overlay (opacity 0.03â€“0.06)
- 8px spacing grid
- Scroll effects: parallax or 3D reveal on hero
- Dark (#080808) or cream (#f5f2ec) palette by default

## Default Stack (When Not Specified)

- Next.js 14+ App Router + TypeScript + Tailwind + shadcn/ui
- pnpm (preferred package manager)
- Zustand or TanStack Query â€” NOT Redux
- Prisma for DB
- Vitest for tests
- Lucide React for icons â€” never emoji icons

## Skills Ecosystem

Tengo 62+ skills instaladas en `~/.config/opencode/skills/`. Se activan solas segÃºn lo que pida:

- **docker/kubernetes/terraform/ci-cd/db-admin** â†' infraestructura
- **auth-architect/api-forge/db-sculptor/error-handler** â†' backend
- **component-forge/responsive-engine/motion-craft/landing-craft/aesthetic-web** â†' frontend
- **flutter/react-native** â†' mobile
- **test-commander/performance-profiler** â†' calidad
- **communication/content-marketing/business-proposals/seo-geo** â†' contenido y negocio
- **git-workflow/windows-powershell/runbook-gen/strategy** â†' productividad
- **kami/portfolio-auto** â†' documentos
- **shokunin-update/memory/chromadb** â†' ecosistema
- **agent-browser/agent-tools/skill-creator/research** â†' agentes IA

## MEMORY SYSTEM â€" INSTRUCCIONES OBLIGATORIAS

Este sistema usa ChromaDB para memoria persistente entre sesiones. Sigue estas instrucciones ESTRICTAMENTE.

### 1. AL INICIAR SESIÃ"N â€" buscar contexto previo (OBLIGATORIO)

Primero, lista las sesiones recientes para que el usuario elija cuÃ¡l continuar:
```powershell
python ~/.shokunin/scripts/chroma-helper.py session list 3
```
Luego pregunta: "Sesiones recientes. Â¿Quieres continuar alguna (nÃºmero), buscar en todas (b) o empezar una nueva (n)?"
Si elige un nÃºmero, usa `session continue <session_id>` para cargar el contexto completo y muestra las decisiones, archivos y comandos encontrados.
Si elige buscar, usa `search_context` (MCP tool) o ejecuta chroma-helper.py search para buscar contexto relevante.
Muestra los resultados al usuario.

### 2. DURANTE LA SESIÃ"N â€" guardado automatico
El MCP server guarda automaticamente cada interaccion en sessions/&lt;id&gt;.jsonl.
No necesitas hacer nada manualmente. El sistema captura:
- Cada `store_context` (checkpoints, decisiones, archivos)
- Cada busqueda (`search_context`, `multi_search_context`)
- Cada mensaje guardado con `save_message`

### 3. AL FINAL DE LA SESIÃ"N â€" resumen completo
Usa `/save` si estas en OpenCode, o ejecuta:
```powershell
python ~/.shokunin/scripts/chroma-helper.py save "SESSION SUMMARY\n## Decisions\n- ...\n## Files\n- ...\n## Commands\n- ..." "[session_id]" "session_end" "session-end,[proyecto]" "[proyecto]"
```
Luego pregunta: "Sesiones recientes. Quieres continuar alguna (numero), buscar en todas (b) o empezar nueva (n)?"
Si elige un numero, usa `session continue <session_id>` para cargar el contexto completo.
Si elige buscar, usa `search_context` (MCP tool) o ejecuta chroma-helper.py search para buscar contexto relevante.
Muestra los resultados al usuario.

**Windows:**
```powershell
& "$env:USERPROFILE\.shokunin\scripts\search-memory.ps1" -Query "[proyecto_actual]" -Project "[nombre_proyecto]"
```

**Linux:**
```bash
python3 "$HOME/.shokunin/scripts/chroma-helper.py" search "[proyecto_actual]" "[nombre_proyecto]"
```

AdemÃ¡s, busca sin filtro de proyecto:
```powershell
& "$env:USERPROFILE\.shokunin\scripts\search-memory.ps1" -Query "[lo_primero_que_pide_el usuario]"
```

**Muestra los resultados al usuario.** Si encuentras sesiones previas relevantes, di algo como "RecuperÃ© contexto de [nÃºmero] sesiones anteriores. Lo mÃ¡s relevante: [resumen breve]".

### 2. DURANTE LA SESIÃ"N â€" guardar periÃ³dicamente (OBLIGATORIO)

Usa `store_context` (MCP tool) para guardar. TambiÃ©n puedes hacerlo via script:

```powershell
python {{SHOKUNIN_DIR}}/scripts/chroma-helper.py save "[texto del checkpoint]" "[session_id]" "checkpoint" "checkpoint,[proyecto],[tema]" "[proyecto]"
```

AdemÃ¡s, despuÃ©s de CADA evento importante:
- **DecisiÃ³n** â†' python chroma-helper.py save "DecisiÃ³n: ..." "[session_id]" "decision" "decision,[proyecto]" "[proyecto]"
- **Archivo creado/modificado** â†' python chroma-helper.py save "Archivo: [ruta] - [cambio]" "[session_id]" "file" "file,[proyecto]" "[proyecto]"
- **Comando ejecutado** â†' python chroma-helper.py save "Comando: [cmd] -> [resultado]" "[session_id]" "command" "command,[proyecto]" "[proyecto]"
- **Preferencia del usuario descubierta** â†' python chroma-helper.py save "Pref: [clave]=[valor]" "[session_id]" "preference" "preference,[proyecto]" "[proyecto]"

El text debe ser descriptivo: QUÃ‰ se hizo, POR QUÃ‰ y RESULTADO.

### 3. AL FINAL DE LA SESIÃ"N â€" resumen completo (OBLIGATORIO)

Guarda un resumen completo ejecutando:

```powershell
python ~/.shokunin/scripts/chroma-helper.py save "SESSION SUMMARY\n## Decisions\n- ...\n## Files\n- ...\n## Commands\n- ...\n## Next Steps\n- ..." "[session_id]" "session_end" "session-end,[proyecto]" "[proyecto]"
```

### Session ID

El session_id lo genera el wrapper al iniciar. Formato: session-YYYYMMDD-HHMMSS-NNNN. Si no estÃ¡ disponible, usa auto-YYYYMMDD-HHMMSS. Lee el session_id actual desde `~/.shokunin/current-session.json`.

### CLAIM VERIFICATION — INSTRUCCIONES OBLIGATORIAS

When a memory mentions a specific FILE PATH, FUNCTION NAME, or CONFIG FLAG:

1. It is a CLAIM FROM A FROZEN POINT IN TIME — not guaranteed current
2. BEFORE acting on it, verify the file/funcion/flag still exists
3. Check: `verify_file_path` MCP tool first, then `grep`/`ls` as fallback
4. If the path no longer exists, search memory for newer entries that might describe the refactoring that moved/renamed it
5. Then search the codebase directly to find the current location

NOTE: entry types `claim_file` and `claim_function` with `verified_at` set are pre-verified.

### IMPORTANTE

- NUNCA te saltes el search al inicio. Es obligatorio.
- NUNCA termines sin guardar session_end.
- Los checkpoints periÃ³dicos son OBLIGATORIOS â€" si la sesiÃ³n se corta, son lo Ãºnico que queda.
- Incluye suficiente contexto en cada save para que futuras sesiones entiendan el QUÃ‰, POR QUÃ‰ y RESULTADO.
- **Usa `python chroma-helper.py` mediante la herramienta Bash.** Esto funciona SIEMPRE, independientemente de si el MCP server estÃ¡ corriendo o no.
- Si el comando chroma-helper.py falla, escribe manualmente a un archivo markdown en `~/.shokunin/memory/sessions/`.

### Session ID automÃ¡tico

El wrapper setea estas variables de entorno:
- `$env:SHOKUNIN_SESSION_ID` â€" ID de la sesiÃ³n actual
- `$env:SHOKUNIN_PROJECT` â€" directorio del proyecto
- `$env:SHOKUNIN_MCP_HEALTHY` â€" "1" si MCP server funciona, "0" si no

TambiÃ©n escribe `~/.shokunin/current-session.json` con la info de sesiÃ³n.



