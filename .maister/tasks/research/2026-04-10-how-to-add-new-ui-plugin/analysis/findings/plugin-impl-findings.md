# Plugin Implementations & Host Rendering — Findings

## Key Finding
There are NO bundled plugin implementations in `src/main/frontend/src/plugins/`. That directory is **host-side infrastructure** only. Plugins are external web apps.

## Host-Side Infrastructure Files

| File | Purpose |
|---|---|
| `src/main/frontend/src/plugins/PluginContext.tsx` | React context + `<PluginProvider>` + `usePluginContext()` hook |
| `src/main/frontend/src/plugins/PluginFrame.tsx` | Renders sandboxed iframe, sets context, registers in registry |
| `src/main/frontend/src/plugins/PluginMessageHandler.ts` | Host-side message handler — routes SDK calls to REST endpoints |
| `src/main/frontend/src/plugins/iframeRegistry.ts` | In-memory map of iframe → PluginInfo for origin validation |
| `src/main/frontend/src/plugins/PluginFilterBar.tsx` | Renders plugin-provided filter controls in product list |
| `src/main/frontend/src/plugins/extensionPoints.ts` | Extension point constants + union type |

## Extension Points
| Constant | Value | Where Rendered |
|---|---|---|
| `MENU_MAIN` | `"menu.main"` | Sidebar nav links |
| `PRODUCT_DETAIL_TABS` | `"product.detail.tabs"` | Product detail page tabs (600px iframe) |
| `PRODUCT_LIST_FILTERS` | `"product.list.filters"` | Product list filter controls |
| `PRODUCT_DETAIL_INFO` | `"product.detail.info"` | Info strip below product details (60px iframe) |

## PluginFrame Behavior
Sets `iframe.name = contextString` before setting `src`, ensuring plugin can read context synchronously. Also sets URL hash as fallback. Sandboxed with `allow-scripts allow-same-origin allow-forms allow-popups allow-modals allow-downloads`.

## Concrete Plugin Examples (from test fixtures)
| Plugin ID | Name | URL | Extension Points |
|---|---|---|---|
| `warehouse` | Warehouse Management | `http://localhost:3001` | `menu.main`, `product.detail.tabs`, `product.list.filters` |
| `analytics` | Analytics Dashboard | `http://localhost:3002` | `menu.main`, `product.detail.tabs` |
