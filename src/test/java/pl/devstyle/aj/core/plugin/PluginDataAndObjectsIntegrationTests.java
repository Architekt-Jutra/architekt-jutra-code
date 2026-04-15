package pl.devstyle.aj.core.plugin;

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
import pl.devstyle.aj.product.Product;
import pl.devstyle.aj.product.ProductRepository;

import java.math.BigDecimal;
import java.util.Map;

import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.notNullValue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@Import({TestcontainersConfiguration.class, SecurityMockMvcConfiguration.class})
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.MOCK)
@AutoConfigureMockMvc
@Transactional
@WithMockEditUser
class PluginDataAndObjectsIntegrationTests {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private PluginDescriptorRepository pluginDescriptorRepository;

    @Autowired
    private CategoryRepository categoryRepository;

    @Autowired
    private ProductRepository productRepository;

    private PluginDescriptor createAndSavePlugin(String id) {
        var plugin = new PluginDescriptor();
        plugin.setId(id);
        plugin.setName(id + " plugin");
        plugin.setVersion("1.0.0");
        plugin.setUrl("http://localhost:3001");
        plugin.setDescription("Test plugin");
        plugin.setEnabled(true);
        plugin.setManifest(Map.of("name", id + " plugin", "version", "1.0.0"));
        return pluginDescriptorRepository.saveAndFlush(plugin);
    }

    private Product createAndSaveProduct(String name, String sku) {
        var category = new Category();
        category.setName("Test Category");
        category.setDescription("Test");
        categoryRepository.saveAndFlush(category);

        var product = new Product();
        product.setName(name);
        product.setDescription("Test product");
        product.setPrice(new BigDecimal("9.99"));
        product.setSku(sku);
        product.setCategory(category);
        return productRepository.saveAndFlush(product);
    }

    @Test
    void setProductPluginData_storesNamespacedData() throws Exception {
        var plugin = createAndSavePlugin("reviews");
        var product = createAndSaveProduct("Laptop", "LAP-001");

        var data = Map.of("rating", 4.5, "count", 10);

        mockMvc.perform(put("/api/plugins/{pluginId}/products/{productId}/data", plugin.getId(), product.getId())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(data)))
                .andExpect(status().isOk());

        mockMvc.perform(get("/api/products/{id}", product.getId()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.pluginData.reviews.rating").value(4.5))
                .andExpect(jsonPath("$.pluginData.reviews.count").value(10));
    }

    @Test
    void getProductPluginData_returnsOnlyPluginNode() throws Exception {
        var pluginA = createAndSavePlugin("reviews");
        var pluginB = createAndSavePlugin("seo");
        var product = createAndSaveProduct("Phone", "PH-001");

        mockMvc.perform(put("/api/plugins/{pluginId}/products/{productId}/data", pluginA.getId(), product.getId())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of("rating", 5))))
                .andExpect(status().isOk());

        mockMvc.perform(put("/api/plugins/{pluginId}/products/{productId}/data", pluginB.getId(), product.getId())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of("title", "Best Phone"))))
                .andExpect(status().isOk());

        mockMvc.perform(get("/api/plugins/{pluginId}/products/{productId}/data", pluginA.getId(), product.getId()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.rating").value(5))
                .andExpect(jsonPath("$.title").doesNotExist());
    }

    @Test
    void deleteProductPluginData_removesOnlyPluginNode() throws Exception {
        var pluginA = createAndSavePlugin("reviews");
        var pluginB = createAndSavePlugin("seo");
        var product = createAndSaveProduct("Tablet", "TB-001");

        mockMvc.perform(put("/api/plugins/{pluginId}/products/{productId}/data", pluginA.getId(), product.getId())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of("rating", 3))))
                .andExpect(status().isOk());

        mockMvc.perform(put("/api/plugins/{pluginId}/products/{productId}/data", pluginB.getId(), product.getId())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of("title", "Great Tablet"))))
                .andExpect(status().isOk());

        mockMvc.perform(delete("/api/plugins/{pluginId}/products/{productId}/data", pluginA.getId(), product.getId()))
                .andExpect(status().isNoContent());

        mockMvc.perform(get("/api/products/{id}", product.getId()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.pluginData.reviews").doesNotExist())
                .andExpect(jsonPath("$.pluginData.seo.title").value("Great Tablet"));
    }

    @Test
    void savePluginObject_createsAndReturns() throws Exception {
        var plugin = createAndSavePlugin("reviews");

        var data = Map.of("text", "Great product!", "stars", 5);

        mockMvc.perform(put("/api/plugins/{pluginId}/objects/{objectType}/{objectId}",
                        plugin.getId(), "review", "rev-1")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(data)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(notNullValue()))
                .andExpect(jsonPath("$.pluginId").value("reviews"))
                .andExpect(jsonPath("$.objectType").value("review"))
                .andExpect(jsonPath("$.objectId").value("rev-1"))
                .andExpect(jsonPath("$.data.text").value("Great product!"))
                .andExpect(jsonPath("$.data.stars").value(5));
    }

    @Test
    void listPluginObjects_filtersByType() throws Exception {
        var plugin = createAndSavePlugin("reviews");

        mockMvc.perform(put("/api/plugins/{pluginId}/objects/{objectType}/{objectId}",
                        plugin.getId(), "review", "rev-1")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of("text", "Good"))))
                .andExpect(status().isOk());

        mockMvc.perform(put("/api/plugins/{pluginId}/objects/{objectType}/{objectId}",
                        plugin.getId(), "comment", "com-1")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of("text", "Nice"))))
                .andExpect(status().isOk());

        mockMvc.perform(get("/api/plugins/{pluginId}/objects/{objectType}",
                        plugin.getId(), "review"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(1)))
                .andExpect(jsonPath("$[0].objectType").value("review"));
    }

    @Test
    void savePluginObject_duplicateKey_updatesExisting() throws Exception {
        var plugin = createAndSavePlugin("reviews");

        mockMvc.perform(put("/api/plugins/{pluginId}/objects/{objectType}/{objectId}",
                        plugin.getId(), "review", "rev-1")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of("text", "Original"))))
                .andExpect(status().isOk());

        mockMvc.perform(put("/api/plugins/{pluginId}/objects/{objectType}/{objectId}",
                        plugin.getId(), "review", "rev-1")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of("text", "Updated"))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.text").value("Updated"));

        mockMvc.perform(get("/api/plugins/{pluginId}/objects/{objectType}",
                        plugin.getId(), "review"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(1)));
    }
}
