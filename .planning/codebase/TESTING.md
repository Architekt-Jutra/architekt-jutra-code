# Testing Patterns

**Analysis Date:** 2026-08-16

This project has two independent test stacks: a Java/Spring Boot backend (main app at repo root, plus a separate `mcp-server/` module) and a Vitest/React frontend (`src/main/frontend/`). A small standalone plugin package (`plugins/ai-description/`) also has its own unit tests.

## Test Framework

### Backend (Java — main app and `mcp-server/`)

**Runner:**
- JUnit 5 (Jupiter), run via Maven Surefire
- Config: `pom.xml` (root), `mcp-server/pom.xml`

**Assertion Library:**
- AssertJ (`assertThat(...)`) for non-HTTP assertions (context beans, datasource checks)
- Hamcrest matchers (`notNullValue()`, etc.) inside `jsonPath()` for HTTP body assertions

**Integration Infrastructure:**
- TestContainers with real PostgreSQL 18 — never mock the database. Config bean: `src/test/java/pl/devstyle/aj/TestcontainersConfiguration.java`
- `@ServiceConnection` on the container bean for automatic datasource wiring

**Run Commands:**
```bash
mvn test                     # Run all backend tests (root module)
mvn test -pl mcp-server       # Run mcp-server tests
mvn test -Dtest=CategoryIntegrationTests   # Single class
```

### Frontend (`src/main/frontend/`)

**Runner:**
- Vitest, `globals: true`, `environment: "jsdom"`
- Config: `src/main/frontend/vitest.config.ts`
- Setup file: `src/main/frontend/src/test/setup.ts` (imports `@testing-library/jest-dom/vitest`)

**Libraries:**
- `@testing-library/react` for rendering/querying
- `@testing-library/jest-dom` for extended DOM matchers

**Run Commands (from `src/main/frontend/package.json`):**
```bash
npm run test          # vitest run (single run)
npm run test:watch    # vitest (watch mode)
npm run lint          # eslint .
```

No coverage script or threshold is currently configured in `package.json`.

### Plugin package (`plugins/ai-description/`)

- Own test directory `plugins/ai-description/src/__tests__/` with `domain.test.ts` and `generate.test.ts` (unit tests, no shared harness with main frontend)

## Test File Organization

**Backend:**
- Tests live under `src/test/java/pl/devstyle/aj/` mirroring the main package structure (e.g. `pl.devstyle.aj.category.CategoryIntegrationTests` would sit alongside production code's package)
- Shared test infrastructure at the top level: `src/test/java/pl/devstyle/aj/TestcontainersConfiguration.java`, `SecurityMockMvcConfiguration.java`, `WithMockAdminUser.java`, `TestAjApplication.java`
- `mcp-server` module has its own parallel `src/test/java/pl/devstyle/aj/mcp/` tree (`AjMcpApplicationTests.java`, `ConfigurationTests.java`, `config/JacksonConfigTests.java`, `security/McpJwtFilterTests.java`, `service/ToolCallIntegrationTests.java`, etc.)

**Frontend:**
- All tests centralized in `src/main/frontend/src/test/` (not co-located with source): `auth.test.tsx`, `extension-points.test.tsx`, `foundation.test.tsx`, `pages.test.tsx`, `plugin-sdk-auth.test.ts`, `plugin-sdk.test.ts`, `plugins.test.tsx`, plus `setup.ts`

**Naming:**
- Backend: plural `*Tests` suffix (never `*Test` or `*Spec`), package-private class visibility, same package as production code — e.g. `CategoryIntegrationTests`, `CategoryValidationTests`
- Frontend: `*.test.tsx` for component tests, `*.test.ts` for logic-only tests

## Test Structure

### Backend integration test class skeleton

```java
@Import({TestcontainersConfiguration.class, SecurityMockMvcConfiguration.class})
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.MOCK)
@AutoConfigureMockMvc
@Transactional
class FeatureIntegrationTests {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void createCategory_returns201WithCategoryResponse() throws Exception {
        mockMvc.perform(post("/api/categories")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request)))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.id").value(notNullValue()));
    }
}
```
Reference example: `src/test/java/pl/devstyle/aj/IntegrationTests.java`

**Critical Spring Boot 4 / Spring Security 7 gotcha:** `@AutoConfigureMockMvc` does NOT auto-apply `SecurityMockMvcConfigurers.springSecurity()`. Every MockMvc test class MUST import `SecurityMockMvcConfiguration` (`src/test/java/pl/devstyle/aj/SecurityMockMvcConfiguration.java`) alongside `TestcontainersConfiguration`, or `@WithMockUser`/custom security annotations have no effect.

**Method naming convention:** `action_condition_expectedResult`, e.g.:
```java
void createCategory_returns201WithCategoryResponse()
void createProduct_withNonExistentCategory_returns404()
void deleteCategoryWithProducts_returns409()
```

**Test data setup:** No shared fixtures. `@Transactional` on the test class rolls back after each test automatically. Use private `createAndSave*()` helpers per test class with `repository.saveAndFlush()`:
```java
private Category createAndSaveCategory(String name, String description) {
    var category = new Category();
    category.setName(name);
    category.setDescription(description);
    return categoryRepository.saveAndFlush(category);
}
```

**Class split convention:** `*IntegrationTests` for CRUD happy paths; `*ValidationTests` for error handling/edge cases (400/404/409).

### Frontend test structure

```typescript
import { render, screen } from "@testing-library/react";
import { describe, expect, it, vi, beforeEach } from "vitest";
import { MemoryRouter } from "react-router-dom";
import { ChakraProvider } from "@chakra-ui/react";
import { system } from "../theme";

function renderWithProviders(ui: React.ReactElement, initialRoute = "/") {
  return render(
    <ChakraProvider value={system}>
      <MemoryRouter initialEntries={[initialRoute]}>{ui}</MemoryRouter>
    </ChakraProvider>,
  );
}
```
Reference example: `src/main/frontend/src/test/pages.test.tsx`

Define `renderWithProviders()` per test file (not shared globally) — each file wraps only the providers it needs.

`describe()` blocks are named after the page/feature under test.

## Mocking

### Backend
- Never mock the database — use TestContainers PostgreSQL for all persistence-touching tests
- `@WebMvcTest` + `@MockBean` reserved for optional, lightweight controller-only tests that don't need a DB (lower priority than integration tests)
- Custom security annotations replace ad-hoc `@WithMockUser` calls:
  - `@WithMockEditUser` — READ + EDIT permissions
  - `@WithMockAdminUser` — READ + EDIT + PLUGIN_MANAGEMENT (`src/test/java/pl/devstyle/aj/WithMockAdminUser.java`)

```java
@Target({ElementType.TYPE, ElementType.METHOD})
@Retention(RetentionPolicy.RUNTIME)
@WithMockUser(username = "test-admin", authorities = {"PERMISSION_READ", "PERMISSION_EDIT", "PERMISSION_PLUGIN_MANAGEMENT"})
public @interface WithMockAdminUser {
}
```

### Frontend
Module-level API mocking with `vi.mock()` factory functions, reset every test:

```typescript
vi.mock("../api/categories", () => ({
  getCategories: vi.fn(),
  getCategory: vi.fn(),
  createCategory: vi.fn(),
  updateCategory: vi.fn(),
  deleteCategory: vi.fn(),
}));

beforeEach(() => {
  vi.resetAllMocks();
  vi.mocked(categoriesApi.getCategories).mockResolvedValue(mockCategories);
});
```
Reference: `src/main/frontend/src/test/pages.test.tsx`

Auth context is also mocked per-file when needed, preserving real exports via `importOriginal`:
```typescript
vi.mock("../auth/AuthContext", async (importOriginal) => {
  const actual = await importOriginal<typeof import("../auth/AuthContext")>();
  return { ...actual, useAuth: vi.fn(() => ({ token: "test-token", permissions: [...] , login: vi.fn(), logout: vi.fn() })) };
});
```

**What NOT to mock (backend):** JPA repository auto-generated methods, Lombok getters/setters, private methods, the database itself.

## Fixtures and Factories

**Backend:** No shared fixture files — each test class defines its own `createAndSave*()` helpers inline. No base test class for shared setup; `@Import` is used only for infrastructure config classes.

**Frontend:** Mock data objects declared inline at the top of each test file as typed const arrays, e.g.:
```typescript
const mockCategories: CategoryResponse[] = [
  { id: 1, name: "Electronics", description: "Gadgets and devices", createdAt: "2026-03-20T10:00:00Z", updatedAt: "2026-03-20T10:00:00Z" },
];
```
Location: inline in each `*.test.tsx` file under `src/main/frontend/src/test/` (not extracted to a shared fixtures module).

## Coverage

**Requirements:** None enforced via config; no coverage script currently in `src/main/frontend/package.json` scripts and no coverage threshold configured in `vitest.config.ts` (verify before assuming coverage gating exists).

## Test Types

**Backend:**
- Integration tests (primary strategy) — `@SpringBootTest` + MockMvc + TestContainers, covering full HTTP request/response cycles including security
- Unit tests — optional, lower priority; used for isolated logic (see `mcp-server/src/test/java/pl/devstyle/aj/mcp/security/AccessTokenHolderTests.java`, `McpJwtFilterTests.java`)
- Context-load smoke tests — `AjApplicationTests.java`, `AjMcpApplicationTests.java` verify Spring context boots

**Frontend:**
- Component tests with Testing Library (`pages.test.tsx`, `plugins.test.tsx`, `auth.test.tsx`)
- Logic-only unit tests without rendering (`plugin-sdk.test.ts`, `plugin-sdk-auth.test.ts`)
- E2E: not used — no Playwright/Cypress config found in the repo

**Plugin package (`plugins/ai-description/`):**
- Pure unit tests of domain/generation logic (`domain.test.ts`, `generate.test.ts`), independent of the main frontend's Vitest setup

## Common Patterns

**Async testing (backend, HTTP):**
```java
mockMvc.perform(get("/api/health"))
    .andExpect(status().isOk())
    .andExpect(content().contentTypeCompatibleWith("application/json"))
    .andExpect(jsonPath("$.status").value("UP"));
```
Reference: `src/test/java/pl/devstyle/aj/IntegrationTests.java`

**Context bean presence check:**
```java
assertThat(applicationContext.getBean(PluginDescriptorRepository.class)).isNotNull();
```

**Error/edge case testing (backend):** Validation and conflict paths asserted via HTTP status codes (400/404/409) in dedicated `*ValidationTests` classes, matching the `GlobalExceptionHandler` (`src/main/java/pl/devstyle/aj/core/error/GlobalExceptionHandler.java`) response contract.

## Test Scope Guidance

Write 2-8 focused tests per feature group covering: CRUD happy paths, duplicate constraints (409), non-existent resources (404), referential integrity violations (409), validation errors (400 with per-field messages). Use `var` for local variables in test methods.

## Spring Security 7 PathPattern Constraint (relevant to security test setup)

`**` cannot appear mid-pattern in `requestMatchers()`; use single-segment `*` for path variables:
```java
// Wrong — fails at startup
.requestMatchers(HttpMethod.GET, "/api/plugins/**/objects/**")
// Correct
.requestMatchers(HttpMethod.GET, "/api/plugins/*/objects/**")
```

---

*Testing analysis: 2026-08-16*
