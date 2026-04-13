# Phase 2 Scope Clarifications

## Decisions Made

### 1. Next.js Router: Pages Router
- Simpler approach, uses `_document.tsx` for SDK script loading
- Closer to existing SPA-in-iframe pattern

### 2. LLM Provider: Configurable
- BAML abstracts the provider
- Support multiple providers via BAML configuration
- Environment variable selects active provider

### 3. Extension Points: Product tab only
- Single extension point: `product.detail.tabs` for the generation UI
- No `product.detail.info` badge
- No `menu.main` sidebar dashboard
- Minimal scope focused on core AI generation feature

### 4. Generation UX: Simple button + spinner
- Click button to generate description
- Show spinner while processing
- Display result when done
- No streaming/progressive display
