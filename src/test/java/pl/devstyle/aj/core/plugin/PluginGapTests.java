package pl.devstyle.aj.core.plugin;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.context.annotation.Import;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;
import pl.devstyle.aj.SecurityMockMvcConfiguration;
import pl.devstyle.aj.TestcontainersConfiguration;
import pl.devstyle.aj.WithMockAdminUser;
import pl.devstyle.aj.category.Category;
import pl.devstyle.aj.category.CategoryRepository;
import pl.devstyle.aj.product.Product;
import pl.devstyle.aj.product.ProductRepository;

import java.math.BigDecimal;
import java.util.Map;

import static org.hamcrest.Matchers.hasSize;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@Import({TestcontainersConfiguration.class, SecurityMockMvcConfiguration.class})
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.MOCK)
@AutoConfigureMockMvc
@Transactional
@WithMockAdminUser
class PluginGapTests {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private PluginDescriptorRepository pluginDescriptorRepository;

    @Autowired
    private CategoryRepository categoryRepository;

    @Autowired
    private ProductRepository productRepository;

    private PluginDescriptor createAndSavePlugin(String id, boolean enabled) {
        var plugin = new PluginDescriptor();
        plugin.setId(id);
        plugin.setName(id + " plugin");
        plugin.setVersion("1.0.0");
        plugin.setUrl("http://localhost:3001");
        plugin.setDescription("Test plugin");
        plugin.setEnabled(enabled);
        plugin.setManifest(Map.of("name", id + " plugin", "version", "1.0.0"));
        return pluginDescriptorRepository.saveAndFlush(plugin);
    }

    private Product createAndSaveProductWithPluginData(String name, String sku, Map<String, Object> pluginData) {
        var category = new Category();
        category.setName("Gap Category " + sku);
        category.setDescription("Test");
        categoryRepository.saveAndFlush(category);

        var product = new Product();
        product.setName(name);
        product.setDescription("Test product");
        product.setPrice(new BigDecimal("9.99"));
        product.setSku(sku);
        product.setCategory(category);
        product.setPluginData(pluginData);
        return productRepository.saveAndFlush(product);
    }

    // --- pluginFilter JSONB query operator tests ---

    @Test
    void listProducts_pluginFilterGt_filtersProductsCorrectly() throws Exception {
        createAndSavePlugin("reviews", true);

        var category = new Category();
        category.setName("Gap Test Electronics");
        category.setDescription("Test");
        categoryRepository.saveAndFlush(category);

        var highRated = new Product();
        highRated.setName("High Rated");
        highRated.setDescription("Good product");
        highRated.setPrice(new BigDecimal("49.99"));
        highRated.setSku("HR-001");
        highRated.setCategory(category);
        highRated.setPluginData(Map.of("reviews", Map.of("rating", 4.5)));
        productRepository.saveAndFlush(highRated);

        var lowRated = new Product();
        lowRated.setName("Low Rated");
        lowRated.setDescription("Okay product");
        lowRated.setPrice(new BigDecimal("19.99"));
        lowRated.setSku("LR-001");
        lowRated.setCategory(category);
        lowRated.setPluginData(Map.of("reviews", Map.of("rating", 2.0)));
        productRepository.saveAndFlush(lowRated);

        mockMvc.perform(get("/api/products").param("pluginFilter", "reviews:rating:gt:3"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(1)))
                .andExpect(jsonPath("$[0].name").value("High Rated"));
    }

    @Test
    void listProducts_pluginFilterExists_filtersProductsCorrectly() throws Exception {
        createAndSavePlugin("seo", true);

        var category = new Category();
        category.setName("Gap Test Books");
        category.setDescription("Test");
        categoryRepository.saveAndFlush(category);

        var withSeo = new Product();
        withSeo.setName("With SEO");
        withSeo.setDescription("Has SEO data");
        withSeo.setPrice(new BigDecimal("29.99"));
        withSeo.setSku("SEO-001");
        withSeo.setCategory(category);
        withSeo.setPluginData(Map.of("seo", Map.of("title", "Great Book")));
        productRepository.saveAndFlush(withSeo);

        var withoutSeo = new Product();
        withoutSeo.setName("Without SEO");
        withoutSeo.setDescription("No SEO data");
        withoutSeo.setPrice(new BigDecimal("19.99"));
        withoutSeo.setSku("NOSEO-001");
        withoutSeo.setCategory(category);
        withoutSeo.setPluginData(Map.of());
        productRepository.saveAndFlush(withoutSeo);

        mockMvc.perform(get("/api/products").param("pluginFilter", "seo:title:exists"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(1)))
                .andExpect(jsonPath("$[0].name").value("With SEO"));
    }

    @Test
    void listProducts_multiplePluginFilters_appliesAllAsAnd() throws Exception {
        createAndSavePlugin("reviews", true);
        createAndSavePlugin("seo", true);

        var category = new Category();
        category.setName("Multi Filter Category");
        category.setDescription("Test");
        categoryRepository.saveAndFlush(category);

        var bothMatch = new Product();
        bothMatch.setName("Both Match");
        bothMatch.setDescription("Has both");
        bothMatch.setPrice(new BigDecimal("49.99"));
        bothMatch.setSku("MF-001");
        bothMatch.setCategory(category);
        bothMatch.setPluginData(Map.of(
                "reviews", Map.of("rating", 4.5),
                "seo", Map.of("title", "Great Product")));
        productRepository.saveAndFlush(bothMatch);

        var onlyReviews = new Product();
        onlyReviews.setName("Only Reviews");
        onlyReviews.setDescription("Has reviews only");
        onlyReviews.setPrice(new BigDecimal("29.99"));
        onlyReviews.setSku("MF-002");
        onlyReviews.setCategory(category);
        onlyReviews.setPluginData(Map.of("reviews", Map.of("rating", 4.0)));
        productRepository.saveAndFlush(onlyReviews);

        var onlySeo = new Product();
        onlySeo.setName("Only SEO");
        onlySeo.setDescription("Has seo only");
        onlySeo.setPrice(new BigDecimal("19.99"));
        onlySeo.setSku("MF-003");
        onlySeo.setCategory(category);
        onlySeo.setPluginData(Map.of("seo", Map.of("title", "Another")));
        productRepository.saveAndFlush(onlySeo);

        mockMvc.perform(get("/api/products")
                        .param("pluginFilter", "reviews:rating:gt:3")
                        .param("pluginFilter", "seo:title:exists"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(1)))
                .andExpect(jsonPath("$[0].name").value("Both Match"));
    }

    // --- pluginId validation: 404 for disabled/missing plugin across endpoint groups ---

    @Test
    void getPluginData_forNonExistentProduct_returns404() throws Exception {
        var plugin = createAndSavePlugin("reviews", true);

        mockMvc.perform(get("/api/plugins/{pluginId}/products/{productId}/data", plugin.getId(), 999999))
                .andExpect(status().isNotFound());
    }

    @Test
    void deletePlugin_thenAccessPluginData_returns404() throws Exception {
        var plugin = createAndSavePlugin("temp-plugin", true);
        var product = createAndSaveProductWithPluginData("Laptop", "LP-001",
                Map.of("temp-plugin", Map.of("key", "value")));

        // Delete the plugin
        mockMvc.perform(delete("/api/plugins/{pluginId}", plugin.getId()))
                .andExpect(status().isNoContent());

        // Accessing plugin data for deleted plugin should return 404
        mockMvc.perform(get("/api/plugins/{pluginId}/products/{productId}/data", "temp-plugin", product.getId()))
                .andExpect(status().isNotFound());
    }

    @Test
    void getPluginData_forDisabledPlugin_returns404() throws Exception {
        var plugin = createAndSavePlugin("disabled-plugin", false);
        var product = createAndSaveProductWithPluginData("Item", "IT-001", Map.of());

        mockMvc.perform(get("/api/plugins/{pluginId}/products/{productId}/data", plugin.getId(), product.getId()))
                .andExpect(status().isNotFound());
    }
}
