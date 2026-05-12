---
name: api-docs
description: Generate API documentation from specs
---


# API Docs

Generates API documentation that developers can integrate with in minutes. Based on documentation standards from Stripe, Twilio, and GitHub.

## Structure per Endpoint

```
### [HTTP Method] [Path]

**Description**: one sentence

**Auth required**: Yes/No [type]

**Request**
  Headers: [required headers]
  Parameters: [path/query/body]

**Response 200**
  Body: [shape with example]

**Error responses**
  400: [description]
  401: [description]
  404: [description]

**Example**
```curl
curl -X GET "https://api.example.com/v1/users" \
  -H "Authorization: Bearer $TOKEN"
```

**Notes**: [gotchas, rate limits, pagination]
```

## Documentation Sections

1. **Overview**: what the API does, base URL, authentication
2. **Quickstart**: 3-step example to make a successful call
3. **Core resources**: your main endpoints, ordered by importance
4. **Advanced**: webhooks, batch operations, rate limits
5. **Errors**: complete error catalog with causes and fixes
6. **Changelog**: what changed, when, migration guides

## Authentication Section

```
All requests require a Bearer token in the Authorization header.

Get your token at: [dashboard URL]

Authorization: Bearer sk_live_abc123...
         â•°â”€â”€ starts with sk_live_ for production
```

Show real examples of tokens (test keys), with clear format.

## Example Quality

Each example must be:
- Runnable (copy-paste into terminal)
- Include the response
- Cover one scenario clearly
- Use realistic but fake data (example.com, user_abc, etc.)

Include SDK examples in the 3 most popular languages for your audience.

## Code Generation

When generating docs from OpenAPI 3.1:

```yaml
paths:
  /users:
    get:
      summary: List all users
      parameters:
        - name: limit
          in: query
          schema: { type: integer, maximum: 100 }
      responses:
        '200':
          description: Successful response
          content:
            application/json:
              schema:
                type: object
                properties:
                  data: { type: array, items: { $ref: '#/components/schemas/User' } }
                  meta: { $ref: '#/components/schemas/Pagination' }
```

## Documentation Checklist

- [ ] Every endpoint has a description
- [ ] Every parameter is documented (name, type, required, default, example)
- [ ] Every error response is documented
- [ ] Authentication section with real example
- [ ] Rate limits documented (requests per window)
- [ ] Pagination explained if applicable
- [ ] Changelog with dates and migration notes
- [ ] Postman collection or OpenAPI spec downloadable

## Sources
- Stripe API documentation (reference)
- Twilio API docs standards
- OpenAPI 3.1 Specification







