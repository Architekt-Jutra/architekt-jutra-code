# Research Sources

Specific files and directories to investigate, in priority order.

---

## Priority 1 — Core Plugin SDK (plugin-sdk category)

| File | Purpose |
|------|---------|
| `src/main/frontend/src/plugin-sdk/index.ts` | SDK entry point — what is exported, how SDK bootstraps |
| `src/main/frontend/src/plugin-sdk/types.ts` | All TypeScript types: PluginContext, Product, PluginObject |
| `src/main/frontend/src/plugin-sdk/context.ts` | Context parsing from window.name / URL hash |
| `src/main/frontend/src/plugin-sdk/host-app.ts` | hostApp API (getProducts, getProduct, getPlugins, fetch) |
| `src/main/frontend/src/plugin-sdk/this-plugin.ts` | thisPlugin API (context, getData/setData, objects.*) |
| `src/main/frontend/src/plugin-sdk/messaging.ts` | postMessage protocol implementation |
| `src/main/frontend/vite.sdk.config.ts` | SDK build config — IIFE format, output path |

---

## Priority 2 — Host-Side Plugin Infrastructure (plugin-implementations category)

| File | Purpose |
|------|---------|
| `src/main/frontend/src/plugins/extensionPoints.ts` | All extension point type constants and the union type |
| `src/main/frontend/src/plugins/PluginFrame.tsx` | iframe rendering component — how context is injected |
| `src/main/frontend/src/plugins/PluginContext.tsx` | React context — how plugins are loaded and extension points resolved |
| `src/main/frontend/src/plugins/PluginMessageHandler.ts` | Host-side message handler — proxies SDK calls to backend |
| `src/main/frontend/src/plugins/iframeRegistry.ts` | Iframe → pluginId/pluginUrl mapping |
| `src/main/frontend/src/plugins/PluginFilterBar.tsx` | product.list.filters extension point rendering |

---

## Priority 3 — Router & Registration (router-and-registration category)

| File | Purpose |
|------|---------|
| `src/main/frontend/src/router.tsx` | Route definitions — `plugins/:pluginId/*` wildcard |
| `src/main/frontend/src/pages/PluginPageRoute.tsx` | How a plugin's full-page route renders a PluginFrame |
| `src/main/frontend/src/components/layout/Sidebar.tsx` | How menu.main extension points become nav links |
| `src/main/frontend/src/api/plugins.ts` | ManifestPayload shape, ExtensionPoint interface, API calls |
| `src/main/frontend/src/pages/PluginListPage.tsx` | Plugin management list UI |
| `src/main/frontend/src/pages/PluginFormPage.tsx` | Plugin creation/edit form (manifest upload) |
| `src/main/frontend/src/pages/ProductDetailPage.tsx` | Shows product.detail.tabs and product.detail.info usage |
| `src/main/frontend/src/pages/ProductListPage.tsx` | Shows product.list.filters usage |

---

## Priority 4 — Backend Plugin Layer (backend-plugin-layer category)

| File | Purpose |
|------|---------|
| `src/main/java/pl/devstyle/aj/core/plugin/PluginDescriptor.java` | Entity — `plugins` table schema |
| `src/main/java/pl/devstyle/aj/core/plugin/PluginDescriptorService.java` | Validation rules for manifest upload |
| `src/main/java/pl/devstyle/aj/core/plugin/PluginController.java` | REST endpoints: PUT manifest, GET, DELETE, PATCH enabled |
| `src/main/java/pl/devstyle/aj/core/plugin/PluginResponse.java` | How manifest JSON is projected into extensionPoints list |
| `src/main/java/pl/devstyle/aj/core/plugin/PluginDataController.java` | Per-plugin product data API (getData/setData/removeData) |
| `src/main/java/pl/devstyle/aj/core/plugin/PluginObjectController.java` | Generic plugin object storage API |
| `src/main/java/pl/devstyle/aj/core/plugin/PluginObjectService.java` | Plugin object storage service |
| `src/main/java/pl/devstyle/aj/core/plugin/DbPluginObjectQueryService.java` | jOOQ-based plugin object queries |

---

## Secondary / Cross-cutting Sources

| File | Purpose |
|------|---------|
| `src/main/frontend/src/main.tsx` | Verify PluginProvider wrapping at app root |
| `src/main/frontend/src/components/layout/AppShell.tsx` | Confirm PluginProvider scope |
| `src/main/resources/db/changelog/` | Any Liquibase migration creating the `plugins` table |
| `src/main/frontend/package.json` | Confirm SDK build scripts exist |
