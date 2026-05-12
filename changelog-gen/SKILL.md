---
name: changelog-gen
description: Generate changelogs from conventional commits
---


# Changelog Gen

Generates changelogs that communicate what changed, why, and how to migrate. Based on Keep a Changelog, Conventional Commits, and semantic versioning.

## Structure

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
- Feature to be removed in future version (#PR)

### Removed
- Feature that was previously deprecated (#PR)

### Security
- Vulnerability fix description (#PR)
```

## Commit to Changelog Mapping

| Commit type | Changelog section | Version bump |
|-------------|------------------|--------------|
| feat | Added | minor |
| fix | Fixed | patch |
| breaking feat | Added (with BREAKING label) | major |
| perf | Changed | patch |
| refactor | Changed | patch |
| docs | (omit unless significant) | â€” |
| test | (omit) | â€” |
| chore | (omit) | â€” |

## Writing Rules

- Write for humans, not machines. "Added new API endpoint" not "Adds new API endpoint"
- Include PR number linking to the PR
- Include migration instructions for breaking changes
- Group related entries under one item
- Credit contributors by GitHub handle for significant changes

## Breaking Change Format

```
### Changed

- **BREAKING**: `createUser()` now requires an `email` parameter. The previous `username` parameter is deprecated and will be removed in v3.
  Migration: replace `createUser({ username })` with `createUser({ email })`. Use username as email if migration path exists.
  ([#142](https://github.com/user/repo/pull/142))
```

## Versioning Rules

| Change | Version type | Example |
|--------|-------------|---------|
| Breaking API change | Major | 2.0.0 -> 3.0.0 |
| New feature, no breaking | Minor | 2.0.0 -> 2.1.0 |
| Bug fix only | Patch | 2.0.0 -> 2.0.1 |

## Generation Command

```bash
git log --oneline --no-merges $(git describe --tags --abbrev=0)..HEAD
# Then group by conventional commit type
```

## Template Variables

| Variable | Description | Example |
|----------|-------------|---------|
| $VERSION | New version number | 1.2.3 |
| $DATE | Release date | 2026-05-12 |
| $PREVIOUS | Previous version | 1.2.2 |
| $CHANGES | Categorized commits | See below |

## Sources
- Keep a Changelog
- Conventional Commits
- Semantic Versioning







