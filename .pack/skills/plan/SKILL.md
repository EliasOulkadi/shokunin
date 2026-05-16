---
name: plan
description: "Planning agent for task breakdown and implementation planning. Use via spawn_subagent with skill='plan' when you need to explore a codebase and design an implementation approach before writing code."
metadata:
  version: 1.0.0
disable-model-invocation: false
---

Entered plan mode. Focus on exploring the codebase and designing an implementation approach without writing code.

In plan mode:
1. Thoroughly explore the codebase to understand existing patterns
2. Identify similar features and architectural approaches
3. Consider multiple approaches and their trade-offs
4. Design a concrete implementation strategy
5. Write the plan and return its path

DO NOT write or edit any files yet (except the plan file). This is a read-only exploration and planning phase.

## Plan Workflow

### Phase 1: Initial Understanding

Goal: Gain comprehensive understanding of the user's request.

**Use only research agents** — no other agent types.

1. Understand the user's request and associated code

2. **Launch research agents in parallel** (single message, multiple calls):
   - Use `skill: 'research'` for all exploration agents
   - Use the cheapest model available
   - 1 agent for isolated tasks with known files
   - Multiple agents for uncertain scope, multiple codebase areas, or pattern discovery
   - Max 3 agents — usually 1 is enough

3. Use multiple agents when:
   - Task touches multiple parts of the codebase
   - Large refactor or architectural change
   - Many edge cases to consider
   - Need to compare different approaches

### Phase 2: Design

Goal: Design an implementation approach based on exploration results.

Launch 1-3 design agents in parallel:
- **Default**: 1 design agent for most tasks
- **Skip agents**: Only for trivial tasks (typo fixes, single-line changes, simple renames)
- **Multiple agents**: For complex tasks needing different perspectives

Example perspectives by task type:
- New feature: simplicity vs performance vs maintainability
- Bug fix: root cause vs workaround vs prevention
- Refactoring: minimal change vs clean architecture

For each agent:
- Provide comprehensive background from Phase 1
- Describe requirements and constraints
- Request a detailed implementation plan

### Phase 3: Review

Goal: Review plans and ensure alignment with user's intentions.
1. Read critical files identified by agents
2. Verify plans align with the original request
3. Do NOT call subagents here

### Phase 4: Final Plan

Goal: Write the final plan. Include:
- Only the recommended approach, not alternatives
- Critical file paths to be modified
- Verification section (how to test end-to-end)
- Concise enough to scan, detailed enough to execute

## Plan Structure Template

```
## Plan: [Feature Name]

### Summary
[1-2 sentence overview of what will be built/changed]

### Files to Modify
| File | Change |
|------|--------|
| path/to/file.ts | [what changes] |

### Implementation Steps
1. [Step 1]: [what to do, why, any gotchas]
2. [Step 2]: [what to do, why, any gotchas]
3. [Step 3]: [what to do, why, any gotchas]

### Architecture Decisions
| Decision | Choice | Rationale |
|----------|--------|-----------|
| [Decision] | [Choice] | [Why this over alternatives] |

### Risks & Mitigations
| Risk | Probability | Mitigation |
|------|-------------|------------|
| [Risk] | Low/Med/High | [Mitigation] |

### Verification
- [ ] [Test command / manual check]
- [ ] [Edge case to verify]
```

## Common Planning Patterns

| Pattern | When to use |
|---------|-------------|
| **Surgical** | Small, isolated change. Read 1-2 files, write plan in 1 message. |
| **Scout** | Adding to existing pattern. Find 3+ similar implementations first. |
| **Architect** | New feature or refactor. Full phases 1-4 with multiple agents. |
| **Emergency** | Production bug. Skip to fix, plan doc optional.

## Anti-Patterns

| Mistake | Fix |
|---------|-----|
| Over-planning trivial changes | Small typo? Just fix it. Plan adds no value. |
| Under-planning complex changes | New feature across 10 files? Always go through phases 1-4. |
| Skipping verification | Always include how to test the end result. |
| Too many alternatives in final plan | Choose one. Use the plan file, not a discussion document. |
| Designing without reading existing patterns | Always check 3+ similar implementations first. |
