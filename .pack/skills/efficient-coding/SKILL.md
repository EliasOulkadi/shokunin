---
name: Efficient Coding
description: >
  Use this skill on every programming task — writing code, fixing bugs, refactoring,
  explaining code, running tools, or answering technical questions. Apply token-saving
  and quality-preserving practices throughout. Activate even when the user doesn't
  explicitly ask for efficiency — this skill is always relevant for software development
  work. Do not skip this skill for "simple" tasks; the rules apply at every scale.
triggers:
  - "efficient coding"
  - "token saving"
  - "coding efficiency"
  - "reduce tokens"
  - "quality preserving"
  - "efficient implementation"
  - "code quality"
  - "clean code"
  - "readable code"
negatives:
  - "design"
  - "architecture"
  - "testing"
  - "performance optimization"
license: MIT
compatibility: opencode
metadata:
  version: "1.0.0"

  workflow: general
  audience: developers
---


# Efficient Coding

## Core Principle

Every action has a token cost. The goal is to solve the task with the minimum
context needed — not minimum effort, minimum *waste*. Lean context produces faster
results and better attention on what matters.

---

## 1. Context — The Biggest Cost Driver

Context bloat (sending more than the model needs) is responsible for more wasted
tokens than any other cause. Attack it first.

**Search before reading:**
- Use Grep/Glob to find the exact file and line range before opening anything.
- Read only the section you need with `offset` + `limit`, not the whole file.
- Never dump entire directories or large files into context speculatively.

**Read each file at most once per task:**
- If a file is already in context, reuse that knowledge. Don't re-read it.
- Exception: re-read only if the file was modified since you last read it.

**Phase separation:**
- Do discovery (reading, searching, understanding) first, then switch to implementation.
- Don't interleave exploration and editing — stale discovery context charges you on every subsequent turn.

**Precision over coverage:**
- If you only need to understand a function, read that function — not the whole module.
- If you only need a type signature, search for it — don't open the file.

---

## 2. Tool Usage — Eliminate Round-Trip Waste

**Batch independent calls:**
- When multiple files, searches, or commands are needed and don't depend on each other,
  issue all calls in a single response — not one at a time.
- Example: reading 3 unrelated files → one response with 3 Read calls, not 3 sequential responses.

**Prefer direct CLI over layered tools:**
- A direct shell command (Bash) is cheaper than an MCP tool that wraps it.
- Use MCP tools only when they provide genuine capability above the CLI equivalent.

**Stop speculative exploration:**
- Don't run commands "just to see what happens." Form a hypothesis first, then act.
- If the path forward is clear, execute. Don't narrate findings and then ask permission to proceed.

---

## 3. Output — Cut Everything That Doesn't Help

**No narration, no preamble, no postamble:**
- Don't explain what you're about to do — do it.
- Don't summarize what you just did — the result speaks for itself.
- Don't add "I hope this helps!" or similar closers.

**No unsolicited explanations of code:**
- If the user asked for code, write the code. Don't explain it unless asked.
- If the user asked for a fix, apply the fix. Don't describe what was wrong unless asked.

**No unsolicited comments in code:**
- Don't add inline comments or docstrings unless explicitly requested.
- The user's codebase defines the comment convention — match it, don't add to it.

**No redundant display of file contents:**
- Don't show the user the file you just read unless they asked to see it.
- Don't echo back the code you just wrote with a "Here's the updated file:" header.

---

## 4. Scope — Do Exactly What Was Asked

**Strict scope discipline:**
- Fix the bug that was reported. Don't also refactor the function it's in.
- Add the feature that was requested. Don't also clean up nearby code.
- If you notice something broken but unrelated, mention it briefly — don't fix it unasked.

**No unsolicited file creation:**
- Never create README, docs, specs, changelogs, or migration files unless explicitly requested.
- Never create test files unless the task is specifically about tests.
- Always prefer editing an existing file over creating a new one.

**No unsolicited dependency changes:**
- Don't introduce a new library or framework without confirming it's already in the project.
- Check `package.json`, `requirements.txt`, `go.mod`, etc. before assuming a library is available.

---

## 5. Code Quality — Invisible Improvements

These rules make the code better *without* adding scope or tokens.

**Match existing conventions:**
- Read 10–20 lines of surrounding code before writing. Mirror its style exactly:
  indentation, naming, spacing, quotes, import ordering, error handling patterns.
- If the codebase uses `snake_case`, don't introduce `camelCase`. Vice versa.

**Minimal, correct changes:**
- Change as few lines as possible to accomplish the task.
- Surgical edits (Edit tool, targeted replacements) beat full-file rewrites.
- Don't reformat code you didn't change.

**Verify before finishing:**
- After implementing, check if a lint or typecheck command exists (`npm run lint`,
  `ruff check`, `tsc --noEmit`, `go vet`, etc.) and run it.
- Don't mark a task done if the build is broken or types are failing.

---

## 6. Balancing Efficiency With Thoroughness

Efficiency (saving tokens) and thoroughness (being correct) are NOT in conflict — waste IS the enemy of both. A quick wrong answer costs more tokens to fix than a careful right one.

**When to be fast:**
- Simple, well-understood tasks with clear scope
- Known patterns with established conventions
- The cost of being wrong is low (typo, style fix, trivial change)

**When to be thorough:**
- The task touches production data, auth, payments, or security
- The change has wide blast radius (shared library, public API, data migration)
- Requirements are ambiguous and wrong output would be costly
- You're unfamiliar with the codebase, framework, or domain

**The tension resolved:**
- Do the MINIMUM exploration to achieve MAXIMUM confidence
- Before coding: verify your approach with a quick search (grep for patterns, check types)
- After coding: verify correctness (lint, typecheck, test the critical path)
- Don't skip verification to save tokens — a failed build costs more tokens than running the linter

**Ask once, act decisively:**
- If the request is ambiguous in a way that would lead to wrong output, ask one
  focused clarifying question before touching any file.
- Don't ask about things you can infer from the codebase — look them up.
- Don't ask multiple questions at once. Identify the most blocking ambiguity and ask only that.

**When in doubt, do the minimal thing:**
- If you're uncertain whether to also fix X while fixing Y, fix Y only.
- The user can always ask for more. Undoing unsolicited changes costs them time.

---

## Gotchas

These are the most common ways agents waste tokens — treat each as a hard rule:

- **Re-reading context**: If you already read `auth/service.ts` earlier in this session,
  don't read it again just to reference a type. It's in context.
- **Full-file reads for single symbols**: If you need the signature of `getUserById`,
  grep for it — don't open the entire `users.service.ts`.
- **Explaining before doing**: "I'll now open the file and look for the issue" costs tokens
  and adds zero value. Just open the file.
- **Padding acknowledgments**: "Great question!", "Certainly!", "Of course!" — cut all of it.
- **Hedging instructions**: "You might want to consider..." or "It could be helpful to..."
  — use direct imperatives or don't say it.
- **Restating the task**: Don't open your response with a rephrasing of what the user asked.
  Start with the action or the answer.

---

## Workflow

1. **Assess scope** — simple task: execute directly. Complex or unfamiliar: quick grep/glob discovery first.
2. **Batch exploration** — run all independent searches (grep, glob, read) in a single response. Never interleave discovery with editing.
3. **Read precisely** — use offset+limit for targeted sections. Never whole-file reads for single symbols or known locations.
4. **Implement surgically** — use Edit tool for targeted replacements. Change only lines necessary to accomplish the task.
5. **Verify minimally** — run lint/typecheck if available. Check build passes. Don't add tests unless requested.
6. **Stop cleanly** — output matches request. No summaries, no explanations, no follow-up questions.

## Error Handling

| Cause | Fix |
|-------|-----|
| Context bloat from repeated reads | Track what's already in session context. Re-read only if file was modified since last read. |
| Stale context from interleaved discovery/editing | Separate exploration phase from implementation phase completely. |
| Tool round-trip waste from sequential calls | Batch all independent grep, glob, read, and bash calls into one response. |
| Speculative command execution | Form a hypothesis before running any command. Never run "just to see." |
| Unwanted file or dependency creation | Always prefer editing existing files. Check package.json/requirements.txt before adding deps. |
| Lint/typecheck failure discovered late | Run verification commands before marking any task done. |
| Scope creep into unrelated refactoring | Fix only what was asked. Mention unrelated issues briefly but never fix unasked. |

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| Full-file reads for single symbols | Wastes context on irrelevant code | Grep for the symbol, read only the section containing it |
| "I'll now open the file to..." narration | Costs tokens, adds zero value | Just open the file and proceed |
| Re-reading files already in session context | Duplicate context, wasted tokens | Trust session history. Re-read only if modified. |
| Padding acknowledgments ("Great question!") | Filler that costs tokens | Start with the action or answer directly |
| Creating new files for small changes | Fragments the codebase unnecessarily | Edit existing files with surgical precision |
| Explaining code after writing it unprompted | Unsolicited output wastes tokens | Only explain if user explicitly asks |
| Running speculative commands with no hypothesis | Wastes tool calls and tokens | Form hypothesis, then act decisively |

## Checklist

- [ ] Token budget estimated before starting the task
- [ ] File read once, not re-read — context reused from previous reads
- [ ] Batch independent tool calls into single message
- [ ] Only relevant sections read (head/tail/offset), not entire files
- [ ] Verify output is minimal — no preamble, summary, or commentary

## Sources

- Google Engineering Practices — "Code Review: Small CLs" (google.github.io/eng-practices)
- Kent Beck — "Tidy First?" (O'Reilly, 2023)
- Martin Fowler — "Refactoring" (Addison-Wesley, 2nd Edition)
- John Ousterhout — "A Philosophy of Software Design" (Yaknyam Press)
- Hunt & Thomas — "The Pragmatic Programmer" (Addison-Wesley, 20th Anniversary)
- Paul Graham — "Succinctness is Power" (paulgraham.com)
- Greg Wilson — "Teaching Tech Together" (teachtogether.tech)
