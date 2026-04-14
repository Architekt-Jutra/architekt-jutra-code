# Pragmatic Code Review: aj-mcp Server

**Date**: 2026-04-04
**Project**: aj-mcp (MCP Server)
**Project Scale**: Greenfield standalone service, MVP/early-stage
**Scope**: All source under `mcp-server/src/`

## Executive Summary

**Status: Appropriate**

This codebase is well-calibrated for its purpose. It is a focused, thin proxy MCP server with 3 tools, trust-and-forward JWT, and RestClient. The implementation is lean (16 production files, ~700 LOC) with no unnecessary abstractions, no heavy infrastructure, and no speculative code. The architecture directly maps to the problem domain.

There are only minor findings -- nothing that would impede development or warrant urgent action.

| Severity | Count |
|----------|-------|
| Critical | 0 |
| High | 0 |
| Medium | 2 |
| Low | 3 |

---

## 1. Complexity Assessment

**Project Scale**: MVP/early-stage standalone service
**Complexity Level**: Low (appropriate)

| Metric | Value |
|--------|-------|
| Production Java files | 16 |
| Test Java files | 9 |
| Total production LOC | ~700 |
| Total test LOC | ~560 |
| Dependencies | 5 (spring-boot-starter-web, security, actuator, mcp-spring-webmvc, lombok) |
| Config files | 1 (application.yml) |
| Abstraction layers | 2 (Service -> Client) |

**Verdict**: Complexity is proportional to the problem. The service does exactly what it needs to -- expose 3 MCP tools that proxy to a backend API. No over-abstraction, no unnecessary layers.

---

## 2. Over-Engineering Patterns

### Not Found

The codebase avoids common over-engineering traps:

- **No unnecessary infrastructure**: No caching (Caffeine/Redis), no message queues, no service discovery. Correct for a stateless proxy.
- **No excessive abstraction**: Services talk directly to the API client. No repository layer, no domain model layer, no factory pattern.
- **No enterprise patterns in simple code**: No circuit breakers, no retry policies, no rate limiting. The backend handles all business logic.
- **No premature optimization**: No connection pooling configuration, no async/reactive complexity. Synchronous MCP transport is the right choice.
- **Minimal configuration**: Single `application.yml` with 7 properties. No profiles, no feature flags, no multi-environment configs.

---

## 3. Key Issues Found

### Medium Severity

#### M1. WellKnownController exists despite being listed as out-of-scope

**File**: `src/main/java/pl/devstyle/aj/mcp/controller/WellKnownController.java` (all 28 lines)
**Evidence**: Spec section "Out of Scope" explicitly lists: "WellKnownController / OAuth protected resource metadata endpoint"
**Impact**: Extra code that was explicitly excluded from requirements. Also adds `aj.oauth.server-url` and `aj.mcp.base-url` config properties and a `/.well-known/**` permitAll rule in SecurityConfig. The `McpAuthenticationEntryPoint` references `aj.mcp.base-url` for the `WWW-Authenticate` header, which may justify the config property, but the controller itself is scope creep.
**Recommendation**: Evaluate whether the OAuth protected resource metadata endpoint is actually needed by the MCP client. If not, remove `WellKnownController.java` and the `/.well-known/**` security rule. Keep `McpAuthenticationEntryPoint` if the `WWW-Authenticate` header is required by the MCP protocol.
**Effort**: 5 minutes

#### M2. ProductService.buildToolAddProduct output schema duplicates the listProducts output schema

**File**: `src/main/java/pl/devstyle/aj/mcp/service/ProductService.java` (lines 206-275)
**Evidence**: The `outputSchema` JSON for `aj_add_product` (single product) is nearly identical to the product item schema inside `aj_list_products` (product inside array). The category sub-object schema is duplicated three times across ProductService and CategoryService.
**Impact**: Maintenance burden when the product/category schema changes -- must update in 3+ places. For 3 tools this is tolerable, but worth noting.
**Recommendation**: This is acceptable for the current scale. If tool count grows, consider extracting shared schema fragments into constants. Do not over-engineer this now.
**Effort**: N/A (accept current state)

### Low Severity

#### L1. Unused `invalidCriteria` factory method on McpToolException

**File**: `src/main/java/pl/devstyle/aj/mcp/exception/McpToolException.java` (lines 41-44)
**Evidence**: `invalidCriteria(String details, String suggestion)` is defined but never called anywhere in the codebase. Grep confirms zero callers outside the definition.
**Impact**: Dead code. Minor, but violates the project's own "Minimal Implementation" standard: "Build only what is needed, clear purpose for every method, delete exploration artifacts."
**Recommendation**: Remove `invalidCriteria` method.
**Effort**: 1 minute

#### L2. Unused import in RestClientConfig

**File**: `src/main/java/pl/devstyle/aj/mcp/config/RestClientConfig.java` (line 13)
**Evidence**: `import org.springframework.web.client.RestClientResponseException;` is imported but never referenced in the file.
**Impact**: Trivial -- unused import.
**Recommendation**: Remove the unused import.
**Effort**: 1 minute

#### L3. Spring Boot version mismatch with spec

**File**: `pom.xml` (line 8)
**Evidence**: Spec says "Spring Boot 4.0.5, Java 25" but `pom.xml` uses `spring-boot-starter-parent:3.5.7`. The code uses Spring Boot 3.x APIs (e.g., `@SpringBootApplication`, `RestClient`) which all exist in 3.5.x. Java 25 is correctly configured.
**Impact**: Not a code quality issue per se -- may be a deliberate decision (Spring Boot 4.0.5 may not be released yet, or MCP SDK may not support it). The spec may have been aspirational. Code works correctly with 3.5.7.
**Recommendation**: Verify this was intentional. If Spring Boot 4.0.5 is available and MCP SDK supports it, consider upgrading. Otherwise, update the spec to reflect 3.5.7.
**Effort**: N/A (clarification only)

---

## 4. Developer Experience Assessment

**Overall DX: Good**

| Dimension | Rating | Notes |
|-----------|--------|-------|
| Setup complexity | Good | Single `mvnw` command, one config file |
| Code readability | Good | Clear naming, flat structure, no indirection |
| Error messages | Good | LLM-friendly error messages via McpToolException |
| Pattern consistency | Good | All tools follow the same buildTool pattern |
| Debugging | Good | LoggingJsonSchemaValidator aids schema debugging |
| Onboarding | Good | 16 files, obvious package structure |

**No DX friction points identified.** The codebase is small enough that any developer can understand the entire system in under 30 minutes.

---

## 5. Requirements Alignment

| Requirement | Status | Notes |
|-------------|--------|-------|
| 3 MCP tools | Implemented | aj_list_products, aj_add_product, aj_list_categories |
| Trust-and-forward JWT | Implemented | McpJwtFilter + AccessTokenHolder + RestClient interceptor |
| RestClient with HttpServiceProxyFactory | Implemented | Clean declarative interface |
| Port 8081 + separate management port | Implemented | 8081 + 9081 |
| Stateless WebMVC transport | Implemented | WebMvcStatelessServerTransport at "/" |
| LLM-friendly errors | Implemented | McpToolException with status-code-based mapping |
| Schema validation tests | Implemented | Draft 7 validation with networknt |
| No caching | Correct | Not present |
| No Feign/Spring Cloud | Correct | Not present |

**Scope creep**: WellKnownController (see M1 above). Everything else aligns with requirements.

---

## 6. Context Consistency

**No contradictory patterns detected.**

- Error handling is consistent across all services (catch McpToolException, rethrow; catch Exception, wrap as apiError).
- Tool building follows the same pattern in both ProductService and CategoryService.
- ThreadLocal token management is clean: set in filter, consumed by interceptor, cleared in finally block.

**Unused code**:
- `McpToolException.invalidCriteria()` -- defined but never called (see L1)
- `RestClientResponseException` import -- imported but unused (see L2)

---

## 7. Recommended Simplifications (Priority Actions)

### Priority 1: Remove WellKnownController if not needed by MCP clients (Medium)

If the OAuth protected resource metadata endpoint is not required by MCP protocol compliance, remove:
- `WellKnownController.java` (28 lines)
- `/.well-known/**` permitAll rule in SecurityConfig
- `aj.oauth.server-url` from application.yml (if only used by WellKnownController)

**Impact**: Removes ~30 lines of out-of-scope code, simplifies security config.

### Priority 2: Remove dead code (Low)

Remove:
- `McpToolException.invalidCriteria()` method (4 lines)
- Unused `RestClientResponseException` import (1 line)

**Impact**: Cleaner codebase aligned with "Minimal Implementation" standard.

### Priority 3: Clarify Spring Boot version (Low)

Verify whether Spring Boot 3.5.7 vs spec's 4.0.5 is intentional. Update spec or pom accordingly.

**Impact**: Documentation accuracy.

---

## 8. Summary Statistics

| Metric | Current | After Simplifications |
|--------|---------|----------------------|
| Production files | 16 | 15 (-1 WellKnownController) |
| Production LOC | ~700 | ~665 |
| Config properties | 7 | 6 (remove oauth.server-url if unused) |
| Dead code methods | 1 | 0 |
| Unused imports | 1 | 0 |

---

## 9. Conclusion

This is a well-built, appropriately-scoped MCP server. The implementation is lean, the architecture is flat, and the code does exactly what the spec asks for with no unnecessary complexity. The only meaningful finding is the out-of-scope WellKnownController, which should be evaluated for necessity and removed if not required.

**Action items**:
1. Decide on WellKnownController -- keep if MCP protocol requires it, remove if not (~5 min)
2. Remove `invalidCriteria()` dead code and unused import (~2 min)
3. Clarify Spring Boot version discrepancy with spec (~0 min, documentation only)

**Total estimated effort**: Under 10 minutes of changes.
