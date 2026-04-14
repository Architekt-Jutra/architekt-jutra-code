package pl.devstyle.aj.mcp.controller;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/.well-known")
public class WellKnownController {

    @Value("${aj.oauth.server-url}")
    private String authServerUrl;

    @Value("${aj.mcp.base-url}")
    private String mcpBaseUrl;

    @GetMapping({"/oauth-protected-resource", "/oauth-protected-resource/**"})
    public Map<String, Object> getProtectedResourceMetadata() {
        return Map.of(
                "resource", mcpBaseUrl,
                "authorization_servers", new String[]{authServerUrl},
                "bearer_methods_supported", new String[]{"header"},
                "scopes_supported", new String[]{"mcp:read", "mcp:edit"}
        );
    }
}
