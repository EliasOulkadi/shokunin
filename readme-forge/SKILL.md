---
name: readme-forge
description: Functional READMEs with install and API
---

Generate READMEs that cover everything a new user needs to go from zero to productive. Standard structure, comprehensive API reference, no fluff. Based on analysis of the top 100 npm packages and their documentation patterns.

## Structure

```
# Project Name
[Badges: CI | Coverage | Version | License]

One-line description: what it is, who it's for, what problem it solves.

## Features
3-6 quantified benefits

## Table of Contents
[link to every section below]

## Installation
One command. Prerequisites listed if any.

## Quick Start
Copy-paste runnable example with expected output.

## API Reference
Every export documented in table format.

## Examples
2-3 real-world usage scenarios.

## Configuration
Environment variables, config file format, CLI flags.

## Contributing
Dev setup, test command, lint command, PR process.

## License
SPDX identifier.
```

## Quick Start Requirement

Copy-paste runnable. No omitted imports. No placeholders. The first example should be the first thing someone would try after installing.

Bad:
```js
import { something } from 'my-lib'
// ... implementation details omitted
```

Good:
```js
import { formatDate } from 'date-fns'
const result = formatDate(new Date(), 'yyyy-MM-dd')
console.log(result) // "2026-05-12"
```

## API Reference Format

Each export gets:

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `input` | `string` | Yes | — | The text to transform |
| `options` | `FormatOptions` | No | `{}` | Configuration object |
| `options.case` | `'upper' \| 'lower'` | No | `'lower'` | Output case |

Returns: `string` — the transformed text.

```js
// Example
toCamelCase('hello world') // 'helloWorld'
```

### Layout Rules

- Parameters table first for each function
- Return type on a separate line
- One complete example per export
- TypeScript types shown inline (no link to separate type doc)
- Edge cases documented: empty input, null, special characters

## Installation Section Patterns

| Package type | Command | Prerequisites |
|-------------|---------|--------------|
| npm library | `npm install <package>` | Node.js 18+ |
| CLI tool | `npm install -g <package>` | Node.js 18+ |
| Plugin | `npm install <host-package> <plugin>` | Host package installed |
| Python | `pip install <package>` | Python 3.10+ |
| Rust | `cargo add <crate>` | Rust 1.70+ |

## Examples Section

2-3 examples minimum. Each example covers a distinct use case:

1. **Basic usage**: simplest possible example
2. **Advanced usage**: with configuration, error handling
3. **Integration**: combining with another library or framework

Each example includes:
- Comment explaining what it does
- Complete code (no truncated snippets)
- Expected output (console.log, return value, or side effect)

## Configuration Section

| Method | Format | Example |
|--------|--------|---------|
| Env vars | `NAME=VALUE` | `API_KEY=sk_123 npm start` |
| Config file | JSON/YAML/TOML | `my-lib.config.json` |
| CLI flags | `--name value` | `my-cli --format json` |
| Programmatic | Options object | `createApp({ debug: true })` |

Document ALL configuration options in a table. No undocumented "easter egg" features.

## Contributing Rules

```
## Contributing

1. Fork the repo
2. Create a branch: `git checkout -b feat/my-feature`
3. Install dependencies: `npm install`
4. Run tests: `npm test`
5. Run linter: `npm run lint`
6. Commit: `git commit -m 'feat: add my feature'`
7. Push and open a PR

See [CONTRIBUTING.md](./CONTRIBUTING.md) for detailed guidelines.
```

Always include: dev setup, test command, lint command, and link to full contributing guide.

## Badge Requirements

| Badge | Required? | Links to |
|-------|-----------|----------|
| CI (build status) | Yes | CI pipeline |
| Package version | Yes | npm/crates.io/pypi |
| License | Yes | LICENSE file |
| Coverage | Recommended | Coverage report |
| Downloads/month | Recommended | Package page |
| GitHub stars | Optional | Repo |
| Discord/Slack | Optional | Community invite |

All badges must link to the relevant page. No dead badge links.

## Anti-Patterns

| Anti-pattern | Fix |
|-------------|-----|
| Default README from template not customized | Remove all template comments. Fill every section. |
| "Coming soon" features listed | Remove them. Ship it or hide it. |
| Missing prerequisites | New users waste time debugging missing deps. List everything needed. |
| No link to full documentation | README is onboarding. Full docs are reference. Link both ways. |
| Installation instructions that don't work | Test your install command from scratch in a clean environment. |
| API docs with no examples | Every function needs at least one runnable example. |
| Contributing section with incomplete setup | Someone will try to contribute on their first day. Make it work. |
| No table of contents (README > 200 lines) | READMEs over 200 lines need a TOC with anchor links. |

## Sources

- Standard Readme specification
- Awesome README — curated list of quality READMEs
- Make a README — README generation best practices
- GitHub docs "About READMEs"
- npm best practices for package documentation
- Rust crate documentation standards
- Python packaging documentation guide
