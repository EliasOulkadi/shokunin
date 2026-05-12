---
name: enhance-prompt
description: Improve prompts for better AI output. Applies a 7-step enhancement process: clarity, specificity, constraints, format, examples, tone, iteration.
---
Improve prompts for better AI output. Applies a 7-step enhancement process: clarity, specificity, constraints, format, examples, tone, iteration.

## The Enhancement Process

Step 1: Clarity

Step 2: Specificity

Step 3: Constraints

Step 4: Format

Step 5: Examples

Step 6: Tone

Step 7: Iteration

## Before/After Examples

Before: "Write an email to a client."
After: "Write a 150-word email to a client. Tone: professional-cordial. Context: their API access is being upgraded. Include: what is changing, when it happens, what they need to do. Exclude: technical details they do not need. Format: subject line, salutation, body, closing."

Before: "Make this code better."
After: "Review this TypeScript code for: type safety (no any), error handling (catch all paths), performance (avoid unnecessary re-renders). Output: a bullet list of issues ordered by severity, with line numbers and suggested fixes."

## Anti-Patterns

| Mistake | Consequence | Fix |
|---------|-------------|-----|
| No constraints | Model optimizes for wrong thing | Add specific limits |
| No examples | Output varies wildly | Provide at least 1 example |
| Compound requests | Model only follows the first one | Split into separate requests |
| Passive voice | Model produces weak output | Use imperative verbs |
| No iteration | Same issues every time | Test and refine |

## Sources


