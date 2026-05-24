# Changelog

v4.2.3 adds null-safety to all MCP handlers, proper lazy loading for chroma_helper_stub, delete command for chroma-helper.py, fixed buffer capture in run-opencode.ps1, corrected search-memory.ps1 sorting, resolved Resolve-Path shadowing in shokunin-update.ps1, and improved install.ps1 encoding.

## [4.2.3] - 2026-05-19
### Fixed
- Path traversal in `_sanitize_id`/`_safe_id` (regex instead of single replace)
- `install.ps1` `$PSScriptRoot` crash when running via iex
- `memory-healthcheck.ps1` `-and` → `-or` logic bug
- Template sync for `mcp-server.py.tpl` and `chroma-helper.py.tpl`
- Skills YAML frontmatter missing (6 skills, 3 locations)
- Data cleanup: 56 stale benchmark/test files deleted, logs truncated
- All PowerShell scripts: StrictMode, ErrorActionPreference, CmdletBinding
- `mcp-server.py` KeyError in `handle_get_session_summary` (args access without .get)
- `shokunin-update.ps1` Resolve-Path shadowing PowerShell built-in
- `search-memory.ps1` bare `catch {}` (2 locations)
- `test-memory.ps1` test numbering sequence
- `memory-healthcheck.ps1` missing cleanup step
- `sitemap.xml` skills.html lastmod date (2025→2026)
- `skills.html` Extras→System domain rename, OG/Twitter meta tags
- `shokunin-update.ps1` StrictMode property crashes (`$g.rule`, `$g.path`, `$e.path`, `.Count`)
- `profile.ps1` infinite recursion risk (fallback `opencode` → `opencode.exe`)
- `weekly-healthcheck.ps1` garbled UTF-8 emoji, empty log bug
- `validate-skills.ps1` false-positive script path warnings
- `run-opencode.sh.tpl` non-existent template reference removed from manifest
- `CLAUDE.md.tpl` / `AGENTS.md.tpl` language mismatch (Spanish → English)

### Changed
- All Python files: type hints, logging for `except:pass`, lazy chromadb init
- CI/CD: dependabot, CODEOWNERS, typecheck + security jobs
- Docs: ARCHITECTURE.md, CONTRIBUTING.md, CHANGELOG.md, MCP-API.md
- ruff: migrated to pyproject.toml with full rule set
- All 62 skills: complete YAML frontmatter (license, compatibility, workflow, audience, semver)
- `brand-design` skill: directory renamed from `design`, all cross-references updated
- `README.md` design→brand-design reference
- `install.ps1` memory-sync function: dot-source detection, skip if not found
- 23 missing reference files created (neon-postgres, agent-tools, kami)
- `normalize-eol.ps1` and kami helper scripts created
- `llms.txt` added at repo root for AI discoverability
- `chroma_helper_stub.py` renamed usages aligned
- `shokunin.json`: added missing script entries (normalize-eol.ps1, profile.ps1, scan-cleanup.sh, test-memory.sh), version 4.2.2→4.2.3
