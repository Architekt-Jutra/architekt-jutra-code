package pl.devstyle.aj.mcp.client.dto;

import com.fasterxml.jackson.annotation.JsonInclude;

import java.math.BigDecimal;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record CreateProductRequest(
        String name,
        String description,
        String photoUrl,
        BigDecimal price,
        String sku,
        Long categoryId
) {
}
