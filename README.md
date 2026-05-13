# Shokunin · 職人

**29 agent skills** — actualizadas y mejoradas con progressive disclosure, YAML frontmatter completo, workflows procedimentales, y referencias externas.

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

| Skill | Description | Updated |
|-------|-------------|---------|
| **api-forge** | REST/GraphQL APIs with OpenAPI 3.1, webhooks, idempotency | v2.0 |
| **auth-architect** | OAuth2 + PKCE, WebAuthn/Passkeys, RBAC/ABAC, OWASP | v2.0 |
| **ci-cd** | GitHub Actions, GitLab CI, CircleCI, rollback, OIDC | v2.0 |
| **component-forge** | React + Vue + Svelte components, RSC patterns, a11y, tests | v2.0 |
| **db-sculptor** | PostgreSQL indexes, EXPLAIN ANALYZE, FTS, migrations | v2.0 |
| **docker** | Multi-stage, multi-arch, BuildKit, compose watch, security | v2.0 |
| **error-handler** | OpenTelemetry tracing, error budgets, circuit breaker | v2.0 |
| **flutter** | Riverpod, Impeller, Dart 3.7+, Pigeon, Clean Architecture | v2.0 |
| **kubernetes** | Gateway API, service mesh, eBPF/Cilium, PDB, HPA | v2.0 |
| **motion-craft** | WAAPI, ScrollTimeline, FLIP, Spring physics, CSS animations | v2.0 |
| **react-native** | Expo Router, FlashList, Reanimated 4, New Architecture | v2.0 |
| **responsive-engine** | Container Queries, :has(), subgrid, dvh/lvh units | v2.0 |
| **terraform** | Stacks, test framework, 1.10+ features, moved/removed blocks | v2.0 |
| **test-commander** | Testing Trophy, MSW, Playwright, visual regression, snapshots | v2.0 |
| **communication** | Emails, SBI feedback, difficult convos, meeting notes | v2.0 |
| **content-marketing** | Blogs, newsletters, threads, SEO/GEO 2026, Cialdini | v2.0 |
| **business-proposals** | Outreach, proposals, SOWs, pitch decks, RFP responses | v2.0 |
| **design** | Brand guidelines, design tokens (W3C), system audit | v2.0 |
| **documentation** | READMEs, API docs, changelogs, knowledge bases | v2.0 |
| **finance** | 5-pillar framework, 2026 limits, Mega Backdoor, tax | v2.0 |
| **landing-craft** | CRO frameworks (LIFT), personalization, form opt, INP | v2.0 |
| **legal-counsel** | GDPR, AI Act, DSA/DMA, HIPAA 2026, state laws, DMCA | v2.0 |
| **runbook-gen** | Incident response, war room, post-mortems, escalation | v2.0 |
| **strategy** | Brainstorming, prompts, ICE/pre-mortem/first principles | v2.0 |
| **translate-craft** | 8 languages (ES, JA, FR, DE, PT, ZH, KO, AR), i18n, RTL | v2.0 |
| **portfolio-auto** | GitHub → portfolio sync with Playwright screenshots | v2.0 |
| **ui-ux-pro-max** | Python searchable DB of UI patterns, colors, typography | v2.0 |
| **whendone-plus** | Auto-notify when long commands complete | v2.0 |

## What's New in v2.0

- **Frontmatter completo** con `license`, `compatibility`, `metadata` con versión, triggers + negative triggers en descriptions
- **Progressive disclosure**: skills <500 líneas, contenido offload a `references/` (ej. auth-architect/references/)
- **Workflows procedimentales**: paso-a-paso numerado con if/then decision trees
- **Actualización técnica 2026**: Flutter Impeller, Terraform Stacks, Kubernetes Gateway API, Container Queries, INP, DSA/DMA, etc.
- **Anti-patrones expandidos** con tablas de fix/causa
- **Checklists de producción** en todas las skills

## Quality

| Metric | Detail |
|--------|--------|
| Coverage | 29 skills across 11 domains |
| Avg depth | ~200 lines per skill |
| Structure | YAML frontmatter + markdown body + optional references/ |
| Sources | Cite real references (OWASP, Google SRE, PostgreSQL docs, MDN, NIST) |

## License

MIT
