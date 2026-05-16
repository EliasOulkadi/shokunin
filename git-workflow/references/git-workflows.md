# Git Workflows — Reference

## Trunk-Based Development

**Core idea:** short-lived feature branches (hours, not days) branch off `main` and merge back frequently. No long-running branches.

| Practice | Detail |
|---|---|
| Branch lifetime | <1 day ideal, max 2 days |
| Branch size | Small, focused changes |
| Merge strategy | Squash or rebase — linear history |
| CI | Must pass before merge |
| Feature flags | Hide incomplete work instead of branches |

**Why:** eliminates merge hell, enables continuous integration, reduces WIP.

### PowerShell shortcuts

```powershell
# Commit often, push at least once per session
git add -A; git commit -m "wip: incremental progress"
# Before merging, squash fixup commits
git rebase -i HEAD~n
```

---

## GitHub Flow

1. Branch off `main` — `feat/my-thing`
2. Commit changes
3. Open a PR — early, even as draft
4. Review, discuss, iterate
5. Merge to `main` and deploy

**Rules:**
- `main` is always deployable
- PRs are the unit of collaboration
- Reviews required before merge
- Deploy immediately after merge

**When to use:** projects with continuous deployment, small teams, web apps.

---

## GitFlow

Long-lived branches for releases, hotfixes, and development.

```text
main        ──●─────────────●─────────
              \           /  \       /
develop       ──●──●──●──●────●──●──●
                \    /  \       /
feature          ●──●    ●─────●
                            \
hotfix                       ●──────●
```

| Branch | Purpose | Source | Merges to |
|---|---|---|---|
| `main` | Production releases | — | — |
| `develop` | Integration branch | `main` | `main` (via release) |
| `feat/*` | Feature work | `develop` | `develop` |
| `release/*` | Release prep | `develop` | `main` + `develop` |
| `hotfix/*` | Urgent production fix | `main` | `main` + `develop` |

**When to use:** scheduled releases, multiple environments, large teams.

---

## Conventional Commits

```
<type>(<scope>): <description>

[body]

[footer]
```

### Types

| Type | Usage |
|---|---|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation |
| `refactor` | Code change with no feature/bug |
| `test` | Adding or fixing tests |
| `chore` | Maintenance, deps, build |
| `style` | Formatting, linting |
| `perf` | Performance improvement |
| `ci` | CI/CD pipeline changes |
| `revert` | Revert a previous commit |

### Breaking changes

```
feat(api)!: remove deprecated v1 endpoints

BREAKING CHANGE: /api/v1/* endpoints removed.
```

### Scope examples

Scopes should be meaningful and consistent:
`feat(auth)`, `fix(api)`, `refactor(db)`, `chore(deps)`

---

## Rebase vs Merge

| Strategy | History | When |
|---|---|---|
| **Merge commit** | Non-linear, preserves topology | Public/shared branches, PR merges |
| **Squash merge** | Single commit per PR | Simple features, PRs |
| **Rebase** | Linear, clean | Local feature branches before PR |
| **Rebase + merge** | Linear, keeps authorship | PR merges with clean history |

### When to rebase

```powershell
# Before opening a PR — clean up your branch
git rebase -i main
# When base branch has moved
git rebase main  # instead of merge
```

### Never rebase
- Public branches others depend on
- Commits that have been pushed and shared
- PRs that are under review (unless team agrees)

### Interactive rebase rules

```powershell
# Squash fixups into meaningful commits
git rebase -i HEAD~5
```

| Command | Effect |
|---|---|
| `pick` | Use commit as-is |
| `squash` | Combine with previous, merge message |
| `fixup` | Combine with previous, discard message |
| `reword` | Edit commit message |
| `edit` | Stop to amend |
| `drop` | Remove commit |

**Best practice:** `fixup` for typos and WIP, `squash` for "address review feedback".

---

## Merge Conflict Resolution

### Strategy

1. **Don't panic.** Conflicts are normal.
2. **Understand both sides.** Read the diff, not just accept yours.
3. **Test after resolving.** Conflicts can introduce subtle bugs.

### Resolve in VS Code

```powershell
# Start merge, get conflicts
git merge feature/foo
# VS Code shows: Current | Incoming | Both | Compare
# After resolving each file:
git add .
git merge --continue
```

### Resolve via CLI

```powershell
# Accept theirs entirely
git checkout --theirs -- src/file.ts
# Accept ours entirely
git checkout --ours -- src/file.ts
# Manual: edit conflicted files, look for <<<< <<< ====
```

### Abort if stuck

```powershell
git merge --abort
git rebase --abort
```

### Good conflict hygiene

- Pull/rebase often — smaller diffs = fewer conflicts
- Break PRs into small, focused changes
- Keep file-level refactors separate from logic changes
- Communicate with team about shared files

---

## Git Worktree

Work with multiple branches simultaneously without stashing.

```powershell
# Add a worktree for a feature branch
git worktree add ../project-feat-auth feat/auth

# List all worktrees
git worktree list

# Remove a worktree
git worktree remove ../project-feat-auth
```

**Use cases:**
- Review a PR while keeping current branch loaded
- Run tests on a different branch side-by-side
- Hotfix on main while working on a feature

**Rules:**
- Don't create nested worktrees inside other worktrees
- Use absolute or `../` paths
- Delete worktree before deleting the branch

---

## Git Hooks

### Hook locations

```
.git/hooks/
├── pre-commit          # Before commit — lint, format, test
├── prepare-commit-msg  # Before editor opens — inject message
├── commit-msg          # Validate commit message format
├── post-commit         # After commit — notify, log
├── pre-push            # Before push — run checks
└── pre-receive         # Server-side — policy enforcement
```

### pre-commit

Runs **before** the commit is created. Stops the commit if it fails.

```bash
#!/usr/bin/env bash
# Example: lint staged files
npx lint-staged
```

Common checks:
- Lint staged files (`lint-staged`, `eslint`, `ruff`)
- Format check (`prettier --check`, `dprint`)
- TypeScript type check (`tsc --noEmit`)
- Secret detection (`talisman`, `gitleaks`)
- No large files
- No `debugger` / `console.log` left

### commit-msg

Validates the commit **message** format.

```bash
#!/usr/bin/env bash
# Enforce conventional commits
INPUT_FILE=$1
grep -Eq '^(feat|fix|docs|refactor|test|chore|style|perf|ci|revert)(\(.+\))?!?: .{1,72}' "$INPUT_FILE"
```

### pre-push

Runs **before** pushing. Good for expensive checks.

```bash
#!/usr/bin/env bash
# Run full test suite
npm test
```

### Managing hooks

- **Check into repo:** use a hooks manager (`lint-staged`, `husky`, `pre-commit` framework)
- **Skip hooks:** `git commit --no-verify`, `git push --no-verify`
- **Hooks are local:** not pushed with `git push` (but tools like husky sync them)

### Husky (Node.js)

```json
// .husky/pre-commit
npx lint-staged
```

### pre-commit framework (Python)

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.6.0
    hooks:
      - id: ruff
      - id: ruff-format
```
