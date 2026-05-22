---
name: Web Security
description: >
  Apply professional-grade security standards to any web application task.
  Use this skill when writing code that handles authentication, authorization,
  user input, APIs, file uploads, sessions, secrets, payments, or any data
  from external sources. Also use when the user asks to review, audit, or
  assess security of code or a web app. Covers OWASP Top 10 (2025), secure
  coding, threat modeling, and defensive architecture. Activate even when
  security is not explicitly mentioned — treat every web feature as a security
  surface.
triggers:
  - "security"
  - "OWASP"
  - "secure"
  - "XSS"
  - "SQL injection"
  - "CSRF"
  - "authentication security"
  - "authorization security"
  - "security audit"
  - "threat modeling"
  - "secure coding"
  - "security review"
negatives:
  - "network security"
  - "firewall"
  - "WAF"
  - "infrastructure security"
  - "cloud security"
  - "IAM"
license: MIT
compatibility: opencode
metadata:
  version: "1.0.0"

  workflow: general
  audience: developers
---


# Web Security — Professional Standards

## Mindset

Every input is hostile until proven otherwise.
Every privilege is a liability until proven necessary.
The average breach goes undetected for 200+ days — not because attacks are sophisticated,
but because code assumed the caller was trustworthy.

Security is not a feature added at the end. It is a design constraint applied from the first line.

---

## OWASP Top 10 — 2025 Edition

Apply these as a mental checklist on every feature you build or review.

### A01 — Broken Access Control (#1 most exploited)

The most common and most damaging class of web vulnerability.

**Rules:**
- Every endpoint must verify the caller has permission for the *specific resource* — not just that they're logged in
- Deny by default: if there's no explicit `allow`, the answer is `deny`
- Never expose internal IDs directly — use opaque tokens or UUIDs, not sequential integers (IDOR prevention)
- Check authorization server-side on every request — never trust client-side state or hidden form fields
- Validate CORS: `Access-Control-Allow-Origin: *` is only acceptable for truly public, read-only data
- File path inputs must be sanitized — validate against a whitelist and use `path.resolve()` + check prefix

**IDOR pattern to enforce:**
```
// Wrong — trusts caller owns the resource
GET /api/orders/1234

// Right — verify ownership server-side
const order = await getOrder(orderId)
if (order.userId !== req.user.id) return 403
```

### A02 — Cryptographic Failures

**Rules:**
- HTTPS everywhere — no exceptions, including internal APIs
- Never store passwords in plaintext or with reversible encryption — use bcrypt, Argon2, or scrypt
- Never use MD5 or SHA-1 for security purposes — use SHA-256 minimum, SHA-512 preferred
- Secrets (API keys, tokens, passwords) never go in source code — use environment variables or secrets managers
- Sensitive data at rest must be encrypted — user PII, payment data, health records
- Session tokens must be cryptographically random — minimum 128 bits of entropy
- Never log sensitive data: passwords, tokens, credit card numbers, SSNs, health info

**Secret detection before every commit:**
```
# Patterns that must NEVER appear in source code:
# - API keys (sk-*, AIza*, AKIA*, etc.)
# - Private keys (-----BEGIN PRIVATE KEY-----)
# - Connection strings with passwords
# - .env files committed to git
```

### A03 — Injection (SQL, XSS, Command, NoSQL)

**SQL injection — always parameterize:**
```
// Wrong — never do this
db.query(`SELECT * FROM users WHERE id = ${userId}`)

// Right — parameterized queries
db.query('SELECT * FROM users WHERE id = ?', [userId])
// or ORM equivalents: User.findById(userId)
```

**XSS — context-aware output encoding:**
- Never inject user data into HTML without escaping
- Use framework's built-in escaping (React JSX auto-escapes, Angular templates, etc.)
- `innerHTML` with user content → always sanitize with DOMPurify or equivalent
- `eval()`, `new Function()`, `setTimeout(string)` — ban entirely

**Command injection:**
```
// Wrong
exec(`ffmpeg -i ${userFilename} output.mp4`)

// Right — never concatenate user input into shell commands
// Use argument arrays, not string interpolation
execFile('ffmpeg', ['-i', userFilename, 'output.mp4'])
```

### A04 — Insecure Design

Security flaws at the design level that code changes can't fix.

**Threat model every feature:**
Before building: ask "who would want to abuse this, and how?"
- Rate limit endpoints by default, especially auth, password reset, and email verification
- Multi-factor authentication for sensitive operations (payment, account changes, admin)
- Secure password reset: time-limited tokens, single use, invalidated on use
- Principle of least privilege in service architecture — services access only what they need

### A05 — Security Misconfiguration

**Security headers — always set:**
```
Content-Security-Policy: default-src 'self'
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
Strict-Transport-Security: max-age=31536000; includeSubDomains
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: camera=(), microphone=(), geolocation=()
```

**Other rules:**
- Never expose stack traces or internal errors to users — log them server-side, return generic messages
- Disable directory listing on web servers
- Remove debug endpoints, verbose error modes, and developer tools before production
- Default credentials (admin/admin, root/root) must be changed before first deployment

### A06 — Vulnerable and Outdated Components

- Run `npm audit`, `pip check`, `go mod verify` on every dependency update
- Pin dependency versions — floating `^` versions can auto-update to vulnerable releases
- Never use packages with known critical CVEs in production
- Unused dependencies must be removed — every dependency is an attack surface
- Check for typosquatting on new packages (`axios` vs `axois`, `lodash` vs `loddash`)

### A07 — Authentication Failures

**Session management:**
- Invalidate sessions on logout — don't just delete the cookie client-side
- Regenerate session token on privilege escalation (login, role change, 2FA completion)
- Session tokens expire: 15-30 min for sensitive apps, max 24h for standard apps
- HttpOnly + Secure + SameSite=Strict on all session cookies

**Brute force protection:**
- Rate limit login attempts: 5 attempts per 15 minutes per IP/account
- Exponential backoff after repeated failures
- Account lockout with secure unlock flow
- Never reveal whether email exists during login ("Invalid credentials" for both)

**Password rules:**
- Minimum 12 characters, no arbitrary maximum (bcrypt handles length internally)
- Check against known breached password lists (HaveIBeenPwned API)
- No forced periodic rotation — it degrades security (users add "1" at the end)

### A08 — Software and Data Integrity Failures

- Verify integrity of downloaded resources (checksums, signatures)
- Use `integrity` attribute on CDN-loaded scripts (SRI: Subresource Integrity)
- CI/CD pipelines must not have write access to production unless deploying
- Never deserialize untrusted data with permissive deserializers
- Pin GitHub Actions to specific commit SHAs, not branch names (`@v1` can be hijacked)

### A09 — Security Logging and Monitoring

Every security-relevant event must be logged with enough context to reconstruct the attack.

**Always log:**
- Failed login attempts (with IP, timestamp, account targeted)
- Successful logins (with IP, user-agent)
- Access control failures (who tried to access what they can't)
- Input validation failures on security-sensitive fields
- Admin actions (who did what, when)
- Password changes and account lockouts

**Never log:**
- Passwords (even failed attempts)
- Session tokens or API keys
- Credit card numbers, SSNs, health data
- Full request bodies containing sensitive fields

**Log format must include:** timestamp, IP, user ID (if authenticated), action, result, resource ID

### A10 — Server-Side Request Forgery (SSRF)

If your server fetches URLs based on user input, you are vulnerable to SSRF.
SSRF in cloud environments exposes the instance metadata service (AWS: 169.254.169.254).

```
// Wrong — user controls what your server fetches
const response = await fetch(req.body.url)

// Right — validate against allowlist before fetching
const ALLOWED_DOMAINS = ['api.trusted.com', 'cdn.trusted.com']
const url = new URL(req.body.url)
if (!ALLOWED_DOMAINS.includes(url.hostname)) return 400
const response = await fetch(url.toString())
```

---

## Security Review Checklist

Run this mentally on every feature, and explicitly when asked to audit:

### Authentication & Authorization
- [ ] Every endpoint checks authentication
- [ ] Every endpoint checks authorization for the specific resource
- [ ] IDOR: resource ownership verified server-side, not by ID alone
- [ ] Sessions invalidated on logout and privilege change
- [ ] Rate limiting on auth endpoints

### Input & Output
- [ ] All user input validated and sanitized at the boundary
- [ ] SQL queries parameterized (no string concatenation)
- [ ] HTML output context-encoded (no raw innerHTML with user data)
- [ ] File uploads: type validated, size limited, stored outside webroot, served with correct MIME type
- [ ] URL inputs validated against allowlist (SSRF prevention)

### Secrets & Cryptography
- [ ] No secrets in source code or logs
- [ ] Passwords hashed with bcrypt/Argon2 (not MD5/SHA-1)
- [ ] Sensitive data encrypted at rest
- [ ] HTTPS enforced (no HTTP fallback)

### Headers & Configuration
- [ ] Security headers present (CSP, HSTS, X-Frame-Options, etc.)
- [ ] Error messages don't leak internals
- [ ] Debug mode disabled in production
- [ ] Dependencies free of known critical CVEs

### Logging & Monitoring
- [ ] Security events logged with context
- [ ] No sensitive data in logs
- [ ] Errors logged server-side, generic message returned to user

---

## Gotchas — Real Attack Vectors Often Missed

- **`path.join()` is not path traversal protection** — `path.join('/uploads', '../../../etc/passwd')` works. Use `path.resolve()` and verify the result starts with your expected base path.
- **JWTs are not encrypted by default** — the payload is base64-encoded (readable), not encrypted. Never put sensitive data in a JWT payload unless you're using JWE.
- **`SameSite=Lax` doesn't protect against all CSRF** — top-level navigations (GET requests via links) still send the cookie. Use CSRF tokens for state-changing operations.
- **Regex can cause ReDoS** — catastrophic backtracking in regex patterns applied to user input can DOS your server. Test regexes against ReDoS checkers before using in production.
- **Rate limiting by IP only is bypassed by distributed attacks** — also rate limit by user account and by action type.
- **`JSON.parse()` on untrusted input can throw** — always wrap in try/catch. An uncaught JSON parse error crashes Node.js requests.
- **`typeof null === 'object'`** — null checks in JavaScript require explicit `=== null`, not just falsy checks.
- **Redirect URLs must be validated** — `?redirect=https://evil.com` after login is an open redirect. Validate redirects against an allowlist of your own domains.
- **Signed cookies are not encrypted** — frameworks like Express's `cookie-session` sign cookies (prevents tampering) but the content is readable. Don't store sensitive data in signed cookies.

---

## Workflow

1. **Identify security surfaces** — map every boundary where data enters the system: HTTP endpoints, file uploads, webhook handlers, CLI args, form inputs.
2. **Apply OWASP checklist** — run the Security Review Checklist against every feature touchpoint. Prioritize A01 (access control) and A03 (injection) — they account for the majority of breaches.
3. **Validate at every boundary** — parameterize all SQL. Encode all HTML output. Validate file uploads by type, size, and content. Whitelist URL fetches (SSRF prevention).
4. **Harden authentication** — HttpOnly + Secure + SameSite cookies. Rate limit auth endpoints. Invalidate sessions on logout and privilege escalation. Never reveal user existence in login errors.
5. **Configure defense in depth** — security headers (CSP, HSTS, X-Frame-Options), no debug mode in production, secrets in env vars only, encrypted at rest for PII.
6. **Audit dependencies** — run vulnerability scan on every update. Pin versions. Remove unused packages. Check for typosquatting.
7. **Verify logging** — security events logged with context. No sensitive data in logs. Errors logged server-side, generic messages returned to users.

## Error Handling

| Cause | Fix |
|-------|-----|
| Exposed stack traces in production errors | Set generic error handler. Log full error server-side. Return "An unexpected error occurred" to user. |
| Open redirect via `?redirect=evil.com` parameter | Validate redirect URLs against an allowlist of your own domains before redirecting. |
| `path.join()` bypassed for path traversal | Use `path.resolve()` and verify the result starts with the expected base path. |
| `JSON.parse()` crashing on untrusted input | Always wrap in try/catch. Uncaught JSON parse error crashes Node.js requests. |
| Regex catastrophic backtracking (ReDoS) on user input | Test all user-facing regex patterns against ReDoS checkers. Set timeout on regex evaluation. |
| Rate limit bypassed by distributed IPs | Layer limits: by IP, by user account, and by action type. Exponential backoff after repeated failures. |
| `typeof null === 'object'` — null slipping past falsy checks | Use explicit `=== null` for null checks. Never rely on falsy coercion for null safety. |
| Signed cookies read as plaintext | Signed = tamper-proof, NOT encrypted. Never store secrets in signed cookies. Use encrypted sessions. |

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| String interpolation in SQL queries | SQL injection — #1 most exploited vulnerability class | Always parameterize. Use ORM or prepared statements. |
| `innerHTML` with unsanitized user content | XSS — executes arbitrary JavaScript | Sanitize with DOMPurify. Prefer `textContent` or framework auto-escaping. |
| Secrets in source code (API keys, tokens) | Credential exposure in git history | Environment variables or secrets manager. Pre-commit hooks to detect. |
| `Access-Control-Allow-Origin: *` on authenticated endpoints | Cross-origin data theft | Restrict CORS to known origins. Never wildcard with credentials. |
| Auth check only at route layer, not resource layer | IDOR — user A accesses user B's data by changing an ID | Verify ownership server-side for every resource access. |
| `MD5` or `SHA-1` for password hashing | Trivially crackable with modern hardware | bcrypt (cost 12+), Argon2id, or scrypt only. |
| User-provided filenames passed directly to shell commands | Command injection — `; rm -rf /` | Use argument arrays (`execFile`), never string interpolation. |
| No timeout on external API calls | Hangs, resource exhaustion, cascading failures | Set explicit timeout on every external call. Add circuit breaker. |

## Sources

- OWASP Top 10 (2025) — owasp.org/www-project-top-ten
- OWASP Cheat Sheet Series — cheatsheetseries.owasp.org
- NIST SP 800-63 — Digital Identity Guidelines (pages.nist.gov/800-63-3)
- CWE Top 25 Most Dangerous Software Weaknesses — cwe.mitre.org/top25
- Mozilla Web Security Guidelines — infosec.mozilla.org/guidelines/web_security
- Google Web Fundamentals — Security (developers.google.com/web/fundamentals/security)
- Troy Hunt — "Have I Been Pwned" API (haveibeenpwned.com/API)
- The Tangled Web — Michal Zalewski (No Starch Press)
- Web Application Hacker's Handbook — Stuttard & Pinto (Wiley, 2nd Edition)

## Checklist

- [ ] Skill loads without errors in the AI agent
- [ ] YAML frontmatter is valid (description, compatibility, audience)
- [ ] Workflow section provides clear step-by-step instructions
- [ ] Error handling section covers common failure modes
- [ ] All referenced files (references/, scripts/, assets/) exist
- [ ] Skill triggers correctly for intended use cases
- [ ] No broken links or missing resources
