---
name: auth-architect
description: Implement auth with OWASP security standards
---


# Auth Architect

Generates authentication and authorization systems that follow OWASP Top 10, CWE/SANS guidelines, and production security patterns from AWS, Auth0, and OWASP Cheat Sheet Series.

## Authentication Methods

| Method | Use Case | Security Level |
|--------|----------|----------------|
| Session-based (httpOnly cookies) | Traditional web apps | High (with CSRF) |
| JWT access + refresh tokens | APIs, SPAs, mobile | Medium (token storage matters) |
| OAuth 2.0 / OIDC | Third-party auth, SSO | High (delegated) |
| API keys | Machine-to-machine, CLIs | Medium (key rotation needed) |
| WebAuthn / Passkeys | Passwordless, high security | Very High |

## Password Requirements

- Minimum 12 characters (not 8)
- No composition rules (uppercase, number, symbol required â€” these weaken security)
- Check against known breached passwords (HaveIBeenPwned API)
- BCrypt with cost factor 12 (or Argon2id)
- Rate limit to 5 attempts per 15 minutes per IP/username

## JWT Best Practices

```json
{
  "iss": "https://api.example.com",
  "sub": "user_abc123",
  "aud": ["web", "mobile"],
  "exp": 900,        // 15 min for access
  "iat": 1700000000,
  "jti": "unique_id",
  "sid": "session_id"
}
```

- Access tokens: 15 min expiry
- Refresh tokens: 7 day expiry, rotate on use
- Store JWTs in httpOnly, Secure, SameSite=Strict cookies â€” NOT localStorage
- Implement token revocation (deny-list for critical actions)

## Session Management

- Generate session ID via crypto.randomUUID() â€” never sequential
- Store sessions server-side (Redis with TTL)
- Rotate session ID on privilege escalation
- Terminate all sessions on password change
- Idle timeout: 30 min for sensitive apps
- Absolute timeout: 24 hours

## CSRF Protection

- SameSite=Strict on cookies
- CSRF tokens for state-changing requests
- Double-submit cookie pattern as fallback

## API Security

- CORS: whitelist specific origins, never `*` with credentials
- Rate limit by user ID + IP
- Request size limits (1MB default)
- Body parsing limits
- SQL injection: parameterized queries only
- No secrets in error messages

## Breach Response

- Log all auth events (login, logout, failure, password change)
- Alert on anomalous patterns (multiple geo-locations, rapid attempts)
- Support account recovery with out-of-band verification
- Notify users on security changes (new device, password change)

## Sources
- OWASP Top 10 (2025)
- OWASP Cheat Sheet Series
- NIST SP 800-63B
- IETF RFC 7519 (JWT)








