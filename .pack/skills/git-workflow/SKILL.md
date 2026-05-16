---
name: git-workflow
description: Automate the complete Git development workflow — create feature branches with conventional naming, atomic commits with conventional commit messages, interactive rebase, squash merges, PR body generation from commit history, branch cleanup, and git worktree patterns. Use when user asks to create a branch, commit changes, make a PR, rebase, squash, clean up branches, or follow a Git workflow. Do NOT use for CI/CD pipeline configuration (use ci-cd), code review (use code-review), or GitHub Actions workflows.
license: MIT
compatibility: opencode
metadata:
  workflow: development
  audience: developers
  version: "3.0"
  author: shokunin
allowed-tools: Read Bash Write Grep
---

# Git Workflow

Automate the development cycle: branch, commit, PR, review, merge, cleanup. Follows conventional commits and trunk-based development.

## Workflow

### Step 1: Create a feature branch

```powershell
scripts/create-feature-branch.ps1 -Name "add-user-auth" -Type feat
```

This:
1. Detects default branch (main/master)
2. Fetches and pulls latest
3. Creates `feat/add-user-auth` from base
4. Pushes upstream with tracking

**Branch naming:**
| Type | Prefix | Example |
|------|--------|---------|
| Feature | `feat/` | `feat/add-user-auth` |
| Fix | `fix/` | `fix/login-redirect` |
| Docs | `docs/` | `docs/api-readme` |
| Refactor | `refactor/` | `refactor/auth-middleware` |
| Chore | `chore/` | `chore/update-deps` |

### Step 2: Make atomic commits

```powershell
scripts/auto-commit.ps1 -Scope "auth" -DryRun  # Preview first
scripts/auto-commit.ps1 -Scope "auth"           # Commit
```

The script analyses changed files, generates a conventional commit message, and stages+commits.

**Conventional commit format:**
```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

**Rules:**
- One logical change per commit
- Description: imperative mood, lowercase, max 72 chars
- Scope: the module/area affected
- Footer: `BREAKING CHANGE:`, `Closes #123`, `Co-authored-by:`

### Step 3: Prepare for PR

```powershell
# Interactive rebase (squash WIP commits)
git rebase -i main

# Generate PR body from commit history
scripts/pr-body.ps1 -Clipboard
```

The PR body script:
1. Detects base branch
2. Extracts commits since fork
3. Groups by conventional commit type
4. Generates ## Summary, ## Changes, ## Testing sections
5. Copies to clipboard

**Squash rules:**
- Squash `fixup!` and `wip` commits
- Keep meaningful commit history
- Never squash if commits have different scopes
- Use `git rebase -i main` with `fixup` (f) for WIP commits

### Step 4: Create PR

```powershell
# Create PR with generated body
gh pr create --title "feat(auth): add user authentication" --body "$(Get-Clipboard)"

# Or use the file
gh pr create --title "feat(auth): add user authentication" --body-file .pr-body.md
```

**PR guidelines:**
| Aspect | Rule |
|--------|------|
| Size | Max 400 lines changed |
| Title | Same as conventional commit |
| Description | What + Why + How to test |
| Reviewers | 1-2 relevant team members |
| Labels | Type (feat/fix/docs) + priority |
| Draft | Use for Work-in-Progress |

### Step 5: Clean up after merge

```powershell
scripts/cleanup-branches.ps1
```

This lists merged branches (excluding protected ones), asks for confirmation, deletes locally and remotely, and prunes remote tracking refs.

## Workflow by strategy

See [references/git-workflows.md](references/git-workflows.md) for full reference.

| Strategy | Best for | Branch model |
|----------|----------|--------------|
| Trunk-based | CI/CD, deploys multiple times/day | Short-lived feature branches → main |
| GitHub Flow | Standard SaaS | feature → main (PR + merge) |
| GitFlow | Release management, multiple versions | feature → develop → release → main |

**Default recommendation**: GitHub Flow for simplicity. Trunk-based if CI/CD is mature.

## Error Handling

| Scenario | Cause | Fix |
|----------|-------|-----|
| Rebase conflicts | Multiple people changed same lines | Resolve conflicts, `git rebase --continue` |
| Can't push (non-fast-forward) | Branch behind base | Rebase on base first |
| Accidental commit on wrong branch | Careless checkout | Cherry-pick to correct branch, reset original |
| Detached HEAD | Accidentally checked out a commit | `git switch -c <new-branch>` |
| Lost commits after reset | `git reset --hard` | `git reflog` → find SHA → `git cherry-pick` |

## Branch Protection Rules

| Rule | GitHub setting | Why |
|------|---------------|-----|
| Require PR before merge | `required_pull_request_reviews` | Prevents direct pushes |
| Require status checks | `required_status_checks` | CI must pass |
| Require linear history | `required_linear_history` | No merge commits |
| Require signed commits | `required_signatures` | Verify authorship |
| Dismiss stale reviews | `dismiss_stale_reviews` | New pushes need re-review |

## Production Checklist

- [ ] Branch named with conventional prefix
- [ ] Commit message follows conventional commits
- [ ] One logical change per commit
- [ ] PR description explains what + why + how to test
- [ ] PR under 400 lines changed
- [ ] CI passes (lint, typecheck, tests)
- [ ] At least 1 reviewer approved
- [ ] Branch deleted after merge
- [ ] No WIP commits in history

## Anti-Patterns

| Anti-pattern | Fix |
|-------------|-----|
| `git commit -m "fix bug"` | Conventional commit with context |
| 1000+ line PRs | Break into smaller, atomic changes |
| Merging main into feature branch | Rebase instead (cleaner history) |
| Committing directly to main | Branch + PR + review always |
| No CI before merge | Block merging without passing checks |
| Pushing to main without PR | Use branch protection rules |
| Stale branches (older than 2 weeks) | Clean up regularly |

## Sources

- Conventional Commits (conventionalcommits.org)
- GitHub Flow (docs.github.com)
- Trunk-Based Development (trunkbaseddevelopment.com)
- Git SCM docs (git-scm.com)
- Keep a Changelog (keepachangelog.com)
- Semantic Versioning (semver.org)
