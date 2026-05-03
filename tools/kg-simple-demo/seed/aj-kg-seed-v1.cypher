// =============================================================================
// AJ Platform — Knowledge Graph Instance Seed (auto-generated)
// Generated at 2026-05-02T14:34:44.455Z
// Source: src/main/java + src/main/frontend + plugins
// Overrides: tools/kg-codegen/overrides.yaml
// Ontology:  aj-kg-ontology.json
// =============================================================================

// CONSTRAINTS
CREATE CONSTRAINT inst_api_id IF NOT EXISTS FOR (n:API) REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT inst_apiendpoints_id IF NOT EXISTS FOR (n:APIEndpoints) REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT inst_action_id IF NOT EXISTS FOR (n:Action) REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT inst_actor_id IF NOT EXISTS FOR (n:Actor) REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT inst_backend_id IF NOT EXISTS FOR (n:Backend) REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT inst_core_id IF NOT EXISTS FOR (n:Core) REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT inst_corepage_id IF NOT EXISTS FOR (n:CorePage) REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT inst_domainconcept_id IF NOT EXISTS FOR (n:DomainConcept) REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT inst_entity_id IF NOT EXISTS FOR (n:Entity) REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT inst_entitybinding_id IF NOT EXISTS FOR (n:EntityBinding) REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT inst_extendedentity_id IF NOT EXISTS FOR (n:ExtendedEntity) REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT inst_extensionpoint_id IF NOT EXISTS FOR (n:ExtensionPoint) REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT inst_externalsystem_id IF NOT EXISTS FOR (n:ExternalSystem) REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT inst_feature_id IF NOT EXISTS FOR (n:Feature) REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT inst_filterdefinition_id IF NOT EXISTS FOR (n:FilterDefinition) REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT inst_frontend_id IF NOT EXISTS FOR (n:Frontend) REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT inst_host_id IF NOT EXISTS FOR (n:Host) REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT inst_hostbridge_id IF NOT EXISTS FOR (n:HostBridge) REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT inst_iframeisolation_id IF NOT EXISTS FOR (n:IframeIsolation) REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT inst_manifest_id IF NOT EXISTS FOR (n:Manifest) REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT inst_module_id IF NOT EXISTS FOR (n:Module) REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT inst_plugin_id IF NOT EXISTS FOR (n:Plugin) REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT inst_pluginengine_id IF NOT EXISTS FOR (n:PluginEngine) REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT inst_pluginentity_id IF NOT EXISTS FOR (n:PluginEntity) REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT inst_pluginpage_id IF NOT EXISTS FOR (n:PluginPage) REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT inst_pluginsdk_id IF NOT EXISTS FOR (n:PluginSDK) REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT inst_pluginshell_id IF NOT EXISTS FOR (n:PluginShell) REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT inst_repository_id IF NOT EXISTS FOR (n:Repository) REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT inst_storagestrategy_id IF NOT EXISTS FOR (n:StorageStrategy) REQUIRE n.id IS UNIQUE;
CREATE CONSTRAINT inst_system_id IF NOT EXISTS FOR (n:System) REQUIRE n.id IS UNIQUE;

// NODES

// --- API ---
MERGE (n:API {id: 'api-ai-description'})
SET n.name = 'AI Description Plugin API',
    n.kind = 'backend-route',
    n.path = 'plugins/ai-description/src/pages/api/generate.ts';
MERGE (n:API {id: 'api-box-size'})
SET n.name = 'Box Size Plugin API',
    n.kind = 'sdk-host-bridge';
MERGE (n:API {id: 'api-warehouse'})
SET n.name = 'Warehouse Management Plugin API',
    n.kind = 'sdk-host-bridge';

// --- APIEndpoints ---
MERGE (n:APIEndpoints {id: 'api-category-create'})
SET n.method = 'POST',
    n.uri = '/api/categories',
    n.handler = 'CategoryController.create';
MERGE (n:APIEndpoints {id: 'api-category-delete'})
SET n.method = 'DELETE',
    n.uri = '/api/categories/{id}',
    n.handler = 'CategoryController.delete';
MERGE (n:APIEndpoints {id: 'api-category-getbyid'})
SET n.method = 'GET',
    n.uri = '/api/categories/{id}',
    n.handler = 'CategoryController.getById';
MERGE (n:APIEndpoints {id: 'api-category-list'})
SET n.method = 'GET',
    n.uri = '/api/categories',
    n.handler = 'CategoryController.list';
MERGE (n:APIEndpoints {id: 'api-category-update'})
SET n.method = 'PUT',
    n.uri = '/api/categories/{id}',
    n.handler = 'CategoryController.update';
MERGE (n:APIEndpoints {id: 'api-health-health'})
SET n.method = 'GET',
    n.uri = '/api/health',
    n.handler = 'HealthController.health';
MERGE (n:APIEndpoints {id: 'api-plugin-data-delete'})
SET n.method = 'DELETE',
    n.uri = '/api/plugins/{pluginId}/products/{productId}/data',
    n.handler = 'PluginDataController.delete';
MERGE (n:APIEndpoints {id: 'api-plugin-data-get'})
SET n.method = 'GET',
    n.uri = '/api/plugins/{pluginId}/products/{productId}/data',
    n.handler = 'PluginDataController.get';
MERGE (n:APIEndpoints {id: 'api-plugin-data-put'})
SET n.method = 'PUT',
    n.uri = '/api/plugins/{pluginId}/products/{productId}/data',
    n.handler = 'PluginDataController.put';
MERGE (n:APIEndpoints {id: 'api-plugin-delete'})
SET n.method = 'DELETE',
    n.uri = '/api/plugins/{pluginId}',
    n.handler = 'PluginController.delete';
MERGE (n:APIEndpoints {id: 'api-plugin-getbyid'})
SET n.method = 'GET',
    n.uri = '/api/plugins/{pluginId}',
    n.handler = 'PluginController.getById';
MERGE (n:APIEndpoints {id: 'api-plugin-list'})
SET n.method = 'GET',
    n.uri = '/api/plugins',
    n.handler = 'PluginController.list';
MERGE (n:APIEndpoints {id: 'api-plugin-object-delete'})
SET n.method = 'DELETE',
    n.uri = '/api/plugins/{pluginId}/objects/{objectType}/{objectId}',
    n.handler = 'PluginObjectController.delete';
MERGE (n:APIEndpoints {id: 'api-plugin-object-get'})
SET n.method = 'GET',
    n.uri = '/api/plugins/{pluginId}/objects/{objectType}/{objectId}',
    n.handler = 'PluginObjectController.get';
MERGE (n:APIEndpoints {id: 'api-plugin-object-list'})
SET n.method = 'GET',
    n.uri = '/api/plugins/{pluginId}/objects/{objectType}',
    n.handler = 'PluginObjectController.list';
MERGE (n:APIEndpoints {id: 'api-plugin-object-listbyentity'})
SET n.method = 'GET',
    n.uri = '/api/plugins/{pluginId}/objects',
    n.handler = 'PluginObjectController.listByEntity';
MERGE (n:APIEndpoints {id: 'api-plugin-object-save'})
SET n.method = 'PUT',
    n.uri = '/api/plugins/{pluginId}/objects/{objectType}/{objectId}',
    n.handler = 'PluginObjectController.save';
MERGE (n:APIEndpoints {id: 'api-plugin-setenabled'})
SET n.method = 'PATCH',
    n.uri = '/api/plugins/{pluginId}/enabled',
    n.handler = 'PluginController.setEnabled';
MERGE (n:APIEndpoints {id: 'api-plugin-uploadmanifest'})
SET n.method = 'PUT',
    n.uri = '/api/plugins/{pluginId}/manifest',
    n.handler = 'PluginController.uploadManifest';
MERGE (n:APIEndpoints {id: 'api-product-create'})
SET n.method = 'POST',
    n.uri = '/api/products',
    n.handler = 'ProductController.create';
MERGE (n:APIEndpoints {id: 'api-product-delete'})
SET n.method = 'DELETE',
    n.uri = '/api/products/{id}',
    n.handler = 'ProductController.delete';
MERGE (n:APIEndpoints {id: 'api-product-getbyid'})
SET n.method = 'GET',
    n.uri = '/api/products/{id}',
    n.handler = 'ProductController.getById';
MERGE (n:APIEndpoints {id: 'api-product-list'})
SET n.method = 'GET',
    n.uri = '/api/products',
    n.handler = 'ProductController.list';
MERGE (n:APIEndpoints {id: 'api-product-update'})
SET n.method = 'PUT',
    n.uri = '/api/products/{id}',
    n.handler = 'ProductController.update';

// --- Action ---
MERGE (n:Action {id: 'action-category-create'})
SET n.name = 'CategoryService.create',
    n.kind = 'command';
MERGE (n:Action {id: 'action-category-delete'})
SET n.name = 'CategoryService.delete',
    n.kind = 'command';
MERGE (n:Action {id: 'action-category-findall'})
SET n.name = 'CategoryService.findAll',
    n.kind = 'query';
MERGE (n:Action {id: 'action-category-findbyid'})
SET n.name = 'CategoryService.findById',
    n.kind = 'query';
MERGE (n:Action {id: 'action-category-update'})
SET n.name = 'CategoryService.update',
    n.kind = 'command';
MERGE (n:Action {id: 'action-plugin-data-getdata'})
SET n.name = 'PluginDataService.getData',
    n.kind = 'query';
MERGE (n:Action {id: 'action-plugin-data-removedata'})
SET n.name = 'PluginDataService.removeData',
    n.kind = 'command';
MERGE (n:Action {id: 'action-plugin-data-setdata'})
SET n.name = 'PluginDataService.setData',
    n.kind = 'command';
MERGE (n:Action {id: 'action-plugin-descriptor-delete'})
SET n.name = 'PluginDescriptorService.delete',
    n.kind = 'command';
MERGE (n:Action {id: 'action-plugin-descriptor-findallenabled'})
SET n.name = 'PluginDescriptorService.findAllEnabled',
    n.kind = 'query';
MERGE (n:Action {id: 'action-plugin-descriptor-findbyid'})
SET n.name = 'PluginDescriptorService.findById',
    n.kind = 'query';
MERGE (n:Action {id: 'action-plugin-descriptor-findenabledorthrow'})
SET n.name = 'PluginDescriptorService.findEnabledOrThrow',
    n.kind = 'query';
MERGE (n:Action {id: 'action-plugin-descriptor-setenabled'})
SET n.name = 'PluginDescriptorService.setEnabled',
    n.kind = 'command';
MERGE (n:Action {id: 'action-plugin-descriptor-uploadmanifest'})
SET n.name = 'PluginDescriptorService.uploadManifest',
    n.kind = 'command';
MERGE (n:Action {id: 'action-plugin-object-delete'})
SET n.name = 'PluginObjectService.delete',
    n.kind = 'command';
MERGE (n:Action {id: 'action-plugin-object-get'})
SET n.name = 'PluginObjectService.get',
    n.kind = 'query';
MERGE (n:Action {id: 'action-plugin-object-list'})
SET n.name = 'PluginObjectService.list',
    n.kind = 'query';
MERGE (n:Action {id: 'action-plugin-object-listbyentity'})
SET n.name = 'PluginObjectService.listByEntity',
    n.kind = 'query';
MERGE (n:Action {id: 'action-plugin-object-save'})
SET n.name = 'PluginObjectService.save',
    n.kind = 'command';
MERGE (n:Action {id: 'action-product-create'})
SET n.name = 'ProductService.create',
    n.kind = 'command';
MERGE (n:Action {id: 'action-product-delete'})
SET n.name = 'ProductService.delete',
    n.kind = 'command';
MERGE (n:Action {id: 'action-product-findall'})
SET n.name = 'ProductService.findAll',
    n.kind = 'query';
MERGE (n:Action {id: 'action-product-findbyid'})
SET n.name = 'ProductService.findById',
    n.kind = 'query';
MERGE (n:Action {id: 'action-product-update'})
SET n.name = 'ProductService.update',
    n.kind = 'command';

// --- Actor ---
MERGE (n:Actor {id: 'catalog-operator'})
SET n.role = 'Catalog Operator';

// --- Backend ---
MERGE (n:Backend {id: 'aj-backend'})
SET n.name = 'AJ Backend',
    n.rootPackage = 'pl.devstyle.aj',
    n.language = 'Java',
    n.framework = 'Spring Boot 4.0.5';

// --- Core ---
MERGE (n:Core {id: 'aj-core'})
SET n.name = 'AJ Core',
    n.rootPackage = 'pl.devstyle.aj.core',
    n.notes = 'BaseEntity audit, JpaAuditingConfig, GlobalExceptionHandler, plugin engine.';

// --- CorePage ---
MERGE (n:CorePage {id: 'page-category-form'})
SET n.name = 'Category Form',
    n.route = '/categories/new | /categories/:id/edit',
    n.component = 'CategoryFormPage';
MERGE (n:CorePage {id: 'page-category-list'})
SET n.name = 'Category List',
    n.route = '/categories',
    n.component = 'CategoryListPage';
MERGE (n:CorePage {id: 'page-layout'})
SET n.name = 'Layout',
    n.route = '/',
    n.component = 'Layout';
MERGE (n:CorePage {id: 'page-plugin-detail'})
SET n.name = 'Plugin Detail',
    n.route = '/plugins/:pluginId/detail',
    n.component = 'PluginDetailPage';
MERGE (n:CorePage {id: 'page-plugin-form'})
SET n.name = 'Plugin Form',
    n.route = '/plugins/new | /plugins/:pluginId/edit',
    n.component = 'PluginFormPage';
MERGE (n:CorePage {id: 'page-plugin-list'})
SET n.name = 'Plugin List',
    n.route = '/plugins',
    n.component = 'PluginListPage';
MERGE (n:CorePage {id: 'page-product-detail'})
SET n.name = 'Product Detail',
    n.route = '/products/:id',
    n.component = 'ProductDetailPage';
MERGE (n:CorePage {id: 'page-product-form'})
SET n.name = 'Product Form',
    n.route = '/products/new | /products/:id/edit',
    n.component = 'ProductFormPage';
MERGE (n:CorePage {id: 'page-product-list'})
SET n.name = 'Product List',
    n.route = '/products',
    n.component = 'ProductListPage';

// --- DomainConcept ---
MERGE (n:DomainConcept {id: 'dc-ai-description-product-description'})
SET n.name = 'ProductDescription';
MERGE (n:DomainConcept {id: 'dc-box-size-box-dimensions'})
SET n.name = 'BoxDimensions';
MERGE (n:DomainConcept {id: 'dc-warehouse-product'})
SET n.name = 'Product';
MERGE (n:DomainConcept {id: 'dc-warehouse-stock-entry'})
SET n.name = 'StockEntry';
MERGE (n:DomainConcept {id: 'dc-warehouse-warehouse'})
SET n.name = 'Warehouse';

// --- Entity ---
MERGE (n:Entity {id: 'entity-category'})
SET n.name = 'Category',
    n.fqcn = 'pl.devstyle.aj.category.Category',
    n.table = 'categories';
MERGE (n:Entity {id: 'entity-plugin-descriptor'})
SET n.name = 'PluginDescriptor',
    n.fqcn = 'pl.devstyle.aj.core.plugin.PluginDescriptor',
    n.table = 'plugins';
MERGE (n:Entity {id: 'entity-plugin-object'})
SET n.name = 'PluginObject',
    n.fqcn = 'pl.devstyle.aj.core.plugin.PluginObject',
    n.table = 'plugin_objects';
MERGE (n:Entity {id: 'entity-product'})
SET n.name = 'Product',
    n.fqcn = 'pl.devstyle.aj.product.Product',
    n.table = 'products';

// --- EntityBinding ---
MERGE (n:EntityBinding {id: 'binding-aidesc-on-product'})
SET n.entityType = 'PRODUCT';
MERGE (n:EntityBinding {id: 'binding-warehouse-stock-on-product'})
SET n.entityType = 'PRODUCT';

// --- ExtendedEntity ---
MERGE (n:ExtendedEntity {id: 'ee-aidesc-data'})
SET n.name = 'AI Product Description',
    n.storage = 'plugin_objects (objectType=description, bound entityType=PRODUCT)';
MERGE (n:ExtendedEntity {id: 'ee-boxsize-data'})
SET n.name = 'Box Dimensions',
    n.storage = 'Product.pluginData[\'box-size\'] (length, width, height)';
MERGE (n:ExtendedEntity {id: 'ee-warehouse-stock-entry'})
SET n.name = 'Stock Entry',
    n.storage = 'plugin_objects (objectType=stock, bound entityType=PRODUCT)';
MERGE (n:ExtendedEntity {id: 'ee-warehouse-stock-flag'})
SET n.name = 'Stock Availability Flag',
    n.storage = 'Product.pluginData[\'warehouse\'][\'stock\'] (boolean JSONB key)';

// --- ExtensionPoint ---
MERGE (n:ExtensionPoint {id: 'ep-ai-description-product-detail-tabs-ai-description'})
SET n.type = 'product.detail.tabs',
    n.label = 'AI Description',
    n.icon = null,
    n.path = '/product-tab',
    n.priority = 70,
    n.scope = 'product',
    n.rendering = 'plugin-iframe';
MERGE (n:ExtensionPoint {id: 'ep-box-size-product-detail-info-box-size'})
SET n.type = 'product.detail.info',
    n.label = 'Box Size',
    n.icon = null,
    n.path = '/product-box-badge',
    n.priority = 20,
    n.scope = 'product',
    n.rendering = 'plugin-iframe';
MERGE (n:ExtensionPoint {id: 'ep-box-size-product-detail-tabs-box-size'})
SET n.type = 'product.detail.tabs',
    n.label = 'Box Size',
    n.icon = null,
    n.path = '/product-box',
    n.priority = 60,
    n.scope = 'product',
    n.rendering = 'plugin-iframe';
MERGE (n:ExtensionPoint {id: 'ep-warehouse-menu-main-warehouse'})
SET n.type = 'menu.main',
    n.label = 'Warehouse',
    n.icon = 'warehouse',
    n.path = '/',
    n.priority = 100,
    n.scope = 'global',
    n.rendering = 'plugin-iframe';
MERGE (n:ExtensionPoint {id: 'ep-warehouse-product-detail-info-availability'})
SET n.type = 'product.detail.info',
    n.label = 'Availability',
    n.icon = null,
    n.path = '/product-availability',
    n.priority = 10,
    n.scope = 'product',
    n.rendering = 'plugin-iframe';
MERGE (n:ExtensionPoint {id: 'ep-warehouse-product-detail-tabs-stock-info'})
SET n.type = 'product.detail.tabs',
    n.label = 'Stock Info',
    n.icon = null,
    n.path = '/product-stock',
    n.priority = 50,
    n.scope = 'product',
    n.rendering = 'plugin-iframe';

// --- ExternalSystem ---
MERGE (n:ExternalSystem {id: 'ext-anthropic'})
SET n.name = 'Anthropic API',
    n.kind = 'LLM provider';
MERGE (n:ExternalSystem {id: 'ext-langfuse'})
SET n.name = 'Langfuse',
    n.kind = 'LLM observability';
MERGE (n:ExternalSystem {id: 'ext-litellm'})
SET n.name = 'LiteLLM Proxy',
    n.kind = 'LLM proxy';
MERGE (n:ExternalSystem {id: 'ext-openai'})
SET n.name = 'OpenAI API',
    n.kind = 'LLM provider';
MERGE (n:ExternalSystem {id: 'ext-postgres'})
SET n.name = 'PostgreSQL',
    n.kind = 'RDBMS';
MERGE (n:ExternalSystem {id: 'ext-presidio'})
SET n.name = 'Presidio',
    n.kind = 'PII detection / redaction';

// --- Feature ---
MERGE (n:Feature {id: 'feat-browse-products'})
SET n.name = 'Browse Products',
    n.owner = 'host',
    n.scope = 'product-list';
MERGE (n:Feature {id: 'feat-capture-box-size'})
SET n.name = 'Capture Box Dimensions',
    n.owner = 'plugin',
    n.scope = 'product-detail';
MERGE (n:Feature {id: 'feat-filter-by-stock'})
SET n.name = 'Filter Products by Stock',
    n.owner = 'plugin',
    n.scope = 'product-list';
MERGE (n:Feature {id: 'feat-generate-ai-description'})
SET n.name = 'Generate AI Product Description',
    n.owner = 'plugin',
    n.scope = 'product-detail';
MERGE (n:Feature {id: 'feat-manage-categories'})
SET n.name = 'Manage Categories',
    n.owner = 'host',
    n.scope = 'catalog';
MERGE (n:Feature {id: 'feat-manage-plugins'})
SET n.name = 'Manage Plugins',
    n.owner = 'host',
    n.scope = 'plugin-management';
MERGE (n:Feature {id: 'feat-manage-products'})
SET n.name = 'Manage Products',
    n.owner = 'host',
    n.scope = 'catalog';
MERGE (n:Feature {id: 'feat-manage-warehouses'})
SET n.name = 'Manage Warehouses',
    n.owner = 'plugin',
    n.scope = 'catalog';
MERGE (n:Feature {id: 'feat-product-availability'})
SET n.name = 'Show Product Availability',
    n.owner = 'plugin',
    n.scope = 'product-detail';
MERGE (n:Feature {id: 'feat-register-plugin'})
SET n.name = 'Register Plugin (manifest)',
    n.owner = 'host',
    n.scope = 'plugin-management';
MERGE (n:Feature {id: 'feat-show-box-size'})
SET n.name = 'Show Box Dimensions Badge',
    n.owner = 'plugin',
    n.scope = 'product-detail';
MERGE (n:Feature {id: 'feat-toggle-plugin'})
SET n.name = 'Enable / Disable Plugin',
    n.owner = 'host',
    n.scope = 'plugin-management';
MERGE (n:Feature {id: 'feat-track-stock'})
SET n.name = 'Track Product Stock',
    n.owner = 'plugin',
    n.scope = 'product-detail';
MERGE (n:Feature {id: 'feat-view-product-details'})
SET n.name = 'View Product Details',
    n.owner = 'host',
    n.scope = 'product-detail';

// --- FilterDefinition ---
MERGE (n:FilterDefinition {id: 'filter-warehouse-stock'})
SET n.filterKey = 'stock',
    n.filterType = 'boolean',
    n.label = 'In Stock',
    n.priority = 10;

// --- Frontend ---
MERGE (n:Frontend {id: 'aj-frontend'})
SET n.name = 'AJ Frontend',
    n.path = 'src/main/frontend',
    n.language = 'TypeScript',
    n.framework = 'React 19 + Vite',
    n.router = 'React Router 7';

// --- Host ---
MERGE (n:Host {id: 'aj-host'})
SET n.name = 'AJ Application Host',
    n.entrypoint = 'pl.devstyle.aj.AjApplication',
    n.port = 8080;

// --- HostBridge ---
MERGE (n:HostBridge {id: 'aj-host-bridge'})
SET n.operations = ['getProducts', 'getProduct', 'getPlugins', 'pluginFetch', 'getData', 'setData', 'removeData', 'objectsList', 'objectsListByEntity', 'objectsGet', 'objectsSave', 'objectsDelete', 'filterChange'],
    n.constraints = 'pluginFetch only allows /api/ paths, strips credentials, rejects path traversal (..), and only returns CORS-safelisted response headers.';

// --- IframeIsolation ---
MERGE (n:IframeIsolation {id: 'aj-iframe-isolation'})
SET n.sandboxFlags = 'allow-scripts allow-same-origin allow-forms allow-popups allow-modals allow-downloads',
    n.originCheck = 'PluginMessageHandler verifies event.origin matches the registered plugin URL origin and that the source iframe is registered.';

// --- Manifest ---
MERGE (n:Manifest {id: 'manifest-ai-description'})
SET n.name = 'AI Description',
    n.version = '1.0.0',
    n.url = 'http://localhost:3003',
    n.description = 'Generate AI-powered product descriptions',
    n.extensionPoints = ['product.detail.tabs'];
MERGE (n:Manifest {id: 'manifest-box-size'})
SET n.name = 'Box Size',
    n.version = '1.0.0',
    n.url = 'http://localhost:3002',
    n.description = 'Track box dimensions (L×W×H in cm) for products',
    n.extensionPoints = ['product.detail.tabs', 'product.detail.info'];
MERGE (n:Manifest {id: 'manifest-warehouse'})
SET n.name = 'Warehouse Management',
    n.version = '1.0.0',
    n.url = 'http://localhost:3001',
    n.description = 'Manages warehouse inventory and stock levels',
    n.extensionPoints = ['menu.main', 'product.detail.tabs', 'product.list.filters', 'product.detail.info'];

// --- Module ---
MERGE (n:Module {id: 'mod-api'})
SET n.name = 'API Surface Module',
    n.package = 'pl.devstyle.aj.api';
MERGE (n:Module {id: 'mod-category'})
SET n.name = 'Category Module',
    n.package = 'pl.devstyle.aj.category';
MERGE (n:Module {id: 'mod-plugin-core'})
SET n.name = 'Plugin Core Module',
    n.package = 'pl.devstyle.aj.core.plugin';
MERGE (n:Module {id: 'mod-product'})
SET n.name = 'Product Module',
    n.package = 'pl.devstyle.aj.product';

// --- Plugin ---
MERGE (n:Plugin {id: 'plugin-ai-description'})
SET n.pluginId = 'ai-description',
    n.name = 'AI Description',
    n.version = '1.0.0',
    n.url = 'http://localhost:3003',
    n.description = 'Generate AI-powered product descriptions',
    n.enabled = true,
    n.path = 'plugins/ai-description';
MERGE (n:Plugin {id: 'plugin-box-size'})
SET n.pluginId = 'box-size',
    n.name = 'Box Size',
    n.version = '1.0.0',
    n.url = 'http://localhost:3002',
    n.description = 'Track box dimensions (L×W×H in cm) for products',
    n.enabled = true,
    n.path = 'plugins/box-size';
MERGE (n:Plugin {id: 'plugin-warehouse'})
SET n.pluginId = 'warehouse',
    n.name = 'Warehouse Management',
    n.version = '1.0.0',
    n.url = 'http://localhost:3001',
    n.description = 'Manages warehouse inventory and stock levels',
    n.enabled = true,
    n.path = 'plugins/warehouse';

// --- PluginEngine ---
MERGE (n:PluginEngine {id: 'aj-plugin-engine'})
SET n.name = 'AJ Plugin Engine',
    n.rootPackage = 'pl.devstyle.aj.core.plugin',
    n.services = ['PluginDescriptorService', 'PluginObjectService', 'PluginDataService', 'DbPluginObjectQueryService'];

// --- PluginEntity ---
MERGE (n:PluginEntity {id: 'pe-warehouse-warehouse'})
SET n.name = 'Warehouse',
    n.storage = 'plugin_objects (objectType=warehouse, no entity binding)';

// --- PluginPage ---
MERGE (n:PluginPage {id: 'pp-ai-description-product-tab'})
SET n.name = 'ProductTab',
    n.route = '/product-tab',
    n.component = 'ProductTab',
    n.extensionPoint = 'product.detail.tabs';
MERGE (n:PluginPage {id: 'pp-box-size-product-box-badge'})
SET n.name = 'ProductBoxBadge',
    n.route = '/ProductBoxBadge',
    n.component = 'ProductBoxBadge',
    n.extensionPoint = null;
MERGE (n:PluginPage {id: 'pp-box-size-product-box-tab'})
SET n.name = 'ProductBoxTab',
    n.route = '/ProductBoxTab',
    n.component = 'ProductBoxTab',
    n.extensionPoint = null;
MERGE (n:PluginPage {id: 'pp-warehouse-product-availability'})
SET n.name = 'ProductAvailability',
    n.route = '/ProductAvailability',
    n.component = 'ProductAvailability',
    n.extensionPoint = null;
MERGE (n:PluginPage {id: 'pp-warehouse-product-stock-tab'})
SET n.name = 'ProductStockTab',
    n.route = '/ProductStockTab',
    n.component = 'ProductStockTab',
    n.extensionPoint = null;
MERGE (n:PluginPage {id: 'pp-warehouse-warehouse-page'})
SET n.name = 'WarehousePage',
    n.route = '/WarehousePage',
    n.component = 'WarehousePage',
    n.extensionPoint = null;

// --- PluginSDK ---
MERGE (n:PluginSDK {id: 'aj-plugin-sdk'})
SET n.facades = ['hostApp', 'thisPlugin'],
    n.contextFields = ['extensionPoint', 'pluginId', 'pluginName', 'hostOrigin', 'productId'];

// --- PluginShell ---
MERGE (n:PluginShell {id: 'aj-plugin-shell'})
SET n.name = 'AJ Plugin Shell',
    n.entrypoint = 'src/main/frontend/src/main.tsx',
    n.notes = 'AppShell + PluginContext + PluginFrame + iframeRegistry + PluginMessageHandler + plugin-sdk host.';

// --- Repository ---
MERGE (n:Repository {id: 'repo-category'})
SET n.name = 'CategoryRepository',
    n.fqcn = 'pl.devstyle.aj.category.CategoryRepository',
    n.kind = 'JpaRepository';
MERGE (n:Repository {id: 'repo-db-plugin-object-query-service'})
SET n.name = 'DbPluginObjectQueryService',
    n.fqcn = 'pl.devstyle.aj.core.plugin.DbPluginObjectQueryService',
    n.kind = 'jOOQ DSLContext';
MERGE (n:Repository {id: 'repo-db-product-query-service'})
SET n.name = 'DbProductQueryService',
    n.fqcn = 'pl.devstyle.aj.product.DbProductQueryService',
    n.kind = 'jOOQ DSLContext';
MERGE (n:Repository {id: 'repo-plugin-descriptor'})
SET n.name = 'PluginDescriptorRepository',
    n.fqcn = 'pl.devstyle.aj.core.plugin.PluginDescriptorRepository',
    n.kind = 'JpaRepository';
MERGE (n:Repository {id: 'repo-plugin-object'})
SET n.name = 'PluginObjectRepository',
    n.fqcn = 'pl.devstyle.aj.core.plugin.PluginObjectRepository',
    n.kind = 'JpaRepository';
MERGE (n:Repository {id: 'repo-product'})
SET n.name = 'ProductRepository',
    n.fqcn = 'pl.devstyle.aj.product.ProductRepository',
    n.kind = 'JpaRepository';

// --- StorageStrategy ---
MERGE (n:StorageStrategy {id: 'storage-namespaced-plugin-data'})
SET n.kind = 'namespaced-plugin-data',
    n.location = 'products.plugin_data JSONB column, namespaced by pluginId',
    n.scope = 'per-entity';
MERGE (n:StorageStrategy {id: 'storage-plugin-custom-object'})
SET n.kind = 'plugin-custom-object',
    n.location = 'plugin_objects table keyed by (pluginId, objectType, objectId)',
    n.scope = 'plugin-collection';

// --- System ---
MERGE (n:System {id: 'aj-platform'})
SET n.name = 'AJ Platform',
    n.groupId = 'pl.devstyle',
    n.artifactId = 'aj',
    n.version = '0.0.1-SNAPSHOT',
    n.framework = 'Spring Boot 4.0.5';

// EDGES
MATCH (s:Feature {id:'feat-browse-products'}), (t:Action {id:'action-product-findall'}) MERGE (s)-[:BACKED_BY]->(t);
MATCH (s:Feature {id:'feat-capture-box-size'}), (t:Action {id:'action-plugin-data-getdata'}) MERGE (s)-[:BACKED_BY]->(t);
MATCH (s:Feature {id:'feat-capture-box-size'}), (t:Action {id:'action-plugin-data-removedata'}) MERGE (s)-[:BACKED_BY]->(t);
MATCH (s:Feature {id:'feat-capture-box-size'}), (t:Action {id:'action-plugin-data-setdata'}) MERGE (s)-[:BACKED_BY]->(t);
MATCH (s:Feature {id:'feat-filter-by-stock'}), (t:Action {id:'action-product-findall'}) MERGE (s)-[:BACKED_BY]->(t);
MATCH (s:Feature {id:'feat-generate-ai-description'}), (t:Action {id:'action-plugin-object-listbyentity'}) MERGE (s)-[:BACKED_BY]->(t);
MATCH (s:Feature {id:'feat-generate-ai-description'}), (t:Action {id:'action-plugin-object-save'}) MERGE (s)-[:BACKED_BY]->(t);
MATCH (s:Feature {id:'feat-generate-ai-description'}), (t:Action {id:'action-product-findbyid'}) MERGE (s)-[:BACKED_BY]->(t);
MATCH (s:Feature {id:'feat-manage-categories'}), (t:Action {id:'action-category-create'}) MERGE (s)-[:BACKED_BY]->(t);
MATCH (s:Feature {id:'feat-manage-categories'}), (t:Action {id:'action-category-delete'}) MERGE (s)-[:BACKED_BY]->(t);
MATCH (s:Feature {id:'feat-manage-categories'}), (t:Action {id:'action-category-findall'}) MERGE (s)-[:BACKED_BY]->(t);
MATCH (s:Feature {id:'feat-manage-categories'}), (t:Action {id:'action-category-findbyid'}) MERGE (s)-[:BACKED_BY]->(t);
MATCH (s:Feature {id:'feat-manage-categories'}), (t:Action {id:'action-category-update'}) MERGE (s)-[:BACKED_BY]->(t);
MATCH (s:Feature {id:'feat-manage-plugins'}), (t:Action {id:'action-plugin-descriptor-delete'}) MERGE (s)-[:BACKED_BY]->(t);
MATCH (s:Feature {id:'feat-manage-plugins'}), (t:Action {id:'action-plugin-descriptor-findallenabled'}) MERGE (s)-[:BACKED_BY]->(t);
MATCH (s:Feature {id:'feat-manage-plugins'}), (t:Action {id:'action-plugin-descriptor-findbyid'}) MERGE (s)-[:BACKED_BY]->(t);
MATCH (s:Feature {id:'feat-manage-products'}), (t:Action {id:'action-product-create'}) MERGE (s)-[:BACKED_BY]->(t);
MATCH (s:Feature {id:'feat-manage-products'}), (t:Action {id:'action-product-delete'}) MERGE (s)-[:BACKED_BY]->(t);
MATCH (s:Feature {id:'feat-manage-products'}), (t:Action {id:'action-product-update'}) MERGE (s)-[:BACKED_BY]->(t);
MATCH (s:Feature {id:'feat-manage-warehouses'}), (t:Action {id:'action-plugin-object-delete'}) MERGE (s)-[:BACKED_BY]->(t);
MATCH (s:Feature {id:'feat-manage-warehouses'}), (t:Action {id:'action-plugin-object-list'}) MERGE (s)-[:BACKED_BY]->(t);
MATCH (s:Feature {id:'feat-manage-warehouses'}), (t:Action {id:'action-plugin-object-save'}) MERGE (s)-[:BACKED_BY]->(t);
MATCH (s:Feature {id:'feat-product-availability'}), (t:Action {id:'action-plugin-data-getdata'}) MERGE (s)-[:BACKED_BY]->(t);
MATCH (s:Feature {id:'feat-register-plugin'}), (t:Action {id:'action-plugin-descriptor-uploadmanifest'}) MERGE (s)-[:BACKED_BY]->(t);
MATCH (s:Feature {id:'feat-show-box-size'}), (t:Action {id:'action-plugin-data-getdata'}) MERGE (s)-[:BACKED_BY]->(t);
MATCH (s:Feature {id:'feat-toggle-plugin'}), (t:Action {id:'action-plugin-descriptor-setenabled'}) MERGE (s)-[:BACKED_BY]->(t);
MATCH (s:Feature {id:'feat-track-stock'}), (t:Action {id:'action-plugin-data-setdata'}) MERGE (s)-[:BACKED_BY]->(t);
MATCH (s:Feature {id:'feat-track-stock'}), (t:Action {id:'action-plugin-object-listbyentity'}) MERGE (s)-[:BACKED_BY]->(t);
MATCH (s:Feature {id:'feat-track-stock'}), (t:Action {id:'action-plugin-object-save'}) MERGE (s)-[:BACKED_BY]->(t);
MATCH (s:Feature {id:'feat-view-product-details'}), (t:Action {id:'action-product-findbyid'}) MERGE (s)-[:BACKED_BY]->(t);
MATCH (s:Plugin {id:'plugin-ai-description'}), (t:HostBridge {id:'aj-host-bridge'}) MERGE (s)-[:COMMUNICATES_VIA]->(t);
MATCH (s:Plugin {id:'plugin-box-size'}), (t:HostBridge {id:'aj-host-bridge'}) MERGE (s)-[:COMMUNICATES_VIA]->(t);
MATCH (s:Plugin {id:'plugin-warehouse'}), (t:HostBridge {id:'aj-host-bridge'}) MERGE (s)-[:COMMUNICATES_VIA]->(t);
MATCH (s:Backend {id:'aj-backend'}), (t:Core {id:'aj-core'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Backend {id:'aj-backend'}), (t:Module {id:'mod-api'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Backend {id:'aj-backend'}), (t:Module {id:'mod-category'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Backend {id:'aj-backend'}), (t:Module {id:'mod-plugin-core'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Backend {id:'aj-backend'}), (t:Module {id:'mod-product'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Core {id:'aj-core'}), (t:PluginEngine {id:'aj-plugin-engine'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Frontend {id:'aj-frontend'}), (t:PluginShell {id:'aj-plugin-shell'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Frontend {id:'aj-frontend'}), (t:CorePage {id:'page-category-form'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Frontend {id:'aj-frontend'}), (t:CorePage {id:'page-category-list'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Frontend {id:'aj-frontend'}), (t:CorePage {id:'page-layout'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Frontend {id:'aj-frontend'}), (t:CorePage {id:'page-plugin-detail'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Frontend {id:'aj-frontend'}), (t:CorePage {id:'page-plugin-form'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Frontend {id:'aj-frontend'}), (t:CorePage {id:'page-plugin-list'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Frontend {id:'aj-frontend'}), (t:CorePage {id:'page-product-detail'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Frontend {id:'aj-frontend'}), (t:CorePage {id:'page-product-form'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Frontend {id:'aj-frontend'}), (t:CorePage {id:'page-product-list'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Host {id:'aj-host'}), (t:Backend {id:'aj-backend'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Host {id:'aj-host'}), (t:Frontend {id:'aj-frontend'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:System {id:'aj-platform'}), (t:Host {id:'aj-host'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:System {id:'aj-platform'}), (t:Plugin {id:'plugin-ai-description'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:System {id:'aj-platform'}), (t:Plugin {id:'plugin-box-size'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:System {id:'aj-platform'}), (t:Plugin {id:'plugin-warehouse'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Module {id:'mod-api'}), (t:APIEndpoints {id:'api-health-health'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Module {id:'mod-category'}), (t:Action {id:'action-category-create'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Module {id:'mod-category'}), (t:Action {id:'action-category-delete'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Module {id:'mod-category'}), (t:Action {id:'action-category-findall'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Module {id:'mod-category'}), (t:Action {id:'action-category-findbyid'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Module {id:'mod-category'}), (t:Action {id:'action-category-update'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Module {id:'mod-category'}), (t:APIEndpoints {id:'api-category-create'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Module {id:'mod-category'}), (t:APIEndpoints {id:'api-category-delete'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Module {id:'mod-category'}), (t:APIEndpoints {id:'api-category-getbyid'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Module {id:'mod-category'}), (t:APIEndpoints {id:'api-category-list'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Module {id:'mod-category'}), (t:APIEndpoints {id:'api-category-update'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Module {id:'mod-category'}), (t:Entity {id:'entity-category'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Module {id:'mod-plugin-core'}), (t:Action {id:'action-plugin-data-getdata'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Module {id:'mod-plugin-core'}), (t:Action {id:'action-plugin-data-removedata'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Module {id:'mod-plugin-core'}), (t:Action {id:'action-plugin-data-setdata'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Module {id:'mod-plugin-core'}), (t:Action {id:'action-plugin-descriptor-delete'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Module {id:'mod-plugin-core'}), (t:Action {id:'action-plugin-descriptor-findallenabled'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Module {id:'mod-plugin-core'}), (t:Action {id:'action-plugin-descriptor-findbyid'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Module {id:'mod-plugin-core'}), (t:Action {id:'action-plugin-descriptor-findenabledorthrow'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Module {id:'mod-plugin-core'}), (t:Action {id:'action-plugin-descriptor-setenabled'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Module {id:'mod-plugin-core'}), (t:Action {id:'action-plugin-descriptor-uploadmanifest'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Module {id:'mod-plugin-core'}), (t:Action {id:'action-plugin-object-delete'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Module {id:'mod-plugin-core'}), (t:Action {id:'action-plugin-object-get'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Module {id:'mod-plugin-core'}), (t:Action {id:'action-plugin-object-list'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Module {id:'mod-plugin-core'}), (t:Action {id:'action-plugin-object-listbyentity'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Module {id:'mod-plugin-core'}), (t:Action {id:'action-plugin-object-save'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Module {id:'mod-plugin-core'}), (t:APIEndpoints {id:'api-plugin-data-delete'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Module {id:'mod-plugin-core'}), (t:APIEndpoints {id:'api-plugin-data-get'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Module {id:'mod-plugin-core'}), (t:APIEndpoints {id:'api-plugin-data-put'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Module {id:'mod-plugin-core'}), (t:APIEndpoints {id:'api-plugin-delete'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Module {id:'mod-plugin-core'}), (t:APIEndpoints {id:'api-plugin-getbyid'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Module {id:'mod-plugin-core'}), (t:APIEndpoints {id:'api-plugin-list'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Module {id:'mod-plugin-core'}), (t:APIEndpoints {id:'api-plugin-object-delete'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Module {id:'mod-plugin-core'}), (t:APIEndpoints {id:'api-plugin-object-get'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Module {id:'mod-plugin-core'}), (t:APIEndpoints {id:'api-plugin-object-list'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Module {id:'mod-plugin-core'}), (t:APIEndpoints {id:'api-plugin-object-listbyentity'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Module {id:'mod-plugin-core'}), (t:APIEndpoints {id:'api-plugin-object-save'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Module {id:'mod-plugin-core'}), (t:APIEndpoints {id:'api-plugin-setenabled'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Module {id:'mod-plugin-core'}), (t:APIEndpoints {id:'api-plugin-uploadmanifest'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Module {id:'mod-plugin-core'}), (t:Entity {id:'entity-plugin-descriptor'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Module {id:'mod-plugin-core'}), (t:Entity {id:'entity-plugin-object'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Module {id:'mod-product'}), (t:Action {id:'action-product-create'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Module {id:'mod-product'}), (t:Action {id:'action-product-delete'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Module {id:'mod-product'}), (t:Action {id:'action-product-findall'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Module {id:'mod-product'}), (t:Action {id:'action-product-findbyid'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Module {id:'mod-product'}), (t:Action {id:'action-product-update'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Module {id:'mod-product'}), (t:APIEndpoints {id:'api-product-create'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Module {id:'mod-product'}), (t:APIEndpoints {id:'api-product-delete'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Module {id:'mod-product'}), (t:APIEndpoints {id:'api-product-getbyid'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Module {id:'mod-product'}), (t:APIEndpoints {id:'api-product-list'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Module {id:'mod-product'}), (t:APIEndpoints {id:'api-product-update'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Module {id:'mod-product'}), (t:Entity {id:'entity-product'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Plugin {id:'plugin-ai-description'}), (t:API {id:'api-ai-description'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Plugin {id:'plugin-ai-description'}), (t:ExtendedEntity {id:'ee-aidesc-data'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Plugin {id:'plugin-ai-description'}), (t:PluginPage {id:'pp-ai-description-product-tab'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Plugin {id:'plugin-box-size'}), (t:API {id:'api-box-size'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Plugin {id:'plugin-box-size'}), (t:ExtendedEntity {id:'ee-boxsize-data'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Plugin {id:'plugin-box-size'}), (t:PluginPage {id:'pp-box-size-product-box-badge'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Plugin {id:'plugin-box-size'}), (t:PluginPage {id:'pp-box-size-product-box-tab'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Plugin {id:'plugin-warehouse'}), (t:API {id:'api-warehouse'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Plugin {id:'plugin-warehouse'}), (t:ExtendedEntity {id:'ee-warehouse-stock-entry'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Plugin {id:'plugin-warehouse'}), (t:ExtendedEntity {id:'ee-warehouse-stock-flag'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Plugin {id:'plugin-warehouse'}), (t:PluginEntity {id:'pe-warehouse-warehouse'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Plugin {id:'plugin-warehouse'}), (t:PluginPage {id:'pp-warehouse-product-availability'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Plugin {id:'plugin-warehouse'}), (t:PluginPage {id:'pp-warehouse-product-stock-tab'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Plugin {id:'plugin-warehouse'}), (t:PluginPage {id:'pp-warehouse-warehouse-page'}) MERGE (s)-[:CONTAINS]->(t);
MATCH (s:Manifest {id:'manifest-ai-description'}), (t:ExtensionPoint {id:'ep-ai-description-product-detail-tabs-ai-description'}) MERGE (s)-[:DECLARES]->(t);
MATCH (s:Manifest {id:'manifest-box-size'}), (t:ExtensionPoint {id:'ep-box-size-product-detail-info-box-size'}) MERGE (s)-[:DECLARES]->(t);
MATCH (s:Manifest {id:'manifest-box-size'}), (t:ExtensionPoint {id:'ep-box-size-product-detail-tabs-box-size'}) MERGE (s)-[:DECLARES]->(t);
MATCH (s:Manifest {id:'manifest-warehouse'}), (t:ExtensionPoint {id:'ep-warehouse-menu-main-warehouse'}) MERGE (s)-[:DECLARES]->(t);
MATCH (s:Manifest {id:'manifest-warehouse'}), (t:ExtensionPoint {id:'ep-warehouse-product-detail-info-availability'}) MERGE (s)-[:DECLARES]->(t);
MATCH (s:Manifest {id:'manifest-warehouse'}), (t:ExtensionPoint {id:'ep-warehouse-product-detail-tabs-stock-info'}) MERGE (s)-[:DECLARES]->(t);
MATCH (s:Manifest {id:'manifest-warehouse'}), (t:FilterDefinition {id:'filter-warehouse-stock'}) MERGE (s)-[:DECLARES]->(t);
MATCH (s:Plugin {id:'plugin-ai-description'}), (t:Manifest {id:'manifest-ai-description'}) MERGE (s)-[:DECLARES]->(t);
MATCH (s:Plugin {id:'plugin-box-size'}), (t:Manifest {id:'manifest-box-size'}) MERGE (s)-[:DECLARES]->(t);
MATCH (s:Plugin {id:'plugin-warehouse'}), (t:Manifest {id:'manifest-warehouse'}) MERGE (s)-[:DECLARES]->(t);
MATCH (s:Plugin {id:'plugin-ai-description'}), (t:DomainConcept {id:'dc-ai-description-product-description'}) MERGE (s)-[:DEFINES]->(t);
MATCH (s:Plugin {id:'plugin-box-size'}), (t:DomainConcept {id:'dc-box-size-box-dimensions'}) MERGE (s)-[:DEFINES]->(t);
MATCH (s:Plugin {id:'plugin-warehouse'}), (t:DomainConcept {id:'dc-warehouse-product'}) MERGE (s)-[:DEFINES]->(t);
MATCH (s:Plugin {id:'plugin-warehouse'}), (t:DomainConcept {id:'dc-warehouse-stock-entry'}) MERGE (s)-[:DEFINES]->(t);
MATCH (s:Plugin {id:'plugin-warehouse'}), (t:DomainConcept {id:'dc-warehouse-warehouse'}) MERGE (s)-[:DEFINES]->(t);
MATCH (s:Feature {id:'feat-capture-box-size'}), (t:ExtensionPoint {id:'ep-box-size-product-detail-tabs-box-size'}) MERGE (s)-[:DELIVERED_VIA]->(t);
MATCH (s:Feature {id:'feat-generate-ai-description'}), (t:ExtensionPoint {id:'ep-ai-description-product-detail-tabs-ai-description'}) MERGE (s)-[:DELIVERED_VIA]->(t);
MATCH (s:Feature {id:'feat-manage-warehouses'}), (t:ExtensionPoint {id:'ep-warehouse-menu-main-warehouse'}) MERGE (s)-[:DELIVERED_VIA]->(t);
MATCH (s:Feature {id:'feat-product-availability'}), (t:ExtensionPoint {id:'ep-warehouse-product-detail-info-availability'}) MERGE (s)-[:DELIVERED_VIA]->(t);
MATCH (s:Feature {id:'feat-show-box-size'}), (t:ExtensionPoint {id:'ep-box-size-product-detail-info-box-size'}) MERGE (s)-[:DELIVERED_VIA]->(t);
MATCH (s:Feature {id:'feat-track-stock'}), (t:ExtensionPoint {id:'ep-warehouse-product-detail-tabs-stock-info'}) MERGE (s)-[:DELIVERED_VIA]->(t);
MATCH (s:Frontend {id:'aj-frontend'}), (t:Plugin {id:'plugin-ai-description'}) MERGE (s)-[:EMBEDS]->(t);
MATCH (s:Frontend {id:'aj-frontend'}), (t:Plugin {id:'plugin-box-size'}) MERGE (s)-[:EMBEDS]->(t);
MATCH (s:Frontend {id:'aj-frontend'}), (t:Plugin {id:'plugin-warehouse'}) MERGE (s)-[:EMBEDS]->(t);
MATCH (s:Entity {id:'entity-category'}), (t:APIEndpoints {id:'api-category-create'}) MERGE (s)-[:EXPOSED_BY]->(t);
MATCH (s:Entity {id:'entity-category'}), (t:APIEndpoints {id:'api-category-delete'}) MERGE (s)-[:EXPOSED_BY]->(t);
MATCH (s:Entity {id:'entity-category'}), (t:APIEndpoints {id:'api-category-getbyid'}) MERGE (s)-[:EXPOSED_BY]->(t);
MATCH (s:Entity {id:'entity-category'}), (t:APIEndpoints {id:'api-category-list'}) MERGE (s)-[:EXPOSED_BY]->(t);
MATCH (s:Entity {id:'entity-category'}), (t:APIEndpoints {id:'api-category-update'}) MERGE (s)-[:EXPOSED_BY]->(t);
MATCH (s:Entity {id:'entity-plugin-descriptor'}), (t:APIEndpoints {id:'api-plugin-delete'}) MERGE (s)-[:EXPOSED_BY]->(t);
MATCH (s:Entity {id:'entity-plugin-descriptor'}), (t:APIEndpoints {id:'api-plugin-getbyid'}) MERGE (s)-[:EXPOSED_BY]->(t);
MATCH (s:Entity {id:'entity-plugin-descriptor'}), (t:APIEndpoints {id:'api-plugin-list'}) MERGE (s)-[:EXPOSED_BY]->(t);
MATCH (s:Entity {id:'entity-plugin-descriptor'}), (t:APIEndpoints {id:'api-plugin-setenabled'}) MERGE (s)-[:EXPOSED_BY]->(t);
MATCH (s:Entity {id:'entity-plugin-descriptor'}), (t:APIEndpoints {id:'api-plugin-uploadmanifest'}) MERGE (s)-[:EXPOSED_BY]->(t);
MATCH (s:Entity {id:'entity-plugin-object'}), (t:APIEndpoints {id:'api-plugin-object-delete'}) MERGE (s)-[:EXPOSED_BY]->(t);
MATCH (s:Entity {id:'entity-plugin-object'}), (t:APIEndpoints {id:'api-plugin-object-get'}) MERGE (s)-[:EXPOSED_BY]->(t);
MATCH (s:Entity {id:'entity-plugin-object'}), (t:APIEndpoints {id:'api-plugin-object-list'}) MERGE (s)-[:EXPOSED_BY]->(t);
MATCH (s:Entity {id:'entity-plugin-object'}), (t:APIEndpoints {id:'api-plugin-object-listbyentity'}) MERGE (s)-[:EXPOSED_BY]->(t);
MATCH (s:Entity {id:'entity-plugin-object'}), (t:APIEndpoints {id:'api-plugin-object-save'}) MERGE (s)-[:EXPOSED_BY]->(t);
MATCH (s:Entity {id:'entity-product'}), (t:APIEndpoints {id:'api-plugin-data-delete'}) MERGE (s)-[:EXPOSED_BY]->(t);
MATCH (s:Entity {id:'entity-product'}), (t:APIEndpoints {id:'api-plugin-data-get'}) MERGE (s)-[:EXPOSED_BY]->(t);
MATCH (s:Entity {id:'entity-product'}), (t:APIEndpoints {id:'api-plugin-data-put'}) MERGE (s)-[:EXPOSED_BY]->(t);
MATCH (s:Entity {id:'entity-product'}), (t:APIEndpoints {id:'api-product-create'}) MERGE (s)-[:EXPOSED_BY]->(t);
MATCH (s:Entity {id:'entity-product'}), (t:APIEndpoints {id:'api-product-delete'}) MERGE (s)-[:EXPOSED_BY]->(t);
MATCH (s:Entity {id:'entity-product'}), (t:APIEndpoints {id:'api-product-getbyid'}) MERGE (s)-[:EXPOSED_BY]->(t);
MATCH (s:Entity {id:'entity-product'}), (t:APIEndpoints {id:'api-product-list'}) MERGE (s)-[:EXPOSED_BY]->(t);
MATCH (s:Entity {id:'entity-product'}), (t:APIEndpoints {id:'api-product-update'}) MERGE (s)-[:EXPOSED_BY]->(t);
MATCH (s:Plugin {id:'plugin-ai-description'}), (t:ExtensionPoint {id:'ep-ai-description-product-detail-tabs-ai-description'}) MERGE (s)-[:EXPOSES]->(t);
MATCH (s:Plugin {id:'plugin-box-size'}), (t:ExtensionPoint {id:'ep-box-size-product-detail-info-box-size'}) MERGE (s)-[:EXPOSES]->(t);
MATCH (s:Plugin {id:'plugin-box-size'}), (t:ExtensionPoint {id:'ep-box-size-product-detail-tabs-box-size'}) MERGE (s)-[:EXPOSES]->(t);
MATCH (s:Plugin {id:'plugin-warehouse'}), (t:ExtensionPoint {id:'ep-warehouse-menu-main-warehouse'}) MERGE (s)-[:EXPOSES]->(t);
MATCH (s:Plugin {id:'plugin-warehouse'}), (t:ExtensionPoint {id:'ep-warehouse-product-detail-info-availability'}) MERGE (s)-[:EXPOSES]->(t);
MATCH (s:Plugin {id:'plugin-warehouse'}), (t:ExtensionPoint {id:'ep-warehouse-product-detail-tabs-stock-info'}) MERGE (s)-[:EXPOSES]->(t);
MATCH (s:ExtendedEntity {id:'ee-aidesc-data'}), (t:Entity {id:'entity-product'}) MERGE (s)-[:EXTENDS]->(t);
MATCH (s:ExtendedEntity {id:'ee-boxsize-data'}), (t:Entity {id:'entity-product'}) MERGE (s)-[:EXTENDS]->(t);
MATCH (s:ExtendedEntity {id:'ee-warehouse-stock-entry'}), (t:Entity {id:'entity-product'}) MERGE (s)-[:EXTENDS]->(t);
MATCH (s:ExtendedEntity {id:'ee-warehouse-stock-flag'}), (t:Entity {id:'entity-product'}) MERGE (s)-[:EXTENDS]->(t);
MATCH (s:ExtensionPoint {id:'ep-ai-description-product-detail-tabs-ai-description'}), (t:PluginPage {id:'pp-ai-description-product-tab'}) MERGE (s)-[:IMPLEMENTED_BY]->(t);
MATCH (s:ExtensionPoint {id:'ep-box-size-product-detail-info-box-size'}), (t:PluginPage {id:'pp-box-size-product-box-badge'}) MERGE (s)-[:IMPLEMENTED_BY]->(t);
MATCH (s:ExtensionPoint {id:'ep-box-size-product-detail-tabs-box-size'}), (t:PluginPage {id:'pp-box-size-product-box-tab'}) MERGE (s)-[:IMPLEMENTED_BY]->(t);
MATCH (s:ExtensionPoint {id:'ep-warehouse-menu-main-warehouse'}), (t:PluginPage {id:'pp-warehouse-warehouse-page'}) MERGE (s)-[:IMPLEMENTED_BY]->(t);
MATCH (s:ExtensionPoint {id:'ep-warehouse-product-detail-info-availability'}), (t:PluginPage {id:'pp-warehouse-product-availability'}) MERGE (s)-[:IMPLEMENTED_BY]->(t);
MATCH (s:ExtensionPoint {id:'ep-warehouse-product-detail-tabs-stock-info'}), (t:PluginPage {id:'pp-warehouse-product-stock-tab'}) MERGE (s)-[:IMPLEMENTED_BY]->(t);
MATCH (s:PluginEngine {id:'aj-plugin-engine'}), (t:Entity {id:'entity-plugin-descriptor'}) MERGE (s)-[:MANAGES]->(t);
MATCH (s:PluginEngine {id:'aj-plugin-engine'}), (t:Entity {id:'entity-plugin-object'}) MERGE (s)-[:MANAGES]->(t);
MATCH (s:PluginEntity {id:'pe-warehouse-warehouse'}), (t:EntityBinding {id:'binding-warehouse-stock-on-product'}) MERGE (s)-[:MAY_USE]->(t);
MATCH (s:Action {id:'action-category-create'}), (t:Entity {id:'entity-category'}) MERGE (s)-[:OPERATES_ON]->(t);
MATCH (s:Action {id:'action-category-delete'}), (t:Entity {id:'entity-category'}) MERGE (s)-[:OPERATES_ON]->(t);
MATCH (s:Action {id:'action-category-findall'}), (t:Entity {id:'entity-category'}) MERGE (s)-[:OPERATES_ON]->(t);
MATCH (s:Action {id:'action-category-findbyid'}), (t:Entity {id:'entity-category'}) MERGE (s)-[:OPERATES_ON]->(t);
MATCH (s:Action {id:'action-category-update'}), (t:Entity {id:'entity-category'}) MERGE (s)-[:OPERATES_ON]->(t);
MATCH (s:Action {id:'action-plugin-data-getdata'}), (t:Entity {id:'entity-product'}) MERGE (s)-[:OPERATES_ON]->(t);
MATCH (s:Action {id:'action-plugin-data-removedata'}), (t:Entity {id:'entity-product'}) MERGE (s)-[:OPERATES_ON]->(t);
MATCH (s:Action {id:'action-plugin-data-setdata'}), (t:Entity {id:'entity-product'}) MERGE (s)-[:OPERATES_ON]->(t);
MATCH (s:Action {id:'action-plugin-descriptor-delete'}), (t:Entity {id:'entity-plugin-descriptor'}) MERGE (s)-[:OPERATES_ON]->(t);
MATCH (s:Action {id:'action-plugin-descriptor-findallenabled'}), (t:Entity {id:'entity-plugin-descriptor'}) MERGE (s)-[:OPERATES_ON]->(t);
MATCH (s:Action {id:'action-plugin-descriptor-findbyid'}), (t:Entity {id:'entity-plugin-descriptor'}) MERGE (s)-[:OPERATES_ON]->(t);
MATCH (s:Action {id:'action-plugin-descriptor-findenabledorthrow'}), (t:Entity {id:'entity-plugin-descriptor'}) MERGE (s)-[:OPERATES_ON]->(t);
MATCH (s:Action {id:'action-plugin-descriptor-setenabled'}), (t:Entity {id:'entity-plugin-descriptor'}) MERGE (s)-[:OPERATES_ON]->(t);
MATCH (s:Action {id:'action-plugin-descriptor-uploadmanifest'}), (t:Entity {id:'entity-plugin-descriptor'}) MERGE (s)-[:OPERATES_ON]->(t);
MATCH (s:Action {id:'action-plugin-object-delete'}), (t:Entity {id:'entity-plugin-object'}) MERGE (s)-[:OPERATES_ON]->(t);
MATCH (s:Action {id:'action-plugin-object-get'}), (t:Entity {id:'entity-plugin-object'}) MERGE (s)-[:OPERATES_ON]->(t);
MATCH (s:Action {id:'action-plugin-object-list'}), (t:Entity {id:'entity-plugin-object'}) MERGE (s)-[:OPERATES_ON]->(t);
MATCH (s:Action {id:'action-plugin-object-listbyentity'}), (t:Entity {id:'entity-plugin-object'}) MERGE (s)-[:OPERATES_ON]->(t);
MATCH (s:Action {id:'action-plugin-object-save'}), (t:Entity {id:'entity-plugin-object'}) MERGE (s)-[:OPERATES_ON]->(t);
MATCH (s:Action {id:'action-product-create'}), (t:Entity {id:'entity-product'}) MERGE (s)-[:OPERATES_ON]->(t);
MATCH (s:Action {id:'action-product-delete'}), (t:Entity {id:'entity-product'}) MERGE (s)-[:OPERATES_ON]->(t);
MATCH (s:Action {id:'action-product-findall'}), (t:Entity {id:'entity-product'}) MERGE (s)-[:OPERATES_ON]->(t);
MATCH (s:Action {id:'action-product-findbyid'}), (t:Entity {id:'entity-product'}) MERGE (s)-[:OPERATES_ON]->(t);
MATCH (s:Action {id:'action-product-update'}), (t:Entity {id:'entity-product'}) MERGE (s)-[:OPERATES_ON]->(t);
MATCH (s:Feature {id:'feat-browse-products'}), (t:Actor {id:'catalog-operator'}) MERGE (s)-[:PERFORMED_BY]->(t);
MATCH (s:Feature {id:'feat-capture-box-size'}), (t:Actor {id:'catalog-operator'}) MERGE (s)-[:PERFORMED_BY]->(t);
MATCH (s:Feature {id:'feat-filter-by-stock'}), (t:Actor {id:'catalog-operator'}) MERGE (s)-[:PERFORMED_BY]->(t);
MATCH (s:Feature {id:'feat-generate-ai-description'}), (t:Actor {id:'catalog-operator'}) MERGE (s)-[:PERFORMED_BY]->(t);
MATCH (s:Feature {id:'feat-manage-categories'}), (t:Actor {id:'catalog-operator'}) MERGE (s)-[:PERFORMED_BY]->(t);
MATCH (s:Feature {id:'feat-manage-plugins'}), (t:Actor {id:'catalog-operator'}) MERGE (s)-[:PERFORMED_BY]->(t);
MATCH (s:Feature {id:'feat-manage-products'}), (t:Actor {id:'catalog-operator'}) MERGE (s)-[:PERFORMED_BY]->(t);
MATCH (s:Feature {id:'feat-manage-warehouses'}), (t:Actor {id:'catalog-operator'}) MERGE (s)-[:PERFORMED_BY]->(t);
MATCH (s:Feature {id:'feat-product-availability'}), (t:Actor {id:'catalog-operator'}) MERGE (s)-[:PERFORMED_BY]->(t);
MATCH (s:Feature {id:'feat-register-plugin'}), (t:Actor {id:'catalog-operator'}) MERGE (s)-[:PERFORMED_BY]->(t);
MATCH (s:Feature {id:'feat-show-box-size'}), (t:Actor {id:'catalog-operator'}) MERGE (s)-[:PERFORMED_BY]->(t);
MATCH (s:Feature {id:'feat-toggle-plugin'}), (t:Actor {id:'catalog-operator'}) MERGE (s)-[:PERFORMED_BY]->(t);
MATCH (s:Feature {id:'feat-track-stock'}), (t:Actor {id:'catalog-operator'}) MERGE (s)-[:PERFORMED_BY]->(t);
MATCH (s:Feature {id:'feat-view-product-details'}), (t:Actor {id:'catalog-operator'}) MERGE (s)-[:PERFORMED_BY]->(t);
MATCH (s:Entity {id:'entity-category'}), (t:Repository {id:'repo-category'}) MERGE (s)-[:PERSISTED_BY]->(t);
MATCH (s:Entity {id:'entity-plugin-descriptor'}), (t:Repository {id:'repo-plugin-descriptor'}) MERGE (s)-[:PERSISTED_BY]->(t);
MATCH (s:Entity {id:'entity-plugin-object'}), (t:Repository {id:'repo-db-plugin-object-query-service'}) MERGE (s)-[:PERSISTED_BY]->(t);
MATCH (s:Entity {id:'entity-plugin-object'}), (t:Repository {id:'repo-plugin-object'}) MERGE (s)-[:PERSISTED_BY]->(t);
MATCH (s:Entity {id:'entity-product'}), (t:Repository {id:'repo-db-product-query-service'}) MERGE (s)-[:PERSISTED_BY]->(t);
MATCH (s:Entity {id:'entity-product'}), (t:Repository {id:'repo-product'}) MERGE (s)-[:PERSISTED_BY]->(t);
MATCH (s:StorageStrategy {id:'storage-namespaced-plugin-data'}), (t:Entity {id:'entity-product'}) MERGE (s)-[:PERSISTED_IN]->(t);
MATCH (s:StorageStrategy {id:'storage-plugin-custom-object'}), (t:Entity {id:'entity-plugin-object'}) MERGE (s)-[:PERSISTED_IN]->(t);
MATCH (s:HostBridge {id:'aj-host-bridge'}), (t:APIEndpoints {id:'api-plugin-data-delete'}) MERGE (s)-[:PROXIES_TO]->(t);
MATCH (s:HostBridge {id:'aj-host-bridge'}), (t:APIEndpoints {id:'api-plugin-data-get'}) MERGE (s)-[:PROXIES_TO]->(t);
MATCH (s:HostBridge {id:'aj-host-bridge'}), (t:APIEndpoints {id:'api-plugin-data-put'}) MERGE (s)-[:PROXIES_TO]->(t);
MATCH (s:HostBridge {id:'aj-host-bridge'}), (t:APIEndpoints {id:'api-plugin-list'}) MERGE (s)-[:PROXIES_TO]->(t);
MATCH (s:HostBridge {id:'aj-host-bridge'}), (t:APIEndpoints {id:'api-plugin-object-delete'}) MERGE (s)-[:PROXIES_TO]->(t);
MATCH (s:HostBridge {id:'aj-host-bridge'}), (t:APIEndpoints {id:'api-plugin-object-get'}) MERGE (s)-[:PROXIES_TO]->(t);
MATCH (s:HostBridge {id:'aj-host-bridge'}), (t:APIEndpoints {id:'api-plugin-object-list'}) MERGE (s)-[:PROXIES_TO]->(t);
MATCH (s:HostBridge {id:'aj-host-bridge'}), (t:APIEndpoints {id:'api-plugin-object-listbyentity'}) MERGE (s)-[:PROXIES_TO]->(t);
MATCH (s:HostBridge {id:'aj-host-bridge'}), (t:APIEndpoints {id:'api-plugin-object-save'}) MERGE (s)-[:PROXIES_TO]->(t);
MATCH (s:HostBridge {id:'aj-host-bridge'}), (t:APIEndpoints {id:'api-product-getbyid'}) MERGE (s)-[:PROXIES_TO]->(t);
MATCH (s:HostBridge {id:'aj-host-bridge'}), (t:APIEndpoints {id:'api-product-list'}) MERGE (s)-[:PROXIES_TO]->(t);
MATCH (s:FilterDefinition {id:'filter-warehouse-stock'}), (t:ExtendedEntity {id:'ee-warehouse-stock-flag'}) MERGE (s)-[:QUERIES]->(t);
MATCH (s:Feature {id:'feat-browse-products'}), (t:CorePage {id:'page-product-list'}) MERGE (s)-[:REALIZED_BY]->(t);
MATCH (s:Feature {id:'feat-capture-box-size'}), (t:PluginPage {id:'pp-box-size-product-box-tab'}) MERGE (s)-[:REALIZED_BY]->(t);
MATCH (s:Feature {id:'feat-generate-ai-description'}), (t:PluginPage {id:'pp-ai-description-product-tab'}) MERGE (s)-[:REALIZED_BY]->(t);
MATCH (s:Feature {id:'feat-manage-categories'}), (t:CorePage {id:'page-category-form'}) MERGE (s)-[:REALIZED_BY]->(t);
MATCH (s:Feature {id:'feat-manage-categories'}), (t:CorePage {id:'page-category-list'}) MERGE (s)-[:REALIZED_BY]->(t);
MATCH (s:Feature {id:'feat-manage-plugins'}), (t:CorePage {id:'page-plugin-detail'}) MERGE (s)-[:REALIZED_BY]->(t);
MATCH (s:Feature {id:'feat-manage-plugins'}), (t:CorePage {id:'page-plugin-list'}) MERGE (s)-[:REALIZED_BY]->(t);
MATCH (s:Feature {id:'feat-manage-products'}), (t:CorePage {id:'page-product-form'}) MERGE (s)-[:REALIZED_BY]->(t);
MATCH (s:Feature {id:'feat-manage-products'}), (t:CorePage {id:'page-product-list'}) MERGE (s)-[:REALIZED_BY]->(t);
MATCH (s:Feature {id:'feat-manage-warehouses'}), (t:PluginPage {id:'pp-warehouse-warehouse-page'}) MERGE (s)-[:REALIZED_BY]->(t);
MATCH (s:Feature {id:'feat-product-availability'}), (t:PluginPage {id:'pp-warehouse-product-availability'}) MERGE (s)-[:REALIZED_BY]->(t);
MATCH (s:Feature {id:'feat-register-plugin'}), (t:CorePage {id:'page-plugin-form'}) MERGE (s)-[:REALIZED_BY]->(t);
MATCH (s:Feature {id:'feat-show-box-size'}), (t:PluginPage {id:'pp-box-size-product-box-badge'}) MERGE (s)-[:REALIZED_BY]->(t);
MATCH (s:Feature {id:'feat-toggle-plugin'}), (t:CorePage {id:'page-plugin-list'}) MERGE (s)-[:REALIZED_BY]->(t);
MATCH (s:Feature {id:'feat-track-stock'}), (t:PluginPage {id:'pp-warehouse-product-stock-tab'}) MERGE (s)-[:REALIZED_BY]->(t);
MATCH (s:Feature {id:'feat-track-stock'}), (t:PluginPage {id:'pp-warehouse-warehouse-page'}) MERGE (s)-[:REALIZED_BY]->(t);
MATCH (s:Feature {id:'feat-view-product-details'}), (t:CorePage {id:'page-product-detail'}) MERGE (s)-[:REALIZED_BY]->(t);
MATCH (s:PluginEngine {id:'aj-plugin-engine'}), (t:Plugin {id:'plugin-ai-description'}) MERGE (s)-[:REGISTERS]->(t);
MATCH (s:PluginEngine {id:'aj-plugin-engine'}), (t:Plugin {id:'plugin-box-size'}) MERGE (s)-[:REGISTERS]->(t);
MATCH (s:PluginEngine {id:'aj-plugin-engine'}), (t:Plugin {id:'plugin-warehouse'}) MERGE (s)-[:REGISTERS]->(t);
MATCH (s:ExtensionPoint {id:'ep-ai-description-product-detail-tabs-ai-description'}), (t:CorePage {id:'page-product-detail'}) MERGE (s)-[:RENDERED_ON]->(t);
MATCH (s:ExtensionPoint {id:'ep-box-size-product-detail-info-box-size'}), (t:CorePage {id:'page-product-detail'}) MERGE (s)-[:RENDERED_ON]->(t);
MATCH (s:ExtensionPoint {id:'ep-box-size-product-detail-tabs-box-size'}), (t:CorePage {id:'page-product-detail'}) MERGE (s)-[:RENDERED_ON]->(t);
MATCH (s:ExtensionPoint {id:'ep-warehouse-menu-main-warehouse'}), (t:CorePage {id:'page-category-list'}) MERGE (s)-[:RENDERED_ON]->(t);
MATCH (s:ExtensionPoint {id:'ep-warehouse-menu-main-warehouse'}), (t:CorePage {id:'page-plugin-list'}) MERGE (s)-[:RENDERED_ON]->(t);
MATCH (s:ExtensionPoint {id:'ep-warehouse-menu-main-warehouse'}), (t:CorePage {id:'page-product-list'}) MERGE (s)-[:RENDERED_ON]->(t);
MATCH (s:ExtensionPoint {id:'ep-warehouse-product-detail-info-availability'}), (t:CorePage {id:'page-product-detail'}) MERGE (s)-[:RENDERED_ON]->(t);
MATCH (s:ExtensionPoint {id:'ep-warehouse-product-detail-tabs-stock-info'}), (t:CorePage {id:'page-product-detail'}) MERGE (s)-[:RENDERED_ON]->(t);
MATCH (s:FilterDefinition {id:'filter-warehouse-stock'}), (t:CorePage {id:'page-product-list'}) MERGE (s)-[:RENDERED_ON]->(t);
MATCH (s:Plugin {id:'plugin-ai-description'}), (t:IframeIsolation {id:'aj-iframe-isolation'}) MERGE (s)-[:RUNS_IN]->(t);
MATCH (s:Plugin {id:'plugin-box-size'}), (t:IframeIsolation {id:'aj-iframe-isolation'}) MERGE (s)-[:RUNS_IN]->(t);
MATCH (s:Plugin {id:'plugin-warehouse'}), (t:IframeIsolation {id:'aj-iframe-isolation'}) MERGE (s)-[:RUNS_IN]->(t);
MATCH (s:ExtendedEntity {id:'ee-aidesc-data'}), (t:StorageStrategy {id:'storage-plugin-custom-object'}) MERGE (s)-[:STORED_VIA]->(t);
MATCH (s:ExtendedEntity {id:'ee-boxsize-data'}), (t:StorageStrategy {id:'storage-namespaced-plugin-data'}) MERGE (s)-[:STORED_VIA]->(t);
MATCH (s:ExtendedEntity {id:'ee-warehouse-stock-entry'}), (t:StorageStrategy {id:'storage-plugin-custom-object'}) MERGE (s)-[:STORED_VIA]->(t);
MATCH (s:ExtendedEntity {id:'ee-warehouse-stock-flag'}), (t:StorageStrategy {id:'storage-namespaced-plugin-data'}) MERGE (s)-[:STORED_VIA]->(t);
MATCH (s:PluginEntity {id:'pe-warehouse-warehouse'}), (t:StorageStrategy {id:'storage-plugin-custom-object'}) MERGE (s)-[:STORED_VIA]->(t);
MATCH (s:EntityBinding {id:'binding-aidesc-on-product'}), (t:Entity {id:'entity-product'}) MERGE (s)-[:TARGETS]->(t);
MATCH (s:EntityBinding {id:'binding-warehouse-stock-on-product'}), (t:Entity {id:'entity-product'}) MERGE (s)-[:TARGETS]->(t);
MATCH (s:Backend {id:'aj-backend'}), (t:ExternalSystem {id:'ext-postgres'}) MERGE (s)-[:USES]->(t);
MATCH (s:PluginSDK {id:'aj-plugin-sdk'}), (t:HostBridge {id:'aj-host-bridge'}) MERGE (s)-[:USES]->(t);
MATCH (s:API {id:'api-ai-description'}), (t:APIEndpoints {id:'api-plugin-object-listbyentity'}) MERGE (s)-[:USES]->(t);
MATCH (s:API {id:'api-ai-description'}), (t:APIEndpoints {id:'api-plugin-object-save'}) MERGE (s)-[:USES]->(t);
MATCH (s:API {id:'api-ai-description'}), (t:APIEndpoints {id:'api-product-getbyid'}) MERGE (s)-[:USES]->(t);
MATCH (s:API {id:'api-ai-description'}), (t:ExternalSystem {id:'ext-anthropic'}) MERGE (s)-[:USES]->(t);
MATCH (s:API {id:'api-ai-description'}), (t:ExternalSystem {id:'ext-langfuse'}) MERGE (s)-[:USES]->(t);
MATCH (s:API {id:'api-ai-description'}), (t:ExternalSystem {id:'ext-litellm'}) MERGE (s)-[:USES]->(t);
MATCH (s:API {id:'api-ai-description'}), (t:ExternalSystem {id:'ext-openai'}) MERGE (s)-[:USES]->(t);
MATCH (s:API {id:'api-ai-description'}), (t:ExternalSystem {id:'ext-presidio'}) MERGE (s)-[:USES]->(t);
MATCH (s:API {id:'api-box-size'}), (t:APIEndpoints {id:'api-plugin-data-delete'}) MERGE (s)-[:USES]->(t);
MATCH (s:API {id:'api-box-size'}), (t:APIEndpoints {id:'api-plugin-data-get'}) MERGE (s)-[:USES]->(t);
MATCH (s:API {id:'api-box-size'}), (t:APIEndpoints {id:'api-plugin-data-put'}) MERGE (s)-[:USES]->(t);
MATCH (s:API {id:'api-warehouse'}), (t:APIEndpoints {id:'api-plugin-data-get'}) MERGE (s)-[:USES]->(t);
MATCH (s:API {id:'api-warehouse'}), (t:APIEndpoints {id:'api-plugin-data-put'}) MERGE (s)-[:USES]->(t);
MATCH (s:API {id:'api-warehouse'}), (t:APIEndpoints {id:'api-plugin-object-delete'}) MERGE (s)-[:USES]->(t);
MATCH (s:API {id:'api-warehouse'}), (t:APIEndpoints {id:'api-plugin-object-list'}) MERGE (s)-[:USES]->(t);
MATCH (s:API {id:'api-warehouse'}), (t:APIEndpoints {id:'api-plugin-object-listbyentity'}) MERGE (s)-[:USES]->(t);
MATCH (s:API {id:'api-warehouse'}), (t:APIEndpoints {id:'api-plugin-object-save'}) MERGE (s)-[:USES]->(t);
MATCH (s:API {id:'api-warehouse'}), (t:APIEndpoints {id:'api-product-getbyid'}) MERGE (s)-[:USES]->(t);
MATCH (s:API {id:'api-warehouse'}), (t:APIEndpoints {id:'api-product-list'}) MERGE (s)-[:USES]->(t);
MATCH (s:Actor {id:'catalog-operator'}), (t:System {id:'aj-platform'}) MERGE (s)-[:USES]->(t);
MATCH (s:CorePage {id:'page-category-form'}), (t:APIEndpoints {id:'api-category-create'}) MERGE (s)-[:USES]->(t);
MATCH (s:CorePage {id:'page-category-form'}), (t:APIEndpoints {id:'api-category-getbyid'}) MERGE (s)-[:USES]->(t);
MATCH (s:CorePage {id:'page-category-form'}), (t:APIEndpoints {id:'api-category-update'}) MERGE (s)-[:USES]->(t);
MATCH (s:CorePage {id:'page-category-list'}), (t:APIEndpoints {id:'api-category-delete'}) MERGE (s)-[:USES]->(t);
MATCH (s:CorePage {id:'page-category-list'}), (t:APIEndpoints {id:'api-category-list'}) MERGE (s)-[:USES]->(t);
MATCH (s:CorePage {id:'page-plugin-detail'}), (t:APIEndpoints {id:'api-plugin-getbyid'}) MERGE (s)-[:USES]->(t);
MATCH (s:CorePage {id:'page-plugin-form'}), (t:APIEndpoints {id:'api-plugin-getbyid'}) MERGE (s)-[:USES]->(t);
MATCH (s:CorePage {id:'page-plugin-form'}), (t:APIEndpoints {id:'api-plugin-uploadmanifest'}) MERGE (s)-[:USES]->(t);
MATCH (s:CorePage {id:'page-plugin-list'}), (t:APIEndpoints {id:'api-plugin-delete'}) MERGE (s)-[:USES]->(t);
MATCH (s:CorePage {id:'page-plugin-list'}), (t:APIEndpoints {id:'api-plugin-list'}) MERGE (s)-[:USES]->(t);
MATCH (s:CorePage {id:'page-plugin-list'}), (t:APIEndpoints {id:'api-plugin-setenabled'}) MERGE (s)-[:USES]->(t);
MATCH (s:CorePage {id:'page-product-detail'}), (t:APIEndpoints {id:'api-plugin-list'}) MERGE (s)-[:USES]->(t);
MATCH (s:CorePage {id:'page-product-detail'}), (t:APIEndpoints {id:'api-product-getbyid'}) MERGE (s)-[:USES]->(t);
MATCH (s:CorePage {id:'page-product-form'}), (t:APIEndpoints {id:'api-category-list'}) MERGE (s)-[:USES]->(t);
MATCH (s:CorePage {id:'page-product-form'}), (t:APIEndpoints {id:'api-product-create'}) MERGE (s)-[:USES]->(t);
MATCH (s:CorePage {id:'page-product-form'}), (t:APIEndpoints {id:'api-product-getbyid'}) MERGE (s)-[:USES]->(t);
MATCH (s:CorePage {id:'page-product-form'}), (t:APIEndpoints {id:'api-product-update'}) MERGE (s)-[:USES]->(t);
MATCH (s:CorePage {id:'page-product-list'}), (t:APIEndpoints {id:'api-category-list'}) MERGE (s)-[:USES]->(t);
MATCH (s:CorePage {id:'page-product-list'}), (t:APIEndpoints {id:'api-plugin-list'}) MERGE (s)-[:USES]->(t);
MATCH (s:CorePage {id:'page-product-list'}), (t:APIEndpoints {id:'api-product-list'}) MERGE (s)-[:USES]->(t);
MATCH (s:PluginPage {id:'pp-ai-description-product-tab'}), (t:HostBridge {id:'aj-host-bridge'}) MERGE (s)-[:USES]->(t);
MATCH (s:PluginPage {id:'pp-ai-description-product-tab'}), (t:PluginSDK {id:'aj-plugin-sdk'}) MERGE (s)-[:USES]->(t);
MATCH (s:PluginPage {id:'pp-box-size-product-box-badge'}), (t:HostBridge {id:'aj-host-bridge'}) MERGE (s)-[:USES]->(t);
MATCH (s:PluginPage {id:'pp-box-size-product-box-badge'}), (t:PluginSDK {id:'aj-plugin-sdk'}) MERGE (s)-[:USES]->(t);
MATCH (s:PluginPage {id:'pp-box-size-product-box-tab'}), (t:HostBridge {id:'aj-host-bridge'}) MERGE (s)-[:USES]->(t);
MATCH (s:PluginPage {id:'pp-box-size-product-box-tab'}), (t:PluginSDK {id:'aj-plugin-sdk'}) MERGE (s)-[:USES]->(t);
MATCH (s:PluginPage {id:'pp-warehouse-product-availability'}), (t:HostBridge {id:'aj-host-bridge'}) MERGE (s)-[:USES]->(t);
MATCH (s:PluginPage {id:'pp-warehouse-product-availability'}), (t:PluginSDK {id:'aj-plugin-sdk'}) MERGE (s)-[:USES]->(t);
MATCH (s:PluginPage {id:'pp-warehouse-product-stock-tab'}), (t:HostBridge {id:'aj-host-bridge'}) MERGE (s)-[:USES]->(t);
MATCH (s:PluginPage {id:'pp-warehouse-product-stock-tab'}), (t:PluginSDK {id:'aj-plugin-sdk'}) MERGE (s)-[:USES]->(t);
MATCH (s:PluginPage {id:'pp-warehouse-warehouse-page'}), (t:HostBridge {id:'aj-host-bridge'}) MERGE (s)-[:USES]->(t);
MATCH (s:PluginPage {id:'pp-warehouse-warehouse-page'}), (t:PluginSDK {id:'aj-plugin-sdk'}) MERGE (s)-[:USES]->(t);
