package pl.devstyle.aj.mcp.service;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import pl.devstyle.aj.mcp.client.AjApiClient;
import pl.devstyle.aj.mcp.client.dto.CategoryResponse;
import pl.devstyle.aj.mcp.client.dto.ProductResponse;

import io.modelcontextprotocol.common.McpTransportContext;
import pl.devstyle.aj.mcp.AjMcpApplication;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

@SpringBootTest
class ToolCallIntegrationTests {

    @Autowired
    private ProductService productService;

    @Autowired
    private CategoryService categoryService;

    @MockitoBean
    private AjApiClient ajApiClient;

    private final CategoryResponse sampleCategory = new CategoryResponse(
            1L, "Electronics", "Electronic devices");

    private final ProductResponse sampleProduct = new ProductResponse(
            1L, "Laptop", "A powerful laptop", "https://example.com/photo.jpg",
            new BigDecimal("1299.99"), "LAP-001", null, Map.of("color", "silver"),
            LocalDateTime.of(2026, 1, 1, 0, 0), LocalDateTime.of(2026, 1, 2, 0, 0));

    @Test
    void listProducts_callHandler_executesWithoutException() {
        when(ajApiClient.listProducts(any())).thenReturn(List.of(sampleProduct));

        var toolSpec = productService.buildToolListProducts();

        assertThatCode(() -> toolSpec.callHandler().apply(McpTransportContext.create(Map.of(AjMcpApplication.TOKEN_KEY, "test-token")),
                new io.modelcontextprotocol.spec.McpSchema.CallToolRequest(
                        "aj_list_products", Map.of())))
                .doesNotThrowAnyException();
    }

    @Test
    void addProduct_callHandler_executesWithValidArgs() {
        when(ajApiClient.createProduct(any())).thenReturn(sampleProduct);

        var toolSpec = productService.buildToolAddProduct();
        Map<String, Object> args = Map.of(
                "name", "Laptop",
                "price", 1299.99,
                "sku", "LAP-001",
                "categoryId", 1);

        assertThatCode(() -> toolSpec.callHandler().apply(McpTransportContext.create(Map.of(AjMcpApplication.TOKEN_KEY, "test-token")),
                new io.modelcontextprotocol.spec.McpSchema.CallToolRequest(
                        "aj_add_product", args)))
                .doesNotThrowAnyException();
    }

    @Test
    void listCategories_callHandler_executesWithoutException() {
        when(ajApiClient.listCategories()).thenReturn(List.of(sampleCategory));

        var toolSpec = categoryService.buildToolListCategories();

        assertThatCode(() -> toolSpec.callHandler().apply(McpTransportContext.create(Map.of(AjMcpApplication.TOKEN_KEY, "test-token")),
                new io.modelcontextprotocol.spec.McpSchema.CallToolRequest(
                        "aj_list_categories", Map.of())))
                .doesNotThrowAnyException();
    }

    @Test
    void listProducts_returnsWrappedResponse() {
        when(ajApiClient.listProducts(any())).thenReturn(List.of(sampleProduct));

        var result = productService.listProducts("test-token", null);

        assertThat(result).containsKey("products");
        assertThat(result.get("products")).hasSize(1);
        assertThat(result.get("products").getFirst().name()).isEqualTo("Laptop");
    }

    @Test
    void listCategories_returnsWrappedResponse() {
        when(ajApiClient.listCategories()).thenReturn(List.of(sampleCategory));

        var result = categoryService.listCategories("test-token");

        assertThat(result).containsKey("categories");
        assertThat(result.get("categories")).hasSize(1);
        assertThat(result.get("categories").getFirst().name()).isEqualTo("Electronics");
    }
}
