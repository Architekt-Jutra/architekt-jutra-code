## Backend Testing

### Integration Test Infrastructure

Use TestContainers with real PostgreSQL 18 for all integration tests. Never mock the database.

Standard annotation stack for integration test classes:
```java
@Import(TestcontainersConfiguration.class)
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.MOCK)
@AutoConfigureMockMvc
@Transactional
class FeatureIntegrationTests {
```

TestContainers configuration uses `@ServiceConnection` for automatic datasource wiring:
```java
@TestConfiguration(proxyBeanMethods = false)
class TestcontainersConfiguration {
    @Bean
    @ServiceConnection
    PostgreSQLContainer postgresContainer() {
        return new PostgreSQLContainer(DockerImageName.parse("postgres:18"));
    }
}
```

### Integration Tests Over Unit Tests

Integration tests with TestContainers and MockMvc are the primary testing strategy. Controller unit tests (`@WebMvcTest` with `@MockBean`) are optional and lower priority. Use `@WebMvcTest` only for lightweight API-layer tests that don't need a database.

### What NOT to Test

- JPA repository methods that are Spring Data auto-generated
- Entity getters/setters (Lombok-generated)
- Private methods
- Never mock the database — use TestContainers for real PostgreSQL

### Test Data Isolation

Each test creates its own data — no shared fixtures. `@Transactional` on the test class provides automatic rollback after each test. Inject repositories directly for test setup, use MockMvc for HTTP assertions.

### MockMvc for HTTP Assertions

Use MockMvc with `jsonPath()` + Hamcrest matchers for all HTTP response assertions. Use AssertJ only for non-HTTP assertions (context beans, datasource checks).

```java
mockMvc.perform(post("/api/categories")
        .contentType(MediaType.APPLICATION_JSON)
        .content(objectMapper.writeValueAsString(request)))
    .andExpect(status().isCreated())
    .andExpect(jsonPath("$.id").value(notNullValue()));
```

### Test Class Naming

- Plural `*Tests` suffix (not `*Test` or `*Spec`): `CategoryIntegrationTests`
- Package-private visibility (no `public` modifier)
- Same package as production code: `pl.devstyle.aj.category.CategoryIntegrationTests`

### Test Method Naming

Use `action_condition_expectedResult` pattern with underscore separators:

```java
void createCategory_returns201WithCategoryResponse()
void createProduct_withNonExistentCategory_returns404()
void deleteCategoryWithProducts_returns409()
```

### Private Helper Methods for Test Data

Define `createAndSave*()` helper methods per test class. Use `repository.saveAndFlush()` for immediate visibility. Do not use base class inheritance for shared setup — use `@Import` for infrastructure only.

```java
private Category createAndSaveCategory(String name, String description) {
    var category = new Category();
    category.setName(name);
    category.setDescription(description);
    return categoryRepository.saveAndFlush(category);
}
```

### Integration vs Validation Test Split

Split domain tests into two classes:
- `*IntegrationTests` — CRUD happy-path operations (create, list, get, update, delete)
- `*ValidationTests` — Error handling, validation failures, edge cases (400, 404, 409)

### Test Scope

Write 2-8 focused tests per feature group. Cover all CRUD operations plus edge cases: duplicate constraints (409), non-existent resources (404), referential integrity violations (409), validation errors (400 with per-field errors).

Use `var` for local variables in test methods. Run only feature-specific tests during development, full suite before commits.

### MockMvc Security Integration (Spring Boot 4)

Spring Boot 4 / Spring Security 7's `@AutoConfigureMockMvc` does NOT automatically apply `SecurityMockMvcConfigurers.springSecurity()`. This means `@WithMockUser` annotations have no effect on MockMvc requests without explicit configuration.

All MockMvc-based test classes must import `SecurityMockMvcConfiguration` alongside `TestcontainersConfiguration`:

```java
@Import({TestcontainersConfiguration.class, SecurityMockMvcConfiguration.class})
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.MOCK)
@AutoConfigureMockMvc
@Transactional
class FeatureIntegrationTests {
```

`SecurityMockMvcConfiguration` is a `@TestConfiguration` that provides a `MockMvcBuilderCustomizer` bean applying `springSecurity()` to the MockMvc builder.

### Security Test Annotations

Use custom meta-annotations for consistent security context in tests:

- `@WithMockEditUser` — READ + EDIT permissions (for product/category CRUD tests)
- `@WithMockAdminUser` — READ + EDIT + PLUGIN_MANAGEMENT (for plugin lifecycle tests)

Apply at class level. Tests that set up plugins via manifest PUT need `@WithMockAdminUser`.

### Spring Security 7 PathPattern Constraints

`**` cannot appear in the middle of URL patterns in `requestMatchers()`. Use `*` for single path segments (matches actual controller path variables like `{pluginId}`, `{productId}`).

```java
// Wrong — fails at startup
.requestMatchers(HttpMethod.GET, "/api/plugins/**/objects/**")

// Correct — single segment matches {pluginId}
.requestMatchers(HttpMethod.GET, "/api/plugins/*/objects/**")
```
