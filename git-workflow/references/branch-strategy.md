# Branch Strategy — Reference

## Naming Conventions

### Pattern

```
<type>/<description>
```

- `type` — conventional commit type
- `description` — kebab-case, short, meaningful
- No ticket IDs in branch name (use commit trailers: `Closes PROJ-123`)

### Types

| Pattern | Purpose | Base branch |
|---|---|---|
| `feat/*` | New feature | `main` (trunk) or `develop` (GitFlow) |
| `fix/*` | Bug fix | `main` or `develop` |
| `hotfix/*` | Urgent production fix | `main` |
| `release/*` | Release preparation | `develop` |
| `refactor/*` | Code restructuring | `develop` |
| `docs/*` | Documentation only | `main` |
| `chore/*` | Maintenance, deps, config | `main` |
| `test/*` | Test additions/fixes | `main` |

### Examples

```
feat/add-login-form
fix/auth-timeout-handling
hotfix/critical-security-patch
release/v2.1.0
refactor/api-client
chore/update-dependencies
docs/api-readme
```

### Anti-patterns

```
my-branch                    # no type
feature/super-long-desc-that-goes-on-forever-and-ever  # too long
fix/PROJ-123                 # ticket ID instead of description
feat/                        # empty description
wip/experiment               # use chore or keep local
```

---

## Protection Rules

### Branch protection (GitHub/GitLab)

Apply these rules to `main`, `develop`, and `release/*`:

| Rule | Configuration | Why |
|---|---|---|
| Require PR | On | No direct pushes |
| Required approvals | ≥ 1 | Peer review enforced |
| Dismiss stale reviews | On | New commits reset approvals |
| Require up-to-date branch | On | PR must be rebased on latest base |
| Require status checks | On | CI must pass |
| Require linear history | Recommended | No merge commits on base |
| Include administrators | On | No exceptions |
| Restrict push access | Deployment keys, CI only | Automated deploys need controlled access |
| Lock branch | Off unless frozen | Prevents any changes |

### Status check requirements

Minimum gates before merge:
1. **Lint** — no style/code quality issues
2. **Type check** — TypeScript/Python types valid
3. **Tests** — all tests pass
4. **Build** — application compiles/builds
5. **Security scan** — dependency audit (optional for small projects)

### Optional advanced gates

- Coverage threshold (≥80%)
- No decrease in coverage
- Secret detection scan
- License compliance check
- E2E smoke tests
- Performance regression check

---

## PR Size Guidelines

### Limits

| Metric | Max | Ideal |
|---|---|---|
| Lines changed | 400 | < 200 |
| Files changed | 15 | < 8 |
| Commits | 10 | 1–3 (squashed) |
| Review time target | 30 min | < 15 min |

### Small PRs (≤100 lines)

- Fast to review
- Low risk
- High review quality
- Easy to revert if issues

### Large PRs (>400 lines)

- Review quality drops significantly
- Reviewer burnout
- Higher defect rate post-merge
- Action: **break it up**

### Breaking up large PRs

1. **By layer:** API changes first, then data layer, then UI
2. **By feature slice:** vertical slices instead of horizontal
3. **Preparation refactor:** extract interfaces/helpers first, then add logic
4. **Stacked PRs:** chain dependent PRs against a base feature branch

---

## Review Workflow

### Lifecycle

```
[Create PR as Draft] → [Implement] → [Mark Ready] → [Request Review]
                                                          ↓
                                                  [Reviewer Approves]
                                                          ↓
                                              [Author merges (rebase/squash)]
```

### Author responsibilities

- Self-review before requesting
- Write a clear PR description (use `pr-body.ps1`)
- Keep PR small and focused
- Respond to feedback promptly
- Merge or close stale PRs

### Reviewer responsibilities

- Review within 24 hours (same day preferred)
- Focus on correctness, not style (linter handles style)
- Approve or request changes clearly
- Distinguish blockers from nits
- Be constructive, not critical

### Successful merge conditions

- [ ] Approved by ≥1 reviewer
- [ ] All CI checks pass
- [ ] Branch is up-to-date with base
- [ ] No merge conflicts
- [ ] PR description is meaningful

### Merge strategies per branch

| Branch | Strategy | Rationale |
|---|---|---|
| `main` | Squash merge | Single clean commit per PR |
| `develop` | Merge commit | Preserves feature branch topology |
| `release/*` | Merge commit | Preserves release history |
| `hotfix/*` | Squash or rebase | Minimal, urgent changes |

---

## CI Gate Configuration

### GitHub Actions — PR gate

```yaml
name: PR Gate
on: pull_request

jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: 'pnpm'

      - run: pnpm install --frozen-lockfile
      - run: pnpm lint
      - run: pnpm typecheck
      - run: pnpm test -- --coverage
      - run: pnpm build
```

### GitLab CI — Merge request gate

```yaml
stages:
  - lint
  - test
  - build

lint:
  stage: lint
  script:
    - pnpm lint
    - pnpm typecheck

test:
  stage: test
  script:
    - pnpm test -- --coverage

build:
  stage: build
  script:
    - pnpm build
  artifacts:
    paths:
      - dist/
```

### Required status check names

Configure branch protection to require:

```
lint (lint, typecheck)
test
build
```

### CI timing targets

| Stage | Target | Unacceptable |
|---|---|---|
| Lint | < 30s | > 2 min |
| Type check | < 1 min | > 5 min |
| Unit tests | < 2 min | > 10 min |
| Build | < 2 min | > 10 min |
| **Total** | **< 5 min** | **> 20 min** |

### Optimizing CI

- **Cache node_modules** — saves 60-80% on install
- **Shard tests** — run in parallel
- **Conditional jobs** — skip if only docs/md changed
- **Turbo/Happy** — parallel task runners
- **Skip e2e on small PRs** — only run when UI/API changes

```yaml
# Skip CI for docs-only changes
on:
  pull_request:
    paths-ignore:
      - '*.md'
      - 'docs/**'
```

---

## Rebase Policy

### When to rebase

| Situation | Action |
|---|---|
| Updating your feature branch with base | `git rebase main` |
| Before opening a PR | Interactive rebase to clean up |
| Addressing PR feedback | Fixup commits (will be squashed) |

### When NOT to rebase

| Situation | Alternative |
|---|---|
| Branch has an open PR | Add fixup commits, don't rewrite |
| Branch shared with other devs | Merge base instead |
| Release branch | Only merge, no rebase |

### Policy statement

> All PRs targeting `main` **must** be rebased on latest `main` before merging.
> Use squash merge to keep a linear, clean history on the default branch.
> Fixup commits are preferred over amending pushed commits during review.
