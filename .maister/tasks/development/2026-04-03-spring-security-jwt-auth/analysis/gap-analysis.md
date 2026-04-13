# Gap Analysis: Spring Security with JWT Authentication and Role-Based Permissions

## Summary
- **Risk Level**: High
- **Estimated Effort**: High
- **Detected Characteristics**: creates_new_entities, modifies_existing_code, involves_data_operations, ui_heavy

## Task Characteristics
- Has reproducible defect: no
- Modifies existing code: yes (5 controllers, 16 test files, GlobalExceptionHandler, frontend API client, plugin SDKs, router)
- Creates new entities: yes (User entity, security infrastructure, auth controller, login UI)
- Involves data operations: yes (User CRUD -- CREATE via migration seed, READ via login/auth)
- UI heavy: yes (login page, auth state management, token storage, conditional UI based on roles)

---

## Gaps Identified

### Missing Features (Must Be Created From Scratch)

**1. Spring Security dependency and configuration**
- No `spring-boot-starter-security` in pom.xml
- No `SecurityFilterChain` bean
- No CORS configuration anywhere in the project
- No security-related application properties

**2. JWT token infrastructure**
- No JWT library dependency (jjwt-api/impl/jackson)
- No token generation, validation, or parsing logic
- No `JwtAuthenticationFilter` (OncePerRequestFilter)
- No JWT configuration properties (secret key, expiration)

**3. User domain model**
- No `User` entity (will extend BaseEntity which uses sequence-based Long ID + audit fields)
- No `UserRepository`
- No `UserDetailsService` implementation
- No Liquibase migration for users table (next available: 008)
- No password encoding/hashing setup

**4. Authentication endpoint**
- No `AuthController` at `/api/auth/login`
- No login request/response DTOs
- No token refresh mechanism

**5. Role-based authorization**
- No role model (READ, EDIT, PLUGIN_MANAGEMENT)
- No endpoint-to-role mapping
- No method-level or URL-based security rules

**6. Security exception handling**
- GlobalExceptionHandler at `/src/main/java/pl/devstyle/aj/core/error/GlobalExceptionHandler.java` handles only business exceptions
- Missing: `AccessDeniedException` (403), `AuthenticationException` (401)
- The catch-all `Exception` handler would currently swallow security exceptions as 500s

**7. Login UI**
- No login page component in frontend
- No auth state management (React context or similar)
- No token storage mechanism (localStorage/sessionStorage)
- No auth-aware routing (redirect to login when unauthenticated)
- No logout functionality
- No Authorization header injection in API client (`src/main/frontend/src/api/client.ts`)

**8. Plugin SDK JWT propagation**
- `plugins/sdk.ts` -- browser SDK has no concept of auth tokens; it communicates via postMessage to the host, which proxies via `PluginMessageHandler.ts` using the `api` client. The host-side proxy will automatically carry the token IF the `api` client is updated.
- `plugins/server-sdk.ts` -- server SDK makes direct HTTP calls to `hostBaseUrl` with no Authorization header. Needs a `token` parameter in `createServerSDK()`.
- `PluginMessageHandler.ts` -- uses `api` client for all proxied calls. If `api` client carries JWT, plugin iframe calls are automatically authenticated. The `handlePluginFetch` function uses raw `fetch` with `credentials: "omit"` -- this path needs JWT injection too.

### Incomplete Features (Partial Implementation Exists)

**9. CORS support**
- No CORS configuration exists. With security enabled, cross-origin plugin iframe requests will fail.
- Plugin iframes run on different origins (e.g., `localhost:3001` vs `localhost:8080`)
- The `PluginMessageHandler.ts` already validates origins per-plugin, but the browser SDK's `hostApp.fetch` uses `handlePluginFetch` which calls the host API from the host origin (same-origin), so CORS mainly matters for server-sdk.ts direct calls.

### Behavioral Changes Needed

**10. All existing API endpoints become secured**
- Currently all 5 controllers serve responses to anonymous requests
- After: all `/api/*` endpoints require valid JWT except `/api/health` and `/api/auth/login`
- SPA forward routes (handled by `SpaForwardController`) must remain public

**11. All 16 test files break**
- Test pattern: `@SpringBootTest(webEnvironment=MOCK) + @AutoConfigureMockMvc + @Transactional`
- MockMvc calls like `mockMvc.perform(post("/api/products")...)` will get 401 without auth context
- Every test method needs `@WithMockUser` or security post-processors
- Files affected:
  - `ProductIntegrationTests.java`
  - `ProductValidationTests.java`
  - `CategoryIntegrationTests.java`
  - `CategoryValidationTests.java`
  - `PluginRegistryIntegrationTests.java`
  - `PluginDatabaseTests.java`
  - `PluginDataAndObjectsIntegrationTests.java`
  - `PluginObjectApiAndFilterTests.java`
  - `PluginObjectGapTests.java`
  - `PluginObjectEntityBindingTests.java`
  - `PluginGapTests.java`
  - `IntegrationTests.java`
  - `ApiLayerTests.java`
  - `AjApplicationTests.java`
  - `TestAjApplication.java`
  - `TestcontainersConfiguration.java` (may need user seeding)

**12. Frontend API client needs auth headers**
- `src/main/frontend/src/api/client.ts` has a generic `request()` function that adds `Content-Type: application/json`
- Must add `Authorization: Bearer <token>` to all requests
- Must handle 401 responses (redirect to login, clear token)

---

## User Journey Impact Assessment

| Dimension | Current | After | Assessment |
|-----------|---------|-------|------------|
| Reachability | All pages accessible directly via URL | Login gate before any page; all pages accessible after auth | Neutral (expected for auth) |
| Discoverability | N/A (new login page) | Login page at root when unauthenticated; 9/10 | Good |
| Flow Integration | Direct access to all features | Login -> existing flows unchanged | Neutral (auth adds one gate, no flow disruption) |
| Multi-Persona | Single anonymous user type | READ users see data; EDIT users can modify; PLUGIN_MANAGEMENT users manage plugins | Needs design |

### Discoverability: 9/10
Login page will be the entry point when unauthenticated -- immediately visible, standard pattern.

### Navigation Paths
- Unauthenticated: any URL -> redirect to `/login`
- Authenticated: `/login` -> redirect to `/products` (existing default)
- Logout: Header button -> clear token -> redirect to `/login`

---

## Data Lifecycle Analysis

### Entity: User

| Operation | Backend | UI | Access | Status |
|-----------|---------|-----|--------|--------|
| CREATE | Liquibase migration seed (008) | N/A (admin-seeded only) | Via DB migration | Partial -- seed only |
| READ | UserDetailsService (for auth) | N/A (no user management UI) | Internal only | Sufficient for auth |
| UPDATE | Not planned | Not planned | Not planned | N/A (not in scope) |
| DELETE | Not planned | Not planned | Not planned | N/A (not in scope) |

**Completeness**: 75% (sufficient for admin-seeded-only model)
**Orphaned Operations**: None -- deliberate decision to not have user management UI
**Missing Touchpoints**: No user management CRUD -- this is by design per clarification ("admin-seeded only")

### Entity: JWT Token

| Operation | Backend | UI | Access | Status |
|-----------|---------|-----|--------|--------|
| CREATE | AuthController POST /api/auth/login | Login form | Login page | Planned |
| READ | JwtAuthenticationFilter (every request) | Stored in localStorage | Automatic via API client | Planned |
| UPDATE | Refresh mechanism | Auto-refresh or re-login | Transparent | Design needed |
| DELETE | N/A (stateless) | Clear localStorage on logout | Logout button | Planned |

**Completeness**: 75% -- token refresh strategy undefined

---

## Issues Requiring Decisions

### Critical (Must Decide Before Proceeding)

1. **Role model design: enum column vs. separate roles table**
   - **Issue**: Three permissions (READ, EDIT, PLUGIN_MANAGEMENT) need a storage model. A user could have multiple permissions.
   - **Options**:
     - A) Single `role` enum column with hierarchical roles (e.g., VIEWER has READ; EDITOR has READ+EDIT; ADMIN has all three)
     - B) Separate `user_roles` join table allowing arbitrary permission combinations per user
   - **Recommendation**: Option A (hierarchical roles) -- simpler, matches the 3-tier permission model, avoids join table complexity for what is essentially 3 levels of access
   - **Rationale**: With only 3 permissions and admin-seeded users, hierarchical roles (VIEWER/EDITOR/ADMIN) map cleanly. A join table is over-engineering for this scale.

2. **Token refresh strategy**
   - **Issue**: JWT tokens expire. When they do, users get 401. How should the frontend handle this?
   - **Options**:
     - A) Single long-lived access token (e.g., 24h) -- simple, user re-logs daily
     - B) Short-lived access token (15min) + refresh token -- more secure, more complex (needs refresh endpoint, token rotation, storage for refresh tokens)
     - C) Short-lived access token (1h) with no refresh -- moderate security, user re-logs hourly
   - **Recommendation**: Option A (long-lived access token, 24h) -- matches the "admin-seeded users only" low-trust-boundary model, simplest implementation
   - **Rationale**: This is an internal tool with seeded users, not a public-facing app. Refresh tokens add significant complexity (DB storage, rotation, revocation) for minimal benefit here.

3. **Plugin server-sdk.ts authentication approach**
   - **Issue**: `server-sdk.ts` makes direct HTTP calls to the host API. After security is added, these calls need authentication. But plugins are server-side processes, not users.
   - **Options**:
     - A) Pass a user JWT token to `createServerSDK(pluginId, hostBaseUrl, token)` -- plugin must obtain a token somehow
     - B) Create a plugin API key mechanism -- plugins authenticate with a static key, not user JWT
     - C) Whitelist plugin API paths (e.g., `/api/plugins/{pluginId}/*`) from authentication when called with a plugin identifier header
   - **Recommendation**: Option A (pass JWT token) -- simplest, consistent with browser SDK model
   - **Rationale**: Plugin server processes are typically run by an admin. They can use an admin token. Option B adds a new auth mechanism; Option C weakens security.

### Important (Should Decide)

4. **Password hashing for seeded users**
   - **Issue**: Liquibase migration will seed user records. Passwords must be hashed. The hash must be generated at migration time (static) or at application startup.
   - **Options**:
     - A) Pre-computed BCrypt hash in the migration YAML (static, predictable default password like "admin")
     - B) Application startup DataInitializer that seeds users with Spring's PasswordEncoder
   - **Default**: Option A -- keeps seeding in migrations (consistent with existing pattern of sample data in migration 003)
   - **Rationale**: Migration 003 already seeds sample data. User seeding fits the same pattern. A known default password with a "change on first login" note is standard for dev/demo tools.

5. **Frontend auth state management approach**
   - **Issue**: The SPA needs to track authentication state (token, user info, roles). Current codebase uses React Router + Chakra UI with no global state management library.
   - **Options**:
     - A) React Context -- lightweight, no new dependencies, consistent with existing `PluginContext.tsx` pattern
     - B) Add a state management library (zustand, jotai, etc.)
   - **Default**: Option A (React Context) -- matches existing `PluginContext` pattern used in the codebase
   - **Rationale**: The app already uses React Context for plugin state (`src/main/frontend/src/plugins/PluginContext.tsx`). An AuthContext follows the same pattern.

6. **Role-based UI visibility**
   - **Issue**: Should the frontend hide UI elements the user cannot access (e.g., hide "New Product" button for READ-only users) or show them and let the backend reject?
   - **Options**:
     - A) Hide unauthorized UI elements (better UX, requires role info in frontend)
     - B) Show everything, rely on backend 403 responses (simpler frontend, confusing UX)
   - **Default**: Option A (hide unauthorized elements)
   - **Rationale**: Standard UX practice. The JWT payload can include roles, making this straightforward.

7. **Plugin iframe authentication model**
   - **Issue**: Plugin iframes communicate via postMessage to the host, which proxies API calls. The host's `PluginMessageHandler.ts` uses the `api` client. If the `api` client carries the user's JWT, plugin API calls inherit the user's permissions. But `handlePluginFetch` (for `hostApp.fetch`) uses raw `fetch` with `credentials: "omit"`.
   - **Options**:
     - A) Inject the user's JWT into all proxied plugin requests (plugins inherit user permissions)
     - B) Create a separate plugin-scoped token with fixed permissions
   - **Default**: Option A (inherit user permissions) -- plugins act on behalf of the logged-in user
   - **Rationale**: This is the simplest model and maintains the principle of least privilege. The `api` client update will automatically cover `handleApiMessage`. The `handlePluginFetch` path needs explicit JWT injection.

---

## Recommendations

1. **Create a shared test security helper** -- Rather than adding `@WithMockUser` to every test class individually, create a custom annotation (e.g., `@WithMockEditUser`) or a base test configuration that provides default authenticated context. This reduces boilerplate across 16 test files.

2. **Implement security in layers** -- Start with the security filter chain and JWT infrastructure, then update tests, then frontend, then plugin SDK. Each layer can be verified independently.

3. **Use URL-based security over method-level** -- The `SecurityFilterChain` can map URL patterns to roles directly (e.g., `GET /api/**` requires READ, `POST|PUT|DELETE /api/products/**` requires EDIT). This avoids scattering `@PreAuthorize` annotations across controllers and keeps security rules centralized.

4. **Include user roles in JWT claims** -- Embed the role/permissions in the JWT payload so the frontend can read them without an extra API call. This enables role-based UI visibility immediately after login.

5. **Handle the `/assets/plugin-sdk.js` and `/assets/plugin-ui.css` paths** -- These are served as static resources and must be publicly accessible (no auth required), alongside `/api/health` and SPA forward routes.

---

## Risk Assessment

- **Complexity Risk**: HIGH -- Cross-cutting concern touching every layer (backend, frontend, tests, plugins). ~30+ files to create or modify. Spring Boot 4.0.5 security API should be verified (the `SecurityFilterChain` bean approach is standard since Spring Boot 3.x, but 4.x may have further changes).

- **Integration Risk**: MEDIUM -- The plugin iframe model adds a unique authentication propagation path (user JWT -> host API client -> postMessage proxy -> plugin). The `handlePluginFetch` raw fetch path is easy to miss.

- **Regression Risk**: HIGH -- All 16 test files (likely 50+ test methods) must be updated. Any missed test will fail with 401. The jOOQ codegen plugin also runs Liquibase, so the new migration must not break code generation.

- **Security Risk**: MEDIUM -- JWT secret management, password hashing, CORS configuration, and token storage all have security implications. A misconfigured `SecurityFilterChain` could leave endpoints unprotected or block legitimate access.
