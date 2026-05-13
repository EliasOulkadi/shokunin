# Shokunin · 職人

**34 agent skills** — nivel 10/10. Progressive disclosure, scripts ejecutables, referencias profundas, assets reutilizables, YAML frontmatter completo, workflows procedimentales con árboles de decisión, manejo de errores, checklists de producción, y anti-patrones.

> 職人 (shokunin) means *artisan* in Japanese. These skills aim for that standard.

## Quick Start

```bash
git clone git@github.com:EliasOulkadi/shokunin.git

# OpenCode auto-discovers from:
#   ~/.config/opencode/skills/
#   .claude/skills/
```

Or symlink: `ln -s $(pwd)/shokunin/* ~/.config/opencode/skills/`

## Skills

| Skill | Versión | Líneas | Scripts | Refs | Assets | Descripción |
|-------|---------|--------|---------|------|--------|-------------|
| **api-forge** | v3.0 | ~200 | — | — | — | REST/GraphQL APIs con OpenAPI 3.1, webhooks, idempotencia |
| **auth-architect** | v3.0 | ~220 | — | 2 | — | OAuth2 + PKCE, WebAuthn/Passkeys, RBAC/ABAC, OWASP |
| **ci-cd** | v3.0 | ~230 | 1 | 2 | 2 | GitHub Actions, GitLab CI, CircleCI, rollback, OIDC |
| **component-forge** | v3.0 | ~210 | 1 | 2 | 2 | React + Vue + Svelte, RSC, a11y WCAG 2.2, tests |
| **db-admin** | v3.0 | ~160 | 2 | 1 | 1 | PostgreSQL DBA: backup, monitor, replication, pooling |
| **db-sculptor** | v3.0 | ~230 | 1 | 3 | 1 | PostgreSQL indexes, EXPLAIN ANALYZE, FTS, migraciones |
| **docker** | v3.0 | ~210 | 2 | 1 | 1 | Multi-stage, multi-arch, BuildKit, compose watch, security |
| **error-handler** | v3.0 | ~220 | 1 | 2 | 1 | OpenTelemetry tracing, error budgets, circuit breaker |
| **flutter** | v2.0 | ~260 | — | — | — | Riverpod, Impeller, Dart 3.7+, Pigeon, Clean Architecture |
| **git-workflow** | v3.0 | ~210 | 4 | 2 | — | Git automation: branch, commit, PR, rebase, cleanup |
| **kubernetes** | v3.0 | ~240 | 2 | 2 | 1 | Gateway API, service mesh, eBPF/Cilium, PDB, HPA |
| **landing-craft** | v3.0 | ~230 | 1 | 2 | 1 | CRO frameworks, personalización, form opt, INP |
| **motion-craft** | v3.0 | ~190 | 1 | 2 | 1 | WAAPI, ScrollTimeline, FLIP, spring physics |
| **performance-profiler** | v3.0 | ~220 | 2 | 2 | — | Lighthouse, Core Web Vitals, profiling, budgets |
| **react-native** | v2.0 | ~260 | — | — | — | Expo Router, FlashList, Reanimated 4, New Architecture |
| **responsive-engine** | v3.0 | ~200 | 1 | 2 | 1 | Container Queries, :has(), subgrid, dvh/lvh |
| **seo-geo** | v3.0 | ~210 | 2 | 2 | 1 | SEO + GEO 2026, EEAT, schema, AI search optimization |
| **terraform** | v3.0 | ~210 | 2 | 2 | 1 | Stacks, test framework, 1.10+, moved/removed blocks |
| **test-commander** | v3.0 | ~230 | 1 | 2 | 2 | Testing Trophy, MSW, Playwright, visual regression |
| **communication** | v2.0 | ~200 | — | — | — | Emails, SBI feedback, difficult convos, meeting notes |
| **content-marketing** | v2.0 | ~200 | — | — | — | Blogs, newsletters, threads, Cialdini |
| **business-proposals** | v2.0 | ~180 | — | — | — | Outreach, proposals, SOWs, pitch decks |
| **design** | v2.0 | ~180 | — | — | — | Brand guidelines, design tokens (W3C), system audit |
| **documentation** | v2.0 | ~170 | — | — | — | READMEs, API docs, changelogs, knowledge bases |
| **finance** | v2.0 | ~190 | — | — | — | 5-pillar framework, 2026 limits, Mega Backdoor |
| **legal-counsel** | v2.0 | ~180 | — | — | — | GDPR, AI Act, DSA/DMA, HIPAA 2026, state laws |
| **runbook-gen** | v2.0 | ~180 | — | — | — | Incident response, war room, post-mortems |
| **strategy** | v2.0 | ~180 | — | — | — | Brainstorming, prompts, ICE/pre-mortem |
| **translate-craft** | v2.0 | ~190 | — | — | — | 8 languages, i18n, ICU messages, RTL |
| **windows-powershell** | v3.0 | ~180 | 3 | 1 | 1 | Windows 11 sysadmin, system info, cleanup, profile |
| **kami** | v3.0 | ~410 | 5 | 9 | 18 | Professional PDFs with parchment design system |
| **portfolio-auto** | v1.0 | ~120 | — | — | — | GitHub → portfolio sync |
| **ui-ux-pro-max** | v1.0 | ~100 | — | — | — | Python DB: UI patterns, colors, typography |
| **whendone-plus** | v1.0 | ~80 | — | — | — | Auto-notify when commands complete |

## What's New in v3.0

- **10 skills con scripts ejecutables** (PowerShell + Bash): docker, kubernetes, terraform, test-commander, db-sculptor, error-handler, ci-cd, motion-craft, responsive-engine, landing-craft, component-forge
- **5 nuevas skills**: seo-geo, git-workflow, db-admin, windows-powershell, performance-profiler
- **Scripts deterministas** en `scripts/`: generación de scaffolding, auditorías, monitoreo, análisis
- **Assets reutilizables** en `assets/`: templates de código, YAML, CSS, HTML
- **Referencias profundas** en `references/`: contenido denso offload de SKILL.md principal
- **allowed-tools** en frontmatter para control granular de permisos
- **Decision trees** en workflows: if/then/else para elegir el camino correcto
- **Error handling** por skill: tabla de escenarios → causa → fix
- **3 skills Windows-aware**: windows-powershell, db-admin, git-workflow

## Quality

| Metric | Detail |
|--------|--------|
| Coverage | 34 skills across 12 domains |
| Avg depth | ~200 lines per SKILL.md |
| Scripts | 27 ejecutables (PowerShell/Bash) |
| References | 22 archivos de referencia profunda |
| Assets | 14 templates reutilizables |
| Structure | YAML frontmatter + SKILL.md + scripts/ + references/ + assets/ |
| Sources | OWASP, Google SRE, PostgreSQL docs, MDN, NIST, Google Search Central, Microsoft docs |

## License

MIT
