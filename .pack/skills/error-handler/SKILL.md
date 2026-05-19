---
name: error-handler
description: Design error handling, structured logging, and observability with OpenTelemetry (traces, metrics, logs), error classification, recovery patterns (retry with jitter, circuit breaker, bulkhead, timeout), error budgets/SLOs with burn rate alerts, and production incident triage. Use when user asks to implement error handling, logging, monitoring, observability, OpenTelemetry, error boundaries, circuit breakers, retry logic, or SLO tracking. Do NOT use for incident runbooks (use runbook-gen), vendor-specific APM setup (Datadog, Sentry agent config), or K8s debugging.
triggers:
  - "error handling"
  - "logging"
  - "observability"
  - "OpenTelemetry"
  - "error boundary"
  - "circuit breaker"
  - "retry logic"
  - "SLO"
  - "error budget"
  - "structured logging"
  - "monitoring"
  - "tracing"
negatives:
  - "incident runbook"
  - "on-call"
  - "Datadog setup"
  - "Sentry config"
  - "K8s debugging"
  - "APM vendor setup"
license: MIT
compatibility: opencode
metadata:
  workflow: backend
  audience: developers
  version: "4.0.0"
  author: shokunin
allowed-tools: Read Bash Write Grep
---


# Error Handler

Observability that makes debugging fast and production predictable. Based on Google SRE (Site Reliability Engineering), OpenTelemetry semantic conventions, and production patterns from Sentry, Honeycomb, and Datadog.

## Sub-Commands

| Command | Description |
|---------|-------------|
| `setup` | Set up OpenTelemetry SDK + instrumentation for a service |
| `classify` | Classify errors by HTTP status, severity, and alert priority |
| `recover` | Implement recovery patterns: retry with jitter, circuit breaker, timeout |
| `slo` | Define error budget, SLO, and burn rate alerts |
| `audit` | Audit existing error handling against best practices |

## The 3 Signals (OpenTelemetry)

| Signal | Purpose | Example |
|--------|---------|---------|
| Traces | Follow a request across services | User request ? API Gateway ? Auth ? DB |
| Metrics | Aggregate measurements over time | Request count, error rate, latency p50/p95/p99 |
| Logs | Discrete events with context | "User login failed: invalid credentials for user_abc123" |

All three signals share `trace_id` + `span_id` for correlation.

## Workflow

### Step 1: Classify errors

| Category | HTTP | Severity | Log level | SLO impact | Alert? |
|----------|------|:--------:|-----------|:----------:|:------:|
| Validation (user error) | 400 | Low | info | No | No |
| Authentication | 401 | Medium | warn | No | Only if spike detected |
| Authorization | 403 | Medium | warn | No | Only if spike detected |
| Not Found | 404 | Low | debug | No | No |
| Conflict | 409 | Medium | info | No | No |
| Rate Limit | 429 | Low | warn | No | No |
| Internal | 500 | High | error | Yes | Yes |
| Downstream failure | 502/503 | High | error | Yes | Yes |
| Timeout | 504 | High | error | Yes | Yes |

### Step 2: Set up OpenTelemetry (exact configuration)

```typescript
import { NodeSDK } from '@opentelemetry/sdk-node'
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http'
import { Resource } from '@opentelemetry/resources'
import { ATTR_SERVICE_NAME } from '@opentelemetry/semantic-conventions'

const sdk = new NodeSDK({
  resource: new Resource({
    [ATTR_SERVICE_NAME]: 'api-service',
    'deployment.environment': process.env.NODE_ENV,
  }),
  traceExporter: new OTLPTraceExporter({
    url: process.env.OTEL_EXPORTER_OTLP_ENDPOINT,
  }),
  instrumentations: [
    new HttpInstrumentation(),
    new ExpressInstrumentation(),
    new PgInstrumentation(),
    new RedisInstrumentation(),
  ],
})

sdk.start()

process.on('SIGTERM', async () => {
  await sdk.shutdown()
})
```

**Sampling strategy:**
- Dev/staging: AlwaysOn (100%)
- Production: `ParentBased` + `TraceIdRatioBased(0.1)` (10% head-based)
- Never sample errors out. Use `AlwaysOn` for traces with `status=ERROR`.


> **Import note:** `ParentBasedSampler` is imported from `@opentelemetry/sdk-trace-base`, NOT from `@opentelemetry/sdk-node`. If using `@opentelemetry/sdk-node`, configure it via the `sampler` option in `NodeSDK` constructor.
### Step 3: Implement structured error middleware

```typescript
import { trace, SpanStatusCode } from '@opentelemetry/api'
import { randomUUID } from 'crypto'

app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
  const span = trace.getActiveSpan()
  const requestId = req.headers['x-request-id'] || randomUUID()

  span?.recordException(err)
  span?.setStatus({ code: SpanStatusCode.ERROR, message: err.message })

  logger.error({
    message: err.message,
    errorName: err.name,
    stack: err.stack,
    requestId,
    trace_id: span?.spanContext().traceId,
    span_id: span?.spanContext().spanId,
    path: req.path,
    method: req.method,
    userId: req.user?.id,
  })

  if (err instanceof ValidationError) {
    return res.status(400).json({
      error: {
        code: 'VALIDATION_ERROR',
        message: err.message,
        details: err.details,
        requestId,
      },
    })
  }

  if (err instanceof NotFoundError) {
    return res.status(404).json({
      error: { code: 'NOT_FOUND', message: err.message, requestId },
    })
  }

  // Generic fallback - never leak internal state
  res.status(500).json({
    error: {
      code: 'INTERNAL_ERROR',
      message: 'An unexpected error occurred',
      requestId,
    },
  })
})
```

### Step 4: Recovery patterns (exact implementations)

#### Retry with exponential backoff + jitter

```typescript
async function withRetry<T>(
  fn: () => Promise<T>,
  options: { maxRetries?: number; baseMs?: number; maxMs?: number } = {}
): Promise<T> {
  const { maxRetries = 3, baseMs = 200, maxMs = 10000 } = options

  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    try {
      return await fn()
    } catch (error) {
      if (attempt === maxRetries) throw error
      if (!isRetryable(error)) throw error

      const exponentialDelay = baseMs * Math.pow(2, attempt)
      const jitter = Math.random() * 0.3 * exponentialDelay
      const delay = Math.min(exponentialDelay + jitter, maxMs)

      await new Promise(r => setTimeout(r, delay))
    }
  }
  throw new Error('Unreachable')
}

function isRetryable(error: any): boolean {
  const retryableStatuses = [408, 429, 502, 503, 504]
  if (error?.status && retryableStatuses.includes(error.status)) return true
  if (error?.code === 'ETIMEDOUT' || error?.code === 'ECONNRESET') return true
  return false
}

// Never retry: 400, 401, 403, 404, 409, 422
```

#### Circuit breaker

```typescript
class CircuitBreaker {
  private failures = 0
  private state: 'closed' | 'open' | 'half-open' = 'closed'
  private lastFailureTime = 0

  constructor(
    private failureThreshold: number = 5,
    private resetTimeout: number = 30000
  ) {}

  async call<T>(fn: () => Promise<T>): Promise<T> {
    if (this.state === 'open') {
      if (Date.now() - this.lastFailureTime > this.resetTimeout) {
        this.state = 'half-open'
      } else {
        throw new Error('Circuit breaker is open')
      }
    }

    try {
      const result = await fn()
      if (this.state === 'half-open') {
        this.state = 'closed'
        this.failures = 0
      }
      return result
    } catch (error) {
      this.failures++
      this.lastFailureTime = Date.now()

      if (this.failures >= this.failureThreshold) {
        this.state = 'open'
      }
      throw error
    }
  }
}
```

#### Timeout

```typescript
function withTimeout<T>(promise: Promise<T>, timeoutMs: number): Promise<T> {
  const timeout = new Promise<T>((_, reject) =>
    setTimeout(() => reject(new Error(`Operation timed out after ${timeoutMs}ms`)), timeoutMs)
  )
  return Promise.race([promise, timeout])
}

// Usage
const result = await withTimeout(fetch('https://api.example.com/data'), 5000)
```

### Step 5: Error budgets + SLO

| SLO | Error budget (monthly) | Burn rate critical | Burn rate warning |
|-----|------------------------|:-------------------:|:-------------------:|
| 99.9% | 43m 50s | 6x (exhausted in 4.6d) | 3x (exhausted in 9.3d) |
| 99.5% | 3h 39m | 10x (exhausted in 1.1d) | 5x (exhausted in 2.2d) |
| 99% | 7h 18m | 15x (exhausted in 0.5d) | 7.5x (exhausted in 1d) |

**Burn rate alert (PromQL for 99.9% SLO):**
```promql
sum(rate(http_requests_total{status=~"5.."}[5m]))
/
sum(rate(http_requests_total[5m]))
> 0.001 * 6
```

**Multi-window, multi-burn-rate approach** (Google SRE):
- Short window (5m) + high burn rate (6-10x) ? Page on-call immediately
- Long window (1h) + low burn rate (2-3x) ? Ticket for next business day

## Structured Logging Schema

Every log line must be JSON with these fields:

```json
{
  "timestamp": "2026-05-16T10:21:27.000Z",
  "level": "error",
  "message": "Failed to process payment",
  "trace_id": "0af7651916cd43dd8448eb211c80319c",
  "span_id": "b7ad6b7169203331",
  "request_id": "req_a1b2c3d4",
  "service": "payment-service",
  "environment": "production",
  "userId": "user_abc123",
  "path": "/api/payments",
  "method": "POST",
  "duration_ms": 234,
  "error": {
    "name": "PaymentFailedError",
    "message": "Card declined",
    "code": "CARD_DECLINED"
  }
}
```

**Rules:**
- Never log PII, tokens, passwords, or full credit card numbers
- Always include `trace_id`, `span_id`, `request_id` for correlation
- `duration_ms` on every request. p95 > 200ms ? investigate.

## Production Checklist

- [ ] OpenTelemetry SDK initialized at app startup (before any imports)
- [ ] Auto-instrumentations for HTTP, DB, messaging, Redis
- [ ] Every route handler wrapped in try/catch or error middleware
- [ ] Structured JSON logging (never plain text)
- [ ] `trace_id` + `span_id` + `request_id` in every log line
- [ ] Recovery: retry with jitter on external calls. Timeout on every external call.
- [ ] Circuit breaker for critical downstream services
- [ ] SLO defined for every service (99.9% critical, 99.5% standard)
- [ ] Burn rate alerts: multi-window (5m short, 1h long)
- [ ] No PII, tokens, or secrets in logs or error messages
- [ ] Error classification by type (not generic catch-all)
- [ ] Sampling: 10% production, 100% for errors

## Anti-Patterns

| Anti-pattern | Fix |
|-------------|-----|
| Log in catch AND rethrow | Log OR throw. Not both. |
| Generic error messages | Include `code`, `request_id`, `details`. |
| No trace context in async flows | Propagate context via `context.active()`. |
| Silent catch with no log | Every catch logs, handles, or rethrows. |
| Retry non-retryable errors (400, 401) | Check status before retry: `isRetryable()`. |
| No timeout on external calls | Always set connection (2s) + read (10s) timeouts. |
| No error classification | Classify by type and handle accordingly. |
| Plain text logs | Structured JSON with consistent fields. |
| Same retry delay every time | Exponential backoff + jitter. |
| Circuit breaker never tested | Test in staging by killing dependencies. |
| Error budget without alert | Burn rate alerts are mandatory. |

## Error Handling

| Error | Cause | Fix |
|-------|-------|-----|
| OpenTelemetry SDK not exporting traces | Exporter endpoint unreachable or `OTEL_EXPORTER_OTLP_ENDPOINT` not set | Verify endpoint with `curl $OTEL_EXPORTER_OTLP_ENDPOINT/v1/traces`. Set env var before SDK initialization. |
| `ParentBasedSampler` import fails from `@opentelemetry/sdk-node` | Wrong import path | Import from `@opentelemetry/sdk-trace-base`, not `@opentelemetry/sdk-node`. Configure via `sampler` option in `NodeSDK` constructor. |
| Traces missing in production but appear in staging | Sampling rate too low (`TraceIdRatioBased(0.1)` drops 90%) | Use `AlwaysOn` for traces with `status=ERROR`. Never sample errors out. |
| Structured logs have null `trace_id`/`span_id` | Context not propagated into async flow or logger not context-aware | Use `context.active()` before async operations. Inject `trace_id`/`span_id` into every log line via context propagation. |
| Circuit breaker stays open indefinitely | `resetTimeout` is set but `half-open` state logic never triggers | Verify `Date.now() - this.lastFailureTime > this.resetTimeout` comparison. Add logging when state transitions occur. |
| Retry exhausts budget on non-retryable errors | `isRetryable()` returns true for 400/401/403 status codes | Hard-gate retryable statuses: only `[408, 429, 502, 503, 504]` and network errors (`ETIMEDOUT`, `ECONNRESET`). |
| Retry with jitter produces thundering herd | All instances retry at the same time due to identical base delay | Randomize `baseMs` per instance or use `Math.random() * baseMs` as the starting backoff. |
| Burn rate alert fires for low-traffic services | Division by small request count amplifies noise | Set minimum request thresholds: only evaluate SLO when `rate(http_requests_total[5m]) > 1`. |
| Error middleware exposes stack traces to users | Generic `INTERNAL_ERROR` handler includes `err.stack` in response body | Never return `stack` in API responses. Log it server-side; respond with `{ error: { code, message, requestId } }`. |
| PII leaks into structured logs | Full email, IP, SSN, or credit card numbers in log fields | Mask sensitive fields: `email.replace(/(.{3}).*(@.*)/, '$1***$2')`. Configure PII redaction in log pipeline. |
| Timeout wrapped around `fetch` never fires | `Promise.race` with `setTimeout` races against a promise that catches and suppresses errors | Always `reject` in the timeout handler, not `resolve`. The timed-out promise must reject, not resolve. |

## Sources

- Google SRE Book - Monitoring Distributed Systems (Chapter 6)
- Google SRE Workbook - Implementing SLOs (Chapter 5)
- OpenTelemetry documentation (opentelemetry.io)
- OpenTelemetry semantic conventions
- Sentry error handling best practices
- AWS Well-Architected Framework - Reliability Pillar
- Microsoft Polly - Circuit breaker patterns
- Hystrix - Netflix circuit breaker patterns

## Checklist

- [ ] Skill loads without errors in the AI agent
- [ ] YAML frontmatter is valid (description, compatibility, audience)
- [ ] Workflow section provides clear step-by-step instructions
- [ ] Error handling section covers common failure modes
- [ ] All referenced files (references/, scripts/, assets/) exist
- [ ] Skill triggers correctly for intended use cases
- [ ] No broken links or missing resources
