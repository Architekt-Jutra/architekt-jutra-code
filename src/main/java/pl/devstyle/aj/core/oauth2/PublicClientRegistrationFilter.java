package pl.devstyle.aj.core.oauth2;

import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.server.ServletServerHttpResponse;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.oauth2.core.AuthorizationGrantType;
import org.springframework.security.oauth2.core.ClientAuthenticationMethod;
import org.springframework.security.oauth2.server.authorization.client.RegisteredClient;
import org.springframework.security.oauth2.server.authorization.client.RegisteredClientRepository;
import org.springframework.security.oauth2.server.authorization.oidc.OidcClientRegistration;
import org.springframework.security.oauth2.server.authorization.oidc.http.converter.OidcClientRegistrationHttpMessageConverter;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.time.Instant;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Slf4j
public class PublicClientRegistrationFilter extends OncePerRequestFilter {

    private static final String REGISTRATION_ENDPOINT = "/oauth2/register";
    private static final List<String> ALLOWED_SCOPES = List.of("mcp:read", "mcp:edit");

    private final RegisteredClientRepository registeredClientRepository;
    private final PasswordEncoder passwordEncoder;
    private final ObjectMapper objectMapper;
    private final OidcClientRegistrationHttpMessageConverter oidcConverter;

    public PublicClientRegistrationFilter(RegisteredClientRepository registeredClientRepository,
                                          PasswordEncoder passwordEncoder) {
        this.registeredClientRepository = registeredClientRepository;
        this.passwordEncoder = passwordEncoder;
        this.objectMapper = new ObjectMapper();
        this.oidcConverter = new OidcClientRegistrationHttpMessageConverter();
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        if (!("POST".equals(request.getMethod()) && REGISTRATION_ENDPOINT.equals(request.getRequestURI()))) {
            filterChain.doFilter(request, response);
            return;
        }

        try {
            handleRegistrationRequest(request, response);
        } catch (IllegalArgumentException e) {
            log.warn("Client registration failed | reason={}", e.getMessage());
            writeError(response, OAuth2Error.INVALID_CLIENT_METADATA, e.getMessage());
        } catch (Exception e) {
            log.error("Client registration error | reason={}", e.getMessage(), e);
            writeError(response, OAuth2Error.SERVER_ERROR, "An error occurred while processing the registration request");
        }
    }

    @SuppressWarnings("unchecked")
    private void handleRegistrationRequest(HttpServletRequest request, HttpServletResponse response) throws IOException {
        Map<String, Object> requestBody = objectMapper.readValue(request.getInputStream(), Map.class);

        String clientName = (String) requestBody.get("client_name");
        List<String> responseTypes = (List<String>) requestBody.get("response_types");
        List<String> grantTypes = (List<String>) requestBody.get("grant_types");
        List<String> redirectUris = (List<String>) requestBody.get("redirect_uris");
        String tokenEndpointAuthMethod = (String) requestBody.get("token_endpoint_auth_method");
        String scope = (String) requestBody.get("scope");

        validateClientName(clientName);
        validateRedirectUris(redirectUris, grantTypes);
        List<String> scopes = (scope != null && !scope.trim().isEmpty())
                ? Arrays.asList(scope.trim().split("\\s+"))
                : ALLOWED_SCOPES;
        validateScope(scopes);

        String clientId = UUID.randomUUID().toString();
        String clientSecret = UUID.randomUUID().toString();

        var builder = RegisteredClient.withId(UUID.randomUUID().toString())
                .clientId(clientId)
                .clientName(clientName)
                .clientIdIssuedAt(Instant.now())
                .clientSecret(passwordEncoder.encode(clientSecret))
                .redirectUris(uris -> uris.addAll(redirectUris))
                .scopes(scopeSet -> scopeSet.addAll(scopes));

        configureAuthenticationMethod(builder, tokenEndpointAuthMethod);
        configureGrantTypes(builder, grantTypes);

        var registeredClient = builder.build();
        registeredClientRepository.save(registeredClient);

        var oidcRegistration = OidcClientRegistration.builder()
                .clientId(registeredClient.getClientId())
                .clientSecret(clientSecret)
                .clientName(registeredClient.getClientName())
                .clientIdIssuedAt(registeredClient.getClientIdIssuedAt())
                .redirectUris(uris -> uris.addAll(registeredClient.getRedirectUris()))
                .grantTypes(grants -> grants.addAll(grantTypes))
                .responseTypes(types -> { if (responseTypes != null) types.addAll(responseTypes); })
                .scopes(scopeSet -> scopeSet.addAll(registeredClient.getScopes()))
                .tokenEndpointAuthenticationMethod(tokenEndpointAuthMethod)
                .clientSecretExpiresAt(Instant.ofEpochSecond(0))
                .build();

        var httpResponse = new ServletServerHttpResponse(response);
        httpResponse.setStatusCode(HttpStatus.CREATED);
        oidcConverter.write(oidcRegistration, MediaType.APPLICATION_JSON, httpResponse);

        log.info("Client registered | client_id={} | client_name={} | grant_types={} | scopes={} | auth_method={}",
                clientId, clientName, grantTypes, scopes, tokenEndpointAuthMethod);
    }

    private void configureAuthenticationMethod(RegisteredClient.Builder builder, String tokenEndpointAuthMethod) {
        if (tokenEndpointAuthMethod == null) {
            tokenEndpointAuthMethod = "client_secret_post";
        }
        switch (tokenEndpointAuthMethod) {
            case "client_secret_post" -> builder.clientAuthenticationMethod(ClientAuthenticationMethod.CLIENT_SECRET_POST);
            case "client_secret_basic" -> builder.clientAuthenticationMethod(ClientAuthenticationMethod.CLIENT_SECRET_BASIC);
            case "none" -> builder.clientAuthenticationMethod(ClientAuthenticationMethod.NONE);
            default -> throw new IllegalArgumentException(
                    "token_endpoint_auth_method must be 'client_secret_post', 'client_secret_basic', or 'none'");
        }
    }

    private void configureGrantTypes(RegisteredClient.Builder builder, List<String> grantTypes) {
        if (grantTypes == null || grantTypes.isEmpty()) {
            builder.authorizationGrantType(AuthorizationGrantType.AUTHORIZATION_CODE);
            return;
        }
        for (String grantType : grantTypes) {
            switch (grantType) {
                case "authorization_code" -> builder.authorizationGrantType(AuthorizationGrantType.AUTHORIZATION_CODE);
                case "refresh_token" -> builder.authorizationGrantType(AuthorizationGrantType.REFRESH_TOKEN);
                default -> throw new IllegalArgumentException("Unsupported grant type: " + grantType);
            }
        }
    }

    private void validateClientName(String clientName) {
        if (clientName == null || clientName.trim().isEmpty()) {
            throw new IllegalArgumentException("client_name is required and cannot be empty");
        }
        if (clientName.length() > 255) {
            throw new IllegalArgumentException("client_name cannot exceed 255 characters");
        }
    }

    private void validateRedirectUris(List<String> redirectUris, List<String> grantTypes) {
        if (grantTypes != null && grantTypes.contains("authorization_code")) {
            if (redirectUris == null || redirectUris.isEmpty()) {
                throw new IllegalArgumentException("redirect_uris is required when using authorization_code grant type");
            }
            for (String uri : redirectUris) {
                if (uri == null || uri.trim().isEmpty()) {
                    throw new IllegalArgumentException("redirect_uris cannot contain empty values");
                }
                if (!uri.startsWith("https://") && !isLoopbackUri(uri)) {
                    throw new IllegalArgumentException("redirect_uri must be a valid HTTPS URL: " + uri);
                }
                if (uri.contains("#")) {
                    throw new IllegalArgumentException("redirect_uri cannot contain fragments: " + uri);
                }
            }
        }
    }

    private boolean isLoopbackUri(String uri) {
        return uri.startsWith("http://localhost") || uri.startsWith("http://127.0.0.1") || uri.startsWith("http://[::1]");
    }

    private void validateScope(List<String> scopes) {
        for (String requestedScope : scopes) {
            if (!ALLOWED_SCOPES.contains(requestedScope.trim())) {
                throw new IllegalArgumentException("Unsupported scope: " + requestedScope + ". Allowed scopes: " + ALLOWED_SCOPES);
            }
        }
    }

    private void writeError(HttpServletResponse response, OAuth2Error error, String customDescription) throws IOException {
        int status = switch (error) {
            case INVALID_CLIENT -> HttpServletResponse.SC_UNAUTHORIZED;
            case UNAUTHORIZED_CLIENT, ACCESS_DENIED -> HttpServletResponse.SC_FORBIDDEN;
            case SERVER_ERROR -> HttpServletResponse.SC_INTERNAL_SERVER_ERROR;
            default -> HttpServletResponse.SC_BAD_REQUEST;
        };
        response.setStatus(status);
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        byte[] body = objectMapper.writeValueAsBytes(OAuth2ErrorResponse.of(error, customDescription));
        response.getOutputStream().write(body);
        response.getOutputStream().flush();
    }
}
