---
name: code-review
description: "Review code changes for correctness, security, performance, and code quality. Use when the user asks to review a diff, review code changes, review commits, or perform a code review. Input can be: (1) a text diff pasted directly, (2) one or more git commit hashes to extract the diff from, or (3) a git range like abc123..def456. The user may also provide task description or requirements that motivated the change."
triggers:
  - "review code"
  - "code review"
  - "review this change"
  - "review diff"
  - "check my code"
  - "code quality review"
  - "review my PR"
negatives:
  - "comprehensive review"
  - "multi-model review"
  - "design review"
  - "UI review"
license: MIT
compatibility: opencode
metadata:
  version: 1.0.0

  workflow: quality
  audience: developers
---


# Code Review

Expert code reviewer combining rigorous analysis with deep expertise in clarity, consistency, and maintainability. Prioritize readable, explicit code over overly compact solutions while ensuring correctness and security.

## Inputs

Accept any combination of:
1. **Text diff** — pasted directly by the user
2. **Git commit hashes** — one or more SHAs; extract the diff with git
3. **Task description / requirements** — context for what the change is supposed to accomplish

## Workflow

### Step 1: Obtain the diff

- If the user provided a text diff, use it directly.
- If the user provided commit hashes, extract the diff with git:
  ```bash
  # Single commit — show its diff:
  git diff "<commit>^..<commit>"
  # Two commits — diff between them:
  git diff "<commit1>..<commit2>"
  # Range syntax (abc123..def456) — pass directly:
  git diff "<range>"
  ```
- If the user provided a range (e.g. `abc..def`), pass it as a single argument.
- If neither diff nor commits are provided, ask the user for input.

### Step 2: Gather context

- Read the changed files fully (not just the diff hunks) to understand surrounding code.
- Search the codebase for code that depends on or is affected by the changed code — callers, importers, subclasses, consumers of modified interfaces/APIs/types. The actual version of the code after the diff is applied is already checked out, so use file search tools to find dependent code and read it.
- If the user provided task requirements, keep them in mind — flag deviations where the implementation doesn't match stated intent.

### Step 3: Analyze changes

Review against two tiers using the checklist below.

#### Priority Levels

| Level | Meaning | Action |
|-------|---------|--------|
| P0 | Critical — security vulnerability, data loss risk, crash | Must fix |
| P1 | Major — significant bug, performance regression, broken feature | Must fix |
| P2 | Minor — code smell, clarity issue, inconsistency | Nice to fix |
| P3 | Suggestion — improvement idea, optional refactor | Optional |

#### Critical Issues (P0–P1)

**Correctness:**
- Logic errors and off-by-one mistakes
- Unhandled edge cases (null, empty, boundary values)
- Broken control flow (early returns, missing breaks)
- Incorrect type conversions or comparisons
- State mutation side effects

**Security:**
- Injection vulnerabilities (SQL, command, XSS)
- Exposed secrets, tokens, or credentials
- Unsafe deserialization
- Missing input validation at system boundaries
- Improper access control or authorization checks

**Performance:**
- Inefficient algorithms (quadratic where linear is possible)
- N+1 queries or unbounded database calls
- Memory leaks or unbounded growth
- Missing pagination on large datasets
- Blocking operations in async contexts

**Data Integrity:**
- Race conditions in concurrent code
- Missing transactions for multi-step writes
- Data loss on error paths
- Inconsistent state after partial failures

#### Code Quality (P2–P3)

**Clarity:**
- Unnecessary complexity or deep nesting
- Poor naming (vague, misleading, or inconsistent)
- Confusing logic flow or convoluted conditionals
- Nested ternary operators (prefer switch/if-else)
- Magic numbers or unexplained constants

**Consistency:**
- Violations of project conventions
- Inconsistent naming conventions
- Mixed patterns for the same concern
- Import style inconsistencies

**Maintainability:**
- Missing abstractions for duplicated logic
- Tight coupling between unrelated modules
- Over-engineering simple problems
- Dead code or unreachable branches

**Simplification:**
- Redundant null checks or type guards
- Overly verbose constructs with simpler alternatives
- Unnecessary intermediate variables
- Code that reimplements standard library functions

**Principles:**
- Only flag issues **introduced by the change**, not pre-existing problems.
- Preserve functionality — suggest changes to HOW, never WHAT.
- Prefer explicit code over clever one-liners.
- Consider the user's stated requirements when judging correctness.

### Step 4: Produce the review

Output this format:

```
## Code Review

**Verdict**: [APPROVE | REQUEST CHANGES | NEEDS DISCUSSION]
**Confidence**: [HIGH | MEDIUM | LOW]

### Summary
[1-2 sentences: what the change does and overall assessment]

### Findings

| Priority | Issue | Location |
|----------|-------|----------|
| P0 | Description | file:line |
| P1 | Description | file:line |
| P2 | Description | file:line |

### Details

#### [P0/P1] Issue title
**File:** `path/to/file.ext:line`

Description of the issue and why it matters.

**Suggested fix:**
\```
code suggestion
\```

(Repeat for each P0/P1 finding. P2/P3 items only need the table entry unless a code suggestion adds clarity.)

### Recommendation
[Concise actionable recommendation for the author]
```

**Rules:**
- Use `APPROVE` only when there are no P0 or P1 findings.
- Use `REQUEST CHANGES` when P0 or P1 findings exist.
- Use `NEEDS DISCUSSION` when findings are ambiguous or require author's context.
- Include detailed write-ups with suggested fixes for every P0 and P1 finding.
- P2/P3 findings go in the table; add detail sections only when a code suggestion helps.
- Keep it concise — don't pad with praise or filler.

## Review Tone & Psychology

| Situation | Approach | Why |
|-----------|----------|-----|
| First-time contributor | More context, more encouragement, fewer P2/P3 | Build confidence, don't overwhelm |
| Senior teammate regular | Direct, skip obvious nits, focus on P0/P1 | Respect their experience |
| Critical security fix | Maximum rigor, verify every path | One oversight = incident |
| Design/style PR | Suggest alternatives, not absolutes | Style is subjective, solve the problem |
| Junior developer | Explain the "why" behind every finding | Teach fundamentals, not just "fix this" |

Always assume positive intent. Phrase findings as observations: "This path returns null when..." not "You forgot to handle..."

## Common P0/P1 Patterns To Watch For

| Pattern | Why it's dangerous | How to detect |
|---------|-------------------|---------------|
| Missing auth check on new endpoint | Unauthenticated access to data | Check if the endpoint/service is behind auth middleware |
| SQL concatenation | Injection vulnerability | Look for `${var}` in query strings |
| Hardcoded secret/token | Credential exposure | Grep for `sk-`, `AKIA`, `-----BEGIN` |
| No input validation on user-facing API | Malformed data crashes the system | Check API boundary for validation middleware |
| Unbounded array/list growth | Memory exhaustion | Check if push/add has a limit check |
| Swallowing errors silently | Silent data corruption | Look for empty `catch {}` blocks |
| Race condition in concurrent code | Data corruption | Check shared state without locks |
| Missing pagination on list endpoint | Performance regression under load | Check if query has LIMIT/OFFSET |

## Review Speed Guide

| Diff Size | Approach | Estimated time |
|-----------|----------|----------------|
| 1-50 lines | Full line-by-line review | 2-5 min |
| 50-200 lines | Read all, focus on changed logic | 5-10 min |
| 200-500 lines | Read structure, sample key paths | 10-15 min |
| 500+ lines | Read description + key files; flag if too large | 15+ min |
| Generated/auto-formatted code | Check output correctness only | 1-2 min |

---

## Error Handling

| Cause | Fix |
|-------|-----|
| User provides no diff, no commits, no range | Ask for input before proceeding. Don't guess or review random code. |
| Git diff on a single commit returns empty | Use `git diff <commit>^..<commit>` to show changes introduced by that commit. |
| Diff exceeds 500 lines and is unreviewable | Flag the size as a P3 finding. Review structure only, sample key paths. |
| Changed file deleted in working tree | Verify file still exists before reading. Note the deletion in review. |
| Diff contains binary or generated files | Skip binary files. For generated code, check output correctness only. |
| Reference code (callers/importers) not found | Note limited context in review. Flag that surrounding analysis was incomplete. |
| Task requirements contradict the diff | Flag the deviation as a finding. Note what the requirement says vs what the code does. |
| Multiple commit hashes provided, one is invalid | Verify each hash with `git cat-file -t <hash>`. Skip invalid hashes, review remaining. |

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| Reviewing pre-existing code not in the diff | Scope creep. Overwhelms the author with unrelated issues. | Only flag issues introduced by the change. Mention pre-existing issues separately if critical. |
| Flagging style preferences as P0/P1 bugs | Dilutes severity. Authors ignore future reviews. | P0 = crash/security/data loss. P1 = broken feature. P2 = code smell. P3 = preference. |
| Suggesting functional changes beyond the diff scope | Changes WHAT the code does, not HOW | Preserve functionality. Only suggest changes to implementation approach. |
| "This could be simplified" with no specific alternative | Vague, unactionable, frustrating | Always provide a concrete suggested fix with code example. |
| Reviewing generated or vendored code line-by-line | Waste of reviewer time | Check only output correctness. Skip formatting/style on generated code. |
| Using absolute language ("This is wrong") without evidence | Defensive response from author | Phrase as observation: "This path returns null when..." with evidence. |
| Padding review with praise or filler | Wastes author's reading time | Keep it concise. Verdict, findings table, details for P0/P1 only. |
| Not reading surrounding code for context | Misses callers, importers, and downstream effects | Read changed files fully. Search for dependents. Understand the blast radius. |

## Security Review Checklist

- [ ] Input validation: all user input validated at boundary
- [ ] SQL: parameterized queries (no string interpolation)
- [ ] Authentication: every endpoint checks auth
- [ ] Authorization: resource ownership verified server-side
- [ ] Secrets: no API keys, tokens, or passwords in code
- [ ] Error messages: no stack traces or internal paths exposed
- [ ] File uploads: type validated, size limited, stored outside webroot
- [ ] Rate limiting: on auth, password reset, and email endpoints
- [ ] Dependencies: `npm audit` or `pip check` passes with zero HIGH/CRITICAL

## Performance Review Patterns

- [ ] Database: no N+1 queries. Check ORM eager loading.
- [ ] Caching: expensive computations cached. Cache invalidation strategy documented.
- [ ] Bundle size: new dependency impact checked. Tree-shaking verified.
- [ ] Lazy loading: heavy modules split into dynamic imports
- [ ] Memory: no unbounded arrays or maps. Large datasets use pagination/cursors.
- [ ] Network: requests batched. No waterfall of sequential API calls.
- [ ] Render: no unnecessary re-renders. Memoization where appropriate.

## Architectural Review Guidelines

- [ ] Single responsibility: each module has one reason to change
- [ ] Dependency direction: high-level modules don't depend on low-level details
- [ ] Testing: new code has tests. Tests cover happy path + error + edge cases.
- [ ] Documentation: public APIs documented. Complex logic has inline comments explaining WHY.
- [ ] Migration: breaking changes have clear migration path or compatibility layer.

## Sources

- Google Engineering Practices — "How to Do a Code Review" (google.github.io/eng-practices)
- SmartBear — "Best Practices for Code Review" (smartbear.com)
- Palantir — "Code Review Best Practices" (blog.palantir.com)
- Microsoft — "Code Review Checklist" (learn.microsoft.com)
- OWASP Code Review Guide — owasp.org/www-project-code-review-guide
- Conventional Comments — conventionalcomments.org
- Philipp Hauer — "Code Review Guidelines for Humans" (philipphauer.de)
- Trisha Gee — "Code Review Best Practices" (trishagee.com)

## Checklist

- [ ] Skill loads without errors in the AI agent
- [ ] YAML frontmatter is valid (description, compatibility, audience)
- [ ] Workflow section provides clear step-by-step instructions
- [ ] Error handling section covers common failure modes
- [ ] All referenced files (references/, scripts/, assets/) exist
- [ ] Skill triggers correctly for intended use cases
- [ ] No broken links or missing resources
