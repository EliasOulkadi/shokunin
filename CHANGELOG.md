# Changelog

v4.2.2 adds freshness decay (time-weighted memory search), claim verification (verify_file_path MCP tool), 9 MCP tools (was 8), and all 62 skills standardized with Workflow, Error Handling, Sources, and Anti-Patterns sections (average 257 lines each).

## [4.2.2] - 2026-05-16
### Fixed
- Path traversal in `_sanitize_id`/`_safe_id` (regex instead of single replace)
- `install.ps1` `$PSScriptRoot` crash when running via iex
- `memory-healthcheck.ps1` `-and` → `-or` logic bug
- Template sync for `mcp-server.py.tpl` and `chroma-helper.py.tpl`
- Skills YAML frontmatter missing (6 skills, 3 locations)
- Data cleanup: 56 stale benchmark/test files deleted, logs truncated
- All PowerShell scripts: StrictMode, ErrorActionPreference, CmdletBinding

### Changed
- All Python files: type hints, logging for `except:pass`, lazy chromadb init
- CI/CD: dependabot, CODEOWNERS, typecheck + security jobs
- Docs: ARCHITECTURE.md, CONTRIBUTING.md, CHANGELOG.md, MCP-API.md
- ruff: migrated to pyproject.toml with full rule set
