# Coding Conventions

**Analysis Date:** 2026-08-16

## Naming Patterns

**Files (Java, backend `src/main/java/pl/devstyle/aj/`):**
- One public type per file, `PascalCase` matching the class/interface/enum/record name: `CategoryService.java`, `PluginObjectController.java`
- Package per domain/module (feature-based, not layer-based): `category/`, `product/`, `user/`, `core/plugin/`, `core/oauth2/`, `core/security/`, `core/error/`

**Files (frontend `src/main/frontend/src/`):**
- Components/pages: `PascalCase.tsx` (`CategoryListPage.tsx`, `ProductFormPage.tsx`, `PluginFrame.tsx`)
- Non-component modules: `camelCase.ts` (`extensionPoints.ts`, `iframeRegistry.ts`) or lowercase (`context.ts`, `types.ts`, `messaging.ts`)
- API clients grouped by resource in `src/api/` (`categories.ts`, `products.ts`, `plugins.ts`)
- Hooks prefixed `use`: `useCategories.ts`, `useProducts.ts`

**Java classes:**
- Request/response DTOs are Java `record`s named `CreateXRequest`, `UpdateXRequest`, `XResponse` — see `src/main/java/pl/devstyle/aj/category/CreateCategoryRequest.java`, `CategoryResponse.java`
- Services: `XService`, one per domain (`CategoryService.java`, `ProductService.java`, `PluginObjectService.java`)
- Controllers: `XController`, thin, delegate to service (`CategoryController.java`, `ProductController.java`)
- Repositories: `XRepository extends JpaRepository<...>` (`CategoryRepository.java`)
- Custom exceptions: `XException` extending a typed base (`CategoryHasProductsException`, `EntityNotFoundException`, `BusinessConflictException`)
- Query services for read-heavy/authorization paths: `DbXQueryService` (`DbProductQueryService.java`, `DbPluginObjectQueryService.java`) per jOOQ standards

**Variables/methods:**
- `camelCase` throughout Java and TypeScript
- Java local variables use `var` extensively (`var category = new Category();`)
- Boolean-returning/checking methods read naturally (`isEnabled`, `hasProducts` pattern implied by `CategoryHasProductsException`)

**Types (TypeScript):**
- `PascalCase` for types/interfaces: `CategoryResponse`, `ProductResponse` (`src/main/frontend/src/api/categories.ts`, `products.ts`)
- Response DTO shapes mirror backend record field names exactly (id, name, description, createdAt, updatedAt)

## Code Style

**Backend (Java 25 / Spring Boot 4):**
- 4-space indentation, opening brace on same line
- Constructor injection only — no field `@Autowired` (see `CategoryService(CategoryRepository categoryRepository)`)
- Records for immutable request/response DTOs
- Static factory methods for DTO conversion: `CategoryResponse.from(entity)`
- Method chaining with `.stream()...toList()` (Java 16+ `toList()`, not `.collect(Collectors.toList())`)
- No Lombok `@Data`/`@EqualsAndHashCode` on entities — use `@Getter`/`@Setter`/`@NoArgsConstructor` (per `.maister/docs/standards/backend/models.md`)

**Frontend (React 19 / TypeScript / Vite):**
- ESLint config at `src/main/frontend/eslint.config.js`
- npm scripts: `lint` (`eslint .`), `build` (`tsc -b && vite build`), `test` (`vitest run`), `test:watch` (`vitest`) — see `src/main/frontend/package.json`
- Functional components, hooks-based state management (no class components observed)
- Chakra UI v3 for component library (`ChakraProvider`, `system` theme object)

## Import Organization

**Java:**
- Package declaration, then imports grouped: `org.springframework.*` framework imports first, then `pl.devstyle.aj.*` internal imports, then `java.*` standard library — observed order varies slightly but framework/internal/stdlib grouping is consistent (see `GlobalExceptionHandler.java`)
- Static imports for MockMvc matchers in tests: `import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;`

**TypeScript:**
- External libraries first (`react`, `@testing-library/*`, `vitest`), then internal relative imports (`../theme`, `../api/categories`)
- `type` imports separated with `import type { CategoryResponse } from "../api/categories";`
- Namespace imports for API modules under test: `import * as categoriesApi from "../api/categories";`

## Error Handling

**Backend:**
- Centralized handling via `@RestControllerAdvice` — `src/main/java/pl/devstyle/aj/core/error/GlobalExceptionHandler.java`
- Typed domain exceptions: `EntityNotFoundException`, `BusinessConflictException`, `CategoryHasProductsException` (`src/main/java/pl/devstyle/aj/core/error/`, `src/main/java/pl/devstyle/aj/category/`)
- Standard `ErrorResponse` shape: status code, reason phrase, message, optional field-errors map, timestamp (`src/main/java/pl/devstyle/aj/core/error/ErrorResponse.java`)
- Services throw `EntityNotFoundException` via `.orElseThrow(() -> new EntityNotFoundException("Category", id))` pattern
- Database constraint violations (`DataIntegrityViolationException`) caught at service boundary and re-thrown as domain-specific conflict exceptions, e.g. `CategoryService.delete()` catches on `categoryRepository.delete()` and throws `CategoryHasProductsException`
- Unexpected exceptions logged via SLF4J at `ERROR` and mapped to generic 500 response without leaking internals (`handleUnexpectedException` in `GlobalExceptionHandler.java`)
- Validation errors (`MethodArgumentNotValidException`) mapped to 400 with per-field error map

**Frontend:**
- API errors surfaced via hooks (`useCategories.ts`, `useProducts.ts`) — check these files before adding new API error paths

## Comments

Comment sparingly; let naming and structure communicate intent (per `.maister/docs/standards/global/commenting.md`). No changelog-style comments in code — commit history carries that. Source files inspected (`CategoryService.java`, `GlobalExceptionHandler.java`) contain no inline comments, relying entirely on descriptive naming.

## Function Design

**Backend:**
- Service methods are short (5-15 lines), each handling one CRUD operation, wrapped in `@Transactional` or `@Transactional(readOnly = true)`
- Controllers are thin pass-through layers to services (verify in `CategoryController.java`, `ProductController.java`)

**Frontend:**
- Components kept single-responsibility; shared UI in `src/main/frontend/src/components/shared/` (`ConfirmDialog.tsx`, `EmptyState.tsx`, `PrimaryButton.tsx`)

## Module Design

**Backend package structure:** Feature/domain packages (`category`, `product`, `user`) each self-contained with entity, controller, service, repository, DTOs. Shared/cross-cutting concerns in `core/` (`core/error`, `core/security`, `core/oauth2`, `core/plugin`).

**Frontend module structure:**
- `src/api/` — HTTP client functions per resource
- `src/hooks/` — data-fetching hooks wrapping API calls
- `src/pages/` — route-level components
- `src/components/` — reusable UI (`layout/`, `shared/`)
- `src/plugin-sdk/` — SDK surface consumed by plugin iframes (`context.ts`, `host-app.ts`, `messaging.ts`, `this-plugin.ts`, `types.ts`)
- `src/plugins/` — host-side plugin management (`PluginContext.tsx`, `PluginFrame.tsx`, `iframeRegistry.ts`)
- Separate plugin packages live outside the main frontend at repo root: `plugins/ai-description/`, `plugins/box-size/`, `plugins/warehouse/`, each with their own `domain.ts`, `main.tsx`/pages, and (for `ai-description`) `src/__tests__/`

## Documentation Standards Reference

Full standards catalog: `.maister/docs/INDEX.md`. Key files consulted for this analysis:
- `.maister/docs/standards/global/coding-style.md`
- `.maister/docs/standards/global/error-handling.md`
- `.maister/docs/standards/global/commenting.md`
- `.maister/docs/standards/global/conventions.md`
- `.maister/docs/standards/global/minimal-implementation.md`
- `.maister/docs/standards/backend/models.md` (JPA entity modeling — BaseEntity, SEQUENCE ids, LAZY fetch, business-key equals/hashCode)
- `.maister/docs/standards/backend/api.md` (RESTful naming, plural nouns, versioning)
- `.maister/docs/standards/backend/security.md` (JWT + centralized SecurityFilterChain, no `@PreAuthorize`)

---

*Convention analysis: 2026-08-16*
