# Work Log

## 2026-04-04 - Implementation Started

**Total Steps**: 22
**Task Groups**: Group 1 (Bootstrap), Group 2 (Security & RestClient), Group 3 (Tools & DTOs), Group 4 (Test Review)

## 2026-04-04 - Group 1 Complete

**Steps**: 1.1 through 1.n completed (all 7 steps)
**Standards Applied**:
- From plan: coding-style.md, minimal-implementation.md, commenting.md, conventions.md
- From INDEX.md: testing/backend-testing.md (test naming, *Tests suffix)
- Discovered: none
**Tests**: 5 passed (3 test classes)
**Files Created**: 8 (pom.xml, AjMcpApplication.java, application.yml, JacksonConfig.java, LoggingJsonSchemaValidator.java, 3 test files)
**Notes**: Spring Boot downgraded to 3.5.7 — MCP SDK 0.16.0 (and up to 0.18.1) requires Spring Framework 6.x / Jackson 2.x, incompatible with Spring Boot 4.0.5.

## 2026-04-04 - Group 2 Complete

**Steps**: 2.1 through 2.n completed (all 7 steps)
**Standards Applied**:
- From plan: backend/security.md, global/error-handling.md, testing/backend-testing.md
- From INDEX.md: global/coding-style.md, global/minimal-implementation.md
- Discovered: none
**Tests**: 4 new (9 total, no regressions)
**Files Created**: 12 (AccessTokenHolder, McpJwtFilter, SecurityConfig, RestClientConfig, AjApiClient, 3 DTOs, McpToolException, 3 test files)
**Notes**: McpToolException created early (needed by RestClientConfig error handler). DTOs created as simple records. Spring Security 6.x APIs used (matching Boot 3.5.7).

## Standards Reading Log

### Group 1: Project Bootstrap & Configuration
**From Implementation Plan**:
- [x] .maister/docs/standards/global/coding-style.md
- [x] .maister/docs/standards/global/minimal-implementation.md
- [x] .maister/docs/standards/global/commenting.md
- [x] .maister/docs/standards/global/conventions.md

**From INDEX.md**:
- [x] .maister/docs/standards/testing/backend-testing.md - test naming conventions

**Discovered During Execution**:
- (none)

## 2026-04-04 - Group 3 Complete

**Steps**: 3.1 through 3.n completed (all 7 steps)
**Standards Applied**:
- From plan: coding-style.md, minimal-implementation.md, error-handling.md, backend/api.md, testing/backend-testing.md
- From INDEX.md: none additional
- Discovered: JacksonConfig interaction with schema validation tests (timestamp serialization)
**Tests**: 6 new (15 total, no regressions)
**Files Created/Modified**: 8 (ProductService, CategoryService, ToolSchemaValidationTests created; ProductResponse, CreateProductRequest, CategoryResponse, McpToolException, AjMcpApplication modified)
**Notes**: DTOs updated to match actual backend shapes (Long IDs, BigDecimal prices). McpToolException got invalidCriteria() factory.

### Group 2: Security & RestClient Layer
**From Implementation Plan**:
- [x] .maister/docs/standards/backend/security.md
- [x] .maister/docs/standards/global/error-handling.md
- [x] .maister/docs/standards/testing/backend-testing.md

**From INDEX.md**:
- [x] .maister/docs/standards/global/coding-style.md
- [x] .maister/docs/standards/global/minimal-implementation.md

**Discovered During Execution**:
- (none)

## 2026-04-04 - Group 4 Complete

**Steps**: 4.1 through 4.n completed (all 4 steps)
**Standards Applied**:
- From plan: testing/backend-testing.md, global/error-handling.md
- From INDEX.md: global/minimal-implementation.md
- Discovered: none
**Tests**: 10 new (25 total, no regressions)
**Files Created**: 2 (ErrorMappingTests.java, ToolCallIntegrationTests.java)
**Notes**: Exceeded plan estimate of 8 tests with 10 for better error mapping and tool handler coverage. Security integration at HTTP level deferred (requires MCP protocol JSON-RPC payloads).

## 2026-04-04 - Implementation Complete

**Total Steps**: 22 completed
**Total Standards**: 8 applied across 4 groups
**Test Suite**: 25 tests, all passing
**Groups**: 4/4 completed

### Group 3: Tool Services & DTOs
**From Implementation Plan**:
- [x] .maister/docs/standards/global/coding-style.md - aj_ prefix, naming
- [x] .maister/docs/standards/global/minimal-implementation.md - 3 tools only
- [x] .maister/docs/standards/global/error-handling.md - McpToolException
- [x] .maister/docs/standards/backend/api.md - RESTful interface
- [x] .maister/docs/standards/testing/backend-testing.md - test conventions

**From INDEX.md**:
- (none additional)

**Discovered During Execution**:
- JacksonConfig (WRITE_DATES_AS_TIMESTAMPS=false) affects schema validation tests
