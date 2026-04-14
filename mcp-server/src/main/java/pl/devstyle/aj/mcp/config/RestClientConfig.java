package pl.devstyle.aj.mcp.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpRequest;
import org.springframework.http.client.ClientHttpRequestExecution;
import org.springframework.http.client.ClientHttpRequestInterceptor;
import org.springframework.http.client.ClientHttpResponse;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientResponseException;
import org.springframework.web.client.support.RestClientAdapter;
import org.springframework.web.service.invoker.HttpServiceProxyFactory;
import pl.devstyle.aj.mcp.client.AjApiClient;
import pl.devstyle.aj.mcp.exception.McpToolException;
import pl.devstyle.aj.mcp.security.AccessTokenHolder;

import java.io.IOException;

@Configuration
public class RestClientConfig {

    private static final Logger LOG = LoggerFactory.getLogger(RestClientConfig.class);

    @Bean
    public RestClient ajRestClient(@Value("${aj.backend.url}") String backendUrl,
                                   AccessTokenHolder accessTokenHolder) {
        var requestFactory = new SimpleClientHttpRequestFactory();
        requestFactory.setConnectTimeout(5_000);
        requestFactory.setReadTimeout(30_000);

        return RestClient.builder()
                .baseUrl(backendUrl)
                .requestFactory(requestFactory)
                .requestInterceptor(new JwtForwardingInterceptor(accessTokenHolder))
                .defaultStatusHandler(status -> status.is4xxClientError() || status.is5xxServerError(),
                        (request, response) -> {
                            int statusCode = response.getStatusCode().value();
                            String body = new String(response.getBody().readNBytes(8192));
                            LOG.warn("Backend API error: {} {} - {}", statusCode, request.getURI(), body);

                            throw switch (statusCode) {
                                case 400 -> McpToolException.validationError(body);
                                case 401 -> McpToolException.apiError("Authentication required");
                                case 403 -> McpToolException.apiError("Insufficient permissions");
                                case 404 -> McpToolException.notFound(body);
                                default -> McpToolException.apiError(
                                        "Backend error (status %d). Please retry.".formatted(statusCode));
                            };
                        })
                .build();
    }

    @Bean
    public AjApiClient ajApiClient(RestClient ajRestClient) {
        var adapter = RestClientAdapter.create(ajRestClient);
        var factory = HttpServiceProxyFactory.builderFor(adapter).build();
        return factory.createClient(AjApiClient.class);
    }

    /**
     * Interceptor that forwards the JWT token from incoming MCP requests to the aj backend.
     */
    public static class JwtForwardingInterceptor implements ClientHttpRequestInterceptor {

        private final AccessTokenHolder accessTokenHolder;

        public JwtForwardingInterceptor(AccessTokenHolder accessTokenHolder) {
            this.accessTokenHolder = accessTokenHolder;
        }

        @Override
        public ClientHttpResponse intercept(HttpRequest request, byte[] body,
                                            ClientHttpRequestExecution execution) throws IOException {
            if (accessTokenHolder.hasAccessToken()) {
                LOG.info("Forwarding Bearer token to backend: {} {}", request.getMethod(), request.getURI());
                request.getHeaders().setBearerAuth(accessTokenHolder.getAccessToken());
            } else {
                LOG.warn("No token to forward for backend call: {} {}", request.getMethod(), request.getURI());
            }
            return execution.execute(request, body);
        }
    }
}
