# Code Review Report

**Date**: 2026-04-03
**Path**: Spring Security JWT Authentication implementation
**Scope**: all (quality, security, performance, best practices)
**Status**: Issues Found

## Summary
- **Critical**: 2 issues
- **Warnings**: 5 issues
- **Info**: 3 issues

---

## Critical Issues

### C1. JWT Secret Hardcoded in application.properties

**Location**: `src/main/resources/application.properties:4`
**Category**: Security
**Risk**: The JWT signing secret (`i/WZnrbvFqiPfShuZjGmc5kC7IXxRZfpueJEdgCzGFc=`) is committed to version control in plaintext. Anyone with repository access can forge valid JWT tokens for any user with any permissions.
**Recommendation**: Move the secret to an environment variable or external secrets manager. Use `${APP_JWT_SECRET}` placeholder in application.properties and inject at runtime. For development, use a separate `application-dev.properties` that is gitignored.
**Fixable**: true

### C2. No Rate Limiting on Login Endpoint

**Location**: `src/main/java/pl/devstyle/aj/api/AuthController.java:33`
**Category**: Security
**Risk**: The `/api/auth/login` endpoint has no rate limiting or brute-force protection. An attacker can perform unlimited password-guessing attempts. Combined with seed users having predictable usernames (viewer, editor, admin), this is a significant risk.
**Recommendation**: Add rate limiting via Spring's `@RateLimiter`, a servlet filter, or a reverse proxy rule. Consider account lockout after N failed attempts or exponential backoff.
**Fixable**: true

---

## Warnings

### W1. JWT Token Stored in localStorage (XSS Risk)

**Location**: `src/main/frontend/src/auth/AuthContext.tsx:38,52` and `src/main/frontend/src/api/client.ts:17`
**Category**: Security
**Risk**: JWT tokens stored in localStorage are accessible to any JavaScript running on the page, including XSS payloads. If any XSS vulnerability exists (e.g., via a plugin iframe or injected content), the token can be exfiltrated.
**Recommendation**: Consider using httpOnly cookies for token storage, which are not accessible via JavaScript. If localStorage must be used, ensure a strict Content Security Policy (CSP) is in place. The current architecture with plugin iframes increases the XSS attack surface.
**Fixable**: false (architectural decision)

### W2. CSRF Protection Disabled Without Compensating Controls

**Location**: `src/main/java/pl/devstyle/aj/core/security/SecurityConfiguration.java:37`
**Category**: Security
**Risk**: CSRF is disabled (`.csrf(csrf -> csrf.disable())`). While this is standard for stateless JWT APIs using Bearer tokens in the Authorization header, the frontend stores the token in localStorage and attaches it manually. If the token were ever sent via cookies (e.g., future change), CSRF protection would be needed. No explicit documentation of this design decision exists.
**Recommendation**: Add a code comment documenting why CSRF is disabled (stateless JWT with Authorization header, no cookie-based auth). This prevents accidental regression if the auth strategy changes.
**Fixable**: true

### W3. Token Parsed Three Times During Validation

**Location**: `src/main/java/pl/devstyle/aj/core/security/JwtAuthenticationFilter.java:27-29`
**Category**: Performance
**Risk**: Each authenticated request parses the JWT token three times: once in `validateToken()`, once in `getUsernameFromToken()`, and once in `getPermissionsFromToken()`. JWT parsing includes cryptographic signature verification each time.
**Recommendation**: Refactor `JwtTokenProvider` to return all claims in a single parse operation (e.g., a `TokenClaims` record with username and permissions). The filter calls one method instead of three.
**Fixable**: true

### W4. No Token Revocation / Logout Mechanism on Backend

**Location**: `src/main/java/pl/devstyle/aj/core/security/JwtTokenProvider.java` (entire file)
**Category**: Security
**Risk**: Once issued, a JWT token is valid for 24 hours (86400000ms) with no way to revoke it server-side. If a user's permissions change or their account is compromised, the old token remains valid. The frontend logout only clears localStorage.
**Recommendation**: For a demo/internal app this may be acceptable. For production, consider shorter token expiry (e.g., 15-30 minutes) with a refresh token mechanism, or a server-side token blacklist for revocation.
**Fixable**: false (architectural decision)

### W5. Seed Users with Likely Weak Passwords in Migration

**Location**: `src/main/resources/db/changelog/2026/008-create-users-table.yaml:89-144`
**Category**: Security
**Risk**: The seed data includes three users (viewer, editor, admin) with bcrypt-hashed passwords committed to version control. If these passwords are simple/guessable (e.g., matching the username), they represent a security risk in any non-development environment. The hashes use bcrypt cost factor 10, which is acceptable but on the lower end.
**Recommendation**: Ensure seed users are only loaded in development profiles. Add a `context: dev` to the changeset or use a separate seed file. Document the seed passwords so developers know them, but ensure they cannot run in production.
**Fixable**: true

---

## Informational

### I1. Permissions Derived from Token Claims, Not Re-Validated Against Database

**Location**: `src/main/java/pl/devstyle/aj/core/security/JwtAuthenticationFilter.java:29-35`
**Category**: Best Practices
**Description**: The filter reads permissions directly from the JWT claims without checking the database. This is the standard JWT approach (stateless), but means permission changes only take effect when a new token is issued.
**Suggestion**: This is fine for the current use case. If real-time permission revocation is needed, add a lightweight DB check or use shorter token expiry.

### I2. No Issuer or Audience Claims in JWT

**Location**: `src/main/java/pl/devstyle/aj/core/security/JwtTokenProvider.java:34-41`
**Category**: Best Practices
**Description**: The generated JWT does not include `iss` (issuer) or `aud` (audience) claims. In a single-application setup this is fine, but if multiple services share the same signing key, tokens from one service could be accepted by another.
**Suggestion**: Add `.issuer("aj")` and `.audience().add("aj")` to the token builder for defense-in-depth.

### I3. Frontend Decodes JWT Payload Without Verification

**Location**: `src/main/frontend/src/auth/AuthContext.tsx:14-24`
**Category**: Best Practices
**Description**: The `decodeJwtPayload` function decodes the JWT payload using base64 without signature verification. This is acceptable for UI display purposes (showing username, checking expiry) since the backend validates the token on every API call. The frontend cannot verify HMAC signatures anyway.
**Suggestion**: No action needed. This is the standard pattern for SPAs.

---

## Metrics
- Max function length: ~30 lines (SecurityConfiguration.securityFilterChain)
- Max nesting depth: 3 levels
- Potential vulnerabilities: 2 critical, 3 warning-level
- N+1 query risks: 0
- Files analyzed: 13

---

## Prioritized Recommendations

1. **Externalize the JWT secret** -- Move from application.properties to environment variable or secrets manager. This is the highest-priority security fix.
2. **Add rate limiting to the login endpoint** -- Prevents brute-force attacks against the three known seed usernames.
3. **Scope seed data to dev profile** -- Add Liquibase context or Spring profile guard so seed users with known passwords cannot exist in production.
4. **Consolidate JWT parsing** -- Single parse per request instead of three, reducing cryptographic overhead on every authenticated request.
5. **Add issuer/audience claims** -- Low-effort defense-in-depth for JWT validation.
6. **Document CSRF-disabled rationale** -- Prevent accidental regression with a code comment.
7. **Evaluate token storage strategy** -- If plugin iframe security requirements tighten, consider httpOnly cookies over localStorage.
