# Implementation Plan: Build MCP Server

## Overview
Total Steps: 22
Task Groups: 4
Expected Tests: 16-26

## Spec Audit Resolutions

Decisions for audit findings to apply during implementation:

| Finding | Resolution |
|---------|-----------|
| F1: @EnableWebMvc | Include it -- skillpanel-mcp uses it and the MCP SDK's RouterFunction bean requires it. If Spring Boot 4.0.5 auto-configures it, the annotation is harmless. |
| F2: AccessTokenHolder | Use ThreadLocal with cleanup in a try/finally in the filter. Not @RequestScope -- ThreadLocal is simpler, has no proxy overhead, and matches the package structure annotation in the spec. |
| F3: Search param forwarding | RestClient method sends only `search` param. Other params (`category`, `sort`, `pluginFilter`) are not declared in the @HttpExchange interface. |
| F4: Management port | Use 9081 (sequential from 8081, avoids conflict with skillpanel-mcp's 9080). |
| F6: MCP SDK compatibility | Start with mcp-spring-webmvc 0.16.0. If incompatible with Spring Boot 4.0.5, try latest available version. If no compatible version exists, downgrade to Spring Boot 3.5.7 for this module only. |
| F7: Spring Security 7 | Follow aj's SecurityConfiguration pattern (addFilterBefore with UsernamePasswordAuthenticationFilter, SessionCreationPolicy.STATELESS, csrf disable). |
| F8: Price type | Use `"type": "number"` in JSON Schema, `BigDecimal` in Java DTO. `categoryId` as `"type": "integer"`. |
| F9: Error mapping | Map RestClientResponseException subclasses: 400->validationError, 401->apiError("Authentication required"), 403->apiError("Insufficient permissions"), 404->notFound, 5xx->apiError with retry suggestion. |

## Implementation Steps

### Task Group 1: Project Bootstrap & Configuration
**Dependencies:** None
**Estimated Steps:** 6

- [x] 1.0 Complete project bootstrap and configuration layer
  - [x] 1.1 Write 3 tests for project bootstrap (5 test methods across 3 classes)
  - [x] 1.2 Create `mcp-server/pom.xml` (Spring Boot 3.5.7 — SDK incompatible with 4.0.5)
  - [x] 1.3 Create `AjMcpApplication.java` with MCP transport beans
  - [x] 1.4 Create `application.yml` (ports 8081/9081, MCP config, backend URL)
  - [x] 1.5 Create `JacksonConfig.java` in config/
  - [x] 1.6 Create `LoggingJsonSchemaValidator.java` in config/
  - [x] 1.n All 5 bootstrap tests pass

**Acceptance Criteria:**
- Application context loads successfully
- Server runs on port 8081, management on 9081
- ObjectMapper configured with JavaTimeModule and ISO dates
- MCP transport and router beans created

---

### Task Group 2: Security & RestClient Layer
**Dependencies:** Group 1
**Estimated Steps:** 6

- [x] 2.0 Complete security and RestClient integration layer
  - [x] 2.1 Write 4 tests for security and RestClient
  - [x] 2.2 Create AccessTokenHolder with ThreadLocal
  - [x] 2.3 Create McpJwtFilter (trust-and-forward)
  - [x] 2.4 Create SecurityConfig (STATELESS, csrf disabled)
  - [x] 2.5 Create RestClientConfig with JWT interceptor and error handler
  - [x] 2.6 Create AjApiClient interface + DTO records + McpToolException
  - [x] 2.n All 4 Group 2 tests pass (9 total, no regressions)

**Acceptance Criteria:**
- JWT filter extracts and stores Bearer token in ThreadLocal
- ThreadLocal cleaned up after every request (no leaks)
- SecurityFilterChain requires auth on all endpoints except health/error
- RestClient forwards JWT to backend via interceptor
- AjApiClient interface matches backend API contracts

---

### Task Group 3: Tool Services & DTOs
**Dependencies:** Group 2
**Estimated Steps:** 7

- [x] 3.0 Complete tool services, DTOs, and exception handling
  - [x] 3.1 Write 6 tests for tools (spec validation + schema validation)
  - [x] 3.2 Verify/update DTOs to match backend (Long IDs, BigDecimal price, @JsonInclude)
  - [x] 3.3 Verify McpToolException; added invalidCriteria() factory
  - [x] 3.4 Create ProductService with buildToolListProducts, buildToolAddProduct
  - [x] 3.5 Create CategoryService with buildToolListCategories
  - [x] 3.6 Wire all 3 tools into McpStatelessSyncServer in AjMcpApplication
  - [x] 3.n All 6 Group 3 tests pass (15 total, no regressions)

**Acceptance Criteria:**
- All 3 tool specifications build without errors
- JSON schemas match actual DTO structures
- McpToolException provides LLM-friendly error messages
- DTOs mirror backend API contracts exactly
- Tools registered in McpStatelessSyncServer

---

### Task Group 4: Test Review & Gap Analysis
**Dependencies:** Groups 1, 2, 3
**Estimated Steps:** 3

- [x] 4.0 Review and fill critical test gaps
  - [x] 4.1 Reviewed all 15 existing tests across 7 test files
  - [x] 4.2 Analyzed gaps: error mapping, tool call handlers, unexpected exception wrapping
  - [x] 4.3 Wrote 10 additional tests (ErrorMappingTests: 5, ToolCallIntegrationTests: 5)
  - [x] 4.n All 25 tests pass (no regressions)

**Acceptance Criteria:**
- All feature tests pass (18-21 total)
- No more than 8 additional tests added
- Security, error handling, and tool call paths covered
- No gaps in critical paths (auth, error mapping, tool execution)

---

## Execution Order

1. Group 1: Project Bootstrap & Configuration (6 steps, no dependencies)
2. Group 2: Security & RestClient Layer (6 steps, depends on 1)
3. Group 3: Tool Services & DTOs (7 steps, depends on 2)
4. Group 4: Test Review & Gap Analysis (3 steps, depends on 1, 2, 3)

## Standards Compliance

Follow standards from `.maister/docs/standards/`:

- **global/coding-style.md**: Consistent naming (aj_ prefix for tools, PascalCase services, camelCase methods)
- **global/minimal-implementation.md**: Only 3 tools, no speculative methods, no unused endpoints
- **global/error-handling.md**: McpToolException with LLM-friendly messages, fail-fast validation
- **global/commenting.md**: Comment only non-obvious logic (e.g., why trust-and-forward, ThreadLocal cleanup rationale)
- **global/conventions.md**: Predictable package structure mirroring spec, environment variables for backend URL
- **backend/api.md**: RESTful principles for RestClient @HttpExchange interface
- **backend/security.md**: JWT pattern adapted for trust-and-forward (simplified, no validation)
- **testing/backend-testing.md**: Integration-first testing, *Tests suffix, package-private test classes

## Notes

- **Test-Driven**: Each group starts with tests before implementation
- **Run Incrementally**: Only new tests after each group, not entire suite
- **Mark Progress**: Check off steps as completed
- **Reuse First**: McpToolException, JacksonConfig, LoggingJsonSchemaValidator ported from skillpanel-mcp
- **Jackson 2.x vs 3.x**: Spring Boot 4.0.5 may ship Jackson 3.x (tools.jackson). MCP SDK 0.16.0 uses Jackson 2.x (com.fasterxml.jackson). If both are on classpath, create a dedicated Jackson 2.x ObjectMapper bean for MCP components. This is the highest implementation risk after SDK compatibility.
- **SDK Compatibility Fallback**: If mcp-spring-webmvc is incompatible with Spring Boot 4.0.5, downgrade to Spring Boot 3.5.7 for the mcp-server module only. This is acceptable since it is a standalone project with its own pom.xml.
