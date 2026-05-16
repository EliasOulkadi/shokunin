---
name: cross-review
description: Delegate code review to a subagent running a specific model. Use ONLY when user explicitly names a model to review changes ("review with opus", "use sonnet to review", "review with gemini"). The root agent reconstructs changes from conversation history and spawns a subagent with the code-review skill using the specified model. Do NOT use for general code review (use code-review skill instead), for reviewing PRs from git history, or when no model is specified by the user.
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
