# Implementation Plan: Courier Plugin

## Overview

Create a standalone Vite + React + TypeScript plugin at `plugins/courier/` (port 3003) that tracks delivery orders per product and provides an all-orders courier dashboard. All files are new — no existing files are modified. The implementation mirrors the structure of `plugins/warehouse/` and `plugins/box-size/` and integrates with the shared Plugin SDK at `plugins/sdk.ts`.

The plan is organized into five sequential task groups:
1. **Plugin Scaffold** — project skeleton, config files, dev server
2. **Domain Model** — types, constants, and pure functions in `src/domain.ts`
3. **ProductDeliveryTab** — per-product order management component
4. **CourierDashboard** — all-orders dashboard with status filter
5. **Build Verification** — TypeScript compilation and final checks

Tests are explicitly **out of scope** per the specification.

---

## Task Groups

---

### Group 1: Plugin Scaffold

**Purpose**: Create the complete project skeleton so `npm run dev` starts a working Vite dev server on port 3003 with no TypeScript errors. This is the foundation all other groups build on.

**Files**:
- `plugins/courier/package.json`
- `plugins/courier/tsconfig.json`
- `plugins/courier/vite.config.ts`
- `plugins/courier/index.html`
- `plugins/courier/manifest.json`
- `plugins/courier/src/main.tsx`

#### Steps

- [x] 1.1 — Create `plugins/courier/package.json` with name `"courier-plugin"`, ESM `"type": "module"`, dev/build/preview scripts, React 19 + react-router-dom 7 runtime deps, and Vite 8 + TypeScript 5.9 dev deps (no `lru-cache`) — `plugins/courier/package.json`
- [x] 1.2 — Create `plugins/courier/tsconfig.json` with `target: "ES2023"`, `jsx: "react-jsx"`, `strict: true`, `noEmit: true`, `noUnusedLocals: true`, `noUnusedParameters: true`, `erasableSyntaxOnly: true`, `moduleResolution: "bundler"`, `allowImportingTsExtensions: true`, `verbatimModuleSyntax: true`, `include: ["src"]` — `plugins/courier/tsconfig.json`
- [x] 1.3 — Create `plugins/courier/vite.config.ts` with `@vitejs/plugin-react` plugin and `server: { port: 3003, strictPort: true }` — `plugins/courier/vite.config.ts`
- [x] 1.4 — Create `plugins/courier/index.html` loading the Plugin SDK script (`http://localhost:8080/assets/plugin-sdk.js`) and UI stylesheet (`http://localhost:8080/assets/plugin-ui.css`) in `<head>`, with `<div id="root">` and `<script type="module" src="/src/main.tsx">` in `<body>` — `plugins/courier/index.html`
- [x] 1.5 — Create `plugins/courier/manifest.json` with name `"Courier"`, url `"http://localhost:3003"`, and two extension points: `menu.main` (label `"Courier"`, icon `"truck"`, path `"/"`, priority `110`) and `product.detail.tabs` (label `"Delivery"`, path `"/product-delivery"`, priority `55`) — `plugins/courier/manifest.json`
- [x] 1.6 — Create `plugins/courier/src/main.tsx` with `BrowserRouter` + `Routes`: `path="/"` → `<CourierDashboard />` and `path="/product-delivery"` → `<ProductDeliveryTab />`. Use stub placeholder exports for both components (e.g., `export function CourierDashboard() { return <div>Dashboard</div>; }` inline or as temporary stubs in the pages directory) so the router compiles — `plugins/courier/src/main.tsx`
- [x] 1.7 — Create stub `plugins/courier/src/pages/CourierDashboard.tsx` exporting a named `CourierDashboard` function component returning `<div>CourierDashboard</div>` — `plugins/courier/src/pages/CourierDashboard.tsx`
- [x] 1.8 — Create stub `plugins/courier/src/pages/ProductDeliveryTab.tsx` exporting a named `ProductDeliveryTab` function component returning `<div>ProductDeliveryTab</div>` — `plugins/courier/src/pages/ProductDeliveryTab.tsx`
- [x] 1.9 — Run `npm install` in `plugins/courier/` to generate `node_modules/` and `package-lock.json`

**Verification**: `cd plugins/courier && npm run dev` — dev server starts on port 3003, browser opens the stub dashboard with no console errors.

---

### Group 2: Domain Model

**Purpose**: Implement all domain types, constants, and pure functions in `src/domain.ts` exactly as specified. This module has no side effects and no SDK calls — it is pure TypeScript that both page components will import.

**Files**:
- `plugins/courier/src/domain.ts`

#### Steps

- [x] 2.1 — Add the `OrderStatus` union type (`"pending" | "packed" | "shipped" | "delivered" | "returned"`) and the `ORDER_STATUSES` array constant in the same order — `plugins/courier/src/domain.ts`
- [x] 2.2 — Implement the `nextStatus(current: OrderStatus): OrderStatus | null` pure function using the `["pending", "packed", "shipped", "delivered"]` flow array; return `null` for terminal states (`delivered`) and for `"returned"` (not in the flow array, `indexOf` returns `-1`) — `plugins/courier/src/domain.ts`
- [x] 2.3 — Add the `DeliveryMethod` union type (`"parcel_locker" | "delivery_man"`), the `DELIVERY_METHODS` array constant, and the `DELIVERY_METHOD_LABELS` record — `plugins/courier/src/domain.ts`
- [x] 2.4 — Implement `suggestDeliveryMethod(boxData: { length: number; width: number; height: number } | null): DeliveryMethod | null` — returns `null` when `boxData` is null; otherwise returns `"parcel_locker"` when `Math.max(length, width, height) <= 60`, else `"delivery_man"` — `plugins/courier/src/domain.ts`
- [x] 2.5 — Define the `Order` interface with fields: `objectId: string`, `orderNumber: string`, `status: OrderStatus`, `deliveryMethod: DeliveryMethod`, `lockerCode: string` (always present, empty string when N/A), `productId: string` — `plugins/courier/src/domain.ts`
- [x] 2.6 — Implement `toOrder(obj: PluginObject): Order` mapper, importing `PluginObject` from `"../../sdk"`. Cast `obj.data` fields with explicit `as` casts; use `?? ""` for the optional `lockerCode` field — `plugins/courier/src/domain.ts`
- [x] 2.7 — Add the `STATUS_BADGE_CLASS` record (`Record<OrderStatus, string>`): `pending` and `packed` → `"tc-badge"`, `shipped` and `delivered` → `"tc-badge tc-badge--success"`, `returned` → `"tc-badge tc-badge--danger"` — `plugins/courier/src/domain.ts`
- [x] 2.8 — Add the `STATUS_LABELS` record (`Record<OrderStatus, string>`) with human-readable labels: `Pending`, `Packed`, `Shipped`, `Delivered`, `Returned` — `plugins/courier/src/domain.ts`

**Verification**: `npm run build` (or `tsc --noEmit`) in `plugins/courier/` with the stub page components still in place — TypeScript compiles `src/domain.ts` with no errors.

---

### Group 3: ProductDeliveryTab Component

**Purpose**: Replace the stub `ProductDeliveryTab.tsx` with the full per-product order management component. This component reads `productId` from the SDK context, loads orders and box-size suggestion in parallel, renders the add-order form with conditional locker code field, and renders the orders table with advance/return/delete actions.

**Files**:
- `plugins/courier/src/pages/ProductDeliveryTab.tsx`

#### Steps

- [x] 3.1 — Add the import block: `useState`, `useEffect` from React; `getSDK` from `"../../../sdk"`; all required names from `"../domain"` (`Order`, `DeliveryMethod`, `OrderStatus`, `toOrder`, `nextStatus`, `suggestDeliveryMethod`, `DELIVERY_METHODS`, `DELIVERY_METHOD_LABELS`, `STATUS_BADGE_CLASS`, `STATUS_LABELS`) — `plugins/courier/src/pages/ProductDeliveryTab.tsx`
- [x] 3.2 — Declare the component function body opening: call `getSDK()` once at the top level (not inside `useEffect`); extract `productId` from `sdk.thisPlugin.productId ?? ""`; declare all state variables (`orders`, `suggestedMethod`, `loading`, `error`, `formOrderNumber`, `formDeliveryMethod`, `formLockerCode`, `formError`, `saving`) with their correct types and initial values — `plugins/courier/src/pages/ProductDeliveryTab.tsx`
- [x] 3.3 — Implement the `useEffect` (dependency array `[productId]`) with the early-return guard (`if (!productId) { setLoading(false); return; }`), the inner `async function load()`, and `void load()` call. Inside `load()`: use `Promise.all` to fetch both orders (`sdk.thisPlugin.objects.list("order", {...})`) and product data (`sdk.hostApp.getProduct(productId)`) in parallel; call `setOrders(orderObjects.map(toOrder))`; extract `boxData` from `product.pluginData?.["box-size"] ?? null`; compute `suggested = suggestDeliveryMethod(boxData)`; call `setSuggestedMethod(suggested)` and `setFormDeliveryMethod(suggested ?? "parcel_locker")` using the local variable (not state); wrap in `try/catch/finally` with `setError(...)` and `setLoading(false)` — `plugins/courier/src/pages/ProductDeliveryTab.tsx`
- [x] 3.4 — Implement `handleAddOrder()`: trim `formOrderNumber`; validate non-empty with `setFormError`; validate uniqueness case-insensitively against `orders` state; if valid, call `setSaving(true)`, build `data` record (including `lockerCode` only when `formDeliveryMethod === "parcel_locker"`), call `sdk.thisPlugin.objects.save(...)`, reset form fields (`setFormOrderNumber("")`, `setFormLockerCode("")`), reload orders list, set in `try/catch/finally` — `plugins/courier/src/pages/ProductDeliveryTab.tsx`
- [x] 3.5 — Implement `handleAdvanceStatus(order: Order)`: compute `next = nextStatus(order.status)`; return early if `null`; build `data` record preserving all order fields with updated `status`; include `lockerCode` only when `order.deliveryMethod === "parcel_locker"`; call `sdk.thisPlugin.objects.save(...)`; reload orders; wrap in `try/catch` with `setError(...)` — `plugins/courier/src/pages/ProductDeliveryTab.tsx`
- [x] 3.6 — Implement `handleMarkReturned(order: Order)`: guard `if (order.status === "returned" || order.status === "delivered") return`; build `data` record with `status: "returned"`; include `lockerCode` only when `parcel_locker`; call `sdk.thisPlugin.objects.save(...)`; reload orders; wrap in `try/catch` — `plugins/courier/src/pages/ProductDeliveryTab.tsx`
- [x] 3.7 — Implement `handleDeleteOrder(order: Order)`: call `sdk.thisPlugin.objects.delete("order", order.objectId)`; optimistically update state with `setOrders(prev => prev.filter(o => o.objectId !== order.objectId))`; wrap in `try/catch` with `setError(...)` — `plugins/courier/src/pages/ProductDeliveryTab.tsx`
- [x] 3.8 — Implement the render: add early-return guards for `!productId` and `loading`; then return the full JSX with `tc-plugin` wrapper containing: heading, global error paragraph, suggestion hint (conditional on `suggestedMethod`), `tc-section` add-order form (order number input, delivery method select with `DELIVERY_METHODS.map(...)`, conditional locker code input, "Add Order" button with `disabled={saving}`), form error paragraph, and the orders table (empty-state paragraph or `tc-table` with `thead`/`tbody`, action column with advance/return/delete buttons using `tc-ghost-button` and `tc-ghost-button--danger` classes) — `plugins/courier/src/pages/ProductDeliveryTab.tsx`

**Verification**: `npm run build` (or `tsc --noEmit`) in `plugins/courier/` — no TypeScript errors in `ProductDeliveryTab.tsx`.

---

### Group 4: CourierDashboard Component

**Purpose**: Replace the stub `CourierDashboard.tsx` with the full all-orders dashboard. This component loads all orders (no entity filter) and all products in parallel, provides a status filter select, and renders an orders table with advance and delete actions per row. Product names are resolved from the products list via a `Map`.

**Files**:
- `plugins/courier/src/pages/CourierDashboard.tsx`

#### Steps

- [x] 4.1 — Add the import block: `useState`, `useEffect` from React; `getSDK` from `"../../../sdk"`; all required names from `"../domain"` (`Order`, `OrderStatus`, `toOrder`, `nextStatus`, `ORDER_STATUSES`, `DELIVERY_METHOD_LABELS`, `STATUS_BADGE_CLASS`, `STATUS_LABELS`) — `plugins/courier/src/pages/CourierDashboard.tsx`
- [x] 4.2 — Declare the component function body opening: call `getSDK()` once at the top level; declare state variables: `orders: Order[]`, `products: { id: string; name: string; sku: string }[]`, `loading: boolean` (true), `error: string | null`, `statusFilter: OrderStatus | "all"` (initial `"all"`) — `plugins/courier/src/pages/CourierDashboard.tsx`
- [x] 4.3 — Implement the `useEffect` (dependency array `[]` — once on mount): `async function load()` using `Promise.all` to fetch `sdk.thisPlugin.objects.list("order")` (no entity filter) and `sdk.hostApp.getProducts()` in parallel; `setOrders(orderObjects.map(toOrder))`; cast products result as `{ id: string; name: string; sku: string }[]` and call `setProducts(...)`; wrap in `try/catch/finally` with `setError(...)` and `setLoading(false)` — `plugins/courier/src/pages/CourierDashboard.tsx`
- [x] 4.4 — Implement `handleAdvanceStatus(order: Order)`: same pattern as ProductDeliveryTab but reloads the full order list (`sdk.thisPlugin.objects.list("order")` — no entity filter) and uses `order.productId` for the entity binding in the save call — `plugins/courier/src/pages/CourierDashboard.tsx`
- [x] 4.5 — Implement `handleDeleteOrder(order: Order)`: call `sdk.thisPlugin.objects.delete("order", order.objectId)`; optimistically update state with `setOrders(prev => prev.filter(o => o.objectId !== order.objectId))`; wrap in `try/catch` with `setError(...)` — `plugins/courier/src/pages/CourierDashboard.tsx`
- [x] 4.6 — Add derived/computed values inline in the render function body (before the return): `const filteredOrders = statusFilter === "all" ? orders : orders.filter(o => o.status === statusFilter)`; `const productMap = new Map(products.map(p => [p.id, p]))` — `plugins/courier/src/pages/CourierDashboard.tsx`
- [x] 4.7 — Implement the render: add early-return guard for `loading`; return the full JSX with `tc-plugin` wrapper containing: `<h1>Courier Dashboard</h1>`, global error paragraph, filter row (`tc-flex`) with status select (option `"all"` + `ORDER_STATUSES.map(...)`) and order count label (`{filteredOrders.length} order{...}`), and the filtered orders table (empty-state paragraph or `tc-table` with 6 columns: Order #, Product, Status, Method, Locker Code, actions). In each row resolve product from `productMap.get(order.productId)` and display `"${name} (${sku})"` or fall back to `order.productId`. Action column: advance button (conditional on `nextStatus(order.status)`) and delete button (`tc-ghost-button--danger`) — `plugins/courier/src/pages/CourierDashboard.tsx`

**Verification**: `npm run build` (or `tsc --noEmit`) in `plugins/courier/` — no TypeScript errors in `CourierDashboard.tsx`.

---

### Group 5: Build Verification and Integration

**Purpose**: Confirm the entire plugin compiles cleanly, the production bundle can be built, and document the one-time manual registration step to connect the plugin to the running host.

**Files**: No new files created — this group only runs commands and verifies output.

#### Steps

- [x] 5.1 — Run `npm run build` in `plugins/courier/` (`tsc -b && vite build`) — verify TypeScript compilation exits with code 0 and the `dist/` directory is created
- [x] 5.2 — Check the TypeScript compiler output: confirm zero errors and zero warnings for unused locals/parameters (enforced by `noUnusedLocals: true` and `noUnusedParameters: true` in tsconfig)
- [x] 5.3 — Confirm `dist/index.html` and at least one `.js` bundle are present in `plugins/courier/dist/`
- [ ] 5.4 — Start the dev server (`npm run dev` in `plugins/courier/`) and verify it binds to port 3003 with no "address already in use" or module-resolution errors in the terminal
- [ ] 5.5 — *(Manual — requires running host)* Register the plugin manifest once: `curl -X PUT http://localhost:8080/api/plugins/courier/manifest -H "Content-Type: application/json" -d @manifest.json` — expect a 2xx response. This step is only needed once; re-registration is required if extension point paths or names change.

**Verification**: `npm run build` in `plugins/courier/` exits cleanly. `npm run dev` starts the dev server on port 3003 without errors.

---

## Standards Compliance

The following standards from `.maister/docs/INDEX.md` apply to this implementation:

### Global Standards

| Standard | Applies To | Key Guidelines |
|---|---|---|
| **Error Handling** (`standards/global/error-handling.md`) | All SDK calls in both page components | All `async` SDK calls wrapped in `try/catch`; user-visible `tc-error` messages; never swallow errors silently. Form errors displayed inline near the form (not as global error), SDK errors displayed as global `tc-error`. |
| **Validation** (`standards/global/validation.md`) | `handleAddOrder` in ProductDeliveryTab | Fail-fast: validate non-empty and uniqueness before any SDK call; specific error message including the duplicate order number; client-side feedback immediately. |
| **Coding Style** (`standards/global/coding-style.md`) | All files | Descriptive function/variable names; focused functions (one handler per action); consistent indentation; no magic numbers (the `60` cm threshold is documented in the spec and `domain.ts` JSDoc). |
| **Minimal Implementation** (`standards/global/minimal-implementation.md`) | All files | Build only what the spec requires; no speculative abstractions; `lru-cache` explicitly excluded; no `vite-env.d.ts` (not needed); no custom config store for the threshold. |
| **Commenting** (`standards/global/commenting.md`) | `domain.ts` | JSDoc on `nextStatus` and `suggestDeliveryMethod` (non-obvious logic); inline comment on stale-closure avoidance in `useEffect` (`suggested` local variable vs `suggestedMethod` state). |
| **Development Conventions** (`standards/global/conventions.md`) | Project scaffold | Predictable file structure matching the `plugins/warehouse/` reference; no secrets or hardcoded URLs beyond `localhost` dev URLs (same pattern as other plugins). |

### Frontend Standards

| Standard | Applies To | Key Guidelines |
|---|---|---|
| **Components** (`standards/frontend/components.md`) | `ProductDeliveryTab`, `CourierDashboard` | Single responsibility per component (tab vs dashboard); no business logic in render — handlers are separate named functions; named exports (not default). |
| **CSS** (`standards/frontend/css.md`) | All JSX | Use host's shared CSS classes (`tc-plugin`, `tc-table`, `tc-input`, `tc-select`, `tc-primary-button`, `tc-ghost-button`, `tc-ghost-button--danger`, `tc-badge`, `tc-badge--success`, `tc-badge--danger`, `tc-error`, `tc-section`, `tc-flex`) loaded from `plugin-ui.css`; inline `style` only for layout-specific concerns not covered by shared classes (padding, max-width, width on inputs). |
| **Accessibility** (`standards/frontend/accessibility.md`) | Form inputs | All form inputs are wrapped in `<label>` elements with descriptive text (per spec render structure); buttons have clear, descriptive text labels. |

### Plugin-Specific Conventions (from `plugins/CLAUDE.md`)

- Import `getSDK` and `PluginObject` from `"../../../sdk"` (the shared `plugins/sdk.ts`) — never from a plugin-local copy.
- Call `getSDK()` once at the component function body level, not inside `useEffect`.
- `sdk.thisPlugin.productId` for reading product context in `ProductDeliveryTab`.
- `sdk.thisPlugin.objects.save(type, id, data, entityBinding)` for upsert; `delete` for removal.
- Always cast `sdk.hostApp.getProduct(...)` and `sdk.hostApp.getProducts()` results with explicit TypeScript `as` casts.
- Use `tc-plugin` wrapper on the root div of each component.

### Out of Scope

- **Backend testing standards** (`standards/testing/backend-testing.md`) — no backend changes.
- **Frontend testing standards** (`standards/testing/frontend-testing.md`) — tests explicitly deferred per spec section 2.
- **API Design, jOOQ, JPA, Migrations** — no backend changes.
