---
name: documentation
description: >
  Generate READMEs, API docs, changelogs, and knowledge base articles. Covers
  README structure with personality, OpenAPI-based API documentation, changelogs
  from conventional commits, typedoc patterns, and support KB articles.
triggers:
  - "write documentation"
  - "write README"
  - "API documentation"
  - "API docs"
  - "changelog"
  - "release notes"
  - "knowledge base"
  - "setup guide"
  - "getting started"
  - "project docs"
negatives:
  - "API design"
  - "code comments"
  - "blog post"
  - "technical writing prose"
license: MIT
compatibility: opencode
metadata:
  version: "4.0.0"
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

## Workflow

1. **Identify document type** — README, API docs, changelog, or knowledge base article. Each has a distinct structure and rule set.
2. **Gather source material** — for README: project files, package.json, build system. For API: OpenAPI spec or route handlers. For changelog: git log. For KB: product expertise.
3. **Apply the template** — README: hook → features → quick start → API → examples → config → contributing → license. API: method → path → description → auth → request → response → errors.
4. **Fill every section with real data** — no "TODO", "coming soon", "TBD", placeholder text. Quick start must be copy-paste runnable. API docs need curl + SDK examples.
5. **Verify everything** — test quick start from clean environment. Check every link resolves. Confirm license badge matches LICENSE file. KB: test steps as an unfamiliar user.
6. **Cut the generic** — remove default template comments. Strip "write unit tests" style advice. Every sentence must convey a specific convention or fact about this project.

## Error Handling

| Cause | Fix |
|-------|-----|
| Quick start commands fail from a clean environment | Test every command from scratch. Ensure no omitted imports, no assumed global state, no missing env vars. |
| API docs missing error response codes | Document all possible status codes for every endpoint: 400 (validation), 401 (auth), 403 (forbidden), 404 (not found), 500 (server error). |
| Changelog entry lacks migration notes for breaking changes | Every breaking change must include: what changed, why, and the exact migration path. Link to the PR. |
| KB article steps don't produce expected result when followed | Have someone unfamiliar with the product walk through the steps. Fix any ambiguity or missing context. |
| Links in documentation resolve to 404 or redirect | Check every link. Prefer permalinks. Verify external links haven't moved. Use web archive as fallback for critical references. |
| README badges show incorrect or outdated status | Verify CI badge matches current pipeline. Version badge matches latest release. Coverage badge matches current report. |
| API docs example response doesn't match actual API output | Generate response examples from actual API output, not from spec definitions. Update when the API changes. |
| Default README template published with unfilled sections | Remove all template comments and TODO markers before publishing. If a section has no content, omit it rather than leaving a placeholder. |

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

## API Documentation Patterns

### OpenAPI → Docs
```bash
npx @redocly/cli build-docs openapi.yaml -o docs.html
npx @scalar/api-reference openapi.yaml
```

### README Template
1. Title + one-liner, 2. Quick start (install + first command), 3. Features (bullets), 4. Architecture (diagram), 5. API (link), 6. Contributing (link), 7. License

## Changelog Automation

```bash
# Generate from conventional commits
npx standard-version
npx changelogen --from v1.0.0 --to HEAD

# Keep a Changelog format
## [version] - YYYY-MM-DD
### Added | Changed | Deprecated | Removed | Fixed | Security
```

## Sources

- Standard Readme specification
- Stripe API documentation standards
- Keep a Changelog (keepachangelog.com)
- Conventional Commits (conventionalcommits.org)
- OpenAPI Specification (openapis.org)
- Zendesk / Intercom — KB standards

## Checklist

- [ ] Skill loads without errors in the AI agent
- [ ] YAML frontmatter is valid (description, compatibility, audience)
- [ ] Workflow section provides clear step-by-step instructions
- [ ] Error handling section covers common failure modes
- [ ] All referenced files (references/, scripts/, assets/) exist
- [ ] Skill triggers correctly for intended use cases
- [ ] No broken links or missing resources
