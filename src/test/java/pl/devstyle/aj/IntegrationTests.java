package pl.devstyle.aj;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.ApplicationContext;
import org.springframework.context.annotation.Import;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;

import pl.devstyle.aj.api.HealthController;
import pl.devstyle.aj.core.plugin.PluginDescriptorRepository;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@Import({TestcontainersConfiguration.class, SecurityMockMvcConfiguration.class})
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.MOCK)
@AutoConfigureMockMvc
@WithMockUser(authorities = {"PERMISSION_READ", "PERMISSION_EDIT"})
class IntegrationTests {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ApplicationContext applicationContext;

    @Test
    void healthEndpointReturnsCorrectJsonInFullContext() throws Exception {
        mockMvc.perform(get("/api/health"))
                .andExpect(status().isOk())
                .andExpect(content().contentTypeCompatibleWith("application/json"))
                .andExpect(jsonPath("$.status").value("UP"));
    }

    @Test
    void pluginDescriptorRepositoryAndHealthControllerCoexistInContext() {
        assertThat(applicationContext.getBean(PluginDescriptorRepository.class)).isNotNull();
        assertThat(applicationContext.getBean(HealthController.class)).isNotNull();
    }

    @Test
    void apiPathsReturnJsonNotHtmlForward() throws Exception {
        mockMvc.perform(get("/api/health"))
                .andExpect(status().isOk())
                .andExpect(content().contentTypeCompatibleWith("application/json"))
                .andExpect(jsonPath("$.status").value("UP"));
    }

    @Test
    void spaForwardingWorksForClientRoutePaths() throws Exception {
        mockMvc.perform(get("/dashboard"))
                .andExpect(status().isOk());
    }

    @Test
    void spaForwardingWorksForNestedClientRoutePaths() throws Exception {
        mockMvc.perform(get("/settings/profile"))
                .andExpect(status().isOk());
    }

    @Test
    void staticIndexHtmlIsServable() throws Exception {
        mockMvc.perform(get("/index.html"))
                .andExpect(status().isOk());
    }

    @Test
    void liquibaseChangesWereApplied() throws Exception {
        var dataSource = applicationContext.getBean(javax.sql.DataSource.class);
        try (var connection = dataSource.getConnection();
             var rs = connection.getMetaData().getTables(null, null, "databasechangelog", null)) {
            assertThat(rs.next()).as("Liquibase DATABASECHANGELOG table should exist").isTrue();
        }
    }
}
