# Research Plan — How to Add a New UI Plugin to the `aj` Platform

## Research Methodology

**Type**: Technical — Codebase Analysis with Iterative Deepening

The plugin system is entirely defined by source code (no external docs). The methodology is:

1. **Breadth-first discovery**: Identify all files involved in the plugin lifecycle (SDK, host runtime, backend, registration).
2. **Iterative deepening**: For each layer, trace the full data/control flow (manifest → backend → frontend context → iframe rendering → SDK communication).
3. **Pattern extraction**: Identify what a new plugin must provide vs. what the platform already provides, and synthesise that into a concrete step-by-step guide.

---

## Gathering Strategy

Four focused gatherer categories cover the full plugin lifecycle:

### Category 1: `plugin-sdk`
- **category_id**: `plugin-sdk`
- **category_name**: Plugin SDK Internals
- **focus_area**: Everything inside `src/main/frontend/src/plugin-sdk/`. What does the SDK export? What API does it give a plugin (hostApp, thisPlugin)? How does context bootstrapping work (window.name / URL hash)? How does the postMessage protocol work (messaging.ts)?
- **output_file_prefix**: `plugin-sdk`
- **Key questions to answer**:
  - What is the full public API surface of `PluginSDK` (`hostApp`, `thisPlugin`)?
  - How does a plugin read its own context (pluginId, extensionPoint, productId)?
  - What data operations can a plugin perform via `thisPlugin.getData/setData/objects.*`?
  - What host APIs can a plugin call via `hostApp.getProducts/getProduct/fetch`?
  - How is the SDK built and distributed (`vite.sdk.config.ts`, IIFE format)?
  - What is the postMessage wire protocol (request/response shape, `aj.plugin.*` prefix)?

### Category 2: `plugin-implementations`
- **category_id**: `plugin-implementations`
- **category_name**: Host-Side Plugin Rendering Components
- **focus_area**: Everything inside `src/main/frontend/src/plugins/`. How does the host app render plugins via iframes? How are extension points resolved and filtered? How does the message handler bridge SDK calls to backend APIs?
- **output_file_prefix**: `plugin-impl`
- **Key questions to answer**:
  - What extension point types exist (`extensionPoints.ts`), and what does each do?
  - How is `PluginFrame` configured (props: pluginId, pluginUrl, contextType, path, contextData)?
  - How is context passed into the iframe (window.name format: `PREFIX{json}`, URL hash fallback)?
  - How does `PluginContext` / `PluginProvider` load plugin data and expose it to the app?
  - How does `PluginMessageHandler` proxy SDK calls to backend endpoints?
  - What is `iframeRegistry` and why is it needed?

### Category 3: `router-and-registration`
- **category_id**: `router-and-registration`
- **category_name**: Router Integration & Plugin Registration Flow
- **focus_area**: `router.tsx`, `pages/PluginPageRoute.tsx`, `pages/PluginListPage.tsx`, `pages/PluginFormPage.tsx`, `components/layout/Sidebar.tsx`, and `api/plugins.ts`. How does a plugin's `menu.main` extension point become a sidebar link and a routed page? How is a plugin registered with the backend (manifest upload)?
- **output_file_prefix**: `router-registration`
- **Key questions to answer**:
  - How is the `plugins/:pluginId/*` wildcard route used to delegate all sub-paths to a plugin iframe?
  - How does `Sidebar.tsx` consume `getMenuItems()` to create nav links automatically?
  - What is the manifest upload flow (`PUT /api/plugins/:id/manifest`), and what fields are required?
  - What is the `ManifestPayload` shape (name, version, url, extensionPoints array)?
  - What extension point fields are required for each type (label, path, priority, icon, filterKey, filterType)?
  - How does `PluginFormPage` / `PluginListPage` expose the plugin management UI?

### Category 4: `backend-plugin-layer`
- **category_id**: `backend-plugin-layer`
- **category_name**: Backend Plugin Infrastructure
- **focus_area**: All files in `src/main/java/pl/devstyle/aj/core/plugin/`. How does the backend store and serve plugin descriptors? What REST endpoints exist? What validation rules apply to plugin IDs and manifests?
- **output_file_prefix**: `backend-plugin`
- **Key questions to answer**:
  - How is a `PluginDescriptor` stored (database table `plugins`, `id` is a user-chosen string)?
  - What does `PluginDescriptorService.uploadManifest` validate (pluginId pattern, name, url format)?
  - How is the `manifest` JSON blob stored and what fields does `PluginResponse` expose?
  - What backend data APIs does a plugin get (`PluginDataController` — getData/setData/removeData, `PluginObjectController`)?
  - Is any backend code required to create a new UI plugin, or is it purely manifest-driven?

---

## Success Criteria

- [ ] Step-by-step answer: what files must a new plugin project contain to work with this platform?
- [ ] Clear understanding of all four extension point types and their manifest field requirements.
- [ ] Understanding of the SDK bootstrap lifecycle (how a plugin page reads its context on load).
- [ ] Understanding of the postMessage communication protocol between plugin iframe and host.
- [ ] Confirmed whether any backend code changes are needed (answer: no — manifest upload is sufficient).
- [ ] A reference manifest example covering each extension point type.

---

## Confidence Indicators

High confidence is achievable for this research because:
- All relevant source code exists in the repo and is relatively small.
- The plugin system is well-structured with clear separation between SDK, host runtime, and backend.
- No external documentation is needed — the code is the spec.

Expected confidence level: **High** (all questions answerable from codebase alone).
