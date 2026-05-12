---
name: api-forge
description: Design REST/GraphQL APIs with OpenAPI and validation
---


# API Forge

Generates API designs that developers love to integrate with. Based on REST best practices from Stripe, GitHub, Twilio, Xano, and the OpenAPI 3.1 specification.

## Resource Naming

| Pattern | Example | Notes |
|---------|---------|-------|
| Nouns, plural | `/users`, `/orders` | Never verbs |
| Nested resources | `/users/{id}/orders` | Max 2 levels deep |
| Actions as sub-resources | `/orders/{id}/cancel` | Only for non-CRUD |
| Query for filters | `/users?role=admin` | Not `/users/admins` |

## HTTP Methods

| Method | Purpose | Idempotent | Body |
|--------|---------|------------|------|
| GET | Read resource | Yes | No |
| POST | Create resource | No | Yes |
| PUT | Full replace | Yes | Yes |
| PATCH | Partial update | No | Yes |
| DELETE | Remove resource | Yes | Optional |

## Response Format

Always wrap in a standard envelope. Include request ID for debugging.

```json
{
  "data": { },
  "meta": {
    "page": 1,
    "per_page": 25,
    "total": 100
  },
  "error": null
}
```

## Error Handling

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Email is required",
    "details": [
      { "field": "email", "code": "required", "message": "Email is required" }
    ],
    "request_id": "req_abc123"
  }
}
```

Status codes: 200 (ok), 201 (created), 400 (validation), 401 (unauth), 403 (forbidden), 404 (not found), 409 (conflict), 429 (rate limit), 500 (server error).

## Pagination

Use cursor-based pagination for production APIs. Page-based only for small datasets.

```json
GET /items?cursor=abc123&limit=25
{
  "data": [...],
  "meta": { "next_cursor": "def456", "has_more": true }
}
```

## Rate Limiting

Headers: `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`. Return 429 with `Retry-After` when exceeded.

## Versioning

URL path versioning: `/v1/users`, `/v2/users`. Deprecate with `Sunset` header, maintain 6-month migration window.

## API Security Checklist

- [ ] HTTPS enforced (HTTP redirects)
- [ ] CORS configured per environment
- [ ] Input validation at boundary
- [ ] Parameterized queries (no SQL injection)
- [ ] No secrets in responses
- [ ] Rate limiting on auth endpoints
- [ ] Request size limits

## Sources

- Xano "Modern API Design Best Practices for 2026"
- YoungJu "REST API Design Best Practices 2025" (naming, versioning, error handling)
- Fern "API Design Best Practices Guide" (March 2026)
- Hakia "API Design Best Practices: Building Scalable REST APIs in 2026"
- Jeff Sternal "How to (and How Not to) Design REST APIs" (2025 edition)
- OpenAPI 3.1 Specification (openapis.org)







