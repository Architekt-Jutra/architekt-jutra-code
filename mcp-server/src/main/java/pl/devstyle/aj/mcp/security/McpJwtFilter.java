package pl.devstyle.aj.mcp.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.List;

/**
 * JWT filter that authenticates requests based on Bearer tokens.
 * No JWT validation — trust-and-forward model. The backend validates tokens.
 * Token forwarding to the backend is handled via McpTransportContext → service methods → AccessTokenHolder.
 */
@Slf4j
public class McpJwtFilter extends OncePerRequestFilter {

    private static final String AUTHORIZATION_HEADER = "Authorization";
    private static final String BEARER_PREFIX = "Bearer ";

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {
        try {
            String authHeader = request.getHeader(AUTHORIZATION_HEADER);
            if (authHeader != null && authHeader.startsWith(BEARER_PREFIX)) {
                log.info("Received Bearer token from client (length={})", authHeader.length() - BEARER_PREFIX.length());

                var authentication = new UsernamePasswordAuthenticationToken(
                        "mcp-user", null, List.of());
                SecurityContextHolder.getContext().setAuthentication(authentication);
            } else {
                log.info("No Bearer token in request to {}", request.getRequestURI());
            }

            filterChain.doFilter(request, response);
        } finally {
            SecurityContextHolder.clearContext();
        }
    }
}
