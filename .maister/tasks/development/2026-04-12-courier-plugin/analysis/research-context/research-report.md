# How to Add a New UI Plugin to the `aj` Platform

## Executive Summary

The `aj` platform uses a **micro-frontend plugin model**: each plugin is an independent web application loaded inside a sandboxed `<iframe>` by the host. To add a new UI plugin you need to: (1) build a web app that loads the Plugin SDK from the host, (2) register it with the platform via a single `PUT /api/plugins/{id}/manifest` API call that declares the plugin's identity, URL, and which extension points it occupies, and (3) keep the app running at the declared URL. The host then automatically renders the plugin at the correct places in the UI (sidebar, product tabs, filters, info strip) and provides a postMessage-based SDK for the plugin to read context and persist data. The platform is pre-alpha and has a known blocking issue in `PluginDescriptor.java` (missing Lombok annotations) that must be fixed before data APIs work end-to-end.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                   aj Host Application                    │
│  ┌──────────────┐   ┌──────────────┐  ┌──────────────┐ │
│  │  React Router│   │PluginContext │  │PluginFrame   │ │
│  │  (routes)    │──▶│ (React ctx) │──▶│ (iframe mgr) │ │
│  └──────────────┘   └──────────────┘  └──────┬───────┘ │
│                                               │ iframe  │
│  ┌────────────────────────────────────────────▼───────┐ │
│  │          PluginMessageHandler                      │ │
│  │   (routes postMessage → REST API calls)            │ │
│  └────────────────────────────────────────────────────┘ │
│                                                          │
│  REST API: /api/plugins/**, /api/plugins/{id}/products/**│
│            /api/plugins/{id}/objects/**                  │
└─────────────────────────────────────────────────────────┘
           ↑ postMessage (requestId/responseId)
┌──────────────────────────────────────────┐
│          Your Plugin Web App             │
│  ┌──────────────────────────────────┐   │
│  │  <script src="/assets/           │   │
│  │     plugin-sdk.js">              │   │
│  │  window.PluginSDK.thisPlugin.*   │   │
│  │  window.PluginSDK.hostApp.*      │   │
│  └──────────────────────────────────┘   │
│  Served at: http://your-plugin-url       │
└──────────────────────────────────────────┘
```

**Data flow:**

1. Plugin is registered in the database via the manifest API.
2. When the host renders an extension point, `PluginFrame` creates an `<iframe>`, sets `iframe.name = contextJSON`, then sets `iframe.src = pluginUrl`.
3. The plugin app loads, the SDK reads context from `window.name`, and exposes `window.PluginSDK`.
4. All SDK calls (data, products, fetch) go through `window.parent.postMessage`. The host's `PluginMessageHandler` receives them, validates origin via `iframeRegistry`, and forwards to the appropriate REST endpoints.
5. Responses return via postMessage and resolve the SDK's Promises.

---

## Step-by-Step: Adding a New UI Plugin

### Step 1: Create Your Plugin App

Create any web application (React, Vue, plain HTML — any framework works). It must be:

- Served over HTTP or HTTPS at a stable URL (e.g., `http://localhost:3001` in development)
- Able to load a `<script>` tag from the host domain at runtime

There is no prescribed scaffold or template. The test fixtures use simple apps at `http://localhost:3001` (warehouse) and `http://localhost:3002` (analytics).

---

### Step 2: Load the Plugin SDK

In your plugin app's HTML, load the SDK script from the host application's origin:

```html
<!-- Replace with your actual host origin -->
<script src="http://localhost:8080/assets/plugin-sdk.js"></script>
```

This script is built as an IIFE by `vite.sdk.config.ts` and auto-assigns `window.PluginSDK` on load:

```typescript
window.PluginSDK = {
  thisPlugin: { ... },
  hostApp:    { ... }
}
```

After this script executes, `window.PluginSDK` is immediately available — no async init call required.

---

### Step 3: Read Context on Load

The host injects plugin context synchronously by setting `iframe.name` before writing `iframe.src`. Your app should read this on startup:

```typescript
const ctx = window.PluginSDK.thisPlugin.getContext();
// ctx: { pluginId, pluginName, extensionPointType, productId? }

console.log(ctx.pluginId);           // e.g. "warehouse"
console.log(ctx.extensionPointType); // e.g. "product.detail.tabs"
console.log(ctx.productId);          // present only at product-scoped points
```

`productId` is only populated at `product.detail.tabs` and `product.detail.info` extension points.

If `window.name` parsing fails, the SDK falls back to the URL hash (set by the host as a secondary mechanism).

---

### Step 4: Register Your Plugin via Manifest

Registration is a single REST call. You can make it from the `aj` Admin UI (`/plugins/new`) or directly via HTTP.

#### Manifest Format

```json
{
  "name": "My Plugin",
  "version": "1.0.0",
  "url": "http://localhost:3001",
  "description": "An optional description",
  "extensionPoints": [
    {
      "type": "menu.main",
      "label": "My Plugin",
      "icon": "box",
      "path": "/dashboard",
      "priority": 10
    },
    {
      "type": "product.detail.tabs",
      "label": "My Tab",
      "priority": 1
    },
    {
      "type": "product.list.filters",
      "label": "My Filter",
      "filterKey": "myFilterKey",
      "filterType": "boolean",
      "priority": 5
    },
    {
      "type": "product.detail.info",
      "priority": 1
    }
  ]
}
```

**Field reference:**

| Field | Required | Notes |
|---|---|---|
| `name` | Yes | Display name |
| `version` | Yes | Semver string, e.g. `"1.0.0"` |
| `url` | Yes (if calling via API) | Must be `http://` or `https://` |
| `description` | No | Optional human-readable description |
| `extensionPoints` | No | Omit to register a plugin with no UI surface |
| `extensionPoints[].type` | Yes | One of the 4 supported types |
| `extensionPoints[].label` | No | Display text for nav/tab |
| `extensionPoints[].icon` | No | Lucide icon name in kebab-case (e.g. `"shopping-bag"`) |
| `extensionPoints[].path` | No | Sub-path appended to `/plugins/{id}/` for `menu.main` |
| `extensionPoints[].priority` | Yes | Integer; lower numbers render first |
| `extensionPoints[].filterKey` | No | Required for `product.list.filters` |
| `extensionPoints[].filterType` | No | `"boolean"` \| `"string"` \| `"number"` |

#### API Call

```http
PUT /api/plugins/{pluginId}/manifest
Content-Type: application/json

{ ...manifest body above... }
```

- `{pluginId}` must match `^[a-zA-Z0-9_-]+$` — alphanumeric, hyphens, underscores only.
- This call is an **upsert** — calling it again updates the existing plugin record.
- Returns `200 OK` with the plugin record on success.

**cURL example:**

```bash
curl -X PUT http://localhost:8080/api/plugins/my-plugin/manifest \
  -H "Content-Type: application/json" \
  -d '{
    "name": "My Plugin",
    "version": "1.0.0",
    "url": "http://localhost:3001",
    "extensionPoints": [
      { "type": "menu.main", "label": "My Plugin", "icon": "box", "path": "/", "priority": 10 }
    ]
  }'
```

---

### Step 5: Using the SDK APIs

After the SDK is loaded and context is read, use `window.PluginSDK.thisPlugin` and `window.PluginSDK.hostApp` for all platform interactions.

#### `thisPlugin` API

```typescript
const { thisPlugin } = window.PluginSDK;

// Identity
thisPlugin.pluginId;             // string — your plugin's ID
thisPlugin.pluginName;           // string — your plugin's name
thisPlugin.productId;            // string | undefined — current product scope

// Per-product data (one record per plugin+product)
await thisPlugin.getData(productId);          // Promise<unknown>
await thisPlugin.setData(productId, data);    // Promise<unknown>
await thisPlugin.removeData(productId);       // Promise<unknown>

// Plugin objects (structured, multi-record)
await thisPlugin.objects.list(type, opts?);
await thisPlugin.objects.listByEntity(entityType, entityId, opts?);
await thisPlugin.objects.get(type, id);
await thisPlugin.objects.save(type, id, data, opts?);
await thisPlugin.objects.delete(type, id);

// Filter bar
thisPlugin.filterChange(payload);    // fire-and-forget: signal filter state changed
```

#### `hostApp` API

```typescript
const { hostApp } = window.PluginSDK;

// Product queries
await hostApp.getProducts(params?);       // Promise<Product[]>
await hostApp.getProduct(productId);      // Promise<Product>

// Plugin list
await hostApp.getPlugins();              // Promise<unknown[]>

// Proxied HTTP (restricted to /api/ paths only)
const result = await hostApp.fetch('/api/categories', { method: 'GET' });
// result: { status: number, headers: object, body: string }
```

---

## Extension Points Reference

| Type | Value | Where Rendered | iframe Size | Context |
|---|---|---|---|---|
| Main Menu | `menu.main` | Sidebar navigation links | Full page (on navigation) | pluginId, pluginName |
| Product Detail Tab | `product.detail.tabs` | Tab strip on product detail page | 600px height | pluginId, pluginName, productId |
| Product List Filter | `product.list.filters` | Filter bar above product list | Variable | pluginId, pluginName |
| Product Detail Info | `product.detail.info` | Info strip below product detail | 60px height | pluginId, pluginName, productId |

### Extension Point Details

#### `menu.main`
Adds a link to the sidebar navigation. When clicked, navigates to `/plugins/{pluginId}{path}` which renders your plugin in a full-page iframe. The `label` and `icon` fields control how the sidebar item looks. `priority` controls sort order (lower = higher in the list).

#### `product.detail.tabs`
Adds a tab to the product detail page. The iframe is 600px tall. The `productId` context value is always set — use it with `thisPlugin.getData(productId)` to load product-specific state.

#### `product.list.filters`
Renders filter controls in the product list filter bar. Use `filterKey` to identify the filter field and `filterType` to declare the data type. Call `thisPlugin.filterChange(payload)` when the user changes a filter value.

#### `product.detail.info`
Renders a compact (60px) info strip below the product details section. Useful for summary badges or quick indicators. `productId` context is always set.

---

## Plugin SDK Reference

### `PluginContext` Type

```typescript
interface PluginContext {
  pluginId: string;
  pluginName: string;
  extensionPointType: string;  // one of the 4 extension point type values
  productId?: string;          // present at product.detail.tabs and product.detail.info
}
```

### `Product` Type

```typescript
interface Product {
  // Fields returned by /api/products — exact shape depends on backend
  id: number;
  name: string;
  // ... other product fields
}
```

### `PluginObject` Type

```typescript
interface PluginObject {
  id: string;          // plugin-defined ID
  type: string;        // plugin-defined type
  data: unknown;       // arbitrary JSON
  entityType?: string; // "PRODUCT" | "CATEGORY" if entity-bound
  entityId?: number;   // the entity's ID if entity-bound
}
```

### `thisPlugin` Full Reference

| Method/Property | Signature | Description |
|---|---|---|
| `getContext()` | `() => PluginContext` | Returns full context struct synchronously |
| `pluginId` | getter `string` | Shorthand for `getContext().pluginId` |
| `pluginName` | getter `string` | Shorthand for `getContext().pluginName` |
| `productId` | getter `string \| undefined` | Shorthand for `getContext().productId` |
| `getData(productId)` | `(string) => Promise<unknown>` | Read plugin data for a specific product |
| `setData(productId, data)` | `(string, unknown) => Promise<unknown>` | Write plugin data for a specific product |
| `removeData(productId)` | `(string) => Promise<unknown>` | Delete plugin data for a specific product |
| `filterChange(payload)` | `(unknown) => void` | Signal a filter state change (fire-and-forget) |
| `objects.list(type, opts?)` | `(string, opts?) => Promise<PluginObject[]>` | List all objects of a given type |
| `objects.listByEntity(entityType, entityId, opts?)` | `(string, number, opts?) => Promise<PluginObject[]>` | List objects bound to an entity |
| `objects.get(type, id)` | `(string, string) => Promise<PluginObject>` | Fetch one object by type+id |
| `objects.save(type, id, data, opts?)` | `(string, string, unknown, opts?) => Promise<PluginObject>` | Upsert an object |
| `objects.delete(type, id)` | `(string, string) => Promise<unknown>` | Delete an object by type+id |

### `hostApp` Full Reference

| Method | Signature | Description |
|---|---|---|
| `getProducts(params?)` | `(params?) => Promise<Product[]>` | Query the platform product list |
| `getProduct(productId)` | `(string) => Promise<Product>` | Fetch a single product by ID |
| `getPlugins()` | `() => Promise<unknown[]>` | List all registered plugins |
| `fetch(url, opts?)` | `(string, RequestInit?) => Promise<{status, headers, body}>` | Proxied HTTP — `/api/` paths only |

---

## PostMessage Protocol Reference

All SDK calls that require host interaction use a bidirectional postMessage protocol.

### Request Shape

```typescript
{
  requestId: string;   // UUID generated by the SDK
  type: string;        // message type, e.g. "GET_PRODUCTS", "SET_DATA"
  payload: unknown;    // type-specific payload
}
```

### Response Shape

```typescript
{
  responseId: string;  // matches the requestId from the request
  payload: unknown;    // result data on success
  error?: string;      // error message if the call failed
}
```

### Behavior

- **Timeout**: 10 seconds. If no response arrives within 10s, the Promise rejects.
- **Correlation**: Each call creates a Promise; the response listener matches `responseId` to `requestId` to resolve/reject the correct Promise.
- **Security**: The host validates each incoming message's origin against `iframeRegistry` (a map of active iframe origins → plugin info). Messages from unknown origins are silently dropped.
- **Fire-and-forget**: `thisPlugin.filterChange()` sends a message without waiting for a response.

---

## Data Persistence Reference

### Tier 1: Per-Product Data (`thisPlugin.getData/setData/removeData`)

**Use when:** You need to store one piece of configuration or state per product, scoped to your plugin.

- **Cardinality**: One record per `(pluginId, productId)` pair.
- **Storage**: Backend endpoint `PUT/GET/DELETE /api/plugins/{pluginId}/products/{productId}/data`
- **Data format**: Arbitrary JSON (stored as JSONB)
- **Best for**: Product-scoped settings, plugin state tied to a single product

```typescript
// Save preferences for product 42
await thisPlugin.setData("42", { theme: "dark", columns: ["sku", "price"] });

// Read them back
const prefs = await thisPlugin.getData("42");
```

### Tier 2: Plugin Objects (`thisPlugin.objects.*`)

**Use when:** You need to store multiple structured records with your own type system, or want to associate records with platform entities.

- **Cardinality**: Many records per plugin; identified by `(pluginId, objectType, objectId)`.
- **Storage**: Backend endpoint `PUT/GET/DELETE /api/plugins/{pluginId}/objects/{objectType}/{objectId}`
- **Entity binding**: Optionally bind a record to a `PRODUCT` or `CATEGORY` entity using `entityType` + `entityId`.
- **Data format**: Arbitrary JSON (stored as JSONB)
- **Best for**: Structured collections (e.g., inventory records, annotations, alerts)

```typescript
// Save a warehouse location record
await thisPlugin.objects.save("location", "LOC-001", {
  aisle: "B", shelf: 3, quantity: 150
});

// List all locations for product ID 42
await thisPlugin.objects.listByEntity("PRODUCT", 42);

// Get a specific location
const loc = await thisPlugin.objects.get("location", "LOC-001");
```

### Disabled Plugin Behavior

If a plugin is disabled (`enabled = false`), **all data API calls return `404`**. The plugin must be enabled for any persistence operations to succeed.

---

## Known Gaps & Pre-Alpha Status

### Critical: `PluginDescriptor` Missing Lombok Annotations

`PluginDescriptor.java` is missing `@Getter` and `@Setter` Lombok annotations. This causes compile-time errors across the plugin subsystem:

**Affected files:**
- `PluginDescriptorService.java` — All setter calls (`setId`, `setName`, `setUrl`, `setEnabled`, `setManifest`, etc.) and getter calls (`isEnabled`) fail to compile.
- `PluginResponse.java` — All getter calls (`getId`, `getName`, `getVersion`, `getUrl`, `getDescription`, `isEnabled`, `getManifest`) fail to compile.
- Test files `PluginObjectApiAndFilterTests.java` and `PluginGapTests.java` — All `PluginDescriptor` setter/getter calls fail.

**Impact:** The plugin registration and data APIs are non-functional until this is resolved.

**Fix:** Add `@Getter @Setter @NoArgsConstructor` to `PluginDescriptor.java` (consistent with the project's AGENTS.md conventions for JPA entities).

### Other Known Gaps

| Gap | Impact | Notes |
|---|---|---|
| No backend validation of `extensionPoints` structure | Silent failures at render time | Invalid extension point types are stored and only fail when the host tries to render them |
| `product.list.filters` / `filterChange` behavior underdocumented | Uncertain filter implementation | The contract between `filterKey`, `filterType`, and `filterChange` payload is not explicitly documented |
| No prescribed plugin app template or scaffold | Higher bootstrap effort | Any web app works; no official starter exists |
| CORS / CSP requirements for production not documented | Production deployment uncertainty | Development uses permissive localhost settings; production requirements unknown |
| `hostApp.fetch` allowlist enforcement details not confirmed | Security model partially opaque | Documented as "restricted to /api/ only" but enforcement code not fully traced |
| `Category` and `Product` entities also missing Lombok in tests | Broad test compilation failures | Multiple test files fail due to missing annotations on domain entities beyond `PluginDescriptor` |

---

## Confidence Assessment

| Topic | Confidence | Rationale |
|---|---|---|
| Overall plugin architecture (micro-frontend via iframes) | **High** | Consistent across all 4 source categories; explicitly documented |
| Manifest format and registration API | **High** | TypeScript interfaces confirmed by backend validation rules |
| SDK public API surface (`thisPlugin`, `hostApp`) | **High** | Source code directly read from `this-plugin.ts` and `host-app.ts` |
| Extension point types, values, and rendering | **High** | Constants read verbatim from `extensionPoints.ts`; test fixtures confirm |
| Context injection mechanism (`window.name`) | **High** | Both `PluginFrame.tsx` and `context.ts` independently confirm this |
| postMessage protocol (request/response shape, timeout) | **High** | Directly read from `messaging.ts` |
| Two-tier data persistence (per-product data vs objects) | **High** | Both backend tables and SDK methods confirmed |
| `PluginDescriptor` Lombok gap | **High** | Confirmed by LSP errors in 4 files |
| `product.list.filters` full rendering contract | **Low** | Fields exist in types; rendering logic not fully traced |
| Production CORS / CSP requirements | **Low** | Not found in any source; gap |

**Overall research confidence: High** — The core question (how to add a new UI plugin) is answered completely and with high confidence from direct source code inspection. The gaps are secondary concerns that do not block understanding the plugin addition workflow.
