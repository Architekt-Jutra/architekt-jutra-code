# aj — Microkernel Platform

A Spring Boot host application that loads independently-developed **plugins**. Plugins are standalone Vite/React apps rendered in iframes; they talk to the host over a postMessage RPC bridge and store their data in host-owned JSONB columns and tables.

## Commands

```bash
./start-dev.sh                       # Postgres + host app + all plugins (Ctrl+C stops everything)

./mvnw spring-boot:run               # Host app only (auto-starts Postgres via spring-boot-docker-compose)
./mvnw test                          # Full backend suite (TestContainers → real PostgreSQL 18)
./mvnw test -Dtest='ProductIntegrationTests'
./mvnw -DskipTests compile

# Skip jOOQ codegen when the schema hasn't changed — it spins up a throwaway Postgres container each build
./mvnw -DskipTests -Dskip.jooq.generation=true compile

cd src/main/frontend && npm run dev   # Host UI on :5173, proxies /api → :8080
cd src/main/frontend && npm test      # Vitest
cd src/main/frontend && npm run lint
cd plugins/warehouse && npm run dev    # Plugin dev servers: warehouse :3001, box-size :3002
```

Java 25 is the release target; the build also runs fine on a newer JDK.

## Layout

```
src/main/java/pl/devstyle/aj/
  core/           BaseEntity, JpaAuditingConfig
  core/plugin/    Plugin registry, per-product plugin data, plugin-owned objects
  core/error/     GlobalExceptionHandler, typed exceptions, ErrorResponse
  product/        Product domain (JPA writes + jOOQ reads)
  category/       Category domain
  api/            HealthController, SpaForwardController
src/main/frontend/
  plugin-sdk/     SDK source → built as an IIFE to /assets/plugin-sdk.js for plugins
  plugins/        Host side of the bridge: PluginFrame, PluginMessageHandler, extension points
  pages/ components/ api/ hooks/ theme/
  test/           Vitest specs
src/main/resources/db/changelog/2026/   Liquibase changesets (includeAll, numbered)
plugins/          Independent plugin apps — see plugins/CLAUDE.md
```

`src/main/resources/static/` is build output (gitignored). Never edit it — change `src/main/frontend/` and rebuild.

## Plugin architecture

Read `plugins/CLAUDE.md` before touching anything under `plugins/` or `src/main/frontend/src/plugin-sdk/`. It is the contract document: extension point types, SDK API, manifest format, shared CSS classes.

Key points for host-side work:

- A plugin registers by `PUT /api/plugins/{pluginId}/manifest`. The manifest is the single source of truth for extension points; the host stores it as JSONB on the `plugins` table (`PluginDescriptor`, keyed by the natural string pluginId).
- Extension points: `menu.main`, `product.detail.tabs`, `product.detail.info`, `product.list.filters`. The filter type is rendered natively by the host from manifest metadata — no iframe involved.
- Plugin data lives in two places: the `products.plugin_data` JSONB column namespaced by pluginId, and the `plugin_objects` table for plugin-owned collections (optionally bound to a `PRODUCT`/`CATEGORY` entity).
- Changing the SDK surface means changing three things in step: `src/main/frontend/src/plugin-sdk/`, the shared type declarations in `plugins/sdk.ts`, and the docs in `plugins/CLAUDE.md`.

## Backend conventions

- **Reads vs writes**: JPA repositories for CRUD; jOOQ (`Db*QueryService`) for filtered/joined reads. jOOQ classes are generated into `pl.devstyle.aj.jooq` from the Liquibase changelog at `generate-sources` — regenerate after every schema change.
- **Controllers** are thin: `@RestController` on `/api/<plural-noun>`, constructor injection, `@Valid` on request bodies, delegate to a service. Requests/responses are records (`CreateProductRequest`, `ProductResponse`).
- **Migrations**: add a numbered YAML changeset under `db/changelog/2026/`. It's picked up by `includeAll` — never edit an applied changeset.

## Frontend conventions

- React 19 + TypeScript, Chakra UI v3, React Router v7 (routes centralized in `src/router.tsx`).
- Pages in `pages/`, layout in `components/layout/`, reusable pieces in `components/shared/`, HTTP in `api/`, data fetching in `hooks/`.
- Style with Chakra tokens (`gray.900`, `gray.200`) — not raw hex values.
- Icons come from `lucide-react`; plugin manifest icon names are kebab-case Lucide names.

## Rules

`.claude/rules/` holds the coding standards, loaded automatically when you touch matching files:

- `code-craft.md` — always loaded
- `jpa-entities.md`, `jooq-queries.md` — `src/main/java/**`
- `backend-testing.md` — `src/test/java/**`
- `frontend-testing.md` — `src/main/frontend/**`
