---
name: test-commander
description: Generate unit, integration, and e2e tests
---


# Test Commander

Generates tests that catch real bugs, not just exercise code. Follows testing best practices from Kent C. Dodds, Testing Library, and Martin Fowler.

## Testing Trophy (not pyramid)

Focus on integration tests over unit or e2e. The trophy model prioritizes tests that exercise how your code works together.

| Level | Tool | Coverage Target | Speed |
|-------|------|----------------|-------|
| Static | TypeScript, ESLint | All code | Instant |
| Unit | Vitest / Jest | Business logic | Fast |
| Integration | Testing Library | All features | Medium |
| E2E | Playwright | Critical paths | Slow |
| Visual | Storybook + Chromatic | UI components | Medium |

## Unit Test Structure

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

## What to Mock

- Network requests (MSW or similar)
- File system operations
- Random values (Date, UUID, Math.random)
- Browser APIs (localStorage, fetch)
- NEVER mock: business logic, validation, data transformation

## Fixture Strategy

- Realistic data that mirrors production shapes
- Factory functions with sensible defaults
- Override per test for specific scenarios
- Version-controlled alongside tests

```tsx
export const buildUser = (overrides: Partial<User> = {}): User => ({
  id: `user_${faker.string.uuid()}`,
  email: faker.internet.email(),
  name: faker.person.fullName(),
  role: 'user',
  createdAt: new Date(),
  ...overrides,
})
```

## Coverage Thresholds

| Metric | Minimum |
|--------|---------|
| Lines | 80% |
| Branches | 75% |
| Functions | 80% |
| Statements | 80% |

Focus coverage on business logic and integration paths. Utilities rarely need tests if typed well.

## Testing Anti-Patterns

- Testing implementation details (test behavior, not internals)
- Snapshot testing large structures (brittle, low signal)
- Over-mocking (test becomes a mock-verification)
- Testing the framework (React, Vue â€” they already work)
- Flaky tests (fix or remove â€” they erode trust)

## Sources
- Kent C. Dodds Testing Trophy
- Testing Library docs
- Martin Fowler on test coverage








