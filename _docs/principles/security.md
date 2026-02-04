# Security Principles

Project-agnostic principles for secure software development.

---

## Core Principles

| Principle | Description |
|-----------|-------------|
| **Defense in Depth** | Multiple layers of security controls |
| **Least Privilege** | Grant minimum necessary permissions |
| **Fail Secure** | Default to secure state on errors |
| **Security by Design** | Consider security from initial design |

---

## Input Validation

### Rules
- Validate all input from untrusted sources
- Use allowlists rather than blocklists
- Validate on the server, even if validated on client
- Sanitize and encode output to prevent injection

### Implementation Pattern
```typescript
// Allowlist validation
const ALLOWED_ROLES = ['user', 'admin', 'moderator'] as const;

function validateRole(role: string): role is typeof ALLOWED_ROLES[number] {
  return ALLOWED_ROLES.includes(role as any);
}

// Schema validation (using Zod example)
const UserInput = z.object({
  email: z.string().email(),
  age: z.number().int().min(0).max(150),
  role: z.enum(ALLOWED_ROLES)
});
```

---

## OWASP Top 10 Checklist

### 1. Injection
- [ ] Use parameterized queries for database access
- [ ] Use ORM/query builders that escape inputs
- [ ] Validate and sanitize all user input
- [ ] Avoid dynamic command execution with user input

### 2. Broken Authentication
- [ ] Use established authentication frameworks
- [ ] Implement account lockout after failed attempts
- [ ] Use secure session management
- [ ] Implement proper logout (invalidate sessions)

### 3. Sensitive Data Exposure
- [ ] Encrypt sensitive data at rest (AES-256)
- [ ] Use TLS 1.3+ for data in transit
- [ ] Never log sensitive data
- [ ] Mask sensitive data in UI and responses

### 4. XML External Entities (XXE)
- [ ] Disable external entity processing in XML parsers
- [ ] Use JSON instead of XML where possible
- [ ] Validate and sanitize XML input

### 5. Broken Access Control
- [ ] Enforce authorization on every request
- [ ] Deny by default
- [ ] Validate user owns requested resources
- [ ] Log access control failures

### 6. Security Misconfiguration
- [ ] Remove default credentials
- [ ] Disable unnecessary features and services
- [ ] Keep dependencies updated
- [ ] Use security headers (CSP, HSTS, etc.)

### 7. Cross-Site Scripting (XSS)
- [ ] Encode output based on context (HTML, JS, URL, CSS)
- [ ] Use Content Security Policy headers
- [ ] Use frameworks with auto-escaping
- [ ] Validate and sanitize HTML input

### 8. Insecure Deserialization
- [ ] Validate serialized data before deserializing
- [ ] Use simple data formats (JSON) over complex ones
- [ ] Implement integrity checks (signatures)
- [ ] Isolate deserialization code

### 9. Using Components with Known Vulnerabilities
- [ ] Maintain inventory of dependencies
- [ ] Monitor for security advisories
- [ ] Update dependencies regularly
- [ ] Remove unused dependencies

### 10. Insufficient Logging and Monitoring
- [ ] Log security-relevant events
- [ ] Include context (who, what, when, where)
- [ ] Protect logs from tampering
- [ ] Set up alerts for suspicious activity

---

## Authentication Best Practices

### Password Storage
```typescript
// Never store plain text passwords
// Use bcrypt with cost factor 12+
import bcrypt from 'bcrypt';

const COST_FACTOR = 12;

async function hashPassword(password: string): Promise<string> {
  return bcrypt.hash(password, COST_FACTOR);
}

async function verifyPassword(password: string, hash: string): Promise<boolean> {
  return bcrypt.compare(password, hash);
}
```

### Session Management
- Generate cryptographically random session IDs
- Set appropriate session timeouts
- Regenerate session ID after authentication
- Use secure, httpOnly, sameSite cookies

### Token Best Practices
- Use short-lived access tokens (15-60 minutes)
- Use longer-lived refresh tokens with rotation
- Store tokens securely (httpOnly cookies preferred)
- Implement token revocation

---

## Data Protection

### Encryption Standards
| Use Case | Algorithm | Key Size |
|----------|-----------|----------|
| Symmetric encryption | AES-GCM | 256-bit |
| Asymmetric encryption | RSA | 2048-bit minimum |
| Hashing (passwords) | bcrypt/Argon2 | N/A |
| Hashing (integrity) | SHA-256 | N/A |

### Secrets Management
- Never commit secrets to version control
- Use environment variables or secret vaults
- Rotate secrets regularly
- Use different secrets per environment

---

## Error Handling

### Safe Error Messages
```typescript
// Avoid - exposes internal details
throw new Error(`User ${userId} not found in database ${dbName}`);

// Better - safe for external exposure
throw new NotFoundError('User not found');

// Log full details server-side
logger.error('User lookup failed', { userId, dbName, error });
```

### Principle
- Log detailed errors server-side
- Return generic errors to clients
- Never expose stack traces in production
- Include correlation IDs for debugging

---

## Security Review Checklist

When reviewing code for security:

- [ ] All user input is validated
- [ ] Output is encoded appropriately
- [ ] SQL/NoSQL queries use parameterization
- [ ] Authentication checks are present
- [ ] Authorization is enforced
- [ ] Sensitive data is encrypted
- [ ] Secrets are not hardcoded
- [ ] Error messages don't leak information
- [ ] Security-relevant events are logged
- [ ] Dependencies are up to date
