# 職人 · Shokunin

[![CI](https://github.com/EliasOulkadi/shokunin/actions/workflows/ci.yml/badge.svg)](https://github.com/EliasOulkadi/shokunin/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)
[![Windows](https://img.shields.io/badge/Windows-11-0078D6?logo=windows)](https://www.microsoft.com/windows)
[![Linux](https://img.shields.io/badge/Linux-FCC624?logo=linux&logoColor=black)](https://github.com/EliasOulkadi/shokunin)
[![OpenCode](https://img.shields.io/badge/OpenCode-1.14-6B46C1?logo=openai)](https://opencode.ai)
[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://github.com/EliasOulkadi/shokunin/graphs/commit-activity)

**AI Engineering Ecosystem** 37 skills, ChromaDB memory, MCP servers, automations. Zero cost, open source.

> *職人 (shokunin) means artisan in Japanese. These skills aim for that standard: every detail crafted, every edge case handled, every workflow automated.*

```powershell
# One-command install (Windows)
irm https://raw.githubusercontent.com/EliasOulkadi/shokunin/master/install.ps1 | iex
```

```bash
# One-command install (Linux)
bash <(curl -sL https://raw.githubusercontent.com/EliasOulkadi/shokunin/master/install.sh)
```

## Ecosystem

```
OpenCode + VS Code + WezTerm
  37 skills + superpowers plugin + 4 subagents
  MCP servers: filesystem, fetch, memory + ChromaDB
  AI: NVIDIA, OpenAI, Anthropic, Ollama
  Windows (PowerShell) + Linux (bash/zsh)
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

Each skill includes: trigger-optimized descriptions, procedural workflows, error handling, production checklists, anti-patterns, cited sources. Advanced skills also include executable scripts, reference files, and reusable templates.

## What You Get

| Component | Purpose |
|-----------|---------|
| **37 SKILL.md files** | Domain expertise that auto-activates |
| **OpenCode config** | MCP servers, subagents, superpowers plugin |
| **ChromaDB memory** | Persistent context across sessions (v4.0, 3-layer capture, structured data) |
| **CLAUDE.md + AGENTS.md** | Mandatory memory instructions: context search on every start |
| **Auto-save wrapper** | Console buffer capture on exit, saves to ChromaDB + markdown |
| **Memory test suite** | One-command validation of all memory components |
| **PowerShell profile** | 20+ aliases, oh-my-posh, autocomplete |
| **Windows scheduler** | Weekly cleanup and memory backup |
| **Bookmarklet** | Send web pages to OpenCode |
| **Dashboard** | Local ecosystem status viewer |
| **WezTerm config** | GPU terminal with Catppuccin theme |
| **SQLite templates** | Zero-install local database |

## Requirements

### Minimum
| Dependency | Version | Notes |
|------------|---------|-------|
| **OS** | Windows 10/11 or Linux | **Linux:** requires `bash` 4+, not `sh`. Run `bash --version` to verify. |
| **Node.js** | ≥ 18 | Includes `npm`. Run `node --version` to verify. |
| **Python** | ≥ 3.11 | Run `python3 --version` to verify. |
| **Git** | ≥ 2.x | Run `git --version` to verify. |

### Linux — additional dependencies
| Dependency | Why | Install |
|------------|-----|---------|
| `python3-pip` | Required for ChromaDB. Not included by default on Ubuntu/Debian. | `sudo apt-get install -y python3-pip` |
| `build-essential` + `python3-dev` | Needed to compile ChromaDB native wheels on some systems. | `sudo apt-get install -y build-essential python3-dev` |
| `python-is-python3` | Some config files use `python` but Debian/Ubuntu only ship `python3`. | `sudo apt-get install -y python-is-python3` |
| `cron` daemon | Required for automated weekly maintenance (optional). | `sudo systemctl enable --now cron` |

> **Ubuntu 24.04+:** PEP 668 blocks global `pip install` by default. The installer handles this automatically with `--break-system-packages`. If you run into issues, see the Troubleshooting section below.

### Windows — additional notes
- PowerShell 5.1+ required. Run `$PSVersionTable.PSVersion` to verify.
- Execution policy must allow scripts: `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser`

### Demos (skill kami)
- [Equity Report](assets/demos/demo-tesla.pdf) - Tesla Q1 2026 financial report
- [Slides](assets/demos/demo-agent-slides.pdf) - "The Agent You Don't Know" keynote
- [Resume](assets/demos/demo-musk-resume.pdf) - Executive resume example
- [Portfolio](assets/demos/demo-kaku.pdf) - Project portfolio

## Quick Start

**Windows:**
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

**Linux:**
```bash
# 1. Install
bash <(curl -sL https://raw.githubusercontent.com/EliasOulkadi/shokunin/master/install.sh)

# 2. Get a free NVIDIA API key
#    https://build.nvidia.com/

# 3. Reload shell and start OpenCode
source ~/.bashrc
opencode
```

## Memory System v4.0

Three layers ensure no context is lost between sessions:

1. **Agent-driven saves** CLAUDE.md forces checkpoints every 3-5 turns, and after each decision, file change, or command.
2. **Console buffer capture** The wrapper expands the buffer to 9999 lines and reads it when OpenCode exits.
3. **Dual storage** ChromaDB (semantic search) + markdown files (grep-able text backups).

All data stored at `~/.shokunin/memory/`. No cloud, no telemetry, no subscriptions.

```powershell
# Test the memory system
.\test-memory.ps1

# Validate all memory components
.\memory-healthcheck.ps1
```

- [Enterprise White Paper](docs/Shokunin-Enterprise-White-Paper.pdf) - Full ecosystem overview and architecture
- [Ecosystem Guide](docs/Shokunin-Ecosystem-Guide.pdf) - Complete ecosystem walkthrough
- [v4.0 Changelog](docs/Shokunin-v4.0-Changelog.pdf) - What's new in version 4.0
- [v4.2 Linux Port](docs/Shokunin-v4.2-Linux-Port.pdf) - Linux porting notes

## Troubleshooting

| Problem | Cause | Solution |
|---------|-------|----------|
| Installer hangs on `Continue? (y/n)` | `read -p` blocks in non-interactive mode | Use `printf 'y\n\n' \| bash install.sh` or run directly in a terminal |
| `pip3: command not found` | `python3-pip` not installed | `sudo apt-get install python3-pip` |
| `externally-managed-environment` | PEP 668 on Ubuntu 24.04+ | The installer applies `--break-system-packages` automatically. If it fails, run manually: `python3 -m pip install chromadb --break-system-packages` |
| `Cannot uninstall typing_extensions` | Debian-packaged package missing RECORD file | `python3 -m pip install chromadb --break-system-packages --ignore-installed typing-extensions` |
| MCP memory: `"python" not found` | System uses `python3`, not `python` | `sudo apt-get install python-is-python3` or `sudo ln -s $(which python3) /usr/local/bin/python` |
| MCP fetch/filesystem: `Connection closed` | OpenCode runtime config issue | Verify `node` is in PATH and check `~/.config/opencode/opencode.json` |
| `npm install -g opencode` fails | Missing npm or insufficient permissions | Install npm first, or run `sudo npm install -g opencode` |
| ChromaDB fails to install | Missing build dependencies | `sudo apt-get install -y build-essential python3-dev` |

## Commands

After installation, run `opencode` in any project directory. The AI agent loads your skills, searches memory from past sessions, and is ready to work.

**Windows:**
```powershell
.\run-opencode.ps1                    # Start AI session (with memory capture)
opencode                              # Start AI session (simple mode)
.\memory-healthcheck.ps1              # Validate all memory components
gst, ga, gc "msg", gp, gl            # Git aliases
ni, nrd, nrb, nt                       # npm aliases
dps, dlog                               # Docker aliases
mkcd, touch, which, admin             # Utility aliases
```

**Linux:**
```bash
opencode                              # Start AI session (with memory capture)
./memory-healthcheck.sh               # Validate all memory components
gst, ga, gc "msg", gp, gl            # Git aliases
ni, nrd, nrb, nt                       # npm aliases
dps, dlog                               # Docker aliases
mkcd, which                           # Utility functions
```

## Compatibility

The ecosystem works across multiple AI coding runtimes. The core (skills, memory, scripts) is runtime-agnostic. Only MCP server configuration and instruction files differ.

| Runtime | Skills | Memory | MCP | Scripts | Config template |
|---------|--------|--------|-----|---------|-----------------|
| **OpenCode** | ✅ Native | ✅ Native | ✅ .pack/opencode.json | ✅ .ps1 + .sh | Built-in |
| **Claude Code** | ✅ Reads SKILL.md | ✅ Via MCP | ✅ .pack/templates/claude-code.json | ✅ .ps1 + .sh | Copy template |
| **Cline** (VS Code) | ✅ Reads SKILL.md | ✅ Via MCP | ✅ .pack/templates/cline-settings.json | ✅ .ps1 + .sh | Add to settings.json |
| **Cursor** | ✅ Reads SKILL.md | ✅ Via rules | ✅ .pack/templates/cursor-mcp.json | ✅ .ps1 + .sh | Copy to .cursor/ |
| **Continue.dev** | ✅ Reads SKILL.md | ✅ Via rules | ✅ .pack/templates/continue-config.yaml | ✅ .ps1 + .sh | Copy to .continue/ |
| **Windsurf** | ✅ Reads SKILL.md | ✅ Via rules | ⬜ Via UI only | ✅ .sh | Add .windsurf/rules/ |

### Setup per runtime

**Claude Code:** Copy `.pack/templates/claude-code.json` to project root as `claude.json` or configure via CLAUDE.md.

**Cline:** Add the `mcpServers` block from `.pack/templates/cline-settings.json` to VS Code's `settings.json`. Copy `.pack/rules/cline-memory.md` as `.clinerules`.

**Cursor:** Configure MCP servers in Cursor Settings > MCP using `.pack/templates/cursor-mcp.json`. Copy `.pack/rules/cursor-memory.mdc` to `.cursor/rules/memory.mdc`.

**Continue.dev:** Copy `.pack/templates/continue-config.yaml` to `.continue/config.yaml`. Add `.pack/rules/continue-memory.md` to `.continue/rules/`.

**Windsurf:** Configure MCP servers in Settings > Cascade > MCP Servers. Copy `.pack/rules/windsurf-memory.md` to `.windsurf/rules/memory.md`.

## Links

- **GitHub** github.com/EliasOulkadi/shokunin
- **Docs** github.com/EliasOulkadi/shokunin#readme

## License

MIT free as in freedom, free as in zero cost.
