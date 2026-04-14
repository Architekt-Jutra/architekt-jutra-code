package pl.devstyle.aj.mcp.config;

import com.fasterxml.jackson.databind.JavaType;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.modelcontextprotocol.json.McpJsonMapper;
import io.modelcontextprotocol.json.TypeRef;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;

public class JacksonMcpJsonMapper implements McpJsonMapper {

    private static final Logger log = LoggerFactory.getLogger(JacksonMcpJsonMapper.class);
    private final ObjectMapper objectMapper;

    public JacksonMcpJsonMapper(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
    }

    @Override
    public <T> T readValue(String json, Class<T> type) throws IOException {
        log.debug("readValue(String, {})", type.getSimpleName());
        return objectMapper.readValue(json, type);
    }

    @Override
    public <T> T readValue(byte[] bytes, Class<T> type) throws IOException {
        log.debug("readValue(byte[], {})", type.getSimpleName());
        return objectMapper.readValue(bytes, type);
    }

    @Override
    public <T> T readValue(String json, TypeRef<T> typeRef) throws IOException {
        JavaType javaType = objectMapper.getTypeFactory().constructType(typeRef.getType());
        log.debug("readValue(String, TypeRef<{}>)", javaType);
        return objectMapper.readValue(json, javaType);
    }

    @Override
    public <T> T readValue(byte[] bytes, TypeRef<T> typeRef) throws IOException {
        JavaType javaType = objectMapper.getTypeFactory().constructType(typeRef.getType());
        log.debug("readValue(byte[], TypeRef<{}>)", javaType);
        return objectMapper.readValue(bytes, javaType);
    }

    @Override
    public <T> T convertValue(Object value, Class<T> type) {
        log.debug("convertValue({}, {})", value != null ? value.getClass().getSimpleName() : "null", type.getSimpleName());
        return objectMapper.convertValue(value, type);
    }

    @Override
    public <T> T convertValue(Object value, TypeRef<T> typeRef) {
        JavaType javaType = objectMapper.getTypeFactory().constructType(typeRef.getType());
        log.debug("convertValue({}, TypeRef<{}>)", value != null ? value.getClass().getSimpleName() : "null", javaType);
        return objectMapper.convertValue(value, javaType);
    }

    @Override
    public String writeValueAsString(Object value) throws IOException {
        try {
            String result = objectMapper.writeValueAsString(value);
            log.info("writeValueAsString({}) => {}", value != null ? value.getClass().getSimpleName() : "null", result);
            return result;
        } catch (Exception e) {
            log.error("writeValueAsString FAILED for {}: {}", value != null ? value.getClass().getName() : "null", e.getMessage(), e);
            throw e;
        }
    }

    @Override
    public byte[] writeValueAsBytes(Object value) throws IOException {
        try {
            byte[] result = objectMapper.writeValueAsBytes(value);
            log.debug("writeValueAsBytes({}) => {}bytes", value != null ? value.getClass().getSimpleName() : "null", result.length);
            return result;
        } catch (Exception e) {
            log.error("writeValueAsBytes FAILED for {}: {}", value != null ? value.getClass().getName() : "null", e.getMessage(), e);
            throw e;
        }
    }
}
