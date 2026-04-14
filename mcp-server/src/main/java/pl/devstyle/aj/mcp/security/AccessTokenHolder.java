package pl.devstyle.aj.mcp.security;

import org.springframework.stereotype.Component;

/**
 * ThreadLocal-based holder for the current request's JWT access token.
 * Populated by McpJwtFilter, consumed by RestClient interceptor for forwarding to the aj backend.
 */
@Component
public class AccessTokenHolder {

    private static final ThreadLocal<String> TOKEN = new ThreadLocal<>();

    public void setAccessToken(String token) {
        TOKEN.set(token);
    }

    public String getAccessToken() {
        return TOKEN.get();
    }

    public boolean hasAccessToken() {
        return TOKEN.get() != null;
    }

    public void clear() {
        TOKEN.remove();
    }
}
