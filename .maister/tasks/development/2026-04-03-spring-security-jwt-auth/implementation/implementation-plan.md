# Implementation Plan: Spring Security JWT Authentication

## Overview
Total Steps: 38
Task Groups: 6
Expected Tests: 22-38

## Implementation Steps

### Task Group 1: Database Layer (User Model + Migration)
**Dependencies:** None
**Estimated Steps:** 6

- [x] 1.0 Complete database layer
  - [x] 1.1 Write 4 focused tests for User entity and repository
    - Test that User entity persists with username and passwordHash via UserRepository
    - Test unique constraint violation on duplicate username
    - Test that permissions are persisted via @ElementCollection join table (user_permissions)
    - Test that seed users from migration exist and have correct permissions (viewer=READ, editor=READ+EDIT, admin=READ+EDIT+PLUGIN_MANAGEMENT)
  - [x] 1.2 Create Permission enum in `pl.devstyle.aj.user`
    - File: `src/main/java/pl/devstyle/aj/user/Permission.java`
    - Values: READ, EDIT, PLUGIN_MANAGEMENT
  - [x] 1.3 Create User entity in `pl.devstyle.aj.user`
    - File: `src/main/java/pl/devstyle/aj/user/User.java`
    - Extends BaseEntity; @SequenceGenerator(name="base_seq", sequenceName="user_seq", allocationSize=1)
    - Fields: username (unique, not null, length 50), passwordHash (not null, length 72)
    - @ElementCollection(fetch=LAZY) @CollectionTable(name="user_permissions", joinColumns=@JoinColumn(name="user_id")) @Enumerated(EnumType.STRING) @Column(name="permission") Set<Permission> permissions
    - Business-key equals/hashCode on username (follow Category pattern)
    - @Getter @Setter @NoArgsConstructor (follow existing entity pattern)
  - [x] 1.4 Create UserRepository
    - File: `src/main/java/pl/devstyle/aj/user/UserRepository.java`
    - JpaRepository<User, Long> with Optional<User> findByUsername(String username)
  - [x] 1.5 Create Liquibase migration 008-create-users-table.yaml
    - File: `src/main/resources/db/changelog/2026/008-create-users-table.yaml`
    - Changeset 008-create-user-seq: createSequence user_seq startValue=1 incrementBy=1
    - Changeset 008-create-users-table: users table (id BIGINT PK, username VARCHAR(50) NOT NULL UNIQUE, password_hash VARCHAR(72) NOT NULL, created_at TIMESTAMP NOT NULL, updated_at TIMESTAMP NOT NULL)
    - Changeset 008-create-user-permissions-table: user_permissions table (user_id BIGINT FK->users NOT NULL, permission VARCHAR(30) NOT NULL, PK on user_id+permission)
    - Changeset 008-seed-users: insert 3 users with pre-computed BCrypt hashes
      - viewer / viewer123 -> permissions: [READ]
      - editor / editor123 -> permissions: [READ, EDIT]
      - admin / admin123 -> permissions: [READ, EDIT, PLUGIN_MANAGEMENT]
    - All changesets with rollback sections
  - [x] 1.6 Ensure database layer tests pass
    - Run ONLY the 4 tests written in 1.1
    - Do NOT run entire test suite

**Acceptance Criteria:**
- The 4 tests pass
- User entity persists correctly with permissions via @ElementCollection
- Migration 008 creates tables and seeds 3 users
- UserRepository.findByUsername works

---

### Task Group 2: Backend Security Infrastructure (JWT + SecurityFilterChain + AuthController)
**Dependencies:** Group 1
**Estimated Steps:** 10

- [x] 2.0 Complete backend security infrastructure
  - [x] 2.1 Write 8 focused tests for security layer (AuthIntegrationTests)
    - File: `src/test/java/pl/devstyle/aj/core/security/AuthIntegrationTests.java`
    - Test login_validCredentials_returnsTokenInResponse (POST /api/auth/login with admin/admin123 returns 200 with {token})
    - Test login_invalidPassword_returns401
    - Test login_unknownUser_returns401
    - Test protectedEndpoint_noToken_returns401 (GET /api/products without Authorization header)
    - Test protectedEndpoint_validToken_returns200 (GET /api/products with valid JWT)
    - Test protectedEndpoint_expiredToken_returns401
    - Test editEndpoint_readOnlyUser_returns403 (POST /api/products with viewer's token)
    - Test pluginManagement_nonAdminUser_returns403 (PUT /api/plugins/{id}/manifest with editor's token)
  - [x] 2.2 Add dependencies to pom.xml
    - spring-boot-starter-security
    - io.jsonwebtoken:jjwt-api:0.12.6
    - io.jsonwebtoken:jjwt-impl:0.12.6 (runtime scope)
    - io.jsonwebtoken:jjwt-jackson:0.12.6 (runtime scope)
    - spring-boot-starter-security-test (test scope)
  - [x] 2.3 Add JWT configuration to application.properties
    - app.jwt.secret=<256-bit base64 encoded key for dev>
    - app.jwt.expiration-ms=86400000 (24h)
  - [x] 2.4 Create JwtTokenProvider in `pl.devstyle.aj.core.security`
    - File: `src/main/java/pl/devstyle/aj/core/security/JwtTokenProvider.java`
    - @Component; constructor injection of @Value("${app.jwt.secret}") and @Value("${app.jwt.expiration-ms}")
    - generateToken(String username, Set<Permission> permissions): String — builds JWT with sub=username, permissions=list of strings, iat, exp
    - getUsernameFromToken(String token): String
    - getPermissionsFromToken(String token): Set<String>
    - validateToken(String token): boolean (returns false for expired/malformed)
    - Use io.jsonwebtoken.Jwts builder and parser (0.12.x API)
  - [x] 2.5 Create CustomUserDetailsService in `pl.devstyle.aj.core.security`
    - File: `src/main/java/pl/devstyle/aj/core/security/CustomUserDetailsService.java`
    - @Service; implements UserDetailsService
    - loadUserByUsername: loads User from UserRepository, maps permissions to GrantedAuthority with "PERMISSION_" prefix
    - Throws UsernameNotFoundException if user not found
  - [x] 2.6 Create JwtAuthenticationFilter in `pl.devstyle.aj.core.security`
    - File: `src/main/java/pl/devstyle/aj/core/security/JwtAuthenticationFilter.java`
    - @Component; extends OncePerRequestFilter
    - Extracts Bearer token from Authorization header
    - Validates token via JwtTokenProvider
    - On valid token: creates UsernamePasswordAuthenticationToken with permissions as authorities, sets SecurityContext
    - On invalid/missing token: does nothing (lets SecurityFilterChain handle 401)
  - [x] 2.7 Create SecurityConfiguration in `pl.devstyle.aj.core.security`
    - File: `src/main/java/pl/devstyle/aj/core/security/SecurityConfiguration.java`
    - @Configuration; @Bean SecurityFilterChain
    - CSRF disabled (stateless JWT)
    - Session management: STATELESS
    - Custom AuthenticationEntryPoint: returns 401 JSON ErrorResponse for unauthenticated
    - Custom AccessDeniedHandler: returns 403 JSON ErrorResponse for insufficient permissions
    - URL authorization mapping:
      - PERMIT_ALL: POST /api/auth/login, GET /api/health, static assets (/assets/**), SPA routes (/, /index.html, /*.js, /*.css, /favicon.ico)
      - hasAuthority("PERMISSION_READ"): GET /api/categories/**, GET /api/products/**, GET /api/plugins, GET /api/plugins/{id}, GET /api/plugins/**/objects/**, GET /api/plugins/**/products/**/data
      - hasAuthority("PERMISSION_EDIT"): POST /api/categories/**, PUT /api/categories/**, DELETE /api/categories/**, POST /api/products/**, PUT /api/products/**, DELETE /api/products/**, PUT /api/plugins/**/objects/**, DELETE /api/plugins/**/objects/**, PUT /api/plugins/**/products/**/data, DELETE /api/plugins/**/products/**/data
      - hasAuthority("PERMISSION_PLUGIN_MANAGEMENT"): PUT /api/plugins/{id}/manifest, PATCH /api/plugins/{id}/enabled, DELETE /api/plugins/{id}
      - anyRequest().authenticated() as fallback
    - CORS: allow origins for plugin dev servers (configurable)
    - Add JwtAuthenticationFilter before UsernamePasswordAuthenticationFilter
    - Configure AuthenticationManager bean with CustomUserDetailsService + BCryptPasswordEncoder
  - [x] 2.8 Create AuthController in `pl.devstyle.aj.api`
    - File: `src/main/java/pl/devstyle/aj/api/AuthController.java`
    - @RestController @RequestMapping("/api/auth")
    - POST /login: accepts LoginRequest(username, password), authenticates via AuthenticationManager, generates JWT via JwtTokenProvider, returns LoginResponse(token)
    - LoginRequest record: `src/main/java/pl/devstyle/aj/api/LoginRequest.java` with @NotBlank username, @NotBlank password
    - LoginResponse record: `src/main/java/pl/devstyle/aj/api/LoginResponse.java` with String token
    - Catch AuthenticationException -> 401 with ErrorResponse JSON
  - [x] 2.9 Update GlobalExceptionHandler for security exceptions
    - File: `src/main/java/pl/devstyle/aj/core/error/GlobalExceptionHandler.java`
    - Add handler for AccessDeniedException -> 403 Forbidden ErrorResponse (for any method-level security denials)
    - Note: Primary 401/403 handling is in SecurityConfiguration's entrypoint/handler (fires before controllers)
  - [x] 2.10 Ensure security infrastructure tests pass
    - Run ONLY the 8 tests written in 2.1
    - Do NOT run entire test suite

**Acceptance Criteria:**
- The 8 tests pass
- Login endpoint returns JWT with correct claims
- Protected endpoints reject unauthenticated requests with 401
- Endpoints enforce permission-based access (403 for insufficient)
- Health endpoint remains public

---

### Task Group 3: Existing Test Updates (Security Context for 16 Test Files)
**Dependencies:** Group 2
**Estimated Steps:** 5

- [x] 3.0 Complete test updates for security context
  - [x] 3.1 Write 3 focused tests to verify test security helpers work
    - Test that @WithMockUser(authorities={"PERMISSION_READ","PERMISSION_EDIT"}) allows CRUD operations in MockMvc
    - Test that custom test security annotation (if created) works correctly
    - Test that tests without security context receive 401
  - [x] 3.2 Create shared test security annotation (optional, evaluate if helpful)
    - File: `src/test/java/pl/devstyle/aj/WithMockEditUser.java` — meta-annotation with @WithMockUser(username="test-editor", authorities={"PERMISSION_READ","PERMISSION_EDIT"})
    - File: `src/test/java/pl/devstyle/aj/WithMockAdminUser.java` — meta-annotation with @WithMockUser(username="test-admin", authorities={"PERMISSION_READ","PERMISSION_EDIT","PERMISSION_PLUGIN_MANAGEMENT"})
  - [x] 3.3 Update all existing test files with security context
    - Add `@WithMockUser(authorities={"PERMISSION_READ","PERMISSION_EDIT"})` or custom annotation to each test class
    - Plugin tests that test manifest upload/enable/disable/delete need PLUGIN_MANAGEMENT authority too
    - Files to update (apply class-level annotation):
      1. `src/test/java/pl/devstyle/aj/AjApplicationTests.java`
      2. `src/test/java/pl/devstyle/aj/IntegrationTests.java`
      3. `src/test/java/pl/devstyle/aj/api/ApiLayerTests.java`
      4. `src/test/java/pl/devstyle/aj/category/CategoryIntegrationTests.java`
      5. `src/test/java/pl/devstyle/aj/category/CategoryValidationTests.java`
      6. `src/test/java/pl/devstyle/aj/product/ProductIntegrationTests.java`
      7. `src/test/java/pl/devstyle/aj/product/ProductValidationTests.java`
      8. `src/test/java/pl/devstyle/aj/core/plugin/PluginRegistryIntegrationTests.java` (needs PLUGIN_MANAGEMENT)
      9. `src/test/java/pl/devstyle/aj/core/plugin/PluginDatabaseTests.java`
      10. `src/test/java/pl/devstyle/aj/core/plugin/PluginDataAndObjectsIntegrationTests.java` (needs PLUGIN_MANAGEMENT for manifest setup)
      11. `src/test/java/pl/devstyle/aj/core/plugin/PluginObjectApiAndFilterTests.java` (needs PLUGIN_MANAGEMENT for manifest setup)
      12. `src/test/java/pl/devstyle/aj/core/plugin/PluginObjectGapTests.java` (needs PLUGIN_MANAGEMENT for manifest setup)
      13. `src/test/java/pl/devstyle/aj/core/plugin/PluginObjectEntityBindingTests.java` (needs PLUGIN_MANAGEMENT for manifest setup)
      14. `src/test/java/pl/devstyle/aj/core/plugin/PluginGapTests.java` (needs PLUGIN_MANAGEMENT for manifest setup)
      15. `src/test/java/pl/devstyle/aj/TestAjApplication.java` (may not need annotation — evaluate)
      16. `src/test/java/pl/devstyle/aj/TestcontainersConfiguration.java` (configuration class — no annotation needed)
    - For plugin tests that set up plugins via manifest PUT AND test CRUD operations, use admin-level authorities at class level
    - Add spring-security-test import to each file as needed
  - [x] 3.4 Run all existing test files to verify they pass with security context
    - Execute: `./mvnw test` from project root
    - All pre-existing tests must pass — zero regressions
  - [x] 3.5 Ensure test update tests pass
    - Run ONLY the 3 tests written in 3.1 plus full test suite verification from 3.4

**Acceptance Criteria:**
- The 3 helper tests pass
- All 16 pre-existing test files pass with security annotations added
- Zero test regressions
- Plugin tests use admin-level authorities where manifest operations are needed

---

### Task Group 4: Frontend Authentication (Login Page, AuthContext, API Client, UI Visibility)
**Dependencies:** Group 2
**Estimated Steps:** 8

- [x] 4.0 Complete frontend authentication layer
  - [x] 4.1 Write 5 focused tests for frontend auth
    - Test that api client includes Authorization header from localStorage token
    - Test that api client redirects to /login on 401 response
    - Test that LoginPage renders username/password form and submits to /api/auth/login
    - Test that AuthContext provides token/permissions/login/logout
    - Test that unauthorized UI elements are hidden (e.g., no "New Product" button for READ-only user)
  - [x] 4.2 Update API client to inject JWT and handle 401
    - File: `src/main/frontend/src/api/client.ts`
    - In request(): read token from localStorage("auth_token"), add Authorization: Bearer header if present
    - On 401 response: clear localStorage("auth_token"), redirect to /login via window.location
  - [x] 4.3 Create AuthContext and AuthProvider
    - File: `src/main/frontend/src/auth/AuthContext.tsx`
    - Follow PluginContext pattern (createContext + Provider + useAuth hook)
    - State: token (string|null), permissions (string[]), username (string|null)
    - login(username, password): POST /api/auth/login, store token in localStorage, decode JWT payload (base64) to extract permissions array and sub
    - logout(): clear localStorage, reset state
    - On mount: check localStorage for existing token, decode and validate expiry, set state
    - Export useAuth() hook
  - [x] 4.4 Create LoginPage component
    - File: `src/main/frontend/src/pages/LoginPage.tsx`
    - Username + password inputs using Chakra UI
    - Submit button, error message display
    - On success: navigate to /products
    - Styled consistently with existing pages
  - [x] 4.5 Update router with auth guard
    - File: `src/main/frontend/src/router.tsx`
    - Add /login route outside Layout (public route)
    - Wrap Layout with auth guard: if no valid token, redirect to /login
    - Redirect /login to /products if already authenticated
  - [x] 4.6 Update main.tsx to wrap with AuthProvider
    - File: `src/main/frontend/src/main.tsx`
    - Add AuthProvider above PluginProvider in the component tree
  - [x] 4.7 Update Header with logout button and Sidebar with permission-based visibility
    - File: `src/main/frontend/src/components/layout/Header.tsx` — add logout button (calls useAuth().logout())
    - File: `src/main/frontend/src/components/layout/Sidebar.tsx` — conditionally show "Plugins" nav item only when user has PLUGIN_MANAGEMENT permission (useAuth().permissions.includes("PLUGIN_MANAGEMENT"))
  - [x] 4.8 Update pages for role-based UI visibility
    - ProductListPage: hide "New Product" button for users without EDIT permission
    - CategoryListPage: hide "New Category" button for users without EDIT permission
    - ProductDetailPage: hide edit/delete actions for users without EDIT permission
    - PluginListPage: hide "Register Plugin" button for users without PLUGIN_MANAGEMENT permission
    - Use useAuth().permissions to check
  - [x] 4.9 Ensure frontend auth tests pass
    - Run ONLY the 5 tests written in 4.1
    - Do NOT run entire test suite

**Acceptance Criteria:**
- The 5 tests pass
- Login page works end-to-end (form -> API -> token storage -> redirect)
- API client injects JWT in all requests
- 401 responses redirect to login
- UI elements hidden based on permissions from decoded JWT
- Logout clears state and redirects to /login

---

### Task Group 5: Plugin SDK Updates (Browser + Server SDK JWT Propagation)
**Dependencies:** Group 4
**Estimated Steps:** 5

- [x] 5.0 Complete plugin SDK JWT propagation
  - [x] 5.1 Write 3 focused tests for plugin SDK auth
    - Test that handlePluginFetch injects Authorization header from localStorage token
    - Test that server-sdk createServerSDK with token parameter includes Authorization header in requests
    - Test that server-sdk data endpoint URLs use correct /products/{id}/data path (bug fix verification)
  - [x] 5.2 Update PluginMessageHandler handlePluginFetch to inject JWT
    - File: `src/main/frontend/src/plugins/PluginMessageHandler.ts`
    - In handlePluginFetch(): read token from localStorage("auth_token"), add Authorization: Bearer header to fetchOptions.headers
    - Note: handleApiMessage already uses `api` client which will carry JWT after Group 4 changes — no changes needed there
  - [x] 5.3 Update server-sdk.ts to accept optional token parameter
    - File: `plugins/server-sdk.ts`
    - Change signature: createServerSDK(pluginId, hostBaseUrl?, token?)
    - In hostFetch(): if token is provided, add Authorization: Bearer header
    - Fix data endpoint URLs: change `/api/plugins/${pluginId}/data/${productId}` to `/api/plugins/${pluginId}/products/${productId}/data` for getData, setData, removeData
  - [x] 5.4 Update server-sdk.ts ServerSDK interface documentation
    - Add JSDoc noting that token parameter enables authenticated requests
  - [x] 5.5 Ensure plugin SDK tests pass
    - Run ONLY the 3 tests written in 5.1
    - Do NOT run entire test suite

**Acceptance Criteria:**
- The 3 tests pass
- Plugin iframe API calls carry user JWT (via api client for handleApiMessage, via explicit injection for handlePluginFetch)
- Server SDK includes Authorization header when token is provided
- Server SDK data endpoint URLs corrected (bug fix)

---

### Task Group 6: Test Review & Gap Analysis
**Dependencies:** All previous groups (1-5)
**Estimated Steps:** 4

- [x] 6.0 Review and fill critical gaps
  - [x] 6.1 Review tests from previous groups (23 existing tests from groups 1-5)
  - [x] 6.2 Analyze gaps for THIS feature only
    - Check: are all endpoint permission tiers tested? (PERMIT_ALL, READ, EDIT, PLUGIN_MANAGEMENT)
    - Check: is CORS configuration tested for plugin origins?
    - Check: is JWT expiry handled correctly end-to-end?
    - Check: is the SpaForwardController still publicly accessible?
    - Check: does /assets/** path remain public? (plugin-sdk.js, plugin-ui.css)
    - Check: are malformed JWTs handled gracefully?
  - [x] 6.3 Write 6 additional strategic tests
    - Auth edge cases: malformed JWT (random string), JWT with tampered permissions, JWT with wrong signing key
    - Endpoint access matrix: viewer can GET but not POST products, editor can POST products but not manage plugins
    - Public endpoints: /api/health accessible without token, /api/auth/login accessible without token
    - SPA routing: non-API paths forward to index.html without auth
    - CORS: verify plugin origin headers are present in responses
  - [x] 6.4 Run full test suite (104 backend + 34 frontend passed)
    - Run security-related test classes + all existing tests with security context
    - Verify zero regressions across the full test suite

**Acceptance Criteria:**
- All feature tests pass (~23-33 total)
- No more than 10 additional tests added
- Full endpoint permission matrix verified
- No regressions in existing test suite

---

## Execution Order

1. Group 1: Database Layer (6 steps) — no dependencies
2. Group 2: Backend Security Infrastructure (10 steps) — depends on Group 1
3. Group 3: Existing Test Updates (5 steps) — depends on Group 2
4. Group 4: Frontend Authentication (8 steps) — depends on Group 2
5. Group 5: Plugin SDK Updates (5 steps) — depends on Group 4
6. Group 6: Test Review & Gap Analysis (4 steps) — depends on all previous

Note: Groups 3 and 4 can potentially be parallelized since they both depend on Group 2 but do not depend on each other. However, sequential execution is safer to ensure test stability before frontend work.

## Standards Compliance

Follow standards from `.maister/docs/standards/`:
- `global/` — Always applicable (minimal-implementation.md, error-handling.md)
- `backend/models.md` — User entity: extends BaseEntity, @SequenceGenerator, @ElementCollection for permissions, EnumType.STRING, business-key equals/hashCode on username
- `backend/api.md` — /api/auth/login follows REST conventions; consistent ErrorResponse for 401/403
- `backend/migrations.md` — Migration 008: reversible with rollback, separate sequence/table/data changesets
- `testing/backend-testing.md` — Integration-first, @Import(TestcontainersConfiguration.class), action_condition_expectedResult naming, 2-8 tests per group, MockMvc + jsonPath
- `frontend/components.md` — LoginPage: single responsibility; AuthContext: context provider pattern matching PluginContext

## Notes

- **Test-Driven**: Each group starts with 2-8 tests
- **Run Incrementally**: Only new tests after each group
- **Mark Progress**: Check off steps as completed
- **Reuse First**: Prioritize existing components from spec (BaseEntity, GlobalExceptionHandler pattern, PluginContext pattern, Category entity pattern, Liquibase migration pattern)
- **Security-Critical Ordering**: Database model first, then security infrastructure, then tests, then frontend — each layer verifiable independently
- **Plugin Compatibility**: handleApiMessage path inherits JWT automatically via api client update; handlePluginFetch path needs explicit injection
- **Server SDK Bug Fix**: Data endpoint URLs corrected from `/data/{productId}` to `/products/{productId}/data` as part of Group 5
- **jOOQ Codegen**: Migration 008 adds new tables that will be picked up by jOOQ codegen — verify generated sources compile after migration
