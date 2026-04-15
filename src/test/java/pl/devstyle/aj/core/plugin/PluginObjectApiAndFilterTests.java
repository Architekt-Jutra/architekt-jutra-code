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
class PluginObjectApiAndFilterTests {

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

    @Test
    void save_withEntityTypeAndEntityIdQueryParams_returnsEntityBinding() throws Exception {
        var plugin = createAndSavePlugin("reviews");
        var data = Map.of("text", "Great!", "stars", 5);

        mockMvc.perform(put("/api/plugins/{pluginId}/objects/{objectType}/{objectId}?entityType=PRODUCT&entityId=42",
                        plugin.getId(), "review", "rev-1")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(data)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(notNullValue()))
                .andExpect(jsonPath("$.entityType").value("PRODUCT"))
                .andExpect(jsonPath("$.entityId").value(42))
                .andExpect(jsonPath("$.data.text").value("Great!"));
    }

    @Test
    void list_withEntityTypeAndEntityIdFilter_returnsFilteredResults() throws Exception {
        var plugin = createAndSavePlugin("reviews");

        saveObjectWithEntity(plugin.getId(), "review", "rev-1", Map.of("text", "A"), EntityType.PRODUCT, 123L);
        saveObjectWithEntity(plugin.getId(), "review", "rev-2", Map.of("text", "B"), EntityType.PRODUCT, 456L);
        saveObject(plugin.getId(), "review", "rev-3", Map.of("text", "C"));

        mockMvc.perform(get("/api/plugins/{pluginId}/objects/{objectType}?entityType=PRODUCT&entityId=123",
                        plugin.getId(), "review"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(1)))
                .andExpect(jsonPath("$[0].objectId").value("rev-1"));
    }

    @Test
    void listCrossType_withEntityTypeAndEntityId_returnsObjectsOfAllTypes() throws Exception {
        var plugin = createAndSavePlugin("reviews");

        saveObjectWithEntity(plugin.getId(), "review", "rev-1", Map.of("text", "Review"), EntityType.PRODUCT, 123L);
        saveObjectWithEntity(plugin.getId(), "comment", "com-1", Map.of("text", "Comment"), EntityType.PRODUCT, 123L);
        saveObjectWithEntity(plugin.getId(), "review", "rev-2", Map.of("text", "Other"), EntityType.PRODUCT, 999L);

        mockMvc.perform(get("/api/plugins/{pluginId}/objects?entityType=PRODUCT&entityId=123",
                        plugin.getId()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(2)));
    }

    @Test
    void listCrossType_withoutEntityTypeOrEntityId_returns400() throws Exception {
        var plugin = createAndSavePlugin("reviews");

        mockMvc.perform(get("/api/plugins/{pluginId}/objects",
                        plugin.getId()))
                .andExpect(status().isBadRequest());

        mockMvc.perform(get("/api/plugins/{pluginId}/objects?entityType=PRODUCT",
                        plugin.getId()))
                .andExpect(status().isBadRequest());

        mockMvc.perform(get("/api/plugins/{pluginId}/objects?entityId=123",
                        plugin.getId()))
                .andExpect(status().isBadRequest());
    }

    @Test
    void list_withJsonbFilter_returnsOnlyMatchingObjects() throws Exception {
        var plugin = createAndSavePlugin("warehouse");

        saveObject(plugin.getId(), "stock", "s-1", Map.of("quantity", 10, "location", "A1"));
        saveObject(plugin.getId(), "stock", "s-2", Map.of("quantity", 0, "location", "B2"));
        saveObject(plugin.getId(), "stock", "s-3", Map.of("quantity", 5, "location", "A1"));

        mockMvc.perform(get("/api/plugins/{pluginId}/objects/{objectType}?filter=quantity:gt:0",
                        plugin.getId(), "stock"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(2)));
    }

    @Test
    void list_withEntityBindingAndJsonbFilter_returnsCombinedResult() throws Exception {
        var plugin = createAndSavePlugin("warehouse");

        saveObjectWithEntity(plugin.getId(), "stock", "s-1", Map.of("quantity", 10), EntityType.PRODUCT, 123L);
        saveObjectWithEntity(plugin.getId(), "stock", "s-2", Map.of("quantity", 0), EntityType.PRODUCT, 123L);
        saveObjectWithEntity(plugin.getId(), "stock", "s-3", Map.of("quantity", 5), EntityType.PRODUCT, 456L);

        mockMvc.perform(get("/api/plugins/{pluginId}/objects/{objectType}?entityType=PRODUCT&entityId=123&filter=quantity:gt:0",
                        plugin.getId(), "stock"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(1)))
                .andExpect(jsonPath("$[0].objectId").value("s-1"));
    }
}
