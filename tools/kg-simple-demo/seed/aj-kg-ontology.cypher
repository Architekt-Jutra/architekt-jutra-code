// =============================================================================
// AJ Platform — Knowledge Graph Ontology Layer
// Source: aj-kg-ontology.json
//
// Layer model
// -----------
//   Ontology layer (this file): the SCHEMA. Every node is also tagged :Ontology
//     :Ontology:EntityType    — concept (Plugin, Host, Module, …)
//     :Ontology:Property      — typed attribute owned by an EntityType
//     :Ontology:RelationType  — allowed relation kind (CONTAINS, USES, …)
//     :Ontology:RelationRule  — reified (source EntityType, RelationType,
//                                target EntityType) triple. Pinning rules
//                                this way preserves the source–target pairing
//                                that a plain RelationType node would lose.
//     :Ontology:OntologyDoc   — top-level metadata (title, description)
//
//   Instance layer (other files / aj-kg-seed.cypher): real data.
//     Instance nodes use entity-specific labels (:Plugin, :Host, …) and never
//     wear :Ontology, so the two layers never overlap.
//
// Edges (ontology layer)
// ----------------------
//     (EntityType)   -[:HAS_PROPERTY]->  (Property)
//     (RelationRule) -[:FROM]->          (EntityType)
//     (RelationRule) -[:HAS_TYPE]->      (RelationType)
//     (RelationRule) -[:TO]->            (EntityType)
//
// Idempotent: re-running the script is safe (MERGE on stable keys).
// =============================================================================

// -----------------------------------------------------------------------------
// 0. CONSTRAINTS
// -----------------------------------------------------------------------------
CREATE CONSTRAINT ontology_entity_type_name   IF NOT EXISTS FOR (n:EntityType)   REQUIRE n.name IS UNIQUE;
CREATE CONSTRAINT ontology_relation_type_name IF NOT EXISTS FOR (n:RelationType) REQUIRE n.name IS UNIQUE;
CREATE CONSTRAINT ontology_property_id        IF NOT EXISTS FOR (n:Property)     REQUIRE n.id   IS UNIQUE;
CREATE CONSTRAINT ontology_relation_rule_id   IF NOT EXISTS FOR (n:RelationRule) REQUIRE n.id   IS UNIQUE;
CREATE CONSTRAINT ontology_doc_id             IF NOT EXISTS FOR (n:OntologyDoc)  REQUIRE n.id   IS UNIQUE;

// -----------------------------------------------------------------------------
// 1. ONTOLOGY METADATA
// -----------------------------------------------------------------------------
MERGE (doc:Ontology:OntologyDoc {id: 'aj-kg-ontology'})
SET doc.title = 'Graf wiedzy',
    doc.description = 'Logical knowledge graph of the AJ platform — a microkernel where a host application (Spring Boot backend + React frontend) runs sandboxed third-party plugins that extend the product catalog UI and data model. Schema is intended to answer questions from product owners (what features exist, who can do what), architects (how host and plugins interact, what data each owns) and QA (what entry points, what extension contracts, what flows).';

// =============================================================================
// 2. ENTITY TYPES (concepts)
// =============================================================================

MERGE (et:Ontology:EntityType {name: 'system'})
SET et.label = 'System',
    et.description = 'Top-level deployable platform composed of one host application and one or more plugins.';

MERGE (et:Ontology:EntityType {name: 'host'})
SET et.label = 'Host',
    et.description = 'The core application that owns master data (products, categories), runs the plugin engine, exposes the public REST API and renders the user-facing UI shell.';

MERGE (et:Ontology:EntityType {name: 'frontend'})
SET et.label = 'Frontend',
    et.description = 'Single-page application bundled with the host. Renders core pages, hosts the plugin shell, and brokers plugin RPC calls to the backend API.';

MERGE (et:Ontology:EntityType {name: 'backend'})
SET et.label = 'Backend',
    et.description = 'Server-side of the host. Exposes REST endpoints under /api, persists data in PostgreSQL via JPA + jOOQ, and validates plugin manifests.';

MERGE (et:Ontology:EntityType {name: 'core'})
SET et.label = 'Core',
    et.description = 'Shared backend foundation: BaseEntity audit fields, JPA auditing config, central error handling and the plugin engine.';

MERGE (et:Ontology:EntityType {name: 'plugin_engine'})
SET et.label = 'Plugin engine',
    et.description = 'Backend services that register plugins from manifests, persist plugin descriptors, store per-product plugin data, and manage plugin-owned custom objects.';

MERGE (et:Ontology:EntityType {name: 'module'})
SET et.label = 'Module',
    et.description = 'A backend feature module that groups one or more host entities, their REST controller, services and persistence (e.g. category, product, plugin core).';

MERGE (et:Ontology:EntityType {name: 'entity'})
SET et.label = 'Entity',
    et.description = 'Host-owned domain entity persisted by the backend (e.g. Product, Category, PluginDescriptor, PluginObject). Identified by a database table and a fully qualified Java class.';

MERGE (et:Ontology:EntityType {name: 'repository'})
SET et.label = 'Repository',
    et.description = 'Persistence component that reads/writes an entity. Either a Spring Data JpaRepository for CRUD, or a Db*QueryService using jOOQ for complex queries (filtering, sorting, JSONB filters).';

MERGE (et:Ontology:EntityType {name: 'action'})
SET et.label = 'Action',
    et.description = 'A business operation exposed by the backend (a service method). May read or modify state. Each action is exposed by exactly one API endpoint and operates on one or more entities.';

MERGE (et:Ontology:EntityType {name: 'api_endpoints'})
SET et.label = 'API Endpoints',
    et.description = 'HTTP-facing entry points exposed by the host backend under /api. Drive both the host frontend and the plugin SDK proxy.';

MERGE (et:Ontology:EntityType {name: 'core_page'})
SET et.label = 'Core Page',
    et.description = 'A page of the host frontend (not contributed by a plugin). Implements core flows: product/category/plugin lists, detail and edit screens.';

MERGE (et:Ontology:EntityType {name: 'plugin_shell'})
SET et.label = 'Plugin shell',
    et.description = 'Host UI surface that loads plugin metadata, mounts plugin iframes for declared extension points and brokers postMessage RPC between plugin and host. Composed of AppShell + PluginContext + PluginFrame + iframeRegistry + PluginMessageHandler.';

MERGE (et:Ontology:EntityType {name: 'plugin'})
SET et.label = 'Plugin',
    et.description = 'A self-contained extension app served from its own URL. Registers itself with the host by uploading a manifest. Runs in a sandboxed iframe; can render UI at the extension points it declares and read/write its own data via the SDK.';

MERGE (et:Ontology:EntityType {name: 'manifest'})
SET et.label = 'Manifest',
    et.description = "Declarative JSON document a plugin uploads to PUT /api/plugins/{pluginId}/manifest. Single source of truth for the plugin's identity, base URL and the extension points it contributes. Validated by the host (non-blank name, HTTP(S) url, well-formed pluginId).";

MERGE (et:Ontology:EntityType {name: 'extension_point'})
SET et.label = 'Extension Point',
    et.description = 'A named UI surface in the host where plugins can contribute. Declared in the manifest and resolved at runtime by the plugin shell. The host supports four kinds: menu.main (sidebar entry rendered as a full-page plugin), product.detail.tabs (tab on the product detail screen), product.detail.info (compact badge below product details), product.list.filters (host-rendered control on the product list — no iframe needed).';

MERGE (et:Ontology:EntityType {name: 'filter_definition'})
SET et.label = 'Filter Definition',
    et.description = "Host-native product list filter declared by a plugin in its manifest. The host renders the control (switch / text / number) and translates it into a server-side JSONB query against the plugin's namespace in pluginData.";

MERGE (et:Ontology:EntityType {name: 'plugin_page'})
SET et.label = 'Plugin Page',
    et.description = 'A plugin-side page mounted into the host UI through an extension point. Receives a pluginId/pluginName/hostOrigin context (and productId for product-scoped points) injected via the iframe URL hash and window.name.';

MERGE (et:Ontology:EntityType {name: 'plugin_entity'})
SET et.label = 'PluginEntity',
    et.description = "A domain object owned entirely by a plugin (no host equivalent). Persisted as a row in the plugin_objects table or modeled in the plugin's own TypeScript types when no persistence is needed.";

MERGE (et:Ontology:EntityType {name: 'extended_entity'})
SET et.label = 'ExtendedEntity',
    et.description = 'Plugin data that extends a host entity (typically Product) without modifying its schema. Two storage strategies are used: namespaced JSONB on the host entity (Product.pluginData) for per-entity attributes, or plugin_objects rows bound to the entity via (entityType, entityId) for collections.';

MERGE (et:Ontology:EntityType {name: 'storage_strategy'})
SET et.label = 'Storage Strategy',
    et.description = 'One of the two ways a plugin can persist data through the host. (1) Per-entity namespaced JSONB: Product.pluginData[pluginId] = { ... } — suited for a small fixed set of attributes attached to a single host entity, queryable by FilterDefinition. (2) Plugin custom objects: rows in plugin_objects keyed by (pluginId, objectType, objectId), optionally bound to a host entity via (entityType, entityId) — suited for collections and many-to-one relationships.';

MERGE (et:Ontology:EntityType {name: 'entity_binding'})
SET et.label = 'Entity Binding',
    et.description = "Optional link from a plugin custom object to a host entity, expressed as (entityType, entityId) on plugin_objects. Enables server-side queries like 'all stock entries for product 42' and cross-type queries via listByEntity. Both fields must be set together or both omitted.";

MERGE (et:Ontology:EntityType {name: 'iframe_isolation'})
SET et.label = 'Iframe Isolation',
    et.description = "Security boundary around every plugin: the host mounts each plugin in a sandboxed iframe served from the plugin's own origin. The plugin cannot reach the host backend directly — all I/O goes through the postMessage host bridge, whose origin is verified against the registered plugin URL.";

MERGE (et:Ontology:EntityType {name: 'host_bridge'})
SET et.label = 'Host Bridge',
    et.description = 'PostMessage RPC channel between a plugin iframe and the host frontend. The plugin SDK exposes typed operations (hostApp.* and thisPlugin.*) that the bridge translates to host REST API calls. All requests are validated against the registered iframe (origin, source) before being forwarded.';

MERGE (et:Ontology:EntityType {name: 'plugin_sdk'})
SET et.label = 'Plugin SDK',
    et.description = 'TypeScript library served by the host at /assets/plugin-sdk.js and loaded by every plugin. Exposes window.PluginSDK with two facades: hostApp (read host data: products, plugins, raw /api fetch) and thisPlugin (plugin context, per-product getData/setData/removeData, and CRUD over plugin custom objects).';

MERGE (et:Ontology:EntityType {name: 'domain_concept'})
SET et.label = 'Domain Concept',
    et.description = 'Plugin-specific domain abstraction (TypeScript type) that names what the plugin manages. Examples in this codebase: Warehouse, StockEntry, BoxDimensions, ProductDescription. Used to translate raw PluginObject/JSONB rows into typed plugin data.';

MERGE (et:Ontology:EntityType {name: 'feature'})
SET et.label = 'Feature',
    et.description = 'A user-visible capability of the platform, derived from the union of host pages, host endpoints and plugin extension points. Examples: Manage Products, Manage Categories, Register & Toggle Plugins, Track Stock per Warehouse, Capture Box Dimensions, Generate AI Product Description.';

MERGE (et:Ontology:EntityType {name: 'actor'})
SET et.label = 'Actor',
    et.description = 'Type of user that interacts with the platform. The codebase exposes a single, anonymous catalog operator role — there is no authentication, authorization, or multi-tenant code. Captured here so QA/PO can reason about who does what.';

MERGE (et:Ontology:EntityType {name: 'api'})
SET et.label = 'API',
    et.description = "The contract a plugin uses to integrate with the host: most plugins are SDK-only (their integration surface is window.PluginSDK calls), and may also have their own backend route (e.g. ai-description's /api/generate that calls an external LLM proxy).";

MERGE (et:Ontology:EntityType {name: 'external_system'})
SET et.label = 'External System',
    et.description = 'A system the platform depends on but does not own. Includes the database (PostgreSQL) and outbound integrations used by plugins (LLM providers reached via a LiteLLM proxy that chains Presidio for PII redaction and Langfuse for observability).';

// =============================================================================
// 3. PROPERTIES (typed attributes per EntityType)
//    Property id = "{entityTypeName}.{propertyName}" — unique across schema.
//    Edge:  (EntityType) -[:HAS_PROPERTY]-> (Property)
// =============================================================================

// --- system ---
MERGE (p:Ontology:Property {id: 'system.name'})         SET p.name='name',       p.kind='string', p.description='Display name of the platform.';
MERGE (p:Ontology:Property {id: 'system.groupId'})      SET p.name='groupId',    p.kind='string', p.description='Maven groupId of the host.';
MERGE (p:Ontology:Property {id: 'system.artifactId'})   SET p.name='artifactId', p.kind='string', p.description='Maven artifactId of the host.';
MERGE (p:Ontology:Property {id: 'system.version'})      SET p.name='version',    p.kind='string', p.description='Build version of the host.';
MERGE (p:Ontology:Property {id: 'system.framework'})    SET p.name='framework',  p.kind='string', p.description='Primary framework powering the host (e.g. Spring Boot).';
MATCH (et:EntityType {name: 'system'}), (p:Property) WHERE p.id STARTS WITH 'system.' MERGE (et)-[:HAS_PROPERTY]->(p);

// --- host ---
MERGE (p:Ontology:Property {id: 'host.name'})       SET p.name='name',       p.kind='string', p.description='Display name of the host application.';
MERGE (p:Ontology:Property {id: 'host.entrypoint'}) SET p.name='entrypoint', p.kind='string', p.description='Backend boot class (e.g. AjApplication).';
MERGE (p:Ontology:Property {id: 'host.port'})       SET p.name='port',       p.kind='number', p.description='HTTP port the host listens on.';
MATCH (et:EntityType {name: 'host'}), (p:Property) WHERE p.id STARTS WITH 'host.' MERGE (et)-[:HAS_PROPERTY]->(p);

// --- frontend ---
MERGE (p:Ontology:Property {id: 'frontend.name'})      SET p.name='name',      p.kind='string', p.description='Display name of the frontend module.';
MERGE (p:Ontology:Property {id: 'frontend.path'})      SET p.name='path',      p.kind='string', p.description='Source location of the frontend (e.g. src/main/frontend).';
MERGE (p:Ontology:Property {id: 'frontend.language'})  SET p.name='language',  p.kind='string', p.description='Primary language (TypeScript).';
MERGE (p:Ontology:Property {id: 'frontend.framework'}) SET p.name='framework', p.kind='string', p.description='UI framework (React + Vite).';
MERGE (p:Ontology:Property {id: 'frontend.router'})    SET p.name='router',    p.kind='string', p.description='Routing library used (React Router).';
MATCH (et:EntityType {name: 'frontend'}), (p:Property) WHERE p.id STARTS WITH 'frontend.' MERGE (et)-[:HAS_PROPERTY]->(p);

// --- backend ---
MERGE (p:Ontology:Property {id: 'backend.name'})        SET p.name='name',        p.kind='string';
MERGE (p:Ontology:Property {id: 'backend.rootPackage'}) SET p.name='rootPackage', p.kind='string', p.description='Root Java package of the backend.';
MERGE (p:Ontology:Property {id: 'backend.language'})    SET p.name='language',    p.kind='string';
MERGE (p:Ontology:Property {id: 'backend.framework'})   SET p.name='framework',   p.kind='string';
MATCH (et:EntityType {name: 'backend'}), (p:Property) WHERE p.id STARTS WITH 'backend.' MERGE (et)-[:HAS_PROPERTY]->(p);

// --- core ---
MERGE (p:Ontology:Property {id: 'core.name'})        SET p.name='name',        p.kind='string';
MERGE (p:Ontology:Property {id: 'core.rootPackage'}) SET p.name='rootPackage', p.kind='string';
MERGE (p:Ontology:Property {id: 'core.notes'})       SET p.name='notes',       p.kind='string', p.description='Cross-cutting concerns provided by core.';
MATCH (et:EntityType {name: 'core'}), (p:Property) WHERE p.id STARTS WITH 'core.' MERGE (et)-[:HAS_PROPERTY]->(p);

// --- plugin_engine ---
MERGE (p:Ontology:Property {id: 'plugin_engine.name'})        SET p.name='name',        p.kind='string';
MERGE (p:Ontology:Property {id: 'plugin_engine.rootPackage'}) SET p.name='rootPackage', p.kind='string';
MERGE (p:Ontology:Property {id: 'plugin_engine.services'})    SET p.name='services',    p.kind='string[]', p.description='Service classes that implement the engine: PluginDescriptorService, PluginObjectService, PluginDataService, DbPluginObjectQueryService.';
MATCH (et:EntityType {name: 'plugin_engine'}), (p:Property) WHERE p.id STARTS WITH 'plugin_engine.' MERGE (et)-[:HAS_PROPERTY]->(p);

// --- module ---
MERGE (p:Ontology:Property {id: 'module.name'})    SET p.name='name',    p.kind='string';
MERGE (p:Ontology:Property {id: 'module.package'}) SET p.name='package', p.kind='string', p.description="Java package containing the module's classes.";
MATCH (et:EntityType {name: 'module'}), (p:Property) WHERE p.id STARTS WITH 'module.' MERGE (et)-[:HAS_PROPERTY]->(p);

// --- entity ---
MERGE (p:Ontology:Property {id: 'entity.name'})  SET p.name='name',  p.kind='string', p.description='Domain name (Product, Category, ...).';
MERGE (p:Ontology:Property {id: 'entity.fqcn'})  SET p.name='fqcn',  p.kind='string', p.description='Fully qualified Java class name.';
MERGE (p:Ontology:Property {id: 'entity.table'}) SET p.name='table', p.kind='string', p.description='Backing database table.';
MATCH (et:EntityType {name: 'entity'}), (p:Property) WHERE p.id STARTS WITH 'entity.' MERGE (et)-[:HAS_PROPERTY]->(p);

// --- repository ---
MERGE (p:Ontology:Property {id: 'repository.name'}) SET p.name='name', p.kind='string';
MERGE (p:Ontology:Property {id: 'repository.fqcn'}) SET p.name='fqcn', p.kind='string';
MERGE (p:Ontology:Property {id: 'repository.kind'}) SET p.name='kind', p.kind='string', p.description="Implementation flavor: 'JpaRepository' or 'jOOQ DSLContext'.";
MATCH (et:EntityType {name: 'repository'}), (p:Property) WHERE p.id STARTS WITH 'repository.' MERGE (et)-[:HAS_PROPERTY]->(p);

// --- action ---
MERGE (p:Ontology:Property {id: 'action.name'}) SET p.name='name', p.kind='string', p.description='Service method (e.g. ProductService.findAll).';
MERGE (p:Ontology:Property {id: 'action.kind'}) SET p.name='kind', p.kind='enum',   p.description='query | command — read-only vs. state-changing.', p.values=['query','command'];
MATCH (et:EntityType {name: 'action'}), (p:Property) WHERE p.id STARTS WITH 'action.' MERGE (et)-[:HAS_PROPERTY]->(p);

// --- api_endpoints ---
MERGE (p:Ontology:Property {id: 'api_endpoints.method'})  SET p.name='method',  p.kind='enum',   p.description='HTTP verb.', p.values=['GET','POST','PUT','PATCH','DELETE'];
MERGE (p:Ontology:Property {id: 'api_endpoints.uri'})     SET p.name='uri',     p.kind='string', p.description='Path template, e.g. /api/products/{id}.';
MERGE (p:Ontology:Property {id: 'api_endpoints.handler'}) SET p.name='handler', p.kind='string', p.description='Controller method that handles the request.';
MATCH (et:EntityType {name: 'api_endpoints'}), (p:Property) WHERE p.id STARTS WITH 'api_endpoints.' MERGE (et)-[:HAS_PROPERTY]->(p);

// --- core_page ---
MERGE (p:Ontology:Property {id: 'core_page.name'})      SET p.name='name',      p.kind='string';
MERGE (p:Ontology:Property {id: 'core_page.route'})     SET p.name='route',     p.kind='string', p.description='React Router path.';
MERGE (p:Ontology:Property {id: 'core_page.component'}) SET p.name='component', p.kind='string', p.description='React component that renders the page.';
MATCH (et:EntityType {name: 'core_page'}), (p:Property) WHERE p.id STARTS WITH 'core_page.' MERGE (et)-[:HAS_PROPERTY]->(p);

// --- plugin_shell ---
MERGE (p:Ontology:Property {id: 'plugin_shell.name'})       SET p.name='name',       p.kind='string';
MERGE (p:Ontology:Property {id: 'plugin_shell.entrypoint'}) SET p.name='entrypoint', p.kind='string', p.description='Frontend bootstrap file (main.tsx).';
MERGE (p:Ontology:Property {id: 'plugin_shell.notes'})      SET p.name='notes',      p.kind='string', p.description='Components that make up the shell.';
MATCH (et:EntityType {name: 'plugin_shell'}), (p:Property) WHERE p.id STARTS WITH 'plugin_shell.' MERGE (et)-[:HAS_PROPERTY]->(p);

// --- plugin ---
MERGE (p:Ontology:Property {id: 'plugin.pluginId'})    SET p.name='pluginId',    p.kind='string',  p.description='Stable identifier (matches ^[a-zA-Z0-9_-]+$).';
MERGE (p:Ontology:Property {id: 'plugin.name'})        SET p.name='name',        p.kind='string',  p.description='Display name from the manifest.';
MERGE (p:Ontology:Property {id: 'plugin.version'})     SET p.name='version',     p.kind='string';
MERGE (p:Ontology:Property {id: 'plugin.url'})         SET p.name='url',         p.kind='string',  p.description='Origin where the plugin is served (must be HTTP/HTTPS).';
MERGE (p:Ontology:Property {id: 'plugin.description'}) SET p.name='description', p.kind='string';
MERGE (p:Ontology:Property {id: 'plugin.enabled'})     SET p.name='enabled',     p.kind='boolean', p.description='Disabled plugins are hidden from the UI and rejected by data/object endpoints.';
MERGE (p:Ontology:Property {id: 'plugin.path'})        SET p.name='path',        p.kind='string',  p.description='Repository path (plugins/<id>).';
MATCH (et:EntityType {name: 'plugin'}), (p:Property) WHERE p.id STARTS WITH 'plugin.' AND NOT p.id STARTS WITH 'plugin_' MERGE (et)-[:HAS_PROPERTY]->(p);

// --- manifest ---
MERGE (p:Ontology:Property {id: 'manifest.name'})            SET p.name='name',            p.kind='string',   p.description='Required, non-blank.';
MERGE (p:Ontology:Property {id: 'manifest.version'})         SET p.name='version',         p.kind='string';
MERGE (p:Ontology:Property {id: 'manifest.url'})             SET p.name='url',             p.kind='string',   p.description='Plugin origin (http:// or https:// only).';
MERGE (p:Ontology:Property {id: 'manifest.description'})     SET p.name='description',     p.kind='string';
MERGE (p:Ontology:Property {id: 'manifest.extensionPoints'}) SET p.name='extensionPoints', p.kind='object[]', p.description='List of extension point declarations (see ExtensionPoint).';
MATCH (et:EntityType {name: 'manifest'}), (p:Property) WHERE p.id STARTS WITH 'manifest.' MERGE (et)-[:HAS_PROPERTY]->(p);

// --- extension_point ---
MERGE (p:Ontology:Property {id: 'extension_point.type'})      SET p.name='type',      p.kind='enum',   p.description='Extension point identifier.', p.values=['menu.main','product.detail.tabs','product.detail.info','product.list.filters'];
MERGE (p:Ontology:Property {id: 'extension_point.label'})     SET p.name='label',     p.kind='string', p.description='Human label shown in the UI.';
MERGE (p:Ontology:Property {id: 'extension_point.icon'})      SET p.name='icon',      p.kind='string', p.description='Lucide icon name (menu.main only).';
MERGE (p:Ontology:Property {id: 'extension_point.path'})      SET p.name='path',      p.kind='string', p.description="Sub-path on the plugin's origin to mount (iframe-rendered points only).";
MERGE (p:Ontology:Property {id: 'extension_point.priority'})  SET p.name='priority',  p.kind='number', p.description='Sort order — lower comes first.';
MERGE (p:Ontology:Property {id: 'extension_point.scope'})     SET p.name='scope',     p.kind='enum',   p.description='Logical scope where the contribution applies.', p.values=['global','product','product-list'];
MERGE (p:Ontology:Property {id: 'extension_point.rendering'}) SET p.name='rendering', p.kind='enum',   p.description='Whether the host renders it natively or mounts a plugin iframe.', p.values=['plugin-iframe','host-native'];
MATCH (et:EntityType {name: 'extension_point'}), (p:Property) WHERE p.id STARTS WITH 'extension_point.' MERGE (et)-[:HAS_PROPERTY]->(p);

// --- filter_definition ---
MERGE (p:Ontology:Property {id: 'filter_definition.filterKey'})  SET p.name='filterKey',  p.kind='string', p.description="JSONB key in the plugin's pluginData namespace (e.g. 'stock').";
MERGE (p:Ontology:Property {id: 'filter_definition.filterType'}) SET p.name='filterType', p.kind='enum',   p.description='UI control + query operator.', p.values=['boolean','string','number'];
MERGE (p:Ontology:Property {id: 'filter_definition.label'})      SET p.name='label',      p.kind='string';
MERGE (p:Ontology:Property {id: 'filter_definition.priority'})   SET p.name='priority',   p.kind='number';
MATCH (et:EntityType {name: 'filter_definition'}), (p:Property) WHERE p.id STARTS WITH 'filter_definition.' MERGE (et)-[:HAS_PROPERTY]->(p);

// --- plugin_page ---
MERGE (p:Ontology:Property {id: 'plugin_page.name'})           SET p.name='name',           p.kind='string';
MERGE (p:Ontology:Property {id: 'plugin_page.route'})          SET p.name='route',          p.kind='string', p.description='Plugin-side route (matches manifest path).';
MERGE (p:Ontology:Property {id: 'plugin_page.component'})      SET p.name='component',      p.kind='string', p.description='React component that renders the page.';
MERGE (p:Ontology:Property {id: 'plugin_page.extensionPoint'}) SET p.name='extensionPoint', p.kind='string', p.description='Extension point type this page implements.';
MATCH (et:EntityType {name: 'plugin_page'}), (p:Property) WHERE p.id STARTS WITH 'plugin_page.' MERGE (et)-[:HAS_PROPERTY]->(p);

// --- plugin_entity ---
MERGE (p:Ontology:Property {id: 'plugin_entity.name'})    SET p.name='name',    p.kind='string', p.description='Domain name (e.g. Warehouse, BoxDimensions, ProductDescription).';
MERGE (p:Ontology:Property {id: 'plugin_entity.storage'}) SET p.name='storage', p.kind='string', p.description="How instances are persisted (e.g. 'plugin_objects (type=warehouse)').";
MATCH (et:EntityType {name: 'plugin_entity'}), (p:Property) WHERE p.id STARTS WITH 'plugin_entity.' MERGE (et)-[:HAS_PROPERTY]->(p);

// --- extended_entity ---
MERGE (p:Ontology:Property {id: 'extended_entity.name'})    SET p.name='name',    p.kind='string';
MERGE (p:Ontology:Property {id: 'extended_entity.storage'}) SET p.name='storage', p.kind='string', p.description='Storage strategy used (per-entity JSONB vs bound plugin_objects row).';
MATCH (et:EntityType {name: 'extended_entity'}), (p:Property) WHERE p.id STARTS WITH 'extended_entity.' MERGE (et)-[:HAS_PROPERTY]->(p);

// --- storage_strategy ---
MERGE (p:Ontology:Property {id: 'storage_strategy.kind'})     SET p.name='kind',     p.kind='enum',   p.description='Which mechanism the strategy refers to.', p.values=['namespaced-plugin-data','plugin-custom-object'];
MERGE (p:Ontology:Property {id: 'storage_strategy.location'}) SET p.name='location', p.kind='string', p.description="Where bytes live (e.g. 'products.plugin_data JSONB' or 'plugin_objects table').";
MERGE (p:Ontology:Property {id: 'storage_strategy.scope'})    SET p.name='scope',    p.kind='enum',   p.description='Logical scope.', p.values=['per-entity','plugin-collection'];
MATCH (et:EntityType {name: 'storage_strategy'}), (p:Property) WHERE p.id STARTS WITH 'storage_strategy.' MERGE (et)-[:HAS_PROPERTY]->(p);

// --- entity_binding ---
MERGE (p:Ontology:Property {id: 'entity_binding.entityType'}) SET p.name='entityType', p.kind='enum',   p.description='Host entity kind the object is bound to.', p.values=['PRODUCT','CATEGORY'];
MERGE (p:Ontology:Property {id: 'entity_binding.entityId'})   SET p.name='entityId',   p.kind='number', p.description='Primary key of the bound host entity.';
MATCH (et:EntityType {name: 'entity_binding'}), (p:Property) WHERE p.id STARTS WITH 'entity_binding.' MERGE (et)-[:HAS_PROPERTY]->(p);

// --- iframe_isolation ---
MERGE (p:Ontology:Property {id: 'iframe_isolation.sandboxFlags'}) SET p.name='sandboxFlags', p.kind='string', p.description='iframe sandbox attribute used by PluginFrame (allow-scripts allow-same-origin allow-forms allow-popups allow-modals allow-downloads).';
MERGE (p:Ontology:Property {id: 'iframe_isolation.originCheck'})  SET p.name='originCheck',  p.kind='string', p.description="Postmessage origin must match the plugin's registered URL origin; otherwise the message is dropped.";
MATCH (et:EntityType {name: 'iframe_isolation'}), (p:Property) WHERE p.id STARTS WITH 'iframe_isolation.' MERGE (et)-[:HAS_PROPERTY]->(p);

// --- host_bridge ---
MERGE (p:Ontology:Property {id: 'host_bridge.operations'})  SET p.name='operations',  p.kind='string[]', p.description='Message types the bridge accepts: getProducts, getProduct, getPlugins, pluginFetch, getData, setData, removeData, objectsList, objectsListByEntity, objectsGet, objectsSave, objectsDelete, filterChange.';
MERGE (p:Ontology:Property {id: 'host_bridge.constraints'}) SET p.name='constraints', p.kind='string',   p.description='pluginFetch is restricted to /api/ paths, strips credentials, rejects path traversal, and only returns CORS-safelisted response headers.';
MATCH (et:EntityType {name: 'host_bridge'}), (p:Property) WHERE p.id STARTS WITH 'host_bridge.' MERGE (et)-[:HAS_PROPERTY]->(p);

// --- plugin_sdk ---
MERGE (p:Ontology:Property {id: 'plugin_sdk.facades'})       SET p.name='facades',       p.kind='string[]', p.description='Top-level facades exposed to plugin code.', p.values=['hostApp','thisPlugin'];
MERGE (p:Ontology:Property {id: 'plugin_sdk.contextFields'}) SET p.name='contextFields', p.kind='string[]', p.description='Fields injected by the host into every plugin: extensionPoint, pluginId, pluginName, hostOrigin, productId (product-scoped only).';
MATCH (et:EntityType {name: 'plugin_sdk'}), (p:Property) WHERE p.id STARTS WITH 'plugin_sdk.' MERGE (et)-[:HAS_PROPERTY]->(p);

// --- domain_concept --- (no properties declared)

// --- feature ---
MERGE (p:Ontology:Property {id: 'feature.name'})  SET p.name='name',  p.kind='string';
MERGE (p:Ontology:Property {id: 'feature.owner'}) SET p.name='owner', p.kind='enum',   p.description='Who delivers the feature.', p.values=['host','plugin'];
MERGE (p:Ontology:Property {id: 'feature.scope'}) SET p.name='scope', p.kind='enum',   p.description='Surface where the feature is observable.', p.values=['catalog','plugin-management','product-detail','product-list'];
MATCH (et:EntityType {name: 'feature'}), (p:Property) WHERE p.id STARTS WITH 'feature.' MERGE (et)-[:HAS_PROPERTY]->(p);

// --- actor ---
MERGE (p:Ontology:Property {id: 'actor.role'}) SET p.name='role', p.kind='string', p.description='Operator role (single role today).';
MATCH (et:EntityType {name: 'actor'}), (p:Property) WHERE p.id STARTS WITH 'actor.' MERGE (et)-[:HAS_PROPERTY]->(p);

// --- api ---
MERGE (p:Ontology:Property {id: 'api.name'}) SET p.name='name', p.kind='string';
MERGE (p:Ontology:Property {id: 'api.kind'}) SET p.name='kind', p.kind='enum',   p.description='How the plugin reaches outside its iframe.', p.values=['sdk-host-bridge','backend-route'];
MERGE (p:Ontology:Property {id: 'api.path'}) SET p.name='path', p.kind='string', p.description='Backend route source path, when kind = backend-route.';
MATCH (et:EntityType {name: 'api'}), (p:Property) WHERE p.id STARTS WITH 'api.' AND NOT p.id STARTS WITH 'api_' MERGE (et)-[:HAS_PROPERTY]->(p);

// --- external_system ---
MERGE (p:Ontology:Property {id: 'external_system.name'}) SET p.name='name', p.kind='string';
MERGE (p:Ontology:Property {id: 'external_system.kind'}) SET p.name='kind', p.kind='enum', p.description='Role of the external system.', p.values=['RDBMS','LLM proxy','LLM provider','PII detection / redaction','LLM observability'];
MATCH (et:EntityType {name: 'external_system'}), (p:Property) WHERE p.id STARTS WITH 'external_system.' MERGE (et)-[:HAS_PROPERTY]->(p);

// =============================================================================
// 4. RELATION TYPES (allowed kinds of relations between EntityTypes)
//    Stored as nodes so they can be discovered, annotated, and connected to
//    the EntityTypes they pair via :RelationRule reification (section 5).
// =============================================================================
MERGE (rt:Ontology:RelationType {name: 'CONTAINS'})         SET rt.label = 'Contains';
MERGE (rt:Ontology:RelationType {name: 'USES'})             SET rt.label = 'Uses';
MERGE (rt:Ontology:RelationType {name: 'EMBEDS'})           SET rt.label = 'Embeds';
MERGE (rt:Ontology:RelationType {name: 'MANAGES'})          SET rt.label = 'Manages';
MERGE (rt:Ontology:RelationType {name: 'REGISTERS'})        SET rt.label = 'Registers';
MERGE (rt:Ontology:RelationType {name: 'OPERATES_ON'})      SET rt.label = 'Operates on';
MERGE (rt:Ontology:RelationType {name: 'EXPOSED_BY'})       SET rt.label = 'Exposed by';
MERGE (rt:Ontology:RelationType {name: 'PERSISTED_BY'})     SET rt.label = 'Persisted by';
MERGE (rt:Ontology:RelationType {name: 'DECLARES'})         SET rt.label = 'Declares';
MERGE (rt:Ontology:RelationType {name: 'DEFINES'})          SET rt.label = 'Defines';
MERGE (rt:Ontology:RelationType {name: 'RUNS_IN'})          SET rt.label = 'Runs in';
MERGE (rt:Ontology:RelationType {name: 'COMMUNICATES_VIA'}) SET rt.label = 'Communicates via';
MERGE (rt:Ontology:RelationType {name: 'EXPOSES'})          SET rt.label = 'Exposes';
MERGE (rt:Ontology:RelationType {name: 'IMPLEMENTED_BY'})   SET rt.label = 'Implemented by';
MERGE (rt:Ontology:RelationType {name: 'RENDERED_ON'})      SET rt.label = 'Rendered on';
MERGE (rt:Ontology:RelationType {name: 'PROXIES_TO'})       SET rt.label = 'Proxies to';
MERGE (rt:Ontology:RelationType {name: 'QUERIES'})          SET rt.label = 'Queries';
MERGE (rt:Ontology:RelationType {name: 'STORED_VIA'})       SET rt.label = 'Stored via';
MERGE (rt:Ontology:RelationType {name: 'EXTENDS'})          SET rt.label = 'Extends';
MERGE (rt:Ontology:RelationType {name: 'PERSISTED_IN'})     SET rt.label = 'Persisted in';
MERGE (rt:Ontology:RelationType {name: 'MAY_USE'})          SET rt.label = 'May use';
MERGE (rt:Ontology:RelationType {name: 'TARGETS'})          SET rt.label = 'Targets';
MERGE (rt:Ontology:RelationType {name: 'PERFORMED_BY'})     SET rt.label = 'Performed by';
MERGE (rt:Ontology:RelationType {name: 'REALIZED_BY'})      SET rt.label = 'Realized by';
MERGE (rt:Ontology:RelationType {name: 'DELIVERED_VIA'})    SET rt.label = 'Delivered via';
MERGE (rt:Ontology:RelationType {name: 'BACKED_BY'})        SET rt.label = 'Backed by';

// =============================================================================
// 5. RELATION RULES (reified triples: source EntityType, RelationType, target EntityType)
//    Each rule says "instances of <source> may be linked to instances of <target>
//    by a relationship of kind <type>." The instance layer materializes these
//    as actual Neo4j relationships (e.g. (:Plugin)-[:CONTAINS]->(:PluginPage)).
//    Rule id format: "<sourceName>__<TYPE>__<targetName>"
// =============================================================================

// --- system / actor ---
MERGE (r:Ontology:RelationRule {id: 'system__CONTAINS__host'});
MATCH (r:RelationRule {id: 'system__CONTAINS__host'}),
      (s:EntityType {name: 'system'}), (t:EntityType {name: 'host'}),
      (rt:RelationType {name: 'CONTAINS'})
MERGE (r)-[:FROM]->(s) MERGE (r)-[:HAS_TYPE]->(rt) MERGE (r)-[:TO]->(t);

MERGE (r:Ontology:RelationRule {id: 'system__CONTAINS__plugin'});
MATCH (r:RelationRule {id: 'system__CONTAINS__plugin'}),
      (s:EntityType {name: 'system'}), (t:EntityType {name: 'plugin'}),
      (rt:RelationType {name: 'CONTAINS'})
MERGE (r)-[:FROM]->(s) MERGE (r)-[:HAS_TYPE]->(rt) MERGE (r)-[:TO]->(t);

MERGE (r:Ontology:RelationRule {id: 'actor__USES__system'})
SET r.description = 'Catalog operator drives the system through the host UI.';
MATCH (r:RelationRule {id: 'actor__USES__system'}),
      (s:EntityType {name: 'actor'}), (t:EntityType {name: 'system'}),
      (rt:RelationType {name: 'USES'})
MERGE (r)-[:FROM]->(s) MERGE (r)-[:HAS_TYPE]->(rt) MERGE (r)-[:TO]->(t);

// --- host -> frontend / backend ---
MERGE (r:Ontology:RelationRule {id: 'host__CONTAINS__frontend'});
MATCH (r:RelationRule {id: 'host__CONTAINS__frontend'}),
      (s:EntityType {name: 'host'}), (t:EntityType {name: 'frontend'}),
      (rt:RelationType {name: 'CONTAINS'})
MERGE (r)-[:FROM]->(s) MERGE (r)-[:HAS_TYPE]->(rt) MERGE (r)-[:TO]->(t);

MERGE (r:Ontology:RelationRule {id: 'host__CONTAINS__backend'});
MATCH (r:RelationRule {id: 'host__CONTAINS__backend'}),
      (s:EntityType {name: 'host'}), (t:EntityType {name: 'backend'}),
      (rt:RelationType {name: 'CONTAINS'})
MERGE (r)-[:FROM]->(s) MERGE (r)-[:HAS_TYPE]->(rt) MERGE (r)-[:TO]->(t);

// --- frontend ---
MERGE (r:Ontology:RelationRule {id: 'frontend__CONTAINS__core_page'});
MATCH (r:RelationRule {id: 'frontend__CONTAINS__core_page'}),
      (s:EntityType {name: 'frontend'}), (t:EntityType {name: 'core_page'}),
      (rt:RelationType {name: 'CONTAINS'})
MERGE (r)-[:FROM]->(s) MERGE (r)-[:HAS_TYPE]->(rt) MERGE (r)-[:TO]->(t);

MERGE (r:Ontology:RelationRule {id: 'frontend__CONTAINS__plugin_shell'});
MATCH (r:RelationRule {id: 'frontend__CONTAINS__plugin_shell'}),
      (s:EntityType {name: 'frontend'}), (t:EntityType {name: 'plugin_shell'}),
      (rt:RelationType {name: 'CONTAINS'})
MERGE (r)-[:FROM]->(s) MERGE (r)-[:HAS_TYPE]->(rt) MERGE (r)-[:TO]->(t);

MERGE (r:Ontology:RelationRule {id: 'frontend__EMBEDS__plugin'})
SET r.description = 'Frontend mounts each registered plugin via the plugin shell.';
MATCH (r:RelationRule {id: 'frontend__EMBEDS__plugin'}),
      (s:EntityType {name: 'frontend'}), (t:EntityType {name: 'plugin'}),
      (rt:RelationType {name: 'EMBEDS'})
MERGE (r)-[:FROM]->(s) MERGE (r)-[:HAS_TYPE]->(rt) MERGE (r)-[:TO]->(t);

// --- backend ---
MERGE (r:Ontology:RelationRule {id: 'backend__CONTAINS__core'});
MATCH (r:RelationRule {id: 'backend__CONTAINS__core'}),
      (s:EntityType {name: 'backend'}), (t:EntityType {name: 'core'}),
      (rt:RelationType {name: 'CONTAINS'})
MERGE (r)-[:FROM]->(s) MERGE (r)-[:HAS_TYPE]->(rt) MERGE (r)-[:TO]->(t);

MERGE (r:Ontology:RelationRule {id: 'backend__CONTAINS__module'});
MATCH (r:RelationRule {id: 'backend__CONTAINS__module'}),
      (s:EntityType {name: 'backend'}), (t:EntityType {name: 'module'}),
      (rt:RelationType {name: 'CONTAINS'})
MERGE (r)-[:FROM]->(s) MERGE (r)-[:HAS_TYPE]->(rt) MERGE (r)-[:TO]->(t);

MERGE (r:Ontology:RelationRule {id: 'backend__USES__external_system'})
SET r.description = 'Backend persists data in PostgreSQL.';
MATCH (r:RelationRule {id: 'backend__USES__external_system'}),
      (s:EntityType {name: 'backend'}), (t:EntityType {name: 'external_system'}),
      (rt:RelationType {name: 'USES'})
MERGE (r)-[:FROM]->(s) MERGE (r)-[:HAS_TYPE]->(rt) MERGE (r)-[:TO]->(t);

// --- core / plugin_engine ---
MERGE (r:Ontology:RelationRule {id: 'core__CONTAINS__plugin_engine'});
MATCH (r:RelationRule {id: 'core__CONTAINS__plugin_engine'}),
      (s:EntityType {name: 'core'}), (t:EntityType {name: 'plugin_engine'}),
      (rt:RelationType {name: 'CONTAINS'})
MERGE (r)-[:FROM]->(s) MERGE (r)-[:HAS_TYPE]->(rt) MERGE (r)-[:TO]->(t);

MERGE (r:Ontology:RelationRule {id: 'plugin_engine__MANAGES__entity'})
SET r.description = 'Plugin engine owns the PluginDescriptor and PluginObject entities.';
MATCH (r:RelationRule {id: 'plugin_engine__MANAGES__entity'}),
      (s:EntityType {name: 'plugin_engine'}), (t:EntityType {name: 'entity'}),
      (rt:RelationType {name: 'MANAGES'})
MERGE (r)-[:FROM]->(s) MERGE (r)-[:HAS_TYPE]->(rt) MERGE (r)-[:TO]->(t);

MERGE (r:Ontology:RelationRule {id: 'plugin_engine__REGISTERS__plugin'})
SET r.description = 'Validates and persists plugin manifests; toggles enabled state.';
MATCH (r:RelationRule {id: 'plugin_engine__REGISTERS__plugin'}),
      (s:EntityType {name: 'plugin_engine'}), (t:EntityType {name: 'plugin'}),
      (rt:RelationType {name: 'REGISTERS'})
MERGE (r)-[:FROM]->(s) MERGE (r)-[:HAS_TYPE]->(rt) MERGE (r)-[:TO]->(t);

// --- module ---
MERGE (r:Ontology:RelationRule {id: 'module__CONTAINS__action'});
MATCH (r:RelationRule {id: 'module__CONTAINS__action'}),
      (s:EntityType {name: 'module'}), (t:EntityType {name: 'action'}),
      (rt:RelationType {name: 'CONTAINS'})
MERGE (r)-[:FROM]->(s) MERGE (r)-[:HAS_TYPE]->(rt) MERGE (r)-[:TO]->(t);

MERGE (r:Ontology:RelationRule {id: 'module__CONTAINS__entity'});
MATCH (r:RelationRule {id: 'module__CONTAINS__entity'}),
      (s:EntityType {name: 'module'}), (t:EntityType {name: 'entity'}),
      (rt:RelationType {name: 'CONTAINS'})
MERGE (r)-[:FROM]->(s) MERGE (r)-[:HAS_TYPE]->(rt) MERGE (r)-[:TO]->(t);

MERGE (r:Ontology:RelationRule {id: 'module__CONTAINS__api_endpoints'});
MATCH (r:RelationRule {id: 'module__CONTAINS__api_endpoints'}),
      (s:EntityType {name: 'module'}), (t:EntityType {name: 'api_endpoints'}),
      (rt:RelationType {name: 'CONTAINS'})
MERGE (r)-[:FROM]->(s) MERGE (r)-[:HAS_TYPE]->(rt) MERGE (r)-[:TO]->(t);

// --- action ---
MERGE (r:Ontology:RelationRule {id: 'action__OPERATES_ON__entity'});
MATCH (r:RelationRule {id: 'action__OPERATES_ON__entity'}),
      (s:EntityType {name: 'action'}), (t:EntityType {name: 'entity'}),
      (rt:RelationType {name: 'OPERATES_ON'})
MERGE (r)-[:FROM]->(s) MERGE (r)-[:HAS_TYPE]->(rt) MERGE (r)-[:TO]->(t);

MERGE (r:Ontology:RelationRule {id: 'action__EXPOSED_BY__api_endpoints'});
MATCH (r:RelationRule {id: 'action__EXPOSED_BY__api_endpoints'}),
      (s:EntityType {name: 'action'}), (t:EntityType {name: 'api_endpoints'}),
      (rt:RelationType {name: 'EXPOSED_BY'})
MERGE (r)-[:FROM]->(s) MERGE (r)-[:HAS_TYPE]->(rt) MERGE (r)-[:TO]->(t);

// --- entity ---
MERGE (r:Ontology:RelationRule {id: 'entity__PERSISTED_BY__repository'});
MATCH (r:RelationRule {id: 'entity__PERSISTED_BY__repository'}),
      (s:EntityType {name: 'entity'}), (t:EntityType {name: 'repository'}),
      (rt:RelationType {name: 'PERSISTED_BY'})
MERGE (r)-[:FROM]->(s) MERGE (r)-[:HAS_TYPE]->(rt) MERGE (r)-[:TO]->(t);

MERGE (r:Ontology:RelationRule {id: 'entity__EXPOSED_BY__api_endpoints'});
MATCH (r:RelationRule {id: 'entity__EXPOSED_BY__api_endpoints'}),
      (s:EntityType {name: 'entity'}), (t:EntityType {name: 'api_endpoints'}),
      (rt:RelationType {name: 'EXPOSED_BY'})
MERGE (r)-[:FROM]->(s) MERGE (r)-[:HAS_TYPE]->(rt) MERGE (r)-[:TO]->(t);

// --- pages -> endpoints ---
MERGE (r:Ontology:RelationRule {id: 'core_page__USES__api_endpoints'});
MATCH (r:RelationRule {id: 'core_page__USES__api_endpoints'}),
      (s:EntityType {name: 'core_page'}), (t:EntityType {name: 'api_endpoints'}),
      (rt:RelationType {name: 'USES'})
MERGE (r)-[:FROM]->(s) MERGE (r)-[:HAS_TYPE]->(rt) MERGE (r)-[:TO]->(t);

MERGE (r:Ontology:RelationRule {id: 'plugin_page__USES__api_endpoints'})
SET r.description = 'Indirect — plugin pages call the SDK which proxies to host endpoints.';
MATCH (r:RelationRule {id: 'plugin_page__USES__api_endpoints'}),
      (s:EntityType {name: 'plugin_page'}), (t:EntityType {name: 'api_endpoints'}),
      (rt:RelationType {name: 'USES'})
MERGE (r)-[:FROM]->(s) MERGE (r)-[:HAS_TYPE]->(rt) MERGE (r)-[:TO]->(t);

// --- plugin -> X ---
MERGE (r:Ontology:RelationRule {id: 'plugin__DECLARES__manifest'});
MATCH (r:RelationRule {id: 'plugin__DECLARES__manifest'}),
      (s:EntityType {name: 'plugin'}), (t:EntityType {name: 'manifest'}),
      (rt:RelationType {name: 'DECLARES'})
MERGE (r)-[:FROM]->(s) MERGE (r)-[:HAS_TYPE]->(rt) MERGE (r)-[:TO]->(t);

MERGE (r:Ontology:RelationRule {id: 'plugin__CONTAINS__plugin_page'});
MATCH (r:RelationRule {id: 'plugin__CONTAINS__plugin_page'}),
      (s:EntityType {name: 'plugin'}), (t:EntityType {name: 'plugin_page'}),
      (rt:RelationType {name: 'CONTAINS'})
MERGE (r)-[:FROM]->(s) MERGE (r)-[:HAS_TYPE]->(rt) MERGE (r)-[:TO]->(t);

MERGE (r:Ontology:RelationRule {id: 'plugin__CONTAINS__plugin_entity'});
MATCH (r:RelationRule {id: 'plugin__CONTAINS__plugin_entity'}),
      (s:EntityType {name: 'plugin'}), (t:EntityType {name: 'plugin_entity'}),
      (rt:RelationType {name: 'CONTAINS'})
MERGE (r)-[:FROM]->(s) MERGE (r)-[:HAS_TYPE]->(rt) MERGE (r)-[:TO]->(t);

MERGE (r:Ontology:RelationRule {id: 'plugin__CONTAINS__extended_entity'});
MATCH (r:RelationRule {id: 'plugin__CONTAINS__extended_entity'}),
      (s:EntityType {name: 'plugin'}), (t:EntityType {name: 'extended_entity'}),
      (rt:RelationType {name: 'CONTAINS'})
MERGE (r)-[:FROM]->(s) MERGE (r)-[:HAS_TYPE]->(rt) MERGE (r)-[:TO]->(t);

MERGE (r:Ontology:RelationRule {id: 'plugin__DEFINES__domain_concept'})
SET r.description = 'Plugin defines its own domain types (Warehouse, BoxDimensions, ProductDescription, ...).';
MATCH (r:RelationRule {id: 'plugin__DEFINES__domain_concept'}),
      (s:EntityType {name: 'plugin'}), (t:EntityType {name: 'domain_concept'}),
      (rt:RelationType {name: 'DEFINES'})
MERGE (r)-[:FROM]->(s) MERGE (r)-[:HAS_TYPE]->(rt) MERGE (r)-[:TO]->(t);

MERGE (r:Ontology:RelationRule {id: 'plugin__CONTAINS__api'});
MATCH (r:RelationRule {id: 'plugin__CONTAINS__api'}),
      (s:EntityType {name: 'plugin'}), (t:EntityType {name: 'api'}),
      (rt:RelationType {name: 'CONTAINS'})
MERGE (r)-[:FROM]->(s) MERGE (r)-[:HAS_TYPE]->(rt) MERGE (r)-[:TO]->(t);

MERGE (r:Ontology:RelationRule {id: 'plugin__RUNS_IN__iframe_isolation'});
MATCH (r:RelationRule {id: 'plugin__RUNS_IN__iframe_isolation'}),
      (s:EntityType {name: 'plugin'}), (t:EntityType {name: 'iframe_isolation'}),
      (rt:RelationType {name: 'RUNS_IN'})
MERGE (r)-[:FROM]->(s) MERGE (r)-[:HAS_TYPE]->(rt) MERGE (r)-[:TO]->(t);

MERGE (r:Ontology:RelationRule {id: 'plugin__COMMUNICATES_VIA__host_bridge'});
MATCH (r:RelationRule {id: 'plugin__COMMUNICATES_VIA__host_bridge'}),
      (s:EntityType {name: 'plugin'}), (t:EntityType {name: 'host_bridge'}),
      (rt:RelationType {name: 'COMMUNICATES_VIA'})
MERGE (r)-[:FROM]->(s) MERGE (r)-[:HAS_TYPE]->(rt) MERGE (r)-[:TO]->(t);

// --- manifest ---
MERGE (r:Ontology:RelationRule {id: 'manifest__DECLARES__extension_point'});
MATCH (r:RelationRule {id: 'manifest__DECLARES__extension_point'}),
      (s:EntityType {name: 'manifest'}), (t:EntityType {name: 'extension_point'}),
      (rt:RelationType {name: 'DECLARES'})
MERGE (r)-[:FROM]->(s) MERGE (r)-[:HAS_TYPE]->(rt) MERGE (r)-[:TO]->(t);

MERGE (r:Ontology:RelationRule {id: 'manifest__DECLARES__filter_definition'})
SET r.description = 'product.list.filters entries in the manifest become host-rendered filters.';
MATCH (r:RelationRule {id: 'manifest__DECLARES__filter_definition'}),
      (s:EntityType {name: 'manifest'}), (t:EntityType {name: 'filter_definition'}),
      (rt:RelationType {name: 'DECLARES'})
MERGE (r)-[:FROM]->(s) MERGE (r)-[:HAS_TYPE]->(rt) MERGE (r)-[:TO]->(t);

// --- extension point wiring ---
MERGE (r:Ontology:RelationRule {id: 'plugin__EXPOSES__extension_point'});
MATCH (r:RelationRule {id: 'plugin__EXPOSES__extension_point'}),
      (s:EntityType {name: 'plugin'}), (t:EntityType {name: 'extension_point'}),
      (rt:RelationType {name: 'EXPOSES'})
MERGE (r)-[:FROM]->(s) MERGE (r)-[:HAS_TYPE]->(rt) MERGE (r)-[:TO]->(t);

MERGE (r:Ontology:RelationRule {id: 'extension_point__IMPLEMENTED_BY__plugin_page'})
SET r.description = 'Iframe-rendered extension points (menu.main, product.detail.tabs, product.detail.info) point to a plugin page.';
MATCH (r:RelationRule {id: 'extension_point__IMPLEMENTED_BY__plugin_page'}),
      (s:EntityType {name: 'extension_point'}), (t:EntityType {name: 'plugin_page'}),
      (rt:RelationType {name: 'IMPLEMENTED_BY'})
MERGE (r)-[:FROM]->(s) MERGE (r)-[:HAS_TYPE]->(rt) MERGE (r)-[:TO]->(t);

MERGE (r:Ontology:RelationRule {id: 'extension_point__RENDERED_ON__core_page'})
SET r.description = 'Where the contributed UI is composed into the host: menu.main on the sidebar, product.detail.* on the product detail page, product.list.filters on the product list.';
MATCH (r:RelationRule {id: 'extension_point__RENDERED_ON__core_page'}),
      (s:EntityType {name: 'extension_point'}), (t:EntityType {name: 'core_page'}),
      (rt:RelationType {name: 'RENDERED_ON'})
MERGE (r)-[:FROM]->(s) MERGE (r)-[:HAS_TYPE]->(rt) MERGE (r)-[:TO]->(t);

// --- plugin page / sdk / bridge ---
MERGE (r:Ontology:RelationRule {id: 'plugin_page__USES__host_bridge'});
MATCH (r:RelationRule {id: 'plugin_page__USES__host_bridge'}),
      (s:EntityType {name: 'plugin_page'}), (t:EntityType {name: 'host_bridge'}),
      (rt:RelationType {name: 'USES'})
MERGE (r)-[:FROM]->(s) MERGE (r)-[:HAS_TYPE]->(rt) MERGE (r)-[:TO]->(t);

MERGE (r:Ontology:RelationRule {id: 'plugin_page__USES__plugin_sdk'});
MATCH (r:RelationRule {id: 'plugin_page__USES__plugin_sdk'}),
      (s:EntityType {name: 'plugin_page'}), (t:EntityType {name: 'plugin_sdk'}),
      (rt:RelationType {name: 'USES'})
MERGE (r)-[:FROM]->(s) MERGE (r)-[:HAS_TYPE]->(rt) MERGE (r)-[:TO]->(t);

MERGE (r:Ontology:RelationRule {id: 'plugin_sdk__USES__host_bridge'});
MATCH (r:RelationRule {id: 'plugin_sdk__USES__host_bridge'}),
      (s:EntityType {name: 'plugin_sdk'}), (t:EntityType {name: 'host_bridge'}),
      (rt:RelationType {name: 'USES'})
MERGE (r)-[:FROM]->(s) MERGE (r)-[:HAS_TYPE]->(rt) MERGE (r)-[:TO]->(t);

MERGE (r:Ontology:RelationRule {id: 'host_bridge__PROXIES_TO__api_endpoints'})
SET r.description = 'Each SDK message type is forwarded by PluginMessageHandler to a backend endpoint.';
MATCH (r:RelationRule {id: 'host_bridge__PROXIES_TO__api_endpoints'}),
      (s:EntityType {name: 'host_bridge'}), (t:EntityType {name: 'api_endpoints'}),
      (rt:RelationType {name: 'PROXIES_TO'})
MERGE (r)-[:FROM]->(s) MERGE (r)-[:HAS_TYPE]->(rt) MERGE (r)-[:TO]->(t);

// --- filter ---
MERGE (r:Ontology:RelationRule {id: 'filter_definition__RENDERED_ON__core_page'})
SET r.description = 'Host renders filter controls on the product list page.';
MATCH (r:RelationRule {id: 'filter_definition__RENDERED_ON__core_page'}),
      (s:EntityType {name: 'filter_definition'}), (t:EntityType {name: 'core_page'}),
      (rt:RelationType {name: 'RENDERED_ON'})
MERGE (r)-[:FROM]->(s) MERGE (r)-[:HAS_TYPE]->(rt) MERGE (r)-[:TO]->(t);

MERGE (r:Ontology:RelationRule {id: 'filter_definition__QUERIES__extended_entity'})
SET r.description = "Filter resolves into a JSONB query on the plugin's namespace inside Product.pluginData.";
MATCH (r:RelationRule {id: 'filter_definition__QUERIES__extended_entity'}),
      (s:EntityType {name: 'filter_definition'}), (t:EntityType {name: 'extended_entity'}),
      (rt:RelationType {name: 'QUERIES'})
MERGE (r)-[:FROM]->(s) MERGE (r)-[:HAS_TYPE]->(rt) MERGE (r)-[:TO]->(t);

// --- storage ---
MERGE (r:Ontology:RelationRule {id: 'plugin_entity__STORED_VIA__storage_strategy'});
MATCH (r:RelationRule {id: 'plugin_entity__STORED_VIA__storage_strategy'}),
      (s:EntityType {name: 'plugin_entity'}), (t:EntityType {name: 'storage_strategy'}),
      (rt:RelationType {name: 'STORED_VIA'})
MERGE (r)-[:FROM]->(s) MERGE (r)-[:HAS_TYPE]->(rt) MERGE (r)-[:TO]->(t);

MERGE (r:Ontology:RelationRule {id: 'extended_entity__STORED_VIA__storage_strategy'});
MATCH (r:RelationRule {id: 'extended_entity__STORED_VIA__storage_strategy'}),
      (s:EntityType {name: 'extended_entity'}), (t:EntityType {name: 'storage_strategy'}),
      (rt:RelationType {name: 'STORED_VIA'})
MERGE (r)-[:FROM]->(s) MERGE (r)-[:HAS_TYPE]->(rt) MERGE (r)-[:TO]->(t);

MERGE (r:Ontology:RelationRule {id: 'extended_entity__EXTENDS__entity'})
SET r.description = 'Plugin attributes attached to a host entity (typically Product).';
MATCH (r:RelationRule {id: 'extended_entity__EXTENDS__entity'}),
      (s:EntityType {name: 'extended_entity'}), (t:EntityType {name: 'entity'}),
      (rt:RelationType {name: 'EXTENDS'})
MERGE (r)-[:FROM]->(s) MERGE (r)-[:HAS_TYPE]->(rt) MERGE (r)-[:TO]->(t);

MERGE (r:Ontology:RelationRule {id: 'storage_strategy__PERSISTED_IN__entity'})
SET r.description = 'Maps to the host entity that owns the underlying table (Product for namespaced JSONB, PluginObject for custom collections).';
MATCH (r:RelationRule {id: 'storage_strategy__PERSISTED_IN__entity'}),
      (s:EntityType {name: 'storage_strategy'}), (t:EntityType {name: 'entity'}),
      (rt:RelationType {name: 'PERSISTED_IN'})
MERGE (r)-[:FROM]->(s) MERGE (r)-[:HAS_TYPE]->(rt) MERGE (r)-[:TO]->(t);

// --- entity binding ---
MERGE (r:Ontology:RelationRule {id: 'plugin_entity__MAY_USE__entity_binding'})
SET r.description = 'Plugin custom objects may be bound to a host entity for server-side filtering.';
MATCH (r:RelationRule {id: 'plugin_entity__MAY_USE__entity_binding'}),
      (s:EntityType {name: 'plugin_entity'}), (t:EntityType {name: 'entity_binding'}),
      (rt:RelationType {name: 'MAY_USE'})
MERGE (r)-[:FROM]->(s) MERGE (r)-[:HAS_TYPE]->(rt) MERGE (r)-[:TO]->(t);

MERGE (r:Ontology:RelationRule {id: 'entity_binding__TARGETS__entity'});
MATCH (r:RelationRule {id: 'entity_binding__TARGETS__entity'}),
      (s:EntityType {name: 'entity_binding'}), (t:EntityType {name: 'entity'}),
      (rt:RelationType {name: 'TARGETS'})
MERGE (r)-[:FROM]->(s) MERGE (r)-[:HAS_TYPE]->(rt) MERGE (r)-[:TO]->(t);

// --- api ---
MERGE (r:Ontology:RelationRule {id: 'api__USES__api_endpoints'})
SET r.description = 'Plugin integrations ultimately reach host endpoints via the SDK.';
MATCH (r:RelationRule {id: 'api__USES__api_endpoints'}),
      (s:EntityType {name: 'api'}), (t:EntityType {name: 'api_endpoints'}),
      (rt:RelationType {name: 'USES'})
MERGE (r)-[:FROM]->(s) MERGE (r)-[:HAS_TYPE]->(rt) MERGE (r)-[:TO]->(t);

MERGE (r:Ontology:RelationRule {id: 'api__USES__external_system'})
SET r.description = 'Plugin-owned backend routes may call external systems (e.g. AI Description -> LiteLLM).';
MATCH (r:RelationRule {id: 'api__USES__external_system'}),
      (s:EntityType {name: 'api'}), (t:EntityType {name: 'external_system'}),
      (rt:RelationType {name: 'USES'})
MERGE (r)-[:FROM]->(s) MERGE (r)-[:HAS_TYPE]->(rt) MERGE (r)-[:TO]->(t);

// --- feature ---
MERGE (r:Ontology:RelationRule {id: 'feature__PERFORMED_BY__actor'});
MATCH (r:RelationRule {id: 'feature__PERFORMED_BY__actor'}),
      (s:EntityType {name: 'feature'}), (t:EntityType {name: 'actor'}),
      (rt:RelationType {name: 'PERFORMED_BY'})
MERGE (r)-[:FROM]->(s) MERGE (r)-[:HAS_TYPE]->(rt) MERGE (r)-[:TO]->(t);

MERGE (r:Ontology:RelationRule {id: 'feature__REALIZED_BY__core_page'});
MATCH (r:RelationRule {id: 'feature__REALIZED_BY__core_page'}),
      (s:EntityType {name: 'feature'}), (t:EntityType {name: 'core_page'}),
      (rt:RelationType {name: 'REALIZED_BY'})
MERGE (r)-[:FROM]->(s) MERGE (r)-[:HAS_TYPE]->(rt) MERGE (r)-[:TO]->(t);

MERGE (r:Ontology:RelationRule {id: 'feature__REALIZED_BY__plugin_page'});
MATCH (r:RelationRule {id: 'feature__REALIZED_BY__plugin_page'}),
      (s:EntityType {name: 'feature'}), (t:EntityType {name: 'plugin_page'}),
      (rt:RelationType {name: 'REALIZED_BY'})
MERGE (r)-[:FROM]->(s) MERGE (r)-[:HAS_TYPE]->(rt) MERGE (r)-[:TO]->(t);

MERGE (r:Ontology:RelationRule {id: 'feature__DELIVERED_VIA__extension_point'});
MATCH (r:RelationRule {id: 'feature__DELIVERED_VIA__extension_point'}),
      (s:EntityType {name: 'feature'}), (t:EntityType {name: 'extension_point'}),
      (rt:RelationType {name: 'DELIVERED_VIA'})
MERGE (r)-[:FROM]->(s) MERGE (r)-[:HAS_TYPE]->(rt) MERGE (r)-[:TO]->(t);

MERGE (r:Ontology:RelationRule {id: 'feature__BACKED_BY__action'});
MATCH (r:RelationRule {id: 'feature__BACKED_BY__action'}),
      (s:EntityType {name: 'feature'}), (t:EntityType {name: 'action'}),
      (rt:RelationType {name: 'BACKED_BY'})
MERGE (r)-[:FROM]->(s) MERGE (r)-[:HAS_TYPE]->(rt) MERGE (r)-[:TO]->(t);

// =============================================================================
// END
//
// Useful exploration queries
// --------------------------
// 1) Whole schema:
//      MATCH (n:Ontology) RETURN n;
//
// 2) Properties of a concept (e.g. plugin):
//      MATCH (et:EntityType {name:'plugin'})-[:HAS_PROPERTY]->(p:Property)
//      RETURN p.name, p.kind, p.description, p.values;
//
// 3) All allowed relations between entity types:
//      MATCH (s:EntityType)<-[:FROM]-(r:RelationRule)-[:HAS_TYPE]->(rt:RelationType),
//            (r)-[:TO]->(t:EntityType)
//      RETURN s.name AS from, rt.name AS type, t.name AS to, r.description;
//
// 4) Relations a given concept can participate in (as source or target):
//      MATCH (et:EntityType {name:'plugin'})
//      OPTIONAL MATCH (et)<-[:FROM]-(r1:RelationRule)-[:HAS_TYPE]->(rt1:RelationType),
//                      (r1)-[:TO]->(out:EntityType)
//      OPTIONAL MATCH (et)<-[:TO]-(r2:RelationRule)-[:HAS_TYPE]->(rt2:RelationType),
//                      (r2)-[:FROM]->(in:EntityType)
//      RETURN collect(DISTINCT rt1.name + '->' + out.name) AS outgoing,
//             collect(DISTINCT in.name + '->' + rt2.name) AS incoming;
// =============================================================================
