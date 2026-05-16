# Contributing to Shokunin

Thanks for your interest in contributing. Here's what you need to know.

## How to contribute skills

Each skill lives in its own directory with a `SKILL.md` file at the root.

1. Create a new directory under `.pack/skills/` with a descriptive name (e.g. `.pack/skills/my-skill/`)
2. Write a `SKILL.md` following the existing format:
   - YAML frontmatter with `name` and `description`
   - Section-based workflow with steps
   - Clear examples and anti-patterns
3. Submit a Pull Request

## How to report issues

Open a GitHub issue with:
- A clear title
- Steps to reproduce (if bug)
- Expected vs actual behavior
- Environment details (OS, runtime versions)

## Pull request process

1. Fork the repo and create a branch
2. Make your changes
3. Test that the install script still works
4. Open a PR with a clear description of what and why

## Code style

- Markdown: 80 char lines, ATX headings, fenced code blocks
- Shell scripts: `set -euo pipefail`, error messages, portable syntax
- Python: type hints, f-strings, 3.10+ syntax

Questions? Open an issue or reach out to oulkadielias8@icloud.com.
