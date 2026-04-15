# Production Readiness Report

**Date**: 2026-03-29
**Path**: plugins/ai-description/
**Target**: production
**Status**: Not Ready

## Executive Summary
- **Recommendation**: NO-GO
- **Overall Readiness**: 35%
- **Deployment Risk**: Critical
- **Blockers**: 7  Concerns: 5  Recommendations: 3

The AI Description Plugin has solid domain modeling, good input validation, proper error handling in the API route, and clean test coverage for the critical paths. However, it has multiple production blockers: hardcoded localhost URLs, no API key validation at startup, no rate limiting on the LLM endpoint, no request size limits, no health check, no error tracking, and no timeout on the BAML LLM call.

## Category Breakdown
| Category | Score | Status |
|----------|-------|--------|
| Configuration | 40% | Blockers present |
| Monitoring | 10% | Blockers present |
| Resilience | 50% | Concerns present |
| Performance | 20% | Blockers present |
| Security | 40% | Blockers present |
| Deployment | 50% | Concerns present |

---

## Blockers (Must Fix)

### B1. Hardcoded localhost URLs in `_document.tsx`
**Location**: `src/pages/_document.tsx:7-8`
**Issue**: SDK script and CSS stylesheet are loaded from `http://localhost:8080`. This will break in any non-local environment.
**Fix**: Use an environment variable (e.g., `NEXT_PUBLIC_HOST_ORIGIN`) to configure the host origin, or derive it from the SDK context at runtime.

### B2. Hardcoded localhost URL in `manifest.json`
**Location**: `manifest.json:4`
**Issue**: `"url": "http://localhost:3003"` -- the manifest declares a localhost URL. In production, this must point to the deployed plugin URL.
**Fix**: Make the manifest URL configurable per environment, or generate the manifest at build/deploy time with the correct URL.

### B3. No API key validation at startup
**Location**: `baml_src/clients.baml:4` reads `env.OPENAI_API_KEY`
**Issue**: If `OPENAI_API_KEY` is missing or empty, the plugin will start successfully but fail at runtime when a user tries to generate a description. There is no fail-fast behavior.
**Fix**: Add a startup check (e.g., in `next.config.js` or a custom server) that validates required environment variables are present and non-empty.

### B4. No rate limiting on `/api/generate`
**Location**: `src/pages/api/generate.ts`
**Issue**: The generate endpoint calls an external LLM API with no rate limiting. Any user can trigger unlimited LLM calls, leading to cost overruns and potential API key exhaustion.
**Fix**: Add rate limiting middleware (e.g., per-IP or per-session throttle) before the handler, or use Next.js middleware.

### B5. No health check endpoint
**Location**: `src/pages/api/` -- no `/api/health` or `/api/healthz` route exists
**Issue**: No way for load balancers, orchestrators, or monitoring to verify the plugin is alive and its dependencies (LLM provider) are reachable.
**Fix**: Add a `/api/health` endpoint that returns 200 and optionally validates the API key is configured.

### B6. No error tracking integration
**Location**: Project-wide
**Issue**: No Sentry, Bugsnag, or equivalent error tracking. Production LLM call failures, unexpected errors, and client-side exceptions will go unnoticed.
**Fix**: Integrate an error tracking service. For Next.js, Sentry has first-class support via `@sentry/nextjs`.

### B7. No timeout on LLM calls
**Location**: `src/pages/api/generate.ts:46-51`, `baml_src/clients.baml`
**Issue**: The BAML LLM call has no explicit timeout configured. LLM providers can hang for 30+ seconds or indefinitely. The Next.js API route will block the server thread.
**Fix**: Configure a timeout in the BAML client options (e.g., `timeout_ms` in `clients.baml`) or wrap the call with a timeout utility.

---

## Concerns (Should Fix)

### C1. No structured logging
**Location**: Project-wide
**Issue**: No logging library is used anywhere. The API route catches errors silently without logging them. In production, you need structured logs (JSON format with levels) to diagnose LLM failures and API issues.
**Recommendation**: Add a logging library (e.g., `pino`) and log LLM call attempts, durations, and failures in the generate handler.

### C2. Error details swallowed in catch block
**Location**: `src/pages/api/generate.ts:58-62`
**Issue**: The catch block returns a generic user-facing error (good) but does not log the actual error (bad). LLM provider errors, rate limit responses, and authentication failures will be invisible.
**Recommendation**: Log the caught error with context (product name, error type) before returning the generic response.

### C3. No request body size limit on `/api/generate`
**Location**: `src/pages/api/generate.ts`
**Issue**: No explicit body size limit. A malicious request could send a very large `customInformation` field, which gets forwarded to the LLM prompt.
**Recommendation**: Add a Next.js API config to limit body size, and validate/truncate `customInformation` to a reasonable length (e.g., 2000 characters).

### C4. No input sanitization on LLM prompt injection
**Location**: `baml_src/main.baml:14-21`, `src/pages/api/generate.ts`
**Issue**: User-provided `customInformation` (and `productName`/`productDescription` from the host) are interpolated directly into the LLM prompt template. While BAML handles the templating safely, adversarial input could manipulate the LLM's behavior (prompt injection).
**Recommendation**: Consider adding basic input length validation and document the prompt injection risk. For a product tab used by internal users, this is a concern rather than a blocker.

### C5. Frontend fetch uses relative URL
**Location**: `src/pages/product-tab.tsx:52`
**Issue**: `fetch("/api/generate", ...)` uses a relative URL. When the plugin is loaded in an iframe, the relative URL resolves against the plugin's origin, which is correct. However, this assumes the plugin's frontend and API are always co-located, which may not hold in all deployment topologies.
**Recommendation**: Document this assumption. If the API might be deployed separately, use an absolute URL from config.

---

## Recommendations (Nice to Have)

### R1. Add retry logic for LLM calls
**Location**: `baml_src/clients.baml`
**Issue**: The BAML `LlmProvider` uses a fallback strategy with only one provider (OpenAI). If the call fails transiently, there is no retry.
**Recommendation**: Add retry configuration in the BAML client or add a second provider to the fallback chain (e.g., Anthropic as backup).

### R2. Add loading skeleton instead of text
**Location**: `src/pages/product-tab.tsx:99`
**Issue**: The loading state is a plain text "Loading..." div. This is functional but provides a subpar user experience.
**Recommendation**: Use a skeleton/shimmer component for a more polished loading state.

### R3. Add metrics for LLM call latency and success rate
**Location**: `src/pages/api/generate.ts`
**Issue**: No instrumentation to track how long LLM calls take, how often they fail, or usage patterns.
**Recommendation**: Add basic metrics (call count, latency histogram, error rate) to inform operational decisions and cost monitoring.

---

## Next Steps

**Priority 1 -- Must fix before any deployment:**
1. Replace hardcoded localhost URLs with environment-driven configuration (B1, B2)
2. Add startup validation for required env vars -- `OPENAI_API_KEY` (B3)
3. Add rate limiting to `/api/generate` (B4)
4. Add a health check endpoint (B5)
5. Configure a timeout on the BAML LLM client (B7)

**Priority 2 -- Required for production, can be staged:**
6. Integrate error tracking (Sentry) (B6)
7. Add structured logging with error context (C1, C2)
8. Add request body size limits and input length validation (C3, C4)

**Priority 3 -- Should have for production operations:**
9. Add retry logic / secondary LLM provider (R1)
10. Add operational metrics (R3)

---

## Positive Findings

The following aspects are well-implemented and production-ready:

- **Input validation**: The API route validates required fields with specific error messages
- **Error handling in UI**: Network errors and API errors are caught and displayed to users
- **Secret management**: `.env.local` is properly gitignored; `.env.example` documents required vars without real values
- **Type safety**: Strong TypeScript typing throughout, domain types cleanly separated
- **Test coverage**: API handler has 5 tests covering validation, success, failure, and parameter passing
- **Error message hygiene**: Internal error details (e.g., "LLM provider timeout") are not leaked to users (verified by test)
- **Dependency security**: `npm audit` reports 0 vulnerabilities across all 357 dependencies
- **SDK usage**: Proper use of the host SDK for data persistence (custom objects with entity binding)
