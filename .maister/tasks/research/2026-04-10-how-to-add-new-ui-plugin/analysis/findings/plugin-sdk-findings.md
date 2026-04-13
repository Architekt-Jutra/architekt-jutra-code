# Plugin SDK Internals — Findings

## Plugin SDK Files Found

| File | Description |
|---|---|
| `src/main/frontend/src/plugin-sdk/index.ts` | SDK entry point — parses context, installs response listener, assembles and window-exposes `PluginSDK` |
| `src/main/frontend/src/plugin-sdk/types.ts` | Shared TypeScript interfaces: `PluginContext`, `Product`, `PluginObject` |
| `src/main/frontend/src/plugin-sdk/messaging.ts` | postMessage transport layer — request/response correlation, timeout, fire-and-forget |
| `src/main/frontend/src/plugin-sdk/context.ts` | Parses `window.name` (or URL hash fallback) into a `PluginContext` struct |
| `src/main/frontend/src/plugin-sdk/this-plugin.ts` | `thisPlugin` facade — plugin identity + CRUD data API + objects API |
| `src/main/frontend/src/plugin-sdk/host-app.ts` | `hostApp` facade — queries against the host (products, plugins, proxied fetch) |
| `src/main/frontend/vite.sdk.config.ts` | Separate Vite build config that produces the IIFE bundle |

## SDK Exports & Public API

### `thisPlugin`
| Member | Type | Description |
|---|---|---|
| `getContext()` | `() => PluginContext` | Returns full context |
| `.pluginId` | getter | Plugin ID |
| `.pluginName` | getter | Plugin name |
| `.productId` | getter | Present only at product-scoped extension points |
| `getData(productId)` | `Promise<unknown>` | Reads plugin-keyed data for a product |
| `setData(productId, data)` | `Promise<unknown>` | Writes plugin-keyed data for a product |
| `removeData(productId)` | `Promise<unknown>` | Deletes plugin-keyed data for a product |
| `filterChange(payload)` | `void` | Fire-and-forget; signals filter state changed |
| `objects.list(type, opts?)` | `Promise<PluginObject[]>` | Lists plugin objects by type |
| `objects.listByEntity(entityType, entityId, opts?)` | `Promise<PluginObject[]>` | Lists plugin objects for an entity |
| `objects.get(type, id)` | `Promise<PluginObject>` | Gets a single plugin object |
| `objects.save(type, id, data, opts?)` | `Promise<PluginObject>` | Upserts a plugin object |
| `objects.delete(type, id)` | `Promise<unknown>` | Deletes a plugin object |

### `hostApp`
| Member | Type | Description |
|---|---|---|
| `getProducts(params?)` | `Promise<Product[]>` | Queries the platform product list |
| `getProduct(productId)` | `Promise<Product>` | Gets a single product |
| `getPlugins()` | `Promise<unknown[]>` | Lists all registered plugins |
| `fetch(url, opts?)` | `Promise<{status, headers, body}>` | Proxied HTTP fetch — restricted to `/api/` URLs only |

## PostMessage Protocol

Bidirectional request/response over `window.parent.postMessage`. Request: `{requestId, type, payload}`. Response: `{responseId, payload, error?}`. Timeout: 10 seconds.

## Build Configuration
SDK builds as IIFE (`vite.sdk.config.ts`), served at `/assets/plugin-sdk.js`. Auto-assigns `window.PluginSDK = { hostApp, thisPlugin }` on load.
