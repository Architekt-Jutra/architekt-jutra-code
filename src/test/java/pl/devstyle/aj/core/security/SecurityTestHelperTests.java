package pl.devstyle.aj.core.security;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;
import pl.devstyle.aj.SecurityMockMvcConfiguration;
import pl.devstyle.aj.TestcontainersConfiguration;
import pl.devstyle.aj.WithMockAdminUser;
import pl.devstyle.aj.WithMockEditUser;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@Import({TestcontainersConfiguration.class, SecurityMockMvcConfiguration.class})
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.MOCK)
@AutoConfigureMockMvc
@Transactional
class SecurityTestHelperTests {

    @Autowired
    private MockMvc mockMvc;

    @Test
    @WithMockEditUser
    void withMockEditUser_allowsCrudOperations() throws Exception {
        mockMvc.perform(get("/api/categories"))
                .andExpect(status().isOk());

        mockMvc.perform(post("/api/categories")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"Test\",\"description\":\"Test\"}"))
                .andExpect(status().isCreated());
    }

    @Test
    @WithMockAdminUser
    void withMockAdminUser_allowsPluginManagement() throws Exception {
        mockMvc.perform(get("/api/plugins"))
                .andExpect(status().isOk());

        mockMvc.perform(put("/api/plugins/test-helper-plugin/manifest")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"Test Plugin\",\"version\":\"1.0.0\",\"url\":\"http://localhost:3001\",\"description\":\"Test\",\"extensionPoints\":[]}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value("test-helper-plugin"));
    }

    @Test
    void withoutSecurityContext_returns401() throws Exception {
        mockMvc.perform(get("/api/categories"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.status").value(401));
    }
}
