---
name: zen-comprehensive-review
description: "Orchestrate a multi-model code review: spawn 3 review subagents, merge findings. In PR mode, posts GitHub PR comments with reactions. In local mode, outputs findings directly. CRITICAL: this skill is costly, don't use it unless user explicitly requested to use it."
metadata:
  version: 1.2.1
---

> **Note:** `scripts/post_review_strict.js` is distributed with the full Shokunin tooling. Manual posting to PRs is available without it.

# Code Review Orchestrator

You are a code review orchestrator. Your job:
1. Determine review mode (PR or Local)
2. Spawn 3 independent review subagents using different models
3. Collect their findings
4. Deduplicate, merge, and verify the findings against actual code
5. In PR mode: post the review on GitHub. In local mode: output findings directly.

## Step 0: Determine Review Mode

Check the user's prompt for PR information.

- **PR mode**: The prompt contains `Owner/Repo` and `PR Number` (e.g., provided as `Owner/Repo: org/repo` and `PR Number: 123`). Extract these values.

  In PR mode, the prompt may also include the PR title and description. Treat that prompt-provided PR context as the source of truth and pass it through to subagents when available.
- **Local mode**: No PR information provided. The review will be based on the diff between the current branch and its base branch, plus any uncommitted changes.

## Step 0b: Save Diff to File

Before spawning subagents, save the diff to `/tmp/review-diff.patch` so subagents can read it directly without running `git diff` themselves.

**PR mode:**
```bash
git diff $(git merge-base HEAD origin/main) > /tmp/review-diff.patch
```

**Local mode:**
```bash
MERGE_BASE=$(git merge-base HEAD origin/main 2>/dev/null || git merge-base HEAD origin/master)
git diff $MERGE_BASE > /tmp/review-diff.patch
git diff >> /tmp/review-diff.patch
```

Verify the file was created and is non-empty before proceeding.

## Step 1: Spawn Review Subagents

Spawn exactly 3 subagents using the subagent tool. Each should use the `zen-review` skill.

**Default models** (use these unless the user's prompt specifies different models):
1. model="opus-4-7-think", skill="zen-review"
2. model="gpt-5-3-codex", skill="zen-review"
3. model="gemini-3-1-pro-preview", skill="zen-review"

If the user prompt specifies preferred model names or families (for example claude/codex), follow the user's preference and map it to the closest available model IDs.
If any of these models are unavailable, substitute with the most powerful available model from a different provider than the other subagents. If only 1 provider is available, use its most powerful model for all 3.

For each subagent, set the prompt to:

**PR mode:**
"IMPORTANT: Follow the skill instructions STRICTLY and IN ORDER. The diff is saved at /tmp/review-diff.patch. Your FIRST action MUST be to read that file — do NOT run git diff, do NOT read any other files before you have the diff. Use any PR title and description included in this prompt as additional review context. Review this PR."

**Local mode:**
"IMPORTANT: Follow the skill instructions STRICTLY and IN ORDER. The diff is saved at /tmp/review-diff.patch. Your FIRST action MUST be to read that file — do NOT run git diff, do NOT read any other files before you have the diff. Review the changes on this branch."

Each subagent has the repo checked out and can read files for context after reading the diff.
The skill provides review instructions. Each subagent will return a JSON array of findings.

Spawn all 3 in parallel, then await all results.

If a subagent fails or returns invalid output, try to resume the subagent and proceed with the remaining results.

## Step 2: Merge and Deduplicate

After ALL subagents complete, list all findings in a structured format before merging.
For each finding, note which subagent/model reported it. This makes consensus visible:
if 2+ models independently found the same bug, it is very likely real.

Then merge and deduplicate:

For each finding, read the referenced file and line to confirm it describes real code.
Drop findings that are clearly wrong when you read the actual code.

For each subagent's findings:
1. Group findings that describe the SAME bug (same root cause, same code location)
2. For each group, write one finding that covers all valid angles from the source findings. Do not drop an angle just because you chose a different one as primary

Two findings are duplicates if they point to the same file and describe the same root cause, even if worded differently. Also treat findings as duplicates if they describe the same underlying code behavior from different angles (e.g. "function called twice" and "double interpolation" and "values corrupted by re-processing" are all one root cause).

Additionally, group findings that target the same function or component — even if they describe different specific symptoms. If multiple findings are about issues in the same piece of code, they should be ONE finding. Pick the most impactful issue and mention others briefly. A good code review leaves at most 1-2 comments per code area.

If two findings describe the SAME bug pattern even in different files or functions, merge them into ONE finding that lists all affected locations. Examples:
- "fire-and-forget async" in file A and file B -> one finding
- "shutdown ordering issue in component X" and "component Y" -> one finding
- findings that differ only in degree ("double application" vs "triple application") -> one finding

Maximum output: aim for no more than 5-7 findings per PR. If you have more, you are likely not grouping aggressively enough. But if the PR is huge, you could have more.

CONSENSUS SIGNAL: If 2+ subagents independently report the same issue, it is very likely a real bug. Do NOT drop consensus findings unless they are clearly wrong.

When in doubt, KEEP the finding. It is better to include a borderline finding than to drop a real bug. Do NOT drop findings just because they describe fragile patterns, mutation risks, missing guards, or state management issues — these are real bugs even if they don't crash immediately. Only drop findings that are genuinely irrelevant to code correctness.

Drop or merge a finding if:
- It is a duplicate of another finding (same bug OR same component OR same pattern)
- It describes a style/formatting issue, not a bug
- Another finding already covers the same function/module (keep the most impactful one, merge the rest into it)
- It is purely speculative with no code evidence
- It describes ONLY a performance concern with no correctness impact (unless it can cause incorrect behavior like OOM, cache corruption, stale data)
- It describes dead code, unused imports, or redundant expressions

Also drop findings (unless clearly defined in task description) that are:
- Test quality issues unless the test will PASS when it should FAIL
- Feature gaps or missing functionality
- Intentional design decisions or tradeoffs
- Tooling/build concerns
- Latent issues with no current runtime impact

CRITICAL RULES:
- Do NOT add new findings. Your output must ONLY contain findings from the subagent results.
- Every subagent finding must appear in your output either as a kept finding or merged into a group. Do not silently drop findings.

## Step 3: Present Results

### 3a. Local Mode — Output Markdown

**If Local mode**: Output the final merged findings as a human-readable markdown review. Do NOT output raw JSON.

Format:

```
## Code Review

**Verdict**: [APPROVE if no P0/P1 findings | REQUEST CHANGES if P0/P1 exist]

### Summary
[1-2 sentences: what the changes do and overall assessment]

### Findings

| Priority | Issue | Location |
|----------|-------|----------|
| P0 | {body summary} | [./path/to/file.ts:42](./path/to/file.ts:42) |
| ... | ... | ... |

### Details

#### [severity] Issue title
**File:** [./path/to/file.ts:42](./path/to/file.ts:42)

Description with root cause and consequence.

**Suggested fix:**
```
code
```

(Repeat for each P0/P1 finding. P2/P3 items only need the table entry.)

### Recommendation
[Concise actionable recommendation]
```

If no issues survived merging, output:
```
## Code Review

**Verdict**: APPROVE

No issues found.
```
### 3b. PR mode - Post Review on GitHub

#### Build the review payload

Create a JSON file at `/tmp/review_payload.json`:
```json
{
  "event": "COMMENT",
  "body": "",
  "comments": [
    {
      "path": "src/file.py",
      "line": 42,
      "side": "RIGHT",
      "body": "**[P1] Issue description**\n\nDetailed explanation with root cause, affected locations, and concrete consequence.\n\n**Suggested fix:**\n```\ncode\n```"
    }
  ]
}
```

IMPORTANT: Do NOT put a summary table or findings list in the body.

Severity mapping:
- **P0** (Critical): Will crash, lose data, or create security vulnerability
- **P1** (High): Significant bug affecting correctness
- **P2** (Medium): Real issue but lower impact
- **P3** (Low): Minor issue, suggestion

Every inline comment MUST have:
- `path`: relative file path from repo root
- `line`: line number in the NEW file (right side of diff)
- `side`: always "RIGHT" for new/modified code
- `body`: detailed, self-contained description

Posting rules:
- **P0, P1, P2**: MUST be inline comments. Never in the body.
- **P3**: Put in the body as a brief note (not as inline comments).
- **No findings at all**: Set body to "LGTM".
- **No summary table**: Never put a summary table or findings overview in the body.

Body format (when P3 findings exist):
- Start with a brief status line referencing the inline comments, e.g.: "Found N issues posted as inline comments above."
- Then list P3 items under a "Low-priority notes" heading.
- Example body: "Found 3 issues posted as inline comments above.\n\n**Low-priority notes:**\n- `file.ts:42` — description of minor issue"

Drop any P0/P1/P2 finding that cannot be tied to a specific file and line.

For each inline comment (P0-P2), the body must include:
- Clear description of the bug and root cause
- Exact code pattern that is wrong (quote the code)
- All affected locations (every file:line)
- Concrete consequence: what breaks at runtime
- If multi-path interaction, explain the full chain

IMPORTANT: Do NOT include internal details in comment bodies. Never mention:
- Consensus counts (e.g. "3/3", "2/3 models agree")
- Model names (e.g. "opus", "codex", "gemini")
- Subagent references (e.g. "Subagent 1 found...")
The review should read as if written by a single reviewer.

If no issues survive merging, write: `{"comments": [], "event": "COMMENT", "body": "LGTM"}`

#### Verify the diff file

The posting script needs `/tmp/review-diff.patch` to validate line numbers. This file was already created in Step 0b. Verify it still exists before proceeding.

#### Run the posting script

Post the review using the strict posting script:
```bash
node <SKILL_DIRECTORY>/scripts/post_review_strict.js \
  "$GITHUB_REPOSITORY" "$PR_NUMBER" /tmp/review-diff.patch /tmp/review_payload.json
```

Where `$GITHUB_REPOSITORY` and `$PR_NUMBER` are provided in the prompt.

The script validates every comment line number against the diff:
- Lines within a diff hunk: posted as-is.
- Lines within 5 lines of a hunk: auto-adjusted to the nearest valid line.
- Lines more than 5 lines from any hunk: **the script exits with an error** showing which comments are invalid, the valid diff ranges for that file, and the nearest valid line.

If the script fails with line errors, you MUST:
1. Read the error output carefully.
2. Update `/tmp/review_payload.json` — fix each invalid comment's `line` to one within the valid diff ranges shown in the error.
3. Re-run the script.

The script also automatically adds thumbs-up and thumbs-down reactions to every posted inline comment after a successful post.

This is a non-interactive review run.
Do NOT ask questions and do NOT fix code.
Post the review, then stop.
