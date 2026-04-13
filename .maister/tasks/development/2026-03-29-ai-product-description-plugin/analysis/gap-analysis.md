# Gap Analysis: AI Product Description Plugin

## Summary
- **Risk Level**: Medium
- **Estimated Effort**: Medium
- **Detected Characteristics**: creates_new_entities, involves_data_operations, ui_heavy

## Task Characteristics
- Has reproducible defect: no
- Modifies existing code: no
- Creates new entities: yes
- Involves data operations: yes (CREATE/READ generated descriptions per product)
- UI heavy: yes (product tab with generation UI, info badge)

## Gaps Identified

### Missing Features (everything is new -- no existing AI or BAML code)

1. **Plugin directory and project scaffolding**: No `plugins/ai-description/` exists. Must create Next.js project from scratch (unlike existing Vite+React plugins).

2. **BAML schema and AI generation logic**: Zero AI/LLM code in the codebase. BAML library, schema definition for the 4-field output structure, and LLM client are all entirely new.

3. **Next.js API route for LLM calls**: The AI processing backend (Next.js API routes) does not exist. This is the first plugin with its own server-side backend -- all existing plugins are frontend-only SPAs.

4. **Plugin frontend UI**: Generation tab (trigger AI, display results, save) and info badge (compact summary) components do not exist.

5. **Plugin manifest**: No manifest for `ai-description` plugin.

6. **API key management**: No pattern exists for managing external API keys in plugins. The host uses Spring config/env vars, but Next.js plugins would need their own `.env` approach.

### Behavioral/Architectural Differences from Existing Plugins

1. **Next.js vs Vite+React**: All 2 existing plugins use Vite+React with `react-router-dom` client-side routing. Next.js uses file-based routing and has its own dev server. Key differences:
   - No `index.html` entry point (Next.js generates HTML)
   - SDK script tag (`plugin-sdk.js`) and CSS (`plugin-ui.css`) must be loaded differently (via `_document.tsx` or `layout.tsx`)
   - `getSDK()` import path (`../../sdk.ts`) needs to work with Next.js module resolution
   - BrowserRouter routes pattern replaced by Next.js pages/app router
   - Dev server port allocation (existing: 3001, 3002; this plugin: 3003)

2. **Plugin has its own backend**: Existing plugins call host APIs exclusively via `hostApp.fetch()`. This plugin calls its own Next.js API routes for AI generation, then uses SDK for storage. This is a hybrid pattern: Next.js backend for AI, host SDK for persistence.

3. **Async generation UX**: Existing plugins have instant save/load. AI generation has latency (2-15 seconds for LLM calls). Needs loading/streaming states that don't exist in reference plugins.

## New Capability Analysis

### Integration Points

| Integration Point | Type | Details |
|-------------------|------|---------|
| `product.detail.tabs` | Extension point | "AI Description" tab on product detail |
| `product.detail.info` | Extension point | Compact badge/summary below product info |
| `thisPlugin.getData/setData` | SDK storage | Per-product description persistence |
| `hostApp.getProduct(id)` | SDK data | Fetch product name, description, price, category as AI input |
| Next.js API route | Plugin backend | `POST /api/generate` for LLM calls |
| Plugin manifest | Registration | `PUT /api/plugins/ai-description/manifest` |

### Patterns to Follow

| Pattern | Source | Adaptation Needed |
|---------|--------|-------------------|
| Per-product data (getData/setData) | `box-size` plugin | Direct reuse -- store AI output as plugin data |
| Product tab page component | `ProductBoxTab.tsx` | Adapt for generation trigger + display (not form input) |
| Info badge component | `ProductBoxBadge.tsx` | Adapt to show one-liner recommendation |
| Domain types + mappers | `box-size/src/domain.ts` | New `ProductDescription` interface with 4 fields |
| Manifest with tabs + info | `box-size/manifest.json` | Same extension point types, new paths |
| Host CSS classes (`tc-*`) | All plugins | Same classes, new layout for pros/cons lists |
| Loading/error state pattern | `ProductBoxTab.tsx` | Extend with generation-in-progress state |

### Architectural Impact

- **New files**: ~10-14 files (Next.js project structure is larger than Vite)
- **New dependencies**: `next`, `react` (already familiar), `@boundaryml/baml`, LLM SDK (OpenAI or Anthropic)
- **No changes to existing files**: Fully additive -- no host code modifications needed
- **Precedent-setting**: First Next.js plugin and first AI integration establish patterns for future work

## Data Lifecycle Analysis

### Entity: ProductDescription

Stored as per-product plugin data via `thisPlugin.setData(productId, data)`.

| Operation | Backend | UI Component | User Access | Status |
|-----------|---------|--------------|-------------|--------|
| CREATE | Next.js API route generates via LLM; SDK `setData` persists | "Generate" button on product tab | Product detail > AI Description tab | Planned |
| READ | SDK `getData` from host JSONB | Display component on tab + badge | Product detail > tab (full) + info badge (summary) | Planned |
| UPDATE | Re-generate via "Generate" button overwrites | Same as CREATE (regenerate flow) | Same "Generate" button | Planned |
| DELETE | SDK `removeData` | "Remove" button on tab | Product detail > AI Description tab | Planned |

**Completeness**: 100% (all CRUD operations planned across all 3 layers)
**Orphaned Operations**: None -- CREATE, READ, UPDATE, DELETE all have UI + backend + user access paths planned.

### Multi-Touchpoint Discovery

The product description data will be accessible at:

1. **Product detail tab** (primary): Full description with all 4 fields -- recommendation, target customer, pros, cons
2. **Product detail info badge** (secondary): Compact one-liner recommendation shown below product info card

No additional touchpoints identified. The description is product-scoped data that makes sense on the product detail view. No need for description data on product list, reports, or other contexts at this stage.

## UI Impact Assessment

### Navigation Paths

Users reach the AI description feature via:
1. Product list > Click product > "AI Description" tab (product.detail.tabs)
2. Product list > Click product > Info badge visible immediately (product.detail.info)

### Discoverability Score: 8/10

The tab pattern is well-established in this application (box-size and warehouse plugins already add tabs). Users familiar with the platform will naturally discover it. The info badge provides passive visibility without requiring tab navigation.

### Persona Impact

| Persona | Impact | Notes |
|---------|--------|-------|
| Product manager | High positive | Primary user -- generates descriptions for products |
| Admin | Neutral | Plugin registration only |
| Developer | Medium positive | New reference plugin pattern (Next.js) |

## Issues Requiring Decisions

### Critical (Must Decide Before Proceeding)

1. **SDK integration approach in Next.js**
   - **Issue**: The host SDK (`plugin-sdk.js`) is loaded via a `<script>` tag in `index.html` and sets `window.PluginSDK`. Next.js does not have a plain `index.html`. The SDK must be loaded in the Next.js HTML output and the shared `plugins/sdk.ts` type declarations must be importable.
   - **Options**:
     - (A) Use Next.js Pages Router with custom `_document.tsx` to inject the SDK script tag and CSS link
     - (B) Use Next.js App Router with a root `layout.tsx` that includes the SDK script tag
   - **Recommendation**: (A) Pages Router -- simpler mental model, closer to existing plugins' single-page approach, and the iframe context doesn't benefit from App Router features (server components, streaming, layouts)
   - **Rationale**: The plugin runs in an iframe with client-side SDK communication. Server components add complexity without benefit. Pages Router is a more natural fit for an SPA-in-iframe.

2. **LLM provider selection**
   - **Issue**: No LLM provider is configured. BAML supports multiple providers (OpenAI, Anthropic, Google, etc.). The choice affects API key management, cost, and output quality.
   - **Options**:
     - (A) OpenAI (GPT-4o or similar)
     - (B) Anthropic (Claude)
     - (C) Make provider configurable via environment variable
   - **Recommendation**: (C) Configurable, with one provider implemented initially
   - **Rationale**: BAML abstracts the provider, so the schema stays the same. Implementing one and making it swappable is low extra effort.

3. **API key management for the Next.js backend**
   - **Issue**: The Next.js plugin runs as a separate process with its own environment. LLM API keys must be stored securely, not in the frontend bundle.
   - **Options**:
     - (A) `.env.local` file in the plugin directory (standard Next.js pattern, gitignored)
     - (B) Shared environment from the host's Docker Compose
   - **Recommendation**: (A) `.env.local` in the plugin directory
   - **Rationale**: Simplest approach, standard Next.js convention. The plugin is a standalone process with its own config. Add `.env.local` to `.gitignore` and provide `.env.example`.

### Important (Should Decide)

1. **Extension points scope**
   - **Issue**: The plugin could register for `menu.main` (sidebar entry for a standalone AI description page) in addition to `product.detail.tabs` and `product.detail.info`. A standalone page could show descriptions for all products.
   - **Options**:
     - (A) Product-scoped only (tabs + info badge) -- matches the per-product nature of descriptions
     - (B) Add `menu.main` for a dashboard showing all generated descriptions
   - **Default**: (A) Product-scoped only
   - **Rationale**: The feature is inherently per-product. A dashboard adds scope without clear user value at this stage. Can be added later.

2. **Generation trigger UX pattern**
   - **Issue**: AI generation takes 2-15 seconds. Need to decide on the interaction pattern.
   - **Options**:
     - (A) Simple "Generate" button with loading spinner and disabled state
     - (B) Streaming response that populates fields progressively
   - **Default**: (A) Simple button with loading state
   - **Rationale**: Streaming adds significant complexity (SSE/WebSocket from Next.js API route, incremental BAML parsing). The simple pattern matches existing plugin UX patterns. Streaming can be a future enhancement.

3. **start-dev.sh compatibility**
   - **Issue**: The `start-dev.sh` script auto-starts all plugins by running `npm run dev` in any `plugins/*/` directory with a `package.json`. Next.js uses the same `npm run dev` command, so it should work. However, Next.js defaults to port 3000 which may conflict.
   - **Options**:
     - (A) Configure Next.js to use port 3003 in `package.json` scripts (`next dev -p 3003`)
     - (B) Use a custom `next.config.js` to set the port
   - **Default**: (A) Port in package.json script
   - **Rationale**: Explicit port in `npm run dev` command is the simplest and most visible approach. Matches how Vite plugins set ports.

## Recommendations

1. **Follow the box-size plugin as primary template**: The per-product data pattern (getData/setData, product tab + info badge) maps directly. Adapt the structure for Next.js while keeping the same SDK integration approach.

2. **Keep the BAML schema simple**: 4 fields (recommendation, targetCustomer, pros, cons) as specified. No nested structures or optional fields for v1.

3. **Add `.env.example` with placeholder**: Document required environment variables (LLM API key, model name) so other developers can set up quickly.

4. **Test the iframe + Next.js dev server combination early**: This is the highest technical risk item. Verify that Next.js dev server works correctly inside the host's iframe with the SDK script tag before building features.

## Risk Assessment

- **Complexity Risk**: Medium -- Next.js in an iframe is uncharted territory for this project. The SDK integration and routing need careful validation.
- **Integration Risk**: Low -- plugin architecture is fully additive. No existing code changes needed. Host iframe loading is tech-agnostic (just a URL).
- **Regression Risk**: Low -- no existing functionality is modified. New plugin in isolation.
- **External Dependency Risk**: Medium -- LLM API availability, rate limits, and costs. BAML is a relatively new library.
