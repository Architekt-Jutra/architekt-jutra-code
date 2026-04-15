# Requirements — Spring Security JWT Authentication

## Initial Description
Add security to the app using spring-security. Issue JWT tokens for logged users containing permissions: READ (read data), EDIT (read + edit data), PLUGIN_MANAGEMENT. Backend + frontend + plugin SDK.

## Q&A

### Phase 1 Clarifications
1. **User creation**: Admin-seeded only, no public registration
2. **Plugin auth**: Full stack — update sdk.ts + server-sdk.ts with JWT propagation
3. **Test updates**: Update all 16 existing test files in this task
4. **Frontend**: Include login UI in React SPA

### Phase 2 Scope Decisions
1. **Role model**: Independent permissions with join table (READ, EDIT, PLUGIN_MANAGEMENT per user)
2. **Token expiry**: 24h access token, no refresh token
3. **Plugin auth**: Inherit user JWT (plugins act as logged-in user)
4. **Password seeding**: Pre-computed BCrypt hash in Liquibase migration
5. **Frontend state**: React Context (matches existing PluginContext pattern)
6. **UI visibility**: Hide unauthorized elements based on JWT claims

### Phase 5 Requirements
1. **Login**: Username + password (not email). Default admin credentials: admin/admin
2. **User model**: Username only — no email field
3. **Seed users**: Three users — viewer (READ), editor (READ+EDIT), admin (READ+EDIT+PLUGIN_MANAGEMENT)
4. **Plugin listing**: GET /api/plugins requires READ (not PLUGIN_MANAGEMENT), since plugins render for all users

## Functional Requirements

### Authentication
- POST /api/auth/login accepts {username, password}, returns {token, expiresIn, permissions[]}
- JWT token contains: sub (username), permissions (array of READ/EDIT/PLUGIN_MANAGEMENT), iat, exp
- Token expires after 24 hours
- No refresh token mechanism
- No registration endpoint

### Authorization — Endpoint Mapping
- **PERMIT_ALL**: GET /api/health, POST /api/auth/login, SPA routes (/, /index.html, static assets)
- **READ**: GET /api/categories/*, GET /api/products/*, GET /api/plugins, GET /api/plugins/{id}, GET /api/plugins/*/objects/*, GET /api/plugins/*/products/*/data
- **EDIT**: POST/PUT/DELETE /api/categories/*, POST/PUT/DELETE /api/products/*, PUT/DELETE /api/plugins/*/objects/*, PUT/DELETE /api/plugins/*/products/*/data
- **PLUGIN_MANAGEMENT**: PUT /api/plugins/{id}/manifest, PATCH /api/plugins/{id}/enabled, DELETE /api/plugins/{id}

### User Model
- Fields: id, username (unique), passwordHash, createdAt, updatedAt
- Permissions stored in user_permissions join table: user_id + permission (enum: READ, EDIT, PLUGIN_MANAGEMENT)
- No email field

### Seed Data
- viewer / viewer123 — permissions: [READ]
- editor / editor123 — permissions: [READ, EDIT]
- admin / admin123 — permissions: [READ, EDIT, PLUGIN_MANAGEMENT]
- Passwords stored as BCrypt hashes in Liquibase migration

### Frontend
- Login page at /login route
- AuthContext provides: user, token, permissions, login(), logout()
- Token stored in localStorage
- Authorization header injected in all API calls
- Unauthorized elements hidden based on permissions from JWT
- Redirect to /login when unauthenticated or token expired

### Plugin SDK
- Browser SDK (sdk.ts): hostApp.fetch() includes Authorization header from host
- Server SDK (server-sdk.ts): createServerSDK() accepts token parameter, includes in requests
- Plugin iframes inherit logged-in user's JWT

### Error Handling
- 401 Unauthorized: missing or invalid/expired JWT
- 403 Forbidden: valid JWT but insufficient permissions
- Add handlers to GlobalExceptionHandler

### Testing
- Update all 16 existing test files with @WithMockUser or SecurityMockMvcRequestPostProcessors
- New tests: AuthController login tests, authorization per endpoint, JWT validation, invalid token handling

## Scope Boundaries
### In scope
- Backend security (Spring Security + JWT)
- Frontend login page + auth context
- Plugin SDK JWT propagation
- Test updates
- Liquibase migration for users + permissions

### Out of scope
- User management UI (CRUD users)
- Password change/reset
- Token refresh mechanism
- Rate limiting on login endpoint
- Audit logging of auth events
- Multi-tenant / organization support

## Reusability Opportunities
- BaseEntity for User entity
- GlobalExceptionHandler pattern for security exceptions
- Existing PluginContext pattern for AuthContext
- Existing Liquibase migration YAML format
- Existing test infrastructure (Testcontainers + MockMvc)
