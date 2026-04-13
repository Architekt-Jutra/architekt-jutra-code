package pl.devstyle.aj.core.security;

import tools.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import pl.devstyle.aj.core.error.ErrorResponse;

import java.time.LocalDateTime;
import java.util.List;

@Configuration
@EnableWebSecurity
public class SecurityConfiguration {

    private final JwtTokenProvider jwtTokenProvider;
    private final ObjectMapper objectMapper;
    private final List<String> allowedOrigins;

    public SecurityConfiguration(JwtTokenProvider jwtTokenProvider, ObjectMapper objectMapper,
                                 @Value("${app.cors.allowed-origins:}") List<String> allowedOrigins) {
        this.jwtTokenProvider = jwtTokenProvider;
        this.objectMapper = objectMapper;
        this.allowedOrigins = allowedOrigins;
    }

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
                .cors(cors -> cors.configurationSource(corsConfigurationSource()))
                // CSRF disabled: stateless JWT authentication with no cookie-based sessions
                .csrf(csrf -> csrf.disable())
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .exceptionHandling(exceptions -> exceptions
                        .authenticationEntryPoint((request, response, authException) -> {
                            response.setStatus(HttpStatus.UNAUTHORIZED.value());
                            response.setContentType(MediaType.APPLICATION_JSON_VALUE);
                            var errorResponse = new ErrorResponse(
                                    HttpStatus.UNAUTHORIZED.value(),
                                    HttpStatus.UNAUTHORIZED.getReasonPhrase(),
                                    "Authentication required",
                                    null,
                                    LocalDateTime.now()
                            );
                            objectMapper.writeValue(response.getOutputStream(), errorResponse);
                        })
                        .accessDeniedHandler((request, response, accessDeniedException) -> {
                            response.setStatus(HttpStatus.FORBIDDEN.value());
                            response.setContentType(MediaType.APPLICATION_JSON_VALUE);
                            var errorResponse = new ErrorResponse(
                                    HttpStatus.FORBIDDEN.value(),
                                    HttpStatus.FORBIDDEN.getReasonPhrase(),
                                    "Access denied",
                                    null,
                                    LocalDateTime.now()
                            );
                            objectMapper.writeValue(response.getOutputStream(), errorResponse);
                        })
                )
                .authorizeHttpRequests(auth -> auth
                        // Public endpoints
                        .requestMatchers(HttpMethod.POST, "/api/auth/login").permitAll()
                        .requestMatchers(HttpMethod.GET, "/api/health").permitAll()
                        .requestMatchers("/assets/**").permitAll()
                        .requestMatchers("/", "/index.html", "/*.js", "/*.css", "/favicon.ico").permitAll()
                        // SPA routes: permit all non-API paths so direct navigation (e.g. /login) works
                        .requestMatchers(request -> !request.getRequestURI().startsWith("/api/")).permitAll()

                        // READ permission
                        .requestMatchers(HttpMethod.GET, "/api/categories/**").hasAuthority("PERMISSION_READ")
                        .requestMatchers(HttpMethod.GET, "/api/products/**").hasAuthority("PERMISSION_READ")
                        .requestMatchers(HttpMethod.GET, "/api/plugins").hasAuthority("PERMISSION_READ")
                        .requestMatchers(HttpMethod.GET, "/api/plugins/*").hasAuthority("PERMISSION_READ")
                        .requestMatchers(HttpMethod.GET, "/api/plugins/*/objects/**").hasAuthority("PERMISSION_READ")
                        .requestMatchers(HttpMethod.GET, "/api/plugins/*/products/*/data").hasAuthority("PERMISSION_READ")

                        // EDIT permission
                        .requestMatchers(HttpMethod.POST, "/api/categories/**").hasAuthority("PERMISSION_EDIT")
                        .requestMatchers(HttpMethod.PUT, "/api/categories/**").hasAuthority("PERMISSION_EDIT")
                        .requestMatchers(HttpMethod.DELETE, "/api/categories/**").hasAuthority("PERMISSION_EDIT")
                        .requestMatchers(HttpMethod.POST, "/api/products/**").hasAuthority("PERMISSION_EDIT")
                        .requestMatchers(HttpMethod.PUT, "/api/products/**").hasAuthority("PERMISSION_EDIT")
                        .requestMatchers(HttpMethod.DELETE, "/api/products/**").hasAuthority("PERMISSION_EDIT")
                        .requestMatchers(HttpMethod.PUT, "/api/plugins/*/objects/**").hasAuthority("PERMISSION_EDIT")
                        .requestMatchers(HttpMethod.DELETE, "/api/plugins/*/objects/**").hasAuthority("PERMISSION_EDIT")
                        .requestMatchers(HttpMethod.PUT, "/api/plugins/*/products/*/data").hasAuthority("PERMISSION_EDIT")
                        .requestMatchers(HttpMethod.DELETE, "/api/plugins/*/products/*/data").hasAuthority("PERMISSION_EDIT")

                        // PLUGIN_MANAGEMENT permission
                        .requestMatchers(HttpMethod.PUT, "/api/plugins/*/manifest").hasAuthority("PERMISSION_PLUGIN_MANAGEMENT")
                        .requestMatchers(HttpMethod.PATCH, "/api/plugins/*/enabled").hasAuthority("PERMISSION_PLUGIN_MANAGEMENT")
                        .requestMatchers(HttpMethod.DELETE, "/api/plugins/*").hasAuthority("PERMISSION_PLUGIN_MANAGEMENT")

                        // Fallback
                        .anyRequest().authenticated()
                )
                .addFilterBefore(new JwtAuthenticationFilter(jwtTokenProvider),
                        UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration authenticationConfiguration)
            throws Exception {
        return authenticationConfiguration.getAuthenticationManager();
    }

    private CorsConfigurationSource corsConfigurationSource() {
        var configuration = new CorsConfiguration();
        configuration.setAllowedOriginPatterns(allowedOrigins);
        configuration.setAllowedMethods(List.of("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
        configuration.setAllowedHeaders(List.of("*"));
        configuration.setAllowCredentials(true);
        var source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }
}
