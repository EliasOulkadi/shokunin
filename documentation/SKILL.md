---
name: documentation
description: Generate READMEs, API docs, changelogs, and knowledge base articles. Covers README structure with personality, OpenAPI-based API documentation, changelogs from conventional commits, typedoc patterns, and support KB articles. Use when user asks to write a README, API documentation, changelog, release notes, knowledge base article, troubleshooting guide, or improve project documentation. Do NOT use for API design (use api-forge) or code comments.
license: MIT
compatibility: opencode
metadata:
  workflow: documentation
  audience: developers
  version: "2.0"
---

# Documentation

Write docs that developers actually read. Covers the four most common types: READMEs, API references, changelogs, and knowledge bases.

## README

### The Hook
First paragraph answers three questions: what is this (5 words), who is this for, why does this exist.

Bad: "A React component library for building modern user interfaces."
Good: "Buttons, modals, forms, done right. No design debt. Zero dependencies."

### Structure
```
# Project [Badges]

One-line description

## Features (3-6 quantified benefits)
## Quick Start — copy-paste runnable
## API Reference — every export in table format
## Examples — 2-3 real-world scenarios
## Configuration — env vars, config file, CLI flags
## Contributing — dev setup, commands
## License — SPDX identifier
```

### Quick Start Rules
Copy-paste runnable. No omitted imports. No placeholders. Include expected output.

### API Reference Format
| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `input` | `string` | Yes | — | Description |
| `options` | `FormatOptions` | No | `{}` | Config object |

Return type on separate line. One complete example per export.

### Badge Requirements
| Badge | Required? |
|-------|-----------|
| CI (build status) | Yes |
| Package version | Yes |
| License | Yes |
| Coverage | Recommended |

## API Documentation (from OpenAPI spec)

### Structure per Endpoint
```
### [HTTP Method] [Path]

**Description**: one sentence
**Auth required**: Yes/No [type]

**Request**
  Headers: [required headers]
  Parameters: [path/query/body]

**Response 200**
  Body: [shape with example]

**Error responses**
  400: [description]
  401: [description]
  404: [description]
```

### Rules
- One section per endpoint. Group related under the same H2.
- Every parameter gets: name, type, required, description, example.
- Every response includes a complete JSON example.
- Error responses: list every status code the endpoint can return.
- Auth: specify type (Bearer, API key, Basic, OAuth scope).
- Rate limits: document headers.

### Include for each endpoint
- [ ] Request example (curl, fetch, Python, or SDK)
- [ ] Response example with all fields
- [ ] Error responses for all possible status codes
- [ ] Pagination docs (if applicable)
- [ ] Rate limit headers

## Changelogs

### Structure
```
# Changelog

## [2.1.0] - 2026-05-12

### Added
- New feature description (#PR)

### Changed
- Behavior change with migration note (#PR)

### Fixed
- Bug fix description (#PR)

### Deprecated
- Feature to be removed (#PR)

### Removed
- Feature removed (#PR)

### Security
- Vulnerability fix (#PR)
```

### Rules
- Keep a Changelog format. One section per version.
- Each entry links to PR or commit.
- Migration notes for breaking changes.
- Unreleased section at top.
- Semantic versioning.
- Explain WHY a change was made, not just WHAT.

## Knowledge Base

### Article Format
```
Title: as a question or problem user would search for
Context: 1-2 sentences — who is this for, what product/feature
Steps: numbered, one action per step
Expected result: what happens after last step
Escalation: what to do if it still doesn't work
```

### Writing Rules
- One action per step. Start with action verb (Click, Navigate, Enter).
- Bold UI labels exactly as they appear.
- Max 15 words per step.
- No jargon when plain language works.
- Include expected result after each step.

### Troubleshooting Flow
```
Problem: symptom as user would describe it
Step 1: Quick fix (under 10s) — refresh, retry, restart
Step 2: Check common causes — list top 3
Step 3: Specific fix — detailed steps for most likely cause
Step 4: Escalation — "Contact support with: [what to include]"
```

## Anti-Patterns

| Mistake | Fix |
|---------|-----|
| Default README | Remove all template comments, fill every section |
| "Coming soon" features | Remove them. Ship or hide. |
| Install instructions that don't work | Test from scratch in clean environment |
| API docs with no examples | Every function needs a runnable example |
| Changelog without migration notes | Breaking changes need a migration path |
| KB with no expected result | User doesn't know if it worked |
| No TOC (README > 200 lines) | TOC with anchor links |

## Sources

- Standard Readme specification
- Awesome README — curated examples
- GitHub docs "About READMEs"
- Stripe API documentation standards
- Twilio API docs
- Keep a Changelog
- Conventional Commits
- Semantic Versioning
- Zendesk, Intercom — KB standards
