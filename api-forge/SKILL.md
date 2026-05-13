---
name: api-forge
description: Design REST/GraphQL APIs with OpenAPI 3.1, error handling, pagination, rate limiting, webhooks, and idempotency. Use when user asks to design an API, create endpoints, define REST/GraphQL schema, or generate OpenAPI spec. Do NOT use for database schema design, frontend API integration, or non-HTTP protocols (gRPC, WebSocket, MQTT).
license: MIT
compatibility: opencode
metadata:
  workflow: backend
  audience: developers
---

# API Forge

Design APIs that developers love to integrate with. Based on patterns from Stripe, GitHub, Twilio, and the OpenAPI 3.1 specification.

## Workflow

### Step 1: Determine API type

| Type | Use Case | Spec |
|------|----------|------|
| REST | CRUD, resource-oriented | OpenAPI 3.1 |
| GraphQL | Complex queries, multiple resources | Schema Definition Language |
| Webhook | Event-driven, async notifications | Postmark/Standard webhooks |

### Step 2: Define resources and naming

| Pattern | Example | Notes |
|---------|---------|-------|
| Nouns, plural | `/users`, `/orders` | Never verbs |
| Nested (max 2 levels) | `/users/{id}/orders` | Flat preferred over nested |
| Actions as sub-resources | `/orders/{id}/cancel` | Only for non-CRUD operations |
| Query for filters | `/users?role=admin` | Not `/users/admins` |
| kebab-case for paths | `/order-items` | Not `/orderItems` |
| snake_case for fields | `first_name` | Not `firstName` in JSON:API |

### Step 3: Map HTTP methods

| Method | Purpose | Idempotent | Safe | Body |
|--------|---------|------------|------|------|
| GET | Read resource | Yes | Yes | No |
| POST | Create resource | No | No | Yes |
| PUT | Full replace | Yes | No | Yes |
| PATCH | Partial update | No | No | Yes |
| DELETE | Remove resource | Yes | No | Optional |

### Step 4: Design response format

Always wrap in a standard envelope:

```json
{
  "data": {},
  "meta": {
    "page": 1,
    "per_page": 25,
    "total": 100
  },
  "error": null,
  "request_id": "req_abc123"
}
```

If using JSON:API or GraphQL, use their standard envelopes instead.

### Step 5: Implement pagination

Use cursor-based pagination for production APIs. Page-based only for admin/internal tools.

```json
GET /items?cursor=abc123&limit=25
{
  "data": [...],
  "meta": {
    "next_cursor": "def456",
    "has_more": true
  }
}
```

Cursor must be opaque (base64-encoded compound key). Never expose internal IDs.

## Error Handling

Every error response includes:
- `code`: machine-readable error code
- `message`: human-readable summary
- `details`: array of field-level errors (for validation)
- `request_id`: for debugging correlation

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Email is required",
    "details": [
      { "field": "email", "code": "required", "message": "Email is required" }
    ],
    "request_id": "req_abc123",
    "docs_url": "https://docs.example.com/errors/validation"
  }
}
```

### Status codes

| Code | When | Body |
|------|------|------|
| 200 | Success (GET, PUT, PATCH) | Resource |
| 201 | Created (POST) | Resource + Location header |
| 204 | No content (DELETE) | Empty |
| 400 | Validation error | Error details |
| 401 | Missing/invalid auth | Generic message |
| 403 | Insufficient permissions | Generic message |
| 404 | Resource not found | Minimal |
| 409 | Conflict (duplicate, stale version) | Details |
| 422 | Unprocessable entity | Validation details |
| 429 | Rate limited | Retry-After header |
| 500 | Internal error | No details (log internally) |
| 502/503 | Downstream failure | Generic message |

## Rate Limiting

### Algorithms

| Algorithm | Best for | Behavior |
|-----------|----------|----------|
| Token Bucket | General purpose, bursts allowed | Tokens refill at constant rate |
| Sliding Window | Strict fairness | Counts requests in rolling time window |
| Fixed Window | Simple, non-critical | Resets at interval boundaries |

Add these headers to every response:
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 42
X-RateLimit-Reset: 1700000000
```

Return `429 Too Many Requests` with `Retry-After` header when exceeded.

### Rate limit by

- **Anonymous**: IP address
- **Authenticated**: User ID + endpoint group
- **Critical**: Per-endpoint (login, password reset: 5/15min)

## Versioning

| Strategy | Example | Pros | Cons |
|----------|---------|------|------|
| URL path | `/v1/users` | Explicit, easy to route | URL pollution |
| Header | `Accept: application/vnd.api+json;version=2` | Clean URLs | Harder to discover |
| Query param | `/users?version=2` | Simple | Cache poisoning risk |

Prefer URL path versioning. Deprecate with `Sunset` and `Deprecation` headers. Maintain 6-month migration window minimum.

```
Deprecation: true
Sunset: Sat, 12 May 2027 00:00:00 GMT
```

## Webhooks

### Delivery format

```json
{
  "id": "wh_abc123",
  "type": "order.created",
  "created": 1700000000,
  "data": {
    "id": "order_456",
    "status": "paid",
    "total": 2999
  }
}
```

### Best practices

- **Idempotency key**: Include in header, receiver deduplicates
- **Retry**: Exponential backoff, max 3 retries, 24h TTL
- **Signature**: HMAC-SHA256 with secret key, include in header
- **Verification**: Receiver computes signature and compares
- **Response expectation**: Acknowledge with 200 within 5s

### Webhook security

```
X-Webhook-Signature: t=1700000000,v1=abc123def456...
```

Receiver verifies:
```typescript
const expected = crypto
  .createHmac('sha256', secret)
  .update(`${timestamp}.${body}`)
  .digest('hex')
```

## Idempotency

Use for POST/PATCH that could be retried (payment, order creation).

| Header | Value | TTL |
|--------|-------|-----|
| `Idempotency-Key` | UUIDv4 | 24 hours |

Return cached response if same key seen within TTL. Return 409 if different request body with same key.

## API Security Checklist

- [ ] HTTPS enforced (HTTP → 301 redirect)
- [ ] TLS 1.2+ only (no TLS 1.0/1.1)
- [ ] CORS whitelist per environment, never `*` with credentials
- [ ] Input validation at boundary (Zod, Joi, Pydantic)
- [ ] Parameterized queries (no SQL injection)
- [ ] No secrets in responses, logs, or error messages
- [ ] Rate limiting on auth and password endpoints
- [ ] Request size limits (1MB default, configurable)
- [ ] Body parsing limits
- [ ] X-Content-Type-Options: nosniff
- [ ] X-Frame-Options: DENY
- [ ] Content-Security-Policy headers

## OpenAPI 3.1 Generation

Every endpoint needs:

```
openapi: 3.1.0
info:
  title: API Name
  version: 1.0.0
paths:
  /users:
    get:
      summary: List users
      parameters:
        - name: cursor
          in: query
          schema: { type: string }
      responses:
        200:
          description: Paginated list of users
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/UserList'
```

Each parameter must document: name, type, required/optional, description, example, constraints (min, max, pattern).

## GraphQL

### Schema design

- **Queries** for read operations
- **Mutations** for write operations
- **Subscriptions** for real-time events
- Max 3 nesting levels per query
- Use `@deprecated` with reason for removals
- Implement DataLoader for N+1 prevention
- Complexity limits to prevent abusive queries
- Pagination via Connection spec (Relay)

### Error handling

```json
{
  "errors": [
    {
      "message": "Validation error",
      "extensions": {
        "code": "VALIDATION_ERROR",
        "field": "email"
      }
    }
  ]
}
```

## Anti-Patterns

| Anti-pattern | Fix |
|-------------|-----|
| Verbs in URL (`/getUsers`) | Use HTTP methods on noun resources |
| Page-based pagination for real-time data | Cursor-based with opaque cursors |
| No rate limit headers | Include `X-RateLimit-*` on every response |
| Returning 500 with stack trace | Log internally, return generic message |
| Breaking changes without migration | Version via URL, deprecation headers |
| No idempotency on POST creates | Add `Idempotency-Key` header support |
| Inconsistent error format | Standard envelope for all errors |
| GraphQL without complexity limits | Implement query depth + cost analysis |

## Sources

- OpenAPI 3.1 Specification (openapis.org)
- Stripe API Reference — idempotency, pagination, webhooks
- GitHub REST API — resource naming, versioning
- Twilio API — webhook signature verification
- JSON:API Specification (jsonapi.org)
- GraphQL Relay Connection Specification
- IETF RFC 7231 — HTTP semantics
- IETF RFC 6585 — Additional HTTP status codes
