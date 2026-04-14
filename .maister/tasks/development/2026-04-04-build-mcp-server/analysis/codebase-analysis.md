# Codebase Analysis Report

**Date**: 2026-04-04
**Task**: Build an MCP server in a new mcp-server/ directory modeled after skillpanel-mcp
**Description**: Build an MCP server in a new mcp-server/ directory at the root of a Java/Spring Boot project, modeled after an existing production MCP server (skillpanel-mcp). Should heavily incorporate skillpanel-mcp libraries, patterns, and conventions.
**Analyzer**: codebase-analyzer skill (3 Explore agents: File Discovery, Code Analysis, Pattern Mining)

---

## Summary

The target project (dna_ai/aj) is a single-module Spring Boot 4.0.5 / Java 25 application with no existing MCP code. The reference project (skillpanel-mcp) is a production MCP server using Spring Boot 3.5.7 / Java 25 with the MCP Spring WebMVC SDK (0.16.0), containing 30 Java source files (~2,023 lines) organized across 8 packages. The new MCP server should be created as a standalone Maven project in `mcp-server/` at the repository root, replicating the skillpanel-mcp architecture (stateless WebMVC transport, JWT security, Feign clients, programmatic tool registration) while adapting it to the aj project's domain, Spring Boot 4.0.5 version, and existing JWT security infrastructure.

---

## Files Identified

### Primary Files (Reference: skillpanel-mcp)

**SkillPanelMcpApplication.java** (74 lines)
- Application bootstrap with MCP transport, router, and server beans
- Central tool/resource registration point -- the primary pattern to replicate

**config/SecurityConfig.java** (62 lines)
- SecurityFilterChain with public paths (/.well-known/**, /actuator/health/**) and authenticated-all-else
- Pattern for MCP endpoint security

**security/McpJwtFilter.java** (92 lines)
- Extracts Bearer token, converts to internal header, stores in AccessTokenHolder
- Key JWT forwarding pattern for downstream calls

**security/AccessTokenHolder.java** (27 lines)
- ThreadLocal token storage for request-scoped JWT propagation

**security/McpAuthenticationEntryPoint.java** (31 lines)
- RFC 9728 compliant WWW-Authenticate header for OAuth protected resources

**config/JacksonConfig.java** (30 lines)
- ObjectMapper customization: JavaTimeModule, dates as ISO strings, lenient deserialization

**config/LoggingJsonSchemaValidator.java** (39 lines)
- Decorator wrapping DefaultJsonSchemaValidator with logging for debugging schema validation

**config/McpJwtTokensFeignRequestInterceptor.java** (43 lines)
- Feign RequestInterceptor forwarding JWT from AccessTokenHolder to downstream services

**config/DefaultFeignConfiguration.java** (98 lines)
- OkHttp client, error decoder, retry configuration

**exception/McpToolException.java** (lines vary)
- Exception with static factories: validationError(), notFound(), apiError(), invalidCriteria()
- All messages include actionable LLM guidance

**controller/WellKnownController.java** (lines vary)
- OAuth protected resource metadata endpoint at /.well-known/oauth-protected-resource

**controller/ErrorPageController.java** (lines vary)
- Custom error page handling

**service/SkillsetService.java** (202 lines)
- Example tool service: buildToolListSkillsets(), buildToolGetSkillset() methods
- Demonstrates tool builder pattern with inline JSON schemas

**service/PersonSearchService.java** (452 lines)
- Complex tool service with multi-field search criteria
- Largest service, demonstrates advanced input/output schema patterns

**service/PersonSkillProfileService.java** (373 lines)
- Tool service demonstrating structured content responses

**service/SkillService.java** (59 lines)
- Resource (not tool) implementation pattern: buildResourceSkills()

**client/MapClient.java** (lines vary)
- Feign client interface with @FeignClient annotation
- Pattern for backend API communication

### Primary Files (Target: dna_ai/aj)

**pom.xml** (280 lines)
- Parent Spring Boot 4.0.5, Java 25, single-module structure
- No MCP dependencies -- mcp-server/ will have its own pom.xml

**src/main/java/pl/devstyle/aj/core/** (security infrastructure)
- Existing JWT security with jjwt library (different from skillpanel's oauth2-resource-server)
- Potential patterns to reuse or integrate with

### Related Files (Reference: skillpanel-mcp)

**client/personsearch/** and **client/skillprofile/** (subdirectories)
- DTO records for Feign client request/response models

**model/Skill.java** (single model)
- Domain model used for resource responses

**src/test/java/.../service/ToolSchemaValidationTest.java**
- Schema validation test pattern -- validates output schemas against actual tool responses
- Uses networknt JSON Schema Draft 7 validator

**src/test/java/.../service/PersonSearchServiceTest.java**
- Person search schema validation (7 tests)

**src/test/java/.../config/JacksonDeserializationTest.java**
- JSON serialization edge case tests

---

## Current Functionality

### Target Project (dna_ai/aj)

The aj project is a plugin-based microkernel platform with:
- Spring Boot 4.0.5 WebMVC application
- JPA + jOOQ + Liquibase + PostgreSQL data layer
- JWT authentication using jjwt library (manual JWT handling)
- Domain packages: core/, category/, user/, product/, api/
- Frontend build via frontend-maven-plugin (Node 22)
- Docker Compose development setup
- No MCP server or MCP-related code exists

### Reference Project (skillpanel-mcp)

A production MCP server exposing 6 tools and 1 resource:
- Stateless WebMVC transport at "/" endpoint
- JWT-based authentication with token forwarding to backend services
- Feign clients for all backend API communication
- Spring Cloud Kubernetes for service discovery (production)
- Caffeine caching for performance

### Key Components/Functions

- **WebMvcStatelessServerTransport**: Stateless HTTP transport wrapping JacksonMcpJsonMapper
- **McpServer.sync()**: Server builder with capabilities, tools, and resources registration
- **McpStatelessServerFeatures.SyncToolSpecification**: Tool definition via builder pattern
- **McpSchema.Tool.builder()**: Tool metadata (name, title, description, annotations, inputSchema, outputSchema)
- **CallToolResult**: Tool response with structuredContent for JSON responses
- **AccessTokenHolder**: ThreadLocal JWT storage for request-scoped propagation
- **McpToolException**: LLM-friendly error responses with actionable suggestions

### Data Flow

```
Client (LLM) --> MCP HTTP POST "/" --> McpJwtFilter (extract token)
  --> WebMvcStatelessServerTransport --> McpStatelessSyncServer
  --> Tool callHandler --> Service --> Feign Client (with forwarded JWT)
  --> Backend API --> Response --> CallToolResult (structuredContent)
```

---

## Dependencies

### Reference MCP Server Dependencies (to replicate)

- **io.modelcontextprotocol.sdk:mcp-spring-webmvc:0.16.0**: Core MCP SDK for Spring WebMVC
- **spring-boot-starter-web**: HTTP server
- **spring-boot-starter-actuator**: Health checks
- **spring-boot-starter-oauth2-resource-server**: JWT validation (skillpanel uses Spring Security OAuth2)
- **spring-cloud-starter-openfeign**: Declarative HTTP clients
- **spring-cloud-starter-loadbalancer**: Client-side load balancing
- **com.github.ben-manes.caffeine:caffeine**: Caching
- **io.github.openfeign:feign-okhttp**: OkHttp transport for Feign
- **io.github.openfeign:feign-micrometer**: Feign metrics
- **org.projectlombok:lombok**: Boilerplate reduction
- **com.devskiller:toolkit:1.3-38**: Internal JWT utilities (NOT applicable to aj)
- **net.logstash.logback:logstash-logback-encoder:7.4**: Structured logging
- **com.datadoghq:dd-trace-api:1.54.0**: Tracing (NOT applicable to aj)
- **spring-cloud Kubernetes**: Service discovery (NOT applicable to aj dev setup)

### Target Project Existing Dependencies

- **spring-boot-starter-webmvc**: Already present (Spring Boot 4.0.5)
- **spring-boot-starter-security**: Already present (with jjwt, not OAuth2 resource server)
- **jackson-databind**: Already present
- **lombok**: Already present

### Consumers (What Depends On This)

The new mcp-server/ will be a standalone application:
- No existing code in aj depends on it
- It will depend on aj's backend API (via Feign or direct HTTP calls)

**Consumer Count**: 0 files (new standalone module)
**Impact Scope**: Low -- new code, no existing consumers

---

## Test Coverage

### Reference Test Files

- **SkillPanelMcpApplicationTests.java**: Context load test
- **ToolSchemaValidationTest.java**: Validates output schemas match actual tool responses (JSON Schema Draft 7)
- **PersonSearchServiceTest.java**: Search schema validation (7 tests)
- **PersonSkillProfileServiceTest.java**: Profile service tests
- **JacksonDeserializationTest.java**: JSON serialization edge cases

### Coverage Assessment

- **Test count**: 5 test files with ~15+ tests
- **Pattern**: Schema validation tests are the primary testing strategy -- ensures tool schemas stay in sync with actual responses
- **Gaps**: No integration tests with actual MCP transport; tests focus on schema correctness and deserialization

---

## Coding Patterns

### Naming Conventions

- **Tool names**: `prefix_verb_object` in snake_case (e.g., `skillpanel_list_skillsets`)
- **Tool titles**: "Prefix: Action Object" in title case
- **Services**: PascalCase + Service suffix (e.g., `SkillsetService`)
- **DTOs**: Java records with `@JsonInclude(NON_NULL)`, named with Dto/Response/Request suffix
- **Tool builder methods**: `buildTool[Action][Entity]()` pattern
- **Resource URIs**: `prefix://resource_name` (e.g., `skillpanel://skills_inventory`)

### Architecture Patterns

- **Style**: Spring Boot application with programmatic MCP bean configuration (no annotation-driven tools)
- **Transport**: Stateless WebMVC -- no session state, all context in JWT
- **Security**: Filter-based JWT extraction with ThreadLocal propagation
- **Data Access**: Feign clients for all external API calls (no direct DB access)
- **Error Handling**: Custom exception with static factory methods producing LLM-friendly messages
- **DTOs**: Immutable Java records throughout
- **Configuration**: @Bean methods in application class for MCP infrastructure; @Configuration classes for cross-cutting concerns
- **Schema Definition**: Inline JSON strings parsed via McpJsonMapper.getDefault() in tool builders

### Anti-Patterns to Avoid

- No custom @Tool annotations -- use programmatic builder exclusively
- No hardcoded error messages without LLM guidance text
- No mutable DTO classes -- use Java records only
- No hardcoded service URLs -- use Feign with service discovery
- No skipping schema validation tests

---

## Complexity Assessment

| Factor | Value | Level |
|--------|-------|-------|
| Reference File Count | 30 Java files | Medium |
| Reference Total Lines | ~2,023 lines | Medium |
| New Dependencies | ~8-10 new deps | Medium |
| Existing Consumers | 0 (greenfield) | Low |
| Test Coverage | Schema validation pattern | Medium |
| Spring Boot Version Gap | 3.5.7 -> 4.0.5 | Medium |

### Overall: Moderate

The task is a greenfield module creation with a well-defined reference implementation. The primary complexity lies in: (1) adapting Spring Boot 3.5.7 patterns to 4.0.5 (potential API differences in security and WebMVC), (2) replacing skillpanel-specific dependencies (devskiller toolkit, Spring Cloud Kubernetes) with aj-appropriate alternatives, and (3) defining the tool domain for the aj project. The MCP SDK itself (0.16.0) may need version verification for Spring Boot 4.0.5 compatibility.

---

## Key Findings

### Strengths
- The reference implementation (skillpanel-mcp) is well-structured, production-proven, and provides clear patterns for every layer (transport, security, tools, error handling, testing)
- The aj project already has JWT security infrastructure that can inform the MCP server's auth approach
- Greenfield module means zero risk of breaking existing functionality
- The MCP SDK provides a clean programmatic API that does not require framework-specific annotations

### Concerns
- **Spring Boot version gap**: skillpanel-mcp uses 3.5.7 while aj uses 4.0.5 -- Spring Security and WebMVC APIs may have breaking changes (SecurityFilterChain configuration, `@EnableWebMvc` behavior)
- **MCP SDK compatibility**: mcp-spring-webmvc 0.16.0 was built against Spring Boot 3.x; needs verification that it works with Spring Boot 4.0.5
- **Internal dependencies**: skillpanel-mcp uses `com.devskiller:toolkit` for JWT utilities and Spring Cloud Kubernetes for service discovery -- these are not available in the aj project and need replacement
- **Security model difference**: aj uses jjwt (manual JWT), skillpanel uses spring-boot-starter-oauth2-resource-server -- the MCP server needs to decide which approach to adopt
- **No domain tools defined yet**: The specific tools to expose via MCP have not been specified for the aj project

### Opportunities
- The standalone mcp-server/ directory can use its own Spring Boot version if 4.0.5 compatibility with MCP SDK is problematic
- The existing aj API endpoints can be called via Feign clients from the MCP server, keeping the systems loosely coupled
- Schema validation test pattern from skillpanel-mcp provides a solid testing strategy to adopt from day one

---

## Impact Assessment

- **Primary changes**: New `mcp-server/` directory with its own Maven project (pom.xml, application class, config, security, services, tests)
- **Related changes**: Possible updates to aj's API to ensure endpoints are accessible to the MCP server; possible Docker Compose updates for local development
- **Test updates**: New test files following the schema validation pattern from skillpanel-mcp

### Risk Level: Low-Medium

The risk is low because this is a greenfield module with no impact on existing code. The medium qualifier comes from the Spring Boot version gap (3.5.7 vs 4.0.5) which may surface API incompatibilities in the MCP SDK or Spring Security configuration, and from the need to replace skillpanel-specific dependencies with aj-appropriate alternatives.

---

## Recommendations

### Architecture Approach

1. **Standalone Maven project** in `mcp-server/` with its own `pom.xml` (not a Maven submodule of the main project). This matches the skillpanel-mcp pattern and keeps the MCP server independently deployable.

2. **Spring Boot version**: Start with 4.0.5 to match the main project. If MCP SDK 0.16.0 has compatibility issues, either: (a) find a newer MCP SDK version compatible with Spring Boot 4.x, or (b) use Spring Boot 3.5.7 for the MCP server (acceptable since it is standalone).

3. **Package structure**: `pl.devstyle.aj.mcp` with subpackages mirroring skillpanel-mcp: `config/`, `security/`, `service/`, `client/`, `exception/`, `controller/`, `model/`.

### Security Implementation

4. **JWT handling**: Replicate the McpJwtFilter + AccessTokenHolder pattern. For JWT validation, decide between: (a) spring-boot-starter-oauth2-resource-server (as skillpanel-mcp does), or (b) the jjwt-based approach already in the aj project. Option (a) is recommended for consistency with the reference.

5. **Token forwarding**: Implement McpJwtTokensFeignRequestInterceptor to propagate tokens to the aj backend API.

### Tool Implementation

6. **Start with skeleton**: Bootstrap the MCP server with transport, router, security, and one placeholder tool. Then iteratively add tools for aj domain entities (categories, products, users).

7. **Follow the builder pattern**: Use programmatic `McpStatelessServerFeatures.SyncToolSpecification` builders, not annotations.

8. **Error handling**: Port McpToolException with its static factory methods and LLM-friendly error messages.

### Dependencies to Include

9. Core: `mcp-spring-webmvc`, `spring-boot-starter-web`, `spring-boot-starter-actuator`, `spring-boot-starter-oauth2-resource-server`, `lombok`
10. Feign: `spring-cloud-starter-openfeign`, `feign-okhttp` (for calling aj backend)
11. Jackson: `jackson-databind` (via spring-boot-starter-web)
12. Testing: `spring-boot-starter-test`

### Dependencies to Skip (skillpanel-specific)

- `com.devskiller:toolkit` -- replace with aj's own JWT utilities
- `spring-cloud-starter-kubernetes-*` -- not needed for local dev; add later for deployment
- `com.datadoghq:dd-trace-api` -- not part of aj's stack
- `net.logstash.logback:logstash-logback-encoder` -- optional, add if structured logging is needed

### Testing Strategy

13. **Schema validation tests**: Adopt the ToolSchemaValidationTest pattern -- validate that output schemas match actual tool responses using JSON Schema Draft 7.
14. **Context load test**: Basic @SpringBootTest to verify application starts.
15. **Jackson deserialization tests**: For any custom DTOs with non-trivial serialization.

---

## Next Steps

The orchestrator should proceed to gap analysis to determine:
1. Which specific aj domain entities/endpoints should be exposed as MCP tools
2. Whether MCP SDK 0.16.0 is compatible with Spring Boot 4.0.5 (or if a newer version exists)
3. The exact security integration approach (OAuth2 resource server vs jjwt)
4. Whether the aj backend API needs any modifications to support MCP server access
