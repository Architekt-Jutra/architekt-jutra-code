package pl.devstyle.aj.mcp.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import io.modelcontextprotocol.json.McpJsonDefaults;
import io.modelcontextprotocol.server.McpStatelessServerFeatures;
import io.modelcontextprotocol.spec.McpSchema;
import pl.devstyle.aj.mcp.AjMcpApplication;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import pl.devstyle.aj.mcp.client.AjApiClient;
import pl.devstyle.aj.mcp.security.AccessTokenHolder;
import pl.devstyle.aj.mcp.client.dto.CategoryResponse;
import pl.devstyle.aj.mcp.exception.McpToolException;

import java.util.List;
import java.util.Map;

@Service
@Slf4j
@RequiredArgsConstructor
public class CategoryService {

    private final AjApiClient ajApiClient;
    private final AccessTokenHolder accessTokenHolder;
    private final ObjectMapper objectMapper;

    public Map<String, List<CategoryResponse>> listCategories(String token) {
        accessTokenHolder.setAccessToken(token);
        try {
            return Map.of("categories", ajApiClient.listCategories());
        } catch (McpToolException ex) {
            throw ex;
        } catch (Exception ex) {
            log.error("Error listing categories", ex);
            throw McpToolException.apiError("Failed to list categories: " + ex.getMessage(), ex);
        }
    }

    public McpStatelessServerFeatures.SyncToolSpecification buildToolListCategories() {
        return McpStatelessServerFeatures.SyncToolSpecification.builder()
                .callHandler((ctx, _) -> {
                    var result = listCategories((String) ctx.get(AjMcpApplication.TOKEN_KEY));
                    try {
                        Object structured = objectMapper.convertValue(result, Map.class);
                        String json = objectMapper.writeValueAsString(structured);
                        return new McpSchema.CallToolResult(
                                List.of(new McpSchema.TextContent(json)), false, structured, null);
                    } catch (Exception e) {
                        throw new RuntimeException(e);
                    }
                })
                .tool(McpSchema.Tool.builder()
                        .name("aj_list_categories")
                        .title("AJ: List Categories")
                        .description("List all available product categories. Use category IDs when creating products with aj_add_product.")
                        .annotations(new McpSchema.ToolAnnotations(null, true, false, false, true, null))
                        .inputSchema(McpJsonDefaults.getMapper(), """
                                {
                                  "type": "object",
                                  "properties": {},
                                  "required": []
                                }
                                """)
                        .outputSchema(McpJsonDefaults.getMapper(), """
                                {
                                  "type": "object",
                                  "properties": {
                                    "categories": {
                                      "type": "array",
                                      "items": {
                                        "type": "object",
                                        "properties": {
                                          "id": {
                                            "type": "integer",
                                            "description": "Category ID"
                                          },
                                          "name": {
                                            "type": "string",
                                            "description": "Category name"
                                          },
                                          "description": {
                                            "type": ["string", "null"],
                                            "description": "Category description"
                                              }
                                        },
                                        "required": ["id", "name"]
                                      }
                                    }
                                  },
                                  "required": ["categories"]
                                }
                                """)
                        .build())
                .build();
    }
}
