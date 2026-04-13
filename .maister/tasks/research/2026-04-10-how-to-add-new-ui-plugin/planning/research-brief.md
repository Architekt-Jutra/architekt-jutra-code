# Research Brief

## Research Question
How to add a new UI plugin to the `aj` platform?

## Research Type
Technical — exploring codebase to understand the plugin system architecture and the steps required to create a new frontend UI plugin.

## Scope

### Included
- Plugin SDK (`src/main/frontend/src/plugin-sdk/`) — what it exports and how it's used
- Existing plugin examples (`src/main/frontend/src/plugins/`) — reference implementations
- Plugin registration mechanism — how plugins are discovered and registered
- Frontend router integration — how plugins hook into the routing system
- Plugin component structure — naming conventions, required files, entry points
- Backend plugin descriptors (if any) — whether backend registration is needed for UI plugins

### Excluded
- Backend-only plugins (no UI)
- Plugin deployment/packaging beyond local development
- Plugin testing infrastructure (out of scope for this question)

## Success Criteria
- Clear step-by-step understanding of what files to create for a new UI plugin
- Understanding of the plugin registration mechanism (how the app discovers plugins)
- Knowledge of what the plugin SDK provides (hooks, components, utilities)
- At least one working reference example from the existing codebase

## Constraints
- Project is pre-alpha; the plugin framework is still being scaffolded
- Focus on the current state of the codebase, not speculative future design
