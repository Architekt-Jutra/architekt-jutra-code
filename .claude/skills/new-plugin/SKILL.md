---
name: new-plugin
description: Scaffold a new plugin for the aj host platform from a description. Use when the user wants to create, add, or scaffold a plugin, or asks for a new extension/tab/sidebar page/product filter on the platform. Creates the full plugin directory, wires routes to manifest extension points, registers the manifest with the running host, and starts the dev server.
---

# New Plugin

Scaffold a working plugin under `plugins/<plugin-id>/`, register it with the host, and get it rendering in the UI.

Read `plugins/CLAUDE.md` for the SDK contract and CSS classes before writing page components. Use `plugins/box-size/` as the structural template — it is the minimal working plugin.

## 1. Settle the inputs

Derive from the user's description, asking only when genuinely ambiguous:

- **plugin id** — kebab-case, must match `^[a-zA-Z0-9_-]+$`. Directory name and URL path segment.
- **display name** — human-readable, goes in `manifest.json` and the sidebar.
- **extension points** — which of the four the plugin needs. Map the request:
  - "page in the sidebar" / "section" → `menu.main` (needs an `icon`: kebab-case [Lucide](https://lucide.dev/icons/) name)
  - "tab on the product" → `product.detail.tabs`
  - "badge / small info under product details" → `product.detail.info` (keep the component ~60px tall)
  - "filter the product list by X" → `product.list.filters` (**no route and no component** — the host renders the control natively from `filterKey` + `filterType`)
- **storage** — per-product values → `thisPlugin.getData/setData`. A collection the plugin owns → `thisPlugin.objects` (bind to a product with `entityType: "PRODUCT"` when it should be server-side filterable).

## 2. Pick a free port

Ports are `strictPort: true` — a collision is a hard startup failure, not a fallback.

```bash
grep -rh "port:" plugins/*/vite.config.ts
lsof -nP -iTCP:<candidate> -sTCP:LISTEN
```

Take the next free port after the highest in use (3001 warehouse, 3002 box-size → 3003). The same port must appear in `vite.config.ts` **and** as `url` in `manifest.json`.

## 3. Create the files

```
plugins/<plugin-id>/
  index.html          # SDK script + plugin-ui.css in <head>
  manifest.json       # identity + extension points
  package.json        # name: "<plugin-id>-plugin"
  tsconfig.json       # copy from box-size unchanged
  vite.config.ts      # the chosen port, strictPort: true
  src/
    main.tsx          # one <Route> per manifest path
    domain.ts         # plugin types + mappers (omit if the plugin stores nothing)
    pages/            # one component per extension point path
```

Copy `index.html`, `tsconfig.json`, `package.json`, and `vite.config.ts` from `plugins/box-size/`, changing only the title, name, and port. Never copy `sdk.ts` into the plugin — it is shared at `plugins/sdk.ts`.

### Import paths — the common mistake

Relative depth differs by file location. `plugins/CLAUDE.md` documents `../../sdk`, which is correct **only from `src/`**:

```typescript
// src/domain.ts          → two levels up
import type { PluginObject } from "../../sdk";

// src/pages/AnyPage.tsx  → three levels up
import { getSDK } from "../../../sdk";
import { toThing } from "../domain";
```

Getting this wrong fails at `tsc -b`, not at runtime, so it survives a browser check.

### Routes must match the manifest

Every extension point with a `path` needs exactly one `<Route path="...">` in `main.tsx` with the identical string. `product.list.filters` entries have no `path` and get no route.

### Styling

Wrap each page root in `tc-plugin` and use the host classes — `tc-primary-button`, `tc-ghost-button`, `tc-input`, `tc-select`, `tc-table`, `tc-card`, `tc-badge tc-badge--success|--danger`, `tc-error`. Inline `style` is for layout only (padding, max-width). Do not restyle buttons, inputs, or tables.

### SDK calls

Every SDK call is a promise that rejects after a 10s timeout. Wrap in try/catch and surface the failure in the UI with `tc-error` — never swallow it.

## 4. Install and register

```bash
cd plugins/<plugin-id> && npm install
```

The host must be running (`./mvnw spring-boot:run`). Register the manifest:

```bash
curl -sS -X PUT http://localhost:8080/api/plugins/<plugin-id>/manifest \
  -H "Content-Type: application/json" -d @plugins/<plugin-id>/manifest.json
```

Confirm the response echoes the plugin with `"enabled": true`. If the host is not running, say so and stop before this step rather than silently skipping it — an unregistered plugin never appears in the UI.

**Re-register after any change to `manifest.json`.** The host stores a copy; editing the file alone changes nothing.

## 5. Verify

Start the dev server in the background:

```bash
cd plugins/<plugin-id> && npm run dev
```

Then check:

- `npx tsc -b` in the plugin passes (catches the import-depth mistake)
- `curl -s http://localhost:8080/api/plugins/<plugin-id>` returns the manifest with the expected extension points
- The plugin's own URL responds: `curl -sI http://localhost:<port>/`

Report the plugin id, port, extension points created, and where in the host UI they show up (sidebar entry, product tab, product detail badge, product list filter).

## Reference plugins

- `plugins/box-size/` — per-product data, a detail tab with a form, a compact info badge
- `plugins/warehouse/` — plugin-owned objects with composite keys, entity binding, a sidebar page, a host-rendered boolean filter
