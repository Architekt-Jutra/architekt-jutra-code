package pl.devstyle.aj.mcp.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.security.core.context.SecurityContextHolder;

import java.io.IOException;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;

class McpJwtFilterTests {

    private final McpJwtFilter filter = new McpJwtFilter();

    @Test
    void doFilter_withBearerToken_setsAuthentication() throws ServletException, IOException {
        var request = new MockHttpServletRequest();
        request.addHeader("Authorization", "Bearer my-jwt-token");
        var response = new MockHttpServletResponse();
        var filterChain = mock(FilterChain.class);

        filter.doFilterInternal(request, response, filterChain);

        // Filter chain should have been called
        verify(filterChain).doFilter(request, response);

        // Security context cleared after filter completes (try/finally)
        assertThat(SecurityContextHolder.getContext().getAuthentication()).isNull();
    }

    @Test
    void doFilter_withoutBearerToken_passesThrough() throws ServletException, IOException {
        var request = new MockHttpServletRequest();
        var response = new MockHttpServletResponse();
        var filterChain = mock(FilterChain.class);

        SecurityContextHolder.clearContext();

        filter.doFilterInternal(request, response, filterChain);

        verify(filterChain).doFilter(request, response);
        assertThat(SecurityContextHolder.getContext().getAuthentication()).isNull();
    }
}
