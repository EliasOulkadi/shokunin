---
name: auth-architect
description: Implement authentication and authorization with OWASP Top 10 standards, OAuth 2.0 + OIDC, WebAuthn/Passkeys, session management, and RBAC/ABAC. Use when user asks to implement login, signup, authentication, authorization, JWT, OAuth, SSO, passkeys, MFA, or role-based access. Do NOT use for API key management (use api-forge), encryption at rest, or network-level security (firewalls, WAF).
license: MIT
compatibility: opencode
metadata:
  workflow: backend
  audience: developers
  version: "2.0"
---

# Auth Architect

Production authentication and authorization systems following OWASP Top 10, NIST SP 800-63B, and patterns from Auth0, AWS Cognito, and OWASP Cheat Sheet Series.

## Workflow

### Step 1: Choose auth method

| Method | Use Case | Security Level | Complexity |
|--------|----------|----------------|------------|
| Session-based (httpOnly cookies) | Server-rendered web apps | High | Low |
| JWT access + refresh tokens | SPAs, mobile, APIs | High (with proper storage) | Medium |
| OAuth 2.0 + OIDC | Third-party login, SSO | High | High |
| API keys with HMAC | M2M, CLIs, integrations | Medium | Low |
| WebAuthn / Passkeys | Passwordless, high-security | Very High | Medium |
| Magic links / OTP | Low-friction, email-based | Medium | Low |

### Step 2: Implement authentication

#### Password-based auth

```
1. Validate email format + length
2. Check against breached passwords (HaveIBeenPwned API)
3. Hash with Argon2id (preferred) or BCrypt (cost 12 minimum)
4. Generate session/JWT
5. Return user (never return password hash)
```

**Password requirements** (NIST SP 800-63B):
- Minimum 12 characters
- No composition rules (uppercase, number, symbol required — these weaken security)
- Allow at least 64 characters max
- Allow all printable ASCII + Unicode
- Check against known breached passwords
- Rate limit: 5 attempts per 15 minutes per IP/username

#### JWT implementation

```json
{
  "iss": "https://api.example.com",
  "sub": "user_abc123",
  "aud": ["web", "mobile"],
  "exp": 900,
  "iat": 1700000000,
  "jti": "unique_id",
  "sid": "session_id"
}
```

- Access token: 15 min expiry
- Refresh token: 7 day expiry, rotate on every use (token rotation)
- Store in httpOnly, Secure, SameSite=Strict cookies
- NEVER store in localStorage (XSS vulnerability)
- Implement refresh token reuse detection (revoke all tokens if stolen)
- Add `typ: "at+jwt"` or `typ: "rt+jwt"` header for explicit token type

#### OAuth 2.0 + OIDC

See [references/oauth2-flow.md](references/oauth2-flow.md) for complete flow.

**Authorization Code + PKCE** (mandatory for public clients):
```
1. Client generates code_verifier (random 43-128 octets)
2. Client computes code_challenge = base64url(SHA256(code_verifier))
3. Browser redirects to /authorize?response_type=code&code_challenge=...
4. Server issues authorization code
5. Client exchanges code + code_verifier for tokens
6. Server verifies SHA256(code_verifier) === code_challenge
```

**Scopes**: Always use least-privilege scopes. Document each scope's access level.

#### WebAuthn / Passkeys

See [references/webauthn.md](references/webauthn.md) for ceremony details.

**Registration ceremony:**
```
1. Server generates challenge (crypto.randomBytes(32))
2. Server sends challenge + user info + relying party info
3. Browser creates credential via navigator.credentials.create()
4. Client sends credential ID, public key, attestation
5. Server verifies attestation, stores public key
```

**Authentication ceremony:**
```
1. Server generates challenge
2. Server sends challenge + allowCredentials (list of registered credential IDs)
3. Browser gets assertion via navigator.credentials.get()
4. Client sends credential ID, signature, authenticator data
5. Server verifies signature against stored public key
```

### Step 3: Implement authorization

#### Role-Based Access Control (RBAC)

```
User → Role(s) → Permission(s)
```

Define roles clearly:
```json
{
  "admin": ["users:*", "orders:*", "settings:*"],
  "manager": ["orders:read", "orders:write", "users:read"],
  "support": ["orders:read", "tickets:*"],
  "user": ["orders:read", "orders:write:own"]
}
```

#### Attribute-Based Access Control (ABAC)

For fine-grained access beyond RBAC:
```
Allow if user.department === resource.department AND user.clearance >= resource.classification
```

### Step 4: Secure the implementation

#### Session management

- Generate session ID via `crypto.randomUUID()` — never sequential or predictable
- Store sessions server-side (Redis with TTL, or database)
- Rotate session ID on privilege escalation (e.g., login)
- Terminate all sessions on password change
- Idle timeout: 30 min for sensitive apps, 2h for standard
- Absolute timeout: 24 hours
- Implement "remember me" with separate, longer-lived token

#### CSRF Protection

| Layer | Implementation |
|-------|---------------|
| Cookie | SameSite=Strict on session cookie |
| Token | CSRF token in state-changing forms |
| Double-submit | Send CSRF token in cookie + header, compare server-side |
| Header | Require custom header (X-Requested-By) for API calls |

#### API Security

| Protection | Implementation |
|------------|---------------|
| CORS | Whitelist specific origins. Never `*` with credentials |
| Rate limit | By user ID + IP. Stricter on auth endpoints |
| Request size | 1MB default, configurable per endpoint |
| Body parsing | Limit nested depth, field count |
| SQL injection | Parameterized queries only. Never string interpolation |
| Secrets in errors | Never expose stack traces, token values, or internal state |
| Password reset | Time-limited token, sent to verified email only |

### Step 5: Add breach response

- Log all auth events: login, logout, failure, password change, token refresh, permission change
- Alert on anomalous patterns: multiple geo-locations < 30min apart, rapid failed attempts, credential stuffing patterns
- Support account recovery with out-of-band verification (email + SMS)
- Notify users on: new device login, password change, email change, MFA change

## MFA Implementation

| Factor Type | Examples | Security |
|-------------|----------|----------|
| TOTP (Time-based OTP) | Authenticator apps (Google, Authy) | High |
| SMS OTP | Phone-based codes | Medium (SIM swap risk) |
| Backup codes | One-time use, generated at setup | High (as backup) |
| Hardware key | YubiKey, SoloKey (FIDO2/WebAuthn) | Very High |
| Passkeys | Platform authenticator (Face ID, Touch ID) | Very High |

### MFA enrollment flow

```
1. Verify password
2. Generate TOTP secret (32 bytes via crypto.randomBytes)
3. Display QR code (otpauth:// protocol)
4. Ask user to scan and enter code
5. Verify code against secret
6. Generate backup codes (10 codes, BCrypt-hashed, stored)
7. Mark MFA as enabled
```

## Production Checklist

- [ ] Password hashing with Argon2id or BCrypt cost >= 12
- [ ] Rate limiting on login (5/15min), password reset (3/60min), MFA (3/15min)
- [ ] Refresh token rotation with reuse detection
- [ ] httpOnly + Secure + SameSite cookies for session/JWT
- [ ] CORS whitelist, never `*` with credentials
- [ ] SQL injection prevention (parameterized queries everywhere)
- [ ] Session fixation prevention (rotate on login)
- [ ] MFA available for all users
- [ ] Account lockout after 5 failed attempts
- [ ] Password breach check at registration and on change
- [ ] Logging of all auth events
- [ ] Rate limiting per endpoint, not globally

## Anti-Patterns

| Anti-pattern | Fix |
|-------------|-----|
| JWT in localStorage | httpOnly cookies with CSRF protection |
| Refresh token without rotation | Rotate on every use. Reuse detection revokes all. |
| Password composition rules | Long passwords (>12 chars) + breach check. No complexity rules. |
| No rate limiting on login | 5 attempts per 15 min per username + IP |
| MFA as optional (unprompted) | Encourage or require MFA for sensitive actions |
| Session doesn't expire | Idle + absolute timeout. Rotate on privilege change. |
| No audit logging | Log all auth events to secure, append-only store |
| Hardcoded JWT secret | Environment variable, rotated periodically |

## Error Handling

| Scenario | Cause | Fix |
|----------|-------|-----|
| Token validation fails | Wrong algorithm or expired key | Verify JWT alg matches expected, check key rotation schedule |
| OAuth callback fails | Mismatched redirect URI or state | Check exact URI match (including trailing slash), validate state parameter |
| Rate limit hit | Too many login attempts | Apply exponential backoff, increase throttling per IP |
| Session fixation | Session ID not rotated on login | Always regenerate session ID after authentication |
| CORS error on auth endpoint | Wrong origin allowed | Restrict to specific origins, never use wildcard in production |
| Password reset token expired | Token TTL too short | Set reasonable expiry (15-30 min), send new link on expiry |

## Sources

- IETF RFC 7519 (JWT), RFC 6749 (OAuth 2.0), RFC 7636 (PKCE)
- IETF RFC 9120 — OAuth 2.0 for Browser-Based Apps
- WebAuthn Level 2 (W3C Recommendation)
- Auth0 Security Architecture
- FIDO2 Specification
