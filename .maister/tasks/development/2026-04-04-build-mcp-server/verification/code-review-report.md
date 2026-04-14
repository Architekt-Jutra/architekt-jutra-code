# Code Review Report

**Date**: 2026-04-04
**Path**: /Users/kuba/Projects/dna_ai/code/mcp-server/src/
**Scope**: all (quality, security, performance, best practices)
**Status**: Warning - Issues Found

## Summary
- **Critical**: 1 issue
- **Warnings**: 5 issues
- **Info**: 4 issues

---

## Critical Issues

### 1. SecurityContext not cleared after request (security leak)
- **Location**: `security/McpJwtFilter.java:32-47`
- **Category**: Security
- **Description**: The `McpJwtFilter` clears the `AccessTokenHolder` in the `finally` block but does NOT clear the `SecurityContextHolder`. After the filter chain completes, the `UsernamePasswordAuthenticationToken` set at line 38-39 persists on the thread. In a servlet container with thread pooling, the next request on the same thread may inherit a stale authentication context from a previous request.
- **Risk**: A subsequent unauthenticated request reusing the same thread could be treated as authenticated, bypassing security. While Spring Security's own `SecurityContextHolderFilter` may clear context in standard setups, relying on that implicit behavior in a custom filter is fragile -- especially since this filter runs `addFilterBefore(UsernamePasswordAuthenticationFilter)`.
- **Recommendation**: Add `SecurityContextHolder.clearContext()` in the `finally` block alongside `accessTokenHolder.clear()`.
- **Fixable**: true

---

## Warnings

### 1. Trust-and-forward JWT with no token structure validation
- **Location**: `security/McpJwtFilter.java:34-36`
- **Category**: Security
- **Description**: Any string after "Bearer " is accepted as a valid token. There is no minimal validation (e.g., checking the token is non-empty, has a reasonable length, or at least looks like a JWT with 3 dot-separated segments). Arbitrary strings, including empty tokens or malicious payloads, will be forwarded to the backend.
- **Risk**: A request with `Authorization: Bearer ` (empty token) will set `accessTokenHolder` to an empty string and authenticate the request as "mcp-user" in the SecurityContext. The backend may reject it, but the MCP server itself considers it authenticated.
- **Recommendation**: Add minimal token format validation (non-blank, reasonable length) before accepting the token and setting authentication.
- **Fixable**: true

### 2. Response body stream consumed without size limit in error handler
- **Location**: `config/RestClientConfig.java:36`
- **Category**: Performance / Security
- **Description**: `response.getBody().readAllBytes()` in the error status handler reads the entire response body into memory with no size limit. A misbehaving or compromised backend could return a very large error response body, causing OutOfMemoryError.
- **Recommendation**: Use `response.getBody().readNBytes(maxSize)` with a reasonable limit (e.g., 8KB) to cap error body consumption.
- **Fixable**: true

### 3. No RestClient timeout configuration
- **Location**: `config/RestClientConfig.java:28-48`
- **Category**: Performance
- **Description**: The `RestClient` is built without connect or read timeouts. If the backend becomes unresponsive, MCP server threads will block indefinitely waiting for a response.
- **Risk**: Under load or backend failure, all servlet threads could be exhausted, causing the MCP server to become completely unresponsive.
- **Recommendation**: Configure connect and read timeouts via `RestClient.builder().requestFactory(...)` with a `SimpleClientHttpRequestFactory` or `HttpComponentsClientHttpRequestFactory` that has timeouts set (e.g., 5s connect, 30s read).
- **Fixable**: true

### 4. LoggingJsonSchemaValidator logs at INFO level in production code
- **Location**: `config/LoggingJsonSchemaValidator.java:22-28`
- **Category**: Quality / Performance
- **Description**: The validator logs schema validation details at INFO level (`log.info("=== JSON Schema Validation Starting ===")`), and pretty-prints the full instance payload at INFO level (line 23-24). This runs on every MCP tool call. In production, this creates noisy logs and serialization overhead on every request.
- **Risk**: Performance overhead from pretty-printing JSON on every request. Potential data exposure in logs if tool arguments contain sensitive information.
- **Recommendation**: Change `log.info` to `log.debug` for the "starting" and "instance" messages. The schema is already at DEBUG. Consider removing the pretty-printing or making it TRACE-level.
- **Fixable**: true

### 5. Unsafe cast in addProduct argument extraction
- **Location**: `service/ProductService.java:38-46`
- **Category**: Quality
- **Description**: The `addProduct` method uses raw casts like `(String) arguments.get("name")` and `((Number) arguments.get("categoryId")).longValue()`. If the MCP client sends a wrong type (e.g., a number for `name`, or a string for `categoryId`), this throws a ClassCastException, which gets wrapped as a generic "Failed to add product" API error. The error message will not indicate which field had the wrong type.
- **Recommendation**: Add type checking or use ObjectMapper to deserialize the arguments map into `CreateProductRequest` directly, which would provide clearer error messages.
- **Fixable**: true

---

## Informational

### 1. Hardcoded "mcp-user" principal with no identity propagation
- **Location**: `security/McpJwtFilter.java:38-39`
- **Category**: Best Practices
- **Description**: All authenticated requests get the same principal "mcp-user" with empty authorities. No information from the JWT (such as subject or permissions) is extracted. This is acceptable for the trust-and-forward model but means the MCP server itself has no visibility into who is making the request, limiting audit/logging capability.
- **Suggestion**: Consider extracting the JWT subject (even without full validation -- just Base64-decode the payload) to use as the principal for logging purposes.

### 2. Hardcoded URLs in application.yml
- **Location**: `resources/application.yml:22-25`
- **Category**: Best Practices
- **Description**: The OAuth server URL (`https://kuba-app.labs-skillpanel.com`) and MCP base URL (`https://kuba-mcp.labs-skillpanel.com`) are hardcoded. These are developer-specific values that should be externalized for different environments.
- **Suggestion**: These should be overridden by environment variables or Spring profiles for staging/production. They serve as reasonable development defaults, but ensure CI/CD and deployment pipelines provide appropriate overrides.

### 3. Duplicate JSON schema definitions across tool specifications
- **Location**: `service/ProductService.java:81-159` and `service/ProductService.java:206-275`
- **Category**: Quality
- **Description**: The category and product output schemas are duplicated across `buildToolListProducts()`, `buildToolAddProduct()`, and `buildToolListCategories()`. The category schema object (`id`, `name`, `description`, `createdAt`, `updatedAt`) appears three times across the two service files.
- **Suggestion**: Extract shared schema fragments into constants or a helper class to reduce duplication and ensure consistency when schemas evolve.

### 4. No pagination support for list endpoints
- **Location**: `client/AjApiClient.java:17-18`, `service/ProductService.java:25-27`
- **Category**: Performance
- **Description**: `listProducts` and `listCategories` return unbounded lists. If the backend has thousands of products, all of them will be serialized and returned in a single MCP response.
- **Suggestion**: Consider adding pagination parameters or documenting that the backend is expected to handle reasonable result set sizes. For an early-stage project, this is acceptable but worth tracking.

---

## Metrics
- Files analyzed: 18 (production) + 7 (test)
- Max function length: ~115 lines (`buildToolAddProduct()` in ProductService.java -- mostly JSON schema literals)
- Max nesting depth: 2 levels (within normal range)
- Potential vulnerabilities: 2 (SecurityContext leak, no token validation)
- N+1 query risks: 0 (no database layer)
- Test count: 25 tests across 7 test classes

---

## Prioritized Recommendations

1. **Clear SecurityContextHolder in McpJwtFilter finally block** -- Prevents potential authentication leakage across pooled threads. One-line fix.
2. **Add RestClient timeouts** -- Prevents thread exhaustion under backend failure. Essential for production resilience.
3. **Add minimal Bearer token validation** -- Reject obviously invalid tokens (empty, excessively long) before forwarding.
4. **Cap error response body size** -- Prevent OOM from unbounded `readAllBytes()` in error handler.
5. **Demote LoggingJsonSchemaValidator log levels** -- Reduce log noise and avoid serialization overhead in production.
6. **Improve type safety in addProduct argument extraction** -- Use ObjectMapper deserialization instead of raw casts for better error messages.
