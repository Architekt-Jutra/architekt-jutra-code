package pl.devstyle.aj.mcp;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.test.context.SpringBootTest;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
class ConfigurationTests {

    @Value("${server.port}")
    private int serverPort;

    @Value("${management.server.port}")
    private int managementPort;

    @Test
    void serverPort_isConfiguredTo8081() {
        assertThat(serverPort).isEqualTo(8081);
    }

    @Test
    void managementPort_isConfiguredTo9081() {
        assertThat(managementPort).isEqualTo(9081);
    }
}
