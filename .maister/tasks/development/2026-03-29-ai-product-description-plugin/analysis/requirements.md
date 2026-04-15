# Requirements — AI Product Description Plugin

## Initial Description
Implement a new plugin with Next.js frontend and server-side backend that creates detailed product descriptions using AI based on the product name and description. Uses BAML for building correct structure of the output: one-liner recommendation, perfect customer target, pros (array of strings), cons (array of strings).

## Architecture Decisions
- **Frontend**: Next.js with Pages Router (demonstrates multi-tech plugin support)
- **Server-side**: Next.js API routes handle BAML/LLM calls
- **LLM Provider**: Configurable via BAML (not locked to one provider)
- **Storage**: Plugin custom objects via `thisPlugin.objects` SDK API
- **Extension Point**: `product.detail.tabs` only (no badge, no dashboard)

## User Journey
1. User navigates to a product detail page in the host app
2. User clicks the "AI Description" tab
3. If no description exists: shows a "Custom Information" textarea (optional) and a "Generate" button
4. User optionally enters custom context in the textarea (e.g., target market notes, tone preferences)
5. User clicks "Generate" — spinner shows while processing
6. Next.js API route receives request, calls BAML with product name + description + custom information
6. BAML returns structured output (recommendation, target customer, pros, cons)
7. Result is saved as a custom object via `thisPlugin.objects.save()`
8. Generated description is displayed in the tab
9. If description already exists: shows the result with a "Regenerate" option

## Functional Requirements

### FR1: Plugin Registration
- Plugin registers via manifest with `product.detail.tabs` extension point
- Plugin runs on Next.js dev server (port 3003)
- Manifest includes plugin identity, URL, and extension point definition

### FR2: Product Description Generation
- Input: Product name and description (fetched from host via SDK) + optional custom information (user-entered textarea)
- Processing: Next.js API route calls BAML function with all inputs
- Output structure (4 fields):
  - `recommendation` (string): One-liner product recommendation
  - `targetCustomer` (string): Perfect customer target description
  - `pros` (string[]): Array of product advantages
  - `cons` (string[]): Array of product limitations
- Simple button + spinner UX (no streaming)

### FR3: Data Persistence
- Store generated descriptions as custom objects via `thisPlugin.objects.save()`
- Object type: "description"
- Object ID: product ID (string)
- Entity binding: `entityType: "PRODUCT"`, `entityId: productId`
- Retrieve on tab load via `thisPlugin.objects.listByEntity()`

### FR4: Display & Regeneration
- Display all 4 fields in a structured layout
- Show "Regenerate" button when description exists
- Regeneration overwrites the existing custom object

## Technical Constraints
- Must use BAML for structured LLM output
- LLM provider configurable via BAML (not hardcoded)
- API keys via `.env.local` in plugin directory
- Host CSS classes (`tc-*`) for styling
- SDK communication via postMessage (iframe pattern)
- Port 3003 for dev server

## Similar Features to Reference
- `plugins/warehouse/` — custom objects, entity binding, product tab pattern
- `plugins/box-size/` — simple per-product form pattern
- `plugins/sdk.ts` — shared SDK types

## Scope Boundaries
- **Included**: Product tab, AI generation, custom object storage, BAML integration
- **Excluded**: Dashboard page, info badge, streaming, product list filters, custom styling
