# Phase 1 Clarifications

## Frontend Framework Decision

**Decision**: Use Next.js (not Vite + React) for the plugin frontend.

**Rationale from user**:
1. Wants to demonstrate that the plugin architecture supports different technologies (not just Vite + React)
2. All LLM requests will be processed server-side within the Next.js backend (API routes)

**Implications**:
- BAML/AI logic lives in Next.js server-side, not in the Spring Boot host
- Plugin will have its own backend (Next.js API routes) in addition to using the host SDK
- This is the first plugin to use Next.js — sets a new precedent
- The plugin still communicates with the host via the SDK (postMessage/iframes) for product data
- AI generation endpoint will be within the Next.js server, called directly from Next.js frontend components
