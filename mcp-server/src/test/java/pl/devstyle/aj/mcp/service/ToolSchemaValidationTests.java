package pl.devstyle.aj.mcp.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.networknt.schema.Error;
import com.networknt.schema.Schema;
import com.networknt.schema.SchemaRegistry;
import com.networknt.schema.SpecificationVersion;
import io.modelcontextprotocol.server.McpStatelessServerFeatures;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import pl.devstyle.aj.mcp.client.AjApiClient;
import pl.devstyle.aj.mcp.client.dto.CategoryResponse;
import pl.devstyle.aj.mcp.client.dto.ProductResponse;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

@SpringBootTest
class ToolSchemaValidationTests {

    @Autowired
    private ProductService productService;

    @Autowired
    private CategoryService categoryService;

    @MockitoBean
    private AjApiClient ajApiClient;

    @Autowired
    private ObjectMapper objectMapper;

    private final SchemaRegistry schemaRegistry = SchemaRegistry.withDefaultDialect(
            SpecificationVersion.DRAFT_7,
            builder -> {}
    );

    private ProductResponse sampleProduct;
    private CategoryResponse sampleCategory;

    @BeforeEach
    void setUp() {
        sampleCategory = new CategoryResponse(1L, "Electronics", "Electronic devices");

        sampleProduct = new ProductResponse(1L, "Laptop", "A powerful laptop",
                "https://example.com/photo.jpg", new BigDecimal("1299.99"), "LAP-001",
                sampleCategory, Map.of("color", "silver"),
                LocalDateTime.of(2026, 1, 1, 0, 0), LocalDateTime.of(2026, 1, 2, 0, 0));
    }

    @Test
    void listProducts_toolSpec_hasCorrectNameAndSchema() {
        McpStatelessServerFeatures.SyncToolSpecification toolSpec = productService.buildToolListProducts();

        assertThat(toolSpec.tool().name()).isEqualTo("aj_list_products");
        assertThat(toolSpec.tool().title()).isEqualTo("AJ: List Products");
        assertThat(toolSpec.tool().inputSchema()).isNotNull();
        assertThat(toolSpec.tool().outputSchema()).isNotNull();
    }

    @Test
    void addProduct_toolSpec_hasCorrectNameAndRequiredFields() throws Exception {
        McpStatelessServerFeatures.SyncToolSpecification toolSpec = productService.buildToolAddProduct();

        assertThat(toolSpec.tool().name()).isEqualTo("aj_add_product");
        assertThat(toolSpec.tool().title()).isEqualTo("AJ: Add Product");

        String inputSchemaJson = objectMapper.writeValueAsString(toolSpec.tool().inputSchema());
        JsonNode inputSchema = objectMapper.readTree(inputSchemaJson);
        JsonNode required = inputSchema.get("required");
        assertThat(required).isNotNull();

        List<String> requiredFields = objectMapper.convertValue(required,
                objectMapper.getTypeFactory().constructCollectionType(List.class, String.class));
        assertThat(requiredFields).containsExactlyInAnyOrder("name", "price", "sku", "categoryId");
    }

    @Test
    void listCategories_toolSpec_hasCorrectName() {
        McpStatelessServerFeatures.SyncToolSpecification toolSpec = categoryService.buildToolListCategories();

        assertThat(toolSpec.tool().name()).isEqualTo("aj_list_categories");
        assertThat(toolSpec.tool().title()).isEqualTo("AJ: List Categories");
        assertThat(toolSpec.tool().inputSchema()).isNotNull();
        assertThat(toolSpec.tool().outputSchema()).isNotNull();
    }

    @Test
    void listProducts_outputSchema_validatesAgainstSampleResponse() throws Exception {
        when(ajApiClient.listProducts(any())).thenReturn(List.of(sampleProduct));

        Map<String, List<ProductResponse>> response = productService.listProducts("test-token", null);
        JsonNode responseJson = objectMapper.valueToTree(response);

        McpStatelessServerFeatures.SyncToolSpecification toolSpec = productService.buildToolListProducts();
        String schemaString = objectMapper.writeValueAsString(toolSpec.tool().outputSchema());
        Schema schema = schemaRegistry.getSchema(schemaString);

        List<Error> errors = schema.validate(responseJson);
        assertThat(errors)
                .as("Output schema for aj_list_products should validate against sample ProductResponse")
                .isEmpty();
    }

    @Test
    void addProduct_inputSchema_validatesSampleRequestWithBigDecimalPrice() throws Exception {
        JsonNode sampleInput = objectMapper.createObjectNode()
                .put("name", "Laptop")
                .put("description", "A powerful laptop")
                .put("photoUrl", "https://example.com/photo.jpg")
                .put("price", 1299.99)
                .put("sku", "LAP-001")
                .put("categoryId", 1);

        McpStatelessServerFeatures.SyncToolSpecification toolSpec = productService.buildToolAddProduct();
        String schemaString = objectMapper.writeValueAsString(toolSpec.tool().inputSchema());
        Schema schema = schemaRegistry.getSchema(schemaString);

        List<Error> errors = schema.validate(sampleInput);
        assertThat(errors)
                .as("Input schema for aj_add_product should validate sample request with BigDecimal price")
                .isEmpty();
    }

    @Test
    void listCategories_outputSchema_validatesAgainstSampleResponse() throws Exception {
        when(ajApiClient.listCategories()).thenReturn(List.of(sampleCategory));

        Map<String, List<CategoryResponse>> response = categoryService.listCategories("test-token");
        JsonNode responseJson = objectMapper.valueToTree(response);

        McpStatelessServerFeatures.SyncToolSpecification toolSpec = categoryService.buildToolListCategories();
        String schemaString = objectMapper.writeValueAsString(toolSpec.tool().outputSchema());
        Schema schema = schemaRegistry.getSchema(schemaString);

        List<Error> errors = schema.validate(responseJson);
        assertThat(errors)
                .as("Output schema for aj_list_categories should validate against sample CategoryResponse")
                .isEmpty();
    }
}
