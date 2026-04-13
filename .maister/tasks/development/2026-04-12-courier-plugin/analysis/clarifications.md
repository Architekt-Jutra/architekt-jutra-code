# Codebase Analysis Clarifications

## Session: 2026-04-12

### Q1: Box size integration for delivery method suggestion
**Answer**: Auto-suggest based on box size (Recommended)
- The courier plugin should read box-size plugin data for the current product via `hostApp.getProduct()` → `product.pluginData["box-size"]`
- Compare dimensions against thresholds to pre-select delivery method
- User can override the suggestion

### Q2: Order statuses
**Answer**: Simple 4-stage (Recommended)
- States: `pending`, `packed`, `shipped`, `delivered`
- Plus `returned` as terminal failure/reversal state
- Total: 5 states

### Q3: Dashboard scope  
**Answer**: Both: dashboard + product tab (Recommended)
- `menu.main` extension point: standalone order management dashboard showing all orders across all products, filterable by status
- `product.detail.tabs` extension point: per-product orders tab showing orders for the currently viewed product
