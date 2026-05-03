# AJ Knowledge Graph — Questions It Can Answer

Derived from `tools/seed/aj-kg-ontology.cypher`. Each question is answerable by traversing the entity types, properties, and relation rules declared in the ontology. Grouped by the three audiences the ontology calls out: **product owners (PO)**, **architects**, and **QA**.

---

## 1. System & platform overview

- What is the platform's display name, Maven groupId/artifactId and current version?
- Which framework powers the host?
- What are the parts of the System (host, plugins) and how are they composed?
- Which actor types interact with the system, and what role do they play?
- Which external systems does the platform depend on, and what role does each play (RDBMS, LLM proxy, LLM provider, PII redaction, LLM observability)?

## 2. Host architecture (architect)

- What does the Host contain (Frontend, Backend)?
- What is the host's boot class (entrypoint) and on which HTTP port does it listen?
- What is the root Java package of the Backend and which framework + language does it use?
- What are the Frontend's path, language, framework and router?
- Which cross-cutting concerns does Core provide (per `core.notes`)?
- Which services make up the Plugin Engine?
- Which modules does the Backend contain, and what is each module's Java package?

## 3. Modules, entities & persistence (architect)

- Which entities does each Module contain? (e.g. which entities live in the `product` module?)
- For a given Entity, what is its fully-qualified Java class and backing database table?
- Which Repository persists each Entity, and is it a JpaRepository or a jOOQ DSLContext?
- Which entities are managed by the Plugin Engine (PluginDescriptor, PluginObject)?
- Which entities can be extended by plugins (via `extended_entity__EXTENDS__entity`)?

## 4. Actions & API endpoints (architect / QA)

- What Actions does each Module expose, and which are queries vs. commands?
- Which Entity does each Action operate on?
- Which API Endpoint exposes a given Action (handler, HTTP method, URI)?
- List all API endpoints of the `product` module / `category` module / plugin module.
- Which endpoints exist under `/api/plugins`?
- Which endpoints are reached by the host frontend's core pages (`core_page__USES__api_endpoints`)?
- Which endpoints does the Host Bridge proxy to (i.e. which endpoints can plugins ultimately call through the SDK)?

## 5. Frontend pages & routing (PO / QA)

- Which CorePages does the Frontend contain, and what React Router route + component renders each?
- Which CorePage realizes a given Feature?
- Which extension points are rendered on which CorePage (e.g. `menu.main` on the sidebar, `product.detail.*` on the product detail page)?
- Where in the host UI is a given filter rendered?

## 6. Plugins & manifests (PO / architect)

- Which plugins are registered, and which are enabled vs. disabled?
- For each plugin: pluginId, display name, version, origin URL, repository path, description.
- What does each plugin's Manifest declare (extension points, filter definitions)?
- Which DomainConcepts does a plugin define (e.g. Warehouse, StockEntry, BoxDimensions, ProductDescription)?
- Which plugin pages does a plugin contain, and which extension point does each implement?
- Which plugins ship their own backend route (API kind = `backend-route`) vs. SDK-only?

## 7. Extension points (PO / QA)

- Which extension point types exist and what do they mean (`menu.main`, `product.detail.tabs`, `product.detail.info`, `product.list.filters`)?
- Which plugins contribute to a given extension point, in what priority order?
- Which extension points are iframe-rendered vs. host-native?
- For each extension point declaration: label, icon (menu.main only), path, scope.
- Which PluginPage implements each iframe-rendered extension point?

## 8. Filters (PO / QA)

- Which FilterDefinitions are declared by which plugin manifests?
- For each filter: filterKey, filterType (boolean / string / number), label, priority.
- Which ExtendedEntity is queried by a given filter (i.e. which plugin namespace inside `Product.pluginData`)?
- On which CorePage are the filters rendered?

## 9. Plugin data & storage strategies (architect)

- Which storage strategies exist (`namespaced-plugin-data` vs. `plugin-custom-object`) and where do their bytes live?
- Which scope does each storage strategy serve (`per-entity` vs. `plugin-collection`)?
- Which PluginEntities and which ExtendedEntities use each storage strategy?
- Which host Entity ultimately persists each storage strategy (Product for namespaced JSONB, PluginObject for custom collections)?
- For a given PluginEntity, what is its declared `storage` (e.g. `plugin_objects (type=warehouse)`)?

## 10. Entity bindings (architect / QA)

- Which PluginEntities may be bound to a host Entity via an EntityBinding?
- Which host entity types can be targeted by an EntityBinding (`PRODUCT`, `CATEGORY`)?
- Why is `(entityType, entityId)` always set together — what query patterns does it enable (e.g. `listByEntity`)?

## 11. Plugin runtime: isolation, bridge, SDK (architect / QA)

- What sandbox flags does PluginFrame apply to plugin iframes?
- How is the postMessage origin verified against the plugin's registered URL?
- Which operations does the Host Bridge accept (getProducts, getProduct, getPlugins, pluginFetch, getData/setData/removeData, objectsList, objectsListByEntity, objectsGet/Save/Delete, filterChange)?
- What constraints apply to `pluginFetch` (path scoping to `/api/`, credential stripping, traversal rejection, CORS-safelisted response headers)?
- Which facades does the Plugin SDK expose (`hostApp`, `thisPlugin`)?
- Which context fields does the host inject into every plugin (extensionPoint, pluginId, pluginName, hostOrigin, productId for product-scoped points)?
- Which API does each Plugin Page use — directly the Plugin SDK or the Host Bridge?

## 12. Features & actors (PO)

- What user-visible features does the platform deliver?
- For each feature: who owns it (host vs. plugin) and on what surface is it observable (catalog, plugin-management, product-detail, product-list)?
- Which actor performs each feature?
- Which CorePages and/or PluginPages realize a given feature?
- Which extension point delivers a given feature?
- Which Actions back a given feature?
- Which features are delivered entirely by plugins?

## 13. End-to-end traceability (multi-hop)

- For a given Feature, trace from actor → page → endpoint → action → entity → repository → table.
- For a given API endpoint, which feature(s) does it back, and which page(s) call it?
- For a given plugin, list every UI surface it contributes to and every backend endpoint it can reach.
- For a given Entity, list every Action that operates on it, every endpoint that exposes it, and every plugin that extends it.
- For a given Plugin, which storage strategies does it use and which host entities does it touch?
- Which plugins reach an external system, through which plugin-owned API, and to do what?

## 14. Schema/ontology introspection (architect)

- What EntityTypes exist and how is each described?
- What properties does a given EntityType have (name, kind, allowed values, description)?
- Which RelationTypes exist?
- What allowed `(source) -[type]-> (target)` triples are declared as RelationRules?
- Which relations can a given EntityType participate in (incoming and outgoing)?
- Which enums are declared, and what are their allowed values (e.g. `extension_point.type`, `feature.scope`, `storage_strategy.kind`, `entity_binding.entityType`, `api_endpoints.method`, `action.kind`, `api.kind`)?

---

## Sample Cypher recipes

```cypher
// All endpoints of a module
MATCH (m:Module)-[:CONTAINS]->(e:APIEndpoints)
WHERE toLower(m.name) CONTAINS $module
RETURN m.name, e.method, e.uri, e.handler
ORDER BY e.uri, e.method;

// Pages → endpoints they call
MATCH (p:CorePage)-[:USES]->(e:APIEndpoints)
RETURN p.name, p.route, collect({method:e.method, uri:e.uri}) AS calls;

// Plugin → extension points → host page where rendered
MATCH (pl:Plugin)-[:EXPOSES]->(ep:ExtensionPoint)-[:RENDERED_ON]->(cp:CorePage)
RETURN pl.pluginId, ep.type, ep.label, cp.name;

// Filters: plugin → filter → core page
MATCH (m:Manifest)-[:DECLARES]->(f:FilterDefinition)-[:RENDERED_ON]->(cp:CorePage)
RETURN m.name, f.filterKey, f.filterType, cp.name
ORDER BY f.priority;

// Plugin → storage strategy → underlying host entity
MATCH (pe:PluginEntity)-[:STORED_VIA]->(s:StorageStrategy)-[:PERSISTED_IN]->(en:Entity)
RETURN pe.name, s.kind, s.location, en.name;

// Feature traceability
MATCH (f:Feature)-[:BACKED_BY]->(a:Action)-[:OPERATES_ON]->(en:Entity),
      (a)<-[:EXPOSED_BY]-(ep:APIEndpoints)
OPTIONAL MATCH (f)-[:REALIZED_BY]->(pg)
RETURN f.name, f.owner, f.scope,
       collect(DISTINCT pg.name) AS pages,
       collect(DISTINCT ep.method + ' ' + ep.uri) AS endpoints,
       collect(DISTINCT en.name) AS entities;
```
