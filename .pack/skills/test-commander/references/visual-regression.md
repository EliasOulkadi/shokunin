# Visual Regression Testing

Catch visual bugs before they reach production. This guide covers Playwright screenshots, Chromatic, and Percy patterns.

---

## Strategy

| Aspect | Recommendation |
|--------|---------------|
| **Coverage** | Every component variant, every viewport breakpoint |
| **Threshold** | `maxDiffPixelRatio: 0.01` (1% diff) — not 0% |
| **Baselines** | Git-tracked, updated intentionally via `--update-snapshots` |
| **CI gate** | Fail PRs that introduce visual diffs > threshold |
| **Review** | Human-in-the-loop for UI changes (Chromatic/Percy) |
| **Dynamic content** | Freeze dates, data, and animations via MSW + CSS |

---

## Playwright Visual Comparisons

### Setup

```bash
npm install --save-dev @playwright/test
npx playwright install
```

```ts
// playwright.config.ts
import { defineConfig } from '@playwright/test'

export default defineConfig({
  use: {
    baseURL: 'http://localhost:3000',
    viewport: { width: 1280, height: 720 },
  },
  snapshotPathTemplate: '__screenshots__/{testFilePath}/{arg}{ext}',
  expect: {
    toHaveScreenshot: {
      maxDiffPixelRatio: 0.01,
      maxDiffPixels: 100,
      threshold: 0.2,
      animations: 'disabled',
      caret: 'hide',
      scale: 'device',
    },
  },
})
```

### Basic snapshot

```ts
import { test, expect } from '@playwright/test'

test('homepage matches baseline', async ({ page }) => {
  await page.goto('/')
  await expect(page).toHaveScreenshot('homepage.png', {
    fullPage: true,
  })
})
```

### Component-level snapshots (Storybook integration)

```ts
test('Button component variants', async ({ page }) => {
  await page.goto('/iframe.html?id=components-button--primary')
  await expect(page.locator('#storybook-root')).toHaveScreenshot('button-primary.png')

  await page.goto('/iframe.html?id=components-button--disabled')
  await expect(page.locator('#storybook-root')).toHaveScreenshot('button-disabled.png')

  await page.goto('/iframe.html?id=components-button--loading')
  await expect(page.locator('#storybook-root')).toHaveScreenshot('button-loading.png')
})
```

### Viewport variants

```ts
const viewports = [
  { name: 'mobile', width: 375, height: 812 },
  { name: 'tablet', width: 768, height: 1024 },
  { name: 'desktop', width: 1280, height: 720 },
  { name: 'wide', width: 1920, height: 1080 },
]

viewports.forEach(({ name, width, height }) => {
  test(`homepage on ${name} (${width}x${height})`, async ({ page }) => {
    await page.setViewportSize({ width, height })
    await page.goto('/')
    await expect(page).toHaveScreenshot(`homepage-${name}.png`, { fullPage: true })
  })
})
```

### Theming / dark mode

```ts
test('dark mode', async ({ page }) => {
  await page.goto('/')
  await page.emulateMedia({ colorScheme: 'dark' })
  await expect(page).toHaveScreenshot('dark-mode.png')
})
```

### Localization

```ts
const locales = ['en', 'es', 'ja', 'fr']

locales.forEach((locale) => {
  test(`homepage in ${locale}`, async ({ page }) => {
    await page.goto(`/${locale}`)
    await expect(page).toHaveScreenshot(`homepage-${locale}.png`)
  })
})
```

### Animations and transitions

```ts
// Disable animations via CSS injection
test('stable snapshot with animations disabled', async ({ page }) => {
  await page.addStyleTag({
    content: `
      *, *::before, *::after {
        animation-duration: 0s !important;
        transition-duration: 0s !important;
        animation-delay: 0s !important;
        caret-color: transparent !important;
      }
    `,
  })

  await page.goto('/')
  await expect(page).toHaveScreenshot('no-animations.png')
})
```

### Masking dynamic content

```ts
test('masks dynamic areas', async ({ page }) => {
  await page.goto('/dashboard')

  await expect(page).toHaveScreenshot('dashboard.png', {
    mask: [
      page.locator('[data-testid="live-clock"]'),
      page.locator('[data-testid="user-avatar"]'),
    ],
    maskColor: '#f0f0f0',
  })
})
```

### Handling flaky screenshots

```ts
// Retry screenshot on failure (network-dependent renders)
test('retry flaky screenshots', async ({ page }) => {
  await page.goto('/analytics')

  // Wait for all chart SVGs to render
  await page.waitForSelector('[data-testid="chart"] svg', { timeout: 10_000 })

  await expect(page).toHaveScreenshot('analytics.png', {
    // Tolerance for antialiasing differences
    threshold: 0.3,
    maxDiffPixels: 200,
    // Compare pixel-per-inch aware
    scale: 'device',
  })
})
```

---

## Chromatic

### Setup

```bash
npm install --save-dev chromatic storybook
npx chromatic --project-token=<token>
```

```yaml
# .github/workflows/chromatic.yml
name: Chromatic
on: pull_request

jobs:
  chromatic:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0    # required for chromatic diff
      - run: npm ci
      - uses: chromaui/action@latest
        with:
          projectToken: ${{ secrets.CHROMATIC_PROJECT_TOKEN }}
          onlyChanged: true
          exitZeroOnChanges: true   # don't fail PR — allow human review
```

### Storybook decorators for visual testing

```ts
// .storybook/preview.ts
import { withScreenshot } from 'storycap'

export const decorators = [withScreenshot]

export const parameters = {
  chromatic: {
    disableSnapshot: false,
    // Pause animations before snapshot
    pauseAnimationAtEnd: true,
    // Delay snapshot (wait for loading states to resolve)
    delay: 500,
  },
  viewport: {
    defaultViewport: 'desktop',
  },
}
```

### Per-story configuration

```ts
// Button.stories.ts
export const Primary: Story = {
  render: () => <Button variant="primary">Click me</Button>,
  parameters: {
    chromatic: {
      // Only snapshot this story at these viewports
      viewports: [375, 1280],
      // Delay snapshot for async rendering
      delay: 1000,
      // Ignore specific elements
      diffThreshold: 0.2,
      // Pause CSS animations before capture
      pauseAnimationAtEnd: true,
    },
  },
}

// Disable snapshot for irrelevant stories
export const Loading: Story = {
  render: () => <Button isLoading>Loading</Button>,
  parameters: {
    chromatic: { disableSnapshot: true },
  },
}
```

### Chromatic modes (themes, viewports, locales)

```ts
// .storybook/preview.ts
export const parameters = {
  chromatic: {
    modes: {
      light: { theme: 'light' },
      dark: { theme: 'dark', backgrounds: { value: '#1a1a1a' } },
      mobile: { viewport: 375 },
      tablet: { viewport: 768 },
      rtl: { locale: 'ar' },
    },
  },
}
```

---

## Percy

### Setup

```bash
npm install --save-dev @percy/cli @percy/storybook
```

```yaml
# .github/workflows/percy.yml
name: Percy
on: pull_request

jobs:
  percy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm ci
      - run: npx percy storybook -- --ci
        env:
          PERCY_TOKEN: ${{ secrets.PERCY_TOKEN }}
```

### Snapshots in E2E tests

```ts
import percySnapshot from '@percy/playwright'

test('percy homepage snapshot', async ({ page }) => {
  await page.goto('/')
  await page.waitForLoadState('networkidle')
  await percySnapshot(page, 'Homepage')
})

test('percy multi-viewport', async ({ page }) => {
  const viewports = [
    { width: 375, height: 812, name: 'mobile' },
    { width: 1280, height: 720, name: 'desktop' },
  ]

  for (const { width, height, name } of viewports) {
    await page.setViewportSize({ width, height })
    await page.goto('/')
    await percySnapshot(page, `Homepage (${name})`)
  }
})
```

### Percy CSS overrides

```ts
// Snap specific elements only
await percySnapshot(page, 'Sidebar', {
  scope: '[data-testid="sidebar"]',
  widths: [320],
  percyCSS: `
    iframe, .animated { display: none; }
    * { transition: none !important; }
    body { background: white; }
  `,
})
```

---

## Freezing dynamic content

```ts
// test-utils.ts — freeze date and data for deterministic screenshots
import { vi } from 'vitest'

export function freezeTime(isoString = '2024-01-15T12:00:00.000Z') {
  vi.setSystemTime(new Date(isoString))
}

export function freezeRandom() {
  // Seed faker or override Math.random
  vi.spyOn(Math, 'random').mockReturnValue(0.5)
}
```

```css
/* In test environment, hide dynamic elements */
[data-testid="live-indicator"],
[data-testid="time-ago"] {
  visibility: hidden;
}
```

---

## CI Integration

```yaml
# .github/workflows/visual.yml
name: Visual Regression
on: pull_request

jobs:
  playwright-screenshots:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm ci
      - run: npx playwright install --with-deps
      - run: npm run build && npm run test:visual
        env:
          PWTEST_SNAPSHOT_ENV: ci

      - uses: actions/upload-artifact@v4
        if: failure()
        with:
          name: snapshot-diffs
          path: test-results/

  chromatic:
    needs: playwright-screenshots
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }
      - run: npm ci
      - uses: chromaui/action@latest
        with:
          projectToken: ${{ secrets.CHROMATIC_PROJECT_TOKEN }}
          onlyChanged: true
```

### Updating baselines locally

```bash
# Playwright
npx playwright test --update-snapshots

# Chromatic
npx chromatic --force-rebuild

# Percy
npx percy storybook -- --dry-run
```

### Reviewing failures

| Tool | Artifact | Action |
|------|----------|--------|
| Playwright | `test-results/*.png` (diff) | Check diff overlay, accept with `--update-snapshots` or fix code |
| Chromatic | Web UI diff viewer | Approve / deny in Chromatic dashboard |
| Percy | Web UI diff viewer | Approve each snapshot individually |

---

## Anti-Patterns

| Anti-pattern | Why | Fix |
|-------------|-----|-----|
| `maxDiffPixelRatio: 0` | Random anti-aliasing fails builds | Use 0.01–0.05 |
| No viewport variants | Miss mobile/tablet breakpoint regressions | Test at 375, 768, 1280 |
| Dynamic content in snapshots | False positives on every run | Freeze time, seed data, mask live areas |
| Snapshot entire page | Minor changes fail entire snapshot | Component-level snapshots + masking |
| Skipping CI review | Diffs merged without human check | Require Chromatic/Percy approval in branch rules |
| No baseline management | Stale baselines hide regressions | Rebase on intentional visual changes only |

---

## Sources

- [Playwright Screenshots](https://playwright.dev/docs/screenshots)
- [Chromatic Docs](https://www.chromatic.com/docs)
- [Percy Docs](https://docs.percy.io)
- [Storycap](https://github.com/reg-viz/storycap)
