# Backend Plugin Infrastructure — Findings

## Plugin Package
All files in `src/main/java/pl/devstyle/aj/core/plugin/`.

## Key Entities

### `plugins` table
| Column | Type | Notes |
|---|---|---|
| `id` | VARCHAR(255) PK | Plugin-supplied ID, must match `^[a-zA-Z0-9_-]+$` |
| `name` | VARCHAR(255) | Required |
| `url` | VARCHAR(500) | Must be HTTP(S) |
| `enabled` | BOOLEAN | Default true |
| `manifest` | JSONB | Full manifest stored verbatim |

### `plugin_objects` table
| Column | Type | Notes |
|---|---|---|
| `id` | BIGINT PK | Generated |
| `plugin_id` | VARCHAR FK → plugins.id | |
| `object_type` | VARCHAR | Plugin-defined type |
| `object_id` | VARCHAR | Plugin-defined ID |
| `data` | JSONB | Arbitrary data |
| `entity_type` | VARCHAR | PRODUCT or CATEGORY (optional) |
| `entity_id` | BIGINT | Optional entity binding |

## REST Endpoints (Backend)
- `PUT /api/plugins/{pluginId}/manifest` — Upsert plugin (create or update)
- `GET /api/plugins` — List enabled plugins
- `GET /api/plugins/{pluginId}` — Get single plugin
- `DELETE /api/plugins/{pluginId}` — Delete plugin
- `PATCH /api/plugins/{pluginId}/enabled` — Enable/disable
- `PUT/GET/DELETE /api/plugins/{pluginId}/products/{productId}/data` — Per-product data
- `PUT/GET/DELETE /api/plugins/{pluginId}/objects/{objectType}/{objectId}` — Generic objects

## Manifest Validation
- `pluginId` must match `^[a-zA-Z0-9_-]+$`
- `name` required, non-blank
- `url` optional, must be HTTP(S) if present
- No backend validation of `extensionPoints` structure

## Key Insight
The plugin must be `enabled=true` for all its object/data operations to succeed — disabled plugins get `404` on all data APIs.
