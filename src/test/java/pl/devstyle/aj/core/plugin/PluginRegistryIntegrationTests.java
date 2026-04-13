package pl.devstyle.aj.core.plugin;

import tools.jackson.databind.ObjectMapper;
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

import java.util.List;
import java.util.Map;

import static org.hamcrest.Matchers.hasSize;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@Import({TestcontainersConfiguration.class, SecurityMockMvcConfiguration.class})
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.MOCK)
@AutoConfigureMockMvc
@Transactional
@WithMockAdminUser
class PluginRegistryIntegrationTests {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private PluginDescriptorRepository pluginDescriptorRepository;

    private Map<String, Object> createManifest(String name, String version, String url, String description) {
        return Map.of(
                "name", name,
                "version", version,
                "url", url,
                "description", description,
                "extensionPoints", List.of(
                        Map.of("type", "product-tab", "label", "Reviews"),
                        Map.of("type", "product-action", "label", "Export")
                )
        );
    }

    private PluginDescriptor createAndSavePlugin(String id, String name, boolean enabled) {
        var plugin = new PluginDescriptor();
        plugin.setId(id);
        plugin.setName(name);
        plugin.setVersion("1.0.0");
        plugin.setUrl("http://localhost:3001");
        plugin.setDescription("Test plugin");
        plugin.setEnabled(enabled);
        plugin.setManifest(Map.of(
                "name", name,
                "version", "1.0.0",
                "url", "http://localhost:3001",
                "description", "Test plugin",
                "extensionPoints", List.of(
                        Map.of("type", "product-tab", "label", "Tab")
                )
        ));
        return pluginDescriptorRepository.saveAndFlush(plugin);
    }

    @Test
    void uploadManifest_createsNewPlugin_returns200() throws Exception {
        var manifest = createManifest("Reviews Plugin", "2.1.0",
                "http://localhost:3001", "Adds product reviews");

        mockMvc.perform(put("/api/plugins/{pluginId}/manifest", "reviews-plugin")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(manifest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value("reviews-plugin"))
                .andExpect(jsonPath("$.name").value("Reviews Plugin"))
                .andExpect(jsonPath("$.version").value("2.1.0"))
                .andExpect(jsonPath("$.url").value("http://localhost:3001"))
                .andExpect(jsonPath("$.description").value("Adds product reviews"))
                .andExpect(jsonPath("$.enabled").value(true))
                .andExpect(jsonPath("$.extensionPoints", hasSize(2)));
    }

    @Test
    void uploadManifest_updatesExistingPlugin_returns200() throws Exception {
        var manifest = createManifest("Reviews Plugin", "1.0.0",
                "http://localhost:3001", "Original description");

        mockMvc.perform(put("/api/plugins/{pluginId}/manifest", "reviews-plugin")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(manifest)))
                .andExpect(status().isOk());

        var updatedManifest = createManifest("Reviews Plugin", "2.0.0",
                "http://localhost:3002", "Updated description");

        mockMvc.perform(put("/api/plugins/{pluginId}/manifest", "reviews-plugin")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(updatedManifest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.version").value("2.0.0"))
                .andExpect(jsonPath("$.url").value("http://localhost:3002"))
                .andExpect(jsonPath("$.description").value("Updated description"));
    }

    @Test
    void getPlugins_returnsOnlyEnabled() throws Exception {
        createAndSavePlugin("enabled-plugin", "Enabled Plugin", true);
        createAndSavePlugin("disabled-plugin", "Disabled Plugin", false);

        mockMvc.perform(get("/api/plugins"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray())
                .andExpect(jsonPath("$", hasSize(1)))
                .andExpect(jsonPath("$[0].id").value("enabled-plugin"));
    }

    @Test
    void getPlugin_returnsPluginWithExtensionPoints() throws Exception {
        createAndSavePlugin("detail-plugin", "Detail Plugin", true);

        mockMvc.perform(get("/api/plugins/{pluginId}", "detail-plugin"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value("detail-plugin"))
                .andExpect(jsonPath("$.name").value("Detail Plugin"))
                .andExpect(jsonPath("$.extensionPoints", hasSize(1)))
                .andExpect(jsonPath("$.extensionPoints[0].type").value("product-tab"));
    }

    @Test
    void deletePlugin_removesPlugin_returns204() throws Exception {
        createAndSavePlugin("delete-me", "Delete Me", true);

        mockMvc.perform(delete("/api/plugins/{pluginId}", "delete-me"))
                .andExpect(status().isNoContent());

        mockMvc.perform(get("/api/plugins/{pluginId}", "delete-me"))
                .andExpect(status().isNotFound());
    }

    @Test
    void setPluginEnabled_togglesState_returns200() throws Exception {
        createAndSavePlugin("toggle-plugin", "Toggle Plugin", true);

        mockMvc.perform(patch("/api/plugins/{pluginId}/enabled", "toggle-plugin")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"enabled\": false}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.enabled").value(false));

        mockMvc.perform(get("/api/plugins"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray())
                .andExpect(jsonPath("$", hasSize(0)));
    }
}
