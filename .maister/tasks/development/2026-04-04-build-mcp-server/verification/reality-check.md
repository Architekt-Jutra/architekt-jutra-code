# Reality Check: Build MCP Server

**Date**: 2026-04-04
**Assessor**: reality-assessor (independent verification)
**Task**: Build standalone MCP server exposing aj backend product/category data to LLM agents

---

## Status: Issues Found

The implementation is functionally complete -- all 3 MCP tools are built, wired, and the codebase compiles and passes 25 tests. The architecture is sound, the code is lean, and the design decisions are reasonable. However, it cannot be verified as "actually working end-to-end" because no integration test exercises the real MCP protocol flow (HTTP POST with JSON-RPC payload -> tool execution -> structured response). The tests validate individual layers in isolation, which is a meaningful gap between "tests pass" and "actually works."

**Deployment decision: GO with mitigations** -- for a dev/staging environment. NO-GO for production without addressing RestClient timeouts and configuration externalization.

---

## 1. Reality vs Claims

### Claim: "25 tests pass, all 4 task groups complete"

**Reality: TRUE -- verified independently.**

Tests were executed via `../mvnw test` and all 25 passed in 4.4 seconds. BUILD SUCCESS confirmed. No flaky tests, no test infrastructure issues.

### Claim: "3 MCP tools built and registered"

**Reality: TRUE -- verified by code inspection and test evidence.**

- `aj_list_products` (ProductService): Tool spec builds, call handler invokes `AjApiClient.listProducts()`, returns `structuredContent` wrapping products in `{"products": [...]}`.
- `aj_add_product` (ProductService): Tool spec builds with required fields (name, price, sku, categoryId), call handler extracts arguments from Map, creates `CreateProductRequest`, invokes `AjApiClient.createProduct()`.
- `aj_list_categories` (CategoryService): Tool spec builds, call handler invokes `AjApiClient.listCategories()`, returns `structuredContent` wrapping categories in `{"categories": [...]}`.

All three are wired into `McpStatelessSyncServer` in `AjMcpApplication.java` via `.tools()`.

### Claim: "Trust-and-forward JWT authentication works"

**Reality: PARTIALLY TRUE -- the mechanism exists but has a security concern.**

The `McpJwtFilter` extracts Bearer tokens, stores them in `AccessTokenHolder` (ThreadLocal), and `RestClientConfig.JwtForwardingInterceptor` forwards them to the backend. The filter cleans up the ThreadLocal in a `finally` block.

However, the `SecurityContextHolder` is NOT cleared after request completion (code review finding CR-1). While Spring Security's own `SecurityContextHolderFilter` typically handles this, the code review correctly flags this as a security concern for thread pool reuse scenarios. This is a real issue, not a theoretical one.

### Claim: "Schema validation tests validate tool output matches JSON Schema"

**Reality: TRUE -- and the tests are well-designed.**

`ToolSchemaValidationTests` uses `networknt/json-schema-validator` with Draft 7 to validate that actual Java DTOs (serialized to JSON by the configured ObjectMapper with JavaTimeModule) pass schema validation against the tool output schemas. This catches mismatches between DTO shapes and declared schemas. Input schema validation for `aj_add_product` also verified.

### Claim: "Error handling maps backend HTTP errors to LLM-friendly McpToolException"

**Reality: TRUE for the RestClient layer, PARTIALLY TRUE for the MCP response layer.**

`RestClientConfig.defaultStatusHandler` correctly maps 400/401/403/404/5xx to appropriate `McpToolException` factory methods. Services catch `McpToolException` (re-throw) and unexpected exceptions (wrap as API error).

Verified via MCP SDK source: `DefaultMcpStatelessServerHandler.handleRequest()` catches ALL exceptions from tool handlers via `onErrorResume` and converts them to `JSONRPCResponse` with `INTERNAL_ERROR` code and the exception message. So `McpToolException` messages DO reach the LLM agent as JSON-RPC error messages. This works, though all errors get the same `INTERNAL_ERROR` code regardless of whether it was a validation error, not-found, or API error. The `ErrorType` enum in `McpToolException` is never used in the response -- only the message matters.

### Claim: "Application starts on port 8081 with management on 9081"

**Reality: TRUE -- verified by `ConfigurationTests` and `AjMcpApplicationTests` context load.**

`application.yml` configures `server.port: 8081` and `management.server.port: 9081`. Tests verify these values. The context loads successfully with mocked `AjApiClient`.

---

## 2. Critical Gaps

### Gap 1: No end-to-end MCP protocol test

**Claim**: Implementation is complete and tested.
**Reality**: No test sends an actual MCP JSON-RPC request (`{"jsonrpc": "2.0", "method": "tools/call", ...}`) over HTTP POST to the "/" endpoint and verifies the structured JSON-RPC response.
**Evidence**: All tests either test service methods directly (ToolCallIntegrationTests), validate schemas (ToolSchemaValidationTests), test error propagation (ErrorMappingTests), or verify configuration (ConfigurationTests, AjMcpApplicationTests). None exercise the MCP transport layer integration.
**Impact**: Medium. The MCP SDK wiring (transport -> router -> server -> tool handler -> response) is not tested. If there is a misconfiguration in the transport setup (e.g., JSON-RPC deserialization, schema validation rejecting valid input, content-type negotiation), it would not be caught. The individual layers work in isolation but the integration seam is untested.
**Severity**: Medium -- the wiring code in `AjMcpApplication` is straightforward and follows the reference implementation pattern. The risk is not high, but it means "the application context loads" is standing in for "the MCP protocol actually works," which is a weaker assertion.

### Gap 2: SecurityContext not cleared in McpJwtFilter

**Claim**: Security filter handles token lifecycle correctly.
**Reality**: `AccessTokenHolder.clear()` is called in the `finally` block, but `SecurityContextHolder.clearContext()` is not.
**Evidence**: `McpJwtFilter.java` lines 32-47 -- the `finally` block only calls `accessTokenHolder.clear()`.
**Impact**: In a thread-pooled servlet container, a subsequent unauthenticated request on the same thread could inherit a stale `SecurityContext` and be treated as authenticated.
**Severity**: High for production. Spring Security 6.x's `SecurityContextHolderFilter` should clear context at the end of the request lifecycle, providing a safety net. But relying on that implicit behavior when explicitly managing the SecurityContext in a custom filter is fragile.

---

## 3. Quality Gaps

### Gap 3: No RestClient timeout configuration

**Evidence**: `RestClientConfig.java` -- `RestClient.builder()` is called with no `requestFactory()` configuration. Default timeouts are effectively infinite.
**Impact**: If the aj backend becomes unresponsive, MCP server threads block indefinitely, leading to thread pool exhaustion.
**Severity**: High for production, Low for dev/staging.

### Gap 4: Hardcoded environment-specific URLs

**Evidence**: `application.yml` lines 22-25 contain `https://kuba-app.labs-skillpanel.com` and `https://kuba-mcp.labs-skillpanel.com`. No environment variable placeholders, no Spring profiles.
**Impact**: Cannot deploy to any environment other than Kuba's dev setup without overriding properties via command line.
**Severity**: Medium. Standard for dev phase, but must be addressed before any shared deployment.

### Gap 5: WellKnownController exists despite being out of scope

**Evidence**: Spec "Out of Scope" section explicitly lists "WellKnownController / OAuth protected resource metadata endpoint". Yet `WellKnownController.java` exists with 28 lines plus `McpAuthenticationEntryPoint.java` (25 lines) and corresponding SecurityConfig rules.
**Impact**: Low -- extra code that works and may actually be useful for MCP client authentication discovery (RFC 8414 pattern). But it represents scope creep.
**Severity**: Low. The code is clean and small. The `McpAuthenticationEntryPoint` returning `WWW-Authenticate: Bearer resource_metadata="..."` may be needed for MCP protocol compliance. Pragmatic verdict: keep it, update the spec.

### Gap 6: ErrorType enum in McpToolException is unused in responses

**Evidence**: `McpToolException` defines `ErrorType.VALIDATION`, `ErrorType.NOT_FOUND`, `ErrorType.API_ERROR`. Services set the type. But the MCP SDK's `DefaultMcpStatelessServerHandler` catches all exceptions generically with `INTERNAL_ERROR` code (line 48 of the handler source). The `ErrorType` never influences the JSON-RPC error code.
**Impact**: Low. The exception message still reaches the LLM agent, which is the primary communication channel. The `ErrorType` could be useful for future structured error responses if the MCP SDK evolves.
**Severity**: Low. Not a bug, just dead metadata.

---

## 4. Integration Assessment

### MCP SDK Integration

**Status**: Correct based on code inspection and reference implementation comparison.

- `WebMvcStatelessServerTransport` created with custom `JacksonMcpJsonMapper` and endpoint "/".
- `RouterFunction<ServerResponse>` bean exposed for Spring WebMVC integration.
- `McpStatelessSyncServer` wired with all 3 tool specs, JSON schema validator, and capabilities.
- `@EnableWebMvc` present (matching reference).

**Risk**: MCP SDK 0.16.0 with Spring Boot 3.5.7 -- this was the correct fallback decision since the SDK is incompatible with Spring Boot 4.0.5. Verified that Spring Boot was correctly downgraded.

### Backend API Client Integration

**Status**: Correct -- DTO shapes match backend exactly.

| MCP Server DTO | Backend DTO | Match |
|----------------|-------------|-------|
| `ProductResponse(Long id, String name, String description, String photoUrl, BigDecimal price, String sku, CategoryResponse category, Map pluginData, LocalDateTime createdAt, LocalDateTime updatedAt)` | Backend `ProductResponse` | Exact match |
| `CreateProductRequest(String name, String description, String photoUrl, BigDecimal price, String sku, Long categoryId)` | Backend `CreateProductRequest` (without validation annotations) | Exact match |
| `CategoryResponse(Long id, String name, String description, LocalDateTime createdAt, LocalDateTime updatedAt)` | Backend `CategoryResponse` | Exact match |

`AjApiClient` interface methods map correctly to `ProductController` and `CategoryController` endpoints:
- `GET /api/products` with optional `search` param (other params correctly omitted)
- `POST /api/products` with `CreateProductRequest` body
- `GET /api/categories` with no params

### JWT Forwarding Integration

**Status**: Correct design, untested end-to-end.

The `JwtForwardingInterceptor` reads from `AccessTokenHolder` and sets `Bearer` auth header. The filter stores tokens before the chain runs and cleans up after. The only concern is the SecurityContext leak noted in Gap 2.

---

## 5. Test Quality Assessment

### Strengths

- Schema validation tests are genuinely useful -- they catch DTO/schema mismatches that would silently break LLM tool usage.
- Error mapping tests cover McpToolException propagation and unexpected exception wrapping.
- Tool call handler tests verify the builder pattern produces working handlers.
- JwtFilter tests verify token extraction and cleanup.

### Weaknesses

- No MCP protocol-level integration test (the most significant gap).
- No test for the RestClient error handler (the `defaultStatusHandler` mapping 400/401/403/404/5xx to McpToolException). The `ErrorMappingTests` test error propagation at the service level by directly throwing McpToolException from the mocked client, but the RestClient error handler that creates those exceptions from HTTP responses is not tested.
- No negative security test (request without Bearer token should be rejected with 401).

### Test Coverage Reality

**Claimed**: 25 tests, all passing.
**Reality**: 25 tests pass. They cover service logic, schema validation, error propagation, JWT filter mechanics, and configuration. But the two most important integration seams (MCP protocol handling, RestClient error mapping) are not tested.

---

## 6. Functional Completeness

| Requirement | Status | Evidence |
|-------------|--------|----------|
| Standalone Maven project, Spring Boot | Complete | `pom.xml` with Spring Boot 3.5.7 (downgraded from 4.0.5 for SDK compatibility) |
| MCP SDK with WebMVC transport at "/" | Complete | `AjMcpApplication.java` beans, `application.yml` config |
| Trust-and-forward JWT auth | Complete with concern | `McpJwtFilter`, `AccessTokenHolder`, `JwtForwardingInterceptor` -- SecurityContext leak |
| RestClient with HttpServiceProxyFactory | Complete | `RestClientConfig`, `AjApiClient` @HttpExchange interface |
| Port 8081, management 9081 | Complete | `application.yml`, `ConfigurationTests` |
| aj_list_products tool | Complete | `ProductService.buildToolListProducts()` with input/output schemas |
| aj_add_product tool | Complete | `ProductService.buildToolAddProduct()` with required fields validation |
| aj_list_categories tool | Complete | `CategoryService.buildToolListCategories()` with output schema |
| LLM-friendly error handling | Complete | `McpToolException` + RestClient error handler + MCP SDK error conversion |
| Programmatic tool registration | Complete | `McpStatelessSyncServer` with `.tools()` builder |

**Functional Completeness: 95%** -- All specified features are implemented. The 5% gap is the SecurityContext cleanup issue and the absence of end-to-end verification.

---

## 7. Pragmatic Action Plan

### Must Do Before Production

| Action | Priority | Effort | Success Criteria |
|--------|----------|--------|------------------|
| Add `SecurityContextHolder.clearContext()` to McpJwtFilter finally block | Critical | 5 min | SecurityContext cleared on every request, concurrent request test passes |
| Add RestClient timeouts (5s connect, 30s read) | High | 15 min | Timeout exception thrown when backend is unresponsive after configured duration |
| Externalize URLs with env var placeholders (`${AJ_BACKEND_URL:http://localhost:8080}`) | High | 10 min | Application starts with env vars set, no hardcoded prod URLs |

### Should Do Before Production

| Action | Priority | Effort | Success Criteria |
|--------|----------|--------|------------------|
| Change LoggingJsonSchemaValidator to DEBUG level | Medium | 5 min | No INFO-level schema validation logs in normal operation |
| Add graceful shutdown config | Medium | 5 min | `server.shutdown: graceful` in application.yml |
| Set default logging to INFO | Medium | 2 min | `pl.devstyle: INFO` in application.yml |

### Consider Doing

| Action | Priority | Effort | Success Criteria |
|--------|----------|--------|------------------|
| Add one MCP protocol integration test | Low | 30 min | Test sends JSON-RPC request to "/" and verifies structured response |
| Add RestClient error handler test | Low | 20 min | Test verifies 400/401/403/404/5xx responses map to correct McpToolException types |
| Decide on WellKnownController (keep and update spec, or remove) | Low | 5 min | Spec and code aligned |

---

## 8. Deployment Decision

**GO for dev/staging** -- the implementation is functionally complete, architecturally sound, and appropriate for its scale. The codebase is lean (~700 LOC), follows the reference implementation patterns, and the core proxy logic is correct.

**NO-GO for production** without the Critical and High items from the action plan (SecurityContext cleanup, RestClient timeouts, URL externalization). These are straightforward fixes totaling ~30 minutes of work.

---

## Summary

The MCP server implementation genuinely solves the stated problem: it exposes 3 tools (list products, add product, list categories) to LLM agents via the MCP protocol, with JWT forwarding to the aj backend. The code is well-structured, the DTOs match the backend exactly, the error handling covers the important paths, and the test suite validates meaningful properties (schema correctness, error propagation, handler execution).

The main gap is the lack of end-to-end MCP protocol testing -- the tests prove the individual layers work but do not prove the assembled system handles a real MCP request. Given the simplicity of the wiring (standard MCP SDK pattern), this is an acceptable risk for initial deployment but should be addressed as the service matures.

The three items that need attention before production (SecurityContext cleanup, RestClient timeouts, URL externalization) are all low-effort fixes that do not require architectural changes.
