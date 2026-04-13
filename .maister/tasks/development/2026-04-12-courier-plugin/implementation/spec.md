# Courier Plugin — Implementation Specification

## 1. Overview

The **courier** plugin is a standalone Vite + React + TypeScript micro-frontend that runs on port **3003**. It integrates with the `aj` platform via the Plugin SDK (sandboxed iframes, postMessage RPC).

### Responsibilities

- Track **orders** per product: each order has a number, status, and delivery method.
- Drive orders through the lifecycle: `pending → packed → shipped → delivered` (plus terminal `returned`).
- Auto-suggest delivery method based on box dimensions from the `box-size` plugin (threshold: `max(L, W, H) ≤ 60 cm` → `parcel_locker`; otherwise `delivery_man`).
- Show a `lockerCode` field **only** when delivery method is `parcel_locker`.
- Validate that order numbers are unique per product (client-side duplicate rejection).

### Extension Points

| Extension point | Path | Purpose |
|---|---|---|
| `product.detail.tabs` | `/product-delivery` | Per-product order management (add, advance, delete) |
| `menu.main` | `/` | Sidebar dashboard — all orders across all products |

### Data Storage Pattern

Orders are stored as **plugin objects** (type `"order"`) bound to a `PRODUCT` entity:

```
objectType : "order"
objectId   : crypto.randomUUID()   (stable ID, not the order number)
entityType : "PRODUCT"
entityId   : productId
data       : { orderNumber, status, deliveryMethod, lockerCode?, productId }
```

Order numbers are not used as objectIds because they are business identifiers that may contain special characters and are easier to validate for uniqueness when stored in the `data` blob.

---

## 2. File Structure

All files are **new** (no existing files to modify except the host registration command).

```
plugins/courier/
├── index.html
├── manifest.json
├── package.json
├── tsconfig.json
├── vite.config.ts
└── src/
    ├── main.tsx
    ├── domain.ts
    └── pages/
        ├── ProductDeliveryTab.tsx
        └── CourierDashboard.tsx
```

No `vite-env.d.ts` is required — the courier plugin does not use `import.meta.env`.

> **Vitest tests**: Frontend unit tests (`ProductDeliveryTab.test.tsx`, `CourierDashboard.test.tsx`) are **out of scope for this implementation**. The plugin has no existing test infrastructure and test setup (mocking `window.PluginSDK`) requires dedicated effort. Tests are deferred to a follow-up task.

---

## 3. Domain Types — `src/domain.ts`

```typescript
import type { PluginObject } from "../../sdk";

// ── Status ────────────────────────────────────────────────────────────────────

export type OrderStatus = "pending" | "packed" | "shipped" | "delivered" | "returned";

export const ORDER_STATUSES: OrderStatus[] = [
  "pending",
  "packed",
  "shipped",
  "delivered",
  "returned",
];

/**
 * Returns the next status in the linear flow, or null when already at a
 * terminal state (delivered or returned).
 *
 * Flow: pending → packed → shipped → delivered
 * returned is a terminal state reachable from any non-delivered status.
 */
export function nextStatus(current: OrderStatus): OrderStatus | null {
  const flow: OrderStatus[] = ["pending", "packed", "shipped", "delivered"];
  const idx = flow.indexOf(current);
  if (idx === -1 || idx === flow.length - 1) return null; // terminal or returned
  return flow[idx + 1];
}

// ── Delivery Method ───────────────────────────────────────────────────────────

export type DeliveryMethod = "parcel_locker" | "delivery_man";

export const DELIVERY_METHODS: DeliveryMethod[] = ["parcel_locker", "delivery_man"];

export const DELIVERY_METHOD_LABELS: Record<DeliveryMethod, string> = {
  parcel_locker: "Parcel Locker",
  delivery_man: "Delivery Man",
};

/**
 * Suggest delivery method based on box dimensions from the box-size plugin.
 * Rule: max(length, width, height) ≤ 60 cm → parcel_locker; otherwise delivery_man.
 * Returns null when no box-size data is available (caller should not pre-select).
 */
export function suggestDeliveryMethod(
  boxData: { length: number; width: number; height: number } | null
): DeliveryMethod | null {
  if (!boxData) return null;
  const maxDim = Math.max(boxData.length, boxData.width, boxData.height);
  return maxDim <= 60 ? "parcel_locker" : "delivery_man";
}

// ── Order ─────────────────────────────────────────────────────────────────────

export interface Order {
  /** Stable object ID (UUID). Not the business order number. */
  objectId: string;
  /** Human-readable order number entered by the user. Unique per product. */
  orderNumber: string;
  status: OrderStatus;
  deliveryMethod: DeliveryMethod;
  /** Present only when deliveryMethod === "parcel_locker". May be empty string. */
  lockerCode: string;
  /** The product this order belongs to. */
  productId: string;
}

export function toOrder(obj: PluginObject): Order {
  const d = obj.data;
  return {
    objectId: obj.objectId,
    orderNumber: d.orderNumber as string,
    status: d.status as OrderStatus,
    deliveryMethod: d.deliveryMethod as DeliveryMethod,
    lockerCode: (d.lockerCode as string | undefined) ?? "",
    productId: d.productId as string,
  };
}

/** Status badge classes — maps status to the appropriate tc-badge modifier. */
export const STATUS_BADGE_CLASS: Record<OrderStatus, string> = {
  pending: "tc-badge",
  packed: "tc-badge",
  shipped: "tc-badge tc-badge--success",
  delivered: "tc-badge tc-badge--success",
  returned: "tc-badge tc-badge--danger",
};

/** Human-readable status labels. */
export const STATUS_LABELS: Record<OrderStatus, string> = {
  pending: "Pending",
  packed: "Packed",
  shipped: "Shipped",
  delivered: "Delivered",
  returned: "Returned",
};
```

---

## 4. `manifest.json`

```json
{
  "name": "Courier",
  "version": "1.0.0",
  "url": "http://localhost:3003",
  "description": "Track product orders, manage delivery status and method",
  "extensionPoints": [
    {
      "type": "menu.main",
      "label": "Courier",
      "icon": "truck",
      "path": "/",
      "priority": 110
    },
    {
      "type": "product.detail.tabs",
      "label": "Delivery",
      "path": "/product-delivery",
      "priority": 55
    }
  ]
}
```

> **Note on gap analysis divergence**: The gap analysis draft manifest used `path: "/orders"` and `label: "Orders"`. The spec intentionally uses `path: "/"` and `label: "Courier"` — the dashboard is the plugin's root page and "Courier" better matches the plugin identity.

---

## 5. Scaffold Files

### `index.html`

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Courier Plugin</title>
    <script src="http://localhost:8080/assets/plugin-sdk.js"></script>
    <link rel="stylesheet" href="http://localhost:8080/assets/plugin-ui.css" />
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
```

### `package.json`

```json
{
  "name": "courier-plugin",
  "private": true,
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc -b && vite build",
    "preview": "vite preview"
  },
  "dependencies": {
    "react": "^19.2.4",
    "react-dom": "^19.2.4",
    "react-router-dom": "^7.13.2"
  },
  "devDependencies": {
    "@types/react": "^19.2.14",
    "@types/react-dom": "^19.2.3",
    "@vitejs/plugin-react": "^6.0.1",
    "typescript": "~5.9.3",
    "vite": "^8.0.1"
  }
}
```

Note: `lru-cache` is **not** included — it was a warehouse-plugin dependency and is not needed here.

### `tsconfig.json`

```json
{
  "compilerOptions": {
    "target": "ES2023",
    "useDefineForClassFields": true,
    "lib": ["ES2023", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "skipLibCheck": true,
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "verbatimModuleSyntax": true,
    "moduleDetection": "force",
    "noEmit": true,
    "jsx": "react-jsx",
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "erasableSyntaxOnly": true,
    "noFallthroughCasesInSwitch": true
  },
  "include": ["src"]
}
```

Identical to the warehouse plugin's `tsconfig.json`.

### `vite.config.ts`

```typescript
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  server: {
    port: 3003,
    strictPort: true,
  },
});
```

### `src/main.tsx`

```tsx
import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { BrowserRouter, Routes, Route } from "react-router-dom";
import { CourierDashboard } from "./pages/CourierDashboard";
import { ProductDeliveryTab } from "./pages/ProductDeliveryTab";

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<CourierDashboard />} />
        <Route path="/product-delivery" element={<ProductDeliveryTab />} />
      </Routes>
    </BrowserRouter>
  </StrictMode>,
);
```

---

## 6. `ProductDeliveryTab` — `src/pages/ProductDeliveryTab.tsx`

### Purpose

Renders inside the product detail tab iframe. Shows all orders for the current product, allows adding new orders, advancing status, and deleting orders.

### Imports

```typescript
import { useState, useEffect } from "react";
import { getSDK } from "../../../sdk";
import {
  type Order,
  type DeliveryMethod,
  type OrderStatus,
  toOrder,
  nextStatus,
  suggestDeliveryMethod,
  DELIVERY_METHODS,
  DELIVERY_METHOD_LABELS,
  STATUS_BADGE_CLASS,
  STATUS_LABELS,
} from "../domain";
```

### State Variables

```typescript
// SDK context
const sdk = getSDK();
const productId = sdk.thisPlugin.productId ?? "";

// Data
const [orders, setOrders] = useState<Order[]>([]);
const [suggestedMethod, setSuggestedMethod] = useState<DeliveryMethod | null>(null);

// Loading / error
const [loading, setLoading] = useState(true);
const [error, setError] = useState<string | null>(null);

// "Add order" form fields
const [formOrderNumber, setFormOrderNumber] = useState("");
const [formDeliveryMethod, setFormDeliveryMethod] = useState<DeliveryMethod>("parcel_locker");
const [formLockerCode, setFormLockerCode] = useState("");
const [formError, setFormError] = useState<string | null>(null);
const [saving, setSaving] = useState(false);
```

### `useEffect` — Load on mount

Triggered by `[productId]`. Guard: if `!productId` set `loading = false` and return early.

> **Note on `sdk` dependency**: `const sdk = getSDK()` is called once at the component function body level (outside `useEffect`). It is intentionally **not** included in the `useEffect` dependency array because `getSDK()` returns `window.PluginSDK`, which is a stable singleton injected by the host. Adding it to deps would be incorrect.

Inside the async load function (wrapped in `try/catch/finally`):

1. **Parallel fetch** using `Promise.all`:
   - `sdk.thisPlugin.objects.list("order", { entityType: "PRODUCT", entityId: productId })`  
     → map results with `toOrder()` → `setOrders(...)`
   - `sdk.hostApp.getProduct(productId)`  
     → cast result as `{ pluginData?: Record<string, unknown> }`  
     → extract `pluginData?.["box-size"]` as `{ length: number; width: number; height: number } | null`  
     → call `suggestDeliveryMethod(boxData)` → `setSuggestedMethod(...)`

2. After suggestion is resolved, call `setFormDeliveryMethod(suggested ?? "parcel_locker")` to pre-select the suggested method in the form. **Note**: use the local variable `suggested` (result of `suggestDeliveryMethod(boxData)`), NOT the state variable `suggestedMethod` (which would read the previous render's value and cause a stale-closure bug).

3. On catch: `setError(err instanceof Error ? err.message : "Failed to load delivery data")`.

4. Finally: `setLoading(false)`.

Full `useEffect` pattern:

```typescript
useEffect(() => {
  if (!productId) {
    setLoading(false);
    return;
  }
  async function load() {
    try {
      const [orderObjects, productRaw] = await Promise.all([
        sdk.thisPlugin.objects.list("order", { entityType: "PRODUCT", entityId: productId }),
        sdk.hostApp.getProduct(productId),
      ]);
      setOrders(orderObjects.map(toOrder));

      const product = productRaw as { pluginData?: Record<string, { length: number; width: number; height: number }> };
      const boxData = product.pluginData?.["box-size"] ?? null;
      const suggested = suggestDeliveryMethod(boxData);
      setSuggestedMethod(suggested);
      setFormDeliveryMethod(suggested ?? "parcel_locker");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to load delivery data");
    } finally {
      setLoading(false);
    }
  }
  void load();
}, [productId]);
```

### `handleAddOrder` — Form Submission

```typescript
async function handleAddOrder() {
  setFormError(null);

  // Validation
  const trimmed = formOrderNumber.trim();
  if (!trimmed) {
    setFormError("Order number is required.");
    return;
  }
  const duplicate = orders.some(
    (o) => o.orderNumber.toLowerCase() === trimmed.toLowerCase()
  );
  if (duplicate) {
    setFormError(`Order number "${trimmed}" already exists for this product.`);
    return;
  }

  setSaving(true);
  try {
    const id = crypto.randomUUID();
    const data: Record<string, unknown> = {
      orderNumber: trimmed,
      status: "pending" as OrderStatus,
      deliveryMethod: formDeliveryMethod,
      productId,
    };
    if (formDeliveryMethod === "parcel_locker") {
      data.lockerCode = formLockerCode.trim();
    }
    await sdk.thisPlugin.objects.save("order", id, data, {
      entityType: "PRODUCT",
      entityId: productId,
    });
    // Reset form
    setFormOrderNumber("");
    setFormLockerCode("");
    // setFormDeliveryMethod stays at current value (user preference)
    // Reload orders
    const updated = await sdk.thisPlugin.objects.list("order", {
      entityType: "PRODUCT",
      entityId: productId,
    });
    setOrders(updated.map(toOrder));
  } catch (err) {
    setFormError(err instanceof Error ? err.message : "Failed to add order.");
  } finally {
    setSaving(false);
  }
}
```

### `handleAdvanceStatus`

```typescript
async function handleAdvanceStatus(order: Order) {
  const next = nextStatus(order.status);
  if (!next) return; // already terminal
  setError(null);
  try {
    const data: Record<string, unknown> = {
      orderNumber: order.orderNumber,
      status: next,
      deliveryMethod: order.deliveryMethod,
      productId: order.productId,
    };
    if (order.deliveryMethod === "parcel_locker") {
      data.lockerCode = order.lockerCode;
    }
    await sdk.thisPlugin.objects.save("order", order.objectId, data, {
      entityType: "PRODUCT",
      entityId: productId,
    });
    const updated = await sdk.thisPlugin.objects.list("order", {
      entityType: "PRODUCT",
      entityId: productId,
    });
    setOrders(updated.map(toOrder));
  } catch (err) {
    setError(err instanceof Error ? err.message : "Failed to update order status.");
  }
}
```

### `handleMarkReturned`

```typescript
async function handleMarkReturned(order: Order) {
  if (order.status === "returned" || order.status === "delivered") return;
```

> **Note on `delivered → returned`**: The guard above intentionally blocks `delivered → returned`. A delivered order is terminal — returning a delivered package is V2 scope. The gap analysis diagram showing this transition was a draft; the spec (and AC-8) are the authoritative definition.

```typescript
  setError(null);
  try {
    const data: Record<string, unknown> = {
      orderNumber: order.orderNumber,
      status: "returned" as OrderStatus,
      deliveryMethod: order.deliveryMethod,
      productId: order.productId,
    };
    if (order.deliveryMethod === "parcel_locker") {
      data.lockerCode = order.lockerCode;
    }
    await sdk.thisPlugin.objects.save("order", order.objectId, data, {
      entityType: "PRODUCT",
      entityId: productId,
    });
    const updated = await sdk.thisPlugin.objects.list("order", {
      entityType: "PRODUCT",
      entityId: productId,
    });
    setOrders(updated.map(toOrder));
  } catch (err) {
    setError(err instanceof Error ? err.message : "Failed to mark order as returned.");
  }
}
```

### `handleDeleteOrder`

```typescript
async function handleDeleteOrder(order: Order) {
  setError(null);
  try {
    await sdk.thisPlugin.objects.delete("order", order.objectId);
    setOrders((prev) => prev.filter((o) => o.objectId !== order.objectId));
  } catch (err) {
    setError(err instanceof Error ? err.message : "Failed to delete order.");
  }
}
```

### Render Structure

```
<div className="tc-plugin" style={{ padding: "1.5rem" }}>
  <h3 style={{ margin: "0 0 1rem" }}>Delivery Orders</h3>

  {/* Global error */}
  {error && <p className="tc-error">{error}</p>}

  {/* Suggestion hint (only when suggestedMethod is not null) */}
  {suggestedMethod && (
    <p style={{ marginBottom: "1rem", fontSize: "13px", color: "#475569" }}>
      Suggested delivery method based on box size:
      <strong> {DELIVERY_METHOD_LABELS[suggestedMethod]}</strong>
    </p>
  )}

  {/* Add order form — always visible */}
  <section className="tc-section">
    <h4 style={{ margin: "0 0 0.75rem" }}>Add Order</h4>
    <div className="tc-flex" style={{ flexWrap: "wrap", alignItems: "flex-end", gap: "0.5rem" }}>
      <label style={{ display: "flex", flexDirection: "column", gap: "0.25rem", fontSize: "13px" }}>
        Order Number
        <input
          className="tc-input"
          type="text"
          placeholder="e.g. ORD-0042"
          value={formOrderNumber}
          onChange={(e) => setFormOrderNumber(e.target.value)}
          style={{ width: 140 }}
        />
      </label>
      <label style={{ display: "flex", flexDirection: "column", gap: "0.25rem", fontSize: "13px" }}>
        Delivery Method
        <select
          className="tc-select"
          value={formDeliveryMethod}
          onChange={(e) => {
            setFormDeliveryMethod(e.target.value as DeliveryMethod);
            setFormLockerCode("");
          }}
          style={{ width: 160 }}
        >
          {DELIVERY_METHODS.map((m) => (
            <option key={m} value={m}>{DELIVERY_METHOD_LABELS[m]}</option>
          ))}
        </select>
      </label>
      {formDeliveryMethod === "parcel_locker" && (
        <label style={{ display: "flex", flexDirection: "column", gap: "0.25rem", fontSize: "13px" }}>
          Locker Code
          <input
            className="tc-input"
            type="text"
            placeholder="e.g. ABC-123"
            value={formLockerCode}
            onChange={(e) => setFormLockerCode(e.target.value)}
            style={{ width: 120 }}
          />
        </label>
      )}
      <button
        className="tc-primary-button"
        onClick={() => void handleAddOrder()}
        disabled={saving}
        style={{ alignSelf: "flex-end" }}
      >
        {saving ? "Adding..." : "Add Order"}
      </button>
    </div>
    {formError && <p className="tc-error" style={{ marginTop: "0.5rem" }}>{formError}</p>}
  </section>

  {/* Orders table */}
  {orders.length === 0 ? (
    <p style={{ color: "#64748b", fontSize: "13px" }}>No orders yet for this product.</p>
  ) : (
    <table className="tc-table">
      <thead>
        <tr>
          <th>Order #</th>
          <th>Status</th>
          <th>Method</th>
          <th>Locker Code</th>
          <th></th>  {/* Actions column — no header text */}
        </tr>
      </thead>
      <tbody>
        {orders.map((order) => (
          <tr key={order.objectId}>
            <td>{order.orderNumber}</td>
            <td>
              <span className={STATUS_BADGE_CLASS[order.status]}>
                {STATUS_LABELS[order.status]}
              </span>
            </td>
            <td>{DELIVERY_METHOD_LABELS[order.deliveryMethod]}</td>
            <td>{order.deliveryMethod === "parcel_locker" ? order.lockerCode || "—" : "—"}</td>
            <td>
              <div className="tc-flex">
                {nextStatus(order.status) && (
                  <button
                    className="tc-ghost-button"
                    onClick={() => void handleAdvanceStatus(order)}
                  >
                    → {STATUS_LABELS[nextStatus(order.status)!]}
                  </button>
                )}
                {order.status !== "returned" && order.status !== "delivered" && (
                  <button
                    className="tc-ghost-button tc-ghost-button--danger"
                    onClick={() => void handleMarkReturned(order)}
                  >
                    Return
                  </button>
                )}
                <button
                  className="tc-ghost-button tc-ghost-button--danger"
                  onClick={() => void handleDeleteOrder(order)}
                >
                  Delete
                </button>
              </div>
            </td>
          </tr>
        ))}
      </tbody>
    </table>
  )}
</div>
```

**Early return guards (before main render):**

```typescript
if (!productId) return <div className="tc-plugin" style={{ padding: "1rem" }}>No product context.</div>;
if (loading)    return <div className="tc-plugin" style={{ padding: "1rem" }}>Loading...</div>;
```

---

## 7. `CourierDashboard` — `src/pages/CourierDashboard.tsx`

### Purpose

Renders in the sidebar iframe. Loads **all** orders across all products. Allows filtering by status. Allows advancing status and deleting orders inline.

### Imports

```typescript
import { useState, useEffect } from "react";
import { getSDK } from "../../../sdk";
import {
  type Order,
  type OrderStatus,
  toOrder,
  nextStatus,
  ORDER_STATUSES,
  DELIVERY_METHOD_LABELS,
  STATUS_BADGE_CLASS,
  STATUS_LABELS,
} from "../domain";
```

### State Variables

```typescript
const sdk = getSDK();

const [orders, setOrders] = useState<Order[]>([]);
const [products, setProducts] = useState<{ id: string; name: string; sku: string }[]>([]);
const [loading, setLoading] = useState(true);
const [error, setError] = useState<string | null>(null);
const [statusFilter, setStatusFilter] = useState<OrderStatus | "all">("all");
```

### `useEffect` — Load on mount

Triggered by `[]` (once on mount). Uses `Promise.all` for parallel loading, `finally` sets `loading = false`.

```typescript
useEffect(() => {
  async function load() {
    try {
      const [orderObjects, productsRaw] = await Promise.all([
        sdk.thisPlugin.objects.list("order"),
        sdk.hostApp.getProducts(),
      ]);
      setOrders(orderObjects.map(toOrder));
      const prods = productsRaw as { id: string; name: string; sku: string }[];
      setProducts(prods);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to load orders");
    } finally {
      setLoading(false);
    }
  }
  void load();
}, []);
```

### `handleAdvanceStatus`

Identical logic to `ProductDeliveryTab.handleAdvanceStatus` except it reloads the **full** order list (no product filter) and updates `orders` state directly:

```typescript
async function handleAdvanceStatus(order: Order) {
  const next = nextStatus(order.status);
  if (!next) return;
  setError(null);
  try {
    const data: Record<string, unknown> = {
      orderNumber: order.orderNumber,
      status: next,
      deliveryMethod: order.deliveryMethod,
      productId: order.productId,
    };
    if (order.deliveryMethod === "parcel_locker") {
      data.lockerCode = order.lockerCode;
    }
    await sdk.thisPlugin.objects.save("order", order.objectId, data, {
      entityType: "PRODUCT",
      entityId: order.productId,
    });
    const updated = await sdk.thisPlugin.objects.list("order");
    setOrders(updated.map(toOrder));
  } catch (err) {
    setError(err instanceof Error ? err.message : "Failed to update order status.");
  }
}
```

### `handleDeleteOrder`

```typescript
async function handleDeleteOrder(order: Order) {
  setError(null);
  try {
    await sdk.thisPlugin.objects.delete("order", order.objectId);
    setOrders((prev) => prev.filter((o) => o.objectId !== order.objectId));
  } catch (err) {
    setError(err instanceof Error ? err.message : "Failed to delete order.");
  }
}
```

### Filter Logic

Computed inline (no separate state needed — derived from `orders` + `statusFilter`):

```typescript
const filteredOrders = statusFilter === "all"
  ? orders
  : orders.filter((o) => o.status === statusFilter);
```

### Product Name Lookup

```typescript
const productMap = new Map(products.map((p) => [p.id, p]));

// In table cell:
const product = productMap.get(order.productId);
// Display: product?.name ?? order.productId
// Display SKU: product?.sku ?? ""
```

### Render Structure

```
<div className="tc-plugin" style={{ padding: "1rem", maxWidth: 900 }}>
  <h1>Courier Dashboard</h1>

  {error && <p className="tc-error">{error}</p>}

  {/* Filter row */}
  <div className="tc-flex" style={{ marginBottom: "1rem", alignItems: "center" }}>
    <label style={{ fontSize: "13px", fontWeight: 500 }}>
      Filter by status:{" "}
      <select
        className="tc-select"
        value={statusFilter}
        onChange={(e) => setStatusFilter(e.target.value as OrderStatus | "all")}
      >
        <option value="all">All</option>
        {ORDER_STATUSES.map((s) => (
          <option key={s} value={s}>{STATUS_LABELS[s]}</option>
        ))}
      </select>
    </label>
    <span style={{ fontSize: "13px", color: "#64748b" }}>
      {filteredOrders.length} order{filteredOrders.length !== 1 ? "s" : ""}
    </span>
  </div>

  {/* Orders table */}
  {filteredOrders.length === 0 ? (
    <p style={{ color: "#64748b" }}>No orders{statusFilter !== "all" ? ` with status "${STATUS_LABELS[statusFilter]}"` : ""} found.</p>
  ) : (
    <table className="tc-table">
      <thead>
        <tr>
          <th>Order #</th>
          <th>Product</th>
          <th>Status</th>
          <th>Method</th>
          <th>Locker Code</th>
          <th></th>  {/* Actions */}
        </tr>
      </thead>
      <tbody>
        {filteredOrders.map((order) => {
          const product = productMap.get(order.productId);
          return (
            <tr key={order.objectId}>
              <td>{order.orderNumber}</td>
              <td>
                {product ? `${product.name} (${product.sku})` : order.productId}
              </td>
              <td>
                <span className={STATUS_BADGE_CLASS[order.status]}>
                  {STATUS_LABELS[order.status]}
                </span>
              </td>
              <td>{DELIVERY_METHOD_LABELS[order.deliveryMethod]}</td>
              <td>{order.deliveryMethod === "parcel_locker" ? order.lockerCode || "—" : "—"}</td>
              <td>
                <div className="tc-flex">
                  {nextStatus(order.status) && (
                    <button
                      className="tc-ghost-button"
                      onClick={() => void handleAdvanceStatus(order)}
                    >
                      → {STATUS_LABELS[nextStatus(order.status)!]}
                    </button>
                  )}
                  <button
                    className="tc-ghost-button tc-ghost-button--danger"
                    onClick={() => void handleDeleteOrder(order)}
                  >
                    Delete
                  </button>
                </div>
              </td>
            </tr>
          );
        })}
      </tbody>
    </table>
  )}
</div>
```

**Early return guards:**

```typescript
if (loading) return <div className="tc-plugin" style={{ padding: "1rem" }}>Loading orders...</div>;
```

---

## 8. SDK Call Patterns

All SDK calls follow the plugin conventions — `const sdk = getSDK()` called once outside `useEffect`, results cast explicitly.

### List all orders for a product (ProductDeliveryTab)

```typescript
const orderObjects = await sdk.thisPlugin.objects.list("order", {
  entityType: "PRODUCT",
  entityId: productId,
});
const orders: Order[] = orderObjects.map(toOrder);
```

### List all orders (CourierDashboard)

```typescript
const orderObjects = await sdk.thisPlugin.objects.list("order");
const orders: Order[] = orderObjects.map(toOrder);
```

### Read product + box-size plugin data

```typescript
const productRaw = await sdk.hostApp.getProduct(productId);
const product = productRaw as {
  pluginData?: Record<string, { length: number; width: number; height: number }>;
};
const boxData = product.pluginData?.["box-size"] ?? null;
```

> **Assumption**: The box-size plugin was registered with ID `"box-size"` (matching its directory name, per platform convention). If the plugin was registered under a different ID, `boxData` will be `null` and auto-suggestion will silently be disabled — this is the correct fallback behavior.

### Save (create) a new order

```typescript
const id = crypto.randomUUID();
await sdk.thisPlugin.objects.save(
  "order",
  id,
  {
    orderNumber: trimmedOrderNumber,
    status: "pending",
    deliveryMethod: formDeliveryMethod,
    lockerCode: formDeliveryMethod === "parcel_locker" ? formLockerCode.trim() : undefined,
    productId,
  },
  { entityType: "PRODUCT", entityId: productId }
);
```

### Update order status (advance or return)

```typescript
await sdk.thisPlugin.objects.save(
  "order",
  order.objectId,
  {
    orderNumber: order.orderNumber,
    status: newStatus,
    deliveryMethod: order.deliveryMethod,
    lockerCode: order.deliveryMethod === "parcel_locker" ? order.lockerCode : undefined,
    productId: order.productId,
  },
  { entityType: "PRODUCT", entityId: order.productId }
);
```

### Delete an order

```typescript
await sdk.thisPlugin.objects.delete("order", order.objectId);
```

### Get all products (CourierDashboard product name lookup)

```typescript
const productsRaw = await sdk.hostApp.getProducts();
const products = productsRaw as { id: string; name: string; sku: string }[];
```

---

## 9. Acceptance Criteria

### AC-1: Plugin scaffold and registration

- [ ] Running `npm install && npm run dev` in `plugins/courier/` starts a dev server on port 3003 with no errors.
- [ ] `PUT http://localhost:8080/api/plugins/courier/manifest` with the manifest file succeeds (2xx response).
- [ ] "Courier" appears in the host sidebar navigation with a truck icon.
- [ ] "Delivery" tab appears on the product detail page.

### AC-2: Product Delivery Tab — loading

- [ ] Opening the Delivery tab for a product shows "Loading..." while fetching, then renders the form and table.
- [ ] When no orders exist, the table area shows the empty state message.

### AC-3: Add order — happy path

- [ ] Filling in an order number and clicking "Add Order" creates an order with status `pending`.
- [ ] The new order appears immediately in the table without a page reload.
- [ ] Form fields clear after successful submission (order number clears; delivery method stays).

### AC-4: Delivery method suggestion

- [ ] When the box-size plugin has set dimensions where `max(L,W,H) ≤ 60`, the form pre-selects "Parcel Locker" and shows a hint message.
- [ ] When `max(L,W,H) > 60`, the form pre-selects "Delivery Man" and shows a hint message.
- [ ] When no box-size data exists, no hint is shown and the form defaults to "Parcel Locker".

### AC-5: Locker Code field visibility

- [ ] The Locker Code input is visible only when "Parcel Locker" is selected as delivery method.
- [ ] Switching from "Parcel Locker" to "Delivery Man" hides the Locker Code field and clears its value.
- [ ] Locker Code is stored in the order object when delivery method is `parcel_locker`.
- [ ] Locker Code column shows "—" for orders with `delivery_man`.

### AC-6: Duplicate order number validation

- [ ] Submitting an order number identical to an existing one (case-insensitive) shows the error `Order number "X" already exists for this product.` and does **not** create a duplicate.
- [ ] The same order number may exist on **different** products (validation is per-product).

### AC-7: Status advancement

- [ ] Clicking "→ Packed" on a `pending` order changes its status to `packed`.
- [ ] Clicking "→ Shipped" on a `packed` order changes its status to `shipped`.
- [ ] Clicking "→ Delivered" on a `shipped` order changes its status to `delivered`.
- [ ] A `delivered` order shows no advance button (terminal state).
- [ ] A `returned` order shows no advance button (terminal state).

### AC-8: Return action

- [ ] The "Return" button is visible on orders with status `pending`, `packed`, or `shipped`.
- [ ] The "Return" button is NOT visible on `delivered` or `returned` orders.
- [ ] Clicking "Return" sets the order status to `returned` and the status badge shows the danger style.

### AC-9: Delete order

- [ ] Clicking "Delete" on an order removes it from the list immediately.
- [ ] The order is deleted from persistent storage (reloading the tab confirms deletion).

### AC-10: Status badge styling

- [ ] `pending` and `packed` show a neutral `tc-badge` (no modifier).
- [ ] `shipped` and `delivered` show `tc-badge tc-badge--success` (green).
- [ ] `returned` shows `tc-badge tc-badge--danger` (red).

### AC-11: Courier Dashboard — loading and display

- [ ] Navigating to the Courier sidebar page loads all orders across all products.
- [ ] Each row shows: order number, product name + SKU, status badge, delivery method, locker code (or "—").
- [ ] The count label ("N orders") updates when the filter changes.

### AC-12: Courier Dashboard — status filter

- [ ] The "All" option shows every order.
- [ ] Selecting "Pending" filters to only `pending` orders.
- [ ] When a filter matches zero orders, the empty state message mentions the filtered status name.

### AC-13: Courier Dashboard — advance and delete

- [ ] Advancing status from the dashboard persists correctly and reflects in the product tab on next load.
- [ ] Deleting from the dashboard removes the order from the list immediately.

### AC-14: Error handling

- [ ] SDK errors (e.g., network timeout) are caught and displayed via `tc-error` styled text; the UI does not crash.
- [ ] Form validation errors (empty order number, duplicate) display inline near the form, not as a global error.
