package pl.devstyle.aj.mcp;

import com.fasterxml.jackson.databind.ObjectMapper;
import io.modelcontextprotocol.common.McpTransportContext;
import io.modelcontextprotocol.json.McpJsonMapper;
import io.modelcontextprotocol.json.schema.JsonSchemaValidator;
import io.modelcontextprotocol.server.McpServer;
import io.modelcontextprotocol.server.McpStatelessSyncServer;
import io.modelcontextprotocol.server.transport.WebMvcStatelessServerTransport;
import io.modelcontextprotocol.spec.McpSchema;
import pl.devstyle.aj.mcp.config.JacksonMcpJsonMapper;
import pl.devstyle.aj.mcp.config.LoggingJsonSchemaValidator;
import pl.devstyle.aj.mcp.service.CategoryService;
import pl.devstyle.aj.mcp.service.ProductService;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.web.servlet.function.RouterFunction;
import org.springframework.web.servlet.function.ServerResponse;

import java.util.Map;

@SpringBootApplication
public class AjMcpApplication {

    public static void main(String[] args) {
        SpringApplication.run(AjMcpApplication.class, args);
    }

    @Bean
    McpJsonMapper mcpJsonMapper(ObjectMapper objectMapper) {
        return new JacksonMcpJsonMapper(objectMapper);
    }

    public static final String TOKEN_KEY = "bearer_token";

    @Bean
    WebMvcStatelessServerTransport webMvcStatelessServerTransport(McpJsonMapper mcpJsonMapper) {
        return WebMvcStatelessServerTransport.builder()
                .jsonMapper(mcpJsonMapper)
                .messageEndpoint("/")
                .contextExtractor(request -> {
                    String auth = request.headers().firstHeader("Authorization");
                    if (auth != null && auth.startsWith("Bearer ")) {
                        return McpTransportContext.create(Map.of(TOKEN_KEY, auth.substring("Bearer ".length())));
                    }
                    return McpTransportContext.EMPTY;
                })
                .build();
    }

    @Bean
    RouterFunction<ServerResponse> routerFunction(WebMvcStatelessServerTransport transport) {
        return transport.getRouterFunction();
    }

    @Bean
    McpStatelessSyncServer mcpStatelessServer(WebMvcStatelessServerTransport transport,
                                              McpJsonMapper mcpJsonMapper,
                                              ObjectMapper objectMapper,
                                              ProductService productService,
                                              CategoryService categoryService) {
        JsonSchemaValidator noOpValidator = (schema, instance) ->
                JsonSchemaValidator.ValidationResponse.asValid(null);
        return McpServer.sync(transport)
                .jsonMapper(mcpJsonMapper)
                .jsonSchemaValidator(new LoggingJsonSchemaValidator(noOpValidator, objectMapper))
                .capabilities(McpSchema.ServerCapabilities.builder()
                        .tools(true)
                        .prompts(false)
                        .resources(false, false)
                        .build())
                .tools(
                        productService.buildToolListProducts(),
                        productService.buildToolAddProduct(),
                        categoryService.buildToolListCategories()
                )
                .build();
    }
}
