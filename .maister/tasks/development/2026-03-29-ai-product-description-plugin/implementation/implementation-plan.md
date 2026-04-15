# Implementation Plan: AI Product Description Plugin

## Overview
Total Steps: 22
Task Groups: 4
Expected Tests: 4-14 (API route tests only; no frontend tests per spec guidance)

## Implementation Steps

### Task Group 1: Plugin Scaffolding & Configuration
**Dependencies:** None
**Estimated Steps:** 6

- [x] 1.0 Complete plugin scaffolding and configuration layer
  - [x] 1.1 Write 2 tests for the API route request validation
    - Test that POST /api/generate rejects requests missing required fields (name, description) with 400
    - Test that POST /api/generate accepts valid requests with optional customInformation field
  - [x] 1.2 Create Next.js project at `plugins/ai-description/`
    - `package.json` with next, react, react-dom, typescript dependencies
    - `tsconfig.json` configured for Next.js Pages Router with path to shared `sdk.ts`
    - `next.config.js` with `experimental.externalDir` for the SDK TypeScript file outside project root, port 3003
  - [x] 1.3 Create `manifest.json` with single `product.detail.tabs` extension point
    - Name: "AI Description", version: "1.0.0", url: "http://localhost:3003"
    - Single extension point: `{ "type": "product.detail.tabs", "label": "AI Description", "path": "/product-tab", "priority": 70 }`
  - [x] 1.4 Create custom `_document.tsx` to inject host SDK and CSS
    - Script tag: `http://localhost:8080/assets/plugin-sdk.js`
    - CSS link: `http://localhost:8080/assets/plugin-ui.css`
    - Reuse pattern from: `plugins/warehouse/index.html` (adapt for Next.js `<Head>`)
  - [x] 1.5 Create environment configuration files
    - `.env.example` with `BAML_LLM_PROVIDER=openai`, `OPENAI_API_KEY=sk-your-key-here`, `ANTHROPIC_API_KEY=sk-ant-your-key-here`
    - `.env.local` is gitignored (document in .env.example)
    - Add `baml_client/` and `.env.local` to `.gitignore`
  - [x] 1.6 Ensure scaffolding tests pass
    - Run ONLY the 2 tests written in 1.1

**Acceptance Criteria:**
- Next.js project compiles and starts on port 3003
- `manifest.json` follows existing plugin manifest format
- `_document.tsx` injects SDK script and CSS link
- `.env.example` documents all required environment variables
- The 2 validation tests pass

---

### Task Group 2: BAML Schema & API Route
**Dependencies:** Group 1
**Estimated Steps:** 6

- [x] 2.0 Complete BAML schema and API generation endpoint
  - [x] 2.1 Write 3 tests for the /api/generate endpoint
    - Test successful generation returns structured response with all 4 fields (recommendation, targetCustomer, pros, cons) -- mock BAML client
    - Test that LLM/BAML failure returns 500 with user-facing error message
    - Test that customInformation is passed through to the BAML function when provided
  - [x] 2.2 Create BAML schema files in `baml_src/`
    - `main.baml`: Define `ProductDescription` class with fields `recommendation` (string), `targetCustomer` (string), `pros` (string[]), `cons` (string[]). Define `GenerateProductDescription` function accepting `productName` (string), `productDescription` (string), `customInformation` (string, optional)
    - `clients.baml`: Configure LLM providers (OpenAI, Anthropic) with fallback strategy; active provider determined by which API key is set
  - [x] 2.3 Add BAML CLI generation to build pipeline
    - Add `postinstall` and `generate` scripts: `npx baml-cli generate`
    - Generated output to `baml_client/` (gitignored)
    - Added `@boundaryml/baml` to dependencies
  - [x] 2.4 Create API route at `src/pages/api/generate.ts`
    - POST handler: validate request body (name, description required)
    - Import generated BAML client from `baml_client/`
    - Call BAML function with product name, description, and optional custom information
    - Return structured JSON response `{ recommendation, targetCustomer, pros, cons }`
    - Error handling: catch BAML/LLM errors, return 500 with `{ error: "user-facing message" }`
  - [x] 2.5 Ensure API route tests pass
    - All 7 tests pass (2 validation + 3 BAML + 2 domain)

**Acceptance Criteria:**
- BAML schema defines the structured output with 4 fields
- `npx baml-cli generate` produces `baml_client/` successfully
- API route validates input and returns structured AI output
- LLM provider is configurable via environment variable
- All 5 tests pass (2 from Group 1 + 3 from Group 2)

---

### Task Group 3: Domain Types & Data Persistence
**Dependencies:** Group 1
**Estimated Steps:** 4

- [x] 3.0 Complete domain types and SDK data persistence
  - [x] 3.1 Write 2 tests for the domain mapper function
    - Test `toProductDescription` correctly maps a `PluginObject` to `ProductDescription` interface
    - Test `toProductDescription` handles missing optional fields (e.g., empty pros/cons arrays)
  - [x] 3.2 Create `src/domain.ts` with ProductDescription interface and mapper
    - Reuse pattern from: `plugins/warehouse/src/domain.ts` and `plugins/box-size/src/domain.ts`
    - Interface: `ProductDescription { objectId: string; recommendation: string; targetCustomer: string; pros: string[]; cons: string[]; customInformation?: string }`
    - Mapper: `toProductDescription(obj: PluginObject): ProductDescription`
  - [x] 3.3 Ensure domain tests pass
    - 2 domain tests pass

**Acceptance Criteria:**
- `ProductDescription` interface covers all 4 AI fields plus optional `customInformation`
- Mapper correctly transforms `PluginObject` data to typed domain object
- The 2 domain tests pass

---

### Task Group 4: Product Tab UI & Integration
**Dependencies:** Groups 2, 3
**Estimated Steps:** 6

- [x] 4.0 Complete the AI Description tab component with full integration
  - [x] 4.1 Create `src/pages/product-tab.tsx` -- the main tab component
    - Reuse patterns from: `plugins/box-size/src/pages/ProductBoxTab.tsx` (loading state, error handling, productId extraction, tc-* CSS classes)
    - On mount: extract `productId` from SDK context via `getSDK().thisPlugin.productId`
    - Load existing description via `thisPlugin.objects.listByEntity("PRODUCT", productId)` and map with `toProductDescription`
    - If no existing description: show empty state with optional "Custom Information" textarea and "Generate" button
    - If existing description: show structured result display with "Regenerate" button and the custom information textarea (pre-filled if previously provided)
  - [x] 4.2 Implement generation flow
    - On "Generate"/"Regenerate" click: fetch product via `hostApp.getProduct(productId)` to get name and description
    - POST to `/api/generate` with `{ name, description, customInformation }` (customInformation from textarea, optional)
    - Show spinner/loading state on button while processing
    - On success: save via `thisPlugin.objects.save("description", productId, data, { entityType: "PRODUCT", entityId: productId })`
    - Update local state with new description
  - [x] 4.3 Implement structured result display
    - Display recommendation as text paragraph
    - Display target customer as text paragraph
    - Display pros as bulleted list
    - Display cons as bulleted list
    - Use `tc-card`, `tc-plugin` CSS classes for layout; inline styles only for spacing
  - [x] 4.4 Implement error handling UI
    - Display `tc-error` message for LLM failures (from API route 500 response)
    - Display `tc-error` message for network errors (fetch failure)
    - Display `tc-error` message when productId is missing from context
    - Follow error handling pattern from `ProductBoxTab.tsx`
  - [x] 4.5 Manual integration verification checklist documented

**Acceptance Criteria:**
- Tab renders in host iframe with correct SDK integration
- Generate/Regenerate flow works end-to-end with BAML
- Descriptions persist as custom objects with entity binding
- Error states are visible to the user
- All host `tc-*` CSS classes used for UI consistency
- No frontend tests required (per spec guidance -- no frontend plugin tests exist in the codebase)

---

## Execution Order

1. Group 1: Plugin Scaffolding & Configuration (6 steps)
2. Group 2: BAML Schema & API Route (6 steps, depends on 1)
3. Group 3: Domain Types & Data Persistence (4 steps, parallel with Group 2 after Group 1)
4. Group 4: Product Tab UI & Integration (6 steps, depends on 2 and 3)

## Standards Compliance

Follow standards from `.maister/docs/standards/`:
- `global/minimal-implementation.md` -- Single extension point, no badge/dashboard/streaming
- `global/error-handling.md` -- User-facing error messages for LLM failures, fail-fast on missing data
- `global/coding-style.md` -- Consistent naming, descriptive names, focused functions
- `global/conventions.md` -- Predictable file structure, environment variables for config
- `global/commenting.md` -- Let code speak; comment only non-obvious BAML integration details

## Notes

- **Test-Driven**: Groups 1-3 start with tests before implementation
- **No Frontend Tests**: Per spec guidance, no frontend component tests (consistent with existing plugins)
- **Run Incrementally**: Only new tests after each group, not entire suite
- **Mark Progress**: Check off steps as completed
- **Reuse First**: SDK types from `plugins/sdk.ts`, tab pattern from `ProductBoxTab.tsx`, domain pattern from `warehouse/src/domain.ts`, manifest format from `box-size/manifest.json`
- **BAML Client**: Generated code in `baml_client/` is gitignored; regenerate via `npx baml-cli generate`
- **Port**: 3003 (warehouse=3001, box-size=3002, ai-description=3003)
