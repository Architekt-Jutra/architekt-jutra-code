# Gap Analysis: Build MCP Server

## Summary
- **Risk Level**: Low-Medium
- **Estimated Effort**: Medium
- **Detected Characteristics**: creates_new_entities, involves_data_operations

## Task Characteristics
- Has reproducible defect: no
- Modifies existing code: no
- Creates new entities: yes
- Involves data operations: yes (product listing and adding via Feign)
- UI heavy: no

## Gaps Identified

### Everything Is Missing (Greenfield)

The `mcp-server/` directory does not exist. All code must be created from scratch. The following components are needed, organized by layer:

### 1. Project Structure & Build

| Gap | Details |
|-----|---------|
| Maven project | New `mcp-server/pom.xml` with Spring Boot 4.0.5 parent, MCP SDK, Spring Cloud OpenFeign, OkHttp, Lombok |
| Application class | Entry point with `@SpringBootApplication`, `@EnableFeignClients`, MCP transport/server/router beans |
| application.properties | Server port (separate from main app's 8080), JWT secret (shared with main app), Feign base URL for aj backend |
| Package structure | `pl.devstyle.aj.mcp` with subpackages: `config/`, `security/`, `service/`, `client/`, `exception/`, `controller/` |

### 2. MCP Infrastructure

| Gap | Details | Reference Pattern |
|-----|---------|-------------------|
| WebMvcStatelessServerTransport bean | Stateless HTTP transport at "/" endpoint | `SkillPanelMcpApplication.webMvcStatelessServerTransport()` |
| RouterFunction bean | Routes to transport | `SkillPanelMcpApplication.routerFunction()` |
| McpStatelessSyncServer bean | Server with capabilities, tools registration | `SkillPanelMcpApplication.mcpStatelessServer()` |
| JacksonConfig | ObjectMapper with JavaTimeModule, ISO dates | `JacksonConfig.java` |
| LoggingJsonSchemaValidator | Schema validation decorator for debugging | `LoggingJsonSchemaValidator.java` |

### 3. Security Layer

| Gap | Details | Reference Pattern |
|-----|---------|-------------------|
| JWT filter | Extract Bearer token, validate with jjwt (aj pattern), store in AccessTokenHolder | Adapted from `McpJwtFilter.java` -- must replace devskiller toolkit with jjwt |
| AccessTokenHolder | Request-scoped ThreadLocal for JWT propagation to Feign clients | Direct port from `AccessTokenHolder.java` |
| SecurityFilterChain | Public paths (/.well-known/**, /actuator/health/**), authenticated everything else | `SecurityConfig.java` |
| Authentication entry point | JSON 401 response (or RFC 9728 WWW-Authenticate) | `McpAuthenticationEntryPoint.java` |

**Key adaptation**: The skillpanel-mcp uses `com.devskiller.toolkit.jwt.*` (DevskillerJwtProperties, DevskillerUserDetailsProvider, JwtFilter) for JWT handling. The aj project uses `io.jsonwebtoken:jjwt` with `JwtTokenProvider`. The MCP server's JWT filter must use jjwt directly, replicating the logic from aj's `JwtAuthenticationFilter` combined with the AccessTokenHolder pattern from skillpanel-mcp.

### 4. Feign Client Layer

| Gap | Details | Reference Pattern |
|-----|---------|-------------------|
| ProductClient interface | `@FeignClient` with endpoints for GET /api/products and POST /api/products | `MapClient.java` |
| Feign JWT interceptor | Forward Bearer token from AccessTokenHolder to aj backend (as Authorization header, NOT Auth-Access-Token) | Adapted from `McpJwtTokensFeignRequestInterceptor` |
| DefaultFeignConfiguration | OkHttp client, request options, error decoder, logger | `DefaultFeignConfiguration.java` -- skip LoadBalanced/Kubernetes/Micrometer |
| ProductResponse DTO | Mirror of aj's `ProductResponse` record (id, name, description, photoUrl, price, sku, category, pluginData, timestamps) | aj's `ProductResponse.java` |
| CreateProductRequest DTO | Mirror of aj's `CreateProductRequest` record (name, description, photoUrl, price, sku, categoryId) | aj's `CreateProductRequest.java` |
| CategoryResponse DTO | Nested in ProductResponse (id, name, description, timestamps) | aj's `CategoryResponse.java` |

### 5. Tool Services

| Gap | Details | Reference Pattern |
|-----|---------|-------------------|
| ProductService | Two tool builder methods: `buildToolListProducts()` and `buildToolAddProduct()` | `SkillsetService.java` |
| List products tool | Call GET /api/products via Feign, return as structuredContent. Input: optional category, search, sort filters | `buildToolListSkillsets()` |
| Add product tool | Call POST /api/products via Feign, return created product. Input: name, description, photoUrl, price, sku, categoryId | `buildToolGetSkillset()` (for input handling pattern) |

### 6. Error Handling

| Gap | Details | Reference Pattern |
|-----|---------|-------------------|
| McpToolException | Exception with static factories: validationError(), notFound(), apiError() | Direct port from `McpToolException.java` |
| Error page controller | Custom error page handling | `ErrorPageController.java` |

### 7. Controllers

| Gap | Details | Reference Pattern |
|-----|---------|-------------------|
| WellKnownController | OAuth protected resource metadata at /.well-known/oauth-protected-resource | `WellKnownController.java` |

### 8. Testing

| Gap | Details | Reference Pattern |
|-----|---------|-------------------|
| Context load test | Basic @SpringBootTest | `SkillPanelMcpApplicationTests.java` |
| Schema validation test | Validate output schemas match actual tool responses | `ToolSchemaValidationTest.java` |

## New Capability Analysis

### Integration Points
1. **aj Backend API**: MCP server calls `GET /api/products` (with query params: category, search, sort, pluginFilter) and `POST /api/products` via Feign HTTP clients
2. **MCP Transport**: Single HTTP POST endpoint at "/" for MCP protocol messages
3. **Health/Actuator**: Standard Spring Boot actuator endpoints for monitoring

### Patterns to Follow
The skillpanel-mcp provides complete patterns for every layer. Key files to replicate/adapt:

| Pattern | Source File | Adaptation Needed |
|---------|-------------|-------------------|
| Application bootstrap | `SkillPanelMcpApplication.java` | Replace skillpanel services with ProductService |
| Tool builder | `SkillsetService.java` | Change domain from skillsets to products |
| Feign client | `MapClient.java` | Point to aj backend, use product endpoints |
| JWT filter | `McpJwtFilter.java` | Replace devskiller toolkit with jjwt |
| Token forwarding | `McpJwtTokensFeignRequestInterceptor.java` | Forward as Authorization Bearer (not Auth-Access-Token) |
| Security config | `SecurityConfig.java` | Remove devskiller toolkit dependencies |
| Error handling | `McpToolException.java` | Direct port (no changes needed) |
| Feign config | `DefaultFeignConfiguration.java` | Remove Kubernetes, LoadBalancer, Micrometer, devskiller deps |

### Architectural Impact: Low
- New standalone directory, no changes to existing code
- Own Maven project with own dependencies
- Communicates with main app only via HTTP API

## Data Lifecycle Analysis

### Entity: Product (via Feign to aj backend)

The MCP server does not own product data -- it proxies to the aj backend. Analysis is on what the MCP server exposes to LLM clients:

| Operation | Backend (aj API) | MCP Tool | Status |
|-----------|------------------|----------|--------|
| CREATE | `POST /api/products` -- exists, requires PERMISSION_EDIT | `aj_add_product` tool -- in scope | Planned |
| READ (list) | `GET /api/products` -- exists, requires PERMISSION_READ, supports category/search/sort/pluginFilter params | `aj_list_products` tool -- in scope | Planned |
| READ (single) | `GET /api/products/{id}` -- exists, requires PERMISSION_READ | Not in initial scope | Out of scope |
| UPDATE | `PUT /api/products/{id}` -- exists, requires PERMISSION_EDIT | Not in initial scope | Out of scope |
| DELETE | `DELETE /api/products/{id}` -- exists, requires PERMISSION_EDIT | Not in initial scope | Out of scope |

**Completeness for initial scope**: 100% -- both LIST and ADD are in scope and have corresponding backend endpoints.

**Backend API readiness**: All required endpoints exist and are fully functional. The aj backend requires JWT authentication with PERMISSION_READ for listing and PERMISSION_EDIT for creating. The MCP server must forward the caller's JWT to satisfy these permission checks.

### Entity: Category (dependency for product creation)

The `aj_add_product` tool requires `categoryId`. LLM agents need a way to discover valid category IDs.

| Operation | Backend (aj API) | MCP Tool | Status |
|-----------|------------------|----------|--------|
| READ (list) | `GET /api/categories` -- exists, requires PERMISSION_READ | Not in scope | Gap |

**Completeness**: 50% -- category listing is missing from scope but needed for the add-product workflow.

## Issues Requiring Decisions

### Critical (Must Decide Before Proceeding)

1. **Spring Boot 4.0.5 + MCP SDK Compatibility**
   - The MCP SDK `mcp-spring-webmvc:0.16.0` was built against Spring Boot 3.x (skillpanel uses 3.5.7). Spring Boot 4.0.5 has breaking changes (Spring Framework 7, Jakarta EE 11, Security 7). The SDK may not compile or function correctly.
   - Options:
     - A) Use Spring Boot 4.0.5 and find/verify a compatible MCP SDK version (may require 0.17+ or a milestone)
     - B) Use Spring Boot 3.5.7 for the MCP server (standalone, so version independence is acceptable)
   - Recommendation: **A** -- try 4.0.5 first since it matches the main project. The MCP SDK is under active development and likely has Spring Boot 4.x compatible releases by now. Fall back to B only if blocking issues arise.
   - Rationale: Version alignment reduces cognitive overhead and ensures consistent security/serialization behavior.

2. **Spring Cloud Version for Feign**
   - Spring Cloud OpenFeign requires a Spring Cloud release train compatible with the chosen Spring Boot version. Spring Cloud 2025.0.x is for Spring Boot 3.5.x. Spring Boot 4.0.x likely needs a newer release train.
   - Options:
     - A) Find the Spring Cloud release train compatible with Spring Boot 4.0.5
     - B) Use a plain Feign client (without Spring Cloud) via direct `feign-core` dependency
     - C) Use Spring's built-in `RestClient`/`HttpServiceProxyFactory` declarative clients (Spring Framework 7 feature) instead of Feign
   - Recommendation: **A or C** -- check if Spring Cloud has a Boot 4.x compatible train first. If not, option C (RestClient + HttpServiceProxyFactory) is the modern Spring-native replacement for Feign and works out of the box with Spring Boot 4.
   - Rationale: Feign is the established pattern from skillpanel-mcp, but if Spring Cloud doesn't support Boot 4.x yet, RestClient is the natural successor.

### Important (Should Decide)

1. **Category Listing Tool for Add-Product Workflow**
   - The `aj_add_product` tool requires `categoryId` as a mandatory field. Without a way to list categories, LLM agents must guess or hallucinate category IDs, making product creation unreliable.
   - Options:
     - A) Add `aj_list_categories` tool to initial scope (small effort, same pattern as list products)
     - B) Keep out of scope -- document categoryId as required and let users provide it
   - Default: **A** -- add category listing
   - Rationale: Without category listing, the add-product tool has a critical usability gap for LLM agents. The implementation effort is minimal (one additional Feign method + one tool builder, ~50 lines).

2. **JWT Secret Sharing Between MCP Server and Main App**
   - The aj backend uses HMAC-SHA symmetric JWT signing (`app.jwt.secret`). The MCP server needs the same secret to validate tokens, or it can skip validation and just forward tokens.
   - Options:
     - A) Share the JWT secret -- MCP server validates tokens itself using jjwt (same as main app)
     - B) Trust-and-forward -- MCP server does not validate JWT, just forwards to backend; backend validates
     - C) Validate via the backend -- add a token validation endpoint to the main app
   - Default: **A** -- share JWT secret
   - Rationale: Token validation at the MCP server boundary provides fail-fast behavior and prevents unnecessary backend calls for invalid tokens. Shared secret is simple for development. Option B is simpler but less secure.

3. **MCP Server Port**
   - The main aj app runs on port 8080. The MCP server needs its own port.
   - Options:
     - A) Port 8081 (next sequential)
     - B) Port 3001 (convention for secondary services)
   - Default: **A** -- port 8081
   - Rationale: Sequential numbering is clear for local development.

4. **Tool Naming Prefix**
   - Skillpanel uses `skillpanel_` prefix (e.g., `skillpanel_list_skillsets`). The aj project needs its own prefix.
   - Options:
     - A) `aj_` prefix (matches project name)
     - B) `products_` prefix (matches domain)
   - Default: **A** -- `aj_` prefix (e.g., `aj_list_products`, `aj_add_product`)
   - Rationale: Matches the project name, leaves room for non-product tools in the future.

## Recommendations

1. **Start with infrastructure skeleton** before implementing tools: pom.xml, application class, security config, Feign config, AccessTokenHolder, McpToolException. Verify the app starts and the MCP transport responds.

2. **Implement tools incrementally**: list products first (read-only, simpler), then add product (write, needs category dependency).

3. **Reuse aj's JWT approach** (jjwt with shared HMAC secret) rather than introducing spring-boot-starter-oauth2-resource-server. This keeps the security model consistent and avoids an unnecessary new dependency.

4. **Mirror aj's DTO records** in the MCP server's client package. These are lightweight records matching the JSON response structure -- no need for shared library at this stage.

5. **Skip non-essential skillpanel-mcp features** in initial scope: Kubernetes service discovery, Micrometer metrics, Caffeine caching, WellKnownController (OAuth protected resource metadata). These can be added later.

## Risk Assessment

- **Complexity Risk**: Medium -- Spring Boot 4.0.5 compatibility with MCP SDK and Spring Cloud OpenFeign is the primary unknown. If both work, implementation is straightforward pattern replication.
- **Integration Risk**: Low -- aj backend API is complete with full CRUD for products. Feign client just needs to call existing endpoints.
- **Regression Risk**: None -- greenfield module with no impact on existing code.
- **Security Risk**: Low -- JWT validation uses the same mechanism as the main app. Token forwarding is a well-established pattern.
