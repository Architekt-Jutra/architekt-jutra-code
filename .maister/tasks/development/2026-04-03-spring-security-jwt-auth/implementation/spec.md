# Specification: Spring Security JWT Authentication

## Goal

Add JWT-based authentication and role-based authorization to the platform so that all API endpoints are protected by permission checks (READ, EDIT, PLUGIN_MANAGEMENT), with admin-seeded users, a frontend login UI, and plugin SDK JWT propagation.

## User Stories

- As a viewer, I want to log in and browse products, categories, and plugin data so that I can see catalog information.
- As an editor, I want to create, update, and delete products, categories, and plugin data so that I can manage the catalog.
- As an admin, I want to register, enable/disable, and delete plugins so that I can manage the platform's extensions.
- As a plugin developer, I want plugin iframes and server SDK calls to inherit the user's JWT so that plugins work seamlessly with the secured API.

## Core Requirements

1. POST /api/auth/login accepts `{username, password}` and returns `{token}` only — permissions are embedded in the JWT, not returned as a separate API field
2. JWT contains: `sub` (username), `permissions` (array of strings), `iat`, `exp` with 24h expiry — frontend decodes the JWT to extract permissions
3. Independent permissions model: users have arbitrary combinations of READ, EDIT, PLUGIN_MANAGEMENT via a join table
4. Endpoint authorization mapping:
   - PERMIT_ALL: GET /api/health, POST /api/auth/login, SPA routes, static assets (/assets/*)
   - READ: GET /api/categories/*, GET /api/products/*, GET /api/plugins, GET /api/plugins/{id}, GET /api/plugins/*/objects/*, GET /api/plugins/*/products/*/data
   - EDIT: POST/PUT/DELETE /api/categories/*, POST/PUT/DELETE /api/products/*, PUT/DELETE /api/plugins/*/objects/*, PUT/DELETE /api/plugins/*/products/*/data
   - PLUGIN_MANAGEMENT: PUT /api/plugins/{id}/manifest, PATCH /api/plugins/{id}/enabled, DELETE /api/plugins/{id}
5. Three seed users via Liquibase migration with pre-computed BCrypt hashes: viewer/viewer123 (READ), editor/editor123 (READ+EDIT), admin/admin123 (READ+EDIT+PLUGIN_MANAGEMENT)
6. Login page at /login route in React SPA with redirect to /products on success
7. AuthContext (React Context) providing: user, token, permissions, login(), logout()
8. Token stored in localStorage; Authorization header injected in all API calls
9. Redirect to /login when unauthenticated or token expired (401 response)
10. Hide unauthorized UI elements based on permissions from JWT (e.g., hide "New Product" button for READ-only users, hide "Plugins" management for non-PLUGIN_MANAGEMENT users)
11. Plugin browser SDK: hostApp.fetch() and handleApiMessage proxy carry Authorization header automatically (via api client update)
12. Plugin browser SDK: handlePluginFetch() injects JWT into raw fetch calls
13. Plugin server SDK: createServerSDK() accepts optional `token` parameter, includes as Authorization header
14. 401 response for missing/invalid/expired JWT; 403 for insufficient permissions
15. Update all 16 existing test files with security context (custom annotation or @WithMockUser)
16. New security-specific integration tests for auth endpoints and authorization rules

## Reusable Components

### Existing Code to Leverage

| Component | File Path | How to Leverage |
|-----------|-----------|-----------------|
| BaseEntity | `src/main/java/pl/devstyle/aj/core/BaseEntity.java` | User entity extends this (gets id, createdAt, updatedAt, sequence-based ID) |
| Category entity | `src/main/java/pl/devstyle/aj/category/Category.java` | Pattern for entity: @SequenceGenerator, @Getter/@Setter/@NoArgsConstructor, business-key equals/hashCode |
| GlobalExceptionHandler | `src/main/java/pl/devstyle/aj/core/error/GlobalExceptionHandler.java` | Add handlers for AccessDeniedException (403) and AuthenticationException (401) using existing ErrorResponse record |
| ErrorResponse record | `src/main/java/pl/devstyle/aj/core/error/ErrorResponse.java` | Reuse for 401/403 error responses — same structure (status, error, message, fieldErrors, timestamp) |
| JpaAuditingConfig | `src/main/java/pl/devstyle/aj/core/JpaAuditingConfig.java` | Pattern for @Configuration class — SecurityConfiguration follows same style |
| Migration YAML format | `src/main/resources/db/changelog/2026/001-create-categories-table.yaml` | Pattern for 008 migration: sequence + table + constraints + rollback |
| API client | `src/main/frontend/src/api/client.ts` | Modify request() to inject Authorization header from localStorage; add 401 intercept |
| PluginContext | `src/main/frontend/src/plugins/PluginContext.tsx` | Pattern for AuthContext: createContext + Provider + useHook, same structure |
| PluginMessageHandler | `src/main/frontend/src/plugins/PluginMessageHandler.ts` | handleApiMessage already uses `api` client (auto-inherits JWT after client update); handlePluginFetch needs explicit JWT injection |
| Router | `src/main/frontend/src/router.tsx` | Add /login route; wrap Layout with auth guard |
| AppShell | `src/main/frontend/src/components/layout/AppShell.tsx` | Existing layout wraps authenticated routes |
| Header | `src/main/frontend/src/components/layout/Header.tsx` | Add logout button |
| Sidebar | `src/main/frontend/src/components/layout/Sidebar.tsx` | Conditionally show "Plugins" nav item based on PLUGIN_MANAGEMENT permission |
| Server SDK | `plugins/server-sdk.ts` | Add optional token parameter to createServerSDK(); inject as Authorization header in hostFetch() |
| Test pattern | `src/test/java/pl/devstyle/aj/category/CategoryIntegrationTests.java` | Pattern for test annotation stack; all 16 files need security context added |
| pom.xml | `pom.xml` | Add spring-boot-starter-security, jjwt-api/impl/jackson, spring-security-test dependencies |
| application.properties | `src/main/resources/application.properties` | Add JWT secret and expiration config properties |

### New Components Required

| Component | Justification |
|-----------|---------------|
| User entity (`pl.devstyle.aj.user.User`) | No user model exists; needed for authentication |
| Permission enum (`pl.devstyle.aj.user.Permission`) | No permission/role model exists; needed for authorization |
| UserRepository | No user persistence layer exists |
| SecurityConfiguration (`pl.devstyle.aj.core.security.SecurityConfiguration`) | No SecurityFilterChain exists; needed to map endpoints to permissions |
| JwtTokenProvider (`pl.devstyle.aj.core.security.JwtTokenProvider`) | No JWT library or token handling exists |
| JwtAuthenticationFilter (`pl.devstyle.aj.core.security.JwtAuthenticationFilter`) | No request filter for extracting/validating JWT from Authorization header |
| CustomUserDetailsService (`pl.devstyle.aj.core.security.CustomUserDetailsService`) | No UserDetailsService implementation for Spring Security |
| AuthController (`pl.devstyle.aj.api.AuthController`) | No login endpoint exists |
| Login request/response records | No auth DTOs exist |
| Liquibase migration 008 | No users/user_permissions tables exist |
| LoginPage component | No login UI exists in the SPA |
| AuthContext + AuthProvider | No authentication state management exists in frontend |
| AuthIntegrationTests | No security tests exist |

## Technical Approach

### Backend Security Layer

- Add `spring-boot-starter-security` and `jjwt-api`/`jjwt-impl`/`jjwt-jackson` (0.12.x) to pom.xml, plus `spring-security-test` for test scope
- Create `SecurityConfiguration` with a `SecurityFilterChain` bean using URL-based authorization (centralized, no @PreAuthorize scattered across controllers)
- `JwtAuthenticationFilter` extends `OncePerRequestFilter`: extracts Bearer token from Authorization header, validates via JwtTokenProvider, sets SecurityContext
- `JwtTokenProvider`: generates token on login, validates/parses token on each request, extracts username + permissions from claims
- `CustomUserDetailsService` loads User from database, maps permissions to Spring Security GrantedAuthority
- JWT secret and 24h expiration configured in application.properties

### User Model

- User entity in `pl.devstyle.aj.user` package extends BaseEntity
- `@ElementCollection` with `@CollectionTable` for permissions (Set<Permission> stored in user_permissions join table) — follows standards: prefer @ElementCollection for simple enums over creating a separate entity
- Permission is an enum: READ, EDIT, PLUGIN_MANAGEMENT stored as EnumType.STRING
- Business-key equals/hashCode on username
- Liquibase migration 008: user_seq, users table, user_permissions table with seed data (3 users with pre-computed BCrypt hashes)

### Authentication Flow

- POST /api/auth/login: validate credentials via AuthenticationManager, generate JWT via JwtTokenProvider, return token only
- LoginRequest record (username, password); LoginResponse record (token) — permissions are in the JWT claims, frontend decodes the token to read them

### Error Handling

- Use Spring Security's AuthenticationEntryPoint and AccessDeniedHandler in SecurityFilterChain to produce consistent ErrorResponse JSON for 401/403 (these fire BEFORE the controller layer, so GlobalExceptionHandler cannot catch them)
- GlobalExceptionHandler: add AccessDeniedException handler only for @PreAuthorize-triggered denials (if any arise from method-level security in future)
- Both entry point and handler must write JSON response directly (not Spring's default HTML/whitelabel)

### Frontend Authentication

- AuthContext (React Context) following PluginContext pattern: AuthProvider wraps the app, useAuth() hook provides user/token/permissions/login/logout
- api client (client.ts): modify request() to read token from localStorage and attach Authorization: Bearer header; on 401 response, clear token and redirect to /login
- Login page: simple username/password form using Chakra UI, calls POST /api/auth/login, stores token in localStorage, decodes JWT to extract permissions, redirects to /products
- Router: add /login route outside the Layout wrapper; protect Layout routes with auth guard that redirects to /login if no valid token
- Header: add logout button that clears localStorage and redirects to /login
- Sidebar: conditionally render "Plugins" nav item only when user has PLUGIN_MANAGEMENT permission
- Product/category pages: conditionally show create/edit/delete buttons only when user has EDIT permission

### Plugin SDK Updates

- Browser SDK (sdk.ts): no changes needed — browser SDK communicates via postMessage, the host proxies via api client which will carry the JWT
- PluginMessageHandler (handlePluginFetch): inject Authorization header by reading token from localStorage directly (no React context access in this function)
- Server SDK (server-sdk.ts): add optional `token` parameter to createServerSDK(pluginId, hostBaseUrl, token?), inject as Authorization: Bearer in hostFetch()
- Server SDK bug fix: correct data endpoint URLs from `/api/plugins/{id}/data/{productId}` to `/api/plugins/{id}/products/{productId}/data`

### Test Updates

- Add `spring-security-test` dependency to pom.xml
- Create a shared custom security annotation (e.g., `@WithMockEditUser`) or use `@WithMockUser(roles = "EDIT")` directly
- Update all 16 existing test files: add security context so MockMvc requests are authenticated
- Most existing tests exercise CRUD, so they need at minimum READ+EDIT permissions
- Plugin tests may need PLUGIN_MANAGEMENT for manifest upload tests
- New AuthIntegrationTests: login success, login failure (bad password, unknown user), token validation, endpoint access by permission level, 401 for expired/missing token, 403 for insufficient permissions

### CORS Configuration

- Configure CORS in SecurityFilterChain to allow plugin iframe origins for server-sdk direct calls
- handlePluginFetch already operates same-origin so CORS is less critical there

## Implementation Guidance

### Testing Approach

- 2-8 focused tests per implementation step group
- Test verification runs only new tests, not entire suite
- Auth tests: login success, login failure, invalid token, expired token, permission checks per endpoint tier
- Existing tests: add security context annotation, verify they still pass

### Standards Compliance

| Standard | Application |
|----------|-------------|
| `standards/backend/models.md` | User entity: extends BaseEntity, @SequenceGenerator, @ElementCollection for permissions, EnumType.STRING, business-key equals/hashCode on username |
| `standards/backend/api.md` | /api/auth/login follows REST conventions; consistent error responses |
| `standards/backend/migrations.md` | Migration 008: reversible with rollback, separate sequence/table/data changesets, descriptive names |
| `standards/testing/backend-testing.md` | Integration-first, @Import(TestcontainersConfiguration.class), action_condition_expectedResult naming, 2-8 tests per group, MockMvc + jsonPath |
| `standards/frontend/components.md` | LoginPage: single responsibility, clear interface, encapsulation; AuthContext: local state pattern |
| `standards/global/minimal-implementation.md` | No user management UI, no refresh tokens, no rate limiting — build only what is needed |
| `standards/global/error-handling.md` | Consistent ErrorResponse for 401/403, fail-fast validation on login input |

## Out of Scope

- User management UI (CRUD users) — admin-seeded only
- Password change or reset functionality
- Token refresh mechanism — 24h access token, daily re-login
- Rate limiting on login endpoint
- Audit logging of authentication events
- Multi-tenant or organization support
- Email field on user model
- Registration endpoint
- Plugin-specific API keys or service tokens (plugins use user JWT)

## Success Criteria

1. All API endpoints return 401 for unauthenticated requests (except health, login, SPA, assets)
2. Endpoints return 403 when user lacks required permission
3. Login with valid credentials returns JWT with correct permissions in claims
4. Frontend redirects to login when unauthenticated; shows appropriate UI based on permissions
5. Plugin iframes continue to work — proxied calls carry user's JWT automatically
6. Server SDK accepts token and includes it in requests
7. All 16 existing test files pass with security context added
8. New security tests verify authentication and authorization rules
9. Three seed users are created by migration and can log in successfully
