# OAuth 2.0 + OIDC Flow Reference

## Authorization Code + PKCE (RFC 7636)

This is the **only** recommended flow for public clients (SPAs, mobile apps). The
implicit flow (RFC 6749 §1.3.2) is deprecated due to security issues with access
tokens in the URL fragment.

### Flow Diagram

```
Client (Browser/App)          Auth Server              Resource Server
       |                           |                        |
       |--- Authorization Request->|                        |
       |   (response_type=code     |                        |
       |    + code_challenge)      |                        |
       |                           |                        |
       |<- Authorization Code -----|                        |
       |                           |                        |
       |--- Token Request -------->|                        |
       |   (code + code_verifier)  |                        |
       |                           |                        |
       |<- Access + Refresh Token -|                        |
       |                           |                        |
       |--- API Request + AT ---->|                        |
       |                           |                        |
       |<- Response ---------------|                        |
```

### Step-by-step

**Step 1: Generate PKCE challenge**

```typescript
const codeVerifier = crypto.randomBytes(64)
  .toString('base64url')
const codeChallenge = crypto
  .createHash('sha256')
  .update(codeVerifier)
  .digest('base64url')
```

**Step 2: Authorization request**

```
GET /authorize?
  response_type=code
  &client_id=your_client_id
  &redirect_uri=https://client.com/callback
  &scope=openid+profile+email
  &state=random_state_string
  &code_challenge=<base64url_sha256>
  &code_challenge_method=S256
```

**Step 3: Handle callback**

```typescript
// Server validates state matches, then:
const params = new URLSearchParams({
  grant_type: 'authorization_code',
  code: authorizationCode,
  redirect_uri: 'https://client.com/callback',
  code_verifier: storedCodeVerifier, // never sent to browser
  client_id: 'your_client_id',
  client_secret: 'your_client_secret', // confidential client only
})

const response = await fetch('https://auth.example.com/token', {
  method: 'POST',
  body: params,
  headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
})

const { access_token, refresh_token, id_token, expires_in } = await response.json()
```

**Step 4: Validate ID Token (OIDC)**

```typescript
const parts = id_token.split('.')
const payload = JSON.parse(atob(parts[1]))

// Verify:
assert(payload.iss === 'https://auth.example.com')
assert(payload.aud.includes('your_client_id'))
assert(payload.exp > Date.now() / 1000)
assert(payload.nonce === storedNonce)
// Verify signature (JWK from https://auth.example.com/.well-known/jwks.json)
```

## Token Refresh

```typescript
const response = await fetch('https://auth.example.com/token', {
  method: 'POST',
  body: new URLSearchParams({
    grant_type: 'refresh_token',
    refresh_token: storedRefreshToken,
    client_id: 'your_client_id',
    client_secret: 'your_client_secret',
  }),
})

const tokens = await response.json()

// On refresh token reuse detected:
if (response.status === 400 && tokens.error === 'token_reuse') {
  // Revoke ALL sessions for this user — token was stolen
  await revokeAllUserSessions(userId)
  // Force re-login
}
```

## Security Rules

| Rule | Rationale |
|------|-----------|
| PKCE mandatory for all public clients | Prevents authorization code interception |
| Validate `state` parameter | CSRF protection on auth flow |
| Validate `iss` and `aud` in ID Token | Prevents token confusion/federation attacks |
| Nonce in ID Token | Replay attack prevention |
| Rotate refresh tokens | Limits stolen token window |
| Token reuse detection | Identifies token theft |
| Redirect URIs must be exact match | Open redirector prevention |
| Never log tokens or authorization codes | Credential leakage prevention |

## Common Flows by Client Type

| Client Type | Flow | Notes |
|-------------|------|-------|
| SPA (browser) | Auth Code + PKCE | No client_secret (public client) |
| Mobile app | Auth Code + PKCE | Uses ASWebAuthenticationSession / Chrome Custom Tabs |
| Web server | Auth Code + PKCE | Client secret stored server-side |
| M2M / API | Client Credentials | No user context |
| Device (TV, CLI) | Device Authorization | User authorizes on separate device |

## Sources

- RFC 6749 — OAuth 2.0 Authorization Framework
- RFC 7636 — PKCE
- RFC 7519 — JSON Web Token (JWT)
- OpenID Connect Core 1.0
- OAuth 2.0 for Browser-Based Apps (Best Current Practice)
- OAuth 2.0 Security Best Current Practice
