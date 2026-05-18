---
name: playwright
description: "Browser automation, web scraping, E2E testing, and visual regression with Playwright. Covers 30+ patterns: login flows, form testing, responsive design checks, broken link validation, API mocking, data extraction, PDF generation, accessibility audits (axe-core), performance budgets (Lighthouse), visual diffing, multi-browser testing (Chromium/Firefox/WebKit), mobile emulation, infinite scroll, shadow DOM, iframes, file downloads, auth state reuse, cookie consent handling, WebSocket monitoring, console error detection, HAR export, trace viewer, Docker CI, GitHub Actions, and parallel sharding. Use when user asks to test a website, take screenshots, check responsive design, automate a browser task, scrape data, validate forms, check broken links, test login, audit accessibility, or measure page performance. Do NOT use for unit testing, API-only testing, or static analysis. Requires Node.js 18+."
license: MIT
compatibility: opencode
metadata:
  workflow: testing
  audience: developers
  version: 2.0.0
---

> **Note:** Helper scripts (helpers.js, analyzer.js, validators.js, run.js) and reference docs (references/*.md) are deployed with the full distribution. Core Playwright interactions work without them.

Intelligent browser automation executor. Analyzes the user's request, selects the optimal pattern from 30+ built-in templates, generates production-grade Playwright code, and executes it with real-time reporting.

## Trigger Decision Tree

When user asks for browser automation, classify the task:

```
User request
├── "screenshot" / "capture" / "take a picture"
│   → screenshot template
├── "responsive" / "mobile" / "different sizes"
│   → responsive check + per-viewport screenshots
├── "login" / "sign in" / "authenticate"
│   → login flow with error detection
├── "form" / "fill" / "submit" / "input"
│   → form testing with validation check
├── "broken links" / "check links" / "link validation"
│   → broken link scanner
├── "scrape" / "extract" / "get data" / "crawl"
│   → data extraction (single page or crawl)
├── "mock" / "intercept" / "stub" / "fake api"
│   → API mocking with route interception
├── "accessibility" / "a11y" / "axe" / "wcag"
│   → accessibility audit (requires axe-core)
├── "performance" / "lighthouse" / "speed" / "load time"
│   → performance audit with budgets
├── "visual" / "visual regression" / "diff"
│   → visual comparison screenshots
├── "download" / "file download"
│   → file download handler
├── "console" / "errors" / "logs"
│   → console error detector
├── "pdf" / "generate pdf"
│   → page-to-PDF converter
└── else → generic browse + report
```

## Architecture

```
SKILL.md           → Entry point (this file)
references/        → Deep-dive guides (loaded on demand)
  authentication   → Session reuse, cookie management
  visual-testing   → Screenshot diff, percy-like patterns
  performance      → Lighthouse, performance budgets  
  ci-cd            → Docker, GitHub Actions, sharding
  debugging        → Trace viewer, HAR, video
templates/         → Reusable code templates
lib/
  helpers.js       → Utility functions
  analyzer.js      → Page analysis engine
  validators.js    → Validation helpers
run.js             → Universal executor
```

## Workflow

### Step 1: Resolve skill directory

Determine `$SKILL_DIR` based on where this SKILL.md was loaded. All paths below are relative to `$SKILL_DIR`.

### Step 2: Verify setup

```bash
cd "$SKILL_DIR"
node -e "require('./lib/helpers').ensureSetup()"
```

This auto-installs Playwright + Chromium if missing. One-time cost.

### Step 3: Auto-detect environment

```bash
cd "$SKILL_DIR"
node -e "require('./lib/helpers').probeEnvironment().then(r => console.log(JSON.stringify(r)))"
```

This probes:
- Active dev servers (ports 3000, 3001, 5173, 8080, 8000, 4200, 5000, 9000)
- Installed browsers (chromium, firefox, webkit)
- Available frameworks (React, Vue, Svelte indicators)

Returns JSON that determines routing decisions below.

### Step 4: Select template + generate code

Based on task classification and environment info, select the appropriate template from `templates/` and customize it with:
- Detected URL (dev server or user-supplied)
- Any user-specific parameters (credentials, selectors, viewports)
- Best-practice patterns auto-inserted (waitForSelector instead of fixed waits, graceful error handling, cleanup in finally)

Rules for code generation:
- Use `getByRole` / `getByText` / `getByLabel` over CSS selectors (stable, accessible)
- Parameterize URL in `TARGET_URL` constant at top
- Never use `waitForTimeout` for conditions — use `waitForSelector`, `waitForURL`, `waitForResponse`
- Always wrap in try/catch/finally with browser.close() in finally
- Include console.error logging at each step
- Comment each logical block
- Write generated file to system temp dir as `playwright-task-{timestamp}.js`

### Step 5: Execute

```bash
cd "$SKILL_DIR"
node run.js <path-to-generated-file>
```

For inline one-off tasks (quick screenshot, check title):
```bash
cd "$SKILL_DIR"
node run.js "await page.goto('$URL'); console.log(await page.title())"
```

### Step 6: Report results

Present results based on task type:
| Task | Output format |
|------|--------------|
| Screenshot | Display path + preview description |
| Responsive | Table: viewport × status × screenshot path |
| Login | Pass/fail + redirect URL + session file |
| Broken links | Summary: working/broken + detailed table |
| Scrape | Number of records + sample rows |
| A11y | Violation count + top 3 issues |
| Performance | Score table + largest offenders |
| Visual diff | Pass/fail + mismatch pixels |

## Smart Defaults

These are applied automatically to every generated script:

| Setting | Default | Why |
|---------|---------|-----|
| `headless` | `false` | User sees what's happening |
| `slowMo` | `100` | Visible transitions for debugging |
| `viewport` | `1280x720` | Standard desktop |
| Timeout | `15000` (15s) | Balance patience vs feedback |
| `args` | `--no-sandbox` | Linux/WSL compatibility |
| Trace | On first failure | Diagnostic data |
| Video | On failure | Visual debug |
| Screenshot | On failure | Visual assert |
| Console listener | Active | Capture browser errors |
| Page error listener | Active | Catch JS exceptions |

## Important Rules

- **No hardcoded URLs**: Always parameterize as `TARGET_URL`
- **No fixed waits**: Use `waitForSelector`, `waitForURL`, `waitForResponse`, `waitForLoadState`
- **Auth state reuse**: Save to `$SKILL_DIR/.auth/` for multi-step flows
- **Temp files only**: Write scripts to OS temp dir, never to project or skill dir
- **Failure screenshots**: Always capture on error for debugging
- **Close browser**: Always `browser.close()` in `finally` block

## Error Recovery

| Error | Diagnosis | Response |
|-------|-----------|----------|
| ECONNREFUSED | Server not running | Suggest dev server or check URL |
| Timeout 30s | Element/page not loading | Retry with waitForSelector, suggest specific selector |
| NoSuchElement | Wrong selector | Auto-capture page HTML snippet, suggest better selector |
| Auth failure | Login credentials wrong | Capture error message, suggest alternative flow |
| 404/500 | Bad URL or server error | Log status + body, offer to check URL |

## Common Fast Patterns

For the most frequent requests, use these directly:

### Quick screenshot
```javascript
const page = await browser.newPage();
await page.setViewportSize({ width: 1920, height: 1080 });
await page.goto(TARGET_URL, { waitUntil: 'networkidle' });
await page.screenshot({ path: '/tmp/screenshot.png', fullPage: true });
console.log('Screenshot: /tmp/screenshot.png');
```

### Quick page info
```javascript
const page = await browser.newPage();
await page.goto(TARGET_URL);
console.log('Title:', await page.title());
console.log('URL:', page.url());
console.log('Meta description:', await page.$eval('meta[name="description"]', el => el.content).catch(() => 'N/A'));
```

### Quick form test
```javascript
const page = await browser.newPage();
await page.goto(TARGET_URL);
const inputs = await page.locator('input, textarea, select').count();
const buttons = await page.locator('button, input[type="submit"]').count();
console.log(`Form has ${inputs} inputs and ${buttons} buttons`);
```

## Extending

For complex scenarios (Chrome extensions, Electron, CDP protocol, WebSocket interception, multi-page flows), see:
- `references/authentication.md` — Session reuse, SSO, MFA bypass patterns
- `references/visual-testing.md` — Screenshot diff, pixelmatch, Percy patterns
- `references/performance.md` — Lighthouse CI, performance budgets, Web Vitals
- `references/ci-cd.md` — Docker images, GitHub Actions, parallel sharding, retry strategies
- `references/debugging.md` — Trace viewer, HAR export, video recording, CDP sessions
- `lib/analyzer.js` — Programmatic a11y audit, SEO check, performance analysis
- `lib/validators.js` — Link validation, form validation, schema validation

## Notes

- Playwright auto-installs on first use via `npm run setup`
- Dev server detection runs automatically — no need to manually specify `localhost` ports
- Scripts go to OS temp dir — no project pollution, auto-cleaned
- Templates are BASE CODE — customize freely before execution
- All patterns support all 3 browsers (Chromium, Firefox, WebKit)
- API_REFERENCE.md has the full API surface — load on demand for depth
