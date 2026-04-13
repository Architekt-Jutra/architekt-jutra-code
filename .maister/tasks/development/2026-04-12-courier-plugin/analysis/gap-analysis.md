# Gap Analysis: Courier Plugin

**Task**: Implement a frontend courier plugin for the aj platform  
**Date**: 2026-04-12  
**Risk Level**: medium

---

## Current State vs Desired State

### Gap 1: Backend — Lombok annotations (previously flagged as blocker)

| | Current | Desired |
|---|---|---|
| `PluginDescriptor.java` | Has `@Getter @Setter @NoArgsConstructor` ✅ | Same — no change needed |
| `PluginObject.java` | Has `@Getter @Setter @NoArgsConstructor` ✅ | Same — no change needed |

**Finding**: Both files already carry all three Lombok annotations (`PluginDescriptor.java:25-27`, `PluginObject.java:26-28`). IDE/LSP shows spurious "method undefined" errors because the language server does not process Lombok annotations, but `mvnw.cmd compile` produces `BUILD SUCCESS` — the annotations work correctly at compile time. **No backend change is required. This is not a blocker.**

---

### Gap 2: No `plugins/courier/` directory

**Current**: Only `plugins/warehouse/` (port 3001) and `plugins/box-size/` (port 3002) exist.  
**Desired**: A complete `plugins/courier/` standalone Vite+React TypeScript app at port 3003.

Files to create (mirroring the warehouse/box-size structure):
- `plugins/courier/index.html`
- `plugins/courier/manifest.json`
- `plugins/courier/package.json`
- `plugins/courier/tsconfig.json`
- `plugins/courier/vite.config.ts` (port 3003)
- `plugins/courier/src/main.tsx` (routes: `/orders`, `/product-delivery`)
- `plugins/courier/src/domain.ts` (Order, DeliveryMethod, OrderStatus types + mappers)
- `plugins/courier/src/pages/CourierDashboard.tsx`
- `plugins/courier/src/pages/ProductDeliveryTab.tsx`

---

### Gap 3: No courier domain model

**Current**: No order/delivery domain types exist anywhere.  
**Desired**: `src/domain.ts` defining:

```typescript
type OrderStatus = "pending" | "packed" | "shipped" | "delivered" | "returned";
type DeliveryMethod = "parcel_locker" | "delivery_man";

interface Order {
  objectId: string;       // composite: `${productId}-${orderNumber}`
  productId: string;
  orderNumber: string;
  deliveryMethod: DeliveryMethod;
  lockerCode?: string;    // only when deliveryMethod === "parcel_locker"
  status: OrderStatus;
}
```

Storage: `thisPlugin.objects.save("order", objectId, data, { entityType: "PRODUCT", entityId: productId })`

---

### Gap 4: No ProductDeliveryTab component

**Current**: Nothing.  
**Desired**: `src/pages/ProductDeliveryTab.tsx` that:
- Reads `productId` from SDK context
- Lists all orders for this product (`objects.list("order", { entityType: "PRODUCT", entityId: productId })`)
- Shows add-order form: order number input, delivery method select (auto-suggested), locker code input (conditional)
- Auto-suggestion logic: reads box-size data via `hostApp.getProduct(productId)` → `product.pluginData["box-size"]`, compares max dimension against a threshold to suggest method
- Status change: each order row has a "Next status" button cycling through the state machine

**Status state machine**:
```
pending → packed → shipped → delivered
                            ↘ returned (from shipped or delivered)
```

---

### Gap 5: No CourierDashboard component

**Current**: Nothing.  
**Desired**: `src/pages/CourierDashboard.tsx` that:
- Lists all orders across all products (`objects.list("order")` — no entity filter)
- Shows product name alongside each order (resolve via `hostApp.getProducts()`)
- Status filter (All / pending / packed / shipped / delivered / returned)
- Status change buttons (same state machine as the tab)

---

### Gap 6: No manifest

**Current**: Nothing.  
**Desired**: `plugins/courier/manifest.json`:

```json
{
  "name": "Courier",
  "version": "1.0.0",
  "url": "http://localhost:3003",
  "description": "Manage delivery orders and courier logistics",
  "extensionPoints": [
    { "type": "menu.main", "label": "Orders", "icon": "truck", "path": "/orders", "priority": 90 },
    { "type": "product.detail.tabs", "label": "Delivery", "path": "/product-delivery", "priority": 55 }
  ]
}
```

---

### Gap 7: No frontend tests

**Current**: No tests for the courier plugin (none of the existing plugins have tests either — this is a greenfield project).  
**Desired**: Vitest tests for:
- `CourierDashboard`: renders order list, status filter, status update
- `ProductDeliveryTab`: renders order form, auto-suggestion, status change

Tests follow the Vitest pattern used in the host frontend (`src/main/frontend/src/test/`), using `vi.mock()` to mock the SDK.

---

## Integration Point: Box-Size Plugin Data

The auto-suggestion feature reads box-size data from the host product API. The box-size plugin stores data under its own namespace in the product's `pluginData` JSON column. Access pattern:

```typescript
// Via hostApp.getProduct()
const product = await sdk.hostApp.getProduct(productId);
const boxData = (product as any).pluginData?.["box-size"];
// boxData shape: { length: number, width: number, height: number } | null
```

The box-size `pluginId` (the manifest registration key) must be confirmed. Based on the existing `manifest.json` in `plugins/box-size/`, the plugin URL is `http://localhost:3002`, but the registration key is whatever `pluginId` was used in the `PUT /api/plugins/{id}/manifest` curl call. Conventionally, plugins use their directory name as the ID (e.g., `box-size`).

**Delivery method threshold**: A box is "parcel locker eligible" when all dimensions fit within typical locker constraints. A reasonable default: max(length, width, height) ≤ 60cm. This is a product decision — using a hardcoded threshold is the simplest valid approach.

---

## What Does NOT Need to Change

- **No backend code changes** — `PluginDescriptor.java` and `PluginObject.java` already have correct Lombok annotations. Plugin data APIs are fully operational.
- **No database migrations** — `plugin_objects` table with entity binding already exists and supports the order storage pattern.
- **No SDK changes** — The existing SDK (`plugins/sdk.ts`) fully supports all required operations.
- **No host frontend changes** — Extension point registration is purely manifest-driven.
- **No changes to warehouse or box-size plugins**.

---

## Risk Assessment

**Risk Level: medium**

| Risk | Severity | Notes |
|---|---|---|
| Cross-plugin data read (box-size `pluginData` key) | Medium | Depends on how box-size plugin registered its `pluginId`. If the key isn't `"box-size"`, auto-suggestion silently falls back to no suggestion. |
| `objectId` uniqueness for orders | Low | Orders use a user-entered order number as part of the composite ID. If the same order number is reused for the same product, the save will be an upsert (overwrite). Need to decide: allow overwrite, or validate uniqueness in the form. |
| Status machine safety | Low | `returned` can be reached from multiple states — the UI must clearly expose which transitions are valid from each state. |
| No existing plugin tests to copy pattern from | Low | The host frontend tests in `src/main/frontend/src/test/` provide a usable pattern, but plugin-level test setup (mocking `window.PluginSDK`) needs to be established from scratch. |

---

## Decisions Needed

### Critical
*(None — all significant ambiguities were resolved in clarifications.)*

### Important

**Decision 1: Box-size dimension threshold for delivery method suggestion**

The auto-suggest logic needs a numeric threshold. Options:
- **A) Hardcode 60cm** — max(L,W,H) ≤ 60cm → suggest parcel locker. Simple, no config needed.
- **B) Make it configurable** — store threshold as plugin config object, user sets it. Adds complexity.

Recommendation: Option A (hardcode 60cm). The threshold can always be made configurable later if needed. The core requirement is "suggest based on box size", not "make threshold configurable".

**Decision 2: Order number uniqueness enforcement**

If a user enters an order number that already exists for the same product:
- **A) Upsert (silent overwrite)** — consistent with how the SDK `objects.save` works. Simple.
- **B) Validate and reject** — load existing orders before save, check for duplicate `orderNumber`. More user-friendly.

Recommendation: Option B (validate). Silently overwriting an order is data-destructive and confusing to users.

---

## Summary of Changes

| Area | Type | Scope |
|---|---|---|
| `plugins/courier/` | Create | ~9 new files (full plugin scaffold) |
| `plugins/courier/src/domain.ts` | Create | Order, DeliveryMethod, OrderStatus types |
| `plugins/courier/src/pages/ProductDeliveryTab.tsx` | Create | Per-product orders + add form + status |
| `plugins/courier/src/pages/CourierDashboard.tsx` | Create | All-orders dashboard with filter |
| `plugins/courier/src/pages/*.test.tsx` | Create | Vitest tests for both components |
| `plugins/courier/manifest.json` | Create | 2 extension points |
| Backend (`PluginDescriptor.java`, `PluginObject.java`) | **No change needed** | Already correct |

**Total new files**: ~9 plugin files + 2 test files = ~11 files  
**Modified existing files**: 0
