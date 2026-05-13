---
name: test-commander
description: Generate unit, integration, and end-to-end tests following the Testing Trophy methodology. Covers Vitest/Jest, Testing Library, Playwright, MSW mocking, snapshot strategy, visual regression (Chromatic/Percy), and CI test sharding. Use when user asks to write tests, unit tests, integration tests, E2E tests, set up testing framework, mock dependencies, or improve test coverage. Do NOT use for production monitoring, load testing, or performance benchmarking (use dedicated tools).
license: MIT
compatibility: opencode
metadata:
  workflow: quality
  audience: developers
  version: "2.0"
---

# Test Commander

Write tests that catch real bugs, not just exercise code. Based on the Testing Trophy, Kent C. Dodds, and patterns from Playwright and Vitest.

## The Testing Trophy

Integration tests catch 80% of bugs with 20% of the maintenance cost. Focus here.

| Level | Tool | Coverage Target | Speed | Catch Rate |
|-------|------|----------------|-------|------------|
| Static | TypeScript, ESLint | All code | Instant | Type errors, style |
| Unit | Vitest / Jest | Business logic | Fast | Logic errors |
| Integration | Testing Library | All features | Medium | Component interaction (most bugs) |
| E2E | Playwright | Critical paths | Slow | System failures |
| Visual | Storybook + Chromatic | UI components | Medium | Visual regressions |

## Workflow

### Step 1: Determine test level

| Question | Level |
|----------|-------|
| Does this test pure logic (utils, helpers, math)? | Unit |
| Does this test how components work together? | Integration |
| Does this test a critical user flow? | E2E |
| Does this test visual appearance? | Visual |

### Step 2: Write unit tests

```tsx
describe('formatPrice', () => {
  it('formats USD correctly', () => {
    expect(formatPrice(29.99, 'USD')).toBe('$29.99')
  })

  it('handles zero', () => {
    expect(formatPrice(0, 'USD')).toBe('$0.00')
  })

  it('handles large numbers with commas', () => {
    expect(formatPrice(1234567.89, 'USD')).toBe('$1,234,567.89')
  })

  it('throws on negative values', () => {
    expect(() => formatPrice(-1, 'USD')).toThrow()
  })
})
```

### Step 3: Write integration tests

```tsx
describe('User profile', () => {
  it('renders user data after loading', async () => {
    render(<UserProfile userId="123" />)
    expect(screen.getByRole('status')).toHaveTextContent('Loading...')

    await waitFor(() => {
      expect(screen.getByText('Alice')).toBeInTheDocument()
    })
  })

  it('shows error state on API failure', async () => {
    server.use(
      http.get('/api/users/123', () => HttpResponse.error())
    )
    render(<UserProfile userId="123" />)
    await waitFor(() => {
      expect(screen.getByRole('alert')).toHaveTextContent('Failed to load')
    })
  })

  it('allows editing user name', async () => {
    render(<UserProfile userId="123" />)
    await userEvent.click(screen.getByLabelText('Edit name'))
    await userEvent.type(screen.getByLabelText('Name'), 'Bob')
    await userEvent.click(screen.getByRole('button', { name: 'Save' }))

    await waitFor(() => {
      expect(screen.getByText('Bob')).toBeInTheDocument()
    })
  })
})
```

### Step 4: Write E2E tests

```tsx
test('user can complete checkout flow', async ({ page }) => {
  await page.goto('/products')
  await page.click('[data-testid="add-to-cart"]')
  await page.click('[data-testid="checkout"]')
  await page.fill('[name="email"]', 'test@example.com')
  await page.click('[data-testid="pay-now"]')
  await expect(page.locator('[data-testid="confirmation"]')).toBeVisible()
})
```

E2E tests cover critical business flows only. Signup, login, purchase, core feature.

## Mocking Strategy

| What to mock | How | What NOT to mock |
|-------------|-----|-----------------|
| Network | MSW (Mock Service Worker) | Business logic |
| File system | Temp directories | Validation |
| Date/UUID | Vitest mock functions | Data transformation |
| Browser APIs | jsdom or Playwright | State management |
| Third-party SDKs | Vitest mock or `__mocks__` | Your own API layer |

### MSW (preferred over mocking fetch)

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

### Mocking modules (Vitest)

```tsx
import { vi } from 'vitest'

// Mock entire module
vi.mock('stripe', () => ({
  default: {
    charges: {
      create: vi.fn().mockResolvedValue({ id: 'ch_123', status: 'succeeded' }),
    },
  },
}))

// Partial mock
vi.mock('fs', async (importOriginal) => {
  const actual = await importOriginal()
  return {
    ...actual,
    readFile: vi.fn().mockResolvedValue('mocked content'),
  }
})

// Spy on existing
const spy = vi.spyOn(console, 'log').mockImplementation(() => {})
```

## Fixture Strategy

- Realistic data that mirrors production shapes
- Factory functions with sensible defaults (use Faker)
- Override per test for specific scenarios
- Version-controlled alongside tests

```tsx
import { faker } from '@faker-js/faker'

export const buildUser = (overrides: Partial<User> = {}): User => ({
  id: `user_${faker.string.uuid()}`,
  email: faker.internet.email(),
  name: faker.person.fullName(),
  role: 'user',
  createdAt: new Date(),
  ...overrides,
})
```

## Snapshot Testing Strategy

### Use snapshots for:
- MSW handler configs (small, stable)
- SQL query outputs (detect unintended changes)
- Error messages (prevent regressions in user-facing text)
- CLI output formats

### Don't use snapshots for:
- Large React component trees (fragile, low signal)
- API responses that change frequently
- Generated CSS

```tsx
it('matches error snapshot', () => {
  expect(formatValidationError({ field: 'email', code: 'required' }))
    .toMatchInlineSnapshot(`"Email is required"`)
})
```

## Visual Regression

| Tool | Best for | Pricing |
|------|----------|---------|
| Chromatic | Storybook integration | Free for OSS |
| Percy | Cross-browser visual diffs | Paid |
| Loki | Screenshot comparison | Free, self-hosted |
| Playwright Visual | Inline E2E screenshots | Included |

```tsx
// Playwright visual comparison
test('homepage matches snapshot', async ({ page }) => {
  await page.goto('/')
  await expect(page).toHaveScreenshot('homepage.png', {
    fullPage: true,
    maxDiffPixelRatio: 0.01,
  })
})
```

## CI Integration

```yaml
# Unit + integration on every PR
test:
  runs-on: ubuntu-latest
  strategy:
    matrix:
      shard: [1/4, 2/4, 3/4, 4/4]
  steps:
    - uses: actions/checkout@v4
    - run: npm ci
    - run: npm test -- --shard=${{ matrix.shard }}

# E2E only on merge to main
e2e:
  if: github.ref == 'refs/heads/main'
  runs-on: ubuntu-latest
  steps:
    - run: npx playwright install --with-deps
    - run: npm run test:e2e
```

## Test Maintenance

| Task | Frequency |
|------|-----------|
| Review flaky tests | Weekly |
| Remove orphaned tests | Monthly |
| Update snapshots deliberately | On intentional output change |
| Audit slow tests (>500ms) | Quarterly |
| Check coverage trends | Monthly |

## Anti-Patterns

| Anti-pattern | Why it fails | Fix |
|-------------|-------------|-----|
| Testing implementation details | Breaks on refactor | Test behavior (user sees / API returns) |
| Large snapshots | Brittle, low signal | Snapshots for small, stable outputs |
| Over-mocking | Tests verify mocks, not real code | Only mock network and I/O |
| Testing the framework | Wastes time | Test YOUR logic |
| Flaky tests (timing, ordering) | Erode trust | Use `waitFor`, `findBy` instead of timeouts |
| Too many assertions per test | First failure hides rest | One assertion per `it()` |
| Shared mutable state | Order-dependent failures | Reset in `beforeEach` |
| Happy path only | 90% of bugs are edge cases | Every state gets a test |

## Sources

- Kent C. Dodds "Testing Trophy" (kentcdodds.com)
- Testing Library docs (testing-library.com)
- Martin Fowler "TestCoverage"
- Google Testing Blog "Just Say No to More End-to-End Tests"
- Playwright docs "Best Practices"
- Vitest documentation
- MSW Documentation (mswjs.io)
- Chromatic Visual Testing (chromatic.com)
