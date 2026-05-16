---
name: find-skills
description: Search the agent skills ecosystem to discover and install skills that extend AI coding agent capabilities. Use when user asks "how do I do X" (X being a common task), "find a skill for X", "is there a skill that can...", or expresses interest in extending agent capabilities. Triggers on "find a skill", "install a skill", "skill for [task]", "can you do X", "I need help with [domain]", "how do I [task]". Do NOT use when user has explicitly asked to proceed without a skill, or when the task is better handled by agent's built-in capabilities (file operations, git, basic coding).
license: MIT
compatibility: opencode
metadata:
  workflow: tooling
  audience: developers
---

Help users discover and install skills from the open agent skills ecosystem.

## What is the Skills CLI?

The Skills CLI (`npx skills`) is the package manager for agent skills:

- `npx skills find [query]` - Search for skills
- `npx skills add <package>` - Install from GitHub
- `npx skills check` - Check for updates
- `npx skills init [name]` - Scaffold a new skill

Browse at: https://skills.sh/

## Workflow

### Step 1: Understand what they need

Identify: domain (React, testing, DevOps) → specific task (writing tests, creating animations) → likelihood a skill exists.

### Step 2: Check the leaderboard first

Before running CLI: check https://skills.sh/ for well-known skills.

Top sources:
- `vercel-labs/agent-skills` — React, Next.js, web design (100K+ installs)
- `anthropics/skills` — Frontend design, document processing (100K+ installs)
- `zencoderai/skills` — OSS security, git gate (50K+ installs)

### Step 3: Search

```bash
npx skills find [query]
```

Examples:
- "how do I make my React app faster" → `npx skills find react performance`
- "help with PR reviews" → `npx skills find pr review`
- "create a changelog" → `npx skills find changelog`

### Step 4: Verify quality

- **Install count**: Prefer 1K+. Be cautious under 100.
- **Source reputation**: Official sources (`vercel-labs`, `anthropics`, `microsoft`) over unknown authors.
- **GitHub stars**: Source repo < 100 stars → treat with skepticism.

### Step 5: Present options

Include: skill name, what it does, install count, source, install command.

```
I found a skill that might help! "react-best-practices" provides
React/Next.js performance optimization guidelines from Vercel Engineering.
(185K installs)

To install:
npx skills add vercel-labs/agent-skills@react-best-practices

Learn more: https://skills.sh/vercel-labs/agent-skills/react-best-practices
```

### Step 6: Install (if user agrees)

```bash
npx skills add <owner/repo@skill> -g -y
```

`-g` installs globally, `-y` skips confirmation.

## Common Categories

| Category | Example Queries |
|----------|----------------|
| Web Development | react, nextjs, typescript, css, tailwind |
| Testing | testing, jest, playwright, e2e |
| DevOps | deploy, docker, kubernetes, ci-cd |
| Documentation | docs, readme, changelog, api-docs |
| Code Quality | review, lint, refactor, best-practices |
| Design | ui, ux, design-system, accessibility |
| Productivity | workflow, automation, git |

## Skill Quality Assessment

When presenting a skill, assess these dimensions:

| Dimension | What to check | Red flags |
|-----------|--------------|-----------|
| Maintenance | Last update < 6 months? | No updates in 1+ year |
| Depth | Has examples, not just description? | Single paragraph, no code |
| Compatibility | Supports your agent? | Only tested on one platform |
| Specificity | Solves your exact problem? | Generic content without actionable patterns |

## Fallback: When No Skills Found

Acknowledge, offer direct help, suggest creating a custom skill:

```
I searched for skills related to "xyz" but didn't find matches.
I can still help with this task directly.

If this is something you do often, create your own skill:
npx skills init my-xyz-skill
```
