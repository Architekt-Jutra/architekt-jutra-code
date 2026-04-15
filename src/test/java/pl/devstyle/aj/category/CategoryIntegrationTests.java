package pl.devstyle.aj.category;

import tools.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;
import pl.devstyle.aj.SecurityMockMvcConfiguration;
import pl.devstyle.aj.TestcontainersConfiguration;
import pl.devstyle.aj.WithMockEditUser;

import static org.hamcrest.Matchers.greaterThanOrEqualTo;
import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.notNullValue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@Import({TestcontainersConfiguration.class, SecurityMockMvcConfiguration.class})
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.MOCK)
@AutoConfigureMockMvc
@Transactional
@WithMockEditUser
class CategoryIntegrationTests {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private CategoryRepository categoryRepository;

    private Category createAndSaveCategory(String name, String description) {
        var category = new Category();
        category.setName(name);
        category.setDescription(description);
        return categoryRepository.saveAndFlush(category);
    }

    @Test
    void createCategory_returns201WithCategoryResponse() throws Exception {
        var request = new CreateCategoryRequest("Electronics", "Electronic devices and gadgets");

        mockMvc.perform(post("/api/categories")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").value(notNullValue()))
                .andExpect(jsonPath("$.name").value("Electronics"))
                .andExpect(jsonPath("$.description").value("Electronic devices and gadgets"))
                .andExpect(jsonPath("$.createdAt").value(notNullValue()))
                .andExpect(jsonPath("$.updatedAt").value(notNullValue()));
    }

    @Test
    void listCategories_returns200WithArray() throws Exception {
        createAndSaveCategory("Books", "All kinds of books");
        createAndSaveCategory("Music", "Musical instruments and albums");

        mockMvc.perform(get("/api/categories"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray())
                .andExpect(jsonPath("$", hasSize(greaterThanOrEqualTo(2))));
    }

    @Test
    void getCategoryById_returns200() throws Exception {
        var saved = createAndSaveCategory("Clothing", "Apparel and accessories");

        mockMvc.perform(get("/api/categories/{id}", saved.getId()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(saved.getId()))
                .andExpect(jsonPath("$.name").value("Clothing"))
                .andExpect(jsonPath("$.description").value("Apparel and accessories"));
    }

    @Test
    void getNonExistentCategory_returns404WithErrorResponse() throws Exception {
        mockMvc.perform(get("/api/categories/{id}", 999999L))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.status").value(404))
                .andExpect(jsonPath("$.error").value("Not Found"))
                .andExpect(jsonPath("$.message").value(notNullValue()));
    }

    @Test
    void updateCategory_returns200WithUpdatedFields() throws Exception {
        var saved = createAndSaveCategory("Old Name", "Old description");
        var request = new UpdateCategoryRequest("New Name", "New description");

        mockMvc.perform(put("/api/categories/{id}", saved.getId())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(saved.getId()))
                .andExpect(jsonPath("$.name").value("New Name"))
                .andExpect(jsonPath("$.description").value("New description"));
    }

    @Test
    void deleteCategory_returns204() throws Exception {
        var saved = createAndSaveCategory("ToDelete", "Will be deleted");

        mockMvc.perform(delete("/api/categories/{id}", saved.getId()))
                .andExpect(status().isNoContent());
    }

    @Test
    void deleteCategoryWithProducts_returns409() throws Exception {
        var saved = createAndSaveCategory("HasProducts", "Category with products");
        categoryRepository.flush();
        insertProductForCategory(saved.getId());

        mockMvc.perform(delete("/api/categories/{id}", saved.getId()))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.status").value(409));
    }

    @Test
    void createDuplicateName_returns409() throws Exception {
        createAndSaveCategory("Unique", "First one");

        var request = new CreateCategoryRequest("Unique", "Duplicate name");

        mockMvc.perform(post("/api/categories")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isConflict());
    }

    @Autowired
    private jakarta.persistence.EntityManager entityManager;

    private void insertProductForCategory(Long categoryId) {
        entityManager.createNativeQuery(
                "INSERT INTO products (id, name, description, price, sku, category_id, created_at, updated_at) " +
                "VALUES (nextval('product_seq'), 'Test Product', 'desc', 9.99, 'SKU-001', :categoryId, now(), now())")
                .setParameter("categoryId", categoryId)
                .executeUpdate();
        entityManager.flush();
    }
}
