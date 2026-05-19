---
name: api-forge
description: Design REST/GraphQL APIs with OpenAPI 3.1, error handling, pagination, rate limiting, webhooks, and idempotency. Use when user asks to design an API, create endpoints, define REST/GraphQL schema, or generate OpenAPI spec. Do NOT use for database schema design, frontend API integration, or non-HTTP protocols (gRPC, WebSocket, MQTT).
triggers:
  - "design an API"
  - "create endpoints"
  - "REST API"
  - "GraphQL schema"
  - "OpenAPI spec"
  - "rate limiting"
  - "webhooks"
  - "idempotency"
  - "API pagination"
  - "API versioning"
  - "API security"
negatives:
  - "database schema"
  - "frontend integration"
  - "gRPC"
  - "WebSocket"
  - "MQTT"
  - "database design"
license: MIT
compatibility: opencode
metadata:
  workflow: backend
  audience: developers
  version: "4.0.0"
  author: shokunin
---


# API Forge

Design APIs that developers love. Based on patterns from Stripe, GitHub, Twilio, Slack, and the OpenAPI 3.1 specification.

## Sub-Commands

| Command | Category | Description |
|---------|----------|-------------|
| `design` | Build | Design an API from user requirements. Generate OpenAPI 3.1 spec. |
| `endpoint` | Build | Design a single endpoint with all methods, parameters, responses, and error codes. |
| `audit` | Evaluate | Audit an existing API against design rules, security checklist, and anti-patterns. |
| `document` | Document | Generate API documentation from OpenAPI spec or route handlers. |
| `extract` | Document | Extract OpenAPI spec from existing route handlers. |
| `webhook` | Build | Design webhook delivery, retry, and signature verification. |

## Workflow

### Step 1: Determine API type

| Type | Use Case | Spec |
|------|----------|------|
| REST | CRUD, resource-oriented | OpenAPI 3.1 |
| GraphQL | Complex queries, multiple resources | Schema Definition Language |
| Webhook | Event-driven, async notifications | Standard webhooks (Stripe pattern) |

### Step 2: Define resources and naming

| Pattern | Example | Notes |
|---------|---------|-------|
| Nouns, plural | `/users`, `/orders` | Never verbs |
| Nested (max 2 levels) | `/users/{id}/orders` | Flat preferred over deep nesting |
| Actions as sub-resources | `/orders/{id}/cancel` | Only for non-CRUD operations |
| Query for filters | `/users?role=admin` | Not `/users/admins` |
| kebab-case for paths | `/order-items` | Not `/orderItems` |
| snake_case for fields | `first_name` | Not `firstName` in JSON:API |

### Step 3: Map HTTP methods

| Method | Purpose | Idempotent | Safe | Body |
|--------|---------|:--:|:--:|:--:|
| GET | Read resource | Yes | Yes | No |
| POST | Create resource | No | No | Yes |
| PUT | Full replace | Yes | No | Yes |
| PATCH | Partial update | No | No | Yes |
| DELETE | Remove resource | Yes | No | Optional |

### Step 4: Design response format

Stripe-style standard envelope:

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

**Cursor-based** for production. Page-based only for admin/internal tools.

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

Cursor must be opaque (base64-encoded compound key). Never expose internal IDs. Maximum limit: 100. Default: 25.

## Error Handling

Every error response includes:
- `code`: machine-readable error code (`VALIDATION_ERROR`, `NOT_FOUND`, `RATE_LIMITED`)
- `message`: human-readable summary, max 150 chars
- `details`: array of field-level errors for validation
- `request_id`: UUIDv4 for debugging correlation
- `docs_url`: link to error documentation (optional, strongly recommended)

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Email is required",
    "details": [
      { "field": "email", "code": "required", "message": "Email is required" }
    ],
    "request_id": "req_a1b2c3d4e5f6",
    "docs_url": "https://docs.example.com/errors/validation"
  }
}
```

### Status codes — exact mapping

| Code | When | What to return |
|------|------|---------------|
| 200 | Success (GET, PUT, PATCH) | Resource + meta |
| 201 | Created (POST) | Created resource + `Location` header |
| 204 | No content (DELETE) | Empty body |
| 400 | Validation error | Error details + fields |
| 401 | Missing/invalid auth | Generic message. Never reveal which part of auth failed. |
| 403 | Insufficient permissions | Generic message |
| 404 | Resource not found | Minimal. Don't reveal if the resource ever existed. |
| 409 | Conflict (duplicate, stale version) | Details of conflicting field |
| 422 | Unprocessable entity | Validation details |
| 429 | Rate limited | `Retry-After` header (seconds) |
| 500 | Internal error | Generic message. No stack traces. No internal state. |
| 502 | Downstream failure | "Service temporarily unavailable" |
| 503 | Maintenance / overload | `Retry-After` header |

## Rate Limiting

### Algorithm decision

| Algorithm | Best for | Behavior |
|-----------|----------|----------|
| Token Bucket | General purpose, bursts allowed | Tokens refill at configurable rate. Allows bursts up to bucket size. |
| Sliding Window | Strict fairness, multi-tenant | Counts requests in rolling time window. No burst edge at boundaries. |
| Fixed Window | Simple, non-critical | Resets at interval. Budget edge problem at boundaries. |

**Default: Token Bucket.**

### Headers (every response)

```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 42
X-RateLimit-Reset: 1700000000
```

Return `429 Too Many Requests` with `Retry-After` header when exceeded.

### Rate limit tiers (exact values)

| Tier | Requests | Window | Per |
|------|----------|--------|-----|
| Anonymous | 60 | 60s | IP |
| Authenticated | 1000 | 60s | User ID + endpoint group |
| Critical endpoints | 5 | 15min | IP + identifier |

Critical: login (5/15min per IP+username), password reset (3/60min per email), MFA (3/15min per user).

## Versioning

| Strategy | Example | When | Risk |
|----------|---------|------|------|
| URL path | `/v1/users` | Default for REST APIs | URL pollution |
| Header | `Accept: application/vnd.api+json;version=2` | Clean URLs needed | Harder to discover |
| Query param | `/users?version=2` | Simple, transitional | Cache poisoning risk |

Prefer URL path for public APIs. Deprecate with sunset headers. 6-month migration window minimum.

```
Deprecation: true
Sunset: Sat, 12 May 2027 00:00:00 GMT
```

## Webhooks

### Delivery format (Stripe pattern)

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

### Delivery protocol

- Retry: exponential backoff (1s, 2s, 4s, 8s, 16s, 32s…)
- Max retries: 3. Max TTL: 24 hours.
- Expect 200 response within 5 seconds.
- Signature: HMAC-SHA256.

### Signature verification (exact implementation)

```
X-Webhook-Signature: t=1700000000,v1=abc123def456...
```

```typescript
function verifyWebhook(payload: string, signature: string, secret: string): boolean {
  const [timestampStr, signatures] = signature.split(',').map(s => s.trim())
  const timestamp = timestampStr.split('=')[1]

  const expected = crypto
    .createHmac('sha256', secret)
    .update(`${timestamp}.${payload}`)
    .digest('hex')

  return crypto.timingSafeEqual(
    Buffer.from(expected),
    Buffer.from(signatures.split('=')[1])
  )
}
```

## Idempotency

| Header | Value | TTL |
|--------|-------|-----|
| `Idempotency-Key` | UUIDv4 | 24 hours |

Return cached response (same status, same body) if same key seen within TTL. Return `409 Conflict` if different request body arrives with same key.

## API Security Checklist

- [ ] HTTPS enforced (HTTP → 301 redirect)
- [ ] TLS 1.2+ only (no TLS 1.0/1.1)
- [ ] CORS whitelist per environment, never `*` with credentials
- [ ] Input validation at boundary (Zod, Joi, Pydantic)
- [ ] Parameterized queries (no SQL injection). Never string interpolation.
- [ ] No secrets in responses, logs, or error messages
- [ ] Rate limiting on auth + password endpoints
- [ ] Request size limit: 1MB default, configurable per endpoint
- [ ] Body parsing limits (depth, field count, string length)
- [ ] Security headers: `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Content-Security-Policy`

## OpenAPI 3.1 Generation

Every endpoint needs:
- `summary`: one sentence. Verb + resource.
- `parameters`: name, in, required, schema, description, example
- `responses`: every possible status code
- `requestBody` (for POST/PUT/PATCH): `content`, `schema`, `required`

## GraphQL

### Schema design

- Queries for read, Mutations for write, Subscriptions for real-time
- Max 3 nesting levels per query
- `@deprecated(reason: "Use fieldX instead")` for removals
- DataLoader for N+1 prevention
- Complexity limits: max depth 5, max cost 1000

### Error handling

```json
{
  "errors": [
    {
      "message": "Validation error",
      "extensions": {
        "code": "VALIDATION_ERROR",
        "field": "email",
        "request_id": "req_abc123"
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
| Breaking changes without migration | Version via URL, deprecation + sunset headers |
| No idempotency on POST creates | Add `Idempotency-Key` header support |
| Inconsistent error format across endpoints | Standard envelope for all errors |
| GraphQL without complexity limits | Implement query depth + cost analysis |
| Nested resources > 2 levels | Restructure. Deep nesting = tight coupling. |
| POST for everything | Use correct HTTP methods. GET=read, PUT=replace, PATCH=partial. |

## Production Checklist

- [ ] All endpoints documented with OpenAPI 3.1
- [ ] Envelope: `{ data, meta, error, request_id }` on every response
- [ ] Cursor-based pagination for public endpoints
- [ ] Rate limit headers on every response
- [ ] Rate limiting on auth endpoints (5/15min login, 3/60min reset)
- [ ] Idempotency-Key support on POST/PATCH
- [ ] Webhook signature verification (HMAC-SHA256)
- [ ] Security headers on every response
- [ ] CORS whitelist (never `*` with credentials)
- [ ] Input validation at boundary
- [ ] Parameterized queries everywhere
- [ ] Error responses include `request_id` and `code`
- [ ] Versioning strategy defined (URL path preferred)
- [ ] Deprecation + Sunset headers on deprecated endpoints

## Sources

- Stripe API Reference — idempotency, pagination, webhooks, error format
- GitHub REST API — resource naming, versioning
- Twilio API — webhook signature verification
- OpenAPI 3.1 Specification (openapis.org)
- JSON:API Specification (jsonapi.org)
- GraphQL Relay Connection Specification
- IETF RFC 7231 — HTTP semantics
- IETF RFC 6585 — Additional HTTP status codes
- Slack API — rate limiting headers

## Checklist

- [ ] Skill loads without errors in the AI agent
- [ ] YAML frontmatter is valid (description, compatibility, audience)
- [ ] Workflow section provides clear step-by-step instructions
- [ ] Error handling section covers common failure modes
- [ ] All referenced files (references/, scripts/, assets/) exist
- [ ] Skill triggers correctly for intended use cases
- [ ] No broken links or missing resources
