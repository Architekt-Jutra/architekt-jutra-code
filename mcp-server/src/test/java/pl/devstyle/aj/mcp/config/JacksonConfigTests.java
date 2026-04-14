package pl.devstyle.aj.mcp.config;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

import java.time.LocalDateTime;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;

@SpringBootTest
class JacksonConfigTests {

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void objectMapper_serializesDatesAsIsoStrings() throws JsonProcessingException {
        var date = LocalDateTime.of(2026, 4, 4, 12, 0, 0);
        var json = objectMapper.writeValueAsString(date);

        assertThat(json).contains("2026-04-04");
        assertThat(json).doesNotContain("[2026");
    }

    @Test
    void objectMapper_ignoresUnknownProperties() {
        var json = """
                {"known": "value", "unknown": "ignored"}
                """;

        assertThatCode(() -> objectMapper.readValue(json, KnownFieldsOnly.class))
                .doesNotThrowAnyException();
    }

    record KnownFieldsOnly(String known) {}
}
