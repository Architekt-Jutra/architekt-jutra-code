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
class ProductIntegrationTests {

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

    private Product createAndSaveProduct(String name, String sku, BigDecimal price, Category category) {
        var product = new Product();
        product.setName(name);
        product.setDescription("Test product");
        product.setPrice(price);
        product.setSku(sku);
        product.setCategory(category);
        return productRepository.saveAndFlush(product);
    }

    @Test
    void createProduct_withValidCategory_returns201WithNestedCategory() throws Exception {
        var category = createAndSaveCategory("Electronics");

        var request = new CreateProductRequest(
                "Laptop", "A powerful laptop", null,
                new BigDecimal("999.99"), "LAP-001", category.getId());

        mockMvc.perform(post("/api/products")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").value(notNullValue()))
                .andExpect(jsonPath("$.name").value("Laptop"))
                .andExpect(jsonPath("$.description").value("A powerful laptop"))
                .andExpect(jsonPath("$.price").value(999.99))
                .andExpect(jsonPath("$.sku").value("LAP-001"))
                .andExpect(jsonPath("$.category.id").value(category.getId()))
                .andExpect(jsonPath("$.category.name").value("Electronics"));
    }

    @Test
    void createProduct_withNonExistentCategory_returns404() throws Exception {
        var request = new CreateProductRequest(
                "Laptop", "A powerful laptop", null,
                new BigDecimal("999.99"), "LAP-002", 999999L);

        mockMvc.perform(post("/api/products")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.status").value(404));
    }

    @Test
    void listProducts_returns200WithArray() throws Exception {
        var category = createAndSaveCategory("Books");
        createAndSaveProduct("Book A", "BK-001", new BigDecimal("19.99"), category);
        createAndSaveProduct("Book B", "BK-002", new BigDecimal("29.99"), category);

        mockMvc.perform(get("/api/products"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray())
                .andExpect(jsonPath("$", hasSize(greaterThanOrEqualTo(2))));
    }

    @Test
    void listProducts_filteredByCategory_returnsFilteredResults() throws Exception {
        var electronics = createAndSaveCategory("Electronics");
        var books = createAndSaveCategory("Books");
        createAndSaveProduct("Laptop", "EL-001", new BigDecimal("999.99"), electronics);
        createAndSaveProduct("Novel", "BK-003", new BigDecimal("14.99"), books);

        mockMvc.perform(get("/api/products").param("category", electronics.getId().toString()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray())
                .andExpect(jsonPath("$", hasSize(1)))
                .andExpect(jsonPath("$[0].name").value("Laptop"));
    }

    @Test
    void listProducts_withSearch_returnsCaseInsensitiveMatches() throws Exception {
        var category = createAndSaveCategory("Gadgets");
        createAndSaveProduct("Ergonomic Trackball", "GM-001", new BigDecimal("29.99"), category);
        createAndSaveProduct("Keyboard", "GM-002", new BigDecimal("49.99"), category);

        mockMvc.perform(get("/api/products").param("search", "trackball"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray())
                .andExpect(jsonPath("$", hasSize(1)))
                .andExpect(jsonPath("$[0].name").value("Ergonomic Trackball"));
    }

    @Test
    void getProductById_returns200WithNestedCategory() throws Exception {
        var category = createAndSaveCategory("Clothing");
        var product = createAndSaveProduct("T-Shirt", "CL-001", new BigDecimal("24.99"), category);

        mockMvc.perform(get("/api/products/{id}", product.getId()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(product.getId()))
                .andExpect(jsonPath("$.name").value("T-Shirt"))
                .andExpect(jsonPath("$.sku").value("CL-001"))
                .andExpect(jsonPath("$.category.id").value(category.getId()))
                .andExpect(jsonPath("$.category.name").value("Clothing"));
    }

    @Test
    void updateProduct_returns200WithUpdatedFields() throws Exception {
        var category = createAndSaveCategory("Food");
        var product = createAndSaveProduct("Apple", "FD-001", new BigDecimal("1.99"), category);

        var request = new UpdateProductRequest(
                "Green Apple", "Organic green apple", null,
                new BigDecimal("2.49"), "FD-001", category.getId());

        mockMvc.perform(put("/api/products/{id}", product.getId())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(product.getId()))
                .andExpect(jsonPath("$.name").value("Green Apple"))
                .andExpect(jsonPath("$.price").value(2.49));
    }

    @Test
    void deleteProduct_returns204() throws Exception {
        var category = createAndSaveCategory("Toys");
        var product = createAndSaveProduct("Action Figure", "TY-001", new BigDecimal("14.99"), category);

        mockMvc.perform(delete("/api/products/{id}", product.getId()))
                .andExpect(status().isNoContent());
    }

    @Test
    void createProduct_withDuplicateSku_returns409() throws Exception {
        var category = createAndSaveCategory("Sports");
        createAndSaveProduct("Football", "SP-001", new BigDecimal("29.99"), category);

        var request = new CreateProductRequest(
                "Basketball", "A basketball", null,
                new BigDecimal("24.99"), "SP-001", category.getId());

        mockMvc.perform(post("/api/products")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isConflict());
    }
}
