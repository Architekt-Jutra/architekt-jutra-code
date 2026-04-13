# Requirements: Courier Plugin

## Initial Description
Implement a new frontend plugin that will provide courier functionality: store order number, changing status of the order for given product, and how this product will be delivered — parcel locker or by delivery man — based on package box size.

## Decisions Made

### Architecture
- Standalone Vite+React+TypeScript app at `plugins/courier/` (port 3003)
- Mirrors box-size and warehouse plugin structure exactly
- SDK loaded from host at runtime: `<script src="http://localhost:8080/assets/plugin-sdk.js">`
- UI styled with `plugin-ui.css` CSS classes (`tc-plugin`, `tc-table`, `tc-input`, etc.)
- Two extension points: `menu.main` + `product.detail.tabs`

### Order statuses (simple 4-stage + returned)
- `pending` → `packed` → `shipped` → `delivered`
- `returned` reachable from `shipped` or `delivered`
- Total: 5 states

### Delivery method
- `parcel_locker` or `delivery_man`
- Auto-suggested based on box-size plugin data: if max(L, W, H) ≤ 60cm → suggest parcel locker
- User can always override the suggestion
- If box-size data is unavailable, default to delivery_man with no suggestion shown
- Conditional field: `lockerCode` input only visible when delivery method is `parcel_locker`

### Box-size integration
- Read via `hostApp.getProduct(productId)` → response has `pluginData["box-size"]` containing `{ length, width, height }` in cm
- box-size plugin's manifest registered under ID `box-size`

### Data storage
- `thisPlugin.objects.save("order", orderNumber, data, { entityType: "PRODUCT", entityId: productId })`
- `objectType = "order"`, `objectId = orderNumber` (order number is the natural key)
- Entity binding to PRODUCT for per-product filtering

### Duplicate order numbers
- Client-side validation: check if `orderNumber` already exists in loaded orders before save
- Show inline error: "Order [number] already exists for this product"

### Dashboard scope
- Both `menu.main` (all orders, cross-product) and `product.detail.tabs` (per-product only)

## Functional Requirements

### FR1: Plugin scaffold
- `plugins/courier/index.html` with SDK + CSS from host
- `plugins/courier/package.json` — same deps as box-size
- `plugins/courier/vite.config.ts` — port 3003
- `plugins/courier/tsconfig.json` — copy from box-size
- `plugins/courier/src/main.tsx` — BrowserRouter + Routes: `/orders` and `/product-delivery`
- `plugins/courier/manifest.json` — identity + 2 extension points

### FR2: Domain types (`src/domain.ts`)
- `OrderStatus` union type: `"pending" | "packed" | "shipped" | "delivered" | "returned"`
- `DeliveryMethod` union type: `"parcel_locker" | "delivery_man"`
- `CourierOrder` interface: `{ objectId, orderNumber, productId, status, deliveryMethod, lockerCode?, createdAt }`
- `toCourierOrder(obj: PluginObject): CourierOrder` mapper
- `NEXT_STATUS: Partial<Record<OrderStatus, OrderStatus>>` map for state machine transitions
- `STATUS_LABELS: Record<OrderStatus, string>` for display
- `suggestDeliveryMethod(pluginData: unknown): DeliveryMethod` — reads box-size data, returns suggestion
- `MAX_PARCEL_LOCKER_DIM = 60` constant (cm)

### FR3: ProductDeliveryTab (`src/pages/ProductDeliveryTab.tsx`)
- Runs in `product.detail.tabs` context at path `/product-delivery`
- On load: reads `productId` from `sdk.thisPlugin.productId`
- Fetches all orders for the product: `objects.list("order", { entityType: "PRODUCT", entityId: productId })`
- Fetches product to get box-size data: `hostApp.getProduct(productId)`
- Derives delivery method suggestion from box-size data
- Displays order list as table: order number | status | delivery method | actions
- "Add order" form (initially collapsed/empty, shown on button click or when no orders):
  - Order number input (required, text)
  - Delivery method select (pre-selected based on box-size suggestion; user can override)
  - Locker code input (visible only when `parcel_locker` selected)
  - Submit button; cancel button
  - Duplicate validation before submit
- Each order row: "Advance status" button (shows next status from NEXT_STATUS map, disabled at terminal states)
- Status displayed as colored text or badge (using tc-badge)
- Error and loading states

### FR4: CourierDashboard (`src/pages/CourierDashboard.tsx`)
- Runs in `menu.main` context at path `/orders`
- On load: fetches all orders `objects.list("order")` + fetches products `hostApp.getProducts()`
- Status filter dropdown (All / pending / packed / shipped / delivered / returned)
- Order table: order number | product name | status | delivery method | advance status action
- "Advance status" button same as tab
- Error and loading states
- Resolves product name by matching `productId` field in order data to product list

### FR5: Manifest
```json
{
  "name": "Courier",
  "version": "1.0.0",
  "url": "http://localhost:3003",
  "description": "Manage delivery orders: track order numbers, update statuses, configure delivery method",
  "extensionPoints": [
    { "type": "menu.main", "label": "Orders", "icon": "truck", "path": "/orders", "priority": 90 },
    { "type": "product.detail.tabs", "label": "Delivery", "path": "/product-delivery", "priority": 55 }
  ]
}
```

## Non-Functional Requirements

- No Chakra UI — use `plugin-ui.css` classes only
- Named exports only (no default exports)
- TypeScript strict mode — no `any`, import type for type-only imports
- SDK instance: `const sdk = getSDK()` at call-site in each handler/effect
- All SDK calls wrapped in try/catch with user-visible error display
- `void asyncFn()` pattern at all call sites in event handlers
- Loading state shown during initial data fetch
- Status changes are optimistic-update pattern: update UI then call SDK

## Scope Boundaries

### Included
- Complete plugin scaffold (all config files)
- `domain.ts` with full type system
- `ProductDeliveryTab.tsx` with order list + add form + status advance
- `CourierDashboard.tsx` with all-orders view + status filter + status advance
- `manifest.json`
- Tests are out of scope for this plugin (no existing plugin tests exist; test scaffolding is a separate task)

### Excluded
- No backend changes
- No host frontend changes
- No database migrations
- No test files (follow-up task)
- No editing of existing orders (create + status advance only)
- No deletion of orders
- No parcel locker address lookup / external courier API integration
