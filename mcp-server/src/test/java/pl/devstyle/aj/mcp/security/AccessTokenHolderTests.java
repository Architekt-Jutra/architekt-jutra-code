package pl.devstyle.aj.mcp.security;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class AccessTokenHolderTests {

    private final AccessTokenHolder holder = new AccessTokenHolder();

    @AfterEach
    void cleanup() {
        holder.clear();
    }

    @Test
    void threadLocal_storesAndClearsToken() {
        holder.setAccessToken("test-token");
        assertThat(holder.getAccessToken()).isEqualTo("test-token");
        assertThat(holder.hasAccessToken()).isTrue();

        holder.clear();
        assertThat(holder.getAccessToken()).isNull();
        assertThat(holder.hasAccessToken()).isFalse();
    }
}
