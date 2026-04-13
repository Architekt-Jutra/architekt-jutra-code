# AGENTS.md — Coding Agent Reference

**Project**: `aj` — a plugin-based microkernel platform built on Spring Boot 4.0.5 + Java 25 with a React/TypeScript frontend. Pre-alpha; business logic and plugin framework are still being scaffolded.

---

## Build & Run Commands

### Backend (Maven Wrapper — run from repo root)

```bash
./mvnw package                              # Full build (compiles, tests, packages)
./mvnw package -DskipTests                  # Build without tests
./mvnw package -Dskip.jooq.generation=true  # Skip jOOQ codegen (faster local builds)
./mvnw test                                 # Run all tests
./mvnw spring-boot:run                      # Start the application
```

> On Windows use `mvnw.cmd` instead of `./mvnw`.

#### Run a single test class or method

```bash
./mvnw test -Dtest=CategoryIntegrationTests
./mvnw test -Dtest=CategoryIntegrationTests#createCategory_returns201WithCategoryResponse
./mvnw test -Dtest="CategoryIntegrationTests,ProductValidationTests"
```

### Frontend (npm — run from `src/main/frontend`)

```bash
npm install          # Install dependencies
npm run dev          # Dev server (Vite)
npm run build        # Type-check + production build
npm run lint         # ESLint
npm test             # Run tests once (Vitest)
npm run test:watch   # Watch mode
```

#### Run a single frontend test file

```bash
npx vitest run src/test/CategoryPage.test.tsx
npx vitest run --reporter=verbose src/test/SomePage.test.tsx
```

### Docker Compose (dev database)

```bash
docker compose up -d   # Start PostgreSQL for local development
```

---

## Project Structure

```
src/main/java/pl/devstyle/aj/
├── AjApplication.java          # Spring Boot entry point
├── api/                        # Cross-cutting HTTP concerns (health, SPA forward)
├── core/                       # Shared infrastructure (BaseEntity, error handling, plugin core)
│   ├── BaseEntity.java
│   ├── error/                  # GlobalExceptionHandler, typed exceptions, ErrorResponse
│   └── plugin/                 # Plugin descriptor, object, data layers
└── <domain>/                   # One package per bounded context (category, product, …)
    ├── <Domain>.java            # JPA entity
    ├── <Domain>Controller.java
    ├── <Domain>Service.java
    ├── <Domain>Repository.java
    ├── Db<Domain>QueryService.java  # jOOQ read service (complex queries)
    ├── Create<Domain>Request.java
    ├── Update<Domain>Request.java
    └── <Domain>Response.java

src/main/frontend/src/
├── api/          # API client modules
├── components/   # Shared React components
├── hooks/        # Custom hooks
├── pages/        # Page-level components
├── plugin-sdk/   # Plugin SDK (exported via vite.sdk.config.ts)
├── plugins/      # Registered frontend plugins
├── test/         # All test files (*.test.tsx / setup.ts)
└── router.tsx    # React Router config
```

---

## Backend Code Style (Java 25 + Spring Boot)

### General

- Use `var` for local variables whenever the type is obvious from context.
- Prefer Java records for immutable data transfer objects.
- Use `switch` expressions, pattern matching, and sealed classes where they improve clarity.
- No dead code: remove unused imports, commented-out blocks, and orphaned helpers.
- No speculative abstractions — build only what is currently needed.

### Naming

| Element | Convention | Example |
|---|---|---|
| Package | lowercase, domain-based | `pl.devstyle.aj.category` |
| Class | PascalCase, singular | `Category`, `CategoryService` |
| Method | camelCase, verb-first | `createCategory`, `findById` |
| Constant | UPPER_SNAKE_CASE | `MAX_RETRIES` |
| DB table | plural snake_case | `categories`, `plugin_objects` |

### Lombok

Use `@Getter @Setter @NoArgsConstructor` on entities. **Never** use `@Data` or `@EqualsAndHashCode` on JPA entities — they generate broken `equals`/`hashCode` based on entity ID.

### JPA Entities

- Extend `BaseEntity` (`id` Long SEQUENCE, `createdAt` @CreatedDate, `updatedAt` @Version).
- Declare the entity-specific sequence at class level: `@SequenceGenerator(name = "base_seq", sequenceName = "category_seq", allocationSize = 1)`.
- Always `@Enumerated(EnumType.STRING)` — never `ORDINAL`.
- All relationships `fetch = FetchType.LAZY` — override the EAGER defaults on `@OneToOne` and `@ManyToOne`.
- Use `Set<?>` for collections (initialized in field declaration). Avoid bare `List<?>` (Bag semantics, poor performance).
- `equals`/`hashCode` based on **business key** (natural ID), never the generated `@Id`.
- Cross-module references: store a type-safe ID wrapper (e.g., `CategoryId`), not a JPA `@ManyToOne` to an entity in another bounded context.

### jOOQ (Complex Queries)

- Use JPA for CRUD; use jOOQ for complex reads, aggregations, reports, authorization queries.
- Always use generated table/column constants (`CATEGORY.ID`) — never string literals.
- All user input via bind variables (`.eq(value)`, never string concatenation).
- Name dedicated read services `Db*QueryService` (e.g., `DbProductQueryService`).
- Use `EXISTS` instead of `COUNT(*) > 0`; project only needed columns; use `MULTISET` for nested collections (avoids N+1); use `UNION ALL` over `UNION` when duplicates are acceptable.
- Use `var` for step-type variables (don't reference specific `Select*Step` interfaces).

### Error Handling

- Define typed exceptions (`EntityNotFoundException`, `BusinessConflictException`) — never throw raw `RuntimeException`.
- Handle all exceptions centrally in `GlobalExceptionHandler` (`@RestControllerAdvice`).
- Return a consistent `ErrorResponse` (fields: `status`, `error`, `message`) for all error responses.
- Validate inputs early; reject invalid data before it reaches the service layer.
- Use `@Valid` on request bodies in controllers; use Bean Validation annotations on request DTOs.

### REST API

- URL prefix: `/api/`; plural resource nouns: `/api/categories`, `/api/products`.
- HTTP status codes: `201` Created, `200` OK, `204` No Content, `400` Bad Request, `404` Not Found, `409` Conflict.
- Keep URL nesting ≤ 2 levels.

### Database Migrations (Liquibase)

- Migrations live in `src/main/resources/db/changelog/`.
- Each migration = one logical change; descriptive filenames.
- Always implement a rollback; never modify a migration after it has been deployed.

---

## Backend Testing

### Test Infrastructure

```java
@Import(TestcontainersConfiguration.class)
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.MOCK)
@AutoConfigureMockMvc
@Transactional          // auto-rollback after each test
class CategoryIntegrationTests {
```

- **Always** use TestContainers with real PostgreSQL 18 — never mock the database.
- `@Transactional` on the class provides automatic rollback; no manual cleanup needed.

### What NOT to Test

- Spring Data auto-generated repository methods.
- Lombok-generated getters/setters.
- Private methods.

### Naming

- Class: `*IntegrationTests` (CRUD happy paths), `*ValidationTests` (errors, edge cases).
- Class visibility: **package-private** (no `public`).
- Same package as production code.
- Method: `action_condition_expectedResult` with underscores — e.g., `createProduct_withNonExistentCategory_returns404`.

### HTTP Assertions

```java
mockMvc.perform(post("/api/categories")
        .contentType(MediaType.APPLICATION_JSON)
        .content(objectMapper.writeValueAsString(request)))
    .andExpect(status().isCreated())
    .andExpect(jsonPath("$.id").value(notNullValue()));
```

Use MockMvc + `jsonPath()` + Hamcrest for HTTP assertions. Use AssertJ only for non-HTTP assertions.

### Test Data

```java
private Category createAndSaveCategory(String name, String description) {
    var category = new Category();
    category.setName(name);
    category.setDescription(description);
    return categoryRepository.saveAndFlush(category);
}
```

Define `createAndSave*()` helpers per test class. Use `saveAndFlush()`. No shared base-class setup — use `@Import` for infrastructure only.

---

## Frontend Code Style (TypeScript + React)

- **TypeScript strict mode** — no `any`; prefer explicit types on public interfaces.
- ESLint enforces `typescript-eslint` recommended + `react-hooks` + `react-refresh` rules. Fix all lint errors before committing.
- Imports: group by (1) external libs, (2) internal modules; no unused imports.
- Single-responsibility components; configurable via props; no business logic in presentational components.
- Use Chakra UI (`@chakra-ui/react`) for UI primitives; minimize custom CSS.
- State: local `useState`/`useReducer` first; extract to custom hooks when shared.
- API calls are isolated in `src/api/` modules.

## Frontend Testing (Vitest + Testing Library)

```typescript
// vitest.config.ts — globals: true, environment: jsdom
// src/test/setup.ts imports @testing-library/jest-dom/vitest
```

- Test files live in `src/test/`.
- Use `renderWithProviders()` (defined per test file) wrapping `ChakraProvider` + `MemoryRouter`.
- Mock API modules with `vi.mock()` factory functions; call `vi.resetAllMocks()` in `beforeEach`.
- Use `vi.mocked()` for type-safe mock configuration.
- `describe()` blocks named after the page or feature under test.

---

## Key Conventions

- **Read `.maister/docs/INDEX.md`** before starting any task — it indexes all coding standards.
- Standards live in `.maister/docs/standards/`; follow them. If a task conflicts with a standard, ask before proceeding.
- No backward-compatibility shims unless explicitly required.
- Comments only for genuinely non-obvious logic — let naming and structure explain the code.
- Secrets and environment-specific values go in environment variables, never committed.

## Plugin Internals Documentation

The comprehensive reference for all skills, agents, commands, and workflow principles is `plugins/maister/CLAUDE.md`. Read it when working on plugin internals — it documents every skill, agent, orchestrator phase, and workflow principle.

## Skills Available to OpenCode

`opencode.json` loads all skill `SKILL.md` files from `C:/source/maister/plugins/maister-copilot/skills/` as instructions. OpenCode sessions in this repo automatically have access to the following skills:

| Skill | Purpose |
|-------|---------|
| `development` | Unified workflow (features, bugs, enhancements) |
| `research` | Multi-source research with synthesis and solution design |
| `performance` | Bottleneck detection and optimization |
| `migration` | Code/data/architecture migrations |
| `product-design` | Interactive product/feature design |
| `quick-bugfix` | TDD-driven quick bug fix |
| `implementation-verifier` | QA orchestrator (completeness, tests, review) |
| `implementation-plan-executor` | Executes implementation plan step by step |
| `codebase-analyzer` | Parallel codebase exploration and analysis |
| `standards-discover` | Discovers coding standards from config and code |
| `standards-update` | Adds or refines standards from conversation |
| `init` | Initializes `.maister/docs/` with project analysis |
| `orchestrator-framework` | Shared patterns for all orchestrators |

These are the **Copilot CLI variants** (from `maister-copilot/`) — they use `ask_user` instead of `AskUserQuestion` and sequential single-select instead of multi-select. Edit source skills in `C:/source/maister/plugins/maister/skills/` and run `make build` to regenerate.

## Key Constraints from Plugin Code

- **Never auto-rollback** without user confirmation. Always use `AskUserQuestion` with rollback as a user choice, not an automatic action.
- **All workflow artifacts** must be saved under `.maister/tasks/[type]/[task-name]/` — never to project dirs like `docs/` or `src/`.
- Commands are categorized: workflow commands (`development`, `performance`, etc.), review commands (`reviews-*`), quick commands (`quick-*`).
- The `docs-manager` skill is internal only — invoke it via the `docs-operator` agent (Task tool), never directly from user commands.
