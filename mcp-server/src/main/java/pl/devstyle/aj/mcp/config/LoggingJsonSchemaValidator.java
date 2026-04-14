package pl.devstyle.aj.mcp.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import io.modelcontextprotocol.json.schema.JsonSchemaValidator;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

import java.util.Map;

@Slf4j
@RequiredArgsConstructor
public class LoggingJsonSchemaValidator implements JsonSchemaValidator {

    private final JsonSchemaValidator delegate;
    private final ObjectMapper objectMapper;

    @Override
    public ValidationResponse validate(Map<String, Object> schema, Object instance) {
        try {
            log.info("=== JSON Schema Validation Starting ===");
            log.debug("Schema: {}", objectMapper.writerWithDefaultPrettyPrinter().writeValueAsString(schema));
            log.info("Instance to validate: {}",
                    objectMapper.writerWithDefaultPrettyPrinter().writeValueAsString(instance));

            ValidationResponse response = delegate.validate(schema, instance);

            log.info("=== Validation completed, response: {} ===", response);

            return response;
        } catch (Exception ex) {
            log.error("Error during JSON schema validation", ex);
            throw new RuntimeException("Schema validation error", ex);
        }
    }
}
