# Shokunin · 職人

**62 agent skills for developers, designers, writers, and operators.** *(Merged from 62 — consolidated related skills into combined power skills.)*

Portable skill files compatible with OpenCode, Claude Code, Cursor, and any agent that supports `SKILL.md` format with YAML frontmatter.

> 職人 (shokunin) means *artisan* in Japanese — someone who takes pride in every detail. These skills aim for that standard.

---

## Quick Start

```bash
# Clone the repository
git clone git@github.com:EliasOulkadi/shokunin.git

# Skills auto-discover in OpenCode when placed in:
#   ~/.config/opencode/skills/
#   .claude/skills/
#   .cursor/skills/

# Or symlink a single category:
ln -s $(pwd)/shokunin/backend ~/.config/opencode/skills/
```

**OpenCode** detects skills automatically. For other agents, reference a skill inline:

```markdown
> Use the `auth-architect` skill — implement JWT with refresh token rotation,
> httpOnly cookies, and rate limiting per OWASP guidelines.
```

---

## Domains

| Domain | Skills | Count |
|--------|--------|-------|
| **Backend** | api-forge, auth-architect, db-sculptor, error-handler, test-commander | 5 |
| **DevOps & Infra** | ci-cd, docker, kubernetes, terraform | 4 |
| **Frontend** | component-forge, landing-craft, motion-craft, responsive-engine | 4 |
| **Mobile** | flutter, react-native | 2 |
| **Content Marketing** | content-marketing | 1 |
| **Business Proposals** | business-proposals | 1 |
| **Communication** | communication, translate-craft | 2 |
| **Documentation** | documentation | 1 |
| **Design** | design, ui-ux-pro-max | 2 |
| **Strategy** | strategy, finance, legal-counsel | 3 |
| **Automation** | portfolio-auto, whendone-plus | 2 |
| **.agents (custom)** | aesthetic-web, agent-browser, agent-tools, code-review, comprehensive-review, cross-review, efficient-coding, find-skills, humanize, init, kagen, kami, plan, play-wright, research, senior-engineer, skill-creator, web-security, zen-comprehensive-review, zen-review | 20 |

**Total: 30 skills across 7 domains (Shokunin) + 20 custom skills (.agents)**

---

## Skill Index

### Backend
| Skill | What it does |
|-------|-------------|
| [api-forge](api-forge/) | Design REST/GraphQL APIs with OpenAPI, error handling, pagination, rate limiting |
| [auth-architect](auth-architect/) | Auth systems with OWASP standards: JWT, OAuth, WebAuthn, session management |
| [db-sculptor](db-sculptor/) | Database schemas with Prisma/Drizzle, indexing strategy, migration safety |
| [error-handler](error-handler/) | Error classification, structured logging, recovery patterns (retry, circuit breaker) |
| [test-commander](test-commander/) | Unit, integration, e2e, and visual tests with Testing Trophy methodology |

### DevOps & Infrastructure
| Skill | What it does |
|-------|-------------|
| [ci-cd](ci-cd/) | CI/CD pipelines for GitHub Actions and GitLab CI with caching, sharding, deployments |
| [docker](docker/) | Multi-stage builds, distroless bases, BuildKit cache, docker-compose, security |
| [kubernetes](kubernetes/) | Deployments, Services, Ingress, NetworkPolicies, Helm, HPA, debugging |
| [terraform](terraform/) | IaC with remote state, modules, moved blocks, CI/CD plan/apply separation |

### Frontend
| Skill | What it does |
|-------|-------------|
| [component-forge](component-forge/) | React/Vue components with all states, a11y, TypeScript strict, tests |
| [landing-craft](landing-craft/) | Conversion-optimized landing pages with scroll effects, A/B testing patterns |
| [motion-craft](motion-craft/) | GPU-accelerated animations, easing system, scroll effects, prefers-reduced-motion |
| [responsive-engine](responsive-engine/) | Fluid typography with clamp(), breakpoint system, touch targets, testing |

### Mobile
| Skill | What it does |
|-------|-------------|
| [flutter](flutter/) | Clean Architecture + Riverpod + GoRouter, platform channels, theming, deployment |
| [react-native](react-native/) | Expo Router / React Navigation, Zustand, Hermes optimization, deep linking |

### Content Marketing
| Skill | What it does |
|-------|-------------|
| [content-marketing](content-marketing/) | Blogs, newsletters, Twitter threads, case studies, copywriting, marketing psychology, and conversion drivers — all in one skill |

### Business Proposals
| Skill | What it does |
|-------|-------------|
| [business-proposals](business-proposals/) | Sales outreach, proposals/SOWs, pricing tiers, and investor pitch decks |

### Communication
| Skill | What it does |
|-------|-------------|
| [communication](communication/) | Corporate email, feedback (SBI), difficult conversations, meeting notes |
| [translate-craft](translate-craft/) | Professional translation with cultural adaptation for 5 languages |

### Documentation
| Skill | What it does |
|-------|-------------|
| [documentation](documentation/) | READMEs, API docs, changelogs, knowledge base articles |

### Design
| Skill | What it does |
|-------|-------------|
| [design](design/) | Brand guidelines, creative direction, design briefs |
| [ui-ux-pro-max](ui-ux-pro-max/) | Searchable database of UI patterns, color palettes, font pairings, UX guidelines |

### Strategy & Productivity
| Skill | What it does |
|-------|-------------|
| [strategy](strategy/) | Brainstorming techniques + prompt engineering (7-dimension framework) |
| [finance](finance/) | Personal finance: budgeting, debt payoff, investing, tax optimization, insurance |
| [legal-counsel](legal-counsel/) | GDPR, AI Act, CCPA, HIPAA, DMCA, contract review framework |

### Automation
| Skill | What it does |
|-------|-------------|
| [portfolio-auto](portfolio-auto/) | Auto-sync GitHub repos to portfolio with Playwright screenshots |
| [whendone-plus](whendone-plus/) | Desktop notifications when long-running commands finish |

---

## Quality

| Metric | Detail |
|--------|--------|
| Coverage | 30 skills across 7 domains |
| Depth | 100-300+ lines per skill, average ~180 lines |
| Structure | YAML frontmatter + markdown body |
| Content | Frameworks, tables, checklists, code snippets, anti-patterns, sources |
| Sources | Each skill cites real references (OWASP, Stripe, Google SRE, NIST, MDN, industry research) |
| Format | Portable across OpenCode, Claude Code, Cursor, Codex, Cline |

---

## Usage

### With OpenCode

Place the repository in your skills directory:

```bash
cp -r skills/* ~/.config/opencode/skills/
# or symlink:
ln -s $(pwd)/skills ~/.config/opencode/skills/shokunin
```

OpenCode auto-discovers skills by their `SKILL.md` file and `name` frontmatter. Skills activate when the task matches their `description` and `triggers` fields.

### With other agents

Reference a skill by its path or paste its content inline. Example for Claude Code:

```markdown
You have the `auth-architect` skill loaded. Implement secure authentication following OWASP guidelines.
```

### Per-project setup

Drop a skill into your project's `.claude/skills/` or `.cursor/skills/` directory to make it available only for that project.

---

## Development

### Adding a skill

```markdown
---
name: my-skill
description: What this skill does in one sentence
---

Practical content organized with:

## Section
- Tables for structured data
- Code snippets for implementation
- Checklists for completeness
- Anti-patterns for common mistakes
## Sources
- Real references, not generic URLs
```

### Directory structure

```
shokunin/
├── api-forge/          # Design REST/GraphQL APIs
├── auth-architect/     # OWASP-compliant authentication
├── business-proposals/ # Sales outreach + proposals + pitch decks
├── communication/      # Email + feedback + meetings + difficult convos
├── component-forge/    # React/Vue components
├── content-marketing/  # Blogs + newsletters + Twitter + case studies
├── design/             # Brand guidelines + creative direction + briefs
├── documentation/      # READMEs + API docs + changelogs + KB
├── strategy/           # Brainstorming + prompt engineering
├── ...                 # (flat structure, 30 skill directories)
├── README.md
└── LICENSE
```

---

## License

MIT

---

*30 skills, 7 domains, zero fluff.*
