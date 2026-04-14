package pl.devstyle.aj.core.oauth2;

import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.MediaType;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.server.authorization.client.RegisteredClient;
import org.springframework.security.oauth2.server.authorization.client.RegisteredClientRepository;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.security.SecureRandom;
import java.util.Arrays;
import java.util.Base64;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

@Slf4j
public class OAuth2AuthorizationFilter extends OncePerRequestFilter {

    private static final String AUTHORIZATION_ENDPOINT = "/oauth2/authorize";
    private static final SecureRandom SECURE_RANDOM = new SecureRandom();

    private final RegisteredClientRepository registeredClientRepository;
    private final AuthorizationCodeService authorizationCodeService;
    private final ObjectMapper objectMapper;

    public OAuth2AuthorizationFilter(RegisteredClientRepository registeredClientRepository,
                                     AuthorizationCodeService authorizationCodeService) {
        this.registeredClientRepository = registeredClientRepository;
        this.authorizationCodeService = authorizationCodeService;
        this.objectMapper = new ObjectMapper();
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        if (!("POST".equals(request.getMethod()) && AUTHORIZATION_ENDPOINT.equals(request.getRequestURI()))) {
            filterChain.doFilter(request, response);
            return;
        }

        try {
            handleAuthorizationRequest(request, response);
        } catch (IllegalArgumentException e) {
            log.warn("Authorization request failed | reason={}", e.getMessage());
            var error = determineError(e.getMessage());
            writeError(response, error, e.getMessage());
        } catch (Exception e) {
            log.error("Authorization request error | reason={}", e.getMessage(), e);
            writeError(response, OAuth2Error.SERVER_ERROR, "An error occurred while processing the authorization request");
        }
    }

    private void handleAuthorizationRequest(HttpServletRequest request, HttpServletResponse response) throws IOException {
        log.info("Authorization request received | params: {}", request.getParameterMap().entrySet().stream()
                .map(e -> e.getKey() + "=" + String.join(",", e.getValue()))
                .collect(Collectors.joining(" | ")));
        String clientId = request.getParameter("client_id");
        String redirectUri = request.getParameter("redirect_uri");
        String responseType = request.getParameter("response_type");
        String scope = request.getParameter("scope");
        String state = request.getParameter("state");
        String codeChallenge = request.getParameter("code_challenge");
        String codeChallengeMethod = request.getParameter("code_challenge_method");

        if (clientId == null || redirectUri == null || responseType == null) {
            throw new IllegalArgumentException("Missing required parameters: client_id, redirect_uri, response_type");
        }

        if (!"code".equals(responseType)) {
            throw new IllegalArgumentException("Unsupported response_type. Only 'code' is supported");
        }

        RegisteredClient client = registeredClientRepository.findByClientId(clientId);
        if (client == null) {
            throw new IllegalArgumentException("Invalid client_id");
        }

        validateRedirectUri(redirectUri, client);
        validateScopes(scope, client);
        validatePkceParameters(codeChallenge, codeChallengeMethod, client);

        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated()) {
            throw new IllegalArgumentException("User must be authenticated");
        }

        String username = (String) authentication.getPrincipal();
        Set<String> permissions = authentication.getAuthorities().stream()
                .map(GrantedAuthority::getAuthority)
                .filter(a -> a.startsWith("PERMISSION_"))
                .map(a -> a.substring("PERMISSION_".length()))
                .collect(Collectors.toSet());

        String authorizationCode = generateAuthorizationCode();

        authorizationCodeService.storeAuthorizationCode(
                authorizationCode, clientId, redirectUri, scope,
                codeChallenge, codeChallengeMethod, username, permissions
        );

        String redirectUrl = redirectUri + "?code=" + authorizationCode;
        if (state != null && !state.isEmpty()) {
            redirectUrl += "&state=" + state;
        }

        log.info("Authorization code issued | client_id={} | user={} | scope={} | pkce={}",
                clientId, username, scope != null ? scope : "none",
                codeChallenge != null ? "enabled" : "disabled");

        response.setStatus(HttpServletResponse.SC_FOUND);
        response.setHeader("Location", redirectUrl);
    }

    private String generateAuthorizationCode() {
        var bytes = new byte[32];
        SECURE_RANDOM.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    private void validateRedirectUri(String redirectUri, RegisteredClient client) {
        if (!client.getRedirectUris().contains(redirectUri)) {
            throw new IllegalArgumentException("redirect_uri not registered for this client");
        }
    }

    private void validateScopes(String scope, RegisteredClient client) {
        if (scope == null || scope.trim().isEmpty()) {
            return;
        }
        Set<String> requestedScopes = new HashSet<>(Arrays.asList(scope.trim().split("\\s+")));
        Set<String> allowedScopes = client.getScopes();
        for (String requestedScope : requestedScopes) {
            if (!allowedScopes.contains(requestedScope)) {
                throw new IllegalArgumentException("Scope not allowed for this client: " + requestedScope);
            }
        }
    }

    private void validatePkceParameters(String codeChallenge, String codeChallengeMethod, RegisteredClient client) {
        boolean isPkceProvided = codeChallenge != null || codeChallengeMethod != null;
        boolean isPublicClient = client.getClientAuthenticationMethods().stream()
                .anyMatch(method -> "none".equals(method.getValue()));

        if (isPublicClient && !isPkceProvided) {
            throw new IllegalArgumentException(
                    "PKCE is required for public clients. Provide code_challenge and code_challenge_method parameters");
        }

        if (isPkceProvided) {
            if (codeChallenge == null || codeChallengeMethod == null) {
                throw new IllegalArgumentException(
                        "Both code_challenge and code_challenge_method must be provided when using PKCE");
            }
            if (!"S256".equals(codeChallengeMethod)) {
                throw new IllegalArgumentException("Unsupported code_challenge_method. Only 'S256' is supported");
            }
            if (codeChallenge.length() < 43 || codeChallenge.length() > 128) {
                throw new IllegalArgumentException("Invalid code_challenge length. Must be 43-128 characters");
            }
            if (!codeChallenge.matches("^[A-Za-z0-9_-]+$")) {
                throw new IllegalArgumentException("Invalid code_challenge format. Must be base64url-encoded");
            }
        }
    }

    private OAuth2Error determineError(String message) {
        if (message.contains("redirect_uri")) return OAuth2Error.INVALID_REQUEST;
        if (message.contains("Scope not allowed") || message.contains("scope")) return OAuth2Error.INVALID_SCOPE;
        if (message.contains("response_type")) return OAuth2Error.UNSUPPORTED_RESPONSE_TYPE;
        if (message.contains("client_id")) return OAuth2Error.INVALID_REQUEST;
        if (message.contains("PKCE")) return OAuth2Error.INVALID_REQUEST;
        if (message.contains("authenticated")) return OAuth2Error.UNAUTHORIZED_CLIENT;
        return OAuth2Error.INVALID_REQUEST;
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
