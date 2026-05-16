---
name: comprehensive-review
description: "Comprehensive code review using parallel specialized subagents. If a PR URL is provided, fetches PR details and can post comments. If no PR is provided, reviews the diff between the current branch and its base branch plus any uncommitted changes. CRITICAL: this skill is costly, don't use it unless user explicitly requested to use it."
metadata:
  version: 2.1.0
---

# Comprehensive Code Review

Run parallel specialized code reviews via subagents, covering architecture, security, performance, code quality, requirements compliance, and bugs. Merge findings and let the user act on them. Works with both GitHub PRs and local branch diffs.

## Variables

- `{TEMP_DIR}` — the OS temporary directory (e.g. `/tmp` on Unix, `%TEMP%` on Windows). Use it for all intermediate files.

## Workflow

### Step 1: Determine review mode

Check if the user provided a GitHub PR link.

- **PR mode**: A PR URL is provided matching `https://github.com/<OWNER>/<REPO>/pull/<PR_NUMBER>`. Extract owner, repo, and PR number.
- **Local mode**: No PR URL provided. The review will be based on the diff between the current branch and its base branch, plus any uncommitted changes.

### Step 2: Fetch diff and task description via subagent

Call a subagent to gather all change details, save the diff, and checkout the correct branch.

**CRITICAL**: You MUST spawn a subagent for this step. Do NOT perform the diff-gathering, branch detection, or complexity assessment yourself. Do NOT read the file `<SKILL_DIRECTORY>/fetch-diff.md` yourself. The subagent must read it and follow its instructions.

Construct the subagent prompt as follows:

```
Read the file `<SKILL_DIRECTORY>/fetch-diff.md` for detailed instructions, then follow them.

Mode: <PR mode or Local mode>
<If PR mode: Owner: <OWNER>, Repo: <REPO>, PR Number: <PR_NUMBER>>

IMPORTANT: Do NOT invoke the Skill tool. All instructions you need are in the file specified above.
```

Use a subagent tool to spawn the subagent. Use a powerful model since this involves complex reasoning to assess complexity.

The subagent will return:
- **Diff file path**: absolute path to the saved diff file (must start with `/`, e.g. `{TEMP_DIR}/review-diff-feature.patch`)
- **Diff line count**: total number of lines in the diff file
- **Title**: the PR title or summary from commits
- **Description**: comprehensive task description with all requirements
- **Complexity**: one of `simple`, `medium`, or `hard`

Remember these values for use in subsequent steps.

### Step 3: Run specialized reviews

The review strategy depends on the **complexity** returned by the fetch-diff subagent.

#### Review Criteria and Instruction Files

Each review criterion has a corresponding instruction file inside this skill's directory:

| Review criterion | Instruction File |
|-------------|-----------------|
| architecture | `criteria/architecture.md` |
| security | `criteria/security.md` |
| performance | `criteria/performance.md` |
| code-quality | `criteria/code-quality.md` |
| requirements-compliance | `criteria/requirements-compliance.md` |
| bugs | `criteria/bugs.md` |

#### Strategy A: Simple complexity

For **simple** PRs, perform the review yourself (the root agent) without calling subagents.

1. Read **all 6** criteria instruction files from `<SKILL_DIRECTORY>/criteria/`.
2. Read the diff file.
3. Apply all criteria to review the change yourself, producing findings as a flat list without priorities (same format as subagents would). You will assign priorities in Step 4.

#### Strategy B: Medium complexity

For **medium** PRs, launch **6 parallel subagent calls** — one per review criterion.

**CRITICAL**: You MUST spawn subagents for this step. Do NOT read the criteria instruction files yourself. Do NOT perform the reviews yourself. Each subagent must read its own instruction file.

Use a subagent tool to spawn each subagent. Select the single most powerful model from each available provider. Alternate these models across the 6 criteria (e.g., provider A's best model for criteria 1, 3, 5 and provider B's best model for criteria 2, 4, 6). If only 1 provider is available, use its most powerful model for all 6.

Construct prompts for subagents as follows:

```
Read the file `<INSTRUCTION_FILE>` for detailed review instructions, then follow them to review the following change.

## <title>

### Task Description
<task description>

### Diff
Read the diff from file: <absolute path to diff file> (total lines: <diff line count>)

IMPORTANT: Do NOT invoke the Skill tool. Do NOT run tests, builds, linters, or type-checks — your review is based on static analysis only. All review instructions are in the file specified above.
```

Where `<INSTRUCTION_FILE>` is the absolute path to the instruction file (e.g. `<SKILL_DIRECTORY>/criteria/architecture.md`).

#### Strategy C: Hard complexity

For **hard** PRs, launch **2 parallel subagent calls per criterion** (12 total) — one per criterion per model, using 2 different models from different providers for diverse perspectives.

**CRITICAL**: You MUST spawn subagents for this step. Do NOT read the criteria instruction files yourself. Do NOT perform the reviews yourself. Each subagent must read its own instruction file.

**Model selection**: Choose exactly 2 models — the single most powerful model from each of 2 different providers. If only 1 provider is available, use its most powerful model for all 12 calls (fall back to Strategy B behavior with 2 calls per criterion).

Use a subagent tool to spawn each subagent.

For each of the 6 criteria, launch 2 subagents — one with each model.
Use following prompt:

```
Read the file `<INSTRUCTION_FILE>` for detailed review instructions, then follow them to review the following change.

## <title>

### Task Description
<task description>

### Diff
Read the diff from file: <absolute path to diff file> (total lines: <diff line count>)

IMPORTANT: Do NOT invoke the Skill tool. Do NOT run tests, builds, linters, or type-checks — your review is based on static analysis only. All review instructions are in the file specified above.
```

Where `<INSTRUCTION_FILE>` is the absolute path to the instruction file (e.g. `<SKILL_DIRECTORY>/criteria/architecture.md`).

All 12 calls should be launched in parallel.

### Step 4: Merge, filter, and prioritize results

Subagents return findings as flat lists without priority or severity labels. The root agent is responsible for deduplication, false-positive filtering, and priority assignment.

#### 4a. Collect and deduplicate

1. Collect all findings from each review (self-review or subagent responses).
2. Group findings by file and line number.
3. Merge issues that describe the same problem (same file, similar line range, same category). When merging, combine their review types. For **hard** PRs, findings from different models on the same criterion that agree strengthen confidence; findings from only one model should be noted as lower confidence.
4. Keep the best description, suggested fix, and **Diff line** from among duplicates. Track Diff line values internally for use in Step 7 but do NOT include them in the output shown to the user.

#### 4b. Filter false positives

Review each finding and discard it if:
- The subagent itself expressed doubt about whether it's a real issue.
- You can verify from the code context that the issue does not apply (e.g., the code is already protected by a guard the subagent missed, or the flagged pattern is intentional and correct).
- The finding is about a pre-existing issue not introduced by the change.

Be conservative — when in doubt, keep the finding.

#### 4c. Assign priorities

Assign a priority to each remaining finding using these levels:

| Priority | Meaning | Action |
|----------|---------|--------|
| P0 | Critical — blocks merge, causes crashes/data loss/security breach | Must fix before merge |
| P1 | Major — significant issue affecting correctness, security, or maintainability | Must fix |
| P2 | Minor — real issue but low impact, improvement opportunity | Nice to fix |
| P3 | Suggestion — nitpick, style preference, optional enhancement | Optional |

When assigning priorities, consider:
- **Cross-criteria signal**: A finding flagged by multiple criteria (e.g., both architecture and security) is likely more important.
- **Blast radius**: Issues affecting hot paths, public APIs, or security boundaries deserve higher priority.
- **Confidence**: Findings confirmed by multiple models (hard PRs) or backed by concrete evidence deserve higher priority than speculative ones.
- **Context**: The same issue type may deserve different priorities depending on the codebase and change context.

#### 4d. Format output

Sort by priority (P0 first), then by file path. Each finding must be a standalone entry — do NOT bundle multiple distinct issues into a single row even if they are related.

```
## Comprehensive Review Findings

| # | Priority | Issue | File:Line | Review type |
|---|----------|-------|-----------|------------|
| 1 | P0 | Description | link to specific line in file | architecture(opus-4-6-think), security(gpt-5-3-codex) |
| 2 | P1 | Description | link to specific line in file | bugs(opus-4-6-think) |
| ... | | | | |

### Details

#### 1. [P0] Issue title
**File:** link to specific line in file
**Review type:** architecture(opus-4-6-think), security(gpt-5-3-codex)

Description and why it matters.

**Suggested fix:**
\`\`\`
code
\`\`\`
```

### Step 5: Ask user how to handle each finding

**Skip this step if the user already specified what to do with findings in their initial prompt** (e.g., "fix all issues", "post comments for all P0s", etc.). In that case, proceed directly to Steps 6/7 based on their instructions.

Otherwise, send a single message asking the user which findings to fix or post as comments. List each finding with its number, priority, and short description, and ask the user to reply with their choices.

- **PR mode**: Ask which issues to fix and which to post as PR comments.
- **Local mode**: Only ask which issues to fix. Do NOT mention posting comments.

### Step 6: Apply fixes for issues marked "Fix"

For each finding the user chose "Fix":

1. Read the relevant file and understand the surrounding context.
2. Apply the suggested fix (or an appropriate fix if the suggestion is incomplete).
3. After all fixes are applied, present a summary of changes made.

### Step 7: Post selected issues as PR comments (PR mode only)

**Skip this step entirely if no findings were marked "Post comment".**

Only applies in PR mode. Post line-specific comments via the `post_review.js` script.

#### 7a. Build the review payload JSON

Construct a JSON object with this structure:

```json
{
  "event": "COMMENT",
  "body": "## Comprehensive Code Review\n\n### Findings Summary\n\n| Priority | Issue | Location | Review type |\n|----------|-------|----------|------------|\n| P0 | Issue title | `path/to/file.ts:42` | code-quality(gpt-5-3-codex) |\n\n### Recommendation\n[Concise recommendation]",
  "comments": [
    {
      "path": "path/to/file.ts",
      "line": 42,
      "side": "RIGHT",
      "body": "**[P0] Issue Title** (review type: code-quality(gpt-5-3-codex))\n\nDescription.\n\n**Suggested fix:**\n```\ncode\n```"
    }
  ]
}
```

For each finding marked "Post comment":
- `path`: the file path relative to repo root
- `line`: the line number for the comment. For `RIGHT` side, this is the new-file line number (from `+new_start,new_count` hunk range). For `LEFT` side, this is the old-file line number (from `-old_start,old_count` hunk range). Use the `Diff line` value from the findings table when the finding targets new/modified code. For findings targeting deleted code, use the old-file line number from the `-`-side of the diff hunk
- `side`: `RIGHT` for new/modified code, `LEFT` for deleted code. Use `LEFT` only when commenting on lines that were removed (shown with `-` prefix in the diff)
- `body`: include priority, title, review type with model name, description, and suggested fix
- Each finding gets its own comment — do NOT merge multiple findings into one comment

If user added custom notes to a finding, update description and/or suggested fix according to these notes.

Save the JSON to a file named `{TEMP_DIR}/review_payload-<branch-name>.json`.

#### 7b. Post via the script

```bash
node <SKILL_DIRECTORY>/scripts/post_review.js <OWNER>/<REPO> <PR_NUMBER> <diff-file-path> {TEMP_DIR}/review_payload-<branch-name>.json
```

The script validates comment line numbers against the diff, adjusts them to the nearest valid diff line when close, and moves out-of-range comments to the review body. You don't need to validate line numbers manually. The script logs progress and any errors (even if they were recoverable). It outputs in the end whether the review was posted successfully.
