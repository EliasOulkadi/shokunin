---
name: documentation
description: >
  Generate READMEs, API docs, changelogs, and knowledge base articles. Covers
  README structure with personality, OpenAPI-based API documentation, changelogs
  from conventional commits, typedoc patterns, and support KB articles.
  Triggers: "write a README", "API docs", "API documentation", "changelog",
  "release notes", "knowledge base", "KB article", "documentation", "project docs",
  "setup guide". Negatives: do NOT use for API design (use api-forge) or code
  comments.
license: MIT
compatibility: opencode
metadata:
  version: "4.0"
  workflow: documentation
  audience: developers
allowed-tools: [read, write, edit, glob, grep, bash, webfetch]
---

# Documentation

Write docs that developers actually read. Based on Stripe API docs, Standard Readme, Keep a Changelog, and OpenAPI.

## Sub-Commands

| Command | Description |
|---------|-------------|
| `readme` | Generate a README from project files |
| `api` | Generate API docs from OpenAPI spec or route handlers |
| `changelog` | Generate changelog from conventional commits |
| `kb` | Write a knowledge base article |

## README Structure

```
# Project Name [Badges]

> One-line description

## Features (3-6 quantified benefits)
## Quick Start — copy-paste runnable (no placeholders, no omitted imports)
## API Reference — every export in table format
## Examples — 2-3 real-world scenarios
## Configuration — env vars, config file, CLI flags
## Contributing — dev setup commands
## License — SPDX identifier
```

### The Hook (first paragraph)

Answers: what (5 words), who, why.

Bad: "A React component library for building modern user interfaces."
Good: "Buttons, modals, forms, done right. No design debt. Zero dependencies."

### Quick Start Rules

Copy-paste runnable. No omitted imports. No placeholders. No "coming soon". Include expected output.

### Badge Requirements

| Badge | Required? |
|-------|-----------|
| CI (build status) | Yes |
| Package version | Yes |
| License | Yes |
| Coverage | Recommended |

## API Documentation

### Structure per Endpoint
```
### [METHOD] [Path]
**Description**: one sentence
**Auth required**: Yes/No [type]
**Request**: Headers, Parameters (path/query/body)
**Response 200**: Body with example
**Error responses**: 400, 401, 404, 500 with descriptions
```

### Rules per Endpoint
- [ ] Request example (curl + one SDK)
- [ ] Response example with ALL fields
- [ ] Error responses for ALL possible status codes
- [ ] Pagination docs (if applicable)
- [ ] Rate limit headers documented

## Changelog Format

```
## [2.1.0] - 2026-05-16

### Added
- New feature (#PR)

### Changed
- Behavior change with migration note (#PR)

### Fixed
- Bug fix (#PR)

### Deprecated / Removed / Security
```

Rules: Keep a Changelog format. Every entry links to PR. Migration notes for breaking changes. Unreleased section at top. Semantic versioning. Explain WHY not just WHAT.

## Knowledge Base

### Article Format
```
Title: as a question user would search for
Context: 1-2 sentences — who, what product/feature
Steps: numbered, one action per step, action verb first
Expected result: after last step
Escalation: if it still doesn't work
```

Rules: One action per step. Bold UI labels exactly as they appear. Max 15 words per step. No jargon.

## Production Checklist

- [ ] All examples tested from clean environment
- [ ] No "TODO", "coming soon", "TBD", placeholder text
- [ ] Consistent tone across all sections
- [ ] Every link resolves
- [ ] License badge matches LICENSE file
- [ ] API docs: curl + SDK example per endpoint
- [ ] Changelog: unreleased section present, versions correct
- [ ] KB: tested by someone unfamiliar with the product

## Anti-Patterns

| Anti-Pattern | Correct |
|--------------|---------|
| Default README (template unfilled) | Remove all template comments. Fill every section. |
| "Coming soon" features | Ship or hide. Never show unfinished. |
| Untested install instructions | Test from scratch in clean environment. |
| API docs without examples | Every function needs a runnable example. |
| Changelog without migration notes | Always include migration path for breaking changes. |
| KB with no expected result | End every step with "You should see..." |
| Example code with secrets | Use placeholder env vars. Never real values. |

## Sources

- Standard Readme specification
- Stripe API documentation standards
- Keep a Changelog (keepachangelog.com)
- Conventional Commits (conventionalcommits.org)
- OpenAPI Specification (openapis.org)
- Zendesk / Intercom — KB standards
