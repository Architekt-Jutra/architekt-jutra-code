package pl.devstyle.aj;

import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.webmvc.test.autoconfigure.MockMvcBuilderCustomizer;
import org.springframework.context.annotation.Bean;
import org.springframework.test.web.servlet.setup.ConfigurableMockMvcBuilder;

import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;

@TestConfiguration(proxyBeanMethods = false)
public class SecurityMockMvcConfiguration {

    @Bean
    MockMvcBuilderCustomizer securityMockMvcCustomizer() {
        return new MockMvcBuilderCustomizer() {
            @Override
            public void customize(ConfigurableMockMvcBuilder<?> builder) {
                builder.apply(springSecurity());
            }
        };
    }
}
