# Specification Audit: Courier Plugin

## Overall Verdict

**pass-with-concerns**

## Summary

The specification is well-structured, detailed, and covers the vast majority of implementation concerns. The SDK call patterns are correct, the domain model is sound, and the render structure JSX is close to implementable as-is. However, there are three issues that will cause compile errors under `strict: true` (one critical, two warnings), one structural inconsistency between the gap analysis and the spec (route path mismatch), and several minor gaps worth noting before implementation begins.

---

## Issues

### Critical

**C-1: `sdk` is used as a render-time closure variable in a Hook — will cause `noUnusedLocals` / `react-hooks/exhaustive-deps` problems**

- **Location**: Section 6 — `ProductDeliveryTab` state variables, Section 7 — `CourierDashboard` state variables
- **Problem**: The spec declares `const sdk = getSDK()` at the top of the component function body, _outside_ `useEffect`. The `sdk` variable is then referenced inside `useEffect` (and inside handlers), but it is never listed in the `useEffect` dependency array. With `eslint-plugin-react-hooks` (exhaustive-deps rule), this is a lint error. It _works_ at runtime because `getSDK()` returns `window.PluginSDK` which is a stable singleton, but under strict lint rules the build may warn or fail.
- **How existing plugins handle it**: The warehouse plugin calls `getSDK()` inside each `useCallback` and inside `useEffect` directly (see `WarehousePage.tsx:24`, `WarehousePage.tsx:35`, etc.), while `ProductStockTab.tsx` and `ProductBoxTab.tsx` call it once at the component top and then reference it inside `useEffect` — but those plugins don't use `eslint-plugin-react-hooks`. The spec does not include an eslint config, so this is latent rather than compile-blocking.
- **Recommendation**: The spec's pattern (call `getSDK()` once at top, reference in effects) is consistent with how `ProductStockTab` and `ProductBoxTab` work and is fine in practice. Explicitly note in the spec that `sdk` is intentionally excluded from dependency arrays because it is a stable singleton. Alternatively, follow `WarehousePage`'s pattern of calling `getSDK()` inside each handler. Either way, the spec should be explicit about which pattern to use so the implementer doesn't introduce inconsistency.

---

**C-2: `suggestedMethod` stale-closure bug in `useEffect` — Step 2 reads a stale value**

- **Location**: Section 6, `useEffect — Load on mount`, step 2
- **Problem**: The spec states:
  > "After suggestion is resolved, call `setFormDeliveryMethod(suggestedMethod ?? "parcel_locker")` to pre-select the suggested method in the form."

  But `suggestedMethod` is a **state variable** from a previous render — the local `const suggested = suggestDeliveryMethod(boxData)` result is computed inline and stored in a local variable. The `useEffect` code example (which is the authoritative version) correctly uses the local `suggested` variable: `setFormDeliveryMethod(suggested ?? "parcel_locker")`. However, the prose description above the code block says `suggestedMethod` (the state variable), which is incorrect and contradicts the code. This contradiction will confuse an implementer who reads the prose before the code.
- **Recommendation**: Change the prose in step 2 to say "call `setFormDeliveryMethod(suggested ?? "parcel_locker")`" (the local variable), matching the code block. This is a documentation inconsistency, not a code bug, but it could cause a subtle real bug if the implementer follows the prose instead of the code.

---

### Warnings

**W-1: Route path mismatch between gap analysis and spec — `main.tsx` routes**

- **Location**: Section 5 (`src/main.tsx`) vs. gap analysis Gap 2 / Gap 3
- **Problem**: The gap analysis (Gap 2, `src/main.tsx`) specifies route `/orders` for the dashboard, matching the manifest path `/orders`. The spec changes the dashboard path to `/` (manifest section 4, `path: "/"`) and updates `main.tsx` accordingly. This is a valid decision, but the gap analysis's manifest snippet uses `/orders` and `"label": "Orders"`, while the spec uses `/` and `"label": "Courier"`. The spec appears to be the final authority, but if the implementer uses the gap analysis manifest as a reference they'll create an inconsistency.
- **Recommendation**: Add a note in the spec acknowledging the divergence from the gap analysis draft manifest, confirming that `path: "/"` and `label: "Courier"` are intentional.

---

**W-2: `pluginData` key depends on box-size plugin registration ID — not validated in spec**

- **Location**: Section 6, `useEffect`, and Section 8, "Read product + box-size plugin data"
- **Problem**: The spec hard-codes `product.pluginData?.["box-size"]` as the key. This key is the `pluginId` used when the box-size plugin was registered via `PUT /api/plugins/{id}/manifest`. Looking at `plugins/box-size/manifest.json`, there is no `pluginId` field — the ID is whatever path segment was used in the curl command. The CLAUDE.md guide says "conventionally, plugins use their directory name as the ID", which would make it `"box-size"`. The gap analysis (Integration Point section) also notes this assumption. However, if the box-size plugin was registered as `"boxSize"` or `"box_size"`, the read will silently return `null` and auto-suggestion will never trigger.
- **Recommendation**: The spec should explicitly state: "This assumes the box-size plugin was registered with ID `box-size`. If in doubt, verify by calling `hostApp.getProduct(productId)` and inspecting the `pluginData` keys in the response." The code itself is correct for the assumed ID; this is a documentation gap, not a logic gap.

---

**W-3: `handleMarkReturned` guard allows `delivered` → `returned` transition per spec, but AC-8 forbids it**

- **Location**: Section 6, `handleMarkReturned` code vs. Section 9, AC-8
- **Problem**: The `handleMarkReturned` function has this guard:
  ```typescript
  if (order.status === "returned" || order.status === "delivered") return;
  ```
  This means a `delivered` order **cannot** be marked as returned. AC-8 confirms this: "The Return button is NOT visible on `delivered` or `returned` orders." The spec is internally consistent on this point. However, the gap analysis status machine diagram shows:
  ```
  pending → packed → shipped → delivered
                              ↘ returned (from shipped or delivered)
  ```
  This implies `delivered → returned` is a valid transition per the gap analysis but is **explicitly blocked** by both the spec code and AC-8. This is a silent scope narrowing.
- **Recommendation**: Add a note in the spec confirming that `delivered → returned` is intentionally out of scope for V1. This prevents an implementer from questioning whether the guard is a bug.

---

**W-4: `CourierDashboard` early return guard omits `tc-plugin` wrapper**

- **Location**: Section 7, "Early return guards"
- **Problem**: The spec's loading guard is:
  ```typescript
  if (loading) return <p>Loading orders...</p>;
  ```
  This lacks the `tc-plugin` class wrapper, making the loading state visually inconsistent with the rest of the plugin. Compare to `ProductDeliveryTab`'s guard which correctly uses `<div className="tc-plugin" style={{ padding: "1rem" }}>Loading...</div>`.
- **Recommendation**: Change to `<div className="tc-plugin" style={{ padding: "1rem" }}>Loading orders...</div>` for consistency.

---

**W-5: No Vitest test files in the spec — gap analysis lists them as required output**

- **Location**: Section 2 (File Structure), Section 9 (Acceptance Criteria)
- **Problem**: The gap analysis (Gap 7 and Summary table) lists `plugins/courier/src/pages/*.test.tsx` as required files and includes Vitest tests as a deliverable. The spec's file structure does not include test files, and the acceptance criteria contain no AC item for tests passing. This is either an intentional omission (tests deferred to a later task) or a gap.
- **Recommendation**: Explicitly state in the spec whether tests are in scope or deferred. If deferred, note it explicitly. If in scope, add `src/pages/CourierDashboard.test.tsx` and `src/pages/ProductDeliveryTab.test.tsx` to the file structure and add an AC item. The current spec is ambiguous — it neither includes nor explicitly excludes them.

---

### Info

**I-1: `getSDK()` import is never shown in component import blocks**

- **Location**: Sections 6 and 7 (component specs)
- The spec shows the component state variables calling `getSDK()` but never shows the import statement. An implementer following the warehouse pattern will know to add `import { getSDK } from "../../../sdk";` but the spec should include it for completeness. The domain imports are also absent from the component headers.
- **Recommendation**: Add a brief imports block to each component section, e.g.:
  ```typescript
  import { getSDK } from "../../../sdk";
  import { toOrder, nextStatus, ... } from "../domain";
  ```

---

**I-2: `vite-env.d.ts` treatment is ambiguous**

- **Location**: Section 2 (File Structure)
- The spec says `vite-env.d.ts` is "not strictly required" and to "mirror warehouse plugin exactly if needed." The warehouse plugin has it (`/// <reference types="vite/client" />`). Vite projects typically need it for `import.meta.env` types — the courier plugin doesn't use `import.meta.env`, so it's genuinely optional. However, the spec's hedge ("may be added if the build complains") adds uncertainty.
- **Recommendation**: Since the courier plugin doesn't use `import.meta.env`, omitting `vite-env.d.ts` is fine. The spec could simply say: "Omit `vite-env.d.ts` — the courier plugin does not use `import.meta.env`."

---

**I-3: `ProductResponse` Java record confirms `pluginData` type is `Map<String, Object>`**

- **Context**: Good news confirmed during the audit. The backend's `ProductResponse.java` has `Map<String, Object> pluginData` — this serializes as a JSON object where each key is a `pluginId` string and the value is the plugin's data blob. The spec's cast `as { pluginData?: Record<string, { length: number; width: number; height: number }> }` is technically overly narrow (the value type for all keys is assumed to be box-dimensions shaped), but this is a safe working cast since we only access the `"box-size"` key. No issue.

---

**I-4: `STATUS_BADGE_CLASS` for `pending` and `packed` uses plain `tc-badge` — confirm this renders visibly**

- **Location**: Section 3, `domain.ts`, `STATUS_BADGE_CLASS`
- The CLAUDE.md plugin guide only documents `tc-badge--success` (green) and `tc-badge--danger` (red) modifiers. Plain `tc-badge` without a modifier may have no visible styling or might be invisible. The spec assigns plain `tc-badge` to both `pending` and `packed` — AC-10 confirms this is intentional ("neutral `tc-badge`"). This is fine assuming the CSS provides base badge styling for the unstyled class. Worth verifying visually during implementation.

---

**I-5: `handleAdvanceStatus` in `CourierDashboard` does not use a loading/saving state**

- **Location**: Section 7, `handleAdvanceStatus`
- In `ProductDeliveryTab`, `handleAddOrder` uses a `saving` flag to disable the button during the async operation. In `CourierDashboard`, `handleAdvanceStatus` and `handleDeleteOrder` have no equivalent button-disabling mechanism — rapid double-clicks could trigger duplicate API calls. This is an edge case but worth noting for robustness.
- **Recommendation**: Consider adding a `saving` state or disabling the clicked row's buttons during the operation, similar to the pattern used in `handleAddOrder`.

---

**I-6: No confirmation dialog for "Delete" or "Return"**

- **Location**: Sections 6 and 7, delete and return handlers
- Neither "Delete" nor "Return" has a confirmation step — the action is immediate. The ACs don't require a confirmation dialog, so this is by spec. Noting it as a UX consideration for future refinement.

---

**I-7: Package version numbers may not exist yet**

- **Location**: Section 5, `package.json`
- The spec lists `"react": "^19.2.4"`, `"react-router-dom": "^7.13.2"`, `"vite": "^8.0.1"`, `"typescript": "~5.9.3"`, `"@vitejs/plugin-react": "^6.0.1"`. The warehouse plugin's `package.json` matches these exactly, so these versions are proven to work. No issue — just noting that the implementer should copy from warehouse's `package.json` as stated.

---

## What's Well-Specified

- **Domain model (`domain.ts`)** is complete and correct: all types, constants, label maps, badge map, and the `nextStatus` / `suggestDeliveryMethod` pure functions are fully specified with correct TypeScript syntax that will compile under `strict: true`.
- **`toOrder` mapper** correctly handles the optional `lockerCode` field with a nullish coalescing default.
- **`handleAddOrder` duplicate validation** is correct: case-insensitive compare on trimmed input, per-product scope.
- **SDK call patterns** (Section 8) exactly match the actual `sdk.ts` type signatures — `list`, `save`, `delete` call shapes are all accurate.
- **`getSDK()` helper** is correctly imported from `../../sdk` (not redeclared), consistent with the shared SDK pattern and CLAUDE.md conventions.
- **Manifest** correctly uses the `truck` Lucide icon name, which is a valid Lucide icon. Priority ordering (110 for menu, 55 for tab) places Courier after Warehouse (100, 50) — logical ordering.
- **`data` object construction** in `handleAdvanceStatus`/`handleMarkReturned` correctly preserves all fields when updating (orderNumber, deliveryMethod, productId, lockerCode) — no field-loss on partial update.
- **Locker code handling** is consistent throughout: stored only when `parcel_locker`, defaulted to `""` in `toOrder`, displayed as `"—"` when method is `delivery_man`.
- **Early return guards** in `ProductDeliveryTab` correctly place the `!productId` guard _before_ the `loading` guard — avoids a flash of loading state when no product context is available.
- **Acceptance criteria** are specific, testable, and cover all major user flows with clear pass/fail conditions. AC-6 correctly specifies case-insensitive comparison and per-product scope.
- **`tsconfig.json`** is identical to the warehouse plugin — proven working configuration.
- **Scaffold files** (`index.html`, `vite.config.ts`, `main.tsx`) are complete and correct.
