# Shokunin · 職人

**45 agent skills for developers, designers, writers, and operators.**

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
| **Content** | blog-craft, case-study, copywriting, newsletter-gen, twitter-thread | 5 |
| **Sales** | pitch-deck, proposal-gen, sales-outreach | 3 |
| **Communication** | difficult-convo, feedback-craft, meeting-notes, professional-email, translate-craft | 5 |
| **Documentation** | api-docs, changelog-gen, kb-writer, readme-artisan, readme-forge | 5 |
| **Design & Brand** | brand-guidelines, creative-director, design-brief, marketing-psychology, ui-ux-pro-max | 5 |
| **Strategy** | brainstorming, enhance-prompt, finance, legal-counsel | 4 |
| **Automation** | portfolio-auto, whendone-plus | 2 |

**Total: 45 skills across 11 domains**

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

### Content
| Skill | What it does |
|-------|-------------|
| [blog-craft](blog-craft/) | Technical blog posts with code examples, SEO, headline formulas |
| [case-study](case-study/) | B2B case studies with problem/approach/results framework |
| [copywriting](copywriting/) | Marketing copy with frameworks (AIDA, PAS, BAB), headline formulas, email patterns |
| [newsletter-gen](newsletter-gen/) | Email newsletters with subject line architecture, deliverability, engagement benchmarks |
| [twitter-thread](twitter-thread/) | Viral thread structure, hook patterns, algorithm mechanics, engagement strategy |

### Sales
| Skill | What it does |
|-------|-------------|
| [pitch-deck](pitch-deck/) | Investor deck structure (10 slides), story arc, traction benchmarks |
| [proposal-gen](proposal-gen/) | Consulting/agency proposals with scope, pricing tiers, risk reduction |
| [sales-outreach](sales-outreach/) | Cold/warm outreach sequences, personalization, follow-up cadence |

### Communication
| Skill | What it does |
|-------|-------------|
| [difficult-convo](difficult-convo/) | Escalations, complaints, negotiations with SBI framework |
| [feedback-craft](feedback-craft/) | Constructive feedback with SBI + BID model, code review patterns |
| [meeting-notes](meeting-notes/) | Structured notes: decisions, action items, risks from raw transcripts |
| [professional-email](professional-email/) | Corporate email with tone matrix, templates, subject line rules |
| [translate-craft](translate-craft/) | Professional translation with cultural adaptation for 5 languages |

### Documentation
| Skill | What it does |
|-------|-------------|
| [api-docs](api-docs/) | API documentation from specs with endpoint structure, code generation |
| [changelog-gen](changelog-gen/) | Changelogs from conventional commits with migration notes |
| [kb-writer](kb-writer/) | Knowledge base articles: troubleshooting, how-to, reference formats |
| [readme-artisan](readme-artisan/) | READMEs with personality, hook, demo, tone by project type |
| [readme-forge](readme-forge/) | Functional READMEs with install, API reference, examples sections |

### Design & Brand
| Skill | What it does |
|-------|-------------|
| [brand-guidelines](brand-guidelines/) | Visual identity systems: logos, color, typography, voice, application rules |
| [creative-director](creative-director/) | Creative direction with SCAMPER, Design Thinking, TRIZ, campaign architecture |
| [design-brief](design-brief/) | Design briefs with problem statement, objectives, scope, success criteria |
| [marketing-psychology](marketing-psychology/) | Persuasion principles, cognitive biases, conversion drivers, visual psychology |
| [ui-ux-pro-max](ui-ux-pro-max/) | Searchable database of UI patterns, color palettes, font pairings, UX guidelines |

### Strategy & Productivity
| Skill | What it does |
|-------|-------------|
| [brainstorming](brainstorming/) | Structured ideation: divergent/convergent techniques, facilitation rules |
| [enhance-prompt](enhance-prompt/) | Prompt engineering: clarity, specificity, constraints, format, tone |
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
| Coverage | 45 skills across 12 domains |
| Depth | 82-276 lines per skill, average ~140 lines |
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
├── component-forge/    # React/Vue components
├── copywriting/        # Marketing copy & conversion
├── ...                 # (flat structure, 45 skill directories)
├── README.md
└── LICENSE
```

---

## License

MIT

---

*45 skills, 12 domains, zero fluff.*
