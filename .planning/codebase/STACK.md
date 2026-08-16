# Technology Stack

**Analysis Date:** 2026-08-16

## Languages

**Primary:**
- Java 25 - Backend (host application, MCP server) — `pom.xml`, `mcp-server/pom.xml`
- TypeScript 5.9 - Frontend host app, plugin apps, MCP client tooling

**Secondary:**
- YAML - Liquibase changelogs, Spring config, Docker Compose
- SQL - jOOQ-generated queries, Liquibase migrations

## Runtime

**Environment:**
- JVM 25 (host app and `mcp-server` module both target `<java.version>25</java.version>`)
- Node.js v22.14.0 (pinned by `frontend-maven-plugin` in `pom.xml` for the host frontend build)

**Package Manager:**
- Maven (host app `pom.xml`, `mcp-server/pom.xml`) via Maven Wrapper (`mvnw`/`mvnw.cmd`)
- npm — separate `package.json` per frontend workspace: `src/main/frontend/package.json` (host UI), and one per plugin (`plugins/warehouse`, `plugins/box-size`, `plugins/logistics`, `plugins/product-validator`, `plugins/ai-description`)
- Lockfiles: npm `package-lock.json` present per plugin/frontend directory

## Frameworks

**Core (Backend — host app, `pom.xml`):**
- Spring Boot 4.0.5 (parent BOM)
  - `spring-boot-starter-webmvc` — REST API
  - `spring-boot-starter-data-jpa` — ORM
  - `spring-boot-starter-jooq` — type-safe SQL for reads
  - `spring-boot-starter-liquibase` — schema migrations
  - `spring-boot-starter-security` + `spring-security-oauth2-authorization-server` — auth (custom JWT + OAuth2 authorization server, see `src/main/java/pl/devstyle/aj/core/security/`, `src/main/java/pl/devstyle/aj/core/oauth2/`)
  - `spring-boot-docker-compose` (optional) — auto-boots `compose.yml` in dev

**Core (Backend — `mcp-server` module, `mcp-server/pom.xml`):**
- Spring Boot 4.0.5 + `mcp-spring-webmvc` (Model Context Protocol SDK 0.18.1) — exposes AJ platform as an MCP server
- `spring-boot-starter-web`, `spring-boot-starter-actuator`, `spring-boot-starter-security`

**Core (Frontend — host UI, `src/main/frontend/`):**
- React 19.2.4 + React DOM 19.2.4
- React Router DOM 7.13.2
- Chakra UI 3.34.0 (`@chakra-ui/react`) — component library
- Lucide React 1.7.0 — icons
- Vite 8.0.1 — dev server / build (two configs: `vite.config.ts` for app, `vite.sdk.config.ts` for the plugin SDK bundle served at `/assets/plugin-sdk.js`)
- TypeScript 5.9.3

**Core (Plugins — `plugins/*`):**
- Standalone Vite + React + TypeScript apps (`plugins/warehouse`, `plugins/box-size`, `plugins/logistics`, `plugins/product-validator`) that run in iframes and talk to the host via a shared SDK (`plugins/sdk.ts`)
- `plugins/ai-description` is a Next.js 15.3.3 app (not Vite) using BoundaryML BAML (`@boundaryml/baml` 0.220.0) for structured LLM prompting

**Testing:**
- JUnit 5 (Jupiter) + Spring Boot Test — backend unit/integration tests
- TestContainers (`spring-boot-testcontainers`, `testcontainers-postgresql`, `testcontainers-junit-jupiter`) — real PostgreSQL 18 in integration tests
- `com.networknt:json-schema-validator` (test scope, `mcp-server`) — MCP schema validation tests
- Vitest 3.2.4 + Testing Library (`@testing-library/react`, `@testing-library/jest-dom`) + jsdom — host frontend tests (`src/main/frontend`)
- Jest 29.7 + `ts-jest` + `node-mocks-http` — `plugins/ai-description` API route tests

**Build/Dev:**
- `frontend-maven-plugin` 1.15.1 — wires `npm install` + `npm run build` into the Maven `generate-resources` phase for the host frontend
- `testcontainers-jooq-codegen-maven-plugin` 0.0.4 — generates jOOQ sources from a throwaway Postgres 18 container seeded by the Liquibase changelog (`generate-sources` phase, output `target/generated-sources/jooq`, package `pl.devstyle.aj.jooq`)
- `build-helper-maven-plugin` — adds generated jOOQ sources to the compile path
- ESLint 9.39 + `typescript-eslint` 8.57 — frontend linting (host UI)

## Key Dependencies

**Critical:**
- `io.jsonwebtoken:jjwt-api/jjwt-impl/jjwt-jackson` 0.12.6 — JWT issuance/parsing (`src/main/java/pl/devstyle/aj/core/security/JwtTokenProvider.java`)
- `org.springframework.security:spring-security-oauth2-authorization-server` — custom OAuth2 authorization server (`src/main/java/pl/devstyle/aj/core/oauth2/`)
- `org.springframework.retry:spring-retry` 2.0.12 — retry policy for footprint audit listener (`app.footprint.audit.retry.*` in `src/main/resources/application.properties`)
- `io.micrometer:micrometer-core` — metrics
- `org.apache.commons:commons-csv` 1.10.0 — CSV import/export
- `@boundaryml/baml` 0.220.0 — typed LLM function definitions/prompting for the AI description plugin (`plugins/ai-description/baml_src/`)

**Infrastructure:**
- `org.postgresql:postgresql` (runtime) — JDBC driver
- `com.fasterxml.jackson.core:jackson-databind` — JSON (de)serialization, both host app and `mcp-server`
- `com.fasterxml.jackson.datatype:jackson-datatype-jsr310` — Java time support in `mcp-server`
- Lombok 1.18.38 — boilerplate reduction (getters/setters/constructors) across all Java modules

## Configuration

**Environment:**
- Host app: `src/main/resources/application.properties` — `spring.application.name`, JWT secret/expiration (`app.jwt.secret`, env override `APP_JWT_SECRET`), CORS allowed origins (`app.cors.allowed-origins`), Liquibase context (`spring.liquibase.contexts=dev`), footprint module SPI toggle (`app.footprint.adapters=in-memory`) and retry/async pool tuning
- MCP server: `mcp-server/src/main/resources/application.yml` — server port 8081 / management port 9081, `spring.ai.mcp.server.name`, and env-overridable `aj.backend.url`, `aj.oauth.server-url`, `aj.oauth.client-id`, `aj.oauth.client-secret`, `aj.mcp.base-url`
- `.env` file presence not confirmed in root; `plugins/ai-description` reads `LITELLM_API_KEY` via BAML client config (`baml_src/clients.baml`); a separate `litellm/.env` (referenced in `compose.yml`, not present in this repo scan) holds LiteLLM provider keys

**Build:**
- `pom.xml` (host app, multi-plugin Maven build incl. frontend build step)
- `mcp-server/pom.xml` (separate Maven module, standalone Spring Boot app)
- `src/main/frontend/vite.config.ts` and `vite.sdk.config.ts` — host UI + plugin SDK bundle
- Per-plugin `vite.config.ts` (Vite plugins) or Next.js config (`ai-description`)
- `src/main/resources/db/changelog/db.changelog-master.yaml` — Liquibase master changelog, also consumed by the jOOQ codegen Maven plugin

## Platform Requirements

**Development:**
- JDK 25
- Node.js 22.x (auto-installed by `frontend-maven-plugin` for the host build; plugin workspaces expect a compatible local Node/npm)
- Docker (for `spring-boot-docker-compose` auto-launch of `compose.yml`, and for TestContainers-based tests/jOOQ codegen which spins up ephemeral `postgres:18` containers)

**Production:**
- Deployment target not yet determined (no CI/CD or hosting config found)
- PostgreSQL 18 required at runtime (matches `postgres:18` image used in dev `compose.yml` and TestContainers)

---

*Stack analysis: 2026-08-16*
