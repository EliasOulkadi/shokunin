---
name: error-handler
description: Design error handling, structured logging, and observability with OpenTelemetry (traces, metrics, logs), error classification, recovery patterns (retry with jitter, circuit breaker, bulkhead, timeout), error budgets/SLOs with burn rate alerts, and production incident triage. Use when user asks to implement error handling, logging, monitoring, observability, OpenTelemetry, error boundaries, circuit breakers, retry logic, or SLO tracking. Do NOT use for incident runbooks (use runbook-gen), vendor-specific APM setup (Datadog, Sentry agent config), or K8s debugging.
license: MIT
compatibility: opencode
metadata:
  workflow: backend
  audience: developers
  version: "3.0"
  author: shokunin
allowed-tools: Read Bash Write Grep
---

# Error Handler

Build observability systems that make debugging fast and production incidents predictable. Based on Google SRE, OpenTelemetry semantic conventions, and production patterns from Sentry and Datadog.

## Workflow

### Step 1: Classify errors

| Category | HTTP | Severity | Log level | Alert? |
|----------|------|----------|-----------|--------|
| Validation | 400 | Low | debug | No |
| Authentication | 401 | Medium | warn | No |
| Authorization | 403 | Medium | warn | No |
| Not Found | 404 | Low | debug | No |
| Conflict | 409 | Medium | info | No |
| Rate Limit | 429 | Low | warn | No |
| Internal | 500 | High | error | Yes |
| Downstream | 502/3 | High | error | Yes |

### Step 2: Set up OpenTelemetry

Run the setup script to scaffold the instrumentation:
```bash
scripts/setup-opentelemetry.sh
```

This generates `src/telemetry/instrumentation.ts` with:
- NodeSDK + OTLP exporter
- Batch span processor
- Resource attributes (service.name, deployment.environment)
- Auto-instrumentations (http, express, grpc)
- Graceful shutdown handler

See [references/opentelemetry-deep.md](references/opentelemetry-deep.md) for context propagation, sampling strategies, semantic conventions, and metrics types.

### Step 3: Implement structured error middleware

```typescript
// Use the provided template
// See assets/error-middleware.template.ts for the complete middleware

import { trace, SpanStatusCode } from '@opentelemetry/api'

app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
  const span = trace.getActiveSpan()
  span?.recordException(err)
  span?.setStatus({ code: SpanStatusCode.ERROR, message: err.message })

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

  // Generic fallback — never leak internals
  res.status(500).json({
    error: { code: 'INTERNAL_ERROR', message: 'An unexpected error occurred', requestId },
  })
})
```

### Step 4: Apply recovery patterns

```typescript
async function withRetry<T>(
  fn: () => Promise<T>,
  options = { maxRetries: 3, baseMs: 100 }
): Promise<T> {
  for (let attempt = 0; attempt <= options.maxRetries; attempt++) {
    try { return await fn() }
    catch (error) {
      if (attempt === options.maxRetries) throw error
      if (!isRetryable(error)) throw error
      const delay = Math.min(options.baseMs * Math.pow(2, attempt), 10000)
      const jitter = delay * (0.5 + Math.random() * 0.5)
      await new Promise(r => setTimeout(r, jitter))
    }
  }
  throw new Error('Unreachable')
}

function isRetryable(error: any): boolean {
  return [408, 429, 502, 503, 504].includes(error?.status) || error?.code === 'ETIMEDOUT'
}
```

### Step 5: Define error budgets and alerts

See [references/error-budgets.md](references/error-budgets.md) for complete SLO calculation, burn rate alerts, and dashboard setup.

**Quick setup:**
| Severity | Burn rate | Window | Response |
|----------|-----------|--------|----------|
| Critical | 6x (budget exhausted in 4.6d) | 5m | Page on-call |
| Warning | 3x (budget exhausted in 9.3d) | 30m | Next-business-day |

```promql
# Burn rate alert (critical)
sum(rate(http_requests_total{status=~"5.."}[5m]))
/
sum(rate(http_requests_total[5m]))
> 0.001 * 6  # 99.9% SLO, 6x burn rate
```

## Error Handling

| Scenario | Cause | Fix |
|----------|-------|-----|
| No trace context in logs | Missing instrumentation | Add auto-instrumentation package |
| Spans not appearing in backend | Wrong OTLP endpoint | Check `OTEL_EXPORTER_OTLP_ENDPOINT` env var |
| Circuit breaker never opens | Threshold too high | Start with 5 failures in 30s window |
| Retries not happening | isRetryable() too strict | Add 503, 504, ETIMEDOUT to retryable |
| Error budget exhausted fast | SLO too tight | Review: is 99.9% needed for this service? |

## Production Checklist

- [ ] OpenTelemetry SDK initialized at app startup
- [ ] Auto-instrumentations for HTTP, DB, messaging
- [ ] Every route handler wrapped in try/catch or middleware
- [ ] Structured JSON logging (never plain text)
- [ ] trace_id + span_id in every log line
- [ ] Recovery patterns (retry + circuit breaker) on external calls
- [ ] Timeouts on all external calls (default 10s)
- [ ] SLOs defined for critical services
- [ ] Burn rate alerts configured
- [ ] No PII/tokens in logs
- [ ] Error classification by type, not generic catch-all

## Anti-Patterns

| Anti-pattern | Fix |
|-------------|-----|
| Log in catch AND rethrow | Log OR throw. Not both. |
| Generic error messages | Include code, request_id, details |
| No trace in async flows | Propagate context across queues/events |
| Silent catch with no log | Every catch handles, logs, or rethrows |
| Retry non-retryable (400, 401) | Check status before retry |
| No timeout on external calls | Always set connection + read timeouts |
| No error classification | Classify and handle by category |
| Plain text logs | Structured JSON with consistent fields |

## Sources

- Google SRE Book — Monitoring Distributed Systems
- OpenTelemetry docs (opentelemetry.io)
- Google SRE Workbook — Burn rate alerts
- Sentry error handling docs
- AWS Well-Architected — Reliability Pillar
- Microsoft Polly — Circuit breaker
