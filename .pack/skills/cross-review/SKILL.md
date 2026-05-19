---
name: cross-review
description: Delegate code review to a subagent running a specific model. Use ONLY when user explicitly names a model to review changes ("review with opus", "use sonnet to review", "review with gemini"). The root agent reconstructs changes from conversation history and spawns a subagent with the code-review skill using the specified model. Do NOT use for general code review (use code-review skill instead), for reviewing PRs from git history, or when no model is specified by the user.
triggers:
  - "review with"
  - "review using"
  - "review via"
  - "cross review"
  - "different model review"
negatives:
  - "comprehensive review"
  - "zen review"
  - "simple review"
  - "code review"
license: MIT
compatibility: opencode
metadata:
  workflow: review
  audience: developers
  version: 1.0.0
---

Reconstruct what you changed during this conversation, then delegate the actual review to a single subagent running the `code-review` skill with a user-specified model.

IMPORTANT: Steps 1-2 run in the current agent (the master). Only Step 3 spawns a subagent.

## Workflow

### Step 1: Parse the user request

Extract:
- **Model**: The model ID from user's request. Validate against available models.
- **Review instructions**: Any text after "Review instructions:" — pass verbatim.
- **Change scope**: What should be reviewed. Default: all changes in this conversation.

### Step 2: Gather context from your own changes

Reconstruct the diff from conversation history:

1. Compose a unified diff of all changes (Edit, Write, Bash, etc.). Group by file.
   - **If no changes**: Inform user and stop.

2. Read final state of changed files for surrounding context.

3. Check related context:
   - Test files related to changed files (skip `node_modules`, `.git`, `dist`, `build`)
   - Config changes that affect behavior
   - Related type definitions or interfaces

Do NOT show gathered context to user. Use only for the subagent.

### Step 3: Spawn the review subagent

```
spawn_subagent:
  skill: "code-review"
  model: <model from user request>
  prompt: |
    Review the changes below using "code-review" skill.

    CONSTRAINTS:
    - Read-only review. Do NOT edit files.
    - All context is provided below. Read files only if clearly incomplete.
    - Review independently and objectively.

    ## Review Instructions
    {user's review instructions, verbatim}

    ## Changes
    {reconstructed diff, grouped by file}

    ## Additional Context
    {links to related files, tests, type definitions, requirements}
```

### Step 4: Relay the result — READ-ONLY, NO ACTIONS

CRITICAL: Output the subagent's review AS-IS. Do NOT:
- Summarize, rephrase, reorder, or filter
- Fix, improve, or refactor based on findings
- Add your own commentary or caveats

One-line model attribution is acceptable. You may offer to implement recommendations, but let the user decide.

## Model Mapping

When user says "review with [model name]", map to a valid model ID:

| User says | Model ID |
|-----------|----------|
| opus, claude opus | claude-3-opus |
| sonnet, claude sonnet | claude-3.5-sonnet |
| gpt-4, gpt4 | gpt-4 |
| gpt-4o | gpt-4o |
| gemini | gemini-2.0-flash |
| deepseek | deepseek-chat |

If the model name is unrecognized, ask for the exact model ID.

## Error Handling

- **Subagent fails or times out**: Inform user. Suggest retry or different model.
- **No changes in conversation**: Inform user and stop.
- **Incomplete review**: Relay what was returned. Note it may be incomplete.
- **Model not available**: Offer alternative from the mapping table.
- **User requests unknown model**: Map fuzzy names to model IDs using the mapping table. If no match, ask user to provide the exact model ID string.
- **Subagent returns malformed output**: The review subagent may return text instead of structured findings. Relay what was returned and note the format deviation.
- **Diff context exceeds subagent limits**: For very large changesets, split the diff by file or module and run multiple sequential subagent reviews. Inform user you are splitting the review.
- **Network or infrastructure failure during spawn**: Retry once with the same configuration. If it fails again, offer to switch to a different model or perform the review inline.
- **Subagent produces factually incorrect findings**: Relay findings as-is but append a note that some claims could not be verified against the codebase. Do not filter or censor.

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| Using cross-review for general PR review | User did not name a model. cross-review is for explicit model-named delegation only. | Use the standard `code-review` skill instead. |
| Summarizing or filtering subagent output | The user requested an independent review. Any distortion defeats the purpose. | Relay output verbatim. Add only a 1-line model attribution. |
| Acting on findings without user approval | The master agent is read-only in this workflow. Fixing issues automatically breaks the delegation contract. | Offer to implement recommendations but wait for user to decide. |
| Skipping context gathering (Step 2) | Sending only the diff without file context produces shallow reviews that miss type errors and behavioral changes. | Always read final file state and related test/config files before spawning the subagent. |
| Delegating to the same model the user is already talking to | If user says "review with sonnet" and master agent IS sonnet, this is circular. | Use a different model than the one running the master agent. |
| Requesting review of unchanged code | cross-review only works on changes made in the current conversation. | If the user wants PR review from git, use the `code-review` skill directly. |

## Model Comparison Methodology

### When to use which model

| Model | Strengths | Best for |
|-------|-----------|----------|
| Claude Opus 4 | Deep reasoning, security analysis, architectural review | Complex refactors, auth code |
| GPT-5 Codex | Code generation patterns, syntax accuracy | Implementation review, template checking |
| Gemini 2.5 Pro | Multi-modal, context window size | Large PRs (200+ files), full-repo context |
| DeepSeek V4 | Fast, cost-effective, strong at bug detection | Routine PRs, quick checks |

### Confidence Scoring

Assign confidence (0.0-1.0) to each finding:
```
confidence = (models_agreeing / total_models) * evidence_score

evidence_score:
  1.0 = exact line + code excerpt proves the bug
  0.7 = logic analysis suggests probable issue
  0.4 = speculative (pattern matching without code walk)
  0.1 = style preference
```

Findings with confidence < 0.5 should be:
- Marked as "suggestion" not "finding"
- Never block a merge
- Phrased as questions: "Did you consider...?"

### Result Merging Strategy

1. Group by file + line range (+-5 lines)
2. If all 3 models agree: high confidence, use as primary finding
3. If 2 of 3 agree: medium confidence, note the dissenting model's view in details
4. If 1 of 3: low confidence, verify against code manually before including
5. Merge descriptions: take the most specific one, append key insights from others
6. Remove duplicates: same finding described differently -> keep clearest description

### Handling Conflicts

When models disagree:
- Don't default to majority -- investigate the code yourself
- The dissenting model may have caught something the others missed
- Present both views: "Claude suggests X, Gemini suggests Y"
- Let the human reviewer decide

## Checklist

- [ ] Valid model name passed (not an alias or unsupported ID)
- [ ] Diff or context reconstructed accurately from conversation history
- [ ] Subagent has the code-review skill loaded
- [ ] Review result captured from subagent output (not assumed)
- [ ] Fallback model specified if primary model is unavailable

## Sources

- MCP Protocol specification (modelcontextprotocol.io) — subprocess agent spawning and message passing
- OpenAI API model list documentation (platform.openai.com/docs/models) — supported model IDs and capabilities
- Anthropic Claude model documentation (docs.anthropic.com/en/docs/about-claude/models) — model IDs and feature comparison
- Google Gemini API model documentation (ai.google.dev/models/gemini) — Gemini model identifiers and rate limits
- DeepSeek API documentation (platform.deepseek.com/api-docs) — model IDs and context window limits
- Conventional Comments specification (conventionalcomments.org) — structured review comment formatting
- "Software Engineering at Google" by Titus Winters, Tom Manshreck, Hyrum Wright (O'Reilly, 2020) — code review best practices at scale
