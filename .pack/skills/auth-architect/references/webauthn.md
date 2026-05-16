# WebAuthn / Passkeys Reference

## Core Concepts

WebAuthn (W3C) + CTAP2 (FIDO2) = Passkeys. Platform authenticators (Face ID,
Touch ID, Windows Hello) and cross-platform authenticators (YubiKey, SoloKey).

## Registration Ceremony

### Server setup

```typescript
// Generate challenge
const challenge = crypto.randomBytes(32)

// Create credential creation options
const options = {
  challenge,
  rp: {
    name: 'Example Corp',
    id: 'example.com', // no port, no protocol, effective domain
  },
  user: {
    id: new TextEncoder().encode(userId),
    name: 'user@example.com',
    displayName: 'User Name',
  },
  pubKeyCredParams: [
    { type: 'public-key', alg: -7 },   // ES256
    { type: 'public-key', alg: -257 },  // RS256
  ],
  authenticatorSelection: {
    authenticatorAttachment: 'platform', // 'platform' for passkeys, 'cross-platform' for security keys
    residentKey: 'required',            // discoverable credential
    userVerification: 'required',
  },
  attestation: 'none',                  // skip attestation for privacy
  excludeCredentials: [],               // prevent registering same device twice
}

// Store challenge in session: await redis.set(`webauthn:register:${userId}`, challenge, { EX: 300 })
return options
```

### Browser

```typescript
const credential = await navigator.credentials.create({
  publicKey: serverOptions,
})

// Send to server
const payload = {
  id: credential.id,
  rawId: new Uint8Array(credential.rawId),
  type: credential.type,
  response: {
    clientDataJSON: new Uint8Array(credential.response.clientDataJSON),
    attestationObject: new Uint8Array(credential.response.attestationObject),
  },
}
```

### Server verification

```typescript
// Verify client data
const clientData = JSON.parse(new TextDecoder().decode(clientDataJSON))
assert(clientData.type === 'webauthn.create')
assert(clientData.challenge === base64url(challenge))
assert(clientData.origin === 'https://example.com')

// Verify attestation (if attestation !== 'none')
// Parse authenticator data
const authData = new Uint8Array(attestationObject.slice(attestationObject.length - 37))
const rpIdHash = authData.slice(0, 32)  // must equal SHA256('example.com')
const flags = authData[32]               // UP + UV + AT + ED
const counter = new DataView(authData.buffer, 33, 4).getUint32(0)

// Extract credential public key (CBOR encoded)
// Store credential.id, credentialPublicKey, counter in database
```

## Authentication Ceremony

### Server setup

```typescript
const challenge = crypto.randomBytes(32)

// Fetch user's credentials from DB
const credentials = await db.credentials.findMany({ where: { userId } })

const options = {
  challenge,
  allowCredentials: credentials.map(c => ({
    id: base64urlToBytes(c.credentialId),
    type: 'public-key',
    transports: ['internal', 'hybrid', 'usb', 'nfc', 'ble'],
  })),
  userVerification: 'required',
}

// Store challenge: await redis.set(`webauthn:auth:${userId}`, challenge, { EX: 300 })
return options
```

### Browser

```typescript
const assertion = await navigator.credentials.get({
  publicKey: serverOptions,
})

const payload = {
  id: assertion.id,
  rawId: new Uint8Array(assertion.rawId),
  type: assertion.type,
  response: {
    clientDataJSON: new Uint8Array(assertion.response.clientDataJSON),
    authenticatorData: new Uint8Array(assertion.response.authenticatorData),
    signature: new Uint8Array(assertion.response.signature),
    userHandle: assertion.response.userHandle
      ? new Uint8Array(assertion.response.userHandle)
      : null,
  },
}
```

### Server verification

```typescript
const clientData = JSON.parse(new TextDecoder().decode(clientDataJSON))
assert(clientData.type === 'webauthn.get')
assert(clientData.challenge === base64url(challenge))
assert(clientData.origin === 'https://example.com')

// Parse authenticator data
const rpIdHash = authData.slice(0, 32)
assert(equal(rpIdHash, sha256('example.com')))
const flags = authData[32]
assert(flags & 0x01) // User Present
assert(flags & 0x04) // User Verified

// Check counter (if > 0, must be > stored counter)
const newCounter = new DataView(authData.buffer, 33, 4).getUint32(0)
assert(newCounter > storedCounter || newCounter === 0)

// Verify signature using stored credentialPublicKey
// crypto.verify(credentialPublicKey, signature, authenticatorData + clientDataHash)
```

## Passkeys (iCloud, Google, 1Password)

Passkeys are discoverable credentials synced across devices by the platform vendor.

### Benefits

- **No passwords to remember**: biometric or PIN
- **Cross-device**: synced via iCloud Keychain, Google Password Manager, 1Password
- **Phishing-resistant**: bound to origin, not domain lookalike
- **Device-bound on most platforms**: prevents remote theft

### Implementation checklist

- [ ] Use `authenticatorSelection.residentKey: 'required'` during registration
- [ ] Set `authenticatorSelection.authenticatorAttachment: 'platform'` for passkeys
- [ ] Support hybrid transport for cross-device auth (QR code flow)
- [ ] Store credentials server-side with user verification counter
- [ ] Provide fallback to password/TOTP for non-WebAuthn browsers

## Conditional UI (autofill)

```typescript
// In registration
const options = {
  ...,
  conditional: true,
}

// In login page, add autocomplete attribute
// <input type="text" name="username" autocomplete="username webauthn" />
```

When the user clicks the username field, browser shows available passkeys.

## Sources

- WebAuthn Level 2 (W3C Recommendation)
- FIDO2 Specification (fidoalliance.org)
- MDN: Web Authentication API
- webauthn.guide
- passkeys.dev
