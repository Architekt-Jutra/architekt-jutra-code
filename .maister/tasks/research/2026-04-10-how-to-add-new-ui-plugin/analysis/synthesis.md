# Research Synthesis — How to Add a New UI Plugin to the `aj` Platform

## Cross-Category Pattern Analysis

### 1. Architecture Pattern: Micro-Frontend via Sandboxed iframes

All four categories converge on a single architectural truth: **plugins are standalone web apps** loaded inside sandboxed iframes. There is no plugin code bundled into the host. The `plugins/` directory in the frontend is purely host-side orchestration infrastructure (rendering, messaging, context injection). This pattern is consistent and high-confidence.

Cross-references:
- `plugin-impl-findings.md`: "There are NO bundled plugin implementations in `src/main/frontend/src/plugins/`. That directory is host-side infrastructure only."
- `router-registration-findings.md`: Manifest requires a `url` field — the base URL of the external plugin app.
- `backend-plugin-findings.md`: `plugins.url` column stores the plugin's origin URL.
- `plugin-sdk-findings.md`: The SDK is served by the host at `/assets/plugin-sdk.js` and loaded into the plugin iframe's context.

### 2. Registration Pattern: Manifest-First, Single API Call

Plugin registration is stateless from the plugin's perspective — a single `PUT /api/plugins/{id}/manifest` call creates or updates the full plugin record (ID, name, URL, version, extension points). No handshake, no build step, no deployment into the host.

Cross-references:
- `router-registration-findings.md`: `uploadManifest(id, manifest)` → `PUT /api/plugins/:id/manifest`
- `backend-plugin-findings.md`: Confirms the PUT endpoint upserts the plugin row plus stores the manifest JSONB verbatim.
- `backend-plugin-findings.md`: Plugin ID must match `^[a-zA-Z0-9_-]+$` — only validated on the backend, not the frontend form.

### 3. Context Injection Pattern: window.name + URL Hash

The host injects plugin context (pluginId, pluginName, productId, extensionPointType) by setting `iframe.name` before the `src` attribute is written. The SDK reads this on load (`context.ts`). A URL hash fallback exists for browsers where `window.name` is unavailable.

Cross-references:
- `plugin-impl-findings.md`: "Sets `iframe.name = contextString` before setting `src`, ensuring plugin can read context synchronously."
- `plugin-sdk-findings.md`: `context.ts` parses `window.name` (or URL hash fallback) into a `PluginContext` struct.
- The combination ensures the plugin knows who it is before any postMessage handshake.

### 4. Communication Pattern: postMessage Request/Response

All SDK calls that reach the host (data reads/writes, product queries, proxied fetch) go through a unified postMessage channel. Each call gets a `requestId`; responses are matched by `responseId`. A 10-second timeout prevents hung promises. The host validates the origin of each message against `iframeRegistry`.

Cross-references:
- `plugin-sdk-findings.md`: `messaging.ts` documents the protocol in detail.
- `plugin-impl-findings.md`: `PluginMessageHandler.ts` is the host-side router for SDK calls → REST endpoints.
- `plugin-impl-findings.md`: `iframeRegistry.ts` maintains an origin-to-plugin mapping for security validation.

### 5. Data Pattern: Two Storage Tiers

Plugins have two distinct storage mechanisms with different cardinality semantics:
- **Per-product data** (`plugin_data` via `thisPlugin.getData/setData/removeData`): One record per plugin+product pair. Best for product-scoped configuration or state.
- **Plugin objects** (`plugin_objects` via `thisPlugin.objects.*`): Many records per plugin, with a user-defined `type` + `id` key. Supports optional entity binding (PRODUCT or CATEGORY). Best for structured, queryable data collections.

Cross-references:
- `backend-plugin-findings.md`: Both `plugin_data` (implied by the data endpoints) and `plugin_objects` tables are present.
- `plugin-sdk-findings.md`: `thisPlugin.getData/setData/removeData` and `thisPlugin.objects.*` map directly to the two storage tiers.

### 6. Extension Point Pattern: Type Determines Rendering Contract

The four extension point types are not interchangeable — each carries a different rendering contract (iframe size, available context, UI placement):

| Type | Rendering | Context Available |
|---|---|---|
| `menu.main` | Sidebar nav link → iframe page | pluginId, pluginName |
| `product.detail.tabs` | Tab in product detail (600px iframe) | pluginId, productId |
| `product.list.filters` | Filter bar controls | pluginId, filterKey |
| `product.detail.info` | Info strip (60px iframe) | pluginId, productId |

Cross-references:
- `plugin-impl-findings.md`: Extension point constants and rendering locations.
- `router-registration-findings.md`: Manifest `extensionPoints` array with `type`, `label`, `icon`, `path`, `priority`, `filterKey`, `filterType`.

---

## Gaps and Uncertainties

### Gap 1: PluginDescriptor Lombok Annotations (Known Pre-Alpha Issue)
The backend `PluginDescriptorService.java` has existing LSP errors, and test files fail because `PluginDescriptor` is missing Lombok `@Getter`/`@Setter` annotations. This is a known project gap that affects data access on the descriptor entity. Confidence: **high** (LSP errors are explicit signals).

### Gap 2: No Backend Validation of extensionPoints
The backend stores `extensionPoints` as part of the JSONB manifest verbatim. There is no schema validation of the extension point structure on the server side — invalid types or missing required fields will be stored silently and only fail at render time in the host frontend.

### Gap 3: `filterKey` / `filterType` Contract Underdocumented
The `product.list.filters` extension point accepts `filterKey` and `filterType` fields, and `PluginFilterBar.tsx` renders them — but the exact rendering behavior and how the plugin app should respond to filter state changes (via `thisPlugin.filterChange`) is not fully documented in the discovered files.

### Gap 4: Plugin App Bootstrap Not Prescribed
There is no prescribed framework or template for the plugin app itself. Test fixtures reference `http://localhost:3001` and `http://localhost:3002`, implying any web server works. The only requirement is loading `plugin-sdk.js` from the host.

### Gap 5: CORS and Security for Production Deployments
The iframe sandbox allows `allow-same-origin`, but no findings document how CORS headers should be configured on the plugin app server for production use, or whether there are Content Security Policy rules in the host that restrict plugin origins.

### Gap 6: `hostApp.fetch` Scope
`hostApp.fetch` is documented as "restricted to `/api/` URLs only" but the enforcement mechanism (host-side allowlist check in `PluginMessageHandler`) is not fully detailed in the available findings.

---

## Confidence Levels by Finding

| Finding | Confidence | Rationale |
|---|---|---|
| Plugins are standalone web apps loaded via iframes | High | Explicitly stated in impl findings; consistent across all 4 sources |
| Registration via `PUT /api/plugins/{id}/manifest` | High | Found in both frontend API module and backend controller |
| Manifest JSON schema (name, version, url, extensionPoints) | High | TypeScript interface found in router findings; confirmed by backend validation rules |
| SDK loaded from `/assets/plugin-sdk.js` | High | Explicit in SDK build config (`vite.sdk.config.ts`) |
| Context injected via `window.name` before iframe src | High | Found in both `PluginFrame.tsx` and `context.ts` |
| postMessage protocol shape (requestId/responseId/timeout) | High | Explicit in `messaging.ts` |
| All 4 extension point constants and values | High | Found verbatim in `extensionPoints.ts` |
| `thisPlugin` and `hostApp` full API | High | Directly read from `this-plugin.ts` and `host-app.ts` |
| Two storage tiers (data vs objects) semantics | Medium | Backend tables confirmed; exact per-product data table name inferred |
| `filterKey`/`filterType` rendering behavior | Low | Fields documented in manifest type; rendering logic not fully traced |
| Production CORS / CSP requirements | Low | Not found in any source — gap |
| PluginDescriptor Lombok issue | High | Confirmed by pre-alpha context note |
