# Codebase Structure

**Analysis Date:** 2026-08-16

## Directory Layout

```
architekt-jutra-code/
├── pom.xml                       # Root Maven build: core Spring Boot app + frontend build
├── src/
│   ├── main/
│   │   ├── java/pl/devstyle/aj/  # Core backend application (see below)
│   │   ├── resources/
│   │   │   ├── application.properties
│   │   │   ├── db/changelog/     # Liquibase migrations
│   │   │   └── static/           # Built frontend output (generated, do not hand-edit)
│   │   └── frontend/              # React/TypeScript SPA (own package.json, Vite)
│   │       └── src/               # SPA source (see below)
│   └── test/java/pl/devstyle/aj/ # Backend integration/unit tests, mirrors main package layout
├── mcp-server/                    # Separate Maven module: standalone MCP (Model Context Protocol) server
│   ├── pom.xml
│   └── src/{main,test}/java/pl/devstyle/aj/mcp/
├── week9/AJ-dotnet/               # Standalone .NET exploration of carbon-footprint domain (not wired into main app)
├── .maister/                      # Maister AI SDLC framework: docs, standards, task history
│   ├── docs/
│   │   ├── INDEX.md               # Documentation index — read first
│   │   ├── project/               # tech-stack.md, architecture.md (project-level docs)
│   │   └── standards/             # backend/, frontend/, global/, testing/ coding standards
│   └── tasks/development/         # Per-task planning/implementation/verification artifacts
├── .planning/                     # GSD codebase mapping output (this directory)
├── .idea/                         # IntelliJ IDEA project files
└── .git/
```

## Directory Purposes

**`src/main/java/pl/devstyle/aj/`:**
- Purpose: core Spring Boot application source
- Contains: package-by-feature domain modules plus a shared `core/` package
- Key subpackages:
  - `api/` — cross-cutting REST controllers (auth, health, SPA forwarding)
  - `category/` — Category CRUD (Controller/Service/Repository/Entity/DTOs)
  - `product/` — Product CRUD + jOOQ read queries
  - `user/` — User entity, permissions, repository (backs Spring Security)
  - `footprint/` — Carbon footprint calculation/reporting domain
  - `archetype/pricing/` — Composable pricing calculator (Composite pattern)
  - `core/` — shared infrastructure: `security/`, `oauth2/`, `plugin/`, `error/`, `BaseEntity.java`, `JpaAuditingConfig.java`

**`src/test/java/pl/devstyle/aj/`:**
- Purpose: backend tests, package-mirrors `src/main/java` structure
- Contains: `*IntegrationTests.java`, `*ValidationTests.java`, TestContainers config (`TestcontainersConfiguration.java`), custom security test annotations (`WithMockAdminUser.java`, `WithMockEditUser.java`)

**`src/main/resources/db/changelog/2026/`:**
- Purpose: Liquibase migrations, one YAML file per schema change, numerically prefixed (001–011)
- Key files: `001-create-categories-table.yaml` through `011-create-footprint-audit-log.yaml`
- Master file: `src/main/resources/db/changelog/db.changelog-master.yaml`

**`src/main/resources/static/`:**
- Purpose: built frontend assets served by Spring Boot
- Generated: Yes (produced by `frontend-maven-plugin` running `npm run build` in `src/main/frontend`)
- Committed: contains build output (`index.html`, `assets/*.js`, `plugin-sdk.js`) — do not hand-edit; edit `src/main/frontend/src/` instead

**`src/main/frontend/`:**
- Purpose: React + TypeScript + Vite single-page app, self-contained npm project
- Contains: `src/` (app source), `node_modules/` (git-ignored), own `package.json`/`vite.config`
- Key subdirectories under `src/main/frontend/src/`:
  - `api/` — typed HTTP client functions per domain (`client.ts`, `categories.ts`, `products.ts`, `footprints.ts`, `plugins.ts`, `problem.ts`)
  - `auth/` — `AuthContext.tsx`, `AuthGuard.tsx`
  - `components/` — `layout/` (AppShell, Header, Sidebar, MobileDrawer), `shared/` (ConfirmDialog, EmptyState, PrimaryButton, Icons), `footprint/` (BreakdownTree, CsvExportButton, ScopeBar, ScopeChip)
  - `hooks/` — data-fetching hooks per domain (`useCategories.ts`, `useProducts.ts`, `useProductFootprint.ts`, `useFootprintComparison.ts`)
  - `pages/` — route-level components (`ProductListPage.tsx`, `CategoryFormPage.tsx`, `LoginPage.tsx`, `PluginListPage.tsx`, `CarbonFootprintLandingPage.tsx`, etc.)
  - `plugin-sdk/` — browser SDK plugins import to talk to the host app (`host-app.ts`, `messaging.ts`, `this-plugin.ts`, `types.ts`)
  - `plugins/` — host-side plugin runtime (`PluginFrame.tsx`, `PluginContext.tsx`, `PluginMessageHandler.ts`, `iframeRegistry.ts`, `extensionPoints.ts`, `PluginFilterBar.tsx`)
  - `theme/` — Chakra UI theme config (`index.ts`)
  - `utils/` — helpers (`url.ts`, `download.ts`, `format.ts`, `scenarioUrl.ts`)
  - `test/` — Vitest test files, flat directory, one file per feature/page (`*.test.tsx`, `*.test.ts`)
  - `router.tsx`, `main.tsx` — app entry/routing

**`mcp-server/`:**
- Purpose: standalone Spring Boot module exposing the core app's product/category functionality as MCP (Model Context Protocol) tools for AI agents
- Contains: `client/` (HTTP client + DTOs calling core app), `config/` (Jackson, RestClient, Security), `controller/` (`WellKnownController`), `security/` (OAuth2 token exchange/introspection), `service/` (CategoryService, ProductService — thin wrappers over `client/`)
- Note: separate Maven module with its own `pom.xml`; runs as an independent process from the core app

**`week9/AJ-dotnet/`:**
- Purpose: standalone .NET 9-style class library exploring carbon-footprint domain logic (Component Tree, Emission Measurement, Footprint Reporting) with xUnit tests
- Generated: No (hand-written)
- Committed: Yes, but not built/referenced by the Java Maven build — treat as a design spike, not production code

**`.maister/docs/`:**
- Purpose: AI SDLC framework documentation — project docs and team coding standards
- Contains: `INDEX.md` (read first), `project/` (architecture.md, tech-stack.md — currently stale, see ARCHITECTURE.md Anti-Patterns), `standards/{backend,frontend,global,testing}/`

**`.maister/tasks/development/`:**
- Purpose: historical per-task planning/implementation/verification artifacts (analysis, implementation plans, spec, work-log, verification reports, screenshots) for completed feature work
- Example: `.maister/tasks/development/2026-03-28-ecommerce-product-management/`, `.maister/tasks/development/2026-03-28-microkernel-skeleton-app/`

## Key File Locations

**Entry Points:**
- `src/main/java/pl/devstyle/aj/AjApplication.java`: core Spring Boot app bootstrap
- `mcp-server/src/main/java/pl/devstyle/aj/mcp/AjMcpApplication.java`: MCP server bootstrap
- `src/main/frontend/src/main.tsx`: SPA bootstrap

**Configuration:**
- `src/main/resources/application.properties`: core app Spring config
- `pom.xml` (root): backend build, jOOQ codegen, frontend-maven-plugin wiring
- `mcp-server/pom.xml`: MCP server module build
- `src/main/frontend/` (package.json/vite config, not enumerated individually): frontend build config

**Core Logic:**
- `src/main/java/pl/devstyle/aj/core/security/SecurityConfiguration.java`: single `SecurityFilterChain`
- `src/main/java/pl/devstyle/aj/core/oauth2/`: OAuth2 Authorization Server implementation
- `src/main/java/pl/devstyle/aj/core/plugin/`: plugin registry + generic entity extension mechanism
- `src/main/resources/db/changelog/db.changelog-master.yaml`: Liquibase migration entrypoint

**Testing:**
- `src/test/java/pl/devstyle/aj/`: backend tests (JUnit 5, TestContainers, MockMvc)
- `mcp-server/src/test/java/pl/devstyle/aj/mcp/`: MCP server tests
- `src/main/frontend/src/test/`: frontend tests (Vitest + Testing Library)
- `week9/AJ-dotnet/tests/FootprintCalculation.Tests/`: .NET xUnit tests (spike module)

## Naming Conventions

**Files:**
- Java: PascalCase, one public class per file, suffixed by role — `*Controller.java`, `*Service.java`, `*Repository.java`, `*Request.java`/`*Response.java`, `Db*QueryService.java` for jOOQ read services
- Java tests: `*IntegrationTests.java`, `*ValidationTests.java`, `*Tests.java` — package-private, same package as production code (per `.maister/docs/standards/testing/backend-testing.md`)
- TypeScript components: PascalCase `.tsx` (e.g. `ProductListPage.tsx`); non-component modules: camelCase `.ts` (e.g. `useProducts.ts`, `format.ts`)
- Frontend tests: `*.test.tsx` / `*.test.ts`, all under flat `src/test/` directory (not co-located with source)
- Liquibase changelogs: zero-padded numeric prefix + kebab-case description, e.g. `007-add-entity-binding-to-plugin-objects.yaml`

**Directories:**
- Backend: package-by-feature (`category/`, `product/`, `user/`, `footprint/`), shared code isolated in `core/`
- Frontend: role-based (`pages/`, `components/`, `hooks/`, `api/`, `utils/`), with domain-specific subfolders inside `components/` (e.g. `components/footprint/`)

## Where to Add New Code

**New Backend Feature/Domain:**
- Create a new top-level package under `src/main/java/pl/devstyle/aj/<domain>/` containing `<Domain>Controller.java`, `<Domain>Service.java`, `<Domain>Repository.java`, `<Domain>.java` (entity), `Create<Domain>Request.java`/`Update<Domain>Request.java`/`<Domain>Response.java`
- Add a Liquibase changeset in `src/main/resources/db/changelog/2026/NNN-<description>.yaml` and register it in `db.changelog-master.yaml`
- Add tests in `src/test/java/pl/devstyle/aj/<domain>/` mirroring the package, following `.maister/docs/standards/testing/backend-testing.md`

**New Frontend Page/Feature:**
- Page component: `src/main/frontend/src/pages/<Name>Page.tsx`
- Route registration: `src/main/frontend/src/router.tsx`
- API calls: add to or create `src/main/frontend/src/api/<domain>.ts`
- Data hook: `src/main/frontend/src/hooks/use<Domain>.ts`
- Shared UI: `src/main/frontend/src/components/shared/` (generic) or `src/main/frontend/src/components/<domain>/` (feature-specific)
- Test: `src/main/frontend/src/test/<Name>.test.tsx`

**New Plugin Extension Point (host side):**
- Extend `src/main/frontend/src/plugins/extensionPoints.ts` and wire through `PluginContext.tsx`/`PluginFrame.tsx`
- Backend metadata/registration: `src/main/java/pl/devstyle/aj/core/plugin/PluginDescriptorService.java`

**Utilities:**
- Backend shared helpers: `src/main/java/pl/devstyle/aj/core/` (only if genuinely cross-domain; otherwise keep in the owning domain package)
- Frontend shared helpers: `src/main/frontend/src/utils/`

**New MCP Tool:**
- Add client DTO/method in `mcp-server/src/main/java/pl/devstyle/aj/mcp/client/` and expose via a `service/*Service.java`
- Tests: `mcp-server/src/test/java/pl/devstyle/aj/mcp/`

## Special Directories

**`src/main/resources/static/`:**
- Purpose: compiled frontend bundle served by Spring Boot at runtime
- Generated: Yes (via `mvn package`/`generate-resources` phase, `frontend-maven-plugin`)
- Committed: Yes (build artifacts are checked in per current repo state) — avoid manual edits, they will be overwritten on next build

**`src/main/frontend/node_modules/`:**
- Purpose: npm dependencies for the SPA
- Generated: Yes
- Committed: No (gitignored)

**`target/generated-sources/jooq/`:**
- Purpose: jOOQ type-safe query classes generated from the live (Testcontainers-provisioned) schema at build time
- Generated: Yes (`testcontainers-jooq-codegen-maven-plugin`, phase `generate-sources`)
- Committed: No

**`.maister/tasks/development/`:**
- Purpose: historical record of completed feature planning/implementation/verification cycles (Maister AI SDLC framework), includes UAT screenshots
- Generated: Partially (reports generated by the maister workflow, but represent real project history)
- Committed: Yes — do not delete, useful as historical reference for conventions actually applied

**`week9/AJ-dotnet/.agent/`, `week9/AJ-dotnet/noesis/`:**
- Purpose: AI-agent design-decision/conversation logs (JSON) tied to the .NET footprint-calculation spike
- Generated: Yes (agent tooling output)
- Committed: Yes

---

*Structure analysis: 2026-08-16*
