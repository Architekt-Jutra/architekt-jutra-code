package pl.devstyle.aj.core.oauth2;

import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.oauth2.server.authorization.client.RegisteredClient;
import org.springframework.security.oauth2.server.authorization.client.RegisteredClientRepository;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
public class OAuth2MetadataController {

    private final RegisteredClientRepository registeredClientRepository;

    public OAuth2MetadataController(RegisteredClientRepository registeredClientRepository) {
        this.registeredClientRepository = registeredClientRepository;
    }

    @GetMapping(value = "/api/oauth2/client-info", produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<Map<String, Object>> getClientInfo(@RequestParam("client_id") String clientId) {
        RegisteredClient client = registeredClientRepository.findByClientId(clientId);
        if (client == null) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
        return ResponseEntity.ok(Map.of(
                "client_id", client.getClientId(),
                "client_name", client.getClientName() != null ? client.getClientName() : "Unknown Application",
                "scopes", client.getScopes()
        ));
    }

    @GetMapping(value = "/.well-known/oauth-authorization-server", produces = MediaType.APPLICATION_JSON_VALUE)
    public Map<String, Object> getAuthorizationServerMetadata(HttpServletRequest request) {
        String baseUrl = getBaseUrl(request);

        return Map.of(
                "issuer", baseUrl,
                "authorization_endpoint", baseUrl + "/oauth2/authorize",
                "token_endpoint", baseUrl + "/oauth2/token",
                "registration_endpoint", baseUrl + "/oauth2/register",
                "grant_types_supported", new String[]{"authorization_code", "refresh_token"},
                "response_types_supported", new String[]{"code"},
                "code_challenge_methods_supported", new String[]{"S256"},
                "token_endpoint_auth_methods_supported", new String[]{"client_secret_post", "client_secret_basic", "none"},
                "scopes_supported", new String[]{"mcp:read", "mcp:edit"}
        );
    }

    private String getBaseUrl(HttpServletRequest request) {
        String scheme = request.getScheme();
        String serverName = request.getServerName();
        int serverPort = request.getServerPort();

        String forwardedProto = request.getHeader("X-Forwarded-Proto");
        String forwardedHost = request.getHeader("X-Forwarded-Host");
        String forwardedPort = request.getHeader("X-Forwarded-Port");

        if (forwardedProto != null) {
            scheme = forwardedProto;
        }
        if (forwardedHost != null) {
            serverName = forwardedHost;
        }
        if (forwardedPort != null) {
            serverPort = Integer.parseInt(forwardedPort);
        }

        if ((scheme.equals("http") && serverPort == 80) || (scheme.equals("https") && serverPort == 443)) {
            return scheme + "://" + serverName;
        }

        // When behind a reverse proxy with X-Forwarded-Proto, omit the local container port
        if (forwardedProto != null && forwardedPort == null) {
            return scheme + "://" + serverName;
        }

        return scheme + "://" + serverName + ":" + serverPort;
    }
}
