---
name: git-workflow
description: Automate the complete Git development workflow — create feature branches with conventional naming, atomic commits with conventional commit messages, interactive rebase, squash merges, PR body generation from commit history, branch cleanup, and git worktree patterns. Use when user asks to create a branch, commit changes, make a PR, rebase, squash, clean up branches, or follow a Git workflow. Do NOT use for CI/CD pipeline configuration (use ci-cd), code review (use code-review), or GitHub Actions workflows.
triggers:
  - "git branch"
  - "create branch"
  - "commit"
  - "git commit"
  - "git push"
  - "git rebase"
  - "squash commits"
  - "git workflow"
  - "make a PR"
  - "pull request"
  - "git merge"
  - "git cleanup"
  - "branch management"
  - "conventional commit"
negatives:
  - "CI/CD pipeline"
  - "GitHub Actions"
  - "code review"
  - "GitHub workflow"
  - "GitLab CI"
license: MIT
compatibility: opencode
metadata:
  workflow: development
  audience: developers
  version: "3.0.0"
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

| Strategy | Best for | Branch model | Pros | Cons | Guidance |
|----------|----------|--------------|------|------|----------|
| **Trunk-based** | CI/CD, deploys multiple times/day, feature flags | Short-lived feature branches → main (hours, not days) | Fast integration, no merge hell, simple CI | Requires feature flags + high test coverage | Keep branches under 24h. Use branch by abstraction for large changes. |
| **GitHub Flow** | Standard SaaS, team of 2-10 | feature → main (PR + squash merge) | Simple, review-friendly, clean history | Can't manage multiple releases | Use for most projects. Squash-merge keeps main linear. Tag releases from main. |
| **GitFlow** | Release management, multiple supported versions, regulated industries | feature → develop → release → main + hotfix branches | Full version tracking, parallel releases | High complexity, slow to release | Only use if you support 2+ release versions simultaneously. Overkill for single-version SaaS. |
| **GitLab Flow** | Environment-based deployments, staging → production gating | feature → main → staging → production (branch per env) | Environment isolation, easy rollback | Duplicate merge overhead per env | Use when environments need different merge cadences. Pair with CI/CD environment protection. |

**Default recommendation**: GitHub Flow for simplicity. Trunk-based if CI/CD is mature and deploying multiple times/day.

## Error Handling

| Scenario | Cause | Fix |
|----------|-------|-----|
| Rebase conflicts | Multiple people changed same lines | Resolve conflicts, `git rebase --continue`. See conflict resolution workflow below. |
| Can't push (non-fast-forward) | Branch behind base | Rebase on base first |
| Accidental commit on wrong branch | Careless checkout | Cherry-pick to correct branch, reset original |
| Detached HEAD | Accidentally checked out a commit | `git switch -c <new-branch>` |
| Lost commits after reset | `git reset --hard` | `git reflog` → find SHA → `git cherry-pick` |

## Rebase conflict resolution

```
# During rebase, conflict arises
git status                          # See conflicted files
# Edit conflicted files → resolve markers (<<<<<<, ======, >>>>>>)
git add <resolved-files>
git rebase --continue               # Move to next commit

# If the rebase is going poorly and you want to bail:
git rebase --abort                  # Return to pre-rebase state

# If you're mid-rebase, unsure, and want to compare:
git diff                            # Show conflict diff
git mergetool                       # Launch configured merge tool (VS Code: code --wait $MERGED)

# Skip a problematic commit entirely:
git rebase --skip

# After rebase, verify history:
git log --oneline --graph -20
```

**Conflict avoidance:**
- Keep branches short-lived (< 3 days). Longer branches accumulate merge debt.
- Pull/rebase daily from main during long features: `git fetch origin && git rebase origin/main`
- Break large features into stacked PRs (PR 1 → PR 2 → PR 3) instead of one 1000-line PR
- Communicate: if you're refactoring a shared module, tell the team

## Parallel work with git worktree

Use `git worktree` to work on multiple branches simultaneously without stashing or cloning:

```powershell
# Create a new worktree for a feature
git worktree add ../project-feat-auth feat/add-user-auth

# List all worktrees
git worktree list

# Remove a worktree after branch is merged
git worktree remove ../project-feat-auth
# Then delete the branch normally
```

**When to use:**
- Hotfix needs to go out while you're mid-feature on another branch
- Running CI/lint/tests in one worktree while coding in another
- Reviewing a PR branch without switching away from your current work
- Exploring an old commit without detaching HEAD

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

## Checklist

- [ ] Skill loads without errors in the AI agent
- [ ] YAML frontmatter is valid (description, compatibility, audience)
- [ ] Workflow section provides clear step-by-step instructions
- [ ] Error handling section covers common failure modes
- [ ] All referenced files (references/, scripts/, assets/) exist
- [ ] Skill triggers correctly for intended use cases
- [ ] No broken links or missing resources
