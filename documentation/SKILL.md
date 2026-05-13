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
  version: "3.0"
  workflow: documentation
  audience: developers
allowed-tools:
  - read
  - write
  - edit
  - glob
  - grep
  - bash
  - webfetch
---

# Documentation Skill v3.0

Write docs that developers actually read. Covers the four most common types:
READMEs, API references, changelogs, and knowledge bases.

---

## Workflow

### Step 1 — Identify document type

Ask or infer what the user needs: README, API reference, changelog, or KB
article. Each has a distinct format (see sections below).

### Step 2 — Gather source material

| Type | Source |
|------|--------|
| README | package.json, source files, existing config |
| API docs | OpenAPI spec, route handlers, SDK types |
| Changelog | git log with conventional commits, PR titles |
| KB | Screenshots, UI labels, reproduce steps, error messages |

### Step 3 — Draft structure

Insert the relevant template from the sections below. Fill each block with
content derived from source material.

### Step 4 — Validate

- [ ] Every code example is copy-paste runnable
- [ ] No placeholder text ("TODO", "coming soon", "TBD")
- [ ] All links resolve
- [ ] All version numbers match current release
- [ ] No credentials or secrets in examples

### Step 5 — Present to user

Output the draft and ask for specific feedback: missing sections, incorrect
examples, tone adjustments.

---

## README

### The Hook

First paragraph answers three questions: what is this (5 words), who is this
for, why does this exist.

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

Copy-paste runnable. No omitted imports. No placeholders. Include expected
output.

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

---

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

### Checklist per Endpoint

- [ ] Request example (curl, fetch, Python, or SDK)
- [ ] Response example with all fields
- [ ] Error responses for all possible status codes
- [ ] Pagination docs (if applicable)
- [ ] Rate limit headers

---

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

---

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

---

## Error Handling

| Scenario | Cause | Fix |
|----------|-------|-----|
| README has placeholder text | Template not filled | Replace with real content or remove section |
| API doc missing error responses | Only happy path documented | Add all possible status codes per endpoint |
| Changelog entry has no context | Just copied commit message | Add WHY — user impact, migration notes |
| KB step fails for user | Wrong assumptions about environment | Add prerequisite check at top |
| Code example doesn't compile | Import path out of date | Run example against current version before writing |
| Badge link returns 404 | Repository renamed/moved | Update badge URLs to current repo path |
| No TOC on long README | Overlooked navigation | Add TOC with anchor links for READMEs >200 lines |

---

## Production Checklist

- [ ] All examples tested from a clean environment
- [ ] No template comments, TODOs, or "coming soon"
- [ ] Consistent tone across all sections
- [ ] Every link resolves (use `git grep` for internal refs)
- [ ] License badge matches LICENSE file in repo
- [ ] API docs: every endpoint has curl + one SDK example
- [ ] Changelog: Unreleased section present, version numbers correct
- [ ] KB: tested by someone unfamiliar with the product
- [ ] Mermaid/Ascii diagrams included for complex flows
- [ ] Search-friendly headings (nouns & verbs users would type)

---

## Anti-Patterns

| Anti-Pattern | Problem | Correct Approach |
|--------------|---------|------------------|
| Default README | Looks abandoned | Remove all template comments, fill every section with real content |
| "Coming soon" features | Breaks trust | Remove them. Ship or hide until implemented. |
| Untested install instructions | User hits errors first try | Test from scratch in a clean environment |
| API docs with no examples | Developer can't integrate | Every function needs a runnable example |
| Changelog without migration notes | Breaking changes surprise users | Always include migration path under a "Migration Notes" subheader |
| KB with no expected result | User can't verify success | End every step with "You should see..." |
| Generic screenshots | Hard to distinguish UI state | Annotate with arrows/boxes, or use video/GIF |
| Overly clever code examples | Obscures the API surface | Write examples that demonstrate one thing clearly |
| No error documentation | Users can't debug failures | Document every error code with cause and fix |
| Example code with secrets | Security leak | Use placeholder env vars (`$API_KEY`, `process.env.SECRET`) never real values |

---

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
- OpenAPI Specification
