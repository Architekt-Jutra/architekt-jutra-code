# Codebase Analysis Report

**Date**: 2026-04-03
**Task**: Add Spring Security with JWT authentication and role-based permissions
**Description**: Add Spring Security with JWT authentication and role-based permissions (READ, EDIT, PLUGIN_MANAGEMENT) to a Spring Boot 4.0.5 microkernel plugin-based platform.
**Analyzer**: codebase-analyzer skill (3 Explore agents: File Discovery, Code Analysis, Context Discovery)

---

## Summary

The codebase is a Spring Boot 4.0.5 microkernel plugin platform (Java 25, PostgreSQL, Liquibase + jOOQ) with zero existing security infrastructure -- no Spring Security dependency, no authentication, no CORS configuration. The platform has 40 Java source files (~1,739 lines) across well-organized feature packages, 16 test files using Testcontainers + MockMvc, and a plugin system with iframe-based frontends communicating via postMessage SDK. Adding JWT-based RBAC requires new dependencies, a user/role data model, security filter chain, JWT token handling, and updates to all existing tests that use MockMvc.

---

## Files Identified

### Primary Files

**/src/main/java/pl/devstyle/aj/product/ProductController.java** (58 lines)
- REST controller at `/api/products` with CRUD endpoints
- GET endpoints need READ role; POST/PUT/DELETE need EDIT role

**/src/main/java/pl/devstyle/aj/category/CategoryController.java** (53 lines)
- REST controller at `/api/categories` with CRUD endpoints
- GET endpoints need READ role; POST/PUT/DELETE need EDIT role

**/src/main/java/pl/devstyle/aj/core/plugin/PluginController.java** (61 lines)
- REST controller at `/api/plugins` managing plugin lifecycle
- manifest PUT, enable/disable PATCH, DELETE need PLUGIN_MANAGEMENT role

**/src/main/java/pl/devstyle/aj/core/plugin/PluginObjectController.java** (86 lines)
- REST controller for plugin custom objects
- GET needs READ; PUT/DELETE need EDIT

**/src/main/java/pl/devstyle/aj/core/plugin/PluginDataController.java** (44 lines)
- REST controller for per-product plugin data
- GET needs READ; PUT/DELETE need EDIT

**/src/main/java/pl/devstyle/aj/core/error/GlobalExceptionHandler.java** (102 lines)
- Central error handling via @RestControllerAdvice
- Must be extended to handle Spring Security exceptions (AccessDeniedException, AuthenticationException)

**/src/main/java/pl/devstyle/aj/core/BaseEntity.java** (36 lines)
- MappedSuperclass with id, createdAt, updatedAt
- User entity should extend this

**/src/main/java/pl/devstyle/aj/api/HealthController.java** (17 lines)
- GET /api/health -- must remain publicly accessible (PERMIT_ALL)

**/src/main/java/pl/devstyle/aj/api/SpaForwardController.java** (36 lines)
- Forwards non-API routes to SPA index.html -- must remain publicly accessible

**/src/main/java/pl/devstyle/aj/core/JpaAuditingConfig.java** (lines TBD)
- @Configuration class pattern to follow for SecurityConfiguration

**pom.xml** (root)
- Must add spring-boot-starter-security, jjwt-api/impl/jackson, spring-security-test

**/src/main/resources/db/changelog/2026/** (7 existing changesets)
- Next available: 008-create-users-table.yaml for user/role schema

### Related Files

**/src/main/java/pl/devstyle/aj/product/ProductService.java**
- Service layer, no direct changes needed but consumers of secured endpoints

**/src/main/java/pl/devstyle/aj/category/CategoryService.java**
- Service layer, no direct changes needed

**/src/main/java/pl/devstyle/aj/core/plugin/PluginService.java**
- Plugin service layer

**/plugins/sdk.ts**
- Shared SDK types -- plugin iframe SDK currently has no auth header support

**/src/test/java/pl/devstyle/aj/TestcontainersConfiguration.java**
- Test infrastructure -- tests must work with security enabled

---

## Current Functionality

The application is a fully functional product catalog with a plugin system but **zero authentication or authorization**. All API endpoints are open to anonymous access. There is no user model, no login mechanism, and no CORS configuration.

### Key Components/Functions

- **Controllers (5)**: ProductController, CategoryController, PluginController, PluginObjectController, PluginDataController -- all expose CRUD at `/api/*`
- **GlobalExceptionHandler**: Handles validation errors, not-found, and generic exceptions via ErrorResponse record
- **BaseEntity**: JPA mapped superclass with audit fields (createdAt, updatedAt)
- **Plugin System**: PluginDescriptor entity, PluginObject for custom data, JSONB storage, iframe-based frontend with postMessage SDK
- **SpaForwardController**: Catches all non-API, non-asset routes and forwards to index.html

### Data Flow

```
Client (browser/plugin iframe)
  -> Controller (@RestController, /api/*)
    -> Service (@Service, @Transactional)
      -> Repository (JpaRepository)
        -> PostgreSQL

Plugin iframes:
  -> postMessage to host
    -> host proxies to /api/plugins/* endpoints
```

Currently no authentication check exists anywhere in this flow.

---

## Dependencies

### Imports (What This Depends On)

- **spring-boot-starter-webmvc**: REST controller infrastructure
- **spring-boot-starter-data-jpa**: Entity persistence, repositories
- **spring-boot-starter-jooq**: Query building for plugin object filtering
- **spring-boot-starter-validation**: Request validation (@Valid, @NotBlank)
- **spring-boot-starter-liquibase**: Database schema migration
- **postgresql**: JDBC driver
- **lombok 1.18.38**: Boilerplate reduction
- **jackson-databind**: JSON serialization
- **spring-boot-docker-compose**: Dev environment

### Dependencies to Add

- **spring-boot-starter-security**: Security filter chain, authentication/authorization
- **jjwt-api + jjwt-impl + jjwt-jackson (0.12.x)**: JWT token creation and validation
- **spring-security-test**: @WithMockUser, SecurityMockMvcRequestPostProcessors

### Consumers (What Depends On This)

- **16 test files**: All integration tests use MockMvc and will receive 401/403 without auth setup
- **Plugin iframes**: Frontend plugins communicate via SDK which calls `/api/` endpoints
- **SPA frontend**: React frontend makes fetch calls to `/api/` endpoints
- **Plugin SDK (server-sdk.ts)**: No auth header support currently

**Consumer Count**: 16+ test files, unknown number of frontend components, plugin iframes
**Impact Scope**: High - every API consumer is affected by adding security

---

## Test Coverage

### Test Files

- **ApiLayerTests.java**: General API layer tests
- **CategoryIntegrationTests.java**: Category CRUD integration tests
- **CategoryValidationTests.java**: Category validation tests
- **ProductIntegrationTests.java**: Product CRUD integration tests
- **ProductValidationTests.java**: Product validation tests
- **PluginRegistryIntegrationTests.java**: Plugin registration tests
- **PluginDatabaseTests.java**: Plugin database tests
- **PluginDataAndObjectsIntegrationTests.java**: Plugin data/object tests
- **PluginObjectApiAndFilterTests.java**: Plugin object API tests
- **PluginObjectGapTests.java**: Plugin object edge cases
- **PluginObjectEntityBindingTests.java**: Entity binding tests
- **PluginGapTests.java**: Plugin edge case tests
- **IntegrationTests.java**: General integration tests

### Coverage Assessment

- **Test count**: 16 test files (likely 50+ individual test methods)
- **Test pattern**: @SpringBootTest(webEnvironment=MOCK) + @AutoConfigureMockMvc + @Transactional + Testcontainers
- **Gaps**: No security tests exist (expected -- no security yet). All existing tests will break when security is added and must be updated to provide authentication context.

---

## Coding Patterns

### Naming Conventions

- **Entities**: Singular nouns extending BaseEntity (Category, Product, PluginDescriptor)
- **Controllers**: `{Resource}Controller` with `@RequestMapping("/api/{resources}")`
- **Services**: `{Resource}Service` with `@Service`
- **Repositories**: `{Entity}Repository extends JpaRepository<Entity, Long>`
- **DTOs**: Records -- `Create{Resource}Request`, `Update{Resource}Request`, `{Resource}Response` with `from()` factory methods
- **Sequences**: `{entity}_seq`
- **Test methods**: `action_condition_expectedResult`
- **Packages**: Feature-based (`category/`, `product/`, `core/plugin/`, `api/`)

### Architecture Patterns

- **Style**: Layered architecture with feature-based package organization
- **Injection**: Constructor injection exclusively (no @Autowired fields)
- **Transactions**: `@Transactional(readOnly=true)` for queries, `@Transactional` for mutations
- **Configuration**: `@Configuration` classes (JpaAuditingConfig as reference)
- **Error handling**: Central `@RestControllerAdvice` with `ErrorResponse` record
- **Database migrations**: Liquibase YAML changesets in `db/changelog/2026/`, sequential numbering (001-007)
- **Lombok usage**: `@Getter`, `@Setter`, `@NoArgsConstructor` on entities

---

## Complexity Assessment

| Factor | Value | Level |
|--------|-------|-------|
| Files to Create | ~8-10 new Java files | High |
| Files to Modify | 5+ controllers, 16 test files, pom.xml, GlobalExceptionHandler | High |
| New Dependencies | 4 (security, jjwt x3) | Medium |
| Consumers Affected | All API consumers (tests, frontend, plugins) | High |
| Existing Test Coverage | 16 test files needing auth updates | High |
| Database Changes | 1 new migration (users + roles table) | Low |

### Overall: Complex

This is a cross-cutting concern that touches every layer of the application. While the codebase is well-structured and relatively small (~1,739 lines across 40 files), security affects every API endpoint, every test, and every consumer. The plugin iframe system adds additional complexity for JWT propagation.

---

## Key Findings

### Strengths
- Clean, consistent architecture makes it straightforward to identify where security hooks go
- Well-established patterns (constructor injection, @Configuration classes, central error handling) to follow
- Comprehensive test suite provides confidence but also means many files to update
- Feature-based package structure naturally accommodates a new `core/security` package
- Liquibase migration chain is clean and sequential

### Concerns
- All 16 test files will need authentication context added -- significant test update effort
- Plugin iframe SDK has no auth token propagation mechanism -- needs design consideration
- No CORS configuration exists -- must be added alongside security
- Spring Boot 4.0.5 may have different Security API patterns than 3.x (e.g., SecurityFilterChain bean vs WebSecurityConfigurerAdapter is already gone, but there may be further changes)
- GlobalExceptionHandler needs security-specific exception handling (401, 403)

### Opportunities
- The existing GlobalExceptionHandler pattern can be extended cleanly for security exceptions
- BaseEntity provides a ready-made superclass for the User entity
- Constructor injection pattern means no refactoring needed for injecting security services
- Test infrastructure with Testcontainers can easily accommodate user seeding in migrations or test setup

---

## Impact Assessment

- **Primary changes**: New security package (`core/security/`), new user package (`user/`), new auth controller (`/api/auth`), new Liquibase migration, pom.xml dependencies
- **Related changes**: GlobalExceptionHandler (add security exceptions), all controllers (verify role annotations if using method-level security), application.properties (JWT config)
- **Test updates**: All 16 test files need MockMvc authentication setup (e.g., `@WithMockUser` or custom test security config), new security-specific test files
- **Frontend/Plugin impact**: SPA needs login UI + token storage, plugin SDK needs JWT propagation

### Risk Level: Medium-High

Security is a cross-cutting concern affecting every API endpoint and consumer. The codebase is small and well-structured which reduces risk, but the breadth of changes (every test file, plugin SDK, frontend) and the criticality of getting security right (auth bypass = vulnerability) elevate the risk. Spring Boot 4.0.5 security API should be verified against current documentation.

---

## Recommendations

### Implementation Strategy

1. **Add dependencies first** -- spring-boot-starter-security, jjwt, spring-security-test to pom.xml
2. **Create data model** -- Liquibase migration 008 for users table with role column (enum: READ, EDIT, PLUGIN_MANAGEMENT), seed an admin user
3. **Build security infrastructure** in `pl.devstyle.aj.core.security`:
   - `SecurityConfiguration` -- SecurityFilterChain bean with endpoint-to-role mappings
   - `JwtTokenProvider` -- Token generation and validation
   - `JwtAuthenticationFilter` -- OncePerRequestFilter extracting JWT from Authorization header
   - `UserDetailsServiceImpl` -- Loads user from database
4. **Create user domain** in `pl.devstyle.aj.user`:
   - `User` entity extending BaseEntity
   - `UserRepository`
   - `AuthController` at `/api/auth` with login endpoint
5. **Update GlobalExceptionHandler** -- Handle AccessDeniedException (403) and AuthenticationException (401)
6. **Configure CORS** -- Allow plugin iframe origins
7. **Update all tests** -- Add `spring-security-test` helpers, consider a shared test base class or custom annotation for authenticated MockMvc requests
8. **Plugin SDK consideration** -- Design JWT propagation for iframe plugins (host passes token via postMessage or cookie-based approach)

### Backward Compatibility

- Health endpoint and SPA routes must remain publicly accessible
- Consider a phased rollout: initially all authenticated users get READ, with role restrictions added incrementally
- Plugin iframe communication may need a separate authentication mechanism (plugin tokens vs user tokens)

### Testing Strategy

- Unit tests for JwtTokenProvider (token create/parse/expire)
- Integration tests for SecurityFilterChain (endpoint access by role)
- Update all existing integration tests with authenticated MockMvc context
- Test 401 for unauthenticated access, 403 for insufficient roles

---

## Next Steps

Proceed to gap analysis to identify specific implementation gaps, resolve open design questions (role model: enum vs separate table, plugin auth mechanism, token refresh strategy), and produce a detailed specification.
