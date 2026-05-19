---
name: playwright
description: "Browser automation, web scraping, E2E testing, and visual regression with Playwright. Covers 30+ patterns: login flows, form testing, responsive design checks, broken link validation, API mocking, data extraction, PDF generation, accessibility audits (axe-core), performance budgets (Lighthouse), visual diffing, multi-browser testing (Chromium/Firefox/WebKit), mobile emulation, infinite scroll, shadow DOM, iframes, file downloads, auth state reuse, cookie consent handling, WebSocket monitoring, console error detection, HAR export, trace viewer, Docker CI, GitHub Actions, and parallel sharding. Use when user asks to test a website, take screenshots, check responsive design, automate a browser task, scrape data, validate forms, check broken links, test login, audit accessibility, or measure page performance. Do NOT use for unit testing, API-only testing, or static analysis. Requires Node.js 18+."
triggers:
  - "Playwright"
  - "browser test"
  - "E2E test"
  - "visual test"
  - "screenshot"
  - "PDF generation"
  - "web scraping"
  - "browser automation"
  - "test form"
  - "test login"
  - "accessibility audit"
  - "visual regression"
negatives:
  - "unit testing"
  - "API testing"
  - "static analysis"
  - "load testing"
  - "quick scraping" -> use agent-browser
license: MIT
compatibility: opencode
metadata:
  workflow: testing
  audience: developers
  version: 2.1.0
---

# Playwright — Browser Automation Skill

Intelligent browser automation executor. Analyzes the user's request, selects the optimal pattern from 30+ built-in templates, generates production-grade Playwright code, and executes it with real-time reporting.

## Setup

Playwright must be available in the environment. If not installed:

```bash
npm init -y
npm install playwright @playwright/test
npx playwright install chromium
```

For all 3 browsers:
```bash
npx playwright install
```

Check what's installed:
```bash
npx playwright install --dry-run
```

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

## Workflow

### Step 1: Detect the environment

Before writing any code, determine what's available:

- **Dev servers**: Check common ports (3000, 3001, 5173, 8080, 8000, 4200, 5000, 9000) for running processes
- **Installed browsers**: Run `npx playwright install --dry-run` to see which browsers are available
- **Framework indicators**: Look for `package.json` dependencies (react, vue, svelte, next, nuxt) to understand the app under test
- **Available credentials**: Check if the user mentioned login credentials or has `.env` files

### Step 2: Select template + generate code

Based on task classification and environment info, select the appropriate template and customize it with:
- Detected URL (dev server or user-supplied)
- Any user-specific parameters (credentials, selectors, viewports)
- Best-practice patterns auto-inserted (waitForSelector instead of fixed waits, graceful error handling, cleanup in finally)

Rules for code generation:
- Use `getByRole` / `getByText` / `getByLabel` over CSS selectors (stable, accessible)
- Parameterize URL in `TARGET_URL` constant at top
- Never use `waitForTimeout` for conditions — use `waitForSelector`, `waitForURL`, `waitForResponse`
- Always wrap in try/catch/finally with `browser.close()` in finally
- Include console.error logging at each step
- Comment each logical block
- Write generated file to OS temp dir as `playwright-task-{timestamp}.js`

### Step 3: Execute

Run the generated script directly with Node:

```bash
node <path-to-generated-file>
```

For inline one-off tasks (quick screenshot, check title):

```bash
node -e "
const { chromium } = require('playwright');
(async () => {
  const browser = await chromium.launch({ headless: false });
  const page = await browser.newPage();
  await page.goto('$URL');
  console.log('Title:', await page.title());
  await browser.close();
})();
"
```

### Step 4: Report results

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
- **Auth state reuse**: Save to `.auth/` directory for multi-step flows
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

### Quick screenshot
```javascript
const { chromium } = require('playwright');
(async () => {
  const browser = await chromium.launch({ headless: false });
  const page = await browser.newPage();
  await page.setViewportSize({ width: 1920, height: 1080 });
  await page.goto(TARGET_URL, { waitUntil: 'networkidle' });
  await page.screenshot({ path: `${require('os').tmpdir()}/screenshot.png`, fullPage: true });
  console.log('Screenshot saved to temp/screenshot.png');
  await browser.close();
})();
```

### Quick page info
```javascript
const { chromium } = require('playwright');
(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage();
  await page.goto(TARGET_URL);
  console.log('Title:', await page.title());
  console.log('URL:', page.url());
  const meta = await page.$('meta[name="description"]');
  console.log('Meta description:', meta ? await meta.getAttribute('content') : 'N/A');
  await browser.close();
})();
```

### Quick form test
```javascript
const { chromium } = require('playwright');
(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage();
  await page.goto(TARGET_URL);
  const inputs = await page.locator('input, textarea, select').count();
  const buttons = await page.locator('button, input[type="submit"]').count();
  console.log(`Form has ${inputs} inputs and ${buttons} buttons`);
  await browser.close();
})();
```

## Advanced Patterns

### Login flow with auth state reuse
```javascript
const { chromium } = require('playwright');
const path = require('path');
const AUTH_FILE = path.join(__dirname, '.auth', 'state.json');

(async () => {
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext();

  // Try to reuse saved auth state
  try {
    const state = require(AUTH_FILE);
    await context.addCookies(state.cookies);
  } catch {}

  const page = await context.newPage();
  await page.goto(TARGET_URL);

  // Check if logged in
  const isLoggedIn = await page.$('[data-logged-in]');
  if (!isLoggedIn) {
    await page.fill('[name="username"]', USERNAME);
    await page.fill('[name="password"]', PASSWORD);
    await page.click('button[type="submit"]');
    await page.waitForURL('**/dashboard');
    // Save auth state
    const cookies = await context.cookies();
    require('fs').writeFileSync(AUTH_FILE, JSON.stringify({ cookies }, null, 2));
  }

  // Continue with authenticated actions...
  await browser.close();
})();
```

### API mocking with route interception
```javascript
const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext();
  const page = await context.newPage();

  // Mock API responses
  await page.route('**/api/users', route => {
    route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify([{ id: 1, name: 'Test User' }])
    });
  });

  // Block analytics/tracking requests
  await page.route(/google-analytics|facebook|gtag/, route => route.abort());

  await page.goto(TARGET_URL);
  // Test with mocked data...
  await browser.close();
})();
```

### Accessibility audit (requires axe-core)
```bash
npm install @axe-core/playwright
```

```javascript
const { chromium } = require('playwright');
const { injectAxe, checkA11y } = require('@axe-core/playwright');

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage();
  await page.goto(TARGET_URL);
  await injectAxe(page);
  const results = await checkA11y(page, null, {
    detailedReport: true,
    detailedReportOptions: { html: true }
  });
  console.log(`Violations: ${results.violations.length}`);
  results.violations.forEach(v => console.log(`- ${v.help}: ${v.nodes.length} instances`));
  await browser.close();
})();
```

## Anti-Patterns

| Anti-Pattern | Why It's Bad | Do This Instead |
|-------------|-------------|-----------------|
| `page.waitForTimeout(5000)` | Flaky, slows tests, false passes | `page.waitForSelector('.loaded')` |
| `page.$eval('.css-selector', ...)` | Brittle, breaks on DOM changes | `page.getByRole('button', { name: 'Submit' })` |
| Hardcoded `localhost:3000` | Fails when port changes | Parameterize as `TARGET_URL` env var |
| No `browser.close()` | Hangs, leaks resources | Always in `finally` block |
| `page.click()` without wait | Race condition, element not ready | `page.click()` already waits for actionability |
| Sequential tests in one script | One failure kills everything | Separate scripts or use test runner |
| `networkidle` on SPAs | Never resolves on polling apps | Use `load` + explicit element wait |
| Capturing fullPage on infinite scroll | Huge images, timeouts | Clip viewport only |
| Reusing selectors between environments | Dev vs prod DOM differs | Use data-testid or role-based locators |

## Error Handling

### Playwright-specific errors and remedies

| Error | Likely Cause | Resolution |
|-------|-------------|------------|
| `browserType.launch: Executable doesn't exist` | Chromium not installed | Run `npx playwright install chromium` |
| `page.goto: net::ERR_CONNECTION_REFUSED` | Dev server not running | Start dev server or verify URL |
| `page.click: Target closed` | Navigation happened during click | Use `page.waitForNavigation()` before click or `Promise.all([page.waitForNavigation(), page.click()])` |
| `locator.click: Timeout 30000ms exceeded` | Element never becomes actionable | Check selector; maybe element is hidden/disabled/covered |
| `page.fill: Element is not an <input>` | Wrong element type targeted | Use `getByRole('textbox')` for proper targeting |
| `route.fulfill: Request already served` | Multiple routes matched same request | Order routes most-specific first; use `route.fallback()` for pass-through |
| `browser.newContext: Cookie domain mismatch` | Auth state reuse on wrong domain | Ensure cookies match the target URL's domain |
| `page.pdf: Protocol error` | Headless mode disabled | PDF generation requires `headless: true` |
| `page.waitForSelector: Target closed` | Navigation destroyed the page | Wrap navigation + post-navigation actions in a single `await` chain |
| `require('playwright'): Cannot find module` | Install incomplete | `npm install playwright` then verify `node_modules/playwright` exists |

## Checklist

- [ ] Locator uses `getByRole`, `getByText`, or `getByTestId` — never XPath or CSS selectors with fragile class names
- [ ] Auto-waiting relied on (no manual `waitForTimeout` or `sleep`)
- [ ] Test isolates state (clean DB or API mock per test)
- [ ] Cross-browser tested (Chromium + Firefox + WebKit) for critical flows
- [ ] Trace viewer enabled on failure for debugging CI flakes

## Sources

- Playwright official documentation (playwright.dev) — locator strategies, auto-waiting, fixtures
- Testing Trophy methodology — 80% integration / 20% unit testing ratio
- @axe-core/playwright for accessibility audits
- Lighthouse CI for performance budgets
- Production E2E patterns from 30+ project codebases
