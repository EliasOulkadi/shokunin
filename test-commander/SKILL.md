---
name: test-commander
description: Generate unit, integration, and e2e tests
---

Generate tests that catch real bugs, not just exercise code. Follows testing best practices from Kent C. Dodds, Testing Library, Martin Fowler, and Google's testing research.

## Testing Trophy (not pyramid)

Focus on integration tests over unit or e2e. The trophy model prioritizes tests that exercise how your code works together — where most real bugs live.

| Level | Tool | Coverage Target | Speed | Catch Rate |
|-------|------|----------------|-------|------------|
| Static | TypeScript, ESLint | All code | Instant | Type errors, style bugs |
| Unit | Vitest / Jest | Business logic | Fast | Logic errors in isolation |
| Integration | Testing Library | All features | Medium | Component interaction bugs (most common) |
| E2E | Playwright | Critical paths | Slow | System-level failures |
| Visual | Storybook + Chromatic | UI components | Medium | Visual regressions |

Integration tests catch 80% of bugs with 20% of the maintenance cost. Focus here.

## Test Structure by Type

### Unit Tests
```tsx
describe('Component / feature', () => {
  it('handles the happy path', () => { /* ... */ })
  it('handles the loading state', () => { /* ... */ })
  it('handles the empty state', () => { /* ... */ })
  it('handles the error state', () => { /* ... */ })
  it('handles edge case: long input', () => { /* ... */ })
  it('handles edge case: rapid clicks', () => { /* ... */ })
})
```

Every "state" your component can be in should have a test. If it has 5 states, write 5 tests.

### Integration Tests
```tsx
describe('User profile feature', () => {
  it('renders user data after loading', async () => { /* ... */ })
  it('shows error state on API failure', async () => { /* ... */ })
  it('allows editing user name', async () => { /* ... */ })
  it('shows validation error on invalid email', async () => { /* ... */ })
  it('persists changes after save', async () => { /* ... */ })
})
```

Integration tests test REAL interactions — API calls, state changes, side effects. Mock only network/browser, not business logic.

### E2E Tests
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

E2E tests cover critical business flows only. Signup, login, purchase, core feature — NOT every UI state.

## Mocking Strategy

| What to mock | How | What NOT to mock |
|-------------|-----|-----------------|
| Network requests | MSW (Mock Service Worker) | Business logic |
| File system | temp directories + cleanup | Validation |
| Random values (Date, UUID, Math.random) | Vitest mock functions | Data transformation |
| Browser APIs (localStorage, fetch) | jsdom or Playwright | State management |
| Third-party SDKs | Vitest mock or __mocks__ directory | Your own API layer |

### MSW (preferred over mocking fetch directly)
```tsx
import { http, HttpResponse } from 'msw'
import { setupServer } from 'msw/node'

const server = setupServer(
  http.get('/api/users', () => {
    return HttpResponse.json([{ id: '1', name: 'Alice' }])
  })
)

beforeAll(() => server.listen())
afterEach(() => server.resetHandlers())
afterAll(() => server.close())
```

MSW intercepts at the network level — your code runs unchanged. No mocking of fetch, axios, or other HTTP clients.

## Fixture Strategy

- Realistic data that mirrors production shapes
- Factory functions with sensible defaults (use Faker for realistic values)
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

// In a test
const admin = buildUser({ role: 'admin' })
```

## Test Naming Conventions

| Pattern | Example | Why |
|---------|---------|-----|
| `it('handles X')` | `it('handles empty input')` | Focus on behavior, not implementation |
| `it('shows error when X')` | `it('shows error when network fails')` | Negative test cases are as important as positive |
| `it('does not X when Y')` | `it('does not submit when form is invalid')` | Edge cases and guard conditions |
| Describe block = feature | `describe('Password reset flow')` | Groups logically related tests |

## Coverage Thresholds

| Metric | Minimum | Focus on |
|--------|---------|----------|
| Lines | 80% | Infrastructure and glue code |
| Branches | 75% | Conditionals, ternaries, early returns |
| Functions | 80% | All exported functions |
| Statements | 80% | General safety net |

Coverage is a safety net, not a goal. Focus coverage on business logic and integration paths. Utilities rarely need tests if well-typed. Don't write tests to inflate coverage — write them to prevent bugs.

## Testing by Stack

### React / Next.js
```tsx
import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'

it('submits form with valid data', async () => {
  const onSubmit = vi.fn()
  render(<LoginForm onSubmit={onSubmit} />)

  await userEvent.type(screen.getByLabelText('Email'), 'user@test.com')
  await userEvent.type(screen.getByLabelText('Password'), 'password123')
  await userEvent.click(screen.getByRole('button', { name: 'Log in' }))

  expect(onSubmit).toHaveBeenCalledWith({
    email: 'user@test.com',
    password: 'password123',
  })
})
```

### Node.js / Express
```tsx
import request from 'supertest'
import { app } from '../app'

it('returns 201 on successful user creation', async () => {
  const res = await request(app)
    .post('/api/users')
    .send({ email: 'test@test.com', name: 'Test' })

  expect(res.status).toBe(201)
  expect(res.body.data).toHaveProperty('id')
})

it('returns 400 on invalid email', async () => {
  const res = await request(app)
    .post('/api/users')
    .send({ email: 'not-an-email' })

  expect(res.status).toBe(400)
  expect(res.body.error.code).toBe('VALIDATION_ERROR')
})
```

## CI Integration

```yaml
# GitHub Actions — parallel test sharding
test:
  runs-on: ubuntu-latest
  strategy:
    matrix:
      shard: [1/4, 2/4, 3/4, 4/4]
  steps:
    - uses: actions/checkout@v4
    - run: npm ci
    - run: npm test -- --shard=${{ matrix.shard }}
```

- Unit + integration tests run on every PR
- E2E tests run only on merge to main
- Visual tests run on PR for changed components
- Tests must pass before merge (blocking CI check)

## Testing Anti-Patterns

| Anti-pattern | Why it fails | Fix |
|-------------|-------------|-----|
| Testing implementation details | Tests break on refactor, even when behavior is correct | Test behavior (what user sees / API returns), not internals |
| Snapshot testing large structures | Brittle, low signal-to-noise ratio | Snapshots for small, stable outputs only (5-10 lines) |
| Over-mocking | Test verifies mock setup, not real behavior | Only mock network and I/O. Never mock business logic. |
| Testing the framework | "Does React render this div?" wastes time | Test YOUR logic, not the framework's |
| Flaky tests (timing, ordering) | Erode trust, ignored, then bugs slip through | Fix or remove. Use `waitFor`, `findBy` instead of arbitrary timeouts |
| Too many assertions per test | First failure hides the rest | One logical assertion per `it()` block |
| Shared mutable state between tests | Order-dependent failures | Reset state in `beforeEach` |
| Testing only the happy path | 90% of bugs are in edge cases | Every error state, empty state, and boundary gets a test |

## Test Maintenance

| Task | Frequency | Why |
|------|-----------|-----|
| Review flaky tests | Weekly | Flaky tests destroy trust in the test suite |
| Remove orphaned tests | Monthly | Tests for deleted features waste CI time |
| Update snapshots deliberately | When output changes intentionally | Never auto-approve snapshot updates |
| Audit slow tests | Quarterly | Tests over 500ms should be optimized or moved to a different level |
| Check coverage trends | Monthly | Dropping coverage signals untested new code |

## Sources

- Kent C. Dodds "Testing Trophy" — testing strategy framework (kentcdodds.com)
- Testing Library docs — guiding principles and best practices (testing-library.com)
- Martin Fowler "TestCoverage" — what coverage means and doesn't mean
- Google Testing Blog "Just Say No to More End-to-End Tests" — testing at scale
- Playwright docs "Best Practices" — E2E testing patterns
- Vitest documentation — modern testing for Vite projects
- Clean Code (Robert C. Martin) — test structure and naming
- Working Effectively with Legacy Code (Michael Feathers) — testing strategies for existing codebases
