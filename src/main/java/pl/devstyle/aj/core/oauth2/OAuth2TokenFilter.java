package pl.devstyle.aj.core.oauth2;

import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.oauth2.server.authorization.client.RegisteredClient;
import org.springframework.security.oauth2.server.authorization.client.RegisteredClientRepository;
import org.springframework.web.filter.OncePerRequestFilter;
import pl.devstyle.aj.core.security.JwtTokenProvider;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Base64;
import java.util.Set;
import java.util.stream.Collectors;

@Slf4j
public class OAuth2TokenFilter extends OncePerRequestFilter {

    private static final String TOKEN_ENDPOINT = "/oauth2/token";

    private final RegisteredClientRepository registeredClientRepository;
    private final AuthorizationCodeService authorizationCodeService;
    private final RefreshTokenService refreshTokenService;
    private final JwtTokenProvider jwtTokenProvider;
    private final PasswordEncoder passwordEncoder;
    private final ObjectMapper objectMapper;

    public OAuth2TokenFilter(RegisteredClientRepository registeredClientRepository,
                             AuthorizationCodeService authorizationCodeService,
                             RefreshTokenService refreshTokenService,
                             JwtTokenProvider jwtTokenProvider,
                             PasswordEncoder passwordEncoder) {
        this.registeredClientRepository = registeredClientRepository;
        this.authorizationCodeService = authorizationCodeService;
        this.refreshTokenService = refreshTokenService;
        this.jwtTokenProvider = jwtTokenProvider;
        this.passwordEncoder = passwordEncoder;
        this.objectMapper = new ObjectMapper();
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        if (!(TOKEN_ENDPOINT.equals(request.getRequestURI()) && "POST".equals(request.getMethod()))) {
            filterChain.doFilter(request, response);
            return;
        }

        log.info("Token request received | params: {}", request.getParameterMap().entrySet().stream()
                .map(e -> e.getKey() + "=" + String.join(",", e.getValue()))
                .collect(Collectors.joining(" | ")));

        try {
            String grantType = request.getParameter("grant_type");
            if ("authorization_code".equals(grantType)) {
                handleAuthorizationCodeGrant(request, response);
            } else if ("refresh_token".equals(grantType)) {
                handleRefreshTokenGrant(request, response);
            } else {
                sendError(response, OAuth2Error.UNSUPPORTED_GRANT_TYPE, "Unsupported grant type: " + grantType);
            }
        } catch (Exception e) {
            log.error("Token endpoint error | reason={}", e.getMessage(), e);
            if (!response.isCommitted()) {
                sendError(response, OAuth2Error.SERVER_ERROR, "Internal server error");
            }
        }
    }

    private void handleAuthorizationCodeGrant(HttpServletRequest request, HttpServletResponse response) throws IOException {
        String code = request.getParameter("code");
        String clientId = request.getParameter("client_id");
        String redirectUri = request.getParameter("redirect_uri");
        String clientSecret = request.getParameter("client_secret");

        if (code == null || code.isBlank()) {
            sendError(response, OAuth2Error.INVALID_REQUEST, "Missing required parameter: code");
            return;
        }

        if (redirectUri == null || redirectUri.isBlank()) {
            sendError(response, OAuth2Error.INVALID_REQUEST, "Missing required parameter: redirect_uri");
            return;
        }

        var authCodeData = authorizationCodeService.consumeAuthorizationCode(code);
        if (authCodeData.isEmpty()) {
            sendError(response, OAuth2Error.INVALID_GRANT, "Authorization code is invalid or has expired");
            return;
        }

        var data = authCodeData.get();

        // Validate client_id if provided
        if (clientId != null && !clientId.equals(data.clientId())) {
            log.warn("Token exchange failed | reason=Client ID mismatch");
            sendError(response, OAuth2Error.INVALID_GRANT, "Authorization code is invalid or has expired");
            return;
        }

        // Validate redirect_uri
        if (!redirectUri.equals(data.redirectUri())) {
            log.warn("Token exchange failed | client_id={} | reason=Redirect URI mismatch", data.clientId());
            sendError(response, OAuth2Error.INVALID_GRANT, "Authorization code is invalid or has expired");
            return;
        }

        // Authenticate confidential clients
        RegisteredClient client = registeredClientRepository.findByClientId(data.clientId());
        if (client != null) {
            boolean isConfidentialClient = client.getClientAuthenticationMethods().stream()
                    .noneMatch(method -> "none".equals(method.getValue()));
            if (isConfidentialClient) {
                if (clientSecret == null || clientSecret.isBlank()) {
                    sendError(response, OAuth2Error.INVALID_CLIENT, "Client authentication required");
                    return;
                }
                if (!passwordEncoder.matches(clientSecret, client.getClientSecret())) {
                    sendError(response, OAuth2Error.INVALID_CLIENT, "Client authentication failed");
                    return;
                }
            }
        }

        // Validate PKCE code_verifier
        if (data.codeChallenge() != null) {
            String codeVerifier = request.getParameter("code_verifier");
            if (!validatePkceCodeVerifier(codeVerifier, data.codeChallenge(), data.codeChallengeMethod())) {
                sendError(response, OAuth2Error.INVALID_GRANT, "Authorization code is invalid or has expired");
                return;
            }
        }

        // Generate tokens with granted OAuth2 scopes (not user permissions)
        Set<String> grantedScopes = data.scope() != null
                ? Set.of(data.scope().split("\\s+"))
                : Set.of();
        String issuer = getBaseUrl(request);
        String accessToken = jwtTokenProvider.generateOAuth2Token(data.username(), grantedScopes, issuer);
        String refreshToken = refreshTokenService.issueToken(data.username(), grantedScopes, data.scope());

        sendTokenResponse(response, accessToken, refreshToken, data.scope());

        log.info("OAuth2 token issued | client_id={} | user={} | scope={} | access_token={} | refresh_token={}",
                data.clientId(), data.username(), data.scope(), accessToken, refreshToken);
    }

    private void handleRefreshTokenGrant(HttpServletRequest request, HttpServletResponse response) throws IOException {
        String refreshToken = request.getParameter("refresh_token");
        if (refreshToken == null || refreshToken.isBlank()) {
            sendError(response, OAuth2Error.INVALID_REQUEST, "Missing required parameter: refresh_token");
            return;
        }

        var result = refreshTokenService.consumeAndRotate(refreshToken);
        if (result.isEmpty()) {
            sendError(response, OAuth2Error.INVALID_GRANT, "The provided refresh token is invalid, expired, or revoked");
            return;
        }

        var rotationResult = result.get();
        var data = rotationResult.originalData();

        Set<String> grantedScopes = data.scope() != null
                ? Set.of(data.scope().split("\\s+"))
                : Set.of();
        String issuer = getBaseUrl(request);
        String accessToken = jwtTokenProvider.generateOAuth2Token(data.username(), grantedScopes, issuer);

        sendTokenResponse(response, accessToken, rotationResult.newToken(), data.scope());

        log.info("OAuth2 token refreshed | user={} | scope={}", data.username(), data.scope());
    }

    private boolean validatePkceCodeVerifier(String codeVerifier, String codeChallenge, String codeChallengeMethod) {
        if (codeVerifier == null || codeVerifier.isBlank()) {
            log.warn("PKCE validation failed | reason=Missing code_verifier");
            return false;
        }
        if (codeVerifier.length() < 43 || codeVerifier.length() > 128) {
            log.warn("PKCE validation failed | reason=Invalid code_verifier length");
            return false;
        }
        if (!codeVerifier.matches("^[A-Za-z0-9_\\-\\.~]+$")) {
            log.warn("PKCE validation failed | reason=Invalid code_verifier format");
            return false;
        }
        if (!"S256".equals(codeChallengeMethod)) {
            log.warn("PKCE validation failed | reason=Unsupported code_challenge_method: {}", codeChallengeMethod);
            return false;
        }

        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(codeVerifier.getBytes(StandardCharsets.US_ASCII));
            String computedChallenge = Base64.getUrlEncoder().withoutPadding().encodeToString(hash);
            if (!computedChallenge.equals(codeChallenge)) {
                log.warn("PKCE validation failed | reason=code_verifier does not match code_challenge");
                return false;
            }
            return true;
        } catch (NoSuchAlgorithmException e) {
            log.error("SHA-256 algorithm not available for PKCE validation", e);
            return false;
        }
    }

    private void sendTokenResponse(HttpServletResponse response, String accessToken, String refreshToken, String scope)
            throws IOException {
        response.setStatus(HttpServletResponse.SC_OK);
        response.setContentType("application/json");
        response.setHeader("Cache-Control", "no-store");
        response.setHeader("Pragma", "no-cache");

        var sb = new StringBuilder();
        sb.append("{\"access_token\":\"").append(accessToken).append("\"");
        sb.append(",\"token_type\":\"Bearer\"");
        sb.append(",\"expires_in\":900");
        sb.append(",\"refresh_token\":\"").append(refreshToken).append("\"");
        if (scope != null && !scope.isEmpty()) {
            sb.append(",\"scope\":\"").append(scope).append("\"");
        }
        sb.append("}");

        String tokenResponseBody = sb.toString();
        log.info("OAuth2 token response body: {}", tokenResponseBody);
        response.getOutputStream().write(tokenResponseBody.getBytes(java.nio.charset.StandardCharsets.UTF_8));
        response.getOutputStream().flush();
    }

    private void sendError(HttpServletResponse response, OAuth2Error error, String description) throws IOException {
        int status = switch (error) {
            case INVALID_CLIENT -> HttpServletResponse.SC_UNAUTHORIZED;
            case UNAUTHORIZED_CLIENT, ACCESS_DENIED -> HttpServletResponse.SC_FORBIDDEN;
            case SERVER_ERROR -> HttpServletResponse.SC_INTERNAL_SERVER_ERROR;
            default -> HttpServletResponse.SC_BAD_REQUEST;
        };
        log.warn("OAuth2 token error | error={} | description={} | status={}", error, description, status);
        response.setStatus(status);
        response.setContentType("application/json");
        byte[] body = objectMapper.writeValueAsBytes(OAuth2ErrorResponse.of(error, description));
        response.getOutputStream().write(body);
        response.getOutputStream().flush();
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

        if (forwardedProto != null && forwardedPort == null) {
            return scheme + "://" + serverName;
        }

        return scheme + "://" + serverName + ":" + serverPort;
    }
}
