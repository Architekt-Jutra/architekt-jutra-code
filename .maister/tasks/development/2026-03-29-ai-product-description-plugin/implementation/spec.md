# Specification: AI Product Description Plugin

## Goal
Create a Next.js plugin that generates structured AI-powered product descriptions (recommendation, target customer, pros, cons) using BAML for structured LLM output, stored as custom objects via the host SDK.

## User Stories
- As a product manager, I want to generate an AI-powered description for a product so that I have a structured recommendation, target customer profile, and pros/cons list without writing them manually.
- As a product manager, I want to optionally provide custom context (e.g., target market notes, tone preferences) to influence the AI-generated description.
- As a product manager, I want to regenerate a description so that I can get updated AI output when product details change.

## Core Requirements

1. **Plugin scaffolding**: Next.js Pages Router project at `plugins/ai-description/` running on port 3003, with host SDK and CSS loaded via custom `_document.tsx`
2. **Plugin manifest**: Register with `product.detail.tabs` extension point (single tab: "AI Description")
3. **Product data retrieval**: Fetch product name and description from the host via `hostApp.getProduct(productId)` as AI input
4. **Custom information input**: Optional textarea where users can add custom context (e.g., target market notes, tone preferences) to influence the AI generation
5. **AI generation endpoint**: Next.js API route (`POST /api/generate`) that accepts product name, description, and optional custom information, calls BAML to produce structured output
6. **BAML schema**: Define a BAML function that accepts product name, description, and optional custom information, and returns 4 fields -- `recommendation` (string), `targetCustomer` (string), `pros` (string[]), `cons` (string[])
7. **Configurable LLM provider**: BAML configuration supports multiple providers; active provider selected via environment variable in `.env.local`
8. **Data persistence**: Save generated descriptions as custom objects via `thisPlugin.objects.save("description", productId, data, { entityType: "PRODUCT", entityId: productId })`; load on tab open via `thisPlugin.objects.listByEntity("PRODUCT", productId)`
9. **Generation UI**: Optional "Custom Information" textarea + "Generate" button with spinner while processing; display all 4 fields in a structured layout when complete
10. **Regeneration**: When a description already exists, show the result with the custom information textarea and a "Regenerate" button that overwrites the existing custom object
11. **Error handling**: Display user-facing error messages for LLM failures, network errors, and missing product data
12. **Environment configuration**: `.env.local` for API keys and provider selection (`BAML_LLM_PROVIDER`, API key per provider), `.env.example` with placeholder values documenting required variables

## Reusable Components

### Existing Code to Leverage

| Component | File Path | What It Provides |
|-----------|-----------|-----------------|
| SDK type declarations | `plugins/sdk.ts` | `PluginSDKType`, `PluginContext`, `PluginObject`, `getSDK()` -- import directly for host communication |
| Product tab pattern | `plugins/box-size/src/pages/ProductBoxTab.tsx` | Loading state, error handling, `productId` extraction, `tc-*` CSS class usage, save/load lifecycle |
| Domain type + mapper pattern | `plugins/box-size/src/domain.ts` | Interface definition + `toX()` mapper from `PluginObject` -- adapt for `ProductDescription` |
| Manifest structure | `plugins/box-size/manifest.json` | `product.detail.tabs` extension point registration format |
| Host CSS classes | `plugins/CLAUDE.md` (UI section) | `tc-plugin`, `tc-primary-button`, `tc-ghost-button`, `tc-card`, `tc-error`, `tc-badge` |
| Custom objects with entity binding | `plugins/warehouse/src/pages/WarehousePage.tsx` | `thisPlugin.objects.save/list` with entity binding pattern |
| HTML template for SDK loading | `plugins/warehouse/index.html` | SDK script tag and plugin-ui.css link -- adapt for Next.js `_document.tsx` |

### New Components Required

| Component | Why New Code Is Needed |
|-----------|----------------------|
| Next.js project scaffolding | First Next.js plugin -- no existing Next.js template; Vite templates cannot be reused for Next.js Pages Router |
| Custom `_document.tsx` | Next.js-specific way to inject the host SDK script tag and CSS link into the HTML head (replaces `index.html`) |
| BAML schema + client | Entirely new capability -- no AI/BAML code exists in the codebase |
| Next.js API route (`/api/generate`) | Server-side LLM processing -- no existing plugin has a backend; the API route pattern is Next.js-specific |
| AI Description tab component | New page component with generation trigger, spinner, and structured result display -- the interaction pattern (async generation with latency) differs from existing instant save/load patterns |

## Technical Approach

### Architecture
The plugin is a standalone Next.js application that serves two roles:
1. **Frontend**: React pages rendered in a host iframe, communicating with the host via the shared SDK (postMessage RPC)
2. **Backend**: Next.js API routes that handle BAML/LLM calls server-side, keeping API keys secure

### Data Flow
1. Plugin iframe loads inside host product detail view, receives `productId` via SDK context
2. On mount: check for existing description via `thisPlugin.objects.listByEntity("PRODUCT", productId)`
3. If exists: display the saved description with "Regenerate" option
4. On "Generate"/"Regenerate" click:
   a. Fetch product details via `hostApp.getProduct(productId)` to get name and description
   b. POST to `/api/generate` with product name, description, and optional custom information from textarea
   c. API route invokes BAML function with all inputs, which calls the configured LLM provider
   d. BAML returns structured `{ recommendation, targetCustomer, pros, cons }`
   e. Frontend receives response, saves via `thisPlugin.objects.save()` with entity binding
   f. Display the result

### SDK Integration in Next.js
- Custom `_document.tsx` injects the SDK script tag (`plugin-sdk.js`) and CSS link (`plugin-ui.css`) in the HTML head, mirroring the `index.html` pattern used by Vite plugins
- `plugins/sdk.ts` is imported via relative path (`../../../sdk`) for type declarations and `getSDK()` (3 levels up from `src/pages/`)
- `next.config.js` must include `transpilePackages` to resolve the SDK TypeScript file outside the project root
- Pages Router file-based routing replaces `react-router-dom` Routes

### Storage Strategy
Custom objects (not per-product plugin data) are used because the requirements specify `thisPlugin.objects` with entity binding. Object type: `"description"`, object ID: `productId`, entity binding: `{ entityType: "PRODUCT", entityId: productId }`.

### BAML Configuration
- BAML schema defines the structured output function with 4 fields
- Provider configuration supports multiple LLM backends (OpenAI, Anthropic, etc.)
- Active provider and API key are configured via `.env.local` environment variables
- BAML client is generated via `npx baml-cli generate` (run as build step or `postinstall` script)
- Generated client output goes to `baml_client/` directory (gitignored)
- API route imports from `baml_client/` for type-safe BAML function calls

### Architectural Note: Next.js Choice
This is intentionally the first Next.js plugin, chosen to demonstrate that the plugin architecture supports different frontend technologies. The codebase analysis recommended Vite+React (existing convention), but the user explicitly chose Next.js for two reasons: (1) prove multi-tech support, (2) server-side LLM processing via API routes without needing Spring Boot changes.

## Implementation Guidance

### Testing Approach
- 2-8 focused tests per implementation step group
- Test verification runs only new tests, not entire suite
- API route tests: mock the BAML client to avoid real LLM calls; verify request validation, response structure, and error handling
- No frontend tests required (consistent with existing plugin testing approach -- no frontend plugin tests exist in the codebase)

### Standards Compliance
- **Minimal Implementation** (`standards/global/minimal-implementation.md`): Single extension point (product tab only), no badge, no dashboard, no streaming -- build only what is specified
- **Error Handling** (`standards/global/error-handling.md`): User-facing error messages for LLM failures, fail-fast on missing product data
- **Coding Style** (`standards/global/coding-style.md`): Consistent naming, descriptive names, focused functions
- **Conventions** (`standards/global/conventions.md`): Predictable file structure following plugin patterns, environment variables for config
- **Commenting** (`standards/global/commenting.md`): Let code speak; comment only non-obvious BAML integration details

### Project Structure
```
plugins/ai-description/
  manifest.json
  package.json
  tsconfig.json
  next.config.js
  .env.example
  .env.local              (gitignored)
  baml_src/
    main.baml             (BAML schema: function + output type)
    clients.baml          (LLM provider configuration)
  baml_client/              (BAML generated client -- gitignored)
  src/
    domain.ts             (ProductDescription interface + toProductDescription mapper)
    pages/
      _document.tsx       (SDK script + CSS injection)
      product-tab.tsx     (AI Description tab component)
      api/
        generate.ts       (POST endpoint: BAML invocation)
```

## Out of Scope
- Product detail info badge (`product.detail.info`)
- Sidebar dashboard page (`menu.main`)
- Streaming/progressive display of AI output
- Product list filters
- Custom CSS beyond host `tc-*` classes
- Multiple description variants per product
- DELETE operation for descriptions (regenerate overwrites; no explicit delete UI)

## Success Criteria
1. Plugin loads in host iframe on product detail "AI Description" tab
2. Clicking "Generate" (with optional custom information) calls the LLM via BAML and displays structured output (recommendation, target customer, pros, cons)
3. Generated description persists as a custom object and loads on subsequent tab visits
4. "Regenerate" overwrites the existing description with fresh AI output
5. LLM provider is configurable via environment variables without code changes
6. Plugin runs on port 3003 and is compatible with the `start-dev.sh` script
7. Error states are displayed to the user for LLM failures and network errors
