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
import pl.devstyle.aj.WithMockEditUser;

import java.util.Map;

import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.notNullValue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@Import({TestcontainersConfiguration.class, SecurityMockMvcConfiguration.class})
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.MOCK)
@AutoConfigureMockMvc
@Transactional
@WithMockEditUser
class PluginObjectGapTests {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private PluginDescriptorRepository pluginDescriptorRepository;

    private PluginDescriptor createAndSavePlugin(String id) {
        var plugin = new PluginDescriptor();
        plugin.setId(id);
        plugin.setName(id + " plugin");
        plugin.setVersion("1.0.0");
        plugin.setUrl("http://localhost:3001");
        plugin.setDescription("Test plugin");
        plugin.setEnabled(true);
        plugin.setManifest(Map.of("name", id + " plugin", "version", "1.0.0"));
        return pluginDescriptorRepository.saveAndFlush(plugin);
    }

    private void saveObject(String pluginId, String objectType, String objectId, Map<String, Object> data) throws Exception {
        mockMvc.perform(put("/api/plugins/{pluginId}/objects/{objectType}/{objectId}",
                        pluginId, objectType, objectId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(data)))
                .andExpect(status().isOk());
    }

    private void saveObjectWithEntity(String pluginId, String objectType, String objectId,
                                       Map<String, Object> data, EntityType entityType, Long entityId) throws Exception {
        mockMvc.perform(put("/api/plugins/{pluginId}/objects/{objectType}/{objectId}?entityType={entityType}&entityId={entityId}",
                        pluginId, objectType, objectId, entityType, entityId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(data)))
                .andExpect(status().isOk());
    }

    // --- JSONB filter: bool operator ---

    @Test
    void list_withJsonbBoolFilter_returnsMatchingObjects() throws Exception {
        var plugin = createAndSavePlugin("features");

        saveObject(plugin.getId(), "flag", "f-1", Map.of("active", true, "name", "dark-mode"));
        saveObject(plugin.getId(), "flag", "f-2", Map.of("active", false, "name", "beta"));
        saveObject(plugin.getId(), "flag", "f-3", Map.of("active", true, "name", "notifications"));

        mockMvc.perform(get("/api/plugins/{pluginId}/objects/{objectType}?filter=active:bool:true",
                        plugin.getId(), "flag"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(2)));
    }

    // --- JSONB filter: exists operator ---

    @Test
    void list_withJsonbExistsFilter_returnsObjectsWithKey() throws Exception {
        var plugin = createAndSavePlugin("metadata");

        saveObject(plugin.getId(), "item", "i-1", Map.of("color", "red", "size", "M"));
        saveObject(plugin.getId(), "item", "i-2", Map.of("size", "L"));
        saveObject(plugin.getId(), "item", "i-3", Map.of("color", "blue"));

        mockMvc.perform(get("/api/plugins/{pluginId}/objects/{objectType}?filter=color:exists",
                        plugin.getId(), "item"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(2)));
    }

    // --- JSONB filter: eq operator ---

    @Test
    void list_withJsonbEqFilter_returnsExactMatches() throws Exception {
        var plugin = createAndSavePlugin("inventory");

        saveObject(plugin.getId(), "item", "i-1", Map.of("status", "active"));
        saveObject(plugin.getId(), "item", "i-2", Map.of("status", "archived"));
        saveObject(plugin.getId(), "item", "i-3", Map.of("status", "active"));

        mockMvc.perform(get("/api/plugins/{pluginId}/objects/{objectType}?filter=status:eq:active",
                        plugin.getId(), "item"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(2)));
    }

    // --- Invalid filter format ---

    @Test
    void list_withInvalidFilterFormat_returns400() throws Exception {
        var plugin = createAndSavePlugin("warehouse");

        mockMvc.perform(get("/api/plugins/{pluginId}/objects/{objectType}?filter=invalid",
                        plugin.getId(), "stock"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void list_withUnsupportedFilterOperator_returns400() throws Exception {
        var plugin = createAndSavePlugin("warehouse");

        mockMvc.perform(get("/api/plugins/{pluginId}/objects/{objectType}?filter=quantity:between:1",
                        plugin.getId(), "stock"))
                .andExpect(status().isBadRequest());
    }

    // --- Save with only entityType (no entityId) ---

    @Test
    void save_withEntityTypeButNoEntityId_returns400() throws Exception {
        var plugin = createAndSavePlugin("reviews");
        var data = Map.of("text", "Partial binding");

        mockMvc.perform(put("/api/plugins/{pluginId}/objects/{objectType}/{objectId}?entityType=PRODUCT",
                        plugin.getId(), "review", "rev-1")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(data)))
                .andExpect(status().isBadRequest());
    }

    // --- Cross-type with JSONB filter ---

    @Test
    void listCrossType_withJsonbFilter_returnsCombinedFilteredResults() throws Exception {
        var plugin = createAndSavePlugin("warehouse");

        saveObjectWithEntity(plugin.getId(), "stock", "s-1", Map.of("quantity", 10), EntityType.PRODUCT, 123L);
        saveObjectWithEntity(plugin.getId(), "price", "p-1", Map.of("quantity", 5), EntityType.PRODUCT, 123L);
        saveObjectWithEntity(plugin.getId(), "stock", "s-2", Map.of("quantity", 0), EntityType.PRODUCT, 123L);

        mockMvc.perform(get("/api/plugins/{pluginId}/objects?entityType=PRODUCT&entityId=123&filter=quantity:gt:0",
                        plugin.getId()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(2)));
    }

    // --- Response shape includes all expected fields ---

    @Test
    void save_responseIncludesAllExpectedFields() throws Exception {
        var plugin = createAndSavePlugin("reviews");
        var data = Map.of("text", "Full response check");

        mockMvc.perform(put("/api/plugins/{pluginId}/objects/{objectType}/{objectId}?entityType=PRODUCT&entityId=42",
                        plugin.getId(), "review", "rev-1")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(data)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(notNullValue()))
                .andExpect(jsonPath("$.pluginId").value(plugin.getId()))
                .andExpect(jsonPath("$.objectType").value("review"))
                .andExpect(jsonPath("$.objectId").value("rev-1"))
                .andExpect(jsonPath("$.data.text").value("Full response check"))
                .andExpect(jsonPath("$.entityType").value("PRODUCT"))
                .andExpect(jsonPath("$.entityId").value(42))
                .andExpect(jsonPath("$.createdAt").value(notNullValue()))
                .andExpect(jsonPath("$.updatedAt").value(notNullValue()));
    }
}
