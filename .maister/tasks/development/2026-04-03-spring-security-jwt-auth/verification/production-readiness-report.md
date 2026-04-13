# Production Readiness Report

**Date**: 2026-04-03
**Path**: /Users/kuba/Projects/dna_ai/code (Spring Security JWT Authentication feature)
**Target**: production
**Status**: With Concerns

## Executive Summary
- **Recommendation**: GO WITH MITIGATIONS
- **Overall Readiness**: 62%
- **Deployment Risk**: Medium
- **Blockers**: 3  Concerns: 7  Recommendations: 4

The JWT authentication implementation is functionally complete and well-structured. The core security logic (JWT generation/validation, permission-based authorization, BCrypt password hashing, stateless sessions) follows sound patterns. However, there are three blockers that must be addressed before production deployment: the JWT secret is hardcoded in `application.properties` with no environment-based override mechanism, there is no CORS configuration despite plugin iframes running on separate origins, and there is no audit logging of authentication events (login success/failure). The remaining concerns are typical for a pre-alpha project moving toward production.

## Category Breakdown
| Category | Score | Status |
|----------|-------|--------|
| Configuration | 40% | Needs Work |
| Monitoring | 35% | Needs Work |
| Resilience | 70% | Acceptable |
| Performance | 75% | Acceptable |
| Security | 65% | Needs Work |
| Deployment | 85% | Good |

---

## Blockers (Must Fix)

### B1. JWT Secret Hardcoded in application.properties
- **Location**: `src/main/resources/application.properties` (line 4)
- **Issue**: The JWT signing secret `i/WZnrbvFqiPfShuZjGmc5kC7IXxRZfpueJEdgCzGFc=` is committed directly in the properties file. There is no `application-prod.properties` or environment variable override (`${JWT_SECRET}`). This means the same secret is used in dev and production, and anyone with source access can forge valid JWTs.
- **How to fix**: Change to `app.jwt.secret=${JWT_SECRET}` in `application.properties` (or add `application-prod.properties` with the override). Document the required environment variable. Keep the current value only in `application-local.properties` or as a default for dev.
- **Fixable**: true

### B2. No CORS Configuration
- **Location**: `src/main/java/pl/devstyle/aj/core/security/SecurityConfiguration.java`
- **Issue**: The spec mentions "Configure CORS in SecurityFilterChain to allow plugin iframe origins" but no CORS configuration exists anywhere in the security chain. Plugin iframes running on separate origins (e.g., `localhost:3001`) making server-sdk direct HTTP calls will be blocked by browser CORS policy in production. The `handlePluginFetch` path works same-origin but `hostApp.fetch()` from server-sdk needs CORS for direct calls.
- **How to fix**: Add `.cors(cors -> cors.configurationSource(...))` to the SecurityFilterChain with allowed origins configured via properties (not wildcard). At minimum, allow the known plugin origins.
- **Fixable**: true

### B3. No Authentication Event Logging
- **Location**: `src/main/java/pl/devstyle/aj/api/AuthController.java`, `src/main/java/pl/devstyle/aj/core/security/JwtAuthenticationFilter.java`
- **Issue**: There is zero logging of authentication events. No log on successful login, failed login, invalid token, or expired token. In production, this makes it impossible to detect brute-force attempts, credential stuffing, or unauthorized access patterns. The spec marks "Audit logging of authentication events" as out of scope, but basic structured logging (not a full audit trail) is a production baseline requirement.
- **How to fix**: Add `log.info("Login successful for user: {}", username)` on success, `log.warn("Login failed for user: {}", username)` on failure in `AuthController`. Add `log.warn("Invalid JWT token presented")` in `JwtAuthenticationFilter` when validation fails.
- **Fixable**: true

---

## Concerns (Should Fix)

### C1. Seed User Passwords Are Weak and Well-Known
- **Location**: `src/main/resources/db/changelog/2026/008-create-users-table.yaml` (lines 91-144)
- **Issue**: The three seed users have predictable passwords (viewer123, editor123, admin123) with BCrypt hashes committed in the migration. While acceptable for development, these must be changed before any production deployment. There is no mechanism to force password changes on first login.
- **Recommendation**: Add a production migration or startup script that rotates seed passwords, or document that seed users must be re-created with strong passwords before production.

### C2. No Security Headers Configured
- **Location**: `src/main/java/pl/devstyle/aj/core/security/SecurityConfiguration.java`
- **Issue**: Spring Security's default headers are likely active (X-Content-Type-Options, X-Frame-Options, etc.) since they were not explicitly disabled, but there is no explicit configuration for Content-Security-Policy, Strict-Transport-Security (HSTS), or Referrer-Policy. The X-Frame-Options default (`DENY`) may also conflict with the plugin iframe architecture.
- **Recommendation**: Explicitly configure headers in SecurityFilterChain: set X-Frame-Options to SAMEORIGIN or configure frame-ancestors in CSP to allow plugin origins. Add HSTS for production. Verify default headers are not conflicting with iframe usage.

### C3. No Profile-Based Configuration
- **Location**: `src/main/resources/`
- **Issue**: There is only a single `application.properties` file. No `application-prod.properties`, `application-staging.properties`, or Spring profile separation exists. All configuration (including JWT secret and expiration) is in one file with no environment differentiation.
- **Recommendation**: Create at minimum an `application-prod.properties` that externalizes sensitive config via environment variables.

### C4. Token Stored in localStorage (XSS Risk)
- **Location**: `src/main/frontend/src/auth/AuthContext.tsx`, `src/main/frontend/src/api/client.ts`
- **Issue**: The JWT is stored in `localStorage` which is accessible to any JavaScript running on the page. If an XSS vulnerability exists anywhere in the application (including in plugin iframes), the token can be stolen. This is a known tradeoff documented in the spec.
- **Recommendation**: Consider HttpOnly cookies for token storage in a future iteration. At minimum, ensure CSP headers prevent inline script execution and limit plugin iframe access.

### C5. No Request Timeout on JWT Validation
- **Location**: `src/main/java/pl/devstyle/aj/core/security/JwtAuthenticationFilter.java`
- **Issue**: The filter parses the JWT on every request (up to 3 times: validate, getUsername, getPermissions). While JWT parsing is CPU-only (no network), a maliciously crafted large token could consume CPU. There is no token size limit enforcement.
- **Recommendation**: Add a maximum token length check (e.g., reject tokens > 4KB) at the start of `extractToken()` before parsing.

### C6. Health Endpoint Does Not Check Dependencies
- **Location**: `src/main/java/pl/devstyle/aj/api/HealthController.java`
- **Issue**: The health endpoint returns a static `{"status": "UP"}` without checking database connectivity, disk space, or other dependencies. This means a health check will pass even when the application cannot serve requests due to database being down.
- **Recommendation**: Add Spring Boot Actuator with health indicators for database, or manually check database connectivity in the health endpoint.

### C7. No Error Tracking Integration
- **Location**: Project-wide
- **Issue**: There is no Sentry, Bugsnag, or equivalent error tracking service configured. The `GlobalExceptionHandler` logs unexpected errors via SLF4J, but there is no alerting or aggregation mechanism for production error visibility.
- **Recommendation**: Add an error tracking integration (Sentry is typical for Spring Boot) to capture and alert on unexpected exceptions.

---

## Recommendations (Nice to Have)

### R1. Add Rate Limiting on Login Endpoint
- **Location**: `POST /api/auth/login`
- **Issue**: The login endpoint has no rate limiting, making it susceptible to brute-force attacks. The spec marks this as out of scope, but it is a standard production hardening measure.
- **Recommendation**: Add a simple rate limiter (e.g., Bucket4j, Spring Cloud Gateway rate limiter, or a servlet filter) limiting login attempts per IP.

### R2. Consider Token Refresh Mechanism
- **Location**: Frontend auth flow
- **Issue**: The 24-hour token expiry with no refresh mechanism means users are forced to re-login daily. The spec marks this as out of scope, which is acceptable for pre-alpha.
- **Recommendation**: Implement a refresh token flow before GA to improve UX.

### R3. Add Structured Logging Format
- **Location**: Project-wide
- **Issue**: Logging appears to use the default Spring Boot console appender. For production, JSON-structured logs are preferred for log aggregation services (ELK, Datadog, CloudWatch).
- **Recommendation**: Add `logback-spring.xml` with JSON encoder for the production profile.

### R4. JWT Token Parsing Redundancy
- **Location**: `src/main/java/pl/devstyle/aj/core/security/JwtAuthenticationFilter.java` (lines 27-29)
- **Issue**: The filter calls `validateToken()`, then `getUsernameFromToken()`, then `getPermissionsFromToken()` -- each of which independently parses and verifies the JWT signature (3 parse operations per request). While functionally correct, this is wasteful.
- **Recommendation**: Add a single `parseToken(String token)` method to `JwtTokenProvider` that returns a parsed claims object, and use that in the filter to extract both username and permissions from one parse.

---

## Next Steps

**Priority 1 (Must fix before any deployment):**
1. Externalize JWT secret via environment variable (B1)
2. Add CORS configuration for plugin origins (B2)
3. Add authentication event logging (B3)

**Priority 2 (Should fix before production):**
4. Rotate or disable seed user passwords for production (C1)
5. Configure security headers explicitly, especially for iframe compatibility (C2)
6. Create production Spring profile with externalized config (C3)
7. Add dependency health checks to health endpoint (C6)

**Priority 3 (Plan for production hardening):**
8. Add rate limiting on login endpoint (R1)
9. Add error tracking integration (C7)
10. Add maximum token length check (C5)
