---
name: enhance-prompt
description: Improve user prompts for clearer, more specific, and more effective AI output. Use when user gives a vague, underspecified, or compound request that would produce weak or unfocused results. Triggers on "improve this prompt", "make this better", vague questions, compound requests, or prompts missing constraints, format, or examples. Do NOT use when user asks a direct, well-specified question or gives clear instructions.
license: MIT
compatibility: opencode
metadata:
  workflow: prompt-engineering
  audience: developers
---

Analyze the user's raw prompt through 7 dimensions. For each dimension, identify what is missing and improve it.

Return the enhanced prompt as a complete rewrite, plus a brief changelog of what was changed and why.

## The 7 Dimensions

### 1. Clarity

**Goal**: Remove ambiguity. Every noun and verb should have one interpretation.

| Issue | Example | Fix |
|-------|---------|-----|
| Vague nouns | "the thing" | Name the thing explicitly |
| Ambiguous pronouns | "it", "they" | Repeat the noun or rephrase |
| Missing subject | "make it faster" | Faster than what? At what? |
| Implicit context | "as usual" | Spell out what "usual" means |

**Diagnostic**: Could someone with zero context execute this? If not, add context.

### 2. Specificity

**Goal**: Replace general requests with concrete, measurable parameters.

| Dimension | Vague | Specific |
|-----------|-------|----------|
| Scope | "help with this code" | "refactor the auth middleware in `src/middleware/auth.ts`" |
| Quantity | "some options" | "exactly 3 options ranked by cost" |
| Criteria | "better" | "faster than 200ms p95, < 10KB bundle impact" |
| Audience | "for users" | "for frontend devs with React experience but no backend knowledge" |
| Constraints | "reasonably" | "under $50/month, < 2s response time" |

### 3. Constraints

**Goal**: Define hard boundaries. What is IN and OUT of scope.

Always include both positive constraints (what to do) and negative constraints (what NOT to do).

| Constraint Type | Example |
|-----------------|---------|
| Technology | "React 18+, no class components" |
| Resource | "must work offline, no external API calls" |
| Time | "must load in < 1.5s on 3G" |
| Compatibility | "must support Safari 15+ and Firefox 100+" |
| Compliance | "must be GDPR-compliant, no analytics without consent" |

### 4. Format

**Goal**: Specify the exact structure of the output.

| Format | When to use |
|--------|-------------|
| Bullet list | Comparing options, enumerating items |
| Table | Structured data with consistent columns |
| Code block | Code output, config files, CLI commands |
| JSON/YAML | Machine-parseable output |
| Markdown | Documented prose with headers |
| Mermaid | Diagrams, flowcharts, architecture |
| Shell commands | Copy-paste ready sequences |

Specify length: "max 200 words", "3-5 bullet points", "under 50 lines of code".

### 5. Examples

**Goal**: One example is worth 100 words of description.

| What examples clarify | Example |
|-----------------------|---------|
| Tone | "Like this: 'Hey team, quick update on the API change...'" |
| Structure | "Input: `GET /users`, Output: `{ data: [...], meta: {...} }`" |
| Edge cases | "What about when `email` field is null?" |
| Quality bar | "At least as thorough as the existing tests in `__tests__/`" |

### 6. Tone

**Goal**: Match the output tone to the audience and medium.

| Medium | Default Tone |
|--------|-------------|
| Internal team message | Direct, informal, no fluff |
| Client email | Professional-cordial, concise |
| Documentation | Neutral, precise, complete |
| Bug report | Factual, minimal, reproducible |
| Code review | Constructive, specific, actionable |
| API design | Consistent, predictable, self-documenting |

### 7. Iteration Signal

**Goal**: Include a signal about how the user wants to iterate.

| Signal | Meaning |
|--------|---------|
| "Start here, we'll refine" | Produce a reasonable first draft |
| "Make it production-ready" | Higher quality bar, handle edge cases |
| "Give me options" | Present 2-3 approaches with trade-offs |
| "Be thorough" | Include rationale, alternatives, risks |
| "Just the code" | Minimal explanation, focused output |

## Enhancement Workflow

### Step 1: Diagnose

Run through the 7 dimensions. Identify which are weak or missing in the user's prompt. Most weak prompts fail on 3+ dimensions simultaneously.

### Step 2: Rewrite

Produce a complete rewrite of the prompt. Do NOT annotate the original — replace it entirely.

### Step 3: Changelog

After the rewritten prompt, add a `**Changes made:**` section with 1-2 bullet points per dimension that was improved.

```
**Changes made:**
- Clarity: Replaced "the thing" with "JWT access token"
- Specificity: Added framework constraint (React 18+)
- Constraints: Added negative constraint "no external auth provider"
- Format: Specified code block with TypeScript
- Tone: Shifted from passive to imperative
```

## Anti-Patterns

| Anti-pattern | Why it fails |
|--------------|-------------|
| Prompt too short (< 10 words) | Model fills gaps with assumptions, often wrong |
| Compound request ("do X and Y and Z") | Models optimize for the first instruction, ignore the rest |
| No output format | Model chooses format, rarely the most useful one |
| No audience | Model defaults to generic explanation, too basic or too advanced |
| Vague success criteria | Cannot verify output quality objectively |
| "Make it good" | Good is subjective. Define measurable quality criteria. |

## Examples

### Example 1: Bug report prompt

**Before:**
```
Fix this bug in the login page.
```

**After:**
```
Debug login failure in the staging environment.

Context:
- URL: https://staging.example.com/login
- Browser: Chrome 120, macOS 14.2
- Error: "401 Unauthorized" after entering valid credentials
- What should happen: redirect to /dashboard
- What actually happens: stays on /login with error toast

Investigate:
1. Check network tab for the auth endpoint response
2. Verify the JWT token is being set in cookies
3. Compare working vs broken session cookies

Output: root cause + exact fix (file, line, diff format).
```

### Example 2: Feature request prompt

**Before:**
```
Add dark mode.
```

**After:**
```
Implement dark mode for the user settings page.

Stack: Next.js 14 + Tailwind CSS + next-themes

Requirements:
- Toggle in /settings/appearance
- Persist choice in localStorage
- Respect system preference on first visit
- Transition animations (300ms ease)
- All existing components must support both modes

Exclusions:
- Do not add new dependencies beyond next-themes
- Do not redesign existing components — just adapt colors

Output: 
1. List of files to create/modify
2. Key implementation decisions
3. Code changes in diff format
