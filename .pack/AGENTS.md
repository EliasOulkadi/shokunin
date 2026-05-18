# AGENTS.md Shokunin AI Ecosystem

## Profile
Senior full-stack dev / indie-hacker. Construyo backend, frontend, mobile, contenido, negocio. Windows 11.

## Skills disponibles (62 v4.0)
Se activan automaticamente segun lo que pidas. No necesitas nombrarlas.

### Infraestructura
- **docker**: Containeriza cualquier proyecto. Multi-stage, multi-arch, compose, seguridad.
- **kubernetes**: Manifiestos, Gateway API, service mesh, debugging.
- **terraform**: Infraestructura como codigo, Stacks, state management.
- **ci-cd**: Pipelines GitHub Actions / GitLab CI / CircleCI, rollback, OIDC.
- **db-admin**: Backup, restore, monitoreo, replicacion PostgreSQL.

### Backend
- **api-forge**: APIs REST/GraphQL con OpenAPI 3.1, webhooks, rate limiting, sub-comandos.
- **auth-architect**: OAuth2, JWT, WebAuthn, RBAC, OWASP security, sub-comandos.
- **db-sculptor**: Schemas Prisma/Drizzle, indices, EXPLAIN ANALYZE, migraciones.
- **error-handler**: OpenTelemetry, error budgets, circuit breaker, logging.

### Frontend (v4.0 mejorado con patrones Emil Kowalski + Impeccable)
- **component-forge**: Componentes React/Vue/Svelte con todos los estados, a11y, buttons tactiles.
- **responsive-engine**: Container Queries, clamp(), :has(), subgrid, mobile collapse rules.
- **motion-craft**: WAAPI + CSS + springs + clip-path + Before/After tables obligatorias. Duraciones exactas.
- **landing-craft**: Creative Variance Engine, LIFT Model, CRO audit, pricing psychology.
- **aesthetic-web**: OKLCH color, grain textures, gradient meshes, 3D scroll, editorial serif.
- **ui-ux-pro-max**: DB de patrones UI, paletas, tipografia (via Python).
- **emil-design-eng**: Filosofia de Emil Kowalski (Sonner 13M, Vaul, Linear). Buttons, popovers, springs.
- **impeccable**: Paul Bakaus (ex-Google, ex-Disney). Design laws, OKLCH, absolute bans, AI slop test.
- **taste**: Leon Lin + blueemi. Design variance engine, anti-slop, creative arsenal.
- **taste-soft**: Diseno agencia $150k+. Double-Bezel, fluid nav, magnetic buttons.
- **taste-minimalist**: Editorial minimalista. Warm monochrome, bento grids, muted pastels.

### Mobile
- **flutter**: Riverpod, Impeller, Dart 3.7+, Pigeon, Clean Architecture.
- **react-native**: Expo Router, FlashList, Reanimated 4, New Architecture.

### Calidad
- **test-commander**: Testing Trophy (80% integracion), MSW, Playwright, visual regression.
- **performance-profiler**: Lighthouse, Core Web Vitals, bundle analysis, backend profiling.
- **code-review**: Review estructurado con P0-P3, diff analysis, security patterns.

### Contenido y Negocio
- **communication**: Emails, feedback SBI, reuniones, conversaciones dificiles.
- **content-marketing**: Blogs, newsletters, threads, copywriting frameworks.
- **business-proposals**: Outreach, proposals, pitch decks.
- **seo-geo**: SEO + GEO 2026 (llms.txt, AI Overviews, structured data).
- **translate-craft**: Traduccion profesional 8 idiomas, i18n, RTL.
- **documentation**: READMEs, API docs, changelogs, KBs.

### Productividad
- **git-workflow**: Branch/commit/PR/cleanup automatizado con scripts PowerShell.
- **windows-powershell**: System info, cleanup, instalacion de tools, perfil PowerShell.
- **runbook-gen**: Runbooks de incidentes, war room, post-mortems.
- **strategy**: Brainstorming, prompt engineering, decisiones (ICE, pre-mortem).
- **design**: Brand guidelines, design tokens (W3C), briefs creativos.
- **finance**: Planificacion financiera, impuestos, inversiones.
- **legal-counsel**: Referencia legal GDPR, AI Act, HIPAA, DMCA.
- **whendone-plus**: Notificaciones cuando comandos largos terminan.

### Documentos
- **kami**: Generacion de PDFs profesionales con sistema de diseno parchment.
- **portfolio-auto**: Sincronizacion automatica de repos GitHub a portfolio.

### Agentes IA
- **agent-browser**: Browser automation CLI. Navega, clicks, screenshots, extrae datos.
- **agent-tools**: 150+ AI apps via inference.sh. FLUX, Veo, Gemini, Grok, search.
- **skill-creator**: Creacion y mejora iterativa de skills con evals.

### Extras
- **playwright**: Browser automation, E2E testing, visual regression, scraping.
- **web-security**: OWASP Top 10, secure coding, threat modeling.
- **plan**: Planning agent para task breakdown e implementacion.
- **comprehensive-review**: Code review multi-modelo con subagentes.
- **cross-review**: Code review delegada a modelo especifico.
- **zen-review / zen-comprehensive-review**: Code review multi-modelo avanzada.
- **find-skills**: Busqueda e instalacion de skills del ecosistema.
- **efficient-coding**: Token-saving y quality-preserving practices.
- **senior-engineer**: Senior software engineering standards. Production-grade.
- **research**: Deep research con web search y analisis.
- **humanize**: Texto natural, sin AI tells, sin em dashes.
- **init**: Inicializar repo, AGENTS.md, contributor guidelines.
- **neon-postgres**: Neon Serverless Postgres. Conexion, auth, API.

### Ecosistema
- **shokunin-update**: Mantenimiento declarativo del ecosistema.
- **chromadb**: Gestion de base de memoria ChromaDB.
- **memory**: Memoria persistente con ChromaDB vector database.

## MCP Servers
- **filesystem**: Acceso a archivos con validacion de rutas.
- **fetch**: Descarga de URLs, scraping, APIs.
- **playwright**: Automatizacion de navegador, screenshots, PDFs.

## Providers
- **NVIDIA Kimi K2.6**: Modelo principal gratuito con reasoning.
- **Ollama local**: Fallback sin internet (Qwen3 14B, DeepSeek, Qwen2.5).

## Comportamiento
- Siempre responde en espanol
- No preambulos, no resumenes, no explicaciones obvias
- Directo al grano
- Usa las skills automaticamente cuando sean necesarias
- Si una skill existe para la tarea, usala - no reinventes

## MEMORY SYSTEM - INSTRUCCIONES OBLIGATORIAS

### 1. AL INICIAR SESIÓN - buscar contexto previo (OBLIGATORIO)
Primero, lista las sesiones recientes para que el usuario elija cuál continuar:
```powershell
python ~/.shokunin/scripts/chroma-helper.py session list 3
```
Luego pregunta: "Sesiones recientes. ¿Quieres continuar alguna (número), buscar en todas (b) o empezar una nueva (n)?"
Si elige un número, usa `session continue <session_id>` para cargar el contexto completo y muestra las decisiones, archivos y comandos encontrados.
Si elige buscar, usa `search_context` (MCP tool) o ejecuta chroma-helper.py search para buscar contexto relevante.
Muestra los resultados al usuario.

### 2. DURANTE LA SESIÓN - guardado automático
El MCP server guarda automáticamente cada interacción en sessions/<id>.jsonl.
No necesitas hacer nada manualmente. El sistema captura:
- Cada `store_context` (checkpoints, decisiones, archivos)
- Cada búsqueda (`search_context`, `multi_search_context`)
- Cada mensaje guardado con `save_message`

### 3. AL FINAL DE LA SESIÓN - resumen completo
Usa `/save` si estás en OpenCode, o ejecuta:
```powershell
python ~/.shokunin/scripts/chroma-helper.py save "SESSION SUMMARY\n## Decisions\n- ...\n## Files\n- ...\n## Commands\n- ..." "[session_id]" "session_end" "session-end,[proyecto]" "[proyecto]"
```

### Session ID automático
El wrapper setea estas variables:
- `$env:SHOKUNIN_SESSION_ID` - ID de la sesión actual
- `$env:SHOKUNIN_PROJECT` - directorio del proyecto
- `$env:SHOKUNIN_MCP_HEALTHY` - "1" si MCP funciona, "0" si no
También escribe `~/.shokunin/current-session.json` con la info de sesión.

### CLAIM VERIFICATION — INSTRUCCIONES OBLIGATORIAS

When a memory mentions a specific FILE PATH, FUNCTION NAME, or CONFIG FLAG:

1. It is a CLAIM FROM A FROZEN POINT IN TIME — not guaranteed current
2. BEFORE acting on it, verify the file/funcion/flag still exists
3. Check: `verify_file_path` MCP tool first, then `grep`/`ls` as fallback
4. If the path no longer exists, search memory for newer entries that might describe the refactoring that moved/renamed it
5. Then search the codebase directly to find the current location

NOTE: entry types `claim_file` and `claim_function` with `verified_at` set are pre-verified.

### IMPORTANTE
- NUNCA te saltes search_context al inicio
- NUNCA termines sin guardar session_end
- Usa `python chroma-helper.py` mediante Bash tool. Esto funciona SIEMPRE, independientemente del MCP server.
- Si el comando chroma-helper.py falla, escribe manualmente a un archivo markdown en `~/.shokunin/memory/sessions/`.
