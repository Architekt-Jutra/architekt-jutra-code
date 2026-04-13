# Reality Check: Spring Security JWT Authentication

**Date**: 2026-04-04
**Status**: WARNING -- Issues Found
**Deployment Decision**: CONDITIONAL GO -- one critical bug must be fixed before production use

---

## Test Results (Independently Verified)

**Backend**: 104 tests passed, 0 failed, 0 skipped -- BUILD SUCCESS
**Frontend**: 34 tests passed, 1 failed (pre-existing `ProductListPage with plugin filters > renders plugin filter iframes in filter bar` -- NOT related to this feature)

Test results match the work-log claims. All security-specific tests pass.

---

## Reality vs Claims

### What Actually Works

1. **Login endpoint (POST /api/auth/login)** -- WORKS. Tested with valid credentials (admin/admin123), returns JWT with correct claims. Invalid credentials return 401 with proper ErrorResponse JSON.

2. **JWT generation and validation** -- WORKS. Tokens contain `sub` (username), `permissions` (array), `iat`, `exp` claims. Expired tokens are rejected. Malformed tokens are rejected. Tokens signed with wrong keys are rejected.

3. **Endpoint protection with permission tiers** -- WORKS.
   - Unauthenticated requests to protected endpoints return 401.
   - Viewer (READ) can GET /api/products but cannot POST (403).
   - Editor (READ+EDIT) can CRUD products but cannot manage plugins (403).
   - Admin (READ+EDIT+PLUGIN_MANAGEMENT) can do everything.
   - Health endpoint (/api/health) remains publicly accessible.

4. **Database layer** -- WORKS. User entity with @ElementCollection permissions, Liquibase migration 008 seeds 3 users with correct BCrypt hashes, UserRepository.findByUsername works.

5. **Frontend AuthContext** -- WORKS. JWT decoded client-side for permissions, stored in localStorage, login/logout functions provided via context.

6. **API client JWT injection** -- WORKS. All API calls include Authorization: Bearer header when token exists. 401 responses trigger redirect to /login.

7. **UI permission gating** -- WORKS. ProductListPage and CategoryListPage hide "New" buttons for READ-only users. Sidebar hides "Plugins" nav for non-PLUGIN_MANAGEMENT users. PluginListPage hides "Register Plugin" for non-admins.

8. **Plugin SDK JWT propagation** -- WORKS. PluginMessageHandler.handlePluginFetch injects Authorization header from localStorage. Server SDK createServerSDK accepts optional token parameter and includes it in requests.

9. **Existing test suite** -- NO REGRESSIONS. All 104 backend tests pass with security annotations (@WithMockUser) applied to 10+ test files.

10. **Server SDK bug fix** -- VERIFIED. Data endpoint URLs corrected from `/data/{productId}` to `/products/{productId}/data`.

### What Does NOT Work

#### CRITICAL: SPA Route `/login` Returns 401 for Unauthenticated Users

**Claim**: "Login page at /login route in React SPA with redirect to /products on success"
**Reality**: Direct browser navigation to `/login` returns a 401 JSON response instead of serving the SPA.

**Evidence**:
- SecurityConfiguration line 70: `requestMatchers("/", "/index.html", "/*.js", "/*.css", "/favicon.ico").permitAll()` -- `/login` is NOT in this list.
- SecurityConfiguration line 98: `anyRequest().authenticated()` -- catches `/login` as unauthenticated.
- SpaForwardController matches `/{path:[^\\.]*}` for `/login` and forwards to `index.html`, but Spring Security evaluates BEFORE the controller runs, so the forward never happens.

**Impact**: Three user flows are broken:
1. **Logout**: `AuthContext.tsx` line 74 does `window.location.href = "/login"` -- full page navigation hits server, gets 401.
2. **401 auto-redirect**: `client.ts` line 34 does `window.location.href = "/login"` -- same problem.
3. **Direct URL access**: Bookmarking or refreshing `/login` gets 401.

**Workaround in current state**: The initial load at `/` works (permitted), React Router handles client-side navigation to `/login`. So the flow works IF the user's first page load is `/` and they haven't refreshed. But logout and 401 handling are broken because they use full page navigation.

**Fix**: Add SPA routes to SecurityConfiguration's permitAll section. The simplest fix:
```java
.requestMatchers("/{path:[^\\.]*}").permitAll()
```
Or more targeted: add `/login` explicitly. But the broader fix is better because all SPA routes need to serve index.html without auth.

---

## Gap Analysis

### Critical Gaps

| # | Gap | Severity | Evidence |
|---|-----|----------|----------|
| 1 | `/login` and other SPA routes return 401 for unauthenticated users (full page navigation broken) | Critical | SecurityConfiguration line 70 + 98: `/login` not in permitAll, falls to authenticated() |
| 2 | Logout flow broken -- `window.location.href = "/login"` gets 401 from server | Critical | AuthContext.tsx line 74 + SecurityConfiguration as above |

### Medium Gaps

| # | Gap | Severity | Evidence |
|---|-----|----------|----------|
| 3 | No CORS configuration for plugin server-SDK origins | Medium | SecurityConfiguration has zero CORS configuration. Spec said "CORS: allow origins for plugin dev servers (configurable)". Server SDK direct HTTP calls from plugin backends to host API on different port/origin will be blocked by browser CORS. |
| 4 | ProductDetailPage has no edit/delete permission gating | Low | ProductDetailPage.tsx imports neither useAuth nor any permission check. However, this page has no edit/delete buttons -- it's read-only. Edit is at `/products/:id/edit` route, and backend enforces permissions. Not a real functional gap. |

### No Gaps Found (Claims Verified)

- JWT token structure and claims: CORRECT
- Permission enforcement at all 4 tiers (PERMIT_ALL, READ, EDIT, PLUGIN_MANAGEMENT): CORRECT
- Seed users with correct passwords and permissions: CORRECT
- Frontend auth flow (login form, context, guard): CORRECT
- API client JWT injection: CORRECT
- Plugin SDK propagation (both browser and server): CORRECT
- Test regression prevention: CORRECT (104 backend, 34 frontend pass)

---

## Pragmatic Action Plan

### Must Fix Before Production

| # | Action | Success Criteria | Priority | Effort |
|---|--------|-----------------|----------|--------|
| 1 | Add SPA catch-all route to SecurityConfiguration permitAll | GET `/login` returns 200 with index.html for unauthenticated users. Logout flow (`window.location.href = "/login"`) works. Page refresh on `/login` works. | Critical | 15 min |
| 2 | Add integration test for unauthenticated access to `/login` | Test verifies GET /login returns 200 (forward to index.html), not 401 | Critical | 10 min |

### Should Fix (Medium Priority)

| # | Action | Success Criteria | Priority | Effort |
|---|--------|-----------------|----------|--------|
| 3 | Add CORS configuration for plugin dev server origins | Server SDK calls from plugin backends (different origin) include correct CORS headers. Configurable via application.properties. | Medium | 30 min |

---

## Functional Completeness Assessment

**Core Requirements Met**: 14/16 (87%)

| Requirement | Status | Notes |
|-------------|--------|-------|
| POST /api/auth/login returns JWT | PASS | |
| JWT contains sub, permissions, iat, exp | PASS | |
| Independent permissions model (READ, EDIT, PLUGIN_MANAGEMENT) | PASS | |
| Endpoint authorization mapping (4 tiers) | PASS | |
| Three seed users via migration | PASS | |
| Login page at /login route | FAIL | Works via client-side routing only; direct server access returns 401 |
| AuthContext with token/permissions/login/logout | PASS | |
| Token in localStorage, Authorization header injected | PASS | |
| Redirect to /login on 401 | FAIL | window.location.href = "/login" gets 401 from server |
| UI elements hidden by permission | PASS | |
| Plugin browser SDK: hostApp.fetch carries JWT | PASS | |
| Plugin browser SDK: handlePluginFetch injects JWT | PASS | |
| Plugin server SDK: accepts token parameter | PASS | |
| 401 for missing/invalid/expired JWT | PASS | |
| 403 for insufficient permissions | PASS | |
| All existing tests pass with security context | PASS | |

---

## Deployment Decision

**CONDITIONAL GO** -- The implementation is architecturally sound and the core security model works correctly. The endpoint protection, JWT handling, permission enforcement, and frontend auth flow are all properly implemented. The one critical bug (SPA routes returning 401) is a straightforward fix (add SPA route pattern to permitAll) that takes 15-30 minutes including a test.

**Conditions**:
1. Fix the SPA route permitAll issue (Critical -- blocks logout and 401 redirect flows)
2. Add test coverage for the fix

**What works well**:
- Clean separation of concerns (SecurityConfiguration, JwtTokenProvider, JwtAuthenticationFilter, AuthController)
- Proper use of Spring Security patterns (OncePerRequestFilter, AuthenticationEntryPoint, AccessDeniedHandler)
- Solid test coverage with 14 auth-specific integration tests covering happy paths, error paths, permission boundaries, malformed tokens, and wrong signing keys
- Frontend auth architecture follows existing project patterns (AuthContext mirrors PluginContext)
- No regressions in existing 104 backend tests
