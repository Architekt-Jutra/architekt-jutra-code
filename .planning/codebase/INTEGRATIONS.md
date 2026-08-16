# External Integrations

**Analysis Date:** 2026-08-16

## APIs & External Services

**LLM / AI Inference:**
- LiteLLM proxy (self-hosted, `compose.yml` service `litellm`, image `ghcr.io/berriai/litellm:main-stable`, port 4000) — single gateway for all LLM calls from `plugins/ai-description`
  - Client config: `plugins/ai-description/baml_src/clients.baml` defines `LiteLlmProvider` (OpenAI-compatible, model `gpt-4o-mini`, `base_url http://localhost:4000/v1`, `api_key env.LITELLM_API_KEY`) and a `LlmProvider` fallback wrapper
  - BAML (`@boundaryml/baml`) code-generates typed client bindings (`baml_client`) consumed in `plugins/ai-description/src/pages/api/generate.ts`
  - Actual upstream model provider keys live in `litellm/.env` (referenced by `compose.yml`, not present in this repo — external/untracked secret)

**LLM Observability:**
- Langfuse (self-hosted, `compose.yml` services `langfuse` port 3100, `langfuse-worker`) — traces/observes LLM calls routed through LiteLLM
  - Backed by its own Postgres (`langfuse-db`, port 5433), ClickHouse (`clickhouse`, ports 8123/9000), Redis (`redis`, port 6379), and MinIO (`minio`, ports 9010/9011) for event/object storage

**PII Filtering / Guardrails:**
- Microsoft Presidio Analyzer + Anonymizer (`compose.yml` services `presidio-analyzer` port 5002, `presidio-anonymizer` port 5001) — PII detection/redaction in the LLM request path, configured via `litellm/presidio_recognizers.json` mounted into the `litellm` container

**Model Context Protocol (MCP):**
- Standalone Spring Boot module `mcp-server/` exposes the AJ platform as an MCP server using `io.modelcontextprotocol.sdk:mcp-spring-webmvc` (v0.18.1)
  - Talks to the main host app's REST API via `aj.backend.url` (`mcp-server/src/main/resources/application.yml`, default `http://localhost:8080`)
  - Delegates OAuth2 to the host's authorization server via `aj.oauth.server-url` (default `https://kuba-app.labs-skillpanel.com`), `aj.oauth.client-id` (default `mcp-server`), `aj.oauth.client-secret`
  - Publishes itself at `aj.mcp.base-url` (default `https://kuba-mcp.labs-skillpanel.com`)
  - Security config: `mcp-server/src/main/java/pl/devstyle/aj/mcp/config/SecurityConfig.java`

## Data Storage

**Databases:**
- PostgreSQL 18 (primary application DB)
  - Connection: standard Spring `spring.datasource.*` (not overridden in `application.properties`; defaults expected to match `compose.yml` service `postgres`, db/user/pass `aj`/`aj`/`aj`, port 5432)
  - Client: dual JPA (`spring-boot-starter-data-jpa`) + jOOQ (`spring-boot-starter-jooq`) — JPA for entity CRUD, jOOQ for complex/typed reads (per `.maister/docs/standards/backend/jooq.md`)
  - Migrations: Liquibase, master changelog `src/main/resources/db/changelog/db.changelog-master.yaml`, contexts controlled by `spring.liquibase.contexts=dev`
- PostgreSQL 18 (Langfuse's own DB) — `langfuse-db` service, isolated from app DB
- PostgreSQL 18 (LiteLLM's own DB) — `litellm-db` service, isolated from app DB
- ClickHouse (`clickhouse` service) — Langfuse's analytics/event store

**File Storage:**
- MinIO (S3-compatible, `minio` service, ports 9010/9011) — used exclusively by Langfuse for event upload storage (`LANGFUSE_S3_EVENT_UPLOAD_*` env vars in `compose.yml`); bucket auto-created by `minio-setup` init container
- No direct application file storage integration detected outside the Langfuse stack

**Caching:**
- Redis 7 (`redis` service, port 6379) — used by Langfuse only (`REDIS_CONNECTION_STRING`); no direct application-level caching integration detected

## Authentication & Identity

**Auth Provider:**
- Custom, self-hosted — no third-party IdP (e.g. Auth0/Okta/Cognito) detected
  - JWT issuance/validation: `src/main/java/pl/devstyle/aj/core/security/JwtTokenProvider.java`, `JwtAuthenticationFilter.java`, `SecurityConfiguration.java` — secret via `app.jwt.secret` (env `APP_JWT_SECRET`), 24h expiration (`app.jwt.expiration-ms=86400000`)
  - Custom OAuth2 Authorization Server built on `spring-security-oauth2-authorization-server`: `src/main/java/pl/devstyle/aj/core/oauth2/` — `DatabaseRegisteredClientRepository.java`, `RegisteredClientEntity.java`/`RegisteredClientJpaRepository.java`, `AuthorizationCodeService.java`, `RefreshTokenService.java`, `OAuth2AuthorizationFilter.java`, `OAuth2TokenFilter.java`, `OAuth2IntrospectionFilter.java`, `OAuth2ClientAuthenticator.java`, `PublicClientRegistrationFilter.java`, `OAuth2MetadataController.java`
  - Login endpoint: `src/main/java/pl/devstyle/aj/api/AuthController.java`
  - Consumed by the MCP server as an OAuth2 client (see `mcp-server/src/main/resources/application.yml`, `aj.oauth.*`) and by plugins via the host bridge pattern (`hostApp.getToken()` / `postMessage`, per `plugins/CLAUDE.md` and `.maister/docs/standards/backend/plugin-auth.md`)

## Monitoring & Observability

**Error Tracking:**
- No dedicated error-tracking service (e.g. Sentry) detected

**Logs:**
- Standard Spring Boot logging; `mcp-server/src/main/resources/application.yml` sets DEBUG level for `pl.devstyle`, `org.springframework.security`, `io.modelcontextprotocol`
- LLM-specific tracing/observability handled by Langfuse (see above), not general app logs

## CI/CD & Deployment

**Hosting:**
- Not yet determined — no Dockerfile for the main app or CI deployment config found in this scan
- Reference non-local URLs appear only as MCP defaults: `https://kuba-app.labs-skillpanel.com` (host/OAuth server), `https://kuba-mcp.labs-skillpanel.com` (MCP server) — likely a staging/labs environment

**CI Pipeline:**
- Not detected (no `.github/workflows`, `.gitlab-ci.yml`, or similar found)

## Environment Configuration

**Required env vars (host app, `src/main/resources/application.properties`):**
- `APP_JWT_SECRET` — JWT signing secret (has an insecure default checked into properties; must be overridden in production)

**Required env vars (`mcp-server/src/main/resources/application.yml`):**
- `AJ_BACKEND_URL`, `AJ_OAUTH_SERVER_URL`, `AJ_OAUTH_CLIENT_ID`, `AJ_OAUTH_CLIENT_SECRET`, `AJ_MCP_BASE_URL`

**Required env vars (`plugins/ai-description`):**
- `LITELLM_API_KEY` — consumed by BAML client (`baml_src/clients.baml`) to authenticate against the local LiteLLM proxy

**Secrets location:**
- Host app JWT secret: `src/main/resources/application.properties` (default value present — not a real secret, needs env override)
- LiteLLM upstream provider keys: `litellm/.env` (external file referenced by `compose.yml`, not committed to this repo)
- Langfuse/MinIO/Postgres/ClickHouse credentials: hardcoded plaintext defaults directly in `compose.yml` (dev-only, e.g. `POSTGRES_PASSWORD: aj`, `MINIO_ROOT_PASSWORD: minioadmin`) — not suitable for production as-is

## Webhooks & Callbacks

**Incoming:**
- None detected — no inbound webhook endpoints found

**Outgoing:**
- None detected — plugin-to-host communication uses `postMessage` RPC (iframe-based, in-browser) rather than webhooks; see `plugins/CLAUDE.md` for the Plugin SDK (`thisPlugin`, `hostApp.fetch` restricted to `/api/` paths, credentials stripped, path traversal rejected)

---

*Integration audit: 2026-08-16*
