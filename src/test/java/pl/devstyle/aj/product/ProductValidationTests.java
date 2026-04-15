package pl.devstyle.aj.product;

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
import pl.devstyle.aj.category.Category;
import pl.devstyle.aj.category.CategoryRepository;

import java.math.BigDecimal;

import static org.hamcrest.Matchers.notNullValue;
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
class ProductValidationTests {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private CategoryRepository categoryRepository;

    @Autowired
    private ProductRepository productRepository;

    private Category createAndSaveCategory(String name) {
        var category = new Category();
        category.setName(name);
        category.setDescription("Test category");
        return categoryRepository.saveAndFlush(category);
    }

    @Test
    void createProduct_withMultipleValidationErrors_returns400WithAllFieldErrors() throws Exception {
        var request = new CreateProductRequest(
                "", null, null,
                new BigDecimal("-5.00"), "", null);

        mockMvc.perform(post("/api/products")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.status").value(400))
                .andExpect(jsonPath("$.error").value("Bad Request"))
                .andExpect(jsonPath("$.message").value("Validation failed"))
                .andExpect(jsonPath("$.fieldErrors").isMap())
                .andExpect(jsonPath("$.fieldErrors.name").value(notNullValue()))
                .andExpect(jsonPath("$.fieldErrors.price").value(notNullValue()))
                .andExpect(jsonPath("$.fieldErrors.sku").value(notNullValue()))
                .andExpect(jsonPath("$.fieldErrors.categoryId").value(notNullValue()));
    }

    @Test
    void createProduct_withNegativePrice_returns400() throws Exception {
        var category = createAndSaveCategory("Validation Test");

        var request = new CreateProductRequest(
                "Valid Name", "Description", null,
                new BigDecimal("-10.00"), "SKU-NEG", category.getId());

        mockMvc.perform(post("/api/products")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.fieldErrors.price").value(notNullValue()));
    }

    @Test
    void createProduct_withZeroPrice_returns400() throws Exception {
        var category = createAndSaveCategory("Zero Price Test");

        var request = new CreateProductRequest(
                "Valid Name", "Description", null,
                BigDecimal.ZERO, "SKU-ZERO", category.getId());

        mockMvc.perform(post("/api/products")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.fieldErrors.price").value(notNullValue()));
    }

    @Test
    void getNonExistentProduct_returns404() throws Exception {
        mockMvc.perform(get("/api/products/{id}", 999999L))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.status").value(404))
                .andExpect(jsonPath("$.error").value("Not Found"))
                .andExpect(jsonPath("$.message").value(notNullValue()));
    }

    @Test
    void updateNonExistentProduct_returns404() throws Exception {
        var category = createAndSaveCategory("Update Test");

        var request = new UpdateProductRequest(
                "Updated", "Updated desc", null,
                new BigDecimal("19.99"), "UPD-001", category.getId());

        mockMvc.perform(put("/api/products/{id}", 999999L)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.status").value(404));
    }

    @Test
    void listProducts_withEmptySearch_returnsAllProducts() throws Exception {
        var category = createAndSaveCategory("Search Test");
        var product = new Product();
        product.setName("SearchTestProduct");
        product.setDescription("desc");
        product.setPrice(new BigDecimal("9.99"));
        product.setSku("SRCH-001");
        product.setCategory(category);
        productRepository.saveAndFlush(product);

        mockMvc.perform(get("/api/products").param("search", ""))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray());
    }

    @Test
    void errorResponse_for404_hasNullFieldErrors() throws Exception {
        mockMvc.perform(get("/api/products/{id}", 999999L))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.status").value(404))
                .andExpect(jsonPath("$.error").value("Not Found"))
                .andExpect(jsonPath("$.message").value(notNullValue()))
                .andExpect(jsonPath("$.fieldErrors").doesNotExist())
                .andExpect(jsonPath("$.timestamp").value(notNullValue()));
    }
}
