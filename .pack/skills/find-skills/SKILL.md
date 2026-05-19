---
name: find-skills
description: Search the agent skills ecosystem to discover and install skills that extend AI coding agent capabilities. Use when user asks "how do I do X" (X being a common task), "find a skill for X", "is there a skill that can...", or expresses interest in extending agent capabilities. Triggers on "find a skill", "install a skill", "skill for [task]", "can you do X", "I need help with [domain]", "how do I [task]". Do NOT use when user has explicitly asked to proceed without a skill, or when the task is better handled by agent's built-in capabilities (file operations, git, basic coding).
triggers:
  - "find a skill"
  - "install a skill"
  - "skill for"
  - "is there a skill"
  - "how do I"
  - "search skills"
  - "discover skills"
  - "skill ecosystem"
  - "available skills"
  - "list skills"
negatives:
  - "create a skill"
  - "write a skill"
  - "edit a skill"
  - "skill development"
license: MIT
compatibility: opencode
metadata:
  workflow: tooling
  audience: developers
  version: "1.0.0"
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

## Error Handling

| Cause | Fix |
|-------|-----|
| `npx skills find` returns zero results for a valid query | Query may be too specific or use jargon not in skill descriptions. Broaden to the domain term (e.g., "testing" instead of "jest snapshot serializers"). Try 2-3 synonym variations. |
| `npx skills add` fails with "package not found" | Verify the package spec format: `<owner>/<repo>@<skill-name>`. Check https://skills.sh/ for the exact package path. GitHub rate limits may apply — retry after 60s. |
| Installed skill does not activate (agent ignores it) | Skill description might not match the user's phrasing. Check the skill's `description` field in its SKILL.md frontmatter. It should use trigger phrases the user naturally says. |
| `npx skills check` reports updates but `add` re-installs same version | The CLI caches resolution metadata. Run `npx skills check --refresh` to force re-resolution. If still stuck, uninstall with `npx skills remove <package>` and re-add. |
| Skills website (skills.sh) is unreachable | GitHub Pages may be down or DNS blocked. Fall back to direct GitHub search: `gh search repos --topic agent-skill <query>`. Present results from the CLI search as primary alternative. |
| User requests a skill for a niche domain with no ecosystem coverage | No skill exists yet. Offer to help directly. Propose creating a custom skill with `npx skills init`. Show the skill-creator workflow if the user wants to build and publish it. |
| Skill install conflicts with an existing skill of the same name | Two skills share a namespace. The CLI will refuse to overwrite. Uninstall the old one first: `npx skills remove <old-package>`. Verify the old skill isn't needed before removing. |

## Skill Discovery Methodology

### Finding skills in the ecosystem
```bash
# List installed skills with version + line count
npx skills list

# Search marketplace by keyword
npx skills find "docker" "kubernetes" "security"

# Check what's available
npx skills check
```

### Quality Evaluation Framework

Rate skills on 5 criteria before installing:
1. **Trigger clarity**: Does the description clearly define when to activate?
2. **Workflow completeness**: Numbered steps or procedural sections?
3. **Error handling**: Does it document common failures and fixes?
4. **Sources cited**: Verifiable references or just opinions?
5. **Anti-patterns**: Explicit warnings about what NOT to do?

Minimum threshold for production: 4 of 5 criteria met.

### Installation Troubleshooting

| Error | Cause | Fix |
|-------|-------|-----|
| `SKILL.md not found` | Directory missing from registry | Check if skill exists at source repository |
| `permission denied` | Plugin directory not writable | `chmod 755 ~/.config/opencode/skills/` |
| `skill already installed` | Version conflict or duplicate | `npx skills remove <name>` then reinstall |
| `trigger not matching` | Description too generic or too narrow | Edit frontmatter `description:` field and re-test |
| `npm ERR!` during install | npm registry issue or network | Retry. If persistent, clone manually from GitHub |

## Checklist

- [ ] Description matching first (the skill's `description` field against the task)
- [ ] At least 2-3 synonym/alternative queries tried before concluding "no skill"
- [ ] SKILL.md content read before recommending (descriptions can be misleading)
- [ ] Compatibility confirmed for the user's platform/tools
- [ ] User consent obtained before installing any skill

## Sources

- Skills CLI documentation (skills.sh/docs) — package manager usage, publish flow, and repository structure
- Vercel Agent Skills repository (github.com/vercel-labs/agent-skills) — reference skill implementations with 100K+ installs
- Anthropic Skills specification (github.com/anthropics/skills) — skill format, metadata schema, and compatibility guidelines
- Zencoder Agent Skills repository (github.com/zencoderai/skills) — OSS security and workflow skills reference
- npm package registry documentation (docs.npmjs.com) — npx resolution, caching, and version management
- GitHub Search API documentation (docs.github.com/en/rest/search) — topic-based repository discovery as fallback
- "The Design of Everyday Things" by Don Norman (Basic Books, 2013) — discoverability principles applied to skill ecosystem UX

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| Recommending a skill without checking install count or maintenance status | Abandoned skills with 0 installs waste the user's time and may contain broken or outdated instructions. | Check install count (>1K preferred), last update (<6 months), and source reputation before presenting. |
| Installing a skill the user didn't explicitly agree to install | Skills modify agent behavior. Installing without consent breaks trust. | Always present the skill first, wait for explicit confirmation, then install. Never auto-install. |
| Searching only once and giving up when zero results appear | First query may use the wrong terminology or be too narrow. | Try 2-3 synonym variations and broader domain terms before concluding no skill exists. |
| Suggesting a skill when the task is trivial and built-in capabilities suffice | Overhead of installing and loading a skill for a 30-second task wastes tokens and attention. | Only suggest skills for recurring patterns, complex domains, or tasks the user explicitly flagged as needing a skill. |
| Evaluating skill quality by description alone without reading the actual content | Descriptions are marketing. The SKILL.md content determines actual usefulness. | After identifying candidates, read the skill's SKILL.md on GitHub before presenting. Check for concrete patterns, code examples, and workflow steps. |
| Assuming a skill works on all platforms when it's only tested on one | A skill written for Claude Code may fail on OpenCode or Gemini CLI due to tool name differences. | Check the skill's `compatibility` metadata field. If missing, test the first step manually before recommending. |
