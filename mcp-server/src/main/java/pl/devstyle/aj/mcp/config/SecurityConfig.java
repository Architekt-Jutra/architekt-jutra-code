package pl.devstyle.aj.mcp.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import pl.devstyle.aj.mcp.security.McpAuthenticationEntryPoint;
import pl.devstyle.aj.mcp.security.McpJwtFilter;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Value("${aj.mcp.base-url}")
    private String mcpBaseUrl;

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
                .csrf(csrf -> csrf.disable())
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers("/.well-known/**").permitAll()
                        .requestMatchers("/actuator/health/**").permitAll()
                        .requestMatchers("/error").permitAll()
                        .anyRequest().authenticated()
                )
                .exceptionHandling(ex -> ex
                        .authenticationEntryPoint(new McpAuthenticationEntryPoint(
                                mcpBaseUrl + "/.well-known/oauth-protected-resource"))
                )
                .addFilterBefore(new McpJwtFilter(),
                        UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }
}
