package pl.devstyle.aj.mcp.client.dto;

import com.fasterxml.jackson.annotation.JsonInclude;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Map;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record ProductResponse(
        Long id,
        String name,
        String description,
        String photoUrl,
        BigDecimal price,
        String sku,
        CategoryResponse category,
        Map<String, Object> pluginData,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) {
}
