package pl.devstyle.aj.mcp.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import io.modelcontextprotocol.json.McpJsonDefaults;
import io.modelcontextprotocol.server.McpStatelessServerFeatures;
import io.modelcontextprotocol.spec.McpSchema;
import pl.devstyle.aj.mcp.AjMcpApplication;
import pl.devstyle.aj.mcp.security.AccessTokenHolder;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import pl.devstyle.aj.mcp.client.AjApiClient;
import pl.devstyle.aj.mcp.client.dto.CreateProductRequest;
import pl.devstyle.aj.mcp.client.dto.ProductResponse;
import pl.devstyle.aj.mcp.exception.McpToolException;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

@Service
@Slf4j
@RequiredArgsConstructor
public class ProductService {

    private final AjApiClient ajApiClient;
    private final AccessTokenHolder accessTokenHolder;
    private final ObjectMapper objectMapper;

    public Map<String, List<ProductResponse>> listProducts(String token, String search) {
        accessTokenHolder.setAccessToken(token);
        try {
            return Map.of("products", ajApiClient.listProducts(search));
        } catch (McpToolException ex) {
            throw ex;
        } catch (Exception ex) {
            log.error("Error listing products", ex);
            throw McpToolException.apiError("Failed to list products: " + ex.getMessage(), ex);
        }
    }

    public ProductResponse addProduct(String token, Map<String, Object> arguments) {
        accessTokenHolder.setAccessToken(token);
        try {
            String name = (String) arguments.get("name");
            String description = (String) arguments.get("description");
            String photoUrl = (String) arguments.get("photoUrl");
            BigDecimal price = arguments.get("price") != null
                    ? new BigDecimal(arguments.get("price").toString())
                    : null;
            String sku = (String) arguments.get("sku");
            Long categoryId = arguments.get("categoryId") != null
                    ? ((Number) arguments.get("categoryId")).longValue()
                    : null;

            var request = new CreateProductRequest(name, description, photoUrl, price, sku, categoryId);
            return ajApiClient.createProduct(request);
        } catch (McpToolException ex) {
            throw ex;
        } catch (Exception ex) {
            log.error("Error adding product", ex);
            throw McpToolException.apiError("Failed to add product: " + ex.getMessage(), ex);
        }
    }

    public McpStatelessServerFeatures.SyncToolSpecification buildToolListProducts() {
        return McpStatelessServerFeatures.SyncToolSpecification.builder()
                .callHandler((ctx, req) -> {
                    var result = listProducts(
                            (String) ctx.get(AjMcpApplication.TOKEN_KEY),
                            (String) req.arguments().get("search"));
                    try {
                        String json = objectMapper.writeValueAsString(result);
                        return new McpSchema.CallToolResult(
                                List.of(new McpSchema.TextContent(json)), false, result, null);
                    } catch (Exception e) {
                        throw new RuntimeException(e);
                    }
                })
                .tool(McpSchema.Tool.builder()
                        .name("aj_list_products")
                        .title("AJ: List Products")
                        .description("Search and list products. Optionally filter by search text.")
                        .annotations(new McpSchema.ToolAnnotations(null, true, false, false, true, null))
                        .inputSchema(McpJsonDefaults.getMapper(), """
                                {
                                  "type": "object",
                                  "properties": {
                                    "search": {
                                      "type": "string",
                                      "description": "Optional text to search products by name or description"
                                    }
                                  },
                                  "required": []
                                }
                                """)
                        .outputSchema(McpJsonDefaults.getMapper(), """
                                {
                                  "type": "object",
                                  "properties": {
                                    "products": {
                                      "type": "array",
                                      "items": {
                                        "type": "object",
                                        "properties": {
                                          "id": {
                                            "type": "integer",
                                            "description": "Product ID"
                                          },
                                          "name": {
                                            "type": "string",
                                            "description": "Product name"
                                          },
                                          "description": {
                                            "type": ["string", "null"],
                                            "description": "Product description"
                                          },
                                          "photoUrl": {
                                            "type": ["string", "null"],
                                            "description": "URL to product photo"
                                          },
                                          "price": {
                                            "type": "number",
                                            "description": "Product price"
                                          },
                                          "sku": {
                                            "type": "string",
                                            "description": "Stock keeping unit"
                                          },
                                          "category": {
                                            "type": ["object", "null"],
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
                                              },
                                              "createdAt": {
                                                "type": ["string", "null"],
                                                "description": "Creation timestamp"
                                              },
                                              "updatedAt": {
                                                "type": ["string", "null"],
                                                "description": "Last update timestamp"
                                              }
                                            },
                                            "required": ["id", "name"]
                                          },
                                          "pluginData": {
                                            "type": ["object", "null"],
                                            "description": "Plugin-specific data"
                                          },
                                          "createdAt": {
                                            "type": ["string", "null"],
                                            "description": "Creation timestamp"
                                          },
                                          "updatedAt": {
                                            "type": ["string", "null"],
                                            "description": "Last update timestamp"
                                          }
                                        },
                                        "required": ["id", "name", "price", "sku"]
                                      }
                                    }
                                  },
                                  "required": ["products"]
                                }
                                """)
                        .build())
                .build();
    }

    public McpStatelessServerFeatures.SyncToolSpecification buildToolAddProduct() {
        return McpStatelessServerFeatures.SyncToolSpecification.builder()
                .callHandler((ctx, req) -> {
                    var result = addProduct(
                            (String) ctx.get(AjMcpApplication.TOKEN_KEY),
                            req.arguments());
                    try {
                        String json = objectMapper.writeValueAsString(result);
                        return new McpSchema.CallToolResult(
                                List.of(new McpSchema.TextContent(json)), false, result, null);
                    } catch (Exception e) {
                        throw new RuntimeException(e);
                    }
                })
                .tool(McpSchema.Tool.builder()
                        .name("aj_add_product")
                        .title("AJ: Add Product")
                        .description("Create a new product. Requires name, price, sku, and categoryId. Use aj_list_categories to find valid category IDs.")
                        .annotations(new McpSchema.ToolAnnotations(null, false, false, false, true, null))
                        .inputSchema(McpJsonDefaults.getMapper(), """
                                {
                                  "type": "object",
                                  "properties": {
                                    "name": {
                                      "type": "string",
                                      "description": "Product name"
                                    },
                                    "description": {
                                      "type": "string",
                                      "description": "Product description"
                                    },
                                    "photoUrl": {
                                      "type": "string",
                                      "description": "URL to product photo"
                                    },
                                    "price": {
                                      "type": "number",
                                      "description": "Product price"
                                    },
                                    "sku": {
                                      "type": "string",
                                      "description": "Stock keeping unit"
                                    },
                                    "categoryId": {
                                      "type": "integer",
                                      "description": "Category ID. Use aj_list_categories to find valid IDs."
                                    }
                                  },
                                  "required": ["name", "price", "sku", "categoryId"]
                                }
                                """)
                        .outputSchema(McpJsonDefaults.getMapper(), """
                                {
                                  "type": "object",
                                  "properties": {
                                    "id": {
                                      "type": "integer",
                                      "description": "Product ID"
                                    },
                                    "name": {
                                      "type": "string",
                                      "description": "Product name"
                                    },
                                    "description": {
                                      "type": ["string", "null"],
                                      "description": "Product description"
                                    },
                                    "photoUrl": {
                                      "type": ["string", "null"],
                                      "description": "URL to product photo"
                                    },
                                    "price": {
                                      "type": "number",
                                      "description": "Product price"
                                    },
                                    "sku": {
                                      "type": "string",
                                      "description": "Stock keeping unit"
                                    },
                                    "category": {
                                      "type": ["object", "null"],
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
                                        },
                                        "createdAt": {
                                          "type": ["string", "null"],
                                          "description": "Creation timestamp"
                                        },
                                        "updatedAt": {
                                          "type": ["string", "null"],
                                          "description": "Last update timestamp"
                                        }
                                      },
                                      "required": ["id", "name"]
                                    },
                                    "pluginData": {
                                      "type": ["object", "null"],
                                      "description": "Plugin-specific data"
                                    },
                                    "createdAt": {
                                      "type": ["string", "null"],
                                      "description": "Creation timestamp"
                                    },
                                    "updatedAt": {
                                      "type": ["string", "null"],
                                      "description": "Last update timestamp"
                                    }
                                  },
                                  "required": ["id", "name", "price", "sku"]
                                }
                                """)
                        .build())
                .build();
    }
}
