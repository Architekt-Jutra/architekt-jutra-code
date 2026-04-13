# Codebase Analysis — Courier Plugin

**Task**: Implement a new frontend courier plugin providing order number storage per product, order status management, and delivery method selection based on box size.

**Analysis Date**: 2026-04-12
**Agents Used**: File Discovery, Code Analysis, Pattern Mining (3 agents)

---

## Summary

The courier plugin is a **pure frontend task** — no backend changes are required. All necessary infrastructure (plugin object storage, entity binding, JSONB filtering) is already in place. The implementation follows the exact same pattern as the existing `warehouse` plugin: a standalone Vite+React+TypeScript app in `plugins/courier/`, registered via manifest, using the Plugin SDK for data access and `plugin-ui.css` for styling.

**Complexity**: Low-to-moderate. Well-understood patterns; two reference plugins available.
**Risk Level**: Low. No schema changes, no backend changes, isolated frontend app.

---

## Key Files

### Plugin Infrastructure (Backend — read-only, no changes needed)

| File | Purpose |
|------|---------|
| `src/main/java/pl/devstyle/aj/core/plugin/PluginDescriptor.java` | JPA entity for plugin registry (plugins table) |
| `src/main/java/pl/devstyle/aj/core/plugin/PluginDescriptorService.java` | Manifest upsert and plugin lookup |
| `src/main/java/pl/devstyle/aj/core/plugin/PluginController.java` | REST `/api/plugins` — PUT `/{id}/manifest` to register |
| `src/main/java/pl/devstyle/aj/core/plugin/PluginObject.java` | JPA entity for plugin_objects table (stores all courier orders) |
| `src/main/java/pl/devstyle/aj/core/plugin/PluginObjectController.java` | REST `/api/plugins/{id}/objects/**` — CRUD for objects |
| `src/main/java/pl/devstyle/aj/core/plugin/PluginObjectService.java` | Upsert with entity binding logic |
| `src/main/java/pl/devstyle/aj/core/plugin/DbPluginObjectQueryService.java` | jOOQ JSONB filtering for list/filter queries |
| `src/main/java/pl/devstyle/aj/core/plugin/EntityType.java` | `PRODUCT` / `CATEGORY` enum |
| `src/main/resources/db/changelog/006-create-plugin-objects-table.yaml` | plugin_objects schema (already deployed) |
| `src/main/resources/db/changelog/007-add-entity-binding-to-plugin-objects.yaml` | entityType/entityId columns (already deployed) |

### SDK & Host Frontend (read-only)

| File | Purpose |
|------|---------|
| `plugins/sdk.ts` | Shared type declarations — `PluginSDKType`, `PluginContext`, `PluginObject`, `getSDK()` |
| `src/main/frontend/src/plugin-sdk/` | Host-side SDK implementation (IIFE → `/assets/plugin-sdk.js`) |
| `src/main/frontend/src/plugins/PluginFrame.tsx` | Renders plugin iframes at extension points |
| `src/main/frontend/src/plugins/extensionPoints.ts` | Extension point registry |
| `src/main/frontend/src/router.tsx` | Catch-all `plugins/:pluginId/*` → `PluginPageRoute` |
| `src/main/frontend/src/pages/ProductDetailPage.tsx` | Renders `product.detail.tabs` extension points |

### Reference Plugins (template source)

| File | Purpose |
|------|---------|
| `plugins/warehouse/` | Primary reference: `thisPlugin.objects` CRUD, entity binding, `menu.main` + `product.detail.tabs` |
| `plugins/warehouse/src/domain.ts` | Pattern for domain types + `toXxx()` mapper functions |
| `plugins/warehouse/src/main.tsx` | Pattern for `BrowserRouter` + `Routes` setup |
| `plugins/warehouse/src/pages/WarehousePage.tsx` | Full-page plugin with `useCallback` + `useEffect` data loading |
| `plugins/warehouse/src/pages/ProductStockTab.tsx` | Product tab with `productId` guard + entity-filtered list |
| `plugins/warehouse/vite.config.ts` | Template: `port: 3001, strictPort: true` |
| `plugins/warehouse/index.html` | Template: SDK + plugin-ui.css loading from host |
| `plugins/warehouse/manifest.json` | Template: `menu.main` + `product.detail.tabs` registration |
| `plugins/box-size/src/domain.ts` | Pattern for simple domain types without SDK entity deps |
| `plugins/box-size/src/pages/ProductBoxTab.tsx` | Minimal product tab pattern |
| `plugins/CLAUDE.md` | Authoritative plugin development guide |

### New Files to Create

| File | Purpose |
|------|---------|
| `plugins/courier/index.html` | Entry HTML: loads SDK + plugin-ui.css |
| `plugins/courier/manifest.json` | Plugin identity + `menu.main` + `product.detail.tabs` extension points |
| `plugins/courier/package.json` | Dependencies: react, react-dom, react-router-dom, typescript, vite |
| `plugins/courier/tsconfig.json` | TypeScript config (copy from warehouse) |
| `plugins/courier/vite.config.ts` | Vite config: `port: 3003, strictPort: true` |
| `plugins/courier/src/main.tsx` | Router: `/` → `OrdersPage`, `/product-orders` → `ProductOrdersTab` |
| `plugins/courier/src/domain.ts` | `Order` interface + `toOrder()` mapper + `OrderStatus` + `DeliveryMethod` enums |
| `plugins/courier/src/pages/OrdersPage.tsx` | Full-page: global order list + status management |
| `plugins/courier/src/pages/ProductOrdersTab.tsx` | Product tab: orders for current product + add/edit order |

---

## Data Model

Orders are stored as **plugin custom objects** using `thisPlugin.objects`. No new DB migrations are needed.

```
objectType:  "order"
objectId:    <orderNumber>          ← natural key; upsert semantics work correctly
entityType:  "PRODUCT"
entityId:    <productId>
data: {
  orderNumber:    string
  status:         "pending" | "processing" | "shipped" | "delivered" | "cancelled"
  deliveryMethod: "parcel_locker" | "courier"
  lockerCode?:    string            ← present only when deliveryMethod = "parcel_locker"
  createdAt:      string            ← ISO timestamp
}
```

**Box size integration**: `deliveryMethod` is determined by the product's box size (read from the box-size plugin via `hostApp.getProduct()` or `thisPlugin.getData()` for the box-size plugin). Large boxes → courier only; small boxes → parcel locker available.

**SDK calls**:
```typescript
// Save/update an order
await sdk.thisPlugin.objects.save("order", orderNumber, data, {
  entityType: "PRODUCT",
  entityId: productId,
});

// List orders for a specific product (ProductOrdersTab)
await sdk.thisPlugin.objects.list("order", {
  entityType: "PRODUCT",
  entityId: productId,
});

// List all orders (OrdersPage)
await sdk.thisPlugin.objects.list("order");
```

---

## Extension Points

| Extension Point | Path | Description |
|-----------------|------|-------------|
| `menu.main` | `/` | Full-page order management dashboard: browse all orders across all products, filter by status/method |
| `product.detail.tabs` | `/product-orders` | Product-scoped tab: orders for this product, add new order, change status |

**Manifest registration** (after dev server is running):
```bash
curl -X PUT http://localhost:8080/api/plugins/courier/manifest \
  -H "Content-Type: application/json" -d @plugins/courier/manifest.json
```

---

## Integration Points

| Integration | Mechanism | Notes |
|-------------|-----------|-------|
| Backend storage | `thisPlugin.objects.save/list/get/delete` | plugin_objects table, scoped to pluginId="courier" |
| Product context | `sdk.thisPlugin.productId` | Only available in `product.detail.tabs` context; must guard with `if (!productId)` |
| Box size data | `sdk.hostApp.getProduct(productId)` then read `pluginData["box-size"]`, or `sdk.thisPlugin.getData(productId)` on the box-size plugin namespace | Cross-plugin data read to determine delivery method eligibility |
| Host UI | `plugin-ui.css` CSS classes loaded in `index.html` | `tc-plugin`, `tc-table`, `tc-primary-button`, `tc-select`, `tc-badge`, `tc-error` |
| Host routing | React Router route matching manifest paths | `/` for full page, `/product-orders` for tab |
| Dev port | `3003` | warehouse=3001, box-size=3002; courier=3003 |

---

## Coding Patterns to Follow

All patterns are verified from `plugins/warehouse/` and `plugins/CLAUDE.md`:

1. **SDK import**: `import { getSDK } from "../../sdk"` — always from shared `plugins/sdk.ts`
2. **Domain types**: `src/domain.ts` with `interface Order` + `toOrder(obj: PluginObject): Order` mapper
3. **Named exports only**: no `export default` in any file
4. **Component files**: PascalCase (`OrdersPage.tsx`), others camelCase (`domain.ts`)
5. **Loading/error state**: `const [loading, setLoading] = useState(true)` + `try/catch` + `finally(() => setLoading(false))`
6. **productId guard**: `const productId = sdk.thisPlugin.productId ?? ""; if (!productId) return <p>No product context.</p>;`
7. **Upsert key**: use `orderNumber` directly as `objectId` (natural key; save is idempotent)
8. **No Chakra UI**: plugin-ui.css classes only — `className="tc-primary-button"`, not `<Button colorScheme="blue">`
9. **Root wrapper**: `<div className="tc-plugin" style={{ padding: "1rem" }}>` on every page component
10. **Error display**: `{error && <p className="tc-error">{error}</p>}` after the root div open tag

---

## Complexity Assessment

**Overall: Low-to-moderate**

| Dimension | Assessment |
|-----------|------------|
| New files | ~9 files (all new; no existing files modified) |
| Backend changes | None |
| DB migrations | None |
| Novel patterns | None — exact same pattern as warehouse plugin |
| Cross-plugin dependency | Low risk — box-size data read via `hostApp.getProduct()`, graceful fallback if absent |
| State complexity | Moderate — order status transitions need clear UI affordance |
| Test coverage | Frontend plugin tests are out of scope (no existing plugin tests in test suite) |

---

## Risk Assessment

**Risk Level: Low**

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| SDK unavailable when running standalone (dev) | Medium | SDK provides fallback context; dev workflow requires host running on :8080 |
| Box-size plugin data absent for a product | Medium | Guard against `null` box dimensions; default to showing both delivery options |
| Order number collisions (two products same order number) | Low | `objectId` uniqueness is per `(pluginId, objectType, objectId)` — two products CAN have same order number; if truly global uniqueness needed, use `{productId}-{orderNumber}` as objectId |
| Port 3003 already in use | Low | `strictPort: true` in vite config surfaces this immediately |
| manifest not re-registered after extension point changes | Low | Document in README; host caches old manifest until re-PUT |

---

## Recommended Approach

1. **Scaffold from warehouse plugin**: copy `plugins/warehouse/` → `plugins/courier/`, update `package.json` name, `vite.config.ts` port (3001→3003), `index.html` title.
2. **Define domain types** in `src/domain.ts`: `OrderStatus` union type, `DeliveryMethod` union type, `Order` interface, `toOrder()` mapper.
3. **Create manifest** with `menu.main` (icon: `"package"` or `"truck"`, path: `/`, priority: 200) and `product.detail.tabs` (path: `/product-orders`, priority: 40).
4. **Implement `ProductOrdersTab`** first (simpler scope): reads `productId` from context, lists orders for that product, allows adding new order with order number + status + delivery method.
5. **Implement `OrdersPage`** second: lists all orders across all products, supports status updates inline.
6. **Box size integration**: in `ProductOrdersTab`, call `sdk.hostApp.getProduct(productId)` and check `pluginData["box-size"]` (length/width/height). If dimensions exceed threshold → disable parcel locker option; otherwise show both.
7. **Register manifest** once: `curl -X PUT http://localhost:8080/api/plugins/courier/manifest ...`
8. **Install deps**: `cd plugins/courier && npm install`

**No backend work. No DB work. No host frontend changes.**
