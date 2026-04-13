# Codebase Analysis Report

**Date**: 2026-03-29
**Task**: Implement AI-powered product description plugin with BAML structured output
**Description**: Implement a new plugin with Next.js frontend and Java backend that creates detailed AI-powered product descriptions using BAML for structured output (one-liner recommendation, perfect customer target, pros array, cons array)
**Analyzer**: codebase-analyzer skill (3 Explore agents: File Discovery, Code Analysis, Pattern Mining)

---

## Summary

The codebase is a microkernel plugin-based platform (Spring Boot 4.0.5 + Java 25) with iframe-isolated plugins using Vite + React. Two reference plugins exist (warehouse, box-size) that demonstrate all integration patterns needed. The task requires introducing two new capabilities not present in the codebase: (1) AI/LLM integration with BAML for structured output, and (2) a backend component for the plugin itself. All existing plugins are frontend-only SPAs that use the host's SDK for persistence -- no plugin has its own backend. The task's request for Next.js conflicts with the established Vite + React plugin architecture; SSR provides no benefit inside an iframe.

---

## Files Identified

### Primary Files

**`/plugins/sdk.ts`** (100 lines)
- Shared SDK type declarations used by all plugins
- Defines PluginSDKType, PluginContext, PluginObject interfaces and getSDK() helper
- The new plugin will import from here for host communication

**`/plugins/warehouse/manifest.json`** (34 lines)
- Best template for manifest structure -- uses all 4 extension point types
- The new plugin will need a similar manifest with product.detail.tabs and product.detail.info

**`/plugins/warehouse/src/main.tsx`** (17 lines)
- Router setup pattern: BrowserRouter with Routes matching manifest paths
- Template for the new plugin's entry point

**`/plugins/warehouse/src/domain.ts`** (34 lines)
- Domain types and PluginObject mapper functions
- Pattern for the new plugin's ProductDescription type

**`/plugins/box-size/src/pages/ProductBoxTab.tsx`** (114 lines)
- Per-product data form pattern using thisPlugin.getData/setData
- Closest pattern to the description editor: load product data, show form, save back
- Demonstrates loading states, error handling, validation

**`/plugins/warehouse/src/pages/WarehousePage.tsx`** (lines vary)
- Full CRUD pattern with thisPlugin.objects
- Demonstrates table display, create/edit flows

**`/plugins/warehouse/index.html`** (14 lines)
- Plugin HTML template: loads SDK script + plugin-ui.css from host, mounts React app

**`/plugins/warehouse/vite.config.ts`** (9 lines)
- Minimal Vite config with React plugin and custom port

**`/plugins/warehouse/package.json`** (23 lines)
- Dependencies template: react 19, react-router-dom 7, vite 8, typescript 5.9

### Related Files

**`/src/main/java/pl/devstyle/aj/core/plugin/PluginDataService.java`** (71 lines)
- Backend service for per-product plugin data (JSONB storage)
- The new plugin will use this via SDK's thisPlugin.getData/setData

**`/src/main/java/pl/devstyle/aj/core/plugin/PluginObjectService.java`** (99 lines)
- Backend service for custom plugin objects with entity binding
- May be used to store generated descriptions as plugin objects

**`/src/main/java/pl/devstyle/aj/core/plugin/PluginDataController.java`** (44 lines)
- REST API for plugin data CRUD operations

**`/src/main/java/pl/devstyle/aj/core/plugin/PluginObjectController.java`** (90 lines)
- REST API for plugin object CRUD with entity binding and JSONB filtering

**`/src/main/java/pl/devstyle/aj/product/Product.java`** (64 lines)
- Product entity with pluginData JSONB column
- Contains the data the AI will use as input (name, description, category, price, etc.)

**`/src/main/java/pl/devstyle/aj/product/ProductService.java`** (154 lines)
- Product CRUD service, manages pluginData persistence

**`/src/main/frontend/src/plugins/PluginContext.tsx`** (lines vary)
- Host-side plugin loading and iframe management

**`/plugins/CLAUDE.md`** (comprehensive)
- Plugin development guide with SDK docs, extension points, styling, and conventions

---

## Current Functionality

The platform has no AI/LLM integration. No BAML, no OpenAI/Anthropic SDK, no AI-related dependencies exist in the codebase.

Existing plugin data patterns:
1. **Per-product data** (box-size pattern): `thisPlugin.getData/setData` stores plugin-specific JSONB on each product. Simple key-value per product.
2. **Custom objects** (warehouse pattern): `thisPlugin.objects.save/list` for plugin-owned entities with optional entity binding. Supports JSONB filtering.

### Key Components/Functions

- **getSDK()**: Entry point for all plugin-to-host communication
- **thisPlugin.getData/setData**: Per-product JSONB storage (ideal for storing generated descriptions)
- **thisPlugin.objects**: Custom object CRUD with entity binding (alternative storage)
- **hostApp.getProduct(id)**: Fetch product details (name, description, price, etc.) as AI input
- **hostApp.fetch()**: Raw API calls to host -- restricted to /api/ paths only

### Data Flow

Current plugin data flow:
1. Plugin iframe loads, receives context (pluginId, productId) via SDK
2. Plugin calls SDK methods (getData, setData, objects.*) which use postMessage RPC
3. Host receives messages, routes to PluginDataController or PluginObjectController
4. Controllers delegate to PluginDataService or PluginObjectService
5. Services persist to PostgreSQL (product.plugin_data JSONB or plugin_objects table)

Proposed AI description flow:
1. User navigates to product detail, sees "AI Description" tab
2. Plugin loads existing description (if any) via thisPlugin.getData
3. User clicks "Generate" -- plugin fetches product details via hostApp.getProduct
4. Plugin calls AI backend (BAML) with product data
5. BAML returns structured output (recommendation, target customer, pros, cons)
6. Plugin displays result and saves via thisPlugin.setData

---

## Dependencies

### Imports (What This Depends On)

- **Plugin SDK** (`plugins/sdk.ts`): All host communication
- **React 19 + react-router-dom 7**: UI framework (established pattern)
- **Vite 8**: Build tool (established pattern)
- **Host plugin-sdk.js**: Runtime SDK loaded via script tag
- **Host plugin-ui.css**: Shared styling (tc-* classes)

### New Dependencies Required

- **BAML**: Structured LLM output library (not yet in codebase)
- **LLM API client**: OpenAI/Anthropic SDK for the AI backend (not yet in codebase)
- **Backend for AI calls**: Either a new Spring service or a standalone backend

### Consumers (What Depends On This)

- **Host PluginContext.tsx**: Will load the new plugin's iframe
- **Host sidebar/product tabs**: Will render extension points from manifest
- **PluginDataService**: Will store generated descriptions

**Consumer Count**: 3 host integration points
**Impact Scope**: Low - new plugin only, no changes to existing code required

---

## Test Coverage

### Test Files

- **PluginDataAndObjectsIntegrationTests.java**: Tests plugin data and object CRUD
- **PluginObjectApiAndFilterTests.java**: Tests object API with JSONB filtering
- **PluginObjectEntityBindingTests.java**: Tests entity binding
- **PluginRegistryIntegrationTests.java**: Tests plugin registration via manifest
- **ProductIntegrationTests.java**: Tests product CRUD

### Coverage Assessment

- **Test count**: 16 test files covering core platform
- **Gaps**: No frontend plugin tests exist. No AI/LLM test patterns established.
- **New plugin testing**: Will need integration tests for the AI backend service and frontend component tests

---

## Coding Patterns

### Naming Conventions

- **Plugin IDs**: kebab-case (`warehouse`, `box-size`) matching `^[a-zA-Z0-9_-]+$`
- **Plugin directories**: match plugin ID (`plugins/warehouse/`, `plugins/box-size/`)
- **Components**: PascalCase (`WarehousePage`, `ProductBoxTab`, `ProductAvailability`)
- **Domain types**: PascalCase interfaces with `to*` mapper functions
- **Files**: PascalCase for components, camelCase for utilities
- **Java packages**: `pl.devstyle.aj.[domain]` (singular)
- **Java services**: `*Service` for business logic, `Db*QueryService` for read queries

### Architecture Patterns

- **Style**: Functional React components with hooks (useState, useEffect)
- **State Management**: Local state only (no global state library)
- **Data fetching**: useEffect + async functions with loading/error states
- **Plugin isolation**: Iframe-based with postMessage RPC
- **Backend**: Spring Boot layered architecture (Controller -> Service -> Repository)
- **Persistence**: JPA entities with SEQUENCE strategy, @Version optimistic locking
- **CSS**: Host-provided tc-* classes, minimal inline styles for layout only

---

## Complexity Assessment

| Factor | Value | Level |
|--------|-------|-------|
| Files to create | ~8-10 (plugin frontend + AI backend) | Medium |
| Dependencies (new) | 2-3 (BAML, LLM SDK, possibly Spring AI) | Medium |
| Consumers | 3 host integration points | Low |
| Test Coverage | Platform well-tested, no AI test patterns | Medium |
| New Concepts | BAML integration, LLM API calls | High |

### Overall: Moderate-Complex

The plugin frontend is straightforward -- well-established patterns exist from warehouse and box-size plugins. The complexity comes from: (1) introducing AI/LLM integration as a first-of-its-kind in this codebase, (2) deciding where the BAML/AI backend lives (new Spring service vs. standalone), and (3) API key management and error handling for external AI services.

---

## Key Findings

### Strengths
- Excellent reference plugins with comprehensive documentation (CLAUDE.md in plugins/)
- Plugin SDK provides all necessary host communication primitives
- Per-product data storage (thisPlugin.getData/setData) maps perfectly to storing AI-generated descriptions
- Host CSS classes provide consistent UI without custom styling effort
- Plugin architecture is fully additive -- no existing code needs modification

### Concerns
- **Next.js vs Vite+React**: The task requests Next.js, but all existing plugins use Vite+React. Next.js SSR provides no benefit inside an iframe. Using Next.js would break established conventions and add unnecessary complexity. Strong recommendation: use Vite+React to match existing patterns.
- **AI backend placement**: The host application has no AI dependencies. Introducing BAML/LLM calls requires deciding: (a) add to the Spring Boot host as a new domain package, (b) create a standalone backend that the plugin frontend calls directly, or (c) use the plugin frontend to call an external AI API directly (security concern with API keys).
- **API key security**: LLM API keys cannot be safely stored in a frontend-only plugin. A backend component is required.
- **No existing AI patterns**: This will be the first AI integration, setting precedent for future plugins.

### Opportunities
- Establish a reusable AI service pattern that future plugins can leverage
- Use BAML's structured output to enforce consistent description format (recommendation, target, pros, cons)
- Per-product data storage is ideal for caching generated descriptions (avoid re-generation costs)
- The product.detail.info extension point can show a compact AI description badge/summary

---

## Impact Assessment

- **Primary changes**: New plugin directory (`plugins/ai-description/` or similar) with ~6-8 frontend files
- **Backend changes**: New Spring service or package for AI/BAML integration (`pl.devstyle.aj.ai` or within plugin infrastructure)
- **Related changes**: `pom.xml` for new AI dependencies (if backend approach), possibly new Liquibase migration (if storing AI config)
- **Test updates**: New integration tests for AI service, possibly mocked LLM responses
- **No changes to existing files**: Plugin architecture is fully additive

### Risk Level: Medium

The frontend plugin is low-risk (well-established patterns). The AI backend integration is medium-high risk due to: no existing AI patterns to follow, external API dependency, API key management, and BAML being a relatively new tool. The risk is mitigated by the additive nature of the change -- nothing existing breaks if the new plugin has issues.

---

## Recommendations

### Architecture Decision: Frontend Technology

**Recommendation**: Use Vite + React (not Next.js). Rationale:
- All existing plugins use Vite + React -- consistency matters
- Plugins run in iframes -- SSR provides zero benefit
- Vite is simpler to configure and faster for development
- The plugin SDK and host CSS integration are proven with Vite

### Architecture Decision: AI Backend Placement

**Recommended approach**: Add a thin AI service to the Spring Boot host application.

Option A (Recommended): **New `pl.devstyle.aj.ai` package in the host**
- Add BAML + LLM client dependencies to pom.xml
- Create `AiDescriptionService` that accepts product data and returns structured description
- Expose via REST endpoint (e.g., `POST /api/ai/product-description`)
- Plugin frontend calls via `hostApp.fetch("/api/ai/product-description", ...)`
- API keys managed via Spring configuration (environment variables)
- Pros: Secure API key handling, consistent with host architecture, reusable for future AI features

Option B: **Standalone backend alongside the plugin**
- Separate process with its own dependencies
- Plugin calls it directly (not through host SDK)
- Pros: Isolation. Cons: Breaks plugin architecture patterns, deployment complexity.

### Implementation Strategy

1. **Plugin frontend** (follow box-size pattern):
   - `plugins/ai-description/` with standard Vite + React setup
   - Port 3003 (next available after 3001, 3002)
   - Extension points: `product.detail.tabs` (description editor/generator), `product.detail.info` (compact summary badge)
   - Domain types: `ProductDescription { recommendation: string, targetCustomer: string, pros: string[], cons: string[] }`
   - Store generated descriptions via `thisPlugin.setData(productId, description)`

2. **AI backend service** (new capability in host):
   - BAML schema defining the structured output format
   - Spring service calling LLM with product context
   - REST endpoint for the plugin to call via `hostApp.fetch`
   - Error handling for LLM timeouts, rate limits, malformed responses

3. **Testing**:
   - Backend: Integration tests with mocked LLM responses
   - Frontend: Manual testing via host app (consistent with existing plugins)

### Patterns to Follow

- Copy `plugins/warehouse/` as template, strip to essentials
- Use `thisPlugin.getData/setData` for per-product description storage (like box-size)
- Use `hostApp.getProduct(productId)` to fetch product details as AI input
- Use `hostApp.fetch` to call the new AI endpoint
- Use `tc-*` CSS classes for all UI elements
- Keep domain types in `src/domain.ts` with mapper functions
- Loading and error states on all async operations

---

## Next Steps

The orchestrator should proceed to gap analysis to clarify:
1. Final decision on frontend technology (Vite+React recommended over Next.js)
2. AI backend placement (host service recommended)
3. BAML schema design for the structured output
4. LLM provider selection (OpenAI, Anthropic, etc.)
5. API key management approach
6. Whether to add a menu.main page or only product-scoped extension points
