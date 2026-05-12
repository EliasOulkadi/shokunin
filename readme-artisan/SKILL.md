---
name: readme-artisan
description: Original READMEs with personality and voice
---

Craft READMEs that people actually read. Not template filler. Based on analysis of the top 50 GitHub repositories by stars and developer audience research.

## The Hook

First paragraph answers three questions in three sentences: what is this (5 words), who is this for, why does this exist.

Bad: "A React component library for building modern user interfaces."
Good: "Buttons, modals, forms, done right. No design debt. Zero dependencies."

## The Demo

After the hook, show a 3-line code example, an ASCII diagram, or a screenshot. Never start with installation instructions. Let them SEE it first. The demo should make someone think "I want that" before they know how to install it.

## Features

Every feature must be quantified or comparative.

| Bad | Good |
|-----|------|
| Fast, lightweight, easy to use | 2KB gzipped. Zero dependencies. Works in React, Vue, and vanilla JS. |
| Full-featured API client | 3 methods. 15KB. Types included. |
| Modern CSS framework | 40 utility classes. No build step. Drop into any HTML file. |

## The Why Section

One paragraph explaining the decision behind the project. Builds trust. Helps people decide if your tradeoffs match theirs. Example: "Most form libraries are kitchen sinks. We built MinForm to do one thing well — validation — and leave rendering to you."

## Installation

```bash
npm install my-project
```

Keep it minimal. If they've gotten this far, they want to try it. Don't put walls between them and running your code.

## Quick Start

The first example should be the first thing someone would try. Copy-paste runnable. No omitted imports, no placeholders. Show the output they should expect.

## API Reference

Each export gets: name, parameters table with type/required/default/description, return value with type and description, one example.

## Tone by Project

| Project type | Tone | Anti-pattern |
|-------------|------|-------------|
| CLI tool | Direct, confident | Marketing fluff |
| Library | Helpful, thorough | Overselling |
| Design system | Opinionated | Apologetic |
| Personal project | Honest, humble | Self-deprecating |
| Company OSS | Professional, warm | Corporate jargon |
| Game/mod | Enthusiastic, playful | Dry documentation voice |
| Tutorial | Encouraging, clear | Skipping steps |

## README Sections (in order)

1. **Hook** (name + one-line description): 5 words max
2. **Demo**: screenshot, GIF, or 3-line code sample
3. **Features**: quantified benefits, 3-6 items
4. **Why**: context, tradeoffs, philosophy
5. **Installation**: one command, copy-paste
6. **Quick Start**: first thing someone would try, with expected output
7. **API Reference**: table-per-export format
8. **Contributing**: link to CONTRIBUTING.md, code of conduct
9. **License**: MIT, Apache, or standard badge
10. **Badges**: CI, coverage, version, downloads (only if they link somewhere real)

## Anti-Patterns

| Anti-pattern | Why it fails | Fix |
|-------------|-------------|-----|
| Screenshots of code instead of code blocks | Can't copy-paste | Always use markdown code blocks with syntax highlighting |
| "Coming soon" features | Looks incomplete. Ship or remove. | Remove or move to ROADMAP.md |
| Ignoring mobile rendering | Most READMEs read on phones | Test on 375px width. Keep tables simple. |
| Badges that don't link anywhere | Visual noise | Every badge links to the relevant page |
| Generated-by-Copilot look | No personality, no trust | Write the why section. Show your voice. |
| Missing prerequisites | New users hit walls immediately | List what they need before starting |
| Default README from template | Clearly unmaintained | Customize every section. Remove template comments. |
| Too many badges (badge bar > 1 line) | Looks like repo spam | Keep to CI, coverage, version, license. Max 5. |
| API docs instead of README | Overwhelming, hard to find key info | README = onboarding. API docs = reference. Separate concerns. |
| No GIF/screenshot for visual projects | Developers won't install what they can't see | Show the UI. A 10-second GIF > 100 words of description. |

## Sources

- Top 50 GitHub repos by stars analysis (React, Vue, Tailwind, etc.)
- Standard Readme specification — community standard format
- Awesome README — curated list of quality READMEs
- Make a README — README generation best practices
- GitHub docs "About READMEs"
- Artemis "How to Write a Great README"
- Monica Powell "How to Create a README That Gets You Hired"
