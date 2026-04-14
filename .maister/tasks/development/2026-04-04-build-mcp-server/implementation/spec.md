# Specification: Build MCP Server

## Goal

Build a standalone MCP server in the `mcp-server/` directory that exposes aj backend product and category data to LLM agents via three MCP tools, using trust-and-forward JWT authentication and RestClient for backend communication.

## User Stories

- As an LLM agent, I want to list products with optional search text so that I can discover available products in the system.
- As an LLM agent, I want to add a new product so that I can create product data through natural language interaction.
- As an LLM agent, I want to list categories so that I can discover valid category IDs needed for product creation.

## Core Requirements

1. Standalone Maven project in `mcp-server/` at the repository root with Spring Boot 4.0.5, Java 25
2. MCP SDK (`mcp-spring-webmvc`) for stateless WebMVC transport at "/" endpoint
3. Trust-and-forward JWT authentication: extract Bearer token from incoming requests, store in AccessTokenHolder, forward to backend calls via RestClient interceptor (no JWT validation in MCP server)
4. RestClient with `HttpServiceProxyFactory` for declarative HTTP interface to aj backend at `localhost:8080`
5. Server runs on port 8081, separate management port for actuator
6. **aj_list_products** tool: accepts optional `search` text parameter, calls `GET /api/products?search={search}`, returns product list as structuredContent
7. **aj_add_product** tool: accepts `name` (required), `description`, `photoUrl`, `price` (required), `sku` (required), `categoryId` (required), calls `POST /api/products`, returns created product as structuredContent
8. **aj_list_categories** tool: no parameters, calls `GET /api/categories`, returns category list as structuredContent
9. LLM-friendly error handling via McpToolException with static factory methods
10. Programmatic tool registration via `McpStatelessServerFeatures.SyncToolSpecification` builder pattern (no annotation-driven tools)

## Reusable Components

### Existing Code to Leverage

| Component | Source | How to Leverage |
|-----------|--------|----------------|
| Application bootstrap pattern | `/Users/kuba/Projects/devskiller/code/skillpanel-mcp/src/main/java/com/skillpanel/skillpanelmcp/SkillPanelMcpApplication.java` | Replicate transport -> router -> server bean pattern, remove `@EnableFeignClients`, no resources |
| Tool builder pattern | `/Users/kuba/Projects/devskiller/code/skillpanel-mcp/src/main/java/com/skillpanel/skillpanelmcp/service/SkillsetService.java` | Replicate `buildTool*()` method structure with inline JSON schemas and `CallToolResult.builder().structuredContent()` |
| McpToolException | `/Users/kuba/Projects/devskiller/code/skillpanel-mcp/src/main/java/com/skillpanel/skillpanelmcp/exception/McpToolException.java` | Port nearly verbatim -- static factories: `validationError()`, `notFound()`, `apiError()`, `invalidCriteria()` |
| AccessTokenHolder | `/Users/kuba/Projects/devskiller/code/skillpanel-mcp/src/main/java/com/skillpanel/skillpanelmcp/security/AccessTokenHolder.java` | Adapt pattern -- use `@RequestScope` bean (or ThreadLocal) for thread-safe concurrent request handling. The skillpanel reference uses a plain `@Component` singleton which is unsafe under concurrent requests; fix this by making it request-scoped. |
| JacksonConfig | `/Users/kuba/Projects/devskiller/code/skillpanel-mcp/src/main/java/com/skillpanel/skillpanelmcp/config/JacksonConfig.java` | Port verbatim -- JavaTimeModule, ISO dates, lenient deserialization |
| LoggingJsonSchemaValidator | `/Users/kuba/Projects/devskiller/code/skillpanel-mcp/src/main/java/com/skillpanel/skillpanelmcp/config/LoggingJsonSchemaValidator.java` | Port verbatim -- debugging wrapper for schema validation |
| SecurityFilterChain pattern | `/Users/kuba/Projects/devskiller/code/skillpanel-mcp/src/main/java/com/skillpanel/skillpanelmcp/config/SecurityConfig.java` | Adapt: remove devskiller toolkit deps, simplify JWT filter to trust-and-forward (no validation) |
| Product API contract | `/Users/kuba/Projects/dna_ai/code/src/main/java/pl/devstyle/aj/product/ProductController.java` | Use to define RestClient interface: `GET /api/products` params (category, search, sort, pluginFilter), `POST /api/products` body |
| ProductResponse shape | `/Users/kuba/Projects/dna_ai/code/src/main/java/pl/devstyle/aj/product/ProductResponse.java` | Mirror as record DTO in MCP server's client package (id, name, description, photoUrl, price, sku, category, pluginData, createdAt, updatedAt) |
| CreateProductRequest shape | `/Users/kuba/Projects/dna_ai/code/src/main/java/pl/devstyle/aj/product/CreateProductRequest.java` | Mirror as record DTO without validation annotations (name, description, photoUrl, price, sku, categoryId) |
| CategoryResponse shape | `/Users/kuba/Projects/dna_ai/code/src/main/java/pl/devstyle/aj/category/CategoryResponse.java` | Mirror as record DTO (id, name, description, createdAt, updatedAt) |

### New Components Required

| Component | Justification |
|-----------|--------------|
| JWT filter (simplified) | Cannot reuse skillpanel's McpJwtFilter because it delegates to devskiller toolkit JwtFilter for validation. Our trust-and-forward model is simpler: just extract Bearer token and store it, no validation needed. New `OncePerRequestFilter` subclass. |
| RestClient configuration + HTTP interface | Skillpanel uses Feign which is not compatible with Spring Boot 4.0.5 (Spring Cloud version gap). Use Spring-native `RestClient` + `HttpServiceProxyFactory` with a declarative `@HttpExchange` interface instead. |
| RestClient JWT interceptor | Replaces Feign's `McpJwtTokensFeignRequestInterceptor`. New `ClientHttpRequestInterceptor` that reads from AccessTokenHolder and adds `Authorization: Bearer {token}` header. |
| ProductService | Domain-specific tool service: `buildToolListProducts()`, `buildToolAddProduct()`. Cannot reuse skillpanel services -- different domain. |
| CategoryService | Domain-specific tool service: `buildToolListCategories()`. Same justification. |
| pom.xml | New standalone project -- no existing pom to extend. Needs MCP SDK, spring-boot-starter-web, spring-boot-starter-actuator, spring-boot-starter-security, lombok. No Spring Cloud dependencies. |

## Technical Approach

### Architecture

The MCP server is a standalone Spring Boot application that acts as a stateless proxy between LLM agents (MCP clients) and the aj backend API. It owns no data.

```
LLM Agent --> HTTP POST "/" --> McpJwtFilter (extract + store token)
  --> WebMvcStatelessServerTransport --> McpStatelessSyncServer
  --> Tool callHandler --> ProductService/CategoryService
  --> RestClient (with forwarded JWT) --> aj backend (localhost:8080)
  --> Response --> CallToolResult (structuredContent)
```

### Package Structure

```
pl.devstyle.aj.mcp
  ├── AjMcpApplication.java          (entry point + MCP beans)
  ├── config/
  │   ├── SecurityConfig.java         (SecurityFilterChain)
  │   ├── JacksonConfig.java          (ObjectMapper)
  │   ├── LoggingJsonSchemaValidator.java
  │   └── RestClientConfig.java       (RestClient + HttpServiceProxyFactory)
  ├── security/
  │   ├── McpJwtFilter.java           (trust-and-forward Bearer extraction)
  │   └── AccessTokenHolder.java      (ThreadLocal token storage)
  ├── client/
  │   ├── AjApiClient.java            (@HttpExchange interface)
  │   ├── ProductResponse.java        (record DTO)
  │   ├── CreateProductRequest.java   (record DTO)
  │   └── CategoryResponse.java       (record DTO)
  ├── service/
  │   ├── ProductService.java         (aj_list_products, aj_add_product)
  │   └── CategoryService.java        (aj_list_categories)
  └── exception/
      └── McpToolException.java       (LLM-friendly errors)
```

### Security Model (Trust-and-Forward)

The MCP server does NOT validate JWT tokens. It extracts the Bearer token from the `Authorization` header, stores it in `AccessTokenHolder`, and forwards it to the aj backend via RestClient interceptor. The backend validates the token and enforces permissions (PERMISSION_READ, PERMISSION_EDIT). This avoids JWT secret sharing and keeps the security boundary at the backend.

The SecurityFilterChain still requires authentication on all endpoints except actuator health and error. The simplified JWT filter sets a basic `Authentication` object in the SecurityContext to satisfy Spring Security, without actually validating the token.

### RestClient Integration

Use Spring Framework 7's `HttpServiceProxyFactory` with `RestClientAdapter` to create a declarative HTTP interface:

- `AjApiClient` interface with `@HttpExchange` annotated methods
- `RestClientConfig` creates `RestClient.Builder` with base URL and JWT interceptor
- `HttpServiceProxyFactory` generates the proxy implementation

### Tool Simplification

Per requirements, tool parameters are simplified for LLM agents:
- **aj_list_products**: only `search` (optional text). Not exposing `category`, `sort`, `pluginFilter` query params.
- **aj_add_product**: all fields from `CreateProductRequest` (name, description, photoUrl, price, sku, categoryId). Validation happens at the backend.
- **aj_list_categories**: no parameters.

### Dependencies

**Include:**
- `io.modelcontextprotocol.sdk:mcp-spring-webmvc` (latest compatible with Spring Boot 4.0.5)
- `spring-boot-starter-web`
- `spring-boot-starter-actuator`
- `spring-boot-starter-security`
- `org.projectlombok:lombok`
- `spring-boot-starter-test` (test scope)

**Exclude (skillpanel-specific):**
- Spring Cloud OpenFeign, LoadBalancer, Kubernetes (replaced by RestClient)
- `com.devskiller:toolkit` (not available)
- `feign-okhttp`, `feign-micrometer` (not needed without Feign)
- `logstash-logback-encoder`, `dd-trace-api` (not in scope)
- `caffeine` (no caching needed for 3 simple tools)
- `spring-boot-starter-oauth2-resource-server` (trust-and-forward doesn't need it)

## Implementation Guidance

### Testing Approach

- 2-8 focused tests per implementation step group
- Context load test to verify application starts
- Schema validation tests for each tool: validate that output schemas match actual tool response structure (JSON Schema Draft 7 pattern from skillpanel-mcp)
- Test verification runs only new tests, not entire suite

### Standards Compliance

- **Coding Style** (`standards/global/coding-style.md`): Consistent naming, descriptive names, focused functions
- **Minimal Implementation** (`standards/global/minimal-implementation.md`): Only build what is needed -- 3 tools, no speculative methods
- **Error Handling** (`standards/global/error-handling.md`): McpToolException with clear LLM-friendly messages, fail-fast validation
- **API Design** (`standards/backend/api.md`): RESTful principles for the RestClient interface
- **Security** (`standards/backend/security.md`): JWT authentication pattern (simplified for trust-and-forward)
- **Commenting** (`standards/global/commenting.md`): Let code speak, comment only non-obvious logic (e.g., why trust-and-forward)
- **Conventions** (`standards/global/conventions.md`): Predictable file structure, environment variables for config

## Out of Scope

- Single product retrieval (`aj_get_product`), update, delete tools
- Complex query parameters (category filter, sort, pluginFilter) for product listing
- JWT token validation in the MCP server
- Kubernetes deployment, service discovery
- Structured logging (logstash), tracing (Datadog)
- Caching
- WellKnownController / OAuth protected resource metadata endpoint
- Docker Compose updates
- MCP resources (only tools)
- MCP prompts

## Success Criteria

1. MCP server starts on port 8081 and accepts MCP protocol messages at "/"
2. `aj_list_products` returns product list from backend when called with valid JWT
3. `aj_add_product` creates a product via backend and returns the created product
4. `aj_list_categories` returns category list from backend
5. All three tools return LLM-friendly error messages when backend returns errors or token is missing/invalid
6. JWT token is correctly forwarded from MCP request to backend API calls
7. Schema validation tests pass for all three tools
