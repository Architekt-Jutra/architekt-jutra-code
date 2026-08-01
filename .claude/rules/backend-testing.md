---
paths:
  - "src/test/java/**"
---

# Backend Testing

## Integration-first

TestContainers with real PostgreSQL 18 is the primary strategy. **Never mock the database.** Standard stack:

```java
@Import(TestcontainersConfiguration.class)
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.MOCK)
@AutoConfigureMockMvc
@Transactional
class FeatureIntegrationTests {
```

`@Transactional` on the class rolls back after each test — that is the isolation mechanism. `@WebMvcTest` is optional and only for API-layer checks that need no database.

## Don't test

- Spring Data auto-generated repository methods
- Lombok-generated getters/setters
- Private methods

## Naming

- Classes: `*Tests` (plural, not `*Test`/`*Spec`), package-private, in the same package as the code under test.
- Methods: `action_condition_expectedResult` with underscores.

```java
void createCategory_returns201WithCategoryResponse()
void createProduct_withNonExistentCategory_returns404()
void deleteCategoryWithProducts_returns409()
```

## Split by concern

- `*IntegrationTests` — CRUD happy paths (create, list, get, update, delete)
- `*ValidationTests` — validation failures and edge cases (400, 404, 409)

## Assertions

MockMvc with `jsonPath()` + Hamcrest for every HTTP assertion. AssertJ only for non-HTTP checks (context beans, datasource).

```java
mockMvc.perform(post("/api/categories")
        .contentType(MediaType.APPLICATION_JSON)
        .content(objectMapper.writeValueAsString(request)))
    .andExpect(status().isCreated())
    .andExpect(jsonPath("$.id").value(notNullValue()));
```

## Test data

Each test builds its own data — no shared fixtures, no base class for setup (`@Import` is for infrastructure only). Use private `createAndSave*()` helpers per class with `repository.saveAndFlush()` so the row is visible immediately.

```java
private Category createAndSaveCategory(String name, String description) {
    var category = new Category();
    category.setName(name);
    category.setDescription(description);
    return categoryRepository.saveAndFlush(category);
}
```

## Scope

2–8 focused tests per feature group: all CRUD operations plus duplicate constraints (409), missing resources (404), referential integrity (409), and validation errors (400 with per-field messages). Use `var` for locals. Run feature-specific tests while working, the full suite before committing.
