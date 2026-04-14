package pl.devstyle.aj.core.oauth2;

import tools.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;
import pl.devstyle.aj.TestcontainersConfiguration;
import pl.devstyle.aj.api.LoginRequest;
import pl.devstyle.aj.core.security.JwtTokenProvider;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.util.Base64;

import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.notNullValue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@Import(TestcontainersConfiguration.class)
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.MOCK)
@AutoConfigureMockMvc
@Transactional
class OAuth2IntegrationTests {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private JwtTokenProvider jwtTokenProvider;

    private String loginAndGetToken(String username, String password) throws Exception {
        var request = new LoginRequest(username, password);
        var result = mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andReturn();
        var body = objectMapper.readTree(result.getResponse().getContentAsString());
        return body.get("token").asText();
    }

    private String registerClient(String redirectUri) throws Exception {
        var body = """
                {
                    "client_name": "Test MCP Client",
                    "grant_types": ["authorization_code", "refresh_token"],
                    "redirect_uris": ["%s"],
                    "response_types": ["code"],
                    "token_endpoint_auth_method": "none",
                    "scope": "mcp:read mcp:edit"
                }
                """.formatted(redirectUri);

        var result = mockMvc.perform(post("/oauth2/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isCreated())
                .andReturn();

        return result.getResponse().getContentAsString();
    }

    private String generateCodeVerifier() {
        var bytes = new byte[32];
        new SecureRandom().nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    private String generateCodeChallenge(String codeVerifier) throws Exception {
        var digest = MessageDigest.getInstance("SHA-256");
        var hash = digest.digest(codeVerifier.getBytes(StandardCharsets.US_ASCII));
        return Base64.getUrlEncoder().withoutPadding().encodeToString(hash);
    }

    @Test
    void getMetadata_returnsOAuth2ServerMetadata() throws Exception {
        mockMvc.perform(get("/.well-known/oauth-authorization-server"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.issuer").value(notNullValue()))
                .andExpect(jsonPath("$.authorization_endpoint").value(containsString("/oauth2/authorize")))
                .andExpect(jsonPath("$.token_endpoint").value(containsString("/oauth2/token")))
                .andExpect(jsonPath("$.registration_endpoint").value(containsString("/oauth2/register")));
    }

    @Test
    void registerClient_returns201WithClientCredentials() throws Exception {
        var body = """
                {
                    "client_name": "My MCP Client",
                    "grant_types": ["authorization_code"],
                    "redirect_uris": ["http://localhost:3000/callback"],
                    "response_types": ["code"],
                    "token_endpoint_auth_method": "client_secret_post",
                    "scope": "mcp:read mcp:edit"
                }
                """;

        mockMvc.perform(post("/oauth2/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.client_id").value(notNullValue()))
                .andExpect(jsonPath("$.client_secret").value(notNullValue()))
                .andExpect(jsonPath("$.client_name").value("My MCP Client"));
    }

    @Test
    void registerClient_withInvalidName_returns400() throws Exception {
        var body = """
                {
                    "grant_types": ["authorization_code"],
                    "redirect_uris": ["http://localhost:3000/callback"],
                    "token_endpoint_auth_method": "none"
                }
                """;

        mockMvc.perform(post("/oauth2/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("invalid_client_metadata"));
    }

    @Test
    void authorizationCodeFlow_fullCycle() throws Exception {
        var token = loginAndGetToken("admin", "admin123");
        var redirectUri = "http://localhost:3000/callback";

        // Register client
        var registrationJson = registerClient(redirectUri);
        var registration = objectMapper.readTree(registrationJson);
        var clientId = registration.get("client_id").asText();

        // Generate PKCE
        var codeVerifier = generateCodeVerifier();
        var codeChallenge = generateCodeChallenge(codeVerifier);

        // Authorize
        var authorizeResult = mockMvc.perform(post("/oauth2/authorize")
                        .header("Authorization", "Bearer " + token)
                        .param("client_id", clientId)
                        .param("redirect_uri", redirectUri)
                        .param("response_type", "code")
                        .param("scope", "mcp:read mcp:edit")
                        .param("state", "test-state")
                        .param("code_challenge", codeChallenge)
                        .param("code_challenge_method", "S256"))
                .andExpect(status().isFound())
                .andReturn();

        var location = authorizeResult.getResponse().getHeader("Location");
        assert location != null && location.startsWith(redirectUri);
        var code = extractQueryParam(location, "code");
        assert location.contains("state=test-state");

        // Token exchange
        mockMvc.perform(post("/oauth2/token")
                        .param("grant_type", "authorization_code")
                        .param("code", code)
                        .param("redirect_uri", redirectUri)
                        .param("client_id", clientId)
                        .param("code_verifier", codeVerifier))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.access_token").value(notNullValue()))
                .andExpect(jsonPath("$.refresh_token").value(notNullValue()))
                .andExpect(jsonPath("$.token_type").value("Bearer"));
    }

    @Test
    void authorize_withPkce_requiresCodeVerifierOnTokenExchange() throws Exception {
        var token = loginAndGetToken("admin", "admin123");
        var redirectUri = "http://localhost:3000/callback";

        var registrationJson = registerClient(redirectUri);
        var registration = objectMapper.readTree(registrationJson);
        var clientId = registration.get("client_id").asText();

        var codeVerifier = generateCodeVerifier();
        var codeChallenge = generateCodeChallenge(codeVerifier);

        // Authorize with PKCE
        var authorizeResult = mockMvc.perform(post("/oauth2/authorize")
                        .header("Authorization", "Bearer " + token)
                        .param("client_id", clientId)
                        .param("redirect_uri", redirectUri)
                        .param("response_type", "code")
                        .param("code_challenge", codeChallenge)
                        .param("code_challenge_method", "S256"))
                .andExpect(status().isFound())
                .andReturn();

        var code = extractQueryParam(authorizeResult.getResponse().getHeader("Location"), "code");

        // Token exchange without code_verifier should fail
        mockMvc.perform(post("/oauth2/token")
                        .param("grant_type", "authorization_code")
                        .param("code", code)
                        .param("redirect_uri", redirectUri)
                        .param("client_id", clientId))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("invalid_grant"));
    }

    @Test
    void authorize_withInvalidRedirectUri_returns400() throws Exception {
        var token = loginAndGetToken("admin", "admin123");
        var redirectUri = "http://localhost:3000/callback";

        var registrationJson = registerClient(redirectUri);
        var registration = objectMapper.readTree(registrationJson);
        var clientId = registration.get("client_id").asText();

        mockMvc.perform(post("/oauth2/authorize")
                        .header("Authorization", "Bearer " + token)
                        .param("client_id", clientId)
                        .param("redirect_uri", "http://evil.com/callback")
                        .param("response_type", "code"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("invalid_request"));
    }

    @Test
    void tokenExchange_withRefreshToken_returnsNewAccessToken() throws Exception {
        var token = loginAndGetToken("admin", "admin123");
        var redirectUri = "http://localhost:3000/callback";

        var registrationJson = registerClient(redirectUri);
        var registration = objectMapper.readTree(registrationJson);
        var clientId = registration.get("client_id").asText();

        var codeVerifier = generateCodeVerifier();
        var codeChallenge = generateCodeChallenge(codeVerifier);

        // Authorize
        var authorizeResult = mockMvc.perform(post("/oauth2/authorize")
                        .header("Authorization", "Bearer " + token)
                        .param("client_id", clientId)
                        .param("redirect_uri", redirectUri)
                        .param("response_type", "code")
                        .param("code_challenge", codeChallenge)
                        .param("code_challenge_method", "S256"))
                .andExpect(status().isFound())
                .andReturn();

        var code = extractQueryParam(authorizeResult.getResponse().getHeader("Location"), "code");

        // Token exchange
        var tokenResult = mockMvc.perform(post("/oauth2/token")
                        .param("grant_type", "authorization_code")
                        .param("code", code)
                        .param("redirect_uri", redirectUri)
                        .param("client_id", clientId)
                        .param("code_verifier", codeVerifier))
                .andExpect(status().isOk())
                .andReturn();

        var tokenJson = objectMapper.readTree(tokenResult.getResponse().getContentAsString());
        var refreshToken = tokenJson.get("refresh_token").asText();

        // Refresh token exchange
        mockMvc.perform(post("/oauth2/token")
                        .param("grant_type", "refresh_token")
                        .param("refresh_token", refreshToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.access_token").value(notNullValue()))
                .andExpect(jsonPath("$.refresh_token").value(notNullValue()))
                .andExpect(jsonPath("$.token_type").value("Bearer"));
    }

    @Test
    void tokenExchange_withInvalidCode_returns400() throws Exception {
        mockMvc.perform(post("/oauth2/token")
                        .param("grant_type", "authorization_code")
                        .param("code", "invalid-code")
                        .param("redirect_uri", "http://localhost:3000/callback")
                        .param("client_id", "nonexistent"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("invalid_grant"));
    }

    private String extractQueryParam(String url, String paramName) {
        var queryStart = url.indexOf('?');
        if (queryStart == -1) return null;
        var query = url.substring(queryStart + 1);
        for (var param : query.split("&")) {
            var parts = param.split("=", 2);
            if (parts[0].equals(paramName)) {
                return parts.length > 1 ? parts[1] : "";
            }
        }
        return null;
    }
}
