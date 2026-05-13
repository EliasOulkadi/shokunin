---
name: error-handler
description: Design error handling and logging strategies with OpenTelemetry (traces, metrics, logs), error classification, structured logging, recovery patterns (retry, circuit breaker, bulkhead), and error budgets/SLOs. Use when user asks to implement error handling, logging, alerts, monitoring, observability, or incident response patterns. Do NOT use for incident runbooks (use runbook-gen), APM setup (vendor-specific), or Docker/K8s debugging.
license: MIT
compatibility: opencode
metadata:
  workflow: backend
  audience: developers
  version: "2.0"
---

# Error Handler

Build observability systems that make debugging fast and production incidents manageable. Based on Google SRE, OpenTelemetry, and patterns from Sentry and Datadog.

## Workflow

### Step 1: Classify errors

| Category | HTTP Code | Examples | Severity | Action |
|----------|-----------|----------|----------|--------|
| Validation | 400 | Missing field, invalid format | Low | Return details, log debug |
| Authentication | 401 | Expired token, invalid credentials | Medium | Log warning, generic message |
| Authorization | 403 | Insufficient permissions | Medium | Log with user context |
| Not Found | 404 | Missing resource | Low | Log debug |
| Conflict | 409 | Duplicate, stale version | Medium | Return details |
| Rate Limit | 429 | Too many requests | Low | Retry-After header |
| Internal | 500 | DB timeout, null ref | High | Alert, full context |
| Downstream | 502/503 | External service failure | High | Circuit break, trace |

### Step 2: Implement structured logging

```json
{
  "timestamp": "2026-05-12T10:30:00Z",
  "level": "error",
  "message": "Payment processing failed",
  "service": "payment-service",
  "trace_id": "trac_abc123",
  "span_id": "span_def456",
  "error": {
    "type": "StripeAPIError",
    "code": "card_declined",
    "stack": "Error: ..."
  },
  "context": {
    "order_id": "order_456",
    "amount": 2999,
    "currency": "USD"
  },
  "duration_ms": 452
}
```

Rules:
- Structured JSON only (never plain text)
- Always include trace_id + span_id
- Never log PII, passwords, tokens, or secrets
- Use semantic conventions for field names

### Step 3: Add OpenTelemetry tracing

```typescript
import { trace, SpanStatusCode } from '@opentelemetry/api'

async function processPayment(orderId: string) {
  const tracer = trace.getTracer('payment-service')
  const span = tracer.startSpan('processPayment', {
    attributes: { orderId, amount: 2999 },
  })

  try {
    const result = await stripeClient.charges.create({ ... })
    span.setStatus({ code: SpanStatusCode.OK })
    return result
  } catch (error) {
    span.recordException(error)
    span.setStatus({
      code: SpanStatusCode.ERROR,
      message: error.message,
    })
    throw error
  } finally {
    span.end()
  }
}
```

### Step 4: Implement error boundaries

```typescript
// Express middleware
app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
  const span = trace.getActiveSpan()
  span?.recordException(err)
  span?.setStatus({ code: SpanStatusCode.ERROR })

  const requestId = req.headers['x-request-id'] || crypto.randomUUID()

  logger.error({
    message: err.message,
    error: err,
    requestId,
    trace_id: span?.spanContext().traceId,
    path: req.path,
  })

  if (err instanceof ValidationError) {
    return res.status(400).json({
      error: { code: 'VALIDATION_ERROR', message: err.message, details: err.details, requestId },
    })
  }

  if (err instanceof AuthError) {
    return res.status(401).json({
      error: { code: 'UNAUTHORIZED', message: 'Invalid credentials', requestId },
    })
  }

  // Generic fallback — never leak internals
  res.status(500).json({
    error: { code: 'INTERNAL_ERROR', message: 'An unexpected error occurred', requestId },
  })
})
```

### Step 5: Apply recovery patterns

| Pattern | Use | Implementation | Config |
|---------|-----|----------------|--------|
| Retry | Transient failures | Exponential backoff with jitter | Max 3 retries, base 100ms, cap 10s |
| Circuit breaker | Downstream failures | Trip after 5 failures in 30s, half-open after 30s | 5 failures, 30s cooldown |
| Fallback | Non-critical features | Return cached/default data | Cache TTL: 5 min |
| Bulkhead | Resource isolation | Separate thread/connection pool per dependency | Pool size = 10 |
| Timeout | Unresponsive services | Always set timeouts | Default: 10s, per-call configurable |

#### Retry with exponential backoff + jitter

```typescript
async function withRetry<T>(
  fn: () => Promise<T>,
  options: { maxRetries?: number; baseMs?: number; maxMs?: number } = {}
): Promise<T> {
  const { maxRetries = 3, baseMs = 100, maxMs = 10000 } = options

  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    try {
      return await fn()
    } catch (error) {
      if (attempt === maxRetries) throw error
      if (!isRetryable(error)) throw error

      const delay = Math.min(baseMs * Math.pow(2, attempt), maxMs)
      const jitter = delay * (0.5 + Math.random() * 0.5)
      await new Promise(resolve => setTimeout(resolve, jitter))
    }
  }
  throw new Error('Unreachable')
}

function isRetryable(error: any): boolean {
  const retryableStatuses = [408, 429, 502, 503, 504]
  return retryableStatuses.includes(error?.status) || error?.code === 'ETIMEDOUT'
}
```

#### Circuit breaker

```typescript
class CircuitBreaker {
  private failures = 0
  private lastFailureTime = 0
  private state: 'closed' | 'open' | 'half-open' = 'closed'

  constructor(
    private threshold = 5,
    private cooldownMs = 30000,
    private halfOpenMaxRequests = 3
  ) {}

  async call<T>(fn: () => Promise<T>): Promise<T> {
    if (this.state === 'open') {
      if (Date.now() - this.lastFailureTime > this.cooldownMs) {
        this.state = 'half-open'
        this.failures = 0
      } else {
        throw new CircuitBreakerOpenError()
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
      if (this.failures >= this.threshold) {
        this.state = 'open'
      }
      throw error
    }
  }
}
```

### Step 6: Set up monitoring and alerting

#### Error budgets (SLO-based)

```yaml
service: payment-api
slo:
  - name: availability
    target: 99.9%       # ~43 min downtime per month
    measurement: good_requests / total_requests
    window: 28d
  - name: latency
    target: 99% under 500ms
    measurement: p99 latency
    window: 7d

error_budget:
  burn_rate_alerts:
    - name: critical
      burn_rate: 6        # exhaust budget in 4.6 days
      window: 5m
    - name: warning
      burn_rate: 3        # exhaust budget in 9.3 days
      window: 30m
```

#### Alert rules

| Condition | Severity | Response |
|-----------|----------|----------|
| 5xx rate > 1% over 5 min | Critical | Page on-call |
| p99 latency > 2x p50 over 15 min | Warning | Investigate next business day |
| Error budget consumed > 50% | Warning | Review during office hours |
| Any 500 on critical endpoint | Critical | Page immediately |
| Downstream dependency unavailable | High | Route traffic, page on-call |

## Anti-Patterns

| Anti-pattern | Fix |
|-------------|-----|
| Logging in catch and throwing again | Log OR throw. Not both. Higher level catches once. |
| Generic error messages | Include error code, request_id, and details |
| No tracing in async flows | Propagate trace context across queues, events, and background jobs |
| Silent catch with no logging | Every catch either handles, logs, or re-throws |
| Retrying non-retryable errors (400, 401, 403) | Check status before retrying |
| No timeout on external calls | Always set connection + read timeouts |
| Monolithic error handler | Classify errors and handle by category |
| No structured logging | Machine-parseable JSON with consistent fields |

## Sources

- Google SRE Book — Monitoring Distributed Systems
- OpenTelemetry Documentation (opentelemetry.io)
- Sentry Error Handling Docs
- Datadog Monitoring Best Practices
- AWS Well-Architected Framework — Reliability Pillar
- Microsoft Polly — Circuit breaker patterns
- Burn Rate Alerts (Google SRE Workbook)
