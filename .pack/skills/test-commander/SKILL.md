---
name: test-commander
description: Generate unit, integration, E2E, and visual regression tests following the Testing Trophy methodology (80% integration). Covers Vitest/Jest, Testing Library, Playwright, MSW for API mocking, snapshot strategy, visual regression (Chromatic/Percy/Playwright), test factories with Faker, and CI sharding. Use when user asks to write tests, set up testing framework, mock API/dependencies, improve coverage, or add visual regression. Do NOT use for performance/load testing, production monitoring, or type testing (covered by TypeScript).
triggers:
  - "write tests"
  - "unit test"
  - "integration test"
  - "E2E test"
  - "test coverage"
  - "Vitest"
  - "Jest"
  - "Playwright test"
  - "Testing Library"
  - "MSW"
  - "mock API"
  - "visual regression"
  - "test setup"
negatives:
  - "performance testing"
  - "load testing"
  - "production monitoring"
  - "type testing"
  - "TypeScript"
license: MIT
compatibility: opencode
metadata:
  workflow: quality
  audience: developers
  version: "4.0.0"
  author: shokunin
allowed-tools: Read Bash Write Grep Glob
---


# Test Commander

Tests that catch real bugs. Following the Testing Trophy (Kent C. Dodds): 80% integration, 10% unit, 10% E2E. Based on patterns from Testing Library, Playwright, MSW, and Chromatic.

## Testing Trophy (visual)

```
        /\
       /E2E\        ← 2-3 critical flows
      /------\
     / Visual \     ← Visual regression on key components
    /----------\
   /Integration\    ← 80% of tests. Components + API + store.
  /--------------\
 /     Unit       \ ← Pure logic. Utils, helpers, formatters.
/------------------\
     Static         ← TypeScript + ESLint
```

## Workflow

### Step 1: Determine test level

| What are you testing? | Level | Tool | Speed |
|------------------------|-------|------|:-----:|
| Pure logic (math, format, transform) | Unit | Vitest | < 5ms each |
| Component + API + store together | Integration | Testing Library + MSW | 50-200ms each |
| Critical user flow (checkout, signup) | E2E | Playwright | 2-10s each |
| Visual appearance | Visual | Playwright / Chromatic | 1-5s each |

**Default: Integration.** Catches 80% of bugs with 20% of maintenance cost.

### Step 2: Write integration tests (5 mandatory states)

Every data-fetching component must test ALL five states:

```tsx
describe('UserProfile', () => {
  it('shows loading skeleton initially', async () => {
    render(<UserProfile userId="123" />)
    expect(screen.getByRole('status')).toHaveTextContent('Loading...')
  })

  it('shows error state with retry button', async () => {
    server.use(http.get('/api/users/123', () => new HttpResponse(null, { status: 500 })))
    render(<UserProfile userId="123" />)
    await waitFor(() => {
      expect(screen.getByRole('alert')).toHaveTextContent('Failed to load')
    })
    expect(screen.getByRole('button', { name: /retry/i })).toBeInTheDocument()
  })

  it('shows empty state when no data', async () => {
    server.use(http.get('/api/users/123', () => HttpResponse.json(null)))
    render(<UserProfile userId="123" />)
    await waitFor(() => {
      expect(screen.getByText(/no user found/i)).toBeInTheDocument()
    })
  })

  it('renders user data on success', async () => {
    render(<UserProfile userId="123" />)
    await screen.findByText('Alice')
    expect(screen.getByText('alice@example.com')).toBeInTheDocument()
  })

  it('handles race condition: fast re-fetch', async () => {
    const { rerender } = render(<UserProfile userId="123" />)
    await screen.findByText('Alice')
    rerender(<UserProfile userId="456" />)
    await screen.findByText('Bob')
    expect(screen.queryByText('Alice')).not.toBeInTheDocument()
  })
})
```

### Step 3: MSW setup (exact pattern)

```typescript
import { http, HttpResponse } from 'msw'
import { setupServer } from 'msw/node'

const server = setupServer(
  http.get('/api/users', () => {
    return HttpResponse.json([
      { id: '1', name: 'Alice', email: 'alice@example.com' },
      { id: '2', name: 'Bob', email: 'bob@example.com' },
    ])
  }),

  http.post('/api/users', async ({ request }) => {
    const body = await request.json()
    return HttpResponse.json({ id: '3', ...body }, { status: 201 })
  })
)

beforeAll(() => server.listen({ onUnhandledRequest: 'warn' }))
afterEach(() => server.resetHandlers())
afterAll(() => server.close())
```

### Step 4: Test factories (Faker)

```typescript
import { faker } from '@faker-js/faker'

function createUser(overrides: Partial<User> = {}): User {
  return {
    id: faker.string.uuid(),
    name: faker.person.fullName(),
    email: faker.internet.email(),
    createdAt: faker.date.recent().toISOString(),
    ...overrides,
  }
}

const admin = createUser({ name: 'Admin User' })
const emptyUser = createUser({ email: '' })  // Edge case factory
```

### Step 5: E2E tests (Playwright)

```tsx
test('checkout flow', async ({ page }) => {
  await page.goto('/products')
  await page.getByTestId('add-to-cart').click()
  await page.getByTestId('cart-count').toHaveText('1')
  await page.getByTestId('checkout').click()
  await page.getByLabel('Email').fill('test@example.com')
  await page.getByRole('button', { name: 'Pay $29.99' }).click()
  await expect(page.getByTestId('order-confirmed')).toBeVisible()
  await expect(page.getByTestId('order-id')).not.toBeEmpty()
})
```

Always record traces on failure:
```bash
npx playwright test --trace on
```

### Step 6: Visual regression

```tsx
test('homepage visual', async ({ page }) => {
  await page.goto('/')
  await expect(page).toHaveScreenshot('homepage.png', {
    fullPage: true,
    maxDiffPixelRatio: 0.01,
  })
})
```

### Step 7: CI sharding

```yaml
test:
  strategy:
    matrix:
      shard: [1/4, 2/4, 3/4, 4/4]
  run: npx vitest --shard=${{ matrix.shard }}
```

---

## Flaky Test Protocol

| Symptom | Root cause | Fix |
|---------|------------|-----|
| Passes locally, fails CI | Timing, different env | Use `waitFor`/`findBy*` instead of fixed timeouts |
| Fails randomly | Shared mutable state | Reset state in `beforeEach`. Use fresh factories. |
| Network-dependent flake | API response timing | MSW mocks all network. No real API calls. |
| Visual diff flake | Anti-aliasing, OS differences | Use `maxDiffPixelRatio: 0.01`. Run on same OS in CI. |

If a test flakes more than once: fix it same day or skip it with `test.skip()` + a comment explaining why. Never let flaky tests accumulate.

---

## Anti-Patterns

| Anti-pattern | Fix |
|-------------|-----|
| Testing implementation details (state, methods, internal props) | Test behavior: what the user sees / API returns |
| Large snapshots (>20 lines) | Snapshots only for small, stable outputs |
| Over-mocking (mocking business logic) | Mock only network + I/O boundaries. Never mock your own code. |
| Too many assertions per test | One behavior per `it()` block |
| Shared mutable state between tests | Reset in `beforeEach`. Factories over literals. |
| Happy path only | Every error + empty state gets a test |
| No trace on E2E failure | Always `--trace on` in CI. Saves to `test-results/`. |
| E2E tests on every PR (slow) | E2E only on merge to main. Integration on every PR. |

## Production Checklist

- [ ] Every data-fetching component: loading + empty + error + success tests
- [ ] MSW: `onUnhandledRequest: 'warn'` + reset between tests
- [ ] Factory functions with Faker for all fixtures
- [ ] E2E: 3-5 critical flows (checkout, signup, key feature)
- [ ] Visual regression: key pages + components
- [ ] CI: 4 shards minimum for integration tests
- [ ] E2E: only on merge to main. Blocking merge on failure.
- [ ] Flaky tests: zero tolerance. Fix or skip within 24 hours.
- [ ] Accessibility: `axe-core` in E2E for key pages
- [ ] Coverage: not a metric. Focus on behavior coverage, not line coverage.

## Test Data Factories

```typescript
import { faker } from '@faker-js/faker'

function createUser(overrides: Partial<User> = {}): User {
  return {
    id: faker.string.uuid(),
    name: faker.person.fullName(),
    email: faker.internet.email(),
    role: faker.helpers.arrayElement(['admin', 'editor', 'viewer']),
    createdAt: faker.date.recent({ days: 30 }).toISOString(),
    ...overrides
  }
}

// Edge cases
const adminUser = createUser({ role: 'admin' })
const emptyEmail = createUser({ email: '' })
const longName = createUser({ name: 'a'.repeat(256) })
const futureDate = createUser({ createdAt: faker.date.future().toISOString() })
```

## Visual Regression Testing

```typescript
// Playwright
test('homepage visual check', async ({ page }) => {
  await page.goto('/')
  await expect(page).toHaveScreenshot('homepage.png', {
    fullPage: true,
    maxDiffPixelRatio: 0.01,
  })
})

// CI update: npx playwright test --update-snapshots
```

## Flaky Test Protocol

| Symptom | Root cause | Fix |
|---------|------------|-----|
| Passes locally, fails CI | Timing, different env | Use `waitFor`/`findBy*` instead of fixed timeouts |
| Fails randomly | Shared mutable state | Reset state in `beforeEach`. Use fresh factories. |
| Network-dependent flake | API response timing | MSW mocks all network. No real API calls. |
| Visual diff flake | Anti-aliasing, OS differences | `maxDiffPixelRatio: 0.01`. Run on same OS in CI. |
| Flaky test not reproducible | Race condition in test setup | Add `await`s. Ensure fixtures are resolved before assertions. |

Rule: one flake = fix today. Two flakes = skip with `test.skip()` + comment. Never let flaky tests accumulate.

## Sources

- Kent C. Dodds — Testing Trophy (kentcdodds.com)
- Testing Library — Guiding Principles
- Playwright — Best Practices
- MSW (mswjs.io) — API mocking
- Chromatic — Visual testing
- Martin Fowler — TestCoverage
- Google Testing Blog — Flaky test elimination

## Error Handling

| Cause | Fix |
|-------|-----|
| MSW server fails to start — port conflict in CI | Run with `--no-file-parallelism` flag. MSW workers share the same server; parallel test files compete for port |
| `screen.findByText()` consistently times out at 1000ms | Increase timeout in options: `screen.findByText(..., {}, { timeout: 5000 })`. Verify MSW handler path matches exactly (trailing slash matters) |
| Visual snapshot differs between CI (Linux) and local (macOS/Windows) | Font anti-aliasing and rendering differ by OS. Run visual tests on same OS as CI. Use `maxDiffPixelRatio: 0.02` for cross-OS tolerance |
| `beforeAll` MSW hook fails — entire test file skips | Ensure `server.listen()` is in `beforeAll` (not `beforeEach`). Register all handlers before calling `listen()`. Check `onUnhandledRequest: 'warn'` catches missing handlers |
| Playwright E2E passes locally, fails headless in CI | Use `--trace on` in CI config. Check browser version: `npx playwright install --with-deps chromium`. Some JS executes differently headless vs headed |
| Test factory generates duplicate unique IDs | Use `faker.string.uuid()` or `crypto.randomUUID()`. Never use sequential integers for unique IDs. Add uniqueness assertion in factory validation |
| E2E test flakes on dynamic content that loads after navigation | Use `page.waitForResponse(urlPattern)` targeting the API call, not `waitForTimeout()`. Assert on data-dependent element, not fixed time |
| Snapshot test fails on every CI run with timestamp diffs | Check snapshot for timestamps, random IDs, or dynamic dates. Mock with `vi.setSystemTime()` or `jest.useFakeTimers()`. Never snapshot unstable content |
| CI shard times out after 10 minutes | Increase shard count from 4 to 8+ for large suites. Profile slowest test file with `--reporter=verbose`. Extract slow E2E tests to separate job |

## Checklist

- [ ] Skill loads without errors in the AI agent
- [ ] YAML frontmatter is valid (description, compatibility, audience)
- [ ] Workflow section provides clear step-by-step instructions
- [ ] Error handling section covers common failure modes
- [ ] All referenced files (references/, scripts/, assets/) exist
- [ ] Skill triggers correctly for intended use cases
- [ ] No broken links or missing resources
