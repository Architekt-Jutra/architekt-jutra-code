package pl.devstyle.aj.mcp.service;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import pl.devstyle.aj.mcp.client.AjApiClient;
import pl.devstyle.aj.mcp.exception.McpToolException;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

@SpringBootTest
class ErrorMappingTests {

    @Autowired
    private ProductService productService;

    @Autowired
    private CategoryService categoryService;

    @MockitoBean
    private AjApiClient ajApiClient;

    @Test
    void listProducts_whenBackendThrowsValidationError_propagatesMcpToolException() {
        when(ajApiClient.listProducts(any()))
                .thenThrow(McpToolException.validationError("Invalid search parameter"));

        assertThatThrownBy(() -> productService.listProducts("token", "bad"))
                .isInstanceOf(McpToolException.class)
                .satisfies(ex -> {
                    var mcpEx = (McpToolException) ex;
                    assertThat(mcpEx.getErrorType()).isEqualTo(McpToolException.ErrorType.VALIDATION);
                    assertThat(mcpEx.getMessage()).isEqualTo("Invalid search parameter");
                });
    }

    @Test
    void listProducts_whenBackendThrowsNotFound_propagatesMcpToolException() {
        when(ajApiClient.listProducts(any()))
                .thenThrow(McpToolException.notFound("Resource not found"));

        assertThatThrownBy(() -> productService.listProducts("token", null))
                .isInstanceOf(McpToolException.class)
                .satisfies(ex -> {
                    var mcpEx = (McpToolException) ex;
                    assertThat(mcpEx.getErrorType()).isEqualTo(McpToolException.ErrorType.NOT_FOUND);
                });
    }

    @Test
    void addProduct_whenBackendThrowsApiError_propagatesMcpToolException() {
        when(ajApiClient.createProduct(any()))
                .thenThrow(McpToolException.apiError("Backend error (status 500). Please retry."));

        assertThatThrownBy(() -> productService.addProduct("token",
                java.util.Map.of("name", "Test", "price", 10, "sku", "T-1", "categoryId", 1)))
                .isInstanceOf(McpToolException.class)
                .satisfies(ex -> {
                    var mcpEx = (McpToolException) ex;
                    assertThat(mcpEx.getErrorType()).isEqualTo(McpToolException.ErrorType.API_ERROR);
                    assertThat(mcpEx.getMessage()).contains("retry");
                });
    }

    @Test
    void listProducts_whenUnexpectedException_wrapsAsApiError() {
        when(ajApiClient.listProducts(any()))
                .thenThrow(new RuntimeException("Connection refused"));

        assertThatThrownBy(() -> productService.listProducts("token", null))
                .isInstanceOf(McpToolException.class)
                .satisfies(ex -> {
                    var mcpEx = (McpToolException) ex;
                    assertThat(mcpEx.getErrorType()).isEqualTo(McpToolException.ErrorType.API_ERROR);
                    assertThat(mcpEx.getMessage()).contains("Failed to list products");
                    assertThat(mcpEx.getMessage()).contains("Connection refused");
                });
    }

    @Test
    void listCategories_whenUnexpectedException_wrapsAsApiError() {
        when(ajApiClient.listCategories())
                .thenThrow(new RuntimeException("Timeout"));

        assertThatThrownBy(() -> categoryService.listCategories("token"))
                .isInstanceOf(McpToolException.class)
                .satisfies(ex -> {
                    var mcpEx = (McpToolException) ex;
                    assertThat(mcpEx.getErrorType()).isEqualTo(McpToolException.ErrorType.API_ERROR);
                    assertThat(mcpEx.getMessage()).contains("Failed to list categories");
                });
    }
}
