# Scope Clarifications

## Session: 2026-04-12

### Decision 1: Box-size dimension threshold
**Answer**: Hardcode 60cm threshold (Recommended)
- max(L, W, H) ≤ 60cm → suggest parcel locker
- max(L, W, H) > 60cm → suggest delivery man
- No configuration UI needed
- Can be made configurable in a future iteration

### Decision 2: Duplicate order numbers
**Answer**: Validate and reject duplicates (Recommended)
- Before saving, check if an order with the same `orderNumber` already exists for the product
- Show an inline error message if duplicate found
- Prevents accidental data overwrite
- Uses list + client-side check (no extra API call needed since orders are already loaded)

## Final Scope Summary
- plugins/courier/ — new standalone Vite+React+TypeScript app at port 3003
- 2 extension points: menu.main (full dashboard) + product.detail.tabs (per-product tab)
- Order statuses: pending, packed, shipped, delivered, returned
- Delivery method suggestion: hardcoded 60cm threshold
- Duplicate order number: client-side validation with error
- ~11 new files total, 0 existing files modified
