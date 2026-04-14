# Production Readiness Report

**Date**: 2026-04-04
**Path**: /Users/kuba/Projects/dna_ai/code/mcp-server
**Target**: production
**Status**: With Concerns

## Executive Summary
- **Recommendation**: GO WITH MITIGATIONS
- **Overall Readiness**: 55%
- **Deployment Risk**: Medium
- **Blockers**: 4  Concerns: 6  Recommendations: 3

The MCP server is a thin, stateless proxy that forwards JWT tokens and delegates all business logic and data persistence to the backend at localhost:8080. This significantly reduces the attack surface and operational complexity. However, several production hardening items are missing: no connection timeouts on the RestClient, no graceful shutdown configuration, no externalized configuration for environment-specific values, and no error tracking integration.

## Category Breakdown
| Category | Score | Status |
|----------|-------|--------|
| Configuration | 40% | Needs Work |
| Monitoring | 50% | Needs Work |
| Resilience | 60% | Acceptable |
| Performance | 40% | Needs Work |
| Security | 70% | Acceptable |
| Deployment | 40% | Needs Work |

---

## Blockers (Must Fix)

### B1. No RestClient Timeouts Configured
- **Location**: `RestClientConfig.java` -- `RestClient.builder()` call
- **Issue**: The RestClient calling the backend has no connect or read timeout. If the backend hangs, the MCP server threads will block indefinitely, leading to thread pool exhaustion and a complete outage.
- **How to fix**: Configure `.requestFactory()` with connection and read timeouts (e.g., 5s connect, 30s read) via `ClientHttpRequestFactorySettings` or a custom `HttpComponentsClientHttpRequestFactory`.

### B2. No Graceful Shutdown
- **Location**: `application.yml`
- **Issue**: Spring Boot graceful shutdown is not enabled. During deployments, in-flight MCP requests will be abruptly terminated. The ThreadLocal-based `AccessTokenHolder` may also leak if requests are interrupted mid-flight.
- **How to fix**: Add `server.shutdown: graceful` and `spring.lifecycle.timeout-per-shutdown-phase: 30s` to `application.yml`.

### B3. Backend URL Hardcoded to localhost
- **Location**: `application.yml` line 21 -- `aj.backend.url: http://localhost:8080`
- **Issue**: The backend URL, OAuth server URL, and MCP base URL are hardcoded in `application.yml` with no environment variable overrides or Spring profiles. In production, the backend will not be at `localhost:8080`. No `.env.example` documents required variables.
- **How to fix**: Use environment variable placeholders (e.g., `${AJ_BACKEND_URL:http://localhost:8080}`) and create a `.env.example` documenting all required variables. Alternatively, use Spring profiles with `application-prod.yml`.

### B4. No Error Tracking Integration
- **Location**: Project-wide (pom.xml, application config)
- **Issue**: No Sentry, Bugsnag, or equivalent error tracking is configured. Runtime exceptions in production will only appear in log files, which may not be actively monitored. For a production service, structured error alerting is essential.
- **How to fix**: Add `sentry-spring-boot-starter` dependency and configure DSN via environment variable.

---

## Concerns (Should Fix)

### C1. No Rate Limiting
- **Location**: `SecurityConfig.java`
- **Issue**: No rate limiting on any endpoint. While the MCP server is typically behind infrastructure that provides this, the server itself has no protection against request floods. Since this is an API proxy, a misbehaving AI client could overwhelm the backend.
- **Recommendation**: Add basic rate limiting via Spring Cloud Gateway, Bucket4j, or infrastructure-level configuration. Document the expected approach.

### C2. Debug Logging in Production
- **Location**: `application.yml` line 29 -- `pl.devstyle: DEBUG`
- **Issue**: DEBUG logging is enabled by default. In production this creates excessive log volume and may expose sensitive request/response data through `LoggingJsonSchemaValidator`.
- **Recommendation**: Set to `INFO` or `WARN` for production. The `LoggingJsonSchemaValidator` at INFO level logs full request payloads on every validation call -- this should be DEBUG or removed entirely for production.

### C3. LoggingJsonSchemaValidator Logs Full Payloads
- **Location**: `LoggingJsonSchemaValidator.java` lines 21-24
- **Issue**: This validator logs schema validation details at INFO level, including the full instance data. In production, this means every MCP tool call will have its complete input/output logged, which could contain sensitive business data.
- **Recommendation**: Change `log.info` calls to `log.debug` or remove the logging wrapper entirely for production.

### C4. No CORS Configuration
- **Location**: `SecurityConfig.java`
- **Issue**: No CORS configuration is present. While MCP servers are typically called by server-side AI clients (not browsers), if any browser-based client integration is planned, CORS must be explicitly configured rather than relying on the default (block all cross-origin).
- **Recommendation**: If browser access is not needed, document this explicitly. If it is, add restrictive CORS configuration.

### C5. No Spring Profile Configuration
- **Location**: `src/main/resources/` -- only one `application.yml`
- **Issue**: No profile-specific configuration files exist. All environments (dev, staging, production) will use the same hardcoded values unless overridden via command-line or environment variables.
- **Recommendation**: Create `application-prod.yml` with production-appropriate settings (logging levels, URLs, timeouts).

### C6. No Request Size Limits
- **Location**: `application.yml`
- **Issue**: No explicit request body size limits are configured. MCP tool call payloads are typically small, but without limits, a malformed or malicious request could consume excessive memory.
- **Recommendation**: Set `spring.servlet.multipart.max-file-size` and `server.tomcat.max-http-form-post-size` or equivalent limits.

---

## Recommendations (Nice to Have)

### R1. Add Retry Logic for Backend Calls
- **Location**: `RestClientConfig.java`
- **Issue**: Backend calls have no retry logic. Transient network issues between MCP server and backend will immediately fail the tool call.
- **Recommendation**: Consider Spring Retry or Resilience4j for idempotent GET calls (list products, list categories).

### R2. Add Structured JSON Logging
- **Location**: Project-wide
- **Issue**: Logging uses default Spring Boot format (plain text). For production log aggregation (ELK, Datadog, etc.), structured JSON logs are preferred.
- **Recommendation**: Add `logstash-logback-encoder` or configure `logging.structured.format.console` in Spring Boot 3.5.

### R3. Add Metrics Instrumentation
- **Location**: `pom.xml`, `application.yml`
- **Issue**: Spring Boot Actuator is present but only health and info endpoints are exposed. No Micrometer metrics registry (Prometheus, Datadog) is configured. Tool call counts, latencies, and error rates will not be visible.
- **Recommendation**: Add `micrometer-registry-prometheus` and expose the `/actuator/prometheus` endpoint on the management port.

---

## What Is Already Good

- **Health endpoint**: Actuator health is exposed on separate management port (9081), properly excluded from auth.
- **Stateless design**: No sessions, JWT trust-and-forward model. Clean ThreadLocal lifecycle with try/finally cleanup in `McpJwtFilter`.
- **Error handling**: Comprehensive error mapping in `RestClientConfig` (400/401/403/404/5xx). Services wrap all exceptions with `McpToolException`. No raw stack traces leak to clients.
- **Security filter chain**: Well-structured with CSRF disabled (appropriate for stateless API), session creation disabled, `.well-known` and health endpoints public, everything else authenticated.
- **Authentication entry point**: Returns proper 401 with `WWW-Authenticate` header pointing to OAuth resource metadata -- MCP protocol compliant.
- **Separate management port**: Actuator on 9081 prevents accidental health check exposure on the main port.
- **No secrets in config**: No passwords, API keys, or tokens hardcoded in application.yml.

---

## Next Steps

1. **[Critical]** Add RestClient connect/read timeouts to prevent thread exhaustion
2. **[Critical]** Enable graceful shutdown in application.yml
3. **[Critical]** Externalize backend URL, OAuth URL, and MCP base URL via environment variables
4. **[Critical]** Integrate error tracking (Sentry or equivalent)
5. **[High]** Change default log level to INFO/WARN; demote LoggingJsonSchemaValidator to DEBUG
6. **[High]** Create application-prod.yml with production-appropriate settings
7. **[Medium]** Add rate limiting strategy (application or infrastructure level)
8. **[Medium]** Configure request size limits
9. **[Low]** Add retry logic for idempotent backend calls
10. **[Low]** Add structured JSON logging
11. **[Low]** Add Prometheus metrics endpoint
