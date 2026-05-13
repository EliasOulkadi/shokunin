---
name: test-commander
description: Generate unit, integration, E2E, and visual regression tests following the Testing Trophy methodology (80% integration). Covers Vitest/Jest, Testing Library, Playwright, MSW for API mocking, snapshot strategy, visual regression (Chromatic/Percy/Playwright), test factories with Faker, and CI sharding. Use when user asks to write tests, set up testing framework, mock API/dependencies, improve coverage, or add visual regression. Do NOT use for performance/load testing, production monitoring, or type testing (covered by TypeScript).
license: MIT
compatibility: opencode
metadata:
  workflow: quality
  audience: developers
  version: "3.0"
  author: shokunin
allowed-tools: Read Bash Write Grep Glob
---

# Test Commander

Write tests that catch real bugs. Follows the Testing Trophy (Kent C. Dodds): focus on integration tests, supplement with unit, E2E, and visual regression.

## Workflow

### Step 1: Determine test level

| Question | Level | Tool |
|----------|-------|------|
| Is this pure logic (util, helper, math)? | Unit | Vitest |
| Does this combine components with API/store? | Integration | Testing Library + MSW |
| Is this a critical user flow? | E2E | Playwright |
| Does this check visual appearance? | Visual | Chromatic/Percy |

**Default: Integration tests.** They catch 80% of bugs with 20% of the maintenance cost.

### Step 2: Scaffold test files

```bash
# Generate a complete test suite for a component
scripts/scaffold-test.sh src/components/Button.tsx --framework react

# For an API endpoint
scripts/scaffold-test.sh src/api/users.ts --type api
```

See [assets/test-component-template.tsx](assets/test-component-template.tsx) and [assets/test-api-template.ts](assets/test-api-template.ts) for complete rendered examples.

### Step 3: Write tests by level

#### Unit tests

```tsx
describe('formatPrice', () => {
  it('formats USD correctly', () => {
    expect(formatPrice(29.99, 'USD')).toBe('$29.99')
  })
  it('handles zero', () => {
    expect(formatPrice(0, 'USD')).toBe('$0.00')
  })
  it('throws on negative', () => {
    expect(() => formatPrice(-1, 'USD')).toThrow()
  })
})
```

#### Integration tests (highest priority)

Cover every state: loading, empty, error, success, and edge cases:

```tsx
describe('UserProfile', () => {
  it('shows loading state', async () => {
    render(<UserProfile userId="123" />)
    expect(screen.getByRole('status')).toHaveTextContent('Loading...')
  })

  it('shows error with retry', async () => {
    server.use(http.get('/api/users/123', () => HttpResponse.error()))
    render(<UserProfile userId="123" />)
    await waitFor(() => {
      expect(screen.getByRole('alert')).toHaveTextContent('Failed to load')
    })
    await userEvent.click(screen.getByRole('button', { name: 'Retry' }))
  })

  it('renders user data on success', async () => {
    render(<UserProfile userId="123" />)
    await waitFor(() => {
      expect(screen.getByText('Alice')).toBeInTheDocument()
    })
  })
})
```

#### E2E tests

```tsx
test('checkout flow', async ({ page }) => {
  await page.goto('/products')
  await page.click('[data-testid="add-to-cart"]')
  await page.click('[data-testid="checkout"]')
  await page.fill('[name="email"]', 'test@example.com')
  await page.click('[data-testid="pay-now"]')
  await expect(page.locator('[data-testid="confirmation"]')).toBeVisible()
})
```

### Step 4: Configure MSW for API mocking

See [references/msw-patterns.md](references/msw-patterns.md) for all patterns. Start with this setup:

```tsx
import { http, HttpResponse } from 'msw'
import { setupServer } from 'msw/node'

const server = setupServer(
  http.get('/api/users', () => {
    return HttpResponse.json([{ id: '1', name: 'Alice' }])
  })
)

beforeAll(() => server.listen({ onUnhandledRequest: 'warn' }))
afterEach(() => server.resetHandlers())
afterAll(() => server.close())
```

### Step 5: Add visual regression

See [references/visual-regression.md](references/visual-regression.md) for all tools and patterns.

```tsx
// Playwright visual comparison
test('homepage matches', async ({ page }) => {
  await page.goto('/')
  await expect(page).toHaveScreenshot('homepage.png', {
    fullPage: true,
    maxDiffPixelRatio: 0.01,
  })
})
```

**Decision**: Use Playwright built-in for simple E2E + visual. Use Chromatic for Storybook-integrated visual review.

### Step 6: Set up CI integration

```yaml
# Unit + integration on every PR
test:
  strategy:
    matrix:
      shard: [1/4, 2/4, 3/4, 4/4]
  run: npm test -- --shard=${{ matrix.shard }}

# E2E only on merge to main
e2e:
  if: github.ref == 'refs/heads/main'
  run: npm run test:e2e
```

## Error Handling

| Error | Cause | Fix |
|-------|-------|-----|
| Test times out | Async not awaited | Add `await` to async operations, increase timeout |
| MSW handler not matched | URL mismatch | Check exact path + method. Use `onUnhandledRequest: 'warn'` |
| Snapshot mismatch | Intentional UI change | Run `vitest -u` to update (review diff first) |
| Flaky test (race condition) | Shared mutable state | Reset in `beforeEach`, use `waitFor`/`findBy` |
| E2E timeout | Slow CI runner | Increase Playwright timeout, tag heavy tests as `@slow` |

## Production Checklist

- [ ] Every data-fetching component has loading/empty/error/success tests
- [ ] MSW setup with `onUnhandledRequest: 'warn'`
- [ ] Factory functions for fixtures (Faker, sensible defaults)
- [ ] Snapshot tests only for stable outputs (<10 lines)
- [ ] E2E covers critical business flows only (3-5 max)
- [ ] Test sharding on CI (4 shards minimum)
- [ ] E2E runs on merge to main only (not every PR)
- [ ] Visual regression on PR for changed components
- [ ] Tests must pass before merge (blocking CI)
- [ ] Flaky tests fixed or removed within 1 week

## Anti-Patterns

| Anti-pattern | Fix |
|-------------|-----|
| Testing implementation details | Test behavior (user sees / API returns) |
| Large snapshots (>10 lines) | Snapshots only for stable, small outputs |
| Over-mocking | Mock only network and I/O. Never business logic. |
| Flaky tests | Fix or remove. Use `waitFor`/`findBy`. |
| Too many assertions per test | One assertion per `it()` block |
| Shared mutable state | Reset in `beforeEach` |
| Happy path only | Every error/empty state gets a test |
| No Playwright trace on failure | Always record traces in CI: `--trace on` |

## Sources

- Kent C. Dodds "Testing Trophy" (kentcdodds.com)
- Testing Library docs (testing-library.com)
- Playwright docs "Best Practices"
- Vitest documentation
- MSW (mswjs.io)
- Martin Fowler "TestCoverage"
- Google Testing Blog
- Chromatic visual testing (chromatic.com)
