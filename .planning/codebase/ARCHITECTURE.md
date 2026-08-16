<!-- refreshed: 2026-08-16 -->
# Architecture

**Analysis Date:** 2026-08-16

## System Overview

```text
┌───────────────────────────────────────────────────────────────────────────┐
│  Frontend SPA (React + TS + Vite)                                          │
│  `src/main/frontend/src/`  →  built into `src/main/resources/static/`     │
│  Pages, plugin-sdk, plugin iframes, footprint UI                           │
└───────────────────────────┬─────────────────────────────────────────────┘
                              │ HTTP (JWT / OAuth2 bearer)
                              ▼
┌───────────────────────────────────────────────────────────────────────────┐
│  Spring Boot Core App (`pl.devstyle.aj`, module: root `pom.xml`)           │
│  `src/main/java/pl/devstyle/aj/`                                          │
├───────────────────┬───────────────────┬───────────────────┬──────────────┤
│  api/              │  core/security     │  core/oauth2       │  core/plugin│
│  Auth, Health, SPA │  JWT filter/provider│ Authorization Server│ Plugin    │
│  forwarding         │                    │ (RFC-compliant)    │ registry/  │
│                     │                    │                    │ data/objs │
├───────────────────┴───────────────────┴───────────────────┴──────────────┤
│  Domain modules: category/, product/, user/, footprint/, archetype/pricing│
│  Controller → Service → Repository (JPA) / DbXQueryService (jOOQ reads)   │
└───────────────────┬──────────────────────────────────────┬────────────────┘
                     │                                      │
                     ▼                                      ▼
┌───────────────────────────────┐         ┌──────────────────────────────────┐
│  PostgreSQL (Liquibase-managed)│         │  MCP Server (separate module)    │
│  `src/main/resources/db/       │         │  `mcp-server/`                   │
│  changelog/2026/*.yaml`        │         │  Exposes core app's product/     │
│                                │         │  category APIs as MCP tools,     │
│                                │         │  authenticates via OAuth2 token  │
│                                │         │  exchange against core app       │
└───────────────────────────────┘         └──────────────────────────────────┘
```

A separate, unconnected exploration exists at `week9/AJ-dotnet/` — a .NET class library implementing carbon-footprint calculation domain logic (Component Tree / Emission Measurement / Footprint Reporting) with its own test suite. It is not wired into the Spring Boot app; the Java `footprint` and `archetype/pricing` packages appear to be the production port/reimplementation of these same domain concepts.

## Component Responsibilities

| Component | Responsibility | File |
|-----------|----------------|------|
| Core app bootstrap | Spring Boot entry point, `@EnableScheduling` | `src/main/java/pl/devstyle/aj/AjApplication.java` |
| Auth/API layer | Login, health check, SPA fallback routing | `src/main/java/pl/devstyle/aj/api/` |
| Security | JWT issuing/validation, `SecurityFilterChain` | `src/main/java/pl/devstyle/aj/core/security/SecurityConfiguration.java`, `JwtTokenProvider.java`, `JwtAuthenticationFilter.java` |
| OAuth2 Authorization Server | RFC-compliant client registration, token exchange, introspection (used by MCP server and plugins) | `src/main/java/pl/devstyle/aj/core/oauth2/` |
| Plugin framework | Plugin registry, enable/disable, plugin-scoped data storage, generic "plugin object" entity extension mechanism | `src/main/java/pl/devstyle/aj/core/plugin/` |
| Error handling | Centralized exception → HTTP response mapping | `src/main/java/pl/devstyle/aj/core/error/GlobalExceptionHandler.java` |
| Category domain | CRUD for product categories | `src/main/java/pl/devstyle/aj/category/` |
| Product domain | CRUD for products, jOOQ read queries | `src/main/java/pl/devstyle/aj/product/` |
| User domain | User entity/permissions, backs Spring Security | `src/main/java/pl/devstyle/aj/user/` |
| Footprint domain | Carbon footprint calculation and reporting | `src/main/java/pl/devstyle/aj/footprint/` |
| Pricing archetype | Composite pricing calculator (Component/Calculator pattern) | `src/main/java/pl/devstyle/aj/archetype/pricing/` |
| MCP server | Standalone Spring Boot app exposing core-app functionality as MCP tools over OAuth2 token exchange | `mcp-server/src/main/java/pl/devstyle/aj/mcp/` |
| Frontend SPA | React/TypeScript UI, plugin host, iframe-based plugin rendering | `src/main/frontend/src/` |
| Plugin SDK (browser) | Client library plugins use to talk to host app via `postMessage` | `src/main/frontend/src/plugin-sdk/` |
| DB migrations | Liquibase changelogs, one file per schema change | `src/main/resources/db/changelog/2026/` |

## Pattern Overview

**Overall:** Layered monolith (Spring Boot MVC: Controller → Service → Repository) with an embedded plugin/extension subsystem and a satellite MCP server module. Originally scoped as a "microkernel" platform (per `.maister/docs/project/architecture.md`, dated 2026-03-28) — that document is stale; the plugin subsystem is now implemented (`core/plugin/`), not just planned.

**Key Characteristics:**
- Single Maven module builds both backend (Java 25) and frontend (Vite/React, via `frontend-maven-plugin`) into one deployable jar with embedded static resources.
- A second, independent Maven module (`mcp-server/`) is a separate Spring Boot application that calls the core app's REST API as an HTTP client and exposes it as Model Context Protocol tools for AI agents.
- Plugins run as sandboxed iframes in the SPA, communicating with the host app via `postMessage` (`src/main/frontend/src/plugins/PluginFrame.tsx`, `PluginMessageHandler.ts`) and with the backend via OAuth2 tokens issued by the core app's authorization server.
- Domain packages (`category`, `product`, `user`, `footprint`) are feature-oriented (package-by-feature), not layer-oriented — each contains its own Controller, Service, Repository, Entity, Request/Response DTOs.
- jOOQ is used alongside JPA: JPA for entity CRUD/persistence, jOOQ (`DbProductQueryService`, `DbPluginObjectQueryService`) for optimized read queries. jOOQ sources are code-generated at build time from the Liquibase-managed schema via `testcontainers-jooq-codegen-maven-plugin` (see `pom.xml`).

## Layers

**Controller (`*Controller.java`):**
- Purpose: HTTP endpoint mapping, request validation entry point
- Location: one per domain package (e.g. `src/main/java/pl/devstyle/aj/product/ProductController.java`)
- Depends on: Service layer, Request/Response DTOs
- Used by: Spring MVC dispatcher

**Service (`*Service.java`):**
- Purpose: business logic, transaction boundaries
- Location: co-located with each domain package
- Depends on: Repository, other services
- Used by: Controllers

**Repository (`*Repository.java`, Spring Data JPA):**
- Purpose: entity persistence (CRUD)
- Location: co-located with each domain package
- Depends on: JPA/Hibernate, PostgreSQL

**Db*QueryService (jOOQ):**
- Purpose: read-optimized, type-safe queries bypassing JPA entity graphs (avoids N+1, supports MULTISET aggregation)
- Examples: `src/main/java/pl/devstyle/aj/product/DbProductQueryService.java`, `src/main/java/pl/devstyle/aj/core/plugin/DbPluginObjectQueryService.java`
- Depends on: generated jOOQ classes (`target/generated-sources/jooq`, package `pl.devstyle.aj.jooq`)

**core/ (cross-cutting):**
- Purpose: shared infrastructure — security, OAuth2 authorization server, plugin framework, error handling, base entity/auditing
- Location: `src/main/java/pl/devstyle/aj/core/`
- Used by: all domain packages

## Data Flow

### Primary Request Path (authenticated API call)

1. SPA sends request with `Authorization: Bearer <JWT>` header (`src/main/frontend/src/api/client.ts`)
2. `JwtAuthenticationFilter` validates token, sets `SecurityContext` (`src/main/java/pl/devstyle/aj/core/security/JwtAuthenticationFilter.java`)
3. `SecurityConfiguration`'s `SecurityFilterChain` authorizes based on path/role (`src/main/java/pl/devstyle/aj/core/security/SecurityConfiguration.java`)
4. Domain `*Controller` receives request, delegates to `*Service`
5. `*Service` calls `*Repository` (JPA write) or `Db*QueryService` (jOOQ read)
6. Response DTO (`*Response.java`) returned as JSON; errors funneled through `GlobalExceptionHandler` (`src/main/java/pl/devstyle/aj/core/error/GlobalExceptionHandler.java`)

### OAuth2 Token Exchange (MCP Server / Plugin Auth)

1. External client (MCP server, or a plugin) presents its own token/credentials
2. `OAuth2TokenFilter` / `OAuth2AuthorizationFilter` / `OAuth2IntrospectionFilter` process the OAuth2 flow against the core app's authorization server (`src/main/java/pl/devstyle/aj/core/oauth2/`)
3. `DatabaseRegisteredClientRepository` looks up registered clients from `oauth2_registered_client` table (seeded via Liquibase changelog `010-seed-mcp-server-oauth2-client.yaml`)
4. Exchanged token is used by the MCP server (`mcp-server/src/main/java/pl/devstyle/aj/mcp/security/TokenExchangeClient.java`, `AccessTokenHolder.java`) to call the core app's REST API (`AjApiClient.java`) on behalf of the caller

### Plugin Extension Flow

1. Backend registers plugin metadata via `PluginDescriptorService`/`PluginController` (`src/main/java/pl/devstyle/aj/core/plugin/`)
2. Frontend `iframeRegistry.ts` and `PluginFrame.tsx` load the plugin's UI in a sandboxed iframe, injecting plugin-sdk (`src/main/frontend/src/plugin-sdk/`)
3. Plugin communicates with host via `postMessage` (`plugin-sdk/messaging.ts` ↔ `plugins/PluginMessageHandler.ts`)
4. Plugin persists arbitrary structured data through `PluginDataController`/`PluginDataService` (scoped key-value data per plugin) or extends existing entities via `PluginObjectController`/`PluginObjectService` (generic entity-attachment mechanism keyed by `EntityType`)

**State Management (frontend):**
- Auth state: React Context (`src/main/frontend/src/auth/AuthContext.tsx`)
- Plugin state: React Context (`src/main/frontend/src/plugins/PluginContext.tsx`)
- Server data: custom hooks per domain (`src/main/frontend/src/hooks/useProducts.ts`, `useCategories.ts`, `useProductFootprint.ts`, `useFootprintComparison.ts`) — no global store library (no Redux/Zustand detected)

## Key Abstractions

**BaseEntity:**
- Purpose: common id/audit fields for all JPA entities
- Examples: `src/main/java/pl/devstyle/aj/core/BaseEntity.java` (extended by `Category`, `Product`, `PluginDescriptor`, `PluginObject`, `RegisteredClientEntity`)
- Pattern: `@MappedSuperclass`

**PluginObject / EntityType:**
- Purpose: generic mechanism letting plugins attach structured data to core entities (e.g. products) without modifying core schema
- Examples: `src/main/java/pl/devstyle/aj/core/plugin/PluginObject.java`, `EntityType.java`
- Pattern: polymorphic association keyed by entity type + entity id

**Db*QueryService:**
- Purpose: lightweight, non-transactional read services using jOOQ DSL for authorization-safe, N+1-free projections
- Examples: `DbProductQueryService.java`, `DbPluginObjectQueryService.java`
- Pattern: documented in `.maister/docs/standards/backend/jooq.md`

**Pricing Component Tree (`archetype/pricing`):**
- Purpose: composable pricing/calculation model (Composite pattern) — `Component`/`CompositeComponent`/`SimpleComponent`, versioned via `ComponentVersion`, scoped by `Validity`/`Applicability`
- Examples: `src/main/java/pl/devstyle/aj/archetype/pricing/`
- Pattern: mirrors the domain modeling used in `week9/AJ-dotnet/src/FootprintCalculation/ComponentTree/` (same Composite-tree shape, applied to carbon footprint instead of pricing)

## Entry Points

**Core Spring Boot app:**
- Location: `src/main/java/pl/devstyle/aj/AjApplication.java`
- Triggers: `mvn spring-boot:run` / packaged jar execution
- Responsibilities: bootstraps Spring context, scheduling enabled

**MCP server app:**
- Location: `mcp-server/src/main/java/pl/devstyle/aj/mcp/AjMcpApplication.java`
- Triggers: run independently as its own Spring Boot process
- Responsibilities: exposes core app functionality as MCP tools; requires the core app running for token exchange and API calls

**Frontend SPA:**
- Location: `src/main/frontend/src/main.tsx`
- Triggers: browser load of `index.html`; built assets served from `src/main/resources/static/` by `SpaForwardController` (`src/main/java/pl/devstyle/aj/api/SpaForwardController.java`) for client-side routing fallback
- Responsibilities: bootstraps React app, routing (`src/main/frontend/src/router.tsx`)

## Architectural Constraints

- **Threading:** Standard Spring MVC servlet thread-per-request model; `@EnableScheduling` on `AjApplication` means scheduled tasks run on Spring's task scheduler thread pool — check for shared mutable state if adding `@Scheduled` methods.
- **Global state:** None significant beyond Spring-managed singleton beans (services, repositories); no static mutable state observed in domain packages.
- **Circular imports:** None observed between `core/` and domain packages (domain depends on `core`, not vice versa).
- **Module boundary:** `mcp-server` is a fully separate Maven module/process with its own `pom.xml` — it must call the core app over HTTP, it cannot import Java classes from the core app directly.
- **Frontend/backend coupling:** Frontend build is wired into the backend Maven build (`frontend-maven-plugin` in root `pom.xml`, phase `generate-resources`), so `mvn package` on the root module always rebuilds and re-bundles the SPA into `src/main/resources/static/`.
- **jOOQ generation coupling:** jOOQ codegen (`testcontainers-jooq-codegen-maven-plugin`) spins up a throwaway Postgres 18 Testcontainer during `generate-sources` to introspect the Liquibase-applied schema — Docker must be available at build time unless `-Dskip.jooq.generation=true`.

## Anti-Patterns

### Stale architecture documentation

**What happens:** `.maister/docs/project/architecture.md` still describes the app as "pre-alpha scaffolding" with "no business logic" and an empty Liquibase changelog, dated 2026-03-28.
**Why it's wrong:** The codebase now has 11 Liquibase changesets, full CRUD domains (category/product/user), a working plugin framework, an OAuth2 authorization server, and a separate MCP server module — none of this is reflected.
**Do this instead:** Treat `.planning/codebase/ARCHITECTURE.md` (this document) as current source of truth; flag `.maister/docs/project/architecture.md` for a refresh via `/maister:standards-update` or docs-manager.

### Two parallel footprint-calculation implementations

**What happens:** `week9/AJ-dotnet/src/FootprintCalculation/` implements the carbon footprint domain in C#/.NET with its own test suite, while `src/main/java/pl/devstyle/aj/footprint/` and `archetype/pricing/` implement overlapping concepts in Java.
**Why it's wrong:** Risk of divergence — domain rules (emission calculation, breakdown tree) could drift between the two implementations if both are maintained.
**Do this instead:** Treat `week9/AJ-dotnet/` as a design exploration/spike, not a shipped component; confirm with the team whether it should be archived or formally ported before adding more logic to either side.

## Error Handling

**Strategy:** Centralized exception translation to HTTP responses via `@ControllerAdvice`.

**Patterns:**
- `GlobalExceptionHandler` (`src/main/java/pl/devstyle/aj/core/error/GlobalExceptionHandler.java`) maps typed exceptions (`EntityNotFoundException`, `BusinessConflictException`, `CategoryHasProductsException`) to structured `ErrorResponse` bodies with appropriate HTTP status codes
- `FootprintExceptionHandler` (`src/main/java/pl/devstyle/aj/footprint/web/FootprintExceptionHandler.java`) provides footprint-domain-specific error mapping
- OAuth2 flows use `OAuth2ErrorResponse`/`OAuth2Error` (`src/main/java/pl/devstyle/aj/core/oauth2/`) per RFC 6749/7662 error shapes
- MCP server maps errors via `McpToolException` (`mcp-server/src/main/java/pl/devstyle/aj/mcp/exception/McpToolException.java`)

## Cross-Cutting Concerns

**Logging:** Standard Spring Boot logging (`commons-logging`/SLF4J); no centralized structured logging framework detected beyond default Spring Boot config.
**Validation:** `spring-boot-starter-validation` (Jakarta Bean Validation) on request DTOs (`CreateCategoryRequest`, `CreateProductRequest`, etc.); frontend performs client-side validation before submit (per `.maister/docs/standards/frontend/`).
**Authentication:** JWT-based for the SPA (`JwtTokenProvider`, `JwtAuthenticationFilter`), OAuth2 Authorization Server flow for machine clients (MCP server, plugins) — both terminate in `SecurityConfiguration`'s single `SecurityFilterChain`, per the project security standard (`.maister/docs/standards/backend/security.md`) which mandates centralized authorization over method-level `@PreAuthorize`.

---

*Architecture analysis: 2026-08-16*
