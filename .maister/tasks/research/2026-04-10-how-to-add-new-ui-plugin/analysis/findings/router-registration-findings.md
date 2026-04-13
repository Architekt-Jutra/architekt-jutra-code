# Router Integration & Manifest Registration — Findings

## Router Configuration
Key plugin routes in `src/main/frontend/src/router.tsx`:
| Route | Component | Purpose |
|---|---|---|
| `plugins` | `PluginListPage` | List all plugins |
| `plugins/new` | `PluginFormPage` | Register a new plugin |
| `plugins/:pluginId/detail` | `PluginDetailPage` | View plugin details |
| `plugins/:pluginId/edit` | `PluginFormPage` | Edit plugin manifest |
| **`plugins/:pluginId/*`** | **`PluginPageRoute`** | **Wildcard: renders plugin UI in iframe** |

## Manifest Shape
```typescript
interface ManifestPayload {
  name: string;               // required
  version: string;            // required, e.g. "1.0.0"
  url: string;                // required, base URL of the plugin app
  description?: string;
  extensionPoints?: ExtensionPoint[];
}

interface ExtensionPoint {
  type: ExtensionPointType;   // "menu.main" | "product.detail.tabs" | "product.list.filters" | "product.detail.info"
  label?: string;
  icon?: string;              // Lucide icon name (kebab-case)
  path?: string;              // Sub-path under /plugins/:id/
  priority: number;           // Lower = first
  filterKey?: string;         // For product.list.filters
  filterType?: "boolean" | "string" | "number";
}
```

## Plugin API (Frontend)
| Function | Endpoint | Purpose |
|---|---|---|
| `getPlugins()` | `GET /api/plugins` | Fetch all plugins |
| `getPlugin(id)` | `GET /api/plugins/:id` | Fetch single plugin |
| `uploadManifest(id, manifest)` | **`PUT /api/plugins/:id/manifest`** | **Register or update** |
| `deletePlugin(id)` | `DELETE /api/plugins/:id` | Delete plugin |
| `setPluginEnabled(id, enabled)` | `PATCH /api/plugins/:id/enabled` | Enable/disable |

## Navigation Integration
Sidebar reads `getMenuItems()` from `PluginContext`, which returns resolved `menu.main` extension points sorted by `priority`. Each renders as a nav link at `/plugins/{pluginId}{path}`.
