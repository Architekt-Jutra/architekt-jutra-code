# AJ Knowledge Graph — Labels, Relationships, Properties

Mirrors `tools/kg-simple-demo/seed/aj-kg-ontology.cypher`. Use these exact identifiers in Cypher.

## Layer model

- **Ontology layer** — every node is `:Ontology:<X>` where X is one of:
  - `EntityType`, `Property`, `RelationType`, `RelationRule`, `OntologyDoc`
- **Instance layer** — concrete domain nodes use entity-specific labels (no `:Ontology` label). One label per node.

## Instance node labels (1:1 with EntityType.name)

| Label              | EntityType name      | Meaning                                                                 |
|--------------------|----------------------|-------------------------------------------------------------------------|
| `System`           | `system`             | Top-level deployable platform.                                          |
| `Host`             | `host`               | Core application owning master data + plugin engine.                    |
| `Frontend`         | `frontend`           | SPA bundled with the host.                                              |
| `Backend`          | `backend`            | Server-side of the host.                                                |
| `Core`             | `core`               | Backend foundation (BaseEntity, auditing, error handling, engine).      |
| `PluginEngine`     | `plugin_engine`      | Backend services that register plugins / store plugin data.             |
| `Module`           | `module`             | Backend feature module (category, product, plugin, …).                  |
| `Entity`           | `entity`             | Host-owned domain entity (Product, Category, PluginDescriptor, …).      |
| `Repository`       | `repository`         | JpaRepository or jOOQ Db*QueryService.                                  |
| `Action`           | `action`             | Service method (query or command) backed by an endpoint.                |
| `APIEndpoints`     | `api_endpoints`      | HTTP endpoint under `/api`.                                             |
| `CorePage`         | `core_page`          | Host-owned frontend page.                                               |
| `PluginShell`      | `plugin_shell`       | Host UI surface that mounts plugin iframes.                             |
| `Plugin`           | `plugin`             | Self-contained extension app.                                           |
| `Manifest`         | `manifest`           | Plugin's declarative JSON document.                                     |
| `ExtensionPoint`   | `extension_point`    | Named UI surface where plugins contribute.                              |
| `FilterDefinition` | `filter_definition`  | Host-rendered product list filter declared by a plugin.                 |
| `PluginPage`       | `plugin_page`        | Plugin-side page mounted into the host UI.                              |
| `PluginEntity`     | `plugin_entity`      | Domain object owned entirely by a plugin.                               |
| `ExtendedEntity`   | `extended_entity`    | Plugin data extending a host entity (Product).                          |
| `StorageStrategy`  | `storage_strategy`   | `namespaced-plugin-data` or `plugin-custom-object`.                     |
| `EntityBinding`    | `entity_binding`     | `(entityType, entityId)` link from PluginObject to host entity.         |
| `IframeIsolation`  | `iframe_isolation`   | Sandbox + origin check around plugin iframes.                           |
| `HostBridge`       | `host_bridge`        | postMessage RPC channel between plugin and host.                        |
| `PluginSDK`        | `plugin_sdk`         | TypeScript library at `/assets/plugin-sdk.js`.                          |
| `DomainConcept`    | `domain_concept`     | Plugin-specific TypeScript domain type.                                 |
| `Feature`          | `feature`            | User-visible capability of the platform.                                |
| `Actor`            | `actor`              | Type of user.                                                           |
| `API`              | `api`                | A plugin's integration contract (`sdk-host-bridge` or `backend-route`). |
| `ExternalSystem`   | `external_system`    | RDBMS / LLM proxy / LLM provider / PII redaction / observability.       |

## Relationship types

```
CONTAINS, USES, EMBEDS, MANAGES, REGISTERS, OPERATES_ON, EXPOSED_BY,
PERSISTED_BY, DECLARES, DEFINES, RUNS_IN, COMMUNICATES_VIA, EXPOSES,
IMPLEMENTED_BY, RENDERED_ON, PROXIES_TO, QUERIES, STORED_VIA, EXTENDS,
PERSISTED_IN, MAY_USE, TARGETS, PERFORMED_BY, REALIZED_BY, DELIVERED_VIA,
BACKED_BY
```

Plus ontology-only edges: `HAS_PROPERTY`, `FROM`, `TO`, `HAS_TYPE` (between `RelationRule` ↔ `EntityType` / `RelationType` / `Property`).

## Allowed `(source) -[type]-> (target)` triples

| From               | Type             | To                   | Notes                                                              |
|--------------------|------------------|----------------------|--------------------------------------------------------------------|
| System             | CONTAINS         | Host                 |                                                                    |
| System             | CONTAINS         | Plugin               |                                                                    |
| Actor              | USES             | System               |                                                                    |
| Host               | CONTAINS         | Frontend             |                                                                    |
| Host               | CONTAINS         | Backend              |                                                                    |
| Frontend           | CONTAINS         | CorePage             |                                                                    |
| Frontend           | CONTAINS         | PluginShell          |                                                                    |
| Frontend           | EMBEDS           | Plugin               | Mounted via PluginShell.                                           |
| Backend            | CONTAINS         | Core                 |                                                                    |
| Backend            | CONTAINS         | Module               |                                                                    |
| Backend            | USES             | ExternalSystem       | PostgreSQL.                                                        |
| Core               | CONTAINS         | PluginEngine         |                                                                    |
| PluginEngine       | MANAGES          | Entity               | PluginDescriptor + PluginObject.                                   |
| PluginEngine       | REGISTERS        | Plugin               |                                                                    |
| Module             | CONTAINS         | Action               |                                                                    |
| Module             | CONTAINS         | Entity               |                                                                    |
| Module             | CONTAINS         | APIEndpoints         |                                                                    |
| Action             | OPERATES_ON      | Entity               |                                                                    |
| Action             | EXPOSED_BY       | APIEndpoints         |                                                                    |
| Entity             | PERSISTED_BY     | Repository           |                                                                    |
| Entity             | EXPOSED_BY       | APIEndpoints         |                                                                    |
| CorePage           | USES             | APIEndpoints         |                                                                    |
| PluginPage         | USES             | APIEndpoints         | Indirect — through the SDK.                                        |
| Plugin             | DECLARES         | Manifest             |                                                                    |
| Plugin             | CONTAINS         | PluginPage           |                                                                    |
| Plugin             | CONTAINS         | PluginEntity         |                                                                    |
| Plugin             | CONTAINS         | ExtendedEntity       |                                                                    |
| Plugin             | DEFINES          | DomainConcept        |                                                                    |
| Plugin             | CONTAINS         | API                  |                                                                    |
| Plugin             | RUNS_IN          | IframeIsolation      |                                                                    |
| Plugin             | COMMUNICATES_VIA | HostBridge           |                                                                    |
| Manifest           | DECLARES         | ExtensionPoint       |                                                                    |
| Manifest           | DECLARES         | FilterDefinition     |                                                                    |
| Plugin             | EXPOSES          | ExtensionPoint       |                                                                    |
| ExtensionPoint     | IMPLEMENTED_BY   | PluginPage           | Iframe-rendered points only.                                       |
| ExtensionPoint     | RENDERED_ON      | CorePage             | menu.main on sidebar; product.detail.* on detail; filters on list. |
| PluginPage         | USES             | HostBridge           |                                                                    |
| PluginPage         | USES             | PluginSDK            |                                                                    |
| PluginSDK          | USES             | HostBridge           |                                                                    |
| HostBridge         | PROXIES_TO       | APIEndpoints         |                                                                    |
| FilterDefinition   | RENDERED_ON      | CorePage             |                                                                    |
| FilterDefinition   | QUERIES          | ExtendedEntity       | Resolves to JSONB query in plugin namespace.                       |
| PluginEntity       | STORED_VIA       | StorageStrategy      |                                                                    |
| ExtendedEntity     | STORED_VIA       | StorageStrategy      |                                                                    |
| ExtendedEntity     | EXTENDS          | Entity               | Plugin attributes on a host entity (Product).                      |
| StorageStrategy    | PERSISTED_IN     | Entity               | Maps to Product (JSONB) or PluginObject (collections).             |
| PluginEntity       | MAY_USE          | EntityBinding        |                                                                    |
| EntityBinding      | TARGETS          | Entity               |                                                                    |
| API                | USES             | APIEndpoints         |                                                                    |
| API                | USES             | ExternalSystem       |                                                                    |
| Feature            | PERFORMED_BY     | Actor                |                                                                    |
| Feature            | REALIZED_BY      | CorePage             |                                                                    |
| Feature            | REALIZED_BY      | PluginPage           |                                                                    |
| Feature            | DELIVERED_VIA    | ExtensionPoint       |                                                                    |
| Feature            | BACKED_BY        | Action               |                                                                    |

## Properties (per label)

Stable key on every instance node: `id` (string, indexed). Below are the typed attributes declared in the ontology — most also exist on the instance node.

- **System** — `name`, `groupId`, `artifactId`, `version`, `framework`
- **Host** — `name`, `entrypoint`, `port`
- **Frontend** — `name`, `path`, `language`, `framework`, `router`
- **Backend** — `name`, `rootPackage`, `language`, `framework`
- **Core** — `name`, `rootPackage`, `notes`
- **PluginEngine** — `name`, `rootPackage`, `services` (string[])
- **Module** — `name`, `package`
- **Entity** — `name`, `fqcn`, `table`
- **Repository** — `name`, `fqcn`, `kind` (`JpaRepository` | `jOOQ DSLContext`)
- **Action** — `name`, `kind` (enum: `query`, `command`)
- **APIEndpoints** — `method` (enum: GET/POST/PUT/PATCH/DELETE), `uri`, `handler`
- **CorePage** — `name`, `route`, `component`
- **PluginShell** — `name`, `entrypoint`, `notes`
- **Plugin** — `pluginId`, `name`, `version`, `url`, `description`, `enabled` (bool), `path`
- **Manifest** — `name`, `version`, `url`, `description`, `extensionPoints` (object[])
- **ExtensionPoint** — `type` (enum: `menu.main`, `product.detail.tabs`, `product.detail.info`, `product.list.filters`), `label`, `icon`, `path`, `priority`, `scope` (enum: `global`, `product`, `product-list`), `rendering` (enum: `plugin-iframe`, `host-native`)
- **FilterDefinition** — `filterKey`, `filterType` (enum: `boolean`, `string`, `number`), `label`, `priority`
- **PluginPage** — `name`, `route`, `component`, `extensionPoint`
- **PluginEntity** — `name`, `storage`
- **ExtendedEntity** — `name`, `storage`
- **StorageStrategy** — `kind` (enum: `namespaced-plugin-data`, `plugin-custom-object`), `location`, `scope` (enum: `per-entity`, `plugin-collection`)
- **EntityBinding** — `entityType` (enum: `PRODUCT`, `CATEGORY`), `entityId` (number)
- **IframeIsolation** — `sandboxFlags`, `originCheck`
- **HostBridge** — `operations` (string[]), `constraints`
- **PluginSDK** — `facades` (string[]: `hostApp`, `thisPlugin`), `contextFields` (string[])
- **Feature** — `name`, `owner` (enum: `host`, `plugin`), `scope` (enum: `catalog`, `plugin-management`, `product-detail`, `product-list`)
- **Actor** — `role`
- **API** — `name`, `kind` (enum: `sdk-host-bridge`, `backend-route`), `path`
- **ExternalSystem** — `name`, `kind` (enum: `RDBMS`, `LLM proxy`, `LLM provider`, `PII detection / redaction`, `LLM observability`)
- **DomainConcept** — `name` only.
