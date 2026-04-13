# Specification Audit: Spring Security JWT Authentication

**Date**: 2026-04-03
**Specification**: `/implementation/spec.md`
**Supporting artifacts**: `analysis/requirements.md`, `analysis/gap-analysis.md`, `analysis/codebase-analysis.md`
**Compliance Status**: **Mostly Compliant** -- The specification is well-structured and largely implementable, but contains several inconsistencies, ambiguities, and missing details that should be resolved before implementation begins.

---

## Summary

The specification describes adding JWT-based authentication with an independent permissions model (READ, EDIT, PLUGIN_MANAGEMENT) to a Spring Boot 4.0.5 microkernel plugin platform. It covers backend security, frontend login UI, plugin SDK propagation, and test updates across 16 files.

The spec is thorough for a greenfield security implementation. However, independent verification of the codebase revealed **5 issues requiring attention** before implementation, ranging from a credential inconsistency across documents to missing specification of security behavior for edge-case API paths. No critical blockers were found, but the issues collectively create ambiguity that could lead to implementation mistakes on a high-risk cross-cutting feature.

---

## Findings

### Finding 1: Credential inconsistency between requirements and specification

**Spec Reference**: Spec line 24 -- "admin/admin123"; Requirements line 23 -- "Default admin credentials: admin/admin"

**Evidence**:
- `implementation/spec.md` line 24: `admin/admin123 (READ+EDIT+PLUGIN_MANAGEMENT)`
- `analysis/requirements.md` line 23: `Default admin credentials: admin/admin`
- `analysis/requirements.md` line 51: `admin / admin123`

**Category**: Incorrect (internal inconsistency)

**Severity**: Medium -- The requirements document contradicts itself (line 23 says "admin/admin", line 51 says "admin/admin123"). The spec chose "admin123" but the Phase 5 Q&A answer that seeded this requirement says "admin/admin". Since BCrypt hashes are pre-computed in the migration, the wrong password would mean the admin seed user cannot log in.

**Recommendation**: Confirm which password is intended. The spec's consistent use of the `{user}/{user}123` pattern (viewer/viewer123, editor/editor123, admin/admin123) suggests admin123 was the deliberate choice, but the requirements Q&A says otherwise. Resolve and update requirements.md line 23 to match.

---

### Finding 2: Endpoint authorization mapping has URL pattern mismatches with actual controllers

**Spec Reference**: Spec lines 21-23 -- endpoint authorization mapping

**Evidence**:
- Spec says READ covers: `GET /api/plugins/*/products/*/data`
- Spec says EDIT covers: `PUT/DELETE /api/plugins/*/products/*/data`
- Actual controller at `PluginDataController.java` line 16: `@RequestMapping("/api/plugins/{pluginId}/products/{productId}/data")`
- This is correct -- the paths match.
- However, spec says READ covers: `GET /api/plugins/*/objects/*`
- Actual `PluginObjectController.java` lines 29-56 exposes THREE GET endpoints:
  - `GET /api/plugins/{pluginId}/objects` (listByEntity -- cross-type query)
  - `GET /api/plugins/{pluginId}/objects/{objectType}` (list by type)
  - `GET /api/plugins/{pluginId}/objects/{objectType}/{objectId}` (get single)
- The wildcard `GET /api/plugins/*/objects/*` would match the latter two but **NOT** `GET /api/plugins/{pluginId}/objects` (the cross-type listing endpoint with no sub-path).

**Category**: Incomplete

**Severity**: Medium -- When implementing the `SecurityFilterChain` with URL-based authorization, the implementer could miss the cross-type listing endpoint (`GET /api/plugins/{pluginId}/objects` with query params), which would default to either denying access or requiring a different permission than intended.

**Recommendation**: Expand the READ authorization mapping to explicitly include `GET /api/plugins/*/objects` (no trailing wildcard) alongside `GET /api/plugins/*/objects/**`. Better yet, use `GET /api/plugins/**/objects/**` or list each path explicitly to avoid ambiguity.

---

### Finding 3: Missing specification for PluginController.list() returning only enabled plugins

**Spec Reference**: Spec line 21 -- "READ: GET /api/plugins"

**Evidence**:
- `PluginController.java` line 37: `pluginDescriptorService.findAllEnabled()` -- the list endpoint already filters to enabled-only plugins.
- Spec requirement 4 in `requirements.md` line 26: "Plugin listing: GET /api/plugins requires READ (not PLUGIN_MANAGEMENT), since plugins render for all users."
- The spec correctly assigns READ to `GET /api/plugins` and `GET /api/plugins/{id}`.
- However, `GET /api/plugins/{id}` does NOT filter by enabled status -- it returns any plugin.
- This means a READ user can view a disabled plugin by ID but not see it in the list.

**Category**: Ambiguous

**Severity**: Low -- This is existing behavior unrelated to the security spec, but worth noting since the spec doesn't call out whether disabled plugin access should differ by permission level. If `GET /api/plugins/{id}` for disabled plugins should require PLUGIN_MANAGEMENT, the spec should say so.

**Recommendation**: Clarify whether `GET /api/plugins/{id}` for disabled plugins should be restricted to PLUGIN_MANAGEMENT users or remain accessible to READ users. Current spec treats all GET plugin endpoints uniformly as READ.

---

### Finding 4: Spring Boot 4.0.5 security API compatibility not verified

**Spec Reference**: Spec line 83 -- "spring-boot-starter-security and jjwt-api/jjwt-impl/jjwt-jackson (0.12.x)"

**Evidence**:
- `pom.xml` line 8: `<version>4.0.5</version>` confirms Spring Boot 4.0.5
- `pom.xml` line 30: `<java.version>25</java.version>` confirms Java 25
- Spring Boot 4.x is based on Spring Framework 7.x and Spring Security 7.x
- Spring Security 7.x has breaking changes from 6.x:
  - `SecurityFilterChain` bean approach remains valid
  - `authorizeHttpRequests()` syntax may have changed
  - `OncePerRequestFilter` may have been restructured
  - New defaults for CSRF, session management may differ
- The spec mentions "OncePerRequestFilter" and "SecurityFilterChain bean" which were standard in Spring Boot 3.x/Security 6.x, but does not acknowledge potential API differences in 7.x
- jjwt 0.12.x compatibility with Java 25 is also unverified

**Category**: Ambiguous

**Severity**: Medium -- Spring Boot 4.0.5 is very recent. The spec's technical approach describes patterns from Spring Security 6.x without confirming they still apply in 7.x. If the API has changed, the implementation plan could be based on outdated assumptions.

**Recommendation**: Before implementation planning, verify Spring Security 7.x API documentation for: (1) `SecurityFilterChain` bean configuration syntax, (2) `OncePerRequestFilter` availability, (3) `authorizeHttpRequests()` method chain, (4) default CSRF and session policies. Add a note to the spec acknowledging the Spring Boot 4.x version and any confirmed API differences.

---

### Finding 5: GlobalExceptionHandler catch-all will swallow security exceptions

**Spec Reference**: Spec lines 105-107 -- "Security exceptions must be caught BEFORE the generic Exception handler to avoid 500s"

**Evidence**:
- `GlobalExceptionHandler.java` line 90-101: Generic `@ExceptionHandler(Exception.class)` handler returns 500 for all uncaught exceptions.
- The spec correctly identifies this risk and proposes adding `AccessDeniedException` and `AuthenticationException` handlers.
- However, the spec does not address the interaction between Spring Security's built-in exception handling (via `AuthenticationEntryPoint` and `AccessDeniedHandler` configured in the `SecurityFilterChain`) and `@RestControllerAdvice`.
- Spring Security intercepts exceptions in the filter chain BEFORE they reach `@RestControllerAdvice`. If the `SecurityFilterChain` is configured with custom `AuthenticationEntryPoint` and `AccessDeniedHandler`, the `GlobalExceptionHandler` additions may be redundant or, worse, create conflicting behavior depending on whether the exception is thrown in the filter chain vs. within a controller method.

**Category**: Incomplete

**Severity**: Medium -- The spec says to add handlers to GlobalExceptionHandler AND configure AuthenticationEntryPoint/AccessDeniedHandler (line 107). This dual approach needs explicit scoping: which mechanism handles which scenario. Without clarity, the implementer may create duplicate/conflicting error responses.

**Recommendation**: Specify explicitly:
1. `AuthenticationEntryPoint` + `AccessDeniedHandler` in `SecurityFilterChain` handle filter-level security exceptions (missing/invalid JWT, insufficient permissions on URL-pattern-matched endpoints).
2. `GlobalExceptionHandler` additions handle any `AccessDeniedException` thrown explicitly from within controller/service code (if method-level security is ever added).
3. Clarify that both should produce identical `ErrorResponse` JSON format for consistency.

---

### Finding 6: handlePluginFetch JWT injection mechanism unspecified

**Spec Reference**: Spec line 122 -- "PluginMessageHandler (handlePluginFetch): inject Authorization header from the current user's token into the raw fetch call"

**Evidence**:
- `PluginMessageHandler.ts` lines 43-92: `handlePluginFetch()` is a standalone async function that receives only `payload: Record<string, unknown>`. It has no access to React context, component state, or the AuthContext.
- `handlePluginFetch` is called from within the `createMessageHandler` closure (line 187), which receives `registry` and `options` but no auth state.
- The `handleApiMessage` function (line 95) uses the `api` client which will automatically carry JWT after `client.ts` is updated -- this part of the spec is correct.
- But `handlePluginFetch` uses raw `fetch()` (line 75) with `credentials: "omit"`. The spec says to "inject Authorization header" but does not specify HOW the token gets from AuthContext/localStorage into this function.

**Category**: Incomplete

**Severity**: High -- `handlePluginFetch` is the code path for `hostApp.fetch()` from plugin iframes. Without a clear mechanism for token injection, this path will fail with 401 after security is added. The function is not a React component and has no access to React context.

**Recommendation**: Specify the injection mechanism explicitly. Two options:
- (A) `handlePluginFetch` reads the token directly from `localStorage` (simplest, no API changes needed)
- (B) `createMessageHandler` accepts the token as a parameter or callback and passes it through
Option A is simplest and consistent with the spec's decision to store the token in localStorage. The spec should state: "handlePluginFetch reads the JWT directly from localStorage and adds it as an Authorization: Bearer header to the fetch call."

---

### Finding 7: CORS configuration scope and plugin origins unspecified

**Spec Reference**: Spec lines 136-137 -- "Configure CORS in SecurityFilterChain to allow plugin iframe origins for server-sdk direct calls"

**Evidence**:
- No CORS configuration exists in the codebase (confirmed by examining all controllers and configuration files).
- Plugin iframes run on different ports (e.g., localhost:3001 for warehouse plugin vs. localhost:8080 for host).
- The `handleApiMessage` path (postMessage proxy) is same-origin -- CORS is not an issue there.
- The `handlePluginFetch` path is also same-origin (the host's PluginMessageHandler.ts makes the fetch from the host's origin).
- The server-sdk.ts makes direct cross-origin HTTP calls from Node.js -- CORS does not apply to server-side calls.
- Browser-based plugin direct calls to the host API from an iframe COULD be cross-origin, but the SDK architecture routes everything through postMessage.

**Category**: Ambiguous

**Severity**: Low -- The spec mentions CORS but does not specify which origins to allow or whether it is actually needed given the architecture. Based on codebase analysis, the postMessage proxy architecture means browser-side CORS is largely irrelevant. Server-side SDK calls are not subject to browser CORS. The only scenario requiring CORS would be if a plugin iframe makes direct `fetch()` calls to the host API bypassing the SDK, which the architecture discourages.

**Recommendation**: Either (A) remove the CORS requirement as unnecessary given the postMessage architecture, or (B) specify it as a defense-in-depth measure with explicit allowed origins (e.g., `http://localhost:*` for development). Clarify that this is primarily for server-sdk scenarios or future direct-call plugins.

---

### Finding 8: No specification for jOOQ codegen interaction with new migration

**Spec Reference**: Spec line 96 -- "Liquibase migration 008: user_seq, users table, user_permissions table with seed data"

**Evidence**:
- `pom.xml` lines 114-180: The `testcontainers-jooq-codegen-maven-plugin` runs Liquibase migrations during build to generate jOOQ code.
- The plugin at line 126: `<changeLogPath>src/main/resources/db/changelog/db.changelog-master.yaml</changeLogPath>` runs ALL migrations.
- Adding migration 008 with `users` and `user_permissions` tables will cause jOOQ to generate Java classes for these tables.
- The jOOQ excludes pattern (line 138) only excludes `databasechangelog.*`.
- The spec does not mention whether jOOQ-generated User/UserPermission classes should be excluded or leveraged.

**Category**: Missing

**Severity**: Low -- The generated jOOQ classes for users/user_permissions tables won't cause build failures, but they may create confusion if someone finds both JPA entities and jOOQ-generated classes for the same tables. The spec's user domain uses JPA exclusively.

**Recommendation**: Add a note to either (A) exclude `users|user_permissions` from jOOQ codegen in pom.xml, or (B) acknowledge the generated classes exist but are not used by the security layer. Option A is cleaner.

---

### Finding 9: Spec references plugin data URLs inconsistently

**Spec Reference**: Spec line 21-22 -- endpoint authorization mapping

**Evidence**:
- Spec line 21: `GET /api/plugins/*/products/*/data` (READ)
- Spec line 22: `PUT/DELETE /api/plugins/*/products/*/data` (EDIT)
- Actual controller path: `@RequestMapping("/api/plugins/{pluginId}/products/{productId}/data")` -- matches.
- BUT the `PluginMessageHandler.ts` uses DIFFERENT paths:
  - Line 115: `api.get(\`/plugins/${pluginId}/products/${payload.productId}/data\`)` for getData
  - This means the api client path is `/plugins/{pluginId}/products/{productId}/data` (without `/api` prefix -- the `api` client prepends `/api` on line 16 of client.ts).
- The server-sdk.ts line 82: `hostFetchJson<unknown>(\`/api/plugins/${pluginId}/data/${productId}\`)` -- note this uses `/api/plugins/{id}/data/{productId}` NOT `/api/plugins/{id}/products/{productId}/data`.

**Category**: Incorrect (pre-existing bug in server-sdk.ts, not introduced by spec)

**Severity**: High -- The server-sdk.ts uses a DIFFERENT URL pattern (`/api/plugins/{id}/data/{productId}`) than the actual controller (`/api/plugins/{id}/products/{productId}/data`). This means server-sdk getData/setData/removeData calls would currently return 404. This is a pre-existing bug unrelated to the security spec, but the spec should acknowledge it since it lists server-sdk.ts as a file to modify.

**Recommendation**: The spec should note this pre-existing URL mismatch in server-sdk.ts and either (A) fix it as part of the security update since the file is being modified anyway, or (B) explicitly mark it as out of scope with a separate bug ticket. The server-sdk.ts data paths should be `/api/plugins/${pluginId}/products/${productId}/data` to match the controller.

---

### Finding 10: BaseEntity uses @Version on updatedAt -- spec should note User entity implications

**Spec Reference**: Spec line 93 -- "User entity in pl.devstyle.aj.user package extends BaseEntity"

**Evidence**:
- `BaseEntity.java` line 33-35: `@Version @Column(nullable = false) private LocalDateTime updatedAt;`
- The `@Version` annotation provides optimistic locking. This means every UPDATE to a User entity will check the version and increment it.
- For a User entity that is admin-seeded and only read during authentication (never updated), this is fine.
- However, if password changes or permission updates are ever added (currently out of scope), the `@Version` field creates concurrency control semantics that may be unexpected.
- More importantly, the Liquibase seed data migration must provide an `updated_at` value (not null) for the `@Version` column to work. The spec does not specify this.

**Category**: Incomplete

**Severity**: Low -- The migration must include `updated_at` values for seed users. This is a minor implementation detail but easy to miss since the spec focuses on `user_seq`, `users`, `user_permissions` columns without listing the inherited BaseEntity columns (`id`, `created_at`, `updated_at`) that must also be populated in the seed data.

**Recommendation**: Add a note that the seed data INSERT must include `id` (from sequence), `created_at`, and `updated_at` (as CURRENT_TIMESTAMP or a fixed value) since these are NOT NULL columns inherited from BaseEntity.

---

## Extra Features (in spec but not in requirements)

No significant extras were found. The spec stays within the scope defined by requirements.md.

---

## Clarification Questions

1. **Admin password**: Is it "admin" (requirements.md Phase 5, line 23) or "admin123" (spec line 24, requirements.md line 51)? The implementation will bake BCrypt hashes into a migration, so this must be unambiguous.

2. **Disabled plugin access**: Should `GET /api/plugins/{id}` for a disabled plugin require PLUGIN_MANAGEMENT permission, or is READ sufficient? Current spec treats all plugin GET endpoints uniformly.

3. **CORS**: Is CORS configuration actually needed given the postMessage proxy architecture? If yes, what origins should be allowed?

4. **Server-sdk.ts URL bug**: The server-sdk.ts uses `/api/plugins/{id}/data/{productId}` but the actual endpoint is `/api/plugins/{id}/products/{productId}/data`. Should this be fixed as part of this task?

---

## Positive Observations

1. **Comprehensive reusable components table** (spec lines 39-58): The spec thoroughly maps existing code to leverage, which will reduce implementation time and ensure consistency.

2. **Clear out-of-scope section** (spec lines 162-170): Explicit boundaries prevent scope creep -- no user management UI, no refresh tokens, no rate limiting.

3. **Correct plugin SDK analysis**: The spec correctly identifies that `handleApiMessage` will automatically inherit JWT via the `api` client update, while `handlePluginFetch` needs explicit injection. This shows deep understanding of the architecture.

4. **Standards compliance table** (spec lines 149-157): Explicit mapping of each standard to its application in this task.

5. **Test update scope**: The spec correctly identifies all 16 test files and the need for security context additions.

6. **URL-based security over @PreAuthorize**: Good architectural decision to keep security rules centralized in `SecurityFilterChain` rather than scattered across controllers.

---

## Compliance Assessment

| Dimension | Status | Notes |
|-----------|--------|-------|
| Completeness | Good | All major areas covered: backend, frontend, plugins, tests, migrations |
| Clarity | Mostly Good | 3 ambiguities requiring clarification (findings 3, 4, 7) |
| Consistency | Needs Fix | Credential mismatch (finding 1), URL pattern gap (finding 2) |
| Implementability | Good | Clear technical approach with specific file paths and patterns |
| Standards alignment | Good | Explicit standards mapping in spec |
| Risk awareness | Moderate | Spring Boot 4.x API compatibility not addressed (finding 4) |

**Overall**: The specification is well-crafted and demonstrates strong understanding of the codebase. The findings are primarily precision issues (URL patterns, credential values, mechanism details) rather than fundamental design flaws. Resolving findings 1, 6, and 9 before implementation would eliminate the highest-risk ambiguities.
