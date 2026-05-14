# 職人 · Shokunin

[![CI](https://github.com/EliasOulkadi/shokunin/actions/workflows/ci.yml/badge.svg)](https://github.com/EliasOulkadi/shokunin/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)
[![Windows](https://img.shields.io/badge/Windows-11-0078D6?logo=windows)](https://www.microsoft.com/windows)
[![OpenCode](https://img.shields.io/badge/OpenCode-1.14-6B46C1?logo=openai)](https://opencode.ai)
[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://github.com/EliasOulkadi/shokunin/graphs/commit-activity)


**AI Engineering Ecosystem** — 35 skills, ChromaDB memory, MCP servers, and automations. Zero cost, open source.

> *職人 (shokunin) means artisan in Japanese. These skills aim for that standard — every detail crafted, every edge case handled, every workflow automated.*

```powershell
# One-command install (Windows)
irm https://raw.githubusercontent.com/EliasOulkadi/shokunin/master/install.ps1 | iex
```

## Ecosystem

```
┌─────────────────────────────────────────────────┐
│  TERMINAL / EDITOR                              │
│  OpenCode · VS Code + Cline · WezTerm           │
├─────────────────────────────────────────────────┤
│  AGENT LAYER                                    │
│  35 skills · superpowers plugin · subagents     │
├─────────────────────────────────────────────────┤
│  INFRASTRUCTURE                                 │
│  MCP (filesystem, fetch, memory) · ChromaDB     │
├─────────────────────────────────────────────────┤
│  AI PROVIDERS                                   │
│  NVIDIA · OpenAI · Anthropic · Ollama (any model)         │
├─────────────────────────────────────────────────┤
│  SYSTEM (Windows 11)                            │
│  PowerShell profile · Task Scheduler · Cleanup  │
└─────────────────────────────────────────────────┘
```

## Skills

| Domain | Skills | Version |
|--------|--------|---------|
| **Infrastructure** | docker, kubernetes, terraform, ci-cd, db-admin | v3.0 |
| **Backend** | auth-architect, api-forge, db-sculptor, error-handler | v3.0 |
| **Frontend** | component-forge, responsive-engine, motion-craft, landing-craft, ui-ux-pro-max | v3.0 |
| **Mobile** | flutter, react-native | v3.0 |
| **Quality** | test-commander, performance-profiler | v3.0 |
| **Content & Business** | communication, content-marketing, business-proposals, seo-geo, translate-craft | v3.0 |
| **Documents** | kami (PDF generator), portfolio-auto | v3.0 |
| **Productivity** | git-workflow, windows-powershell, strategy, design, documentation, runbook-gen, finance, legal-counsel | v3.0 |
| **System** | memory, chromadb, whendone-plus, session-logger | v4.0 |

Each skill includes: trigger-optimized descriptions, procedural workflows, error handling, production checklists, anti-patterns, and cited sources. Advanced skills also include executable scripts, reference files, and reusable templates.

## What You Get

| Component | Purpose |
|-----------|---------|
| **35 SKILL.md files** | Domain expertise that auto-activates |
| **OpenCode config** | MCP servers, subagents, superpowers plugin |
| **ChromaDB memory** | Persistent context across sessions (v4.0: 3-layer capture, structured data) |
| **CLAUDE.md + AGENTS.md** | Mandatory memory instructions: context search on every start |
| **Auto-save wrapper** | Console buffer capture on exit, saves to ChromaDB + markdown |
| **Memory test suite** | One-command validation of all memory components |
| **PowerShell profile** | 20+ aliases, oh-my-posh, autocomplete |
| **Windows scheduler** | Weekly cleanup & memory backup |
| **Bookmarklet** | Send web pages to OpenCode |
| **Dashboard** | Local ecosystem status viewer |
| **WezTerm config** | GPU terminal with Catppuccin theme |
| **SQLite templates** | Zero-install local database |

## Requirements

- Windows 10/11
- Node.js 18+
- Python 3.11+
- Git

## Quick Start

```powershell
# 1. Install
irm https://raw.githubusercontent.com/EliasOulkadi/shokunin/master/install.ps1 | iex

# 2. Get a free NVIDIA API key
#    https://build.nvidia.com/

# 3. Start OpenCode (with memory capture)
.\run-opencode.ps1

# Or without memory capture (simple mode):
opencode
```

## Memory System v4.0

Three layers ensure no context is lost between sessions:

1. **Agent-driven saves** — CLAUDE.md forces checkpoints every 3-5 turns, and after each decision, file change, or command.
2. **Console buffer capture** — The wrapper expands the buffer to 9999 lines and reads it when OpenCode exits.
3. **Dual storage** — ChromaDB (semantic search) + markdown files (grep-able text backups).

All data stored at `~/.shokunin/memory/`. No cloud, no telemetry, no subscriptions.

```powershell
# Test the memory system
.\test-memory.ps1
```

## PDF Guides

- **Quick Start**: github.com/EliasOulkadi/shokunin/blob/master/docs/Shokunin-Quickstart.pdf
- **Ecosystem Guide**: github.com/EliasOulkadi/shokunin/blob/master/docs/Shokunin-Ecosystem-Guide.pdf
- **v4.0 Changelog**: github.com/EliasOulkadi/shokunin/blob/master/docs/Shokunin-v4.0-Changelog.pdf

## Commands

After installation, run `.\run-opencode.ps1` (with memory capture) or `opencode` (simple mode) in any project directory. The AI agent loads your skills, searches memory from past sessions, and is ready to work.

```powershell
.\run-opencode.ps1                    # Start AI session (with memory capture)
opencode                              # Start AI session (simple mode)
gst, ga, gc "msg", gp, gl            # Git aliases
ni, nrd, nrb, nt                       # npm aliases
dps, dlog                               # Docker aliases
mkcd, touch, which, admin             # Utility aliases
```

## Links

- **GitHub**: github.com/EliasOulkadi/shokunin
- **Docs**: github.com/EliasOulkadi/shokunin#readme

## License

MIT — free as in freedom, free as in zero cost.





