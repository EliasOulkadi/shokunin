---
name: error-handler
description: Design error handling and logging strategies
---


# Error Handler

Generates error handling systems that make debugging fast and production incidents manageable. Based on patterns from Sentry, Datadog, and Google SRE books.

## Error Classification

| Category | HTTP Code | Examples | Action |
|----------|-----------|----------|--------|
| Validation | 400 | Missing field, invalid format | Return details to client |
| Authentication | 401 | Expired token, invalid credentials | Log, return generic message |
| Authorization | 403 | Insufficient permissions | Log with user context |
| Not Found | 404 | Missing resource | Return, log at debug |
| Conflict | 409 | Duplicate, stale version | Return details |
| Rate Limit | 429 | Too many requests | Return Retry-After header |
| Internal | 500 | DB timeout, null reference | Alert, log full context |
| External | 502/503 | Downstream failure | Circuit break, log trace ID |

## Error Response Format

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Human-readable summary",
    "details": [{ "field": "email", "reason": "required" }],
    "request_id": "req_abc123",
    "docs_url": "https://docs.example.com/errors/validation"
  }
}
```

## Logging Standards

```json
{
  "timestamp": "2026-05-12T10:30:00Z",
  "level": "error",
  "message": "Payment processing failed",
  "request_id": "req_abc123",
  "user_id": "user_xyz",
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

- Always log the request_id
- Never log PII, passwords, tokens
- Structured JSON only (no plain text)
- Different log levels per environment

## Error Boundaries

```typescript
// Express example
app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
  const requestId = req.headers['x-request-id'] || crypto.randomUUID()

  logger.error({ message: err.message, error: err, requestId, path: req.path })

  if (err instanceof ValidationError) {
    return res.status(400).json({
      error: { code: 'VALIDATION_ERROR', message: err.message, details: err.details, requestId }
    })
  }

  // Generic fallback
  res.status(500).json({
    error: { code: 'INTERNAL_ERROR', message: 'An unexpected error occurred', requestId }
  })
})
```

## Recovery Patterns

| Pattern | Use | Implementation |
|---------|-----|----------------|
| Retry | Transient failures | Exponential backoff, max 3 retries |
| Circuit breaker | Downstream failures | Trip after 5 failures, half-open after 30s |
| Fallback | Non-critical features | Return cached data, degraded response |
| Bulkhead | Resource isolation | Separate thread pools per dependency |
| Timeout | Unresponsive services | Always set timeouts (default: 10s) |

## Monitoring

- Alert on 5xx rate > 1% over 5 min window
- Alert on p99 latency > 2x p50
- Dashboard: error rate by type, endpoint, status code
- Log persistent errors to exception tracker (Sentry, Datadog)

## Sources
- Google SRE Book
- Sentry error handling docs
- Datadog monitoring docs







