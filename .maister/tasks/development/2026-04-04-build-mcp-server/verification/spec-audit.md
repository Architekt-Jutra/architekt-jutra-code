# Specification Audit: Build MCP Server

**Date**: 2026-04-04
**Specification**: `.maister/tasks/development/2026-04-04-build-mcp-server/implementation/spec.md`
**Auditor**: spec-auditor (independent verification)

---

## Compliance Status: Mostly Compliant

The specification is well-structured, internally consistent, and closely aligned with both the reference implementation (skillpanel-mcp) and the actual aj backend API contracts. There are no critical blocking issues. Several medium-severity items need clarification or correction before implementation begins.

---

## Summary

The spec defines a standalone MCP server exposing three tools (aj_list_products, aj_add_product, aj_list_categories) over HTTP at port 8081, using Spring Boot 4.0.5 with trust-and-forward JWT authentication and RestClient for backend communication. The specification correctly identifies the need to replace Feign with RestClient, correctly documents all backend API contracts, and appropriately scopes the work. The findings below are mostly about missing details, minor inconsistencies, and ambiguities that should be resolved before implementation.

---

## Findings

### Finding 1: Missing `@EnableWebMvc` in specification

**Spec Reference**: Section "Architecture" and "Package Structure" -- AjMcpApplication.java described as "entry point + MCP beans"

**Evidence**:
- The reference skillpanel-mcp application uses `@EnableWebMvc` annotation (`/Users/kuba/Projects/devskiller/code/skillpanel-mcp/src/main/java/com/skillpanel/skillpanelmcp/SkillPanelMcpApplication.java:25`)
- The MCP SDK's `WebMvcStatelessServerTransport` returns a `RouterFunction<ServerResponse>` which requires WebMVC functional endpoint support
- The spec does not mention `@EnableWebMvc` anywhere

**Category**: Incomplete

**Severity**: Medium -- Without `@EnableWebMvc`, the `RouterFunction` bean may not be properly registered. Spring Boot 4.0.5 may auto-configure this differently than 3.5.7, so the implementer needs explicit guidance on whether this annotation is required or if Spring Boot 4.x handles it automatically.

**Recommendation**: Clarify whether `@EnableWebMvc` is needed with Spring Boot 4.0.5's WebMVC auto-configuration. If it is, add it to the spec. If Spring Boot 4.x handles RouterFunction registration without it, document that difference explicitly.

---

### Finding 2: AccessTokenHolder concurrency model needs more detail

**Spec Reference**: Section "Reusable Components" -- AccessTokenHolder row: "Adapt pattern -- use `@RequestScope` bean (or ThreadLocal) for thread-safe concurrent request handling."

**Evidence**:
- The reference implementation uses `@Component` (singleton) with a plain field (`/Users/kuba/Projects/devskiller/code/skillpanel-mcp/src/main/java/com/skillpanel/skillpanelmcp/security/AccessTokenHolder.java:12-27`)
- The spec correctly identifies this as unsafe under concurrent requests
- The spec says "use `@RequestScope` bean (or ThreadLocal)" but these are fundamentally different approaches
- The package structure lists `AccessTokenHolder.java` under `security/` with annotation "(ThreadLocal token storage)"

**Category**: Ambiguous

**Severity**: Medium -- `@RequestScope` and ThreadLocal have different lifecycle semantics. `@RequestScope` requires a proxy and is cleaner with Spring's DI, but ThreadLocal works outside of Spring-managed contexts. The spec contradicts itself: the table says "@RequestScope bean (or ThreadLocal)" while the package structure says "ThreadLocal token storage."

**Recommendation**: Pick one approach and document it consistently. `@RequestScope` is the Spring-idiomatic choice and simpler. If ThreadLocal is chosen, document the cleanup strategy (clearing after request completes to avoid thread pool leaks). Do not leave it as "or" -- the implementer needs a single decision.

---

### Finding 3: `aj_list_products` search parameter -- missing query parameter forwarding detail

**Spec Reference**: Core Requirement 6: "calls `GET /api/products?search={search}`"

**Evidence**:
- The actual backend `ProductController.list()` accepts four parameters: `category`, `search`, `sort`, `pluginFilter` (`/Users/kuba/Projects/dna_ai/code/src/main/java/pl/devstyle/aj/product/ProductController.java:29-34`)
- The spec correctly states only `search` is exposed (Tool Simplification section)
- However, the spec does not specify what happens with the other parameters when `search` is provided -- should they be null, or should defaults be set?

**Category**: Ambiguous

**Severity**: Low -- The backend handles null parameters gracefully (they are `@RequestParam(required = false)`). The RestClient interface just needs to not send the other parameters. But this should be explicitly stated.

**Recommendation**: Add a note that the RestClient method for `GET /api/products` should only send the `search` parameter, with `category`, `sort`, and `pluginFilter` omitted (not sent as null). This avoids any accidental query string pollution.

---

### Finding 4: Management port not specified

**Spec Reference**: Core Requirement 5: "Server runs on port 8081, separate management port for actuator"

**Evidence**:
- The spec says "separate management port" but does not specify the actual port number
- The reference implementation uses port 9080 for management (`/Users/kuba/Projects/devskiller/code/skillpanel-mcp/src/main/resources/application.yml:42-43`)
- The main aj app uses Spring Boot defaults (no separate management port configured)

**Category**: Incomplete

**Severity**: Low -- The implementer will need to pick a port number. Without specification, they may use 9081 (sequential from 8081), 9080 (matching reference), or some other value.

**Recommendation**: Specify the management port explicitly (e.g., 9081 to avoid conflict with any future skillpanel-mcp instance).

---

### Finding 5: Gap analysis document contains stale Feign references

**Spec Reference**: Not the spec itself, but the supporting gap-analysis.md

**Evidence**:
- `gap-analysis.md` Section 4 is titled "Feign Client Layer" and contains references to `@FeignClient`, `McpJwtTokensFeignRequestInterceptor`, `DefaultFeignConfiguration`, `feign-okhttp` (`/Users/kuba/Projects/dna_ai/code/.maister/tasks/development/2026-04-04-build-mcp-server/analysis/gap-analysis.md:53-60`)
- The spec itself correctly specifies RestClient (not Feign), meaning the gap analysis was written before the Phase 2 decision to switch to RestClient
- The gap analysis "Issues Requiring Decisions" section 2 discusses Spring Cloud Feign compatibility as if undecided (`gap-analysis.md:157-163`)

**Category**: Incorrect (supporting document)

**Severity**: Low -- This does not affect the spec itself, which is correct. But if an implementer reads the gap analysis for context, they may be confused by the Feign references.

**Recommendation**: Either update gap-analysis.md to reflect the RestClient decision, or add a note at the top indicating that sections referencing Feign are superseded by the spec's RestClient approach.

---

### Finding 6: Spring Boot 4.0.5 + MCP SDK 0.16.0 compatibility risk insufficiently specified

**Spec Reference**: Core Requirement 2: "MCP SDK (`mcp-spring-webmvc`) for stateless WebMVC transport"
Dependencies section: "`io.modelcontextprotocol.sdk:mcp-spring-webmvc` (latest compatible with Spring Boot 4.0.5)"

**Evidence**:
- The reference implementation uses MCP SDK 0.16.0 with Spring Boot 3.5.7 (`/Users/kuba/Projects/devskiller/code/skillpanel-mcp/pom.xml:30-31`)
- Spring Boot 4.0.5 uses Spring Framework 7 and Jakarta EE 11 which have breaking changes from Spring Boot 3.x
- The spec says "latest compatible" without specifying the actual version number
- The gap-analysis.md identifies this as a "Critical" decision item (`gap-analysis.md:148-154`)

**Category**: Ambiguous

**Severity**: High -- If MCP SDK 0.16.0 is not compatible with Spring Boot 4.0.5 (which is plausible given the major version jump), the entire implementation approach needs to change. The spec should either: (a) specify the exact MCP SDK version confirmed to work, or (b) specify an explicit fallback plan (e.g., "use Spring Boot 3.5.7 if SDK is incompatible").

**Recommendation**: Before implementation begins, verify MCP SDK compatibility with Spring Boot 4.0.5. Check if a newer version of the MCP SDK (0.17+, 1.0, etc.) exists that targets Spring Framework 7. Document the exact version in the spec. Include a fallback plan: "If no compatible MCP SDK version exists, use Spring Boot 3.5.7 for the MCP server module."

---

### Finding 7: Security filter registration -- Spring Security 7 API changes

**Spec Reference**: Section "Security Model (Trust-and-Forward)" -- "The SecurityFilterChain still requires authentication on all endpoints except actuator health and error."

**Evidence**:
- The reference SecurityConfig uses `http.addFilterBefore(..., BasicAuthenticationFilter.class)` (`/Users/kuba/Projects/devskiller/code/skillpanel-mcp/src/main/java/com/skillpanel/skillpanelmcp/config/SecurityConfig.java:59`)
- Spring Security 7 (bundled with Spring Boot 4.0.5) has API changes including the removal of certain deprecated methods and changes to `HttpSecurity` configuration
- The aj project's own SecurityConfiguration already works with Spring Security 7 (`/Users/kuba/Projects/dna_ai/code/src/main/java/pl/devstyle/aj/core/security/SecurityConfiguration.java`)
- The spec does not mention Spring Security 7 API differences or reference the aj project's existing security config as a pattern to follow

**Category**: Incomplete

**Severity**: Medium -- The implementer should follow the aj project's existing `SecurityConfiguration.java` as the pattern for Spring Security 7 compatibility, not the skillpanel-mcp reference which uses Spring Security 6.x APIs.

**Recommendation**: Add a note to the spec's Security section: "Follow the aj project's SecurityConfiguration.java pattern for Spring Security 7 compatible SecurityFilterChain configuration, not the skillpanel-mcp SecurityConfig which uses Spring Security 6.x APIs."

---

### Finding 8: `aj_add_product` -- `price` type mismatch risk

**Spec Reference**: Core Requirement 7: "accepts `name` (required), `description`, `photoUrl`, `price` (required), `sku` (required), `categoryId` (required)"

**Evidence**:
- The actual `CreateProductRequest` uses `BigDecimal price` (`/Users/kuba/Projects/dna_ai/code/src/main/java/pl/devstyle/aj/product/CreateProductRequest.java:14`)
- The spec does not specify the JSON Schema type for `price` in the tool's input schema
- LLM agents may send price as a string ("19.99"), integer (1999), or number (19.99) -- each needs different handling
- The backend validates `@NotNull @Positive BigDecimal price`, so Jackson deserialization behavior matters

**Category**: Incomplete

**Severity**: Medium -- If the JSON Schema specifies `"type": "number"` but the LLM sends `"19.99"` (string), the tool will fail. The input schema must explicitly define the type as `"number"` and the MCP server's DTO should use `BigDecimal` to match the backend.

**Recommendation**: Add explicit JSON Schema type guidance for the `aj_add_product` tool's input schema. At minimum: `price` should be `"type": "number"`, `categoryId` should be `"type": "integer"`. Consider adding `"description"` fields to each property to help LLM agents provide correct values.

---

### Finding 9: Error handling for backend HTTP errors not fully specified

**Spec Reference**: Core Requirement 9: "LLM-friendly error handling via McpToolException with static factory methods"

**Evidence**:
- The reference SkillsetService catches `FeignException` and `FeignException.NotFound` separately (`/Users/kuba/Projects/devskiller/code/skillpanel-mcp/src/main/java/com/skillpanel/skillpanelmcp/service/SkillsetService.java:29-35, 45-55`)
- With RestClient replacing Feign, the exception types change -- RestClient throws `RestClientResponseException`, `HttpClientErrorException`, `HttpServerErrorException` etc.
- The spec mentions McpToolException static factories but does not document what backend HTTP errors should be caught and how they map

**Category**: Incomplete

**Severity**: Medium -- Without specifying the RestClient exception mapping, the implementer may miss important error cases (400 validation errors from backend, 401 unauthorized, 403 forbidden, 404 not found, 500 server error). Each needs a different LLM-friendly message.

**Recommendation**: Add an error mapping table:
- 400 Bad Request -> `McpToolException.validationError()` (forward backend validation message)
- 401 Unauthorized -> `McpToolException.apiError()` with "Authentication required" message
- 403 Forbidden -> `McpToolException.apiError()` with "Insufficient permissions" message
- 404 Not Found -> `McpToolException.notFound()`
- 5xx Server Error -> `McpToolException.apiError()` with retry suggestion

---

### Finding 10: Spec correctly matches backend API contracts

**Spec Reference**: Core Requirements 6, 7, 8 and "Reusable Components" table

**Evidence** (positive verification):
- `GET /api/products` with `search` param: Confirmed in `ProductController.java:29-34` -- `@RequestParam(required = false) String search`
- `POST /api/products` with CreateProductRequest body: Confirmed in `ProductController.java:43-45` -- `@Valid @RequestBody CreateProductRequest`
- `GET /api/categories`: Confirmed in `CategoryController.java:28-30` -- no parameters
- ProductResponse fields (id, name, description, photoUrl, price, sku, category, pluginData, createdAt, updatedAt): Confirmed in `ProductResponse.java:9-20`
- CreateProductRequest fields (name, description, photoUrl, price, sku, categoryId): Confirmed in `CreateProductRequest.java:11-18`
- CategoryResponse fields (id, name, description, createdAt, updatedAt): Confirmed in `CategoryResponse.java:6-11`
- Backend permissions: `PERMISSION_READ` for GET, `PERMISSION_EDIT` for POST confirmed in `SecurityConfiguration.java:85-96`

**Category**: Correct

**Severity**: N/A -- This is a positive finding. All API contracts in the spec are verified against actual backend code.

---

### Finding 11: Testing approach underspecified

**Spec Reference**: Section "Testing Approach" -- "Context load test to verify application starts. Schema validation tests for each tool."

**Evidence**:
- The reference skillpanel-mcp has 5 test files with ~15+ tests
- The spec mentions only 2 types of tests (context load, schema validation)
- No mention of how to test the trust-and-forward JWT flow
- No mention of how to test RestClient integration (mocking vs WireMock)
- The spec says "2-8 focused tests per implementation step group" but does not define what a "step group" is

**Category**: Incomplete

**Severity**: Low -- Testing strategy can be refined during implementation planning. The core test types are identified; details can emerge during implementation.

**Recommendation**: Consider adding guidance on: (1) how to mock the backend API for schema validation tests (RestClient mock vs WireMock), (2) whether JWT filter tests are in scope, (3) what "step group" means in the context of 3 tools.

---

### Finding 12: No `application.properties` / `application.yml` content specified

**Spec Reference**: The spec mentions port 8081 and "separate management port" but does not provide the configuration file content.

**Evidence**:
- The reference `application.yml` contains server port, management port, logging levels, Spring AI MCP config, Spring Cloud Kubernetes config, OAuth2 config (`/Users/kuba/Projects/devskiller/code/skillpanel-mcp/src/main/resources/application.yml:1-57`)
- The new MCP server needs at minimum: `server.port=8081`, `management.server.port=???`, backend base URL configuration, Spring AI MCP server name/version
- The spec's `spring.ai.mcp.server.*` properties are not mentioned at all

**Category**: Incomplete

**Severity**: Low -- Configuration details are typically handled during implementation. However, specifying the backend base URL property name (e.g., `aj.backend.url=http://localhost:8080`) would help the implementer design the RestClient config.

**Recommendation**: Add a minimal configuration section listing required properties: server port, management port, backend base URL, MCP server name/version, logging levels.

---

## Clarification Questions

1. **MCP SDK Version**: Has anyone verified that `mcp-spring-webmvc` 0.16.0 (or any available version) works with Spring Boot 4.0.5 / Spring Framework 7? If not, what is the fallback plan -- downgrade to Spring Boot 3.5.7 for the MCP server?

2. **AccessTokenHolder approach**: Should the implementation use `@RequestScope` (Spring proxy) or `ThreadLocal` (manual cleanup)? The spec mentions both but they are mutually exclusive approaches.

3. **`@EnableWebMvc`**: Is this annotation needed with Spring Boot 4.0.5 for the MCP `RouterFunction` to work, or does Spring Boot's auto-configuration handle it?

4. **Management port**: What specific port number should the actuator run on?

---

## Extra Features (Not in Spec but Potentially Needed)

None identified. The spec appropriately scopes the work to three tools and explicitly lists out-of-scope items.

---

## Recommendations

1. **Before implementation**: Verify MCP SDK compatibility with Spring Boot 4.0.5. This is the single highest-risk item and could invalidate the entire technical approach.

2. **Resolve AccessTokenHolder ambiguity**: Pick `@RequestScope` (recommended) and update the spec consistently.

3. **Add error mapping table**: Document how RestClient exceptions map to McpToolException factory methods.

4. **Add JSON Schema type guidance**: Specify the input schema types for `aj_add_product` (especially `price` as number, `categoryId` as integer).

5. **Reference aj's SecurityConfiguration**: For Spring Security 7 compatible patterns rather than the skillpanel-mcp reference which uses Spring Security 6.x.

6. **Update gap-analysis.md**: Mark Feign sections as superseded, or add a header note.
