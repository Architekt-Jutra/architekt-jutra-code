# Codebase Concerns

**Analysis Date:** 2026-08-16

## Tech Debt

**Stale architecture documentation:**
- Issue: `.maister/docs/project/architecture.md` describes the project as "pre-alpha scaffolding" with "no business logic" implemented, but the codebase has grown far beyond that — full JWT + OAuth2 auth, category/product CRUD, a plugin system with iframe sandboxing and JSONB storage, a carbon footprint calculator (backend + UI), and a separate `mcp-server` module.
- Files: `.maister/docs/project/architecture.md` (dated 2026-03-28)
- Impact: Any GSD/maister command reading this doc for context will get an inaccurate picture of scope and maturity, potentially under-scoping new phases or missing existing patterns to reuse.
- Fix approach: Regenerate `architecture.md` (and `tech-stack.md`) via `/gsd-map-codebase` (arch focus) or `maister:docs-manager` to reflect current package structure (`api`, `category`, `core/oauth2`, `core/plugin`, `core/security`, `product`, `user`, `footprint`) and the `mcp-server` submodule.

**CSV export logic duplicated three ways:**
- Issue: The "fetch blob → download → status text → reset" flow is implemented independently in `CsvExportButton.tsx`, in the per-card export handler, and in the sequential "export all" handler.
- Files: `src/main/frontend/src/components/footprint/CsvExportButton.tsx`, `src/main/frontend/src/pages/FootprintComparisonPage.tsx` (lines ~247–273, ~598–608)
- Impact: Error handling diverges between the three call sites (the per-card path silently swallows errors instead of surfacing them).
- Fix approach: Replace the per-card inline button with `<CsvExportButton correlationId={...} />`; keep the sequential "export all" flow separate since it has genuinely different UX (progress live-region).

**`useProductFootprint` query-identity footgun:**
- Issue: The hook's effect dependency array includes the raw `query` object reference (`src/main/frontend/src/hooks/useProductFootprint.ts`). Callers must memoize the query object themselves or the hook refetches on every render. The contract is undocumented in the type signature.
- Files: `src/main/frontend/src/hooks/useProductFootprint.ts`, consumer `src/main/frontend/src/pages/ProductFootprintPage.tsx` (works around it with `useMemo`)
- Impact: Any new caller that forgets to memoize the query object will trigger unnecessary refetch loops.
- Fix approach: Derive a stable `queryKey` via `JSON.stringify(query ?? {})` and depend on that instead of the object reference.

**Problem+JSON error parser has single-feature scope:**
- Issue: `api/problem.ts` implements RFC7807 Problem+JSON parsing but is only consumed by the footprint feature (4 call sites). The rest of the app still surfaces raw `err.message` strings from `fetch` rejections.
- Files: `src/main/frontend/src/api/problem.ts`, `src/main/frontend/src/pages/ProductDetailPage.tsx` and other older pages (raw `err.message` usage)
- Impact: Inconsistent error message quality/format across the app; the backend's Problem+JSON convention (`.maister/docs/standards/global/error-handling.md`) is only partially adopted on the frontend.
- Fix approach: Either fold `problem.ts` into `api/client.ts` so all API calls parse Problem+JSON by default, or file a standards-update to require all pages to migrate.

**Largest page in repo lacks internal decomposition:**
- Issue: `FootprintComparisonPage.tsx` is 715 lines, combining URL parse/sync, hook wiring, scenario card grid, mini-bar rendering, delta table, and clipboard copy in one file.
- Files: `src/main/frontend/src/pages/FootprintComparisonPage.tsx`
- Impact: Harder to navigate/maintain; will keep growing if comparison filters/sharing features expand.
- Fix approach: Extract `ScenarioCard` (~200 LOC), `DeltaTable` (~95 LOC), and a `useScenarioUrlSync` hook (~50 LOC) as called out in `.maister/tasks/development/2026-05-20-footprint-calc-engine-ui/verification/pragmatic-review.md`.

**Inline `<input style={...}>` blocks bypass design system:**
- Issue: Raw `<input>` elements with duplicated inline style objects (border/radius/font-size/padding) appear 6 times across footprint pages instead of using Chakra's `Input` component.
- Files: `src/main/frontend/src/pages/ProductFootprintPage.tsx`, `src/main/frontend/src/pages/FootprintComparisonPage.tsx`
- Impact: Visual inconsistency and duplicated styling logic that diverges from the rest of the app's Chakra-based UI.
- Fix approach: Standardize on Chakra `Input` or extract a shared `TextField` component.

**Hard-coded footprint component labels:**
- Issue: `MINI_BAR_COMPONENTS` in `FootprintComparisonPage.tsx` hard-codes `["Materials", "Transport", "Packaging", "Cold storage"]` rather than deriving labels from the API response.
- Files: `src/main/frontend/src/pages/FootprintComparisonPage.tsx` (~line 125)
- Impact: If the backend adds/renames a top-level breakdown component, the mini-bars silently show 0 with no error.
- Fix approach: Derive labels from `scenarios[0].data.breakdown.children.map(c => c.componentId)`.

**Redundant JWT parsing per request:**
- Issue: `JwtAuthenticationFilter` calls `validateToken()`, `getUsernameFromToken()`, and `getPermissionsFromToken()` separately, each independently re-parsing and re-verifying the JWT signature (3 parse operations per authenticated request), despite `JwtTokenProvider.parseToken()` already existing as a single-parse alternative.
- Files: `src/main/java/pl/devstyle/aj/core/security/JwtAuthenticationFilter.java`, `src/main/java/pl/devstyle/aj/core/security/JwtTokenProvider.java`
- Impact: Wasted CPU per request (3x signature verification instead of 1x); scales linearly with traffic.
- Fix approach: Use the existing `parseToken()` method (returns `ParsedToken(username, permissions)`) in the filter instead of three separate calls.

## Known Bugs

None reproducible/logged as open defects at time of analysis. The `removeScenario` guard in `useFootprintComparison.ts` (line ~97) silently no-ops when removing the first scenario in the array — documented as a minor behavioral quirk in the pragmatic review rather than a confirmed bug, but worth a regression test if scenario removal order matters.
- Files: `src/main/frontend/src/hooks/useFootprintComparison.ts`

## Security Considerations

**Default JWT secret committed in source (highest priority):**
- Risk: `app.jwt.secret` in `application.properties` falls back to a hardcoded literal (`i/WZnrbvFqiPfShuZjGmc5kC7IXxRZfpueJEdgCzGFc=`) via `${APP_JWT_SECRET:...}` Spring property syntax. If `APP_JWT_SECRET` is not set in any deployed environment, the same publicly-visible secret signs production tokens — anyone with source access can forge valid JWTs (including admin permission claims).
- Files: `src/main/resources/application.properties` (line 4), `src/main/java/pl/devstyle/aj/core/security/JwtTokenProvider.java`
- Current mitigation: The property supports env-var override syntax, but there is no `application-prod.properties`, no Spring profile separation, and no enforcement that the env var is actually set at deploy time.
- Recommendations: Fail application startup if `APP_JWT_SECRET` is unset in a `prod` profile; remove the literal default or move it to a `application-local.properties` used only for local dev; add a production Spring profile with externalized secrets. This blocker was previously called out in `.maister/tasks/development/2026-04-03-spring-security-jwt-auth/verification/production-readiness-report.md` (B1) and is still unresolved as of this analysis.

**JWT stored in localStorage (XSS exposure):**
- Risk: The frontend stores the JWT in `localStorage` (`auth_token` key), readable by any JavaScript running on the page — including any plugin iframe content if sandboxing is ever weakened, or any injected/XSS script.
- Files: `src/main/frontend/src/auth/AuthContext.tsx`, `src/main/frontend/src/api/client.ts`, `src/main/frontend/src/plugins/PluginMessageHandler.ts` (reads `localStorage.getItem("auth_token")` to forward tokens to plugins via `getToken` message and `pluginFetch`)
- Current mitigation: Plugin iframes are sandboxed and origin-validated in `PluginMessageHandler.ts`; `pluginFetch` restricts URLs to `/api/` prefix and strips traversal (`..`) to reduce SSRF risk. No CSP is configured to further restrict script execution.
- Recommendations: Consider HttpOnly cookie-based token storage in a future iteration; add Content-Security-Policy headers to reduce blast radius of any XSS.

**No authentication event logging:**
- Risk: Login success/failure and invalid/expired JWT presentation are not logged anywhere, making brute-force or credential-stuffing detection impossible.
- Files: `src/main/java/pl/devstyle/aj/api/AuthController.java`, `src/main/java/pl/devstyle/aj/core/security/JwtAuthenticationFilter.java`
- Current mitigation: None.
- Recommendations: Add `log.info`/`log.warn` on login success/failure and invalid-token presentation.

**No rate limiting on login endpoint:**
- Risk: `POST /api/auth/login` has no throttling, making it susceptible to brute-force credential attacks.
- Files: `src/main/java/pl/devstyle/aj/api/AuthController.java`
- Current mitigation: BCrypt password hashing slows individual guesses but does not prevent distributed brute force.
- Recommendations: Add a rate limiter (Bucket4j or a servlet filter) keyed by IP/username on the login endpoint before production use.

**Seed users have weak, predictable passwords:**
- Risk: Database seed migrations create demo users with weak passwords (originally `viewer123`/`editor123`/`admin123`-style values per prior audit); if these migrations run unmodified in a production database, default credentials would be publicly guessable from source.
- Files: `src/main/resources/db/changelog/` (seed user changesets — filename has since been renumbered; re-verify exact current changeset)
- Current mitigation: BCrypt hashing of the passwords in the migration; acceptable for local dev only.
- Recommendations: Ensure seed users are excluded from or rotated in any production changelog track; document this requirement explicitly.

**No explicit security headers (CSP/HSTS) configured:**
- Risk: No Content-Security-Policy or Strict-Transport-Security headers are explicitly set. Default Spring Security `X-Frame-Options: DENY` can also conflict with the plugin iframe architecture if not deliberately relaxed.
- Files: `src/main/java/pl/devstyle/aj/core/security/SecurityConfiguration.java`
- Current mitigation: CORS configuration does exist (a prior blocker, B2, has since been addressed).
- Recommendations: Explicitly configure `frame-ancestors`/CSP to scope allowed plugin origins, and add HSTS for production deployments.

**Health endpoint does not check dependencies:**
- Risk: `HealthController` likely returns a static UP status without verifying database connectivity, so health checks can pass while the app cannot actually serve traffic.
- Files: `src/main/java/pl/devstyle/aj/api/HealthController.java`
- Current mitigation: None observed.
- Recommendations: Add Spring Boot Actuator health indicators or a manual DB connectivity check.

**Plugin postMessage handler is well-guarded but worth periodic re-audit:**
- Risk: `pluginFetch` (in `PluginMessageHandler.ts`) proxies arbitrary requests from plugin iframes to the host's `/api/` surface with the user's JWT attached. It restricts to `/api/` prefix, blocks `..` path traversal, strips credentials, and filters response headers to a CORS-safelist. This is solid, but any future relaxation of the `/api/` prefix check or safelist would reintroduce SSRF/data-exfiltration risk.
- Files: `src/main/frontend/src/plugins/PluginMessageHandler.ts`
- Current mitigation: Origin validation against each plugin's registered URL, `X-Requested-With` header, safelisted response headers.
- Recommendations: Add a regression test asserting `pluginFetch` rejects any URL outside `/api/` and any response header outside the safelist, so future edits can't silently widen the surface.

## Performance Bottlenecks

**Client-side JSONB plugin filtering (by design, but a scaling limit):**
- Problem: `product.list.filters` plugin extension point filters products by JSONB `pluginData` content entirely client-side (fetch all products, then filter in JS) rather than server-side.
- Files: `src/main/java/pl/devstyle/aj/product/ProductController.java`, `src/main/frontend/src/pages/ProductListPage.tsx`, `src/main/frontend/src/plugins/PluginFilterBar.tsx`
- Cause: Deliberate simplification documented in `.maister/tasks/development/2026-03-28-plugin-system/analysis/gap-analysis.md` (decision `jsonb-filter-backend`, Option C) — chosen for pre-alpha simplicity over generic server-side JSONB query support.
- Improvement path: Once product catalogs grow beyond a small dataset, add server-side JSONB filtering via JPA `Specification` or a dedicated query parameter (`?pluginFilter=...`) as described in the gap analysis' deferred Option A/B.

## Fragile Areas

**Plugin iframe / postMessage communication layer:**
- Files: `src/main/frontend/src/plugins/PluginMessageHandler.ts`, `src/main/frontend/src/plugins/iframeRegistry.ts`, `src/main/frontend/src/plugin-sdk/messaging.ts`
- Why fragile: Cross-origin `postMessage` protocols are inherently hard to test end-to-end (mocked in unit tests, not exercised against real iframes in CI); origin/source validation logic is security-critical and easy to regress silently.
- Safe modification: Any change to message type handling, origin validation, or the safelisted header set should be paired with an explicit unit test asserting the negative case (rejected origin, rejected URL, filtered header).
- Test coverage: Frontend unit tests exist (`src/test/plugins.test.tsx`, `src/test/plugin-sdk.test.ts`, `src/test/plugin-sdk-auth.test.ts`) but no browser-level/e2e test exercises real iframe sandboxing.

**JSONB-backed entities (`PluginObject`, `Product.pluginData`):**
- Files: `src/main/java/pl/devstyle/aj/core/plugin/PluginObject.java`, `src/main/java/pl/devstyle/aj/product/Product.java`, `src/main/java/pl/devstyle/aj/core/plugin/DbPluginObjectQueryService.java`, `src/main/java/pl/devstyle/aj/product/DbProductQueryService.java`
- Why fragile: JSONB mapping via `@JdbcTypeCode(SqlTypes.JSON)` was a new pattern introduced specifically for the plugin system (no prior precedent in the codebase); both `DbPluginObjectQueryService` and `DbProductQueryService` contain broad `catch (Exception e)` blocks around JSONB deserialization, which can mask malformed-data errors as generic failures.
- Safe modification: Any schema change to plugin manifest or object `data` shape should be validated against existing JSONB rows; consider tightening the broad `catch (Exception e)` to specific deserialization exception types with explicit logging.
- Test coverage: Covered indirectly by plugin system integration tests; verify JSONB edge cases (null values, malformed JSON, large payloads) are explicitly tested.

**Comparison page state (`FootprintComparisonPage.tsx`):**
- Files: `src/main/frontend/src/pages/FootprintComparisonPage.tsx`, `src/main/frontend/src/hooks/useFootprintComparison.ts`, `src/main/frontend/src/utils/scenarioUrl.ts`
- Why fragile: 715-line page combining URL-state serialization, N independent per-scenario fetches, and a `didMountRef`-based one-shot-effect workaround (documented as intentional in the hook, but still a manual effect-guard pattern that is easy to break when adding new effects).
- Safe modification: Keep new effects independent of the `didMountRef` guard; prefer extracting new UI sections into child components rather than growing this file further.
- Test coverage: `src/test/FootprintComparisonPage.test.tsx` (7 tests) and `src/test/useFootprintComparison.test.ts` (5 tests) — reasonable but "tight" per the pragmatic review; consider adding a test for the URL round-trip (encode → decode → matches original scenario state).

## Scaling Limits

**Single-file `application.properties` with no profile separation:**
- Current capacity: All configuration (JWT secret, expiration, DB connection) lives in one non-profiled properties file.
- Limit: Cannot safely differentiate dev/staging/prod secrets or tuning without editing the same file or relying on env-var overrides alone.
- Scaling path: Introduce `application-prod.properties` / Spring profiles with environment-specific values, particularly for `app.jwt.secret` and future rate-limit/DB pool settings.

## Dependencies at Risk

None identified as deprecated or abandoned during this pass. The stack (Spring Boot 4.0.5, Java 25, JPA + JOOQ, Liquibase, PostgreSQL, React/Vite frontend) uses current, actively maintained versions per `.maister/docs/project/tech-stack.md`. Re-verify this section after each major dependency bump.

## Missing Critical Features

**No production authentication hardening:**
- Problem: No CORS-scoped-to-known-origins beyond what exists, no audit logging, no rate limiting, no token refresh mechanism (24h expiry forces daily re-login with no refresh flow).
- Blocks: Safe production deployment of the JWT/OAuth2 auth system as currently implemented. See full breakdown in `.maister/tasks/development/2026-04-03-spring-security-jwt-auth/verification/production-readiness-report.md` (Overall Readiness: 62%, "GO WITH MITIGATIONS").

**No error tracking / observability integration:**
- Problem: `GlobalExceptionHandler` (`src/main/java/pl/devstyle/aj/core/error/GlobalExceptionHandler.java`) logs unexpected errors via SLF4J only — no Sentry/Bugsnag/equivalent aggregation, and no structured (JSON) log format for production log aggregation.
- Blocks: Production error visibility and alerting.

## Test Coverage Gaps

**No end-to-end/browser test coverage:**
- What's not tested: Real cross-origin iframe sandboxing behavior, actual `postMessage` round-trips in a browser context, full auth login→token→protected-route flow in a real browser.
- Files: All plugin iframe and auth flow code (`src/main/frontend/src/plugins/`, `src/main/frontend/src/auth/`)
- Risk: Security-critical origin-validation logic is only unit-tested with mocked `MessageEvent` objects, not exercised against real browser cross-origin semantics.
- Priority: High — this is the most security-sensitive subsystem in the app (plugin sandboxing) and has no integration-level verification.

**`ProductFootprintPage.test.tsx` under-covers a stateful dual-mode form:**
- What's not tested: The "type in field → no refetch → click Recalculate → refetch with new params" invariant (pending vs. applied state) has no dedicated test, despite being the page's core interaction pattern.
- Files: `src/main/frontend/src/test/ProductFootprintPage.test.tsx`, `src/main/frontend/src/pages/ProductFootprintPage.tsx`
- Risk: A regression that causes premature refetch (defeating the "apply" gesture) would not be caught by the existing 4 tests.
- Priority: Medium.

**No test for JWT secret misconfiguration:**
- What's not tested: There is no test asserting that the application fails fast (or at minimum logs a critical warning) if `APP_JWT_SECRET` is unset and falls back to the committed default.
- Files: `src/main/java/pl/devstyle/aj/core/security/JwtTokenProvider.java`, `src/main/resources/application.properties`
- Risk: The unresolved B1 security blocker (see Security Considerations) could silently ship to production undetected.
- Priority: High — directly tied to the highest-severity open security concern in this document.

---

*Concerns audit: 2026-08-16*
