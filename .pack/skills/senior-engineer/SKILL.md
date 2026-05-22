---
name: Senior Engineer Coding
description: >
  Apply senior software engineering standards when writing, editing, or refactoring
  any code. Use this skill whenever the user asks to write a function, build a feature,
  fix a bug, design a module, or improve existing code — even if they don't mention
  quality explicitly. The goal is production-grade code: readable, correct, maintainable,
  secure, and failure-aware. Always active for any coding task, at any scale.
triggers:
  - "senior engineer"
  - "production code"
  - "production-grade"
  - "write quality code"
  - "robust code"
  - "maintainable code"
  - "secure code"
  - "production quality"
negatives:
  - "design"
  - "architecture"
  - "testing"
  - "performance optimization"
  - "animation"
license: MIT
compatibility: opencode
metadata:
  version: "1.0.0"

  workflow: general
  audience: developers
---


# Senior Engineer Coding

## Mindset

Write code for the next engineer who has to change it at 2am with no context.
Clean code is risk management. Every production incident traces back to unclear,
poorly structured, or hard-to-change code — not missing cleverness.

The standard: a teammate can safely change the code without fear, and explain
what it does after a quick read.

---

## 1. Naming — Highest ROI Habit

Good names eliminate comments, prevent misunderstandings, and make refactoring safe.

**Rules:**
- Name by **intent**, not by type or storage: `emailAddress` not `emailString`
- Use **domain language**: reflect business concepts (`Invoice`, `Subscription`, `Refund`)
- Include **units** in names: `timeoutMs`, `priceCents`, `fileSizeBytes`
- Make **booleans** read as questions: `isEnabled`, `hasAccess`, `shouldRetry`
- Name from the **caller's perspective**: `order.chargePayment()` not `order.process()`
- Be **consistent**: one concept, one word. Never `user` in one place and `customer` in another for the same entity

**Avoid:**
- Noise words: `manager`, `helper`, `data`, `info`, `handler` (unless genuinely descriptive)
- Abbreviations that don't scale: `usrAcctMgr`, `calcDisc`
- Overly generic verbs: `process()`, `handle()`, `doWork()`, `run()`
- Single-letter variables outside tiny loops: `d`, `x`, `tmp` cause real production bugs

---

## 2. Functions — Small, Focused, Predictable

**One function = one job.** If you can't describe it in one sentence, it does too much.

**Guard clauses over nested ifs:**
```
// Wrong — pyramid of doom, hides assumptions
if (user != null) {
  if (user.isActive()) {
    if (hasAccess(user)) {
      process(user)
    }
  }
}

// Right — early returns, happy path stays flat
if (user == null) return
if (!user.isActive()) return
if (!hasAccess(user)) return
process(user)
```

**Limit parameters:**
- More than 3 parameters → create a request/options object
- Long param lists break silently when order is swapped; objects don't

**Separate computation from I/O:**
- Pure logic (calculation, transformation) → separate from functions that read files, call APIs, write DBs
- Pure functions are easier to test, easier to reason about, and have no hidden side effects

**Command/Query separation:**
- Functions that return data → must not mutate state
- Functions that mutate → return a status/result, not data

---

## 3. No Magic Numbers or Strings

Every hardcoded value with business meaning is a future bug.

```
// Wrong
price * 1.21
if (status === 3)
setTimeout(fn, 86400000)

// Right
const VAT_RATE = 0.21
const STATUS_SHIPPED = 3
const ONE_DAY_MS = 24 * 60 * 60 * 1000
```

If a value can change, or has meaning beyond its face value, it must be a named constant.

---

## 4. Error Handling — Fail Fast, Fail Clearly

**Validate inputs at the boundary:**
- Check early, fail fast, with an actionable message
- Never let bad data travel deep into the system before exploding

**Make failures explicit:**
```
// Wrong — vague, no context
throw new Error("Something went wrong")
catch (e) { console.log(e) }

// Right — who failed, what failed, what identifier
throw new Error(`Payment failed for orderId=${order.id}: ${e.message}`)
logger.error({ orderId: order.id, userId: user.id, error: e.message })
```

**Design for failure, not success:**
- APIs fail. Network is unreliable. Data can be malformed. Assume all of it.
- Every external call needs: timeout, error handling, and at minimum a logged failure

**Don't swallow exceptions:**
- Empty `catch {}` blocks are production bugs waiting to happen
- If you catch, you must log (with context) or rethrow

---

## 5. DRY — Don't Repeat Yourself

Duplication is a defect multiplier. One version rounds. Another doesn't. Both are "correct".

- Extract shared logic the moment you write it a second time
- Centralize business rules: discount logic, tax calculation, validation rules
- One source of truth per concept

**But don't over-DRY:**
- Two functions that look similar but represent different concepts → keep them separate
- Premature abstraction is worse than mild duplication

---

## 6. KISS — Simplest Solution That Works

```
// Wrong — "clever" but unmaintainable
Optional<Optional<List<Data>>> result = ...

// Right — obvious and safe
return include ? List.of(data) : List.of()
```

Rules:
- Choose the simplest approach that solves the problem
- If you're proud of how clever it is, it's probably too clever
- Future you with no sleep at 2am must understand it immediately

---

## 7. Structure — Separation of Concerns

**Boundary test:** if changing one feature requires edits in many unrelated places, the boundaries are wrong.

Keep these separated:
- **UI** vs **business logic** — never mix rendering with rules
- **Domain** vs **infrastructure** — business logic must not depend on DB/HTTP/filesystem directly
- **Feature modules** — group by feature, not by layer when it reduces cross-module coupling

**Composition over inheritance:**
```
// Wrong — tight coupling through inheritance
class EmailNotifier extends Order {}

// Right — explicit dependency
class OrderService {
  constructor(private notifier: Notifier) {}
}
```
Inheritance spreads behavior implicitly. Composition makes dependencies explicit and swappable.

---

## 8. Comments — Why, Never What

The code explains **what**. Comments explain **why**.

**Good comments:**
```
// Retry once to handle transient network blips — removing this caused incident #4821
retryOnce(request)

// Using soft deletes — this query MUST include deleted_at IS NULL
// or deactivated accounts appear in results
```

**Bad comments (delete these):**
```
// Loop through users
for (const user of users) { ... }

// Set name
this.name = name
```

**Best outcome:** refactor the code until the comment is unnecessary.

If a `TODO` exists, it must have an owner and a date. Ownerless TODOs become permanent.

---

## 9. Security — Non-Negotiable Defaults

Apply these on every piece of code, without being asked:

- **Never trust external input** — validate and sanitize everything from users, APIs, files
- **Parameterize queries** — never concatenate user input into SQL
- **No secrets in code** — no API keys, passwords, or tokens hardcoded anywhere
- **Auth checks at every endpoint** — don't assume a caller is authenticated
- **Principle of least privilege** — request only the permissions the code actually needs
- **Error messages must not leak internals** — stack traces, DB queries, and file paths stay in logs, never in user-facing responses

---

## 10. SOLID — Applied With Concrete Patterns

Apply when it reduces coupling or improves testability. Don't add layers that don't solve a real problem. Each principle below includes the specific code smell it prevents.

### S — Single Responsibility
**One reason to change per module.** If it changes for two different reasons, split it.

**Smell:** A class/service mixes persistence, business logic, and notification:
```
// Bad — 3 reasons to change
class OrderService {
  save(order) { /* write to DB */ }
  calculateTax(order) { /* math */ }
  sendConfirmation(order) { /* email */ }
}
```
**Fix:**
```
class OrderRepository { save(order) }
class TaxCalculator { calculate(order) }
class OrderNotifier { sendConfirmation(order) }
class OrderService {
  constructor(private repo: OrderRepository, private tax: TaxCalculator, private notifier: OrderNotifier) {}
  async process(order) { await this.repo.save(order); await this.notifier.sendConfirmation(order); }
}
```

### O — Open/Closed
**Extend behavior by adding code, not rewriting existing code.**

**Smell:** A function with a growing switch/if-else for each new type:
```
// Bad — adding a new payment method means editing this function
function processPayment(type, amount) {
  if (type === 'credit') { /* ... */ }
  else if (type === 'paypal') { /* ... */ }
  // add else-if for every new type
}
```
**Fix:**
```
interface PaymentProcessor { process(amount: number): void }
class CreditProcessor implements PaymentProcessor { process(amount) { /* ... */ } }
class PaypalProcessor implements PaymentProcessor { process(amount) { /* ... */ } }
// Add new processors without touching existing code
```

### L — Liskov Substitution
**Subtypes must be substitutable for their base types.** A caller using the parent type must work correctly with any child.

**Smell:** A subclass throws exceptions the parent doesn't, or returns different types:
```
class FileStorage { save(file: Buffer): void }
class S3Storage extends FileStorage {
  save(file: Buffer): void { throw new Error("S3 timeout") } // Breaks callers expecting silent success
}
```
**Fix:** Design by contract. Document preconditions/postconditions. Don't narrow the output or widen the input.

### I — Interface Segregation
**Small, focused interfaces over god-objects with 20 methods.**

**Smell:** A class is forced to implement methods it doesn't need:
```
interface Worker { eat(): void; work(): void; sleep(): void }
class Robot implements Worker {
  eat() { throw "I don't eat" }  // Forced to implement
  work() { /* ... */ }
  sleep() { throw "I don't sleep" }
}
```
**Fix:**
```
interface Workable { work(): void }
interface Eatable { eat(): void }
interface Sleepable { sleep(): void }
class Robot implements Workable { work() { /* ... */ } }
class Human implements Workable, Eatable, Sleepable { work() { /* ... */ }; eat() { /* ... */ }; sleep() { /* ... */ } }
```

### D — Dependency Inversion
**Depend on abstractions, not concretions.** High-level modules should not depend on low-level modules.

**Smell:** Business logic directly instantiates infrastructure:
```
class ReportGenerator {
  private db = new MySQLDatabase()  // Tight coupling to MySQL
}
```
**Fix:**
```
interface Database { query(sql: string): Result }
class ReportGenerator {
  constructor(private db: Database) {}  // Swappable: MySQL, Postgres, mock
}
```

**Reality check:** if SOLID adds layers without reducing risk or improving clarity → don't apply it.

---

## 11. Code to Be Reviewed

Every change will be read by another engineer. Write with that in mind.

- **Keep diffs small and focused** — one PR per concern
- **Meaningful commit messages**: `Add null check to prevent crash when user profile is missing` not `fix bug`
- **No reformatting mixed with logic changes** — they belong in separate commits
- **Self-review before submitting** — read your own diff as if you're reviewing someone else's work

---

## Gotchas — Mistakes That Cause Real Production Bugs

These are concrete errors to avoid, learned from real incidents:

- **Updating a value in 6 places instead of 1**: always ask "where is this defined?" before editing a value
- **Assuming a variable name's meaning**: `d` meant `days` in one context and `discount` in another — causing a retry miscalculation
- **Removing "useless" code without understanding why it exists**: a retry that looked dead was handling transient network failures — removing it caused incidents
- **Mutating state inside a query function**: violates Command/Query separation, causes unpredictable behavior
- **Writing the happy path only**: always ask "what happens if this returns null/undefined/error?"
- **Long functions that batch unrelated operations**: when email sending fails, the whole function retries, duplicating data — keep operations separate
- **Missing `deleted_at IS NULL` on soft-delete tables**: a query that returns deactivated users looks correct until a customer calls
- **Mocking too much in tests**: tests that mock internals break on every refactor while missing real bugs — test behavior, not implementation

---

## Quick Self-Check Before Finishing

Before marking any code task done, run through:

- [ ] Names reveal intent without needing comments?
- [ ] Every function does one thing?
- [ ] No magic numbers or strings?
- [ ] Edge cases handled (null, empty, error)?
- [ ] No secrets or sensitive data hardcoded?
- [ ] No duplicated logic?
- [ ] Lint and typecheck pass?
- [ ] The next engineer can change this safely?

---

## Workflow

1. **Understand intent** — read the task requirements. Identify the boundary of the change and what must not be touched.
2. **Survey surroundings** — grep/glob for callers, importers, and dependent code. Understand how the changed code fits into the larger system.
3. **Plan the change** — identify the minimal set of files and lines that must change. Prefer surgical edits over rewrites.
4. **Write clear, fail-safe code** — guard clauses over nested ifs. Named constants over magic values. Parameterized queries over string interpolation. Explicit error handling at every boundary.
5. **Self-review the diff** — read your own changes as if reviewing a teammate's PR. Check naming, edge cases, security, and style consistency.
6. **Verify correctness** — run lint, typecheck, and the narrowest test that exercises the change. Fix any failures before claiming completion.

## Error Handling

| Cause | Fix |
|-------|-----|
| Null/undefined cascading through functions | Validate at boundary. Return early with explicit null guards. Never propagate null silently. |
| Nested conditionals creating unreachable branches | Flatten with guard clauses. Return/fail early on invalid states. |
| Long functions mixing I/O with business logic | Separate pure computation from I/O. Extract I/O to dedicated functions. |
| Swallowed exceptions in empty catch blocks | Always log with context and rethrow, or handle explicitly. Never empty catch {}. |
| API/timeout failures with no recovery | Add retry with jitter, timeout, and circuit breaker for every external call. |
| Race conditions from shared mutable state | Use transactions for multi-step writes. Add locking or atomic operations for shared state. |
| Missing auth checks on endpoints | Verify auth middleware is applied to every endpoint. Check authorization for the specific resource, not just login status. |
| Magic numbers scattered across codebase | Extract to named constants with descriptive names and units. |

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| "Manager"/"Helper"/"Handler" classes | Vague naming hides responsibility | Name by intent and domain concept: `OrderRepository`, `TaxCalculator` |
| Functions with 5+ parameters | Argument order bugs, hard to call | Create a request/options object. Limit to 3 max. |
| Comments explaining what the code does | Code should be self-documenting | Refactor until the comment is unnecessary. Keep only "why" comments. |
| Premature abstractions ("just in case") | Adds complexity for imaginary future needs | Abstract only when duplication exists. YAGNI. |
| Mixing concerns in one class/service | One class changes for 3 different reasons | Apply Single Responsibility: persistence, business logic, and notification belong in separate classes. |
| Inheritance chains over 2 levels deep | Implicit behavior, hard to trace | Prefer composition. Inject dependencies explicitly. |
| Processing user input without validation | Injection, corruption, crashes | Validate and sanitize at the system boundary before any processing. |
| Throwing generic Error with no context | Debugging requires grep, not error messages | Include what failed, what identifier, and actionable context in every error. |

## Checklist

- [ ] Function does one thing — if it needs a comment to explain sub-steps, extract them
- [ ] Error handling covers all failure modes (null, network, auth, rate limit)
- [ ] Names are precise and reveal intent (no abbreviations, no generic terms)
- [ ] Tests exist for the critical path (not 100% coverage, but core logic is covered)
- [ ] Security review done for any auth, input, or data exposure surface

## Sources

- Robert C. Martin — "Clean Code" (Prentice Hall)
- Martin Fowler — "Refactoring" (Addison-Wesley, 2nd Edition)
- John Ousterhout — "A Philosophy of Software Design" (Yaknyam Press)
- Michael Feathers — "Working Effectively with Legacy Code" (Prentice Hall)
- Steve McConnell — "Code Complete" (Microsoft Press, 2nd Edition)
- Hunt & Thomas — "The Pragmatic Programmer" (Addison-Wesley, 20th Anniversary)
- Kent Beck — "Implementation Patterns" (Addison-Wesley)
- OWASP Top 10 — owasp.org/www-project-top-ten
