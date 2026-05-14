# AGENTS.md Shokunin AI Ecosystem

## Profile
Senior full-stack dev / indie-hacker. Construyo backend, frontend, mobile, contenido, negocio. Windows 11.

## Skills disponibles (34+)
Se activan automaticamente segun lo que pidas. No necesitas nombrarlas.

### Infraestructura
- **docker**: Containeriza cualquier proyecto. Multi-stage, multi-arch, compose, seguridad.
- **kubernetes**: Manifiestos, Gateway API, service mesh, debugging.
- **terraform**: Infraestructura como codigo, Stacks, state management.
- **ci-cd**: Pipelines GitHub Actions / GitLab CI / CircleCI, rollback, OIDC.
- **db-admin**: Backup, restore, monitoreo, replicacion PostgreSQL.

### Backend
- **api-forge**: APIs REST/GraphQL con OpenAPI 3.1, webhooks, rate limiting.
- **auth-architect**: OAuth2, JWT, WebAuthn, RBAC, OWASP security.
- **db-sculptor**: Schemas Prisma/Drizzle, indices, EXPLAIN ANALYZE, migraciones.
- **error-handler**: OpenTelemetry, error budgets, circuit breaker, logging.

### Frontend
- **component-forge**: Componentes React/Vue/Svelte con todos los estados, a11y, tests.
- **responsive-engine**: Container Queries, clamp(), :has(), subgrid.
- **motion-craft**: WAAPI, scroll animations, FLIP, easing systems.
- **landing-craft**: Landing pages optimizadas para conversion, CRO, A/B testing.
- **ui-ux-pro-max**: DB de patrones UI, paletas, tipografia (via Python).

### Mobile
- **flutter**: Riverpod, Impeller, Dart 3.7+, Pigeon, Clean Architecture.
- **react-native**: Expo Router, FlashList, Reanimated 4, New Architecture.

### Calidad
- **test-commander**: Tests unitarios/integracion/E2E/visuales con MSW + Playwright.
- **performance-profiler**: Lighthouse, Core Web Vitals, profiling backend.

### Contenido y Negocio
- **communication**: Emails, feedback, reuniones, conversaciones dificiles.
- **content-marketing**: Blogs, newsletters, threads, copywriting.
- **business-proposals**: Outreach, proposals, pitch decks.
- **seo-geo**: SEO + optimizacion para buscadores AI (ChatGPT, Gemini, Perplexity).
- **translate-craft**: Traduccion profesional 8 idiomas, i18n, RTL.
- **documentation**: READMEs, API docs, changelogs, KBs.

### Productividad
- **git-workflow**: Branch/commit/PR/cleanup automatizado con scripts PowerShell.
- **windows-powershell**: System info, cleanup, instalacion de tools, perfil PowerShell.
- **runbook-gen**: Runbooks de incidentes, war room, post-mortems.
- **strategy**: Brainstorming, prompt engineering, decisiones.
- **design**: Brand guidelines, design tokens, briefs creativos.
- **finance**: Planificacion financiera, impuestos, inversiones.
- **legal-counsel**: Referencia legal GDPR, AI Act, HIPAA, DMCA.
- **whendone-plus**: Notificaciones cuando comandos largos terminan.

### Documentos
- **kami**: Generacion de PDFs profesionales con sistema de diseno parchment.
- **portfolio-auto**: Sincronizacion automatica de repos GitHub a portfolio.

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

### 1. AL INICIAR SESION - buscar contexto previo (OBLIGATORIO)
Ejecuta search_context con el proyecto actual y el tema que pide el usuario.
Muestra los resultados al usuario.

### 2. DURANTE LA SESION - guardar periodicamente (OBLIGATORIO)
Cada 3-5 intercambios, guarda un checkpoint con store_context (type: checkpoint).
Despues de CADA evento importante (decision, archivo, comando, preferencia) guarda con store_context.

### 3. AL FINAL DE LA SESION - resumen completo (OBLIGATORIO)
store_context con type session_end y resumen estructurado de la sesion.

### IMPORTANTE
- NUNCA te saltes search_context al inicio
- NUNCA termines sin store_context type session_end
