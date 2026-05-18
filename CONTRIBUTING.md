# Contributing to Shokunin

## Dev Setup

1. Clone the repo
2. Install Python 3.11+ and Node.js 18+
3. Install dependencies: `pip install chromadb`
4. Run tests: `.\test-memory.ps1`

## Code Standards

### Python
- Format: `ruff format .`
- Lint: `ruff check .` (full rule set, strict)
- Types: `mypy .pack/scripts/chroma-helper.py .pack/memory/mcp-server.py`
- No bare `except:` — always specify exception type
- Type hints on all functions
- F-strings preferred over `%` or `.format()`

### PowerShell
- `Set-StrictMode -Version Latest` at top of every script
- `[CmdletBinding()]` on all advanced functions
- `$ErrorActionPreference = 'Stop'` for critical operations
- Verbose naming: `Get-*`, `Set-*`, `Test-*`, etc.
- CRLF line endings (Windows convention)

### Git
- Conventional commits: `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `ci:`
- Keep commits atomic — one logical change per commit
- Branch from `master`, PR back to `master`

## PR Process
1. Create a feature branch: `feat/short-description` or `fix/short-description`
2. Make your changes
3. Run lint/typecheck: `ruff check . && mypy .`
4. Run memory tests: `.\test-memory.ps1`
5. Submit a PR against `master`
6. CI runs automatically (lint, typecheck, security, memory tests)

## Testing
- Python tests: `pytest tests/` (requires chromadb)
- Memory tests: `.\test-memory.ps1` (Windows) or `./test-memory.sh` (Linux)
- Healthcheck: `.\memory-healthcheck.ps1`
- All PRs must pass CI before merge
