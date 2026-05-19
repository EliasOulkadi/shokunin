---
name: auth-architect
description: Implement authentication and authorization with OWASP Top 10 standards, OAuth 2.0 + OIDC, WebAuthn/Passkeys, session management, and RBAC/ABAC. Use when user asks to implement login, signup, authentication, authorization, JWT, OAuth, SSO, passkeys, MFA, or role-based access. Do NOT use for API key management (use api-forge), encryption at rest, or network-level security (firewalls, WAF).
triggers:
  - "authentication"
  - "authorization"
  - "login"
  - "signup"
  - "OAuth"
  - "JWT"
  - "SSO"
  - "passkeys"
  - "WebAuthn"
  - "MFA"
  - "role-based access"
  - "RBAC"
  - "session management"
  - "passwordless"
negatives:
  - "API key management"
  - "encryption at rest"
  - "firewall"
  - "WAF"
  - "network security"
  - "API design"
license: MIT
compatibility: opencode
metadata:
  workflow: backend
  audience: developers
  version: "4.0.0"
  author: shokunin
---


# Auth Architect

Production authentication following OWASP Top 10, NIST SP 800-63B, and patterns from Auth0, AWS Cognito, and the OWASP Cheat Sheet Series.

## Sub-Commands

| Command | Description |
|---------|-------------|
| `implement` | Implement full authentication system (login, signup, sessions, MFA, password reset) |
| `audit` | Audit existing auth against OWASP Top 10 checklist |
| `enforce` | Add missing security measures (rate limiting, CSRF, session rotation) |
| `teach` | Set up auth context file (AUTH.md) with project-specific configuration |

## Workflow

### Step 1: Choose auth method

| Method | Use Case | Security | Complexity |
|--------|----------|:--------:|:----------:|
| Session-based (httpOnly cookies) | Server-rendered web apps | High | Low |
| JWT access + refresh tokens | SPAs, mobile, APIs | High (with proper storage) | Medium |
| OAuth 2.0 + OIDC | Third-party login, SSO | High | High |
| API keys with HMAC | M2M, CLIs, integrations | Medium | Low |
| WebAuthn / Passkeys | Passwordless, high-security | Very High | Medium |
| Magic links / OTP | Low-friction, email-based | Medium | Low |

### Step 2: Implement authentication

#### Password-based auth

```
1. Validate email format + length (< 254 chars)
2. Check against breached passwords (HaveIBeenPwned API k-anonymity)
3. Hash with Argon2id: memory=19456, iterations=2, parallelism=1
   OR BCrypt: cost=12 minimum
4. Generate session UUIDv4 via crypto.randomUUID()
5. Store session server-side (Redis, TTL=24h)
6. Set cookie: httpOnly, Secure, SameSite=Strict
7. Return user object (never return password hash)
```

**Password requirements** (NIST SP 800-63B):
- Minimum 12 characters (no max below 64)
- NO composition rules (uppercase, number, symbol required - these weaken security, NIST §5.1.1.2)
- Allow all printable ASCII + Unicode
- Check against HaveIBeenPwned API (k-anonymity, SHA-1 prefix)
- Rate limit: 5 attempts per 15 min per IP + username

#### JWT implementation

```json
{
  "iss": "https://api.example.com",
  "sub": "user_abc123",
  "aud": ["web", "mobile"],
  "exp": 900,
  "iat": 1700000000,
  "jti": "a1b2c3d4e5f6",
  "sid": "sess_xyz789"
}
```

**Exact values:**
- Access token: 15 min expiry. Algorithm: RS256 (asymmetric) or HS256 (symmetric, single service).
- Refresh token: 7 day expiry. Rotation on every use.
- Refresh token reuse detection: revoke ALL tokens if a used refresh token is presented (theft indicator).

```typescript
// Refresh rotation + reuse detection
async function refreshToken(providedRefreshToken: string) {
  const stored = await db.findRefreshToken(providedRefreshToken)

  if (!stored) {
    // Token not found - possible reuse. Revoke all user tokens.
    await db.revokeAllRefreshTokens(extractUserId(providedRefreshToken))
    throw new AuthError('Token family revoked')
  }

  if (stored.used) {
    // This token was already used - reuse detected. Revoke all.
    await db.revokeAllRefreshTokens(stored.userId)
    throw new AuthError('Token reuse detected')
  }

  // Mark as used, issue new pair
  await db.markRefreshTokenUsed(providedRefreshToken)
  const newToken = await generateRefreshToken(stored.userId)
  const newAccessToken = await generateAccessToken(stored.userId)
  return { accessToken: newAccessToken, refreshToken: newToken }
}
```

**Storage (CRITICAL):**
- httpOnly, Secure, SameSite=Strict cookies
- NEVER localStorage (XSS reads it)
- NEVER sessionStorage (XSS reads it)
- NEVER in-memory only (page refresh kills auth)

#### OAuth 2.0 + OIDC

Authorization Code + PKCE (RFC 7636). Mandatory for public clients (SPA, mobile).

```
1. Client generates code_verifier: crypto.randomBytes(32).toString('base64url')
2. Client computes code_challenge = SHA256(code_verifier).toString('base64url')
3. Redirect to /authorize?response_type=code&code_challenge=<challenge>&code_challenge_method=S256&scope=openid+profile+email
4. Server issues authorization code (5 min TTL, single use)
5. Client exchanges: POST /token { grant_type: 'authorization_code', code, code_verifier }
6. Server verifies: SHA256(code_verifier) === code_challenge
7. Server returns: { access_token, id_token, refresh_token, expires_in: 900 }
```

Scopes: Always least privilege. Document each scope's access level.

#### WebAuthn / Passkeys (FIDO2)

**Registration ceremony:**
```
1. Server: challenge = crypto.randomBytes(32)
2. Server sends: { challenge, rp: { name, id }, user: { id, name, displayName }, pubKeyCredParams, timeout: 60000 }
3. Browser: credential = await navigator.credentials.create({ publicKey })
4. Client sends: { id, rawId, type, response: { clientDataJSON, attestationObject } }
5. Server verifies attestation against challenge, stores credential ID + public key
```

**Authentication ceremony:**
```
1. Server: challenge = crypto.randomBytes(32)
2. Server sends: { challenge, rpId, allowCredentials: [{ id, type: 'public-key' }], timeout: 60000 }
3. Browser: assertion = await navigator.credentials.get({ publicKey })
4. Client sends: { id, rawId, type, response: { clientDataJSON, authenticatorData, signature, userHandle } }
5. Server verifies signature against stored public key using crypto.verify()
```

### Step 3: Authorization

#### RBAC

```
User ? Role(s) ? Permission(s)
```

```json
{
  "admin": ["users:*", "orders:*", "settings:*", "billing:*"],
  "manager": ["orders:read", "orders:write", "users:read", "reports:read"],
  "support": ["orders:read", "tickets:*", "users:read"],
  "user": ["orders:read", "orders:write:own", "profile:write:own"]
}
```

Permission format: `resource:action[:scope]`

#### ABAC (when RBAC isn't enough)

```
Allow if:
  user.department === resource.department
  AND user.clearance >= resource.classification
  AND resource.country IN user.authorizedCountries
```

### Step 4: Session Management (exact specs)

| Parameter | Value |
|-----------|-------|
| Session ID generation | `crypto.randomUUID()` - never sequential |
| Session storage | Redis, TTL = 24h (absolute). DB for analytics. |
| Idle timeout | 30 min (sensitive), 2h (standard) |
| Absolute timeout | 24h |
| Session rotation | On login, privilege change, password change |
| Remember me | Separate token, 30 day TTL, rotated on use |

### CSRF Protection

| Layer | Implementation |
|-------|---------------|
| Cookie | `SameSite=Strict` on session cookie |
| Token | CSRF token in state-changing forms (hidden input + cookie, compare server-side) |
| Header | Custom header (`X-Requested-By: XMLHttpRequest`) for API calls |

### Step 5: MFA Implementation

| Factor | Security | Setup complexity |
|--------|:--------:|:-----------------:|
| TOTP (Authenticator app) | High | Low (QR code) |
| Hardware key (FIDO2/WebAuthn) | Very High | Medium |
| Passkeys (platform) | Very High | Low (biometric) |
| SMS OTP | Medium (SIM swap risk) | Low |
| Backup codes (10 single-use) | High (as backup) | Low |

**TOTP enrollment:**
```typescript
const secret = authenticator.generateSecret()  // 32 bytes
const otpauth = authenticator.keyuri(user.email, 'MyApp', secret)
// Display QR: otpauth
// Verify: authenticator.verify({ token: userInput, secret })
// Issue: 10 backup codes, BCrypt-hashed, shown once
```

### Step 6: Breach Response

- Log ALL auth events: login, logout, failure, password change, token refresh, MFA enrollment, permission change
- Alert on: multiple geo-locations < 30min apart, rapid failures (credential stuffing), abnormal request patterns
- Notify user on: new device login, password change, email change, MFA change
- Support account recovery: out-of-band verification (email + SMS), time-delayed

## Error Handling

Every auth failure must return a generic message. Never reveal which part of auth failed. Log the specific reason internally.

| Scenario | HTTP | Response Message | Log Action |
|----------|------|------------------|------------|
| Invalid email/password | 401 | "Invalid credentials" | Log: `auth_failure` + username + reason (breach check, hash mismatch, unknown user) |
| Account locked | 423 | "Account temporarily locked. Try again in 30 minutes." | Log: `account_locked` + user_id + failed_attempts |
| Token expired | 401 | "Session expired. Please log in again." | Log: `token_expired` + user_id + token_jti |
| Token reuse detected | 401 | "Session expired. Please log in again." | Log: `token_reuse_detected` ? revoke all user tokens |
| CSRF token mismatch | 403 | "Invalid request" | Log: `csrf_mismatch` + user_id + origin |
| Rate limit exceeded | 429 | "Too many attempts. Try again in 15 minutes." | Log: `rate_limited` + identifier + endpoint |
| Permission denied | 403 | "Access denied" | Log: `permission_denied` + user_id + resource + required_permission |
| MFA challenge failed | 401 | "Verification failed" | Log: `mfa_failure` + user_id + factor_type |
| OAuth state mismatch | 400 | "Invalid request" | Log: `oauth_state_mismatch` + redirect_uri |
| WebAuthn challenge failed | 401 | "Verification failed" | Log: `webauthn_failure` + credential_id + reason |

**Rules:**
- Never distinguish between "email not found" and "wrong password" in responses - identical 401 for both
- Never expose `reason` or `code` to the client on auth errors
- Log all auth failures with user identifier, timestamp, IP, and user agent
- Alert on spikes: >20 auth failures per user per minute, >100 per IP per minute
- Return `Retry-After` header for rate-limited responses

## Production Checklist

- [ ] Password hashing: Argon2id (memory=19456, iterations=2, parallelism=1) or BCrypt (cost = 12)
- [ ] Password breach check (HaveIBeenPwned API, k-anonymity)
- [ ] Rate limiting: login (5/15min per IP+username), reset (3/60min), MFA (3/15min)
- [ ] Refresh token: rotation on every use. Reuse detection revokes ALL user tokens.
- [ ] Token storage: httpOnly + Secure + SameSite=Strict cookies
- [ ] No JWT in localStorage, sessionStorage, or URL
- [ ] Session: `crypto.randomUUID()` generation, rotate on login/privilege change
- [ ] CSRF: SameSite cookies + token verification for state-changing operations
- [ ] CORS: whitelist origins, never `*` with credentials
- [ ] SQL injection: parameterized queries everywhere. Never string interpolation.
- [ ] MFA available for all users. Required for admin actions.
- [ ] Account lockout: 5 failed attempts ? temporary lockout (30 min) with notification
- [ ] Logging: every auth event. Append-only. No PII in logs.
- [ ] Passwords: min 12 chars. No composition rules (NIST §5.1.1.2).
- [ ] Recovery: time-limited token (15 min), sent to verified email only. Single use.
- [ ] OAuth PKCE mandatory for public clients
- [ ] WebAuthn: challenge verified server-side. Attestation verified.

## Anti-Patterns

| Anti-pattern | Fix |
|-------------|-----|
| JWT in localStorage | httpOnly cookies with CSRF protection |
| Refresh token static (no rotation) | Rotate on every use. Reuse detection. |
| Password composition rules (uppercase+number+symbol required) | Long passwords (>12 chars) + breach check. No complexity rules. |
| No rate limiting on login | 5 attempts per 15 min per username + IP |
| MFA optional, unprompted | Prompt MFA enrollment. Require for sensitive actions. |
| Session never expires | Idle (2h max) + absolute (24h max) timeout. |
| No audit logging | Log all auth events. Append-only. Indexed by user_id. |
| Hardcoded JWT secret | Environment variable. Rotated. RS256 preferred over HS256. |
| Password reset without token expiry | 15 min expiry, single use, sent to verified email. |
| Sequential or predictable user IDs | UUIDv4 for all resource IDs. Never auto-increment. |
| Session fixation | Rotate session ID on login, logout, privilege change. |

## Error Handling

| Cause | Fix |
|-------|-----|
| JWT expired but refresh token still valid | Implement silent refresh with retry. Rotate tokens on 401. |
| OAuth state parameter mismatch | Reject. Log possible CSRF attack. Redirect to login flow. |
| Rate limit exceeded on auth endpoint | Return 429 with Retry-After header. Exponential backoff on client. |
| Password reset token reused | Invalidate all existing tokens for user. Force re-login. |
| WebAuthn registration timeout | Allow retry. Set 60s timeout. Warn user of inactivity. |
| Session fixation after login | Regenerate session ID. Invalidate old session. |
| Refresh token reuse detected | Invalidate entire token family. Force full re-authentication. Notify user. |
| MFA code brute force | Rate limit to 5 attempts per 5 minutes. Account lockout after 10 failures. |
| OAuth provider returns malformed token | Validate JWT signature and claims before use. Fallback to error state. |
| Argon2id verification slow under load | Use worker threads. Cache verified sessions. Check memory=19456 config. |

## Sources

- OWASP Top 10 (2025)
- OWASP Cheat Sheet Series - Authentication, Session Management, CSRF, Forgot Password
- NIST SP 800-63B - Digital Identity Guidelines (§5.1.1.2 password requirements)
- IETF RFC 7519 (JWT), RFC 6749 (OAuth 2.0), RFC 7636 (PKCE)
- WebAuthn Level 2 (W3C Recommendation)
- Auth0 Security Architecture
- FIDO2 Specification
- HaveIBeenPwned API (k-anonymity model)

## Checklist

- [ ] Skill loads without errors in the AI agent
- [ ] YAML frontmatter is valid (description, compatibility, audience)
- [ ] Workflow section provides clear step-by-step instructions
- [ ] Error handling section covers common failure modes
- [ ] All referenced files (references/, scripts/, assets/) exist
- [ ] Skill triggers correctly for intended use cases
- [ ] No broken links or missing resources
