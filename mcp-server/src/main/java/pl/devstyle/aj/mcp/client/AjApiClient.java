package pl.devstyle.aj.mcp.client;

import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.service.annotation.GetExchange;
import org.springframework.web.service.annotation.HttpExchange;
import org.springframework.web.service.annotation.PostExchange;
import pl.devstyle.aj.mcp.client.dto.CategoryResponse;
import pl.devstyle.aj.mcp.client.dto.CreateProductRequest;
import pl.devstyle.aj.mcp.client.dto.ProductResponse;

import java.util.List;

@HttpExchange
public interface AjApiClient {

    @GetExchange("/api/products")
    List<ProductResponse> listProducts(@RequestParam(required = false) String search);

    @PostExchange("/api/products")
    ProductResponse createProduct(@RequestBody CreateProductRequest request);

    @GetExchange("/api/categories")
    List<CategoryResponse> listCategories();
}
