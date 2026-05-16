# Changelog

## [4.0.0] - 2026-05-16

### Added
- 24 new skills: aesthetic-web, agent-browser, agent-tools, code-review, comprehensive-review, cross-review, efficient-coding, find-skills, humanize, impeccable, init, kagen, kami, neon-postgres, plan, playwright, research, senior-engineer, shokunin-update, skill-creator, web-security, zen-comprehensive-review, zen-review, emil-design-eng, taste, taste-soft, taste-minimalist
- 5 integrated external skills with improvements: emil-design-eng, impeccable, taste, taste-soft, taste-minimalist
- All skills consolidated under `.pack/skills/` (single source of truth, 62 total)
- CI workflow updated to validate `.pack/skills/` instead of root directories

### Changed
- Upgraded 17 skills to v4.0 with Before/After tables, exact specs, pre-flight checklists
- All frontend skills now include Emil Kowalski patterns, Paul Bakaus principles, Leon Lin variance engines
- `prefers-reduced-motion` required on every animation skill
- Install scripts now point to `.pack/skills/` (62 skills)
- README updated: 38 -> 62 skills, 8 -> 10 domains
- Removed 37 outdated skill directories from repo root (moved to `.pack/skills/`)
- Removed orphaned directories: cleanup-surgeon, readme-shokunin

## [3.0.0] - 2026-05-13

### Added
- 5 new skills: seo-geo, git-workflow, db-admin, windows-powershell, performance-profiler
- 27 executable scripts across 11 skills
- 22 reference files for deep content offload
- 14 reusable asset templates
- `allowed-tools` in frontmatter for tool permission control
- Decision trees (if/then/else) in all v3.0 skill workflows
- Error handling tables (scenario → cause → fix) in all v3.0 skills
- Windows PowerShell awareness in db-admin, git-workflow, windows-powershell

### Changed
- Upgraded 11 skills to v3.0 with scripts/refs/assets (ci-cd, component-forge, db-sculptor, docker, error-handler, kubernetes, landing-craft, motion-craft, responsive-engine, terraform, test-commander)
- Upgraded all frontmatter with license, compatibility, metadata, allowed-tools
- Progressive disclosure pattern applied to all v3.0 skills

## [2.0.0] - 2026-05-13

### Added
- 6 new skills: communication, content-marketing, business-proposals, design, documentation, strategy
- YAML frontmatter with license, compatibility, metadata, triggers + negative triggers
- References directory for auth-architect (oauth2-flow.md, webauthn.md)

### Changed
- All 29 skills overhauled with procedural workflows, anti-patterns, checklists
- Technical updates 2026: Flutter Impeller, Terraform Stacks, K8s Gateway API, Container Queries, INP, DSA/DMA

## [1.0.0] - 2026-04-01

### Added
- 20 base skills from community sources
- SKILL.md format with basic frontmatter
- README with full index
