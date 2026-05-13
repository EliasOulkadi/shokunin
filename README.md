# Shokunin · 職人

**36 agent skills** — nivel 10/10. Progressive disclosure, scripts ejecutables, referencias profundas, assets reutilizables, YAML frontmatter completo, workflows procedimentales, manejo de errores, checklists de produccion, y anti-patrones. Incluye memoria persistente ChromaDB, bot de Telegram, y automatizaciones.

> 職人 (shokunin) means *artisan* in Japanese. These skills aim for that standard.

## One-Command Install

```powershell
irm https://raw.githubusercontent.com/EliasOulkadi/shokunin/master/install.ps1 | iex
```

El instalador configura automaticamente:
- **36 skills** en ~/.config/opencode/skills/
- **ChromaDB** memoria persistente entre sesiones
- **Telegram bot** (necesitas crear uno en @BotFather)
- **PowerShell profile** con 20+ aliases
- **CLAUDE.md** con instrucciones globales
- **MCP servers**: filesystem, fetch, playwright, memory
- **Superpowers plugin**: metodologia de desarrollo
- **Tarea programada**: limpieza semanal (domingos 21h)
- **WezTerm config**, bookmarklet, dashboard

**Requisitos:** Windows 10/11, Node.js 18+, Python 3.11+, Git

**Manual:**
```bash
git clone https://github.com/EliasOulkadi/shokunin.git
# o descarga ZIP: https://github.com/EliasOulkadi/shokunin/archive/refs/heads/master.zip
```

## Skills

| Skill | Ver | Lines | Scripts | Refs | Assets | Description |
|-------|-----|-------|--------|------|--------|-------------|
| **api-forge** | v3.0 | ~200 | - | - | - | REST/GraphQL APIs con OpenAPI 3.1, webhooks, idempotencia |
| **auth-architect** | v3.0 | ~220 | - | 2 | - | OAuth2 + PKCE, WebAuthn/Passkeys, RBAC/ABAC, OWASP |
| **ci-cd** | v3.0 | ~230 | 1 | 2 | 2 | GitHub Actions, GitLab CI, CircleCI, rollback, OIDC |
| **communication** | v2.0 | ~200 | - | - | - | Emails, SBI feedback, difficult convos, meeting notes |
| **component-forge** | v3.0 | ~210 | 1 | 2 | 2 | React + Vue + Svelte, RSC, a11y WCAG 2.2, tests |
| **content-marketing** | v2.0 | ~200 | - | - | - | Blogs, newsletters, threads, SEO/GEO 2026, Cialdini |
| **business-proposals** | v2.0 | ~180 | - | - | - | Outreach, proposals, SOWs, pitch decks |
| **db-admin** | v3.0 | ~160 | 2 | 1 | 1 | PostgreSQL DBA: backup, monitor, replication, pooling |
| **db-sculptor** | v3.0 | ~230 | 1 | 3 | 1 | PostgreSQL indexes, EXPLAIN ANALYZE, FTS, migraciones |
| **design** | v2.0 | ~180 | - | - | - | Brand guidelines, design tokens (W3C), system audit |
| **documentation** | v2.0 | ~170 | - | - | - | READMEs, API docs, changelogs, knowledge bases |
| **docker** | v3.0 | ~210 | 2 | 1 | 1 | Multi-stage, multi-arch, BuildKit, compose watch, security |
| **error-handler** | v3.0 | ~220 | 1 | 2 | 1 | OpenTelemetry tracing, error budgets, circuit breaker |
| **finance** | v2.0 | ~190 | - | - | - | 5-pillar framework, 2026 limits, Mega Backdoor |
| **flutter** | v2.0 | ~260 | - | - | - | Riverpod, Impeller, Dart 3.7+, Pigeon, Clean Architecture |
| **git-workflow** | v3.0 | ~210 | 4 | 2 | - | Git automation: branch, commit, PR, rebase, cleanup |
| **kami** | v3.0 | ~410 | 5 | 9 | 18 | Professional PDFs con parchment design system |
| **kubernetes** | v3.0 | ~240 | 2 | 2 | 1 | Gateway API, service mesh, eBPF/Cilium, PDB, HPA |
| **landing-craft** | v3.0 | ~230 | 1 | 2 | 1 | CRO frameworks, personalizacion, form opt, INP |
| **legal-counsel** | v2.0 | ~180 | - | - | - | GDPR, AI Act, DSA/DMA, HIPAA 2026, state laws |
| **motion-craft** | v3.0 | ~190 | 1 | 2 | 1 | WAAPI, ScrollTimeline, FLIP, spring physics |
| **performance-profiler** | v3.0 | ~220 | 2 | 2 | - | Lighthouse, Core Web Vitals, profiling, budgets |
| **portfolio-auto** | v1.0 | ~120 | - | - | - | GitHub to portfolio sync |
| **react-native** | v2.0 | ~260 | - | - | - | Expo Router, FlashList, Reanimated 4, New Architecture |
| **responsive-engine** | v3.0 | ~200 | 1 | 2 | 1 | Container Queries, :has(), subgrid, dvh/lvh |
| **runbook-gen** | v2.0 | ~180 | - | - | - | Incident response, war room, post-mortems |
| **seo-geo** | v3.0 | ~210 | 2 | 2 | 1 | SEO + GEO 2026, EEAT, schema, AI search optimization |
| **strategy** | v2.0 | ~180 | - | - | - | Brainstorming, prompts, ICE/pre-mortem |
| **terraform** | v3.0 | ~210 | 2 | 2 | 1 | Stacks, test framework, 1.10+, moved/removed blocks |
| **test-commander** | v3.0 | ~230 | 1 | 2 | 2 | Testing Trophy, MSW, Playwright, visual regression |
| **translate-craft** | v2.0 | ~190 | - | - | - | 8 languages, i18n, ICU messages, RTL |
| **ui-ux-pro-max** | v1.0 | ~100 | - | - | - | Python DB: UI patterns, colors, typography |
| **whendone-plus** | v1.0 | ~80 | - | - | - | Auto-notify when commands complete |
| **windows-powershell** | v3.0 | ~180 | 3 | 1 | 1 | Windows 11 sysadmin, cleanup, profile |
| **memory** | v1.0 | ~80 | - | 1 | - | ChromaDB memoria persistente entre sesiones |
| **telegram-bot** | v1.0 | ~70 | - | - | - | Acceso movil via Telegram |
| **chromadb** | v1.0 | ~60 | - | - | - | Gestion de base de memoria vectorial |

## Quality

| Metric | Detail |
|--------|--------|
| Coverage | 36 skills across 9 domains |
| Avg depth | ~200 lines per SKILL.md |
| Scripts | 27 ejecutables (PowerShell/Bash) |
| References | 24 archivos de referencia profunda |
| Assets | 15 templates reutilizables |
| Structure | YAML frontmatter + SKILL.md + scripts/ + references/ + assets/ |
| Cost | $0 (NVIDIA free tier + Ollama local) |

## License

MIT
