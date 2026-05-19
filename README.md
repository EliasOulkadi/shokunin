# 職人 · Shokunin

[![CI](https://github.com/EliasOulkadi/shokunin/actions/workflows/ci.yml/badge.svg)](https://github.com/EliasOulkadi/shokunin/actions/workflows/ci.yml)
[![Memory Tests](https://github.com/EliasOulkadi/shokunin/actions/workflows/memory-tests.yml/badge.svg)](https://github.com/EliasOulkadi/shokunin/actions/workflows/memory-tests.yml)
[![Release](https://github.com/EliasOulkadi/shokunin/actions/workflows/release.yml/badge.svg)](https://github.com/EliasOulkadi/shokunin/actions/workflows/release.yml)

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)
[![Windows](https://img.shields.io/badge/Windows-11-0078D6?logo=windows)](https://www.microsoft.com/windows)
[![Linux](https://img.shields.io/badge/Linux-FCC624?logo=linux&logoColor=black)](https://github.com/EliasOulkadi/shokunin)
[![OpenCode](https://img.shields.io/badge/OpenCode-6B46C1?logo=openai)](https://opencode.ai)
[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://github.com/EliasOulkadi/shokunin/graphs/commit-activity)
[![Changelog](https://img.shields.io/badge/Changelog-CHANGELOG.md-blue)](CHANGELOG.md)
[![Architecture](https://img.shields.io/badge/Architecture-docs/ARCHITECTURE.md-blue)](docs/ARCHITECTURE.md)

**62 engineering skills + persistent AI memory. One command. Zero servers.**

**v4.2.3** adds freshness decay (time-weighted memory), claim verification (verify_file_path MCP tool), 9 MCP tools (was 8), and 30+ bug fixes.

> *職人 (shokunin) means artisan in Japanese. These skills aim for that standard: every detail crafted, every edge case handled, every workflow automated.*

```powershell
# One-command install (Windows)
irm https://raw.githubusercontent.com/EliasOulkadi/shokunin/master/install.ps1 | iex
```

```bash
# One-command install (Linux)
bash <(curl -sL https://raw.githubusercontent.com/EliasOulkadi/shokunin/master/install.sh)
```

```powershell
# Skills-only install (Windows — no ChromaDB, no MCP)
irm https://raw.githubusercontent.com/EliasOulkadi/shokunin/master/install-skills.ps1 | iex
```

```bash
# Skills-only install (Linux)
bash <(curl -sL https://raw.githubusercontent.com/EliasOulkadi/shokunin/master/install-skills.sh)
```

## Ecosystem

```
OpenCode + VS Code + WezTerm
  62 skills + superpowers plugin + 4 subagents
  MCP servers: filesystem, fetch, memory + ChromaDB
  AI: OpenCode Go (default) + Ollama (local fallback)
  Update system: declarative manifest with drift detection
  Windows (PowerShell) + Linux (bash)
```

## Skills

62 skills across 10 domains. Each skill teaches the agent how to handle a specific domain: with decision tables, error patterns, production checklists, anti-patterns, and cited sources. Not generic prompts. Real engineering guides.

The Docker skill is 1,422 words with a multi-stage Node.js template, BuildKit cache optimization, distroless base images, and CVE scanning. The auth skill references OWASP directly. The database one has real EXPLAIN ANALYZE output. Frontend skills include Emil Kowalski patterns (Sonner, Vaul), Paul Bakaus principles (Impeccable), and Leon Lin variance engines (Taste). Skills are validated by CI on every push: frontmatter, workflow, error handling, sources. All mandatory.

| Domain | Skills | Version |
|--------|--------|---------|
| **Infrastructure** | docker, kubernetes, terraform, ci-cd, db-admin | v4.0 |
| **Backend** | auth-architect, api-forge, db-sculptor, error-handler | v4.0 |
| **Frontend** | component-forge, responsive-engine, motion-craft, landing-craft, aesthetic-web, ui-ux-pro-max, emil-design-eng, impeccable, taste, taste-soft, taste-minimalist | v4.0 |
| **Mobile** | flutter, react-native | v4.0 |
| **Quality** | test-commander, performance-profiler, code-review, comprehensive-review, cross-review, zen-review, zen-comprehensive-review | v4.0 |
| **Content & Business** | communication, content-marketing, business-proposals, seo-geo, translate-craft, documentation | v4.0 |
| **Documents** | kami (PDF generator), portfolio-auto, kagen (AI images) | v4.0 |
| **Productivity** | git-workflow, windows-powershell, strategy, brand-design, runbook-gen, finance, legal-counsel, whendone-plus | v4.0 |
| **AI Agents** | agent-browser, agent-tools, find-skills, skill-creator, research, humanize | v4.0 |
| **System** | memory, chromadb, shokunin-update, init, efficient-coding, senior-engineer, plan, playwright, neon-postgres, web-security | v4.2 |

Each skill includes: trigger-optimized descriptions, procedural workflows, error handling, production checklists, anti-patterns, cited sources. Advanced skills also include executable scripts, reference files, and reusable templates.

## What You Get

| Component | Purpose |
|-----------|---------|
| **62 SKILL.md files** | Domain expertise that auto-activates |
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
| **ChromaDB (SQLite-backed)** | Zero-install local vector database |

## Requirements

### Minimum
| Dependency | Version | Notes |
|------------|---------|-------|
| **OS** | Windows 10/11 or Linux | **Linux:** requires `bash` 4+, not `sh`. Run `bash --version` to verify. |
| **Node.js** | ≥ 18 | Includes `npm`. Run `node --version` to verify. |
| **Python** | ≥ 3.11 | Run `python3 --version` to verify. |
| **Git** | ≥ 2.x | Run `git --version` to verify. |

### Linux: additional dependencies
| Dependency | Why | Install |
|------------|-----|---------|
| `python3-pip` | Required for ChromaDB. Not included by default on Ubuntu/Debian. | `sudo apt-get install -y python3-pip` |
| `build-essential` + `python3-dev` | Needed to compile ChromaDB native wheels on some systems. | `sudo apt-get install -y build-essential python3-dev` |
| `cron` daemon | Required for automated weekly maintenance (optional). | `sudo systemctl enable --now cron` |

> **Ubuntu 24.04+:** PEP 668 blocks global `pip install` by default. The installer handles this automatically with `--break-system-packages`. If you run into issues, see the Troubleshooting section below.

### Windows: additional notes
- PowerShell 5.1+ required. Run `$PSVersionTable.PSVersion` to verify.
- Execution policy must allow scripts: `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser`

## Quick Start

**Windows:**
```powershell
# 1. Install
irm https://raw.githubusercontent.com/EliasOulkadi/shokunin/master/install.ps1 | iex

# 2. (Optional) Free NVIDIA API key, or skip, OpenCode Go works without it
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

# 2. (Optional) Free NVIDIA API key, or skip, OpenCode Go works without it
#    https://build.nvidia.com/

# Quick Start (non-interactive):
bash <(curl -sL https://raw.githubusercontent.com/EliasOulkadi/shokunin/master/install.sh) -y

# 3. Reload shell and start OpenCode
source ~/.bashrc
opencode
```

## Memory System v4.2.3

Multi-strategy recall (vector + BM25 + temporal + reciprocal rank fusion). Session management with explicit continue (no guessing which session to resume).

- **Freshness decay**: exponential recency blending — old memories fade over 30-day half-life so stale claims don't drown out recent context
- **Claim verification**: `verify_file_path` MCP tool validates file paths from old memory before the agent acts on them — treats memory as claims from a frozen point in time, not facts
- **9 MCP tools** (up from 8): store_context, search_context, get_session_summary, multi_search_context (vector+BM25+RRF+temporal), consolidate_memories, list_sessions, continue_session, save_message, verify_file_path

```bash
# List recent sessions
python ~/.shokunin/scripts/chroma-helper.py session list 5

# Continue a specific session (loads full context)
python ~/.shokunin/scripts/chroma-helper.py session continue <session_id>

# Search across all memory
python ~/.shokunin/scripts/chroma-helper.py recall "topic"
```

All data stored at `~/.shokunin/memory/`. No cloud, no telemetry, no subscriptions.

```powershell
# Test the memory system
.\test-memory.ps1

# Validate all memory components
.\memory-healthcheck.ps1
```

- [Technical Overview v4.2.3](docs/Shokunin-Technical-Overview-v4.2.3.pdf) - Full ecosystem overview, multi-strategy recall, Hindsight comparison

## Troubleshooting

| Problem | Cause | Solution |
|---------|-------|----------|
| Installer hangs on `Continue? (y/n)` | `read -p` blocks in non-interactive mode | Use `bash install.sh -y` or run directly in a terminal |
| `pip3: command not found` | `python3-pip` not installed | `sudo apt-get install python3-pip` |
| `externally-managed-environment` | PEP 668 on Ubuntu 24.04+ | The installer applies `--break-system-packages` automatically. If it fails, run manually: `python3 -m pip install chromadb --break-system-packages` |
| `Cannot uninstall typing_extensions` | Debian-packaged package missing RECORD file | `python3 -m pip install chromadb --break-system-packages --ignore-installed typing-extensions` |
| MCP fetch/filesystem: `Connection closed` | OpenCode runtime config issue | Verify `node` is in PATH and check `~/.config/opencode/opencode.json` |
| `npm install -g opencode` fails | Missing npm or insufficient permissions | Install npm first, or run `sudo npm install -g opencode` |
| ChromaDB fails to install | Missing build dependencies | `sudo apt-get install -y build-essential python3-dev` |

## Commands

**OpenCode custom commands:** `/save` (save session to ChromaDB), `/load` (load previous session), `/status` (healthcheck).

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
| **Windsurf** | ✅ Reads SKILL.md | ✅ Via rules | ✅ .pack/templates/windsurf-mcp.json | ✅ .sh | Copy template |

### Setup per runtime

**Claude Code:** Copy `.pack/templates/claude-code.json` to project root as `claude.json` or configure via CLAUDE.md.

**Cline:** Add the `mcpServers` block from `.pack/templates/cline-settings.json` to VS Code's `settings.json`. Copy `.pack/rules/cline-memory.md` as `.clinerules`.

**Cursor:** Configure MCP servers in Cursor Settings > MCP using `.pack/templates/cursor-mcp.json`. Copy `.pack/rules/cursor-memory.mdc` to `.cursor/rules/memory.mdc`.

**Continue.dev:** Copy `.pack/templates/continue-config.yaml` to `.continue/config.yaml`. Add `.pack/rules/continue-memory.md` to `.continue/rules/`.

**Windsurf:** Copy `.pack/templates/windsurf-mcp.json` MCP config. Copy `.pack/rules/windsurf-memory.md` to `.windsurf/rules/memory.md`.

## Links

- **GitHub** github.com/EliasOulkadi/shokunin
- **Website** eliasoulkadi.github.io/shokunin
- [Shokunin Technical Overview](/docs/Shokunin-Technical-Overview-v4.2.3.pdf)

## License

MIT free as in freedom, free as in zero cost.
