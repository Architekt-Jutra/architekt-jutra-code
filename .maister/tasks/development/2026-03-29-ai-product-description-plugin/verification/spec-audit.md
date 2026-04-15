# Specification Audit: AI Product Description Plugin

**Auditor**: Specification Auditor Agent
**Date**: 2026-03-29
**Spec Path**: `.maister/tasks/development/2026-03-29-ai-product-description-plugin/implementation/spec.md`
**Compliance Status**: WARNING -- Mostly Compliant

The specification is well-structured and generally implementable, but contains several inconsistencies with the actual SDK API, duplicate numbering errors, a storage pattern inconsistency between spec and requirements, and underspecified areas that will cause implementation ambiguity.

---

## Critical Issues

### C1: Storage API mismatch between spec and requirements

**Spec Reference**: Core Requirement #7 (Data persistence) -- uses `thisPlugin.objects.save()` and `thisPlugin.objects.list()`

**Requirements Reference**: FR3 (Data Persistence) -- says "Retrieve on tab load via `thisPlugin.objects.listByEntity()`"

**Evidence**:
- Spec line 20 says: `thisPlugin.objects.list("description", { entityType: "PRODUCT", entityId: productId })`
- Requirements line 47 says: `thisPlugin.objects.listByEntity()`
- SDK (`plugins/sdk.ts` lines 71-76) exposes both `list()` with entity filter options AND `listByEntity()` -- these are different methods with different semantics
- `list()` filters by object type + entity; `listByEntity()` returns ALL object types for an entity

**Category**: Inconsistent (between spec and requirements)

**Severity**: Medium -- Both methods would technically work for single-type retrieval, but the spec and requirements contradict each other. The spec's approach (`list` with entity filter) is more precise and correct for this use case since the plugin only has one object type.

**Recommendation**: Align requirements with spec. Use `thisPlugin.objects.list("description", { entityType: "PRODUCT", entityId: productId })` as stated in the spec, since it filters by type.

---

### C2: Codebase analysis recommended against Next.js; spec proceeds with Next.js anyway without addressing concerns

**Spec Reference**: Core Requirement #1 -- "Next.js Pages Router project"

**Codebase Analysis Reference**: Key Findings / Concerns section -- "Next.js vs Vite+React: The task requests Next.js, but all existing plugins use Vite+React. Next.js SSR provides no benefit inside an iframe."

**Evidence**:
- Codebase analysis (`analysis/codebase-analysis.md` lines 217-219) explicitly recommends AGAINST Next.js
- Gap analysis (`analysis/gap-analysis.md` lines 33-38) details 5 specific technical differences that Next.js introduces
- Scope clarifications (`analysis/scope-clarifications.md`) records Pages Router decision but does not record a decision about "Next.js vs Vite+React"
- The plugin guide (`plugins/CLAUDE.md` lines 8-18) documents Vite+React as the standard plugin structure
- All 2 existing plugins (warehouse, box-size) use Vite+React

**Category**: Ambiguous (analysis phase recommended against it, scope clarifications do not explicitly record an override)

**Severity**: High -- This is a precedent-setting architectural decision. The spec should explicitly acknowledge the deviation from established patterns and document why Next.js was chosen despite the analysis recommendation. Without this, the implementer lacks context on whether this was an intentional override or an oversight.

**Recommendation**: Add a brief "Architecture Decision Record" section to the spec explaining: (a) the analysis recommended Vite+React, (b) the stakeholder chose Next.js anyway because [reason], (c) this is intentional and sets precedent for future plugins.

---

## Important Gaps

### H1: Duplicate requirement numbering

**Spec Reference**: Core Requirements list

**Evidence**:
- Line 18: requirement numbered `6.` (BAML schema)
- Line 19: requirement numbered `6.` again (Configurable LLM provider)
- Line 21: requirement numbered `9.` (Generation UI) -- skips 7 and 8

**Category**: Incorrect (formatting error)

**Severity**: Medium -- Ambiguous referencing. If implementation plans or test plans reference "Requirement 7" or "Requirement 8", there is no such requirement. The jump from 6 to 9 also suggests content may have been lost.

**Recommendation**: Renumber requirements sequentially 1-12.

---

### H2: SDK import path incompatibility with Next.js module resolution

**Spec Reference**: SDK Integration in Next.js section -- "`plugins/sdk.ts` is imported via relative path (`../../sdk`)"

**Evidence**:
- Current plugins use `import { getSDK } from "../../sdk"` (e.g., `plugins/box-size/src/pages/ProductBoxTab.tsx` line 2, `plugins/warehouse/src/pages/WarehousePage.tsx` line 2)
- This works because Vite resolves `../../sdk` relative to `src/pages/` -> `plugins/sdk.ts`
- In Next.js Pages Router, pages live in `src/pages/` inside the plugin directory, so `../../sdk` would resolve to `plugins/ai-description/sdk` (wrong) or `plugins/sdk` depending on the actual nesting
- The spec's project structure (line 99-117) shows `src/pages/product-tab.tsx` which is 2 levels deep from `plugins/ai-description/`, but the import `../../sdk` from `src/pages/` would go to `plugins/ai-description/sdk`, not `plugins/sdk.ts`
- The correct relative path from `plugins/ai-description/src/pages/` to `plugins/sdk.ts` would be `../../../sdk`
- Additionally, Next.js may need `next.config.js` transpilePackages or path aliases to resolve TypeScript outside the project root

**Category**: Incorrect

**Severity**: High -- This will cause a build/import error during implementation. The path arithmetic is wrong and Next.js has stricter module boundaries than Vite.

**Recommendation**: (1) Fix the import path to `../../../sdk` (3 levels: pages -> src -> ai-description -> plugins/sdk.ts). (2) Add a note about configuring `next.config.js` with `transpilePackages` or `tsconfig.json` path aliases to resolve imports outside the Next.js project root, since Next.js does not resolve external TypeScript files by default.

---

### H3: API route file path does not match Next.js Pages Router conventions

**Spec Reference**: Project Structure section, line 116 -- `src/api/generate.ts`

**Evidence**:
- Next.js Pages Router API routes must live in `pages/api/` (or `src/pages/api/` if using `src/` directory)
- The spec shows `src/api/generate.ts` which is NOT a valid Next.js API route path
- The correct path would be `src/pages/api/generate.ts`
- The spec mentions the endpoint as `POST /api/generate` (Core Requirement #5, line 17) which is correct for the URL, but the file path is wrong

**Category**: Incorrect

**Severity**: High -- The API route will not be recognized by Next.js at the specified path. The implementer must know to place it in `src/pages/api/`.

**Recommendation**: Change project structure to show `src/pages/api/generate.ts` instead of `src/api/generate.ts`.

---

### H4: No specification for handling the `objects.list` return type when loading existing descriptions

**Spec Reference**: Data Flow step 2 -- "check for existing description via `thisPlugin.objects.list(...)`"

**Evidence**:
- `objects.list()` returns `Promise<PluginObject[]>` (SDK `plugins/sdk.ts` line 71) -- an array
- The spec says object ID = productId, and there should be at most one description per product
- But `list()` returns an array. The spec does not specify:
  - How to handle an empty array (no existing description)
  - How to extract the single expected object from the array (e.g., `results[0]`)
  - Whether to use `objects.get("description", productId)` instead, which returns a single object
- The warehouse plugin uses `list()` because it has multiple objects per type; the box-size plugin uses `getData()`/`setData()` for single-value per-product data

**Category**: Incomplete

**Severity**: Medium -- Since there is exactly one description per product and the objectId is the productId, using `objects.get("description", productId)` would be simpler and more semantically correct for loading. The `list()` call is better suited for the "does it exist?" check. The spec should clarify the load pattern.

**Recommendation**: Specify that on tab load, use `objects.get("description", productId)` wrapped in try/catch (throws if not found) OR use `list()` and take the first result. Be explicit about the pattern.

---

### H5: BAML build-time code generation not addressed in project setup

**Spec Reference**: BAML Configuration section -- "BAML client is generated at build time and imported in the API route"

**Evidence**:
- BAML requires a code generation step (`npx baml generate` or similar) that produces TypeScript clients from `.baml` schema files
- The spec mentions "generated at build time" but does not specify:
  - What command generates the BAML client
  - Whether it should be a `prebuild` or `predev` npm script
  - Where the generated code is output (typically `baml_client/`)
  - Whether `baml_client/` should be gitignored or committed
  - How the generated client is imported in the API route
- The project structure (lines 99-117) does not show a `baml_client/` directory

**Category**: Incomplete

**Severity**: Medium -- An implementer unfamiliar with BAML would not know how to set up the generation pipeline. This is the first BAML integration in the codebase, so there is no existing pattern to follow.

**Recommendation**: Add to the project structure: `baml_client/` (generated, gitignored). Add to implementation guidance: "Add `"generate": "npx @boundaryml/baml generate"` to package.json scripts. Run before dev/build. Add `baml_client/` to `.gitignore`."

---

### H6: `.env.local` variable names and BAML provider selection mechanism unspecified

**Spec Reference**: Core Requirement #12 -- ".env.local for API keys, .env.example with placeholder values"

**Evidence**:
- The spec says "active provider selected via environment variable" but does not specify:
  - The environment variable name(s) (e.g., `OPENAI_API_KEY`, `LLM_PROVIDER`, `ANTHROPIC_API_KEY`)
  - How BAML selects between providers based on env vars
  - What `.env.example` should contain
- BAML's provider configuration pattern typically uses specific env var names in `clients.baml`
- Without specifying these, two implementers could produce incompatible configurations

**Category**: Incomplete

**Severity**: Medium -- The implementer needs to make up variable names and BAML configuration patterns. For a first-of-its-kind integration, these should be specified.

**Recommendation**: Add a concrete `.env.example` to the spec, e.g.:
```
LLM_PROVIDER=openai
OPENAI_API_KEY=sk-your-key-here
# ANTHROPIC_API_KEY=sk-ant-your-key-here
```
And specify how `clients.baml` references these variables.

---

## Minor Discrepancies

### L1: Requirements document mentions `product.detail.info` badge but spec excludes it

**Requirements Reference**: FR3 mentions `listByEntity()`, and the original gap analysis mentions info badge

**Spec Reference**: Out of Scope section explicitly excludes "Product detail info badge"

**Evidence**:
- Gap analysis (`analysis/gap-analysis.md` lines 51, 86-98) includes `product.detail.info` as an integration point and plans a READ operation for the badge
- Scope clarifications (`analysis/scope-clarifications.md` line 16) explicitly excludes the badge
- Spec Out of Scope section confirms exclusion

**Category**: Extra (in analysis artifacts, correctly excluded in spec)

**Severity**: Low -- The spec is correct; the analysis artifacts are outdated. No action needed, but an implementer reading analysis docs first could be confused.

---

### L2: Gap analysis mentions DELETE operation but spec excludes it

**Gap Analysis Reference**: Data Lifecycle table shows DELETE operation as "Planned"

**Spec Reference**: Out of Scope section -- "DELETE operation for descriptions (regenerate overwrites; no explicit delete UI)"

**Evidence**:
- Gap analysis (`analysis/gap-analysis.md` line 87) lists DELETE with "SDK `removeData`" and a "Remove" button
- Spec explicitly excludes DELETE
- Scope clarifications do not record this as a decision

**Category**: Extra (in analysis, correctly excluded in spec)

**Severity**: Low -- Spec is authoritative, but gap analysis is misleading.

---

### L3: Gap analysis references `thisPlugin.getData/setData` but spec uses `thisPlugin.objects`

**Gap Analysis Reference**: Multiple references to `getData/setData` pattern

**Spec Reference**: Core Requirement #7 explicitly uses `thisPlugin.objects.save/list`

**Evidence**:
- Gap analysis (`analysis/gap-analysis.md` lines 61, 80-81) recommends `getData/setData` pattern
- Codebase analysis (`analysis/codebase-analysis.md` lines 97-98, 106) recommends `getData/setData`
- Spec uses `thisPlugin.objects` with entity binding throughout
- Both approaches are valid SDK APIs, but they use different storage mechanisms (plugin data on product vs. custom objects table)

**Category**: Inconsistent (between analysis and spec)

**Severity**: Low -- The spec is the authoritative document and its choice of `objects` with entity binding is a valid approach. But the divergence from analysis recommendations is not explained.

---

### L4: Testing section says "no frontend tests required" but does not address BAML client mocking strategy

**Spec Reference**: Implementation Guidance / Testing Approach -- "API route tests: mock the BAML client"

**Evidence**:
- The spec says to mock the BAML client but does not specify:
  - How to mock (jest.mock, dependency injection, environment variable toggle)
  - What the mock should return (a sample structured response)
  - Whether to use BAML's built-in test capabilities
- This is the first testing of any AI/BAML component in the codebase

**Category**: Incomplete

**Severity**: Low -- Experienced implementers can figure this out, but a sample mock pattern would reduce ambiguity for this first-of-kind integration.

---

## Clarification Needed

### Q1: Was Next.js chosen intentionally over the analysis recommendation?

The codebase analysis explicitly recommended Vite+React over Next.js. The scope clarifications document records decisions about Pages Router, LLM provider, and extension points, but does NOT record a decision about "Next.js vs Vite+React." Was this an intentional override by the stakeholder, or was the analysis recommendation simply not surfaced?

**Impact**: If intentional, the spec should document why. If unintentional, the spec should be reconsidered.

### Q2: Why `thisPlugin.objects` instead of `thisPlugin.getData/setData`?

Both the codebase analysis and gap analysis recommended `getData/setData` for per-product description storage. The spec uses `thisPlugin.objects` with entity binding instead. The `getData/setData` pattern is simpler (single call, no array handling, no entity binding needed) and maps naturally to "one description per product." What drove the decision to use the more complex `objects` API?

**Impact**: Using `objects` is not wrong, but it adds complexity (array returns, entity binding boilerplate) for a use case that `getData/setData` handles more simply.

### Q3: What happens when `hostApp.getProduct(productId)` returns a product with no description?

The spec says the AI input is "product name and description" (Core Requirement #3). But what if the product's description field is empty or null? Should the plugin:
- (a) Disable the Generate button and show a message?
- (b) Generate with name only?
- (c) Treat it as an error?

**Impact**: Missing error handling specification for a likely real-world scenario.

---

## Extra Features (Not in Requirements)

None identified. The spec is well-scoped and matches the scope clarifications.

---

## Recommendations

### Must Fix (Before Implementation)

1. **Fix API route file path**: Change `src/api/generate.ts` to `src/pages/api/generate.ts` in the project structure (Finding H3)
2. **Fix SDK import path**: Change `../../sdk` to `../../../sdk` and add Next.js external module resolution note (Finding H2)
3. **Fix requirement numbering**: Renumber Core Requirements sequentially (Finding H1)

### Should Fix

4. **Specify BAML code generation setup**: Add `baml_client/` to project structure, add generation command to implementation guidance (Finding H5)
5. **Specify environment variable names**: Provide concrete `.env.example` content and BAML provider configuration pattern (Finding H6)
6. **Clarify object loading pattern**: Specify whether to use `objects.get()` or `objects.list()[0]` for loading existing description (Finding H4)
7. **Document Next.js decision rationale**: Add brief ADR explaining why Next.js was chosen despite analysis recommendation (Finding C2)

### Nice to Have

8. **Align analysis artifacts**: Note in spec that analysis docs reference `getData/setData` but spec intentionally uses `objects` (Finding L3)
9. **Add BAML mock example**: Provide sample mock pattern for API route tests (Finding L4)

---

## Summary

| Category | Count |
|----------|-------|
| Critical | 0 |
| High | 3 (C2, H2, H3) |
| Medium | 4 (C1, H1, H4-H6) |
| Low | 4 (L1-L4) |
| Clarification Needed | 3 |

The specification is **functionally complete** -- all user stories have corresponding requirements, the data flow is well-documented, and the out-of-scope section is clear. However, it contains **3 high-severity issues** that will cause implementation failures if not addressed (wrong file path for API route, wrong SDK import path, and an undocumented architectural deviation). The medium-severity gaps around BAML setup and environment configuration will slow implementation due to ambiguity. Fixing the "Must Fix" items above would bring this spec to full compliance.
