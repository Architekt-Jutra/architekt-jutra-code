# Requirements

## Initial Description
Build an MCP server in the mcp-server/ directory at the project root. Not part of the main app itself. Heavily incorporate skillpanel-mcp project patterns, libraries, and conventions.

## Q&A Summary

### Phase 1 Clarifications
- **Scope**: Skeleton infrastructure + product listing/adding tools
- **Spring Boot**: 4.0.5 (match main app)
- **Data access**: Originally Feign HTTP clients, changed to RestClient in Phase 2

### Phase 2 Scope Decisions
- **HTTP client**: RestClient + HttpServiceProxyFactory (Spring Boot 4.x native, replacing Feign)
- **Tool prefix**: aj_ (e.g., aj_list_products)
- **Port**: 8081
- **Scope expansion**: Added aj_list_categories tool (needed for product creation workflow)

### Phase 5 Technical Decisions
- **Authentication**: Trust-and-forward model. MCP server passes Bearer token to backend. Backend validates. No JWT secret sharing needed.
- **Tool parameters**: Simplified params only. Basic listing with optional search text. Keep it simple for LLM agents.

## Functional Requirements

### Infrastructure
1. Standalone Maven project in mcp-server/ directory at repository root
2. Spring Boot 4.0.5, Java 25
3. MCP SDK (mcp-spring-webmvc) for stateless WebMVC transport
4. RestClient for calling aj backend API at localhost:8080
5. Port 8081 for MCP server, separate management port
6. Trust-and-forward JWT authentication (extract Bearer token, forward to backend calls)

### MCP Tools
1. **aj_list_products** — List products with optional search text parameter
2. **aj_add_product** — Create a new product (name, description, photoUrl, price, sku, categoryId)
3. **aj_list_categories** — List all categories (needed for product creation workflow)

### Patterns to Follow (from skillpanel-mcp)
1. Programmatic tool registration via McpStatelessServerFeatures.SyncToolSpecification builder
2. McpToolException with static factory methods for LLM-friendly errors
3. Service classes with buildTool*() methods
4. JSON Schema for input/output definitions
5. LoggingJsonSchemaValidator for debugging
6. JacksonConfig with JavaTimeModule
7. Application class with transport → router → server bean pattern

## Similar Features Identified
- skillpanel-mcp SkillsetService (list + get pattern)
- skillpanel-mcp PersonSearchService (search with params pattern)
- skillpanel-mcp McpToolException (error handling)

## Scope Boundaries
- **In scope**: MCP server skeleton, 3 tools, RestClient, trust-and-forward auth, basic tests
- **Out of scope**: Kubernetes deployment, structured logging (logstash), Datadog tracing, Spring Cloud dependencies, OAuth2 resource server, complex filtering

## Reusability Opportunities
- McpToolException pattern can be copied nearly verbatim
- JacksonConfig can be reused
- LoggingJsonSchemaValidator can be reused
- Application bootstrap pattern (transport → router → server) can be adapted
