// =============================================================================
// AJ KNOWLEDGE GRAPH — INSTANCES
// =============================================================================
// Concrete knowledge about the aj product: modules, plugins, entities,
// repositories, actions, endpoints, pages, external systems, standards.
// Run AFTER 01_ontology.cypher.
//
// Style: each statement is self-contained — MATCH the nodes it needs, then
// MERGE relationships. cypher-shell executes one statement at a time, so we
// don't rely on variables surviving across `;`.
// =============================================================================

// -----------------------------------------------------------------------------
// System / Host / Backend / Frontend
// -----------------------------------------------------------------------------
MERGE (sys:System {name:'aj'})
  SET sys.description = 'Microkernel showcase: Spring Boot host + independent Vite/TS plugins.';

MERGE (host:Host {name:'aj-host'})
  SET host.description = 'Spring Boot 4 host application embedding plugins.',
      host.path        = 'src/main/java/pl/devstyle/aj';

MATCH (sys:System {name:'aj'}), (host:Host {name:'aj-host'})
MERGE (sys)-[:CONTAINS]->(host);

MERGE (be:Backend {name:'aj-backend'})  SET be.path = 'src/main/java/pl/devstyle/aj';
MERGE (fe:Frontend {name:'aj-frontend'}) SET fe.path = 'src/main/frontend/src';
MATCH (host:Host {name:'aj-host'}), (be:Backend {name:'aj-backend'})
MERGE (host)-[:HAS]->(be);
MATCH (host:Host {name:'aj-host'}), (fe:Frontend {name:'aj-frontend'})
MERGE (host)-[:HAS]->(fe);

// -----------------------------------------------------------------------------
// External systems
// -----------------------------------------------------------------------------
MERGE (pg:ExternalSystem {name:'PostgreSQL'})              SET pg.kind='database', pg.version='18';
MERGE (oa:ExternalSystem {name:'OAuth2 Authorization Server'}) SET oa.kind='auth',     oa.note='Built-in Spring Authorization Server.';
MERGE (ba:ExternalSystem {name:'BAML / LLM provider'})     SET ba.kind='llm',      ba.note='Used by ai-description plugin to generate text.';

// -----------------------------------------------------------------------------
// Core (microkernel) + plugin engine
// -----------------------------------------------------------------------------
MERGE (core:Core {name:'core'}) SET core.path='src/main/java/pl/devstyle/aj/core';
MATCH (be:Backend {name:'aj-backend'}), (core:Core {name:'core'})
MERGE (be)-[:CONTAINS]->(core);

MERGE (engine:PluginEngine {name:'plugin-engine'})
  SET engine.path='src/main/java/pl/devstyle/aj/core/plugin',
      engine.responsibilities='Plugin registration, manifest validation, plugin object storage, per-entity plugin data lifecycle.';
MATCH (core:Core {name:'core'}), (engine:PluginEngine {name:'plugin-engine'})
MERGE (core)-[:CONTAINS]->(engine);

// -----------------------------------------------------------------------------
// Backend modules
// -----------------------------------------------------------------------------
MERGE (m:Module {name:'product'})  SET m.path='src/main/java/pl/devstyle/aj/product';
MERGE (m:Module {name:'category'}) SET m.path='src/main/java/pl/devstyle/aj/category';
MERGE (m:Module {name:'user'})     SET m.path='src/main/java/pl/devstyle/aj/user';
MERGE (m:Module {name:'api'})      SET m.path='src/main/java/pl/devstyle/aj/api',
                                       m.responsibilities='Cross-cutting REST: auth login, health.';
MERGE (m:Module {name:'security'}) SET m.path='src/main/java/pl/devstyle/aj/core/security',
                                       m.responsibilities='JWT filter, user details, security configuration.';
MERGE (m:Module {name:'oauth2'})   SET m.path='src/main/java/pl/devstyle/aj/core/oauth2',
                                       m.responsibilities='Spring Authorization Server: code/token/introspect/register.';
MERGE (m:Module {name:'error'})    SET m.path='src/main/java/pl/devstyle/aj/core/error',
                                       m.responsibilities='Global exception handler + error response shape.';

MATCH (be:Backend {name:'aj-backend'}), (m:Module) WHERE m.name IN ['product','category','user','api']
MERGE (be)-[:CONTAINS]->(m);
MATCH (core:Core {name:'core'}),       (m:Module) WHERE m.name IN ['security','oauth2','error']
MERGE (core)-[:CONTAINS]->(m);

// -----------------------------------------------------------------------------
// Entities
// -----------------------------------------------------------------------------
MERGE (e:Entity {qname:'pl.devstyle.aj.product.Product'})
  SET e.name='Product',
      e.fields='id, name, description, photoUrl, price, sku, category, pluginData (JSONB)',
      e.path='src/main/java/pl/devstyle/aj/product/Product.java',
      e.extensible=true;
MERGE (e:Entity {qname:'pl.devstyle.aj.category.Category'})
  SET e.name='Category', e.fields='id, name, description',
      e.path='src/main/java/pl/devstyle/aj/category/Category.java';
MERGE (e:Entity {qname:'pl.devstyle.aj.user.User'})
  SET e.name='User', e.fields='id, username (unique), passwordHash, permissions',
      e.path='src/main/java/pl/devstyle/aj/user/User.java';
MERGE (e:Entity {qname:'pl.devstyle.aj.core.plugin.PluginDescriptor'})
  SET e.name='PluginDescriptor',
      e.fields='id, name, version, url, description, enabled, manifest (JSONB)',
      e.path='src/main/java/pl/devstyle/aj/core/plugin/PluginDescriptor.java';
MERGE (e:Entity {qname:'pl.devstyle.aj.core.plugin.PluginObject'})
  SET e.name='PluginObject',
      e.fields='id, pluginId, objectType, objectId, data (JSONB), entityType, entityId',
      e.path='src/main/java/pl/devstyle/aj/core/plugin/PluginObject.java';
MERGE (e:Entity {qname:'pl.devstyle.aj.core.oauth2.RegisteredClientEntity'})
  SET e.name='RegisteredClientEntity',
      e.path='src/main/java/pl/devstyle/aj/core/oauth2/RegisteredClientEntity.java';

MATCH (m:Module {name:'product'}),  (e:Entity {name:'Product'})            MERGE (m)-[:CONTAINS]->(e);
MATCH (m:Module {name:'category'}), (e:Entity {name:'Category'})           MERGE (m)-[:CONTAINS]->(e);
MATCH (m:Module {name:'user'}),     (e:Entity {name:'User'})               MERGE (m)-[:CONTAINS]->(e);
MATCH (eng:PluginEngine), (e:Entity {name:'PluginDescriptor'})              MERGE (eng)-[:CONTAINS]->(e);
MATCH (eng:PluginEngine), (e:Entity {name:'PluginObject'})                  MERGE (eng)-[:CONTAINS]->(e);
MATCH (m:Module {name:'oauth2'}),   (e:Entity {name:'RegisteredClientEntity'}) MERGE (m)-[:CONTAINS]->(e);

MATCH (p:Entity {name:'Product'}), (c:Entity {name:'Category'})
MERGE (p)-[r:REFERENCES]->(c) SET r.fk='category_id';

// -----------------------------------------------------------------------------
// Repositories
// -----------------------------------------------------------------------------
MERGE (r:Repository {qname:'pl.devstyle.aj.product.ProductRepository'})              SET r.name='ProductRepository',           r.path='src/main/java/pl/devstyle/aj/product/ProductRepository.java';
MERGE (r:Repository {qname:'pl.devstyle.aj.category.CategoryRepository'})            SET r.name='CategoryRepository',          r.path='src/main/java/pl/devstyle/aj/category/CategoryRepository.java';
MERGE (r:Repository {qname:'pl.devstyle.aj.user.UserRepository'})                    SET r.name='UserRepository',              r.path='src/main/java/pl/devstyle/aj/user/UserRepository.java';
MERGE (r:Repository {qname:'pl.devstyle.aj.core.plugin.PluginDescriptorRepository'}) SET r.name='PluginDescriptorRepository',  r.path='src/main/java/pl/devstyle/aj/core/plugin/PluginDescriptorRepository.java';
MERGE (r:Repository {qname:'pl.devstyle.aj.core.plugin.PluginObjectRepository'})     SET r.name='PluginObjectRepository',      r.path='src/main/java/pl/devstyle/aj/core/plugin/PluginObjectRepository.java';

MATCH (m:Module {name:'product'}),  (r:Repository {name:'ProductRepository'})           MERGE (m)-[:CONTAINS]->(r);
MATCH (m:Module {name:'category'}), (r:Repository {name:'CategoryRepository'})          MERGE (m)-[:CONTAINS]->(r);
MATCH (m:Module {name:'user'}),     (r:Repository {name:'UserRepository'})              MERGE (m)-[:CONTAINS]->(r);
MATCH (eng:PluginEngine),           (r:Repository {name:'PluginDescriptorRepository'})  MERGE (eng)-[:CONTAINS]->(r);
MATCH (eng:PluginEngine),           (r:Repository {name:'PluginObjectRepository'})      MERGE (eng)-[:CONTAINS]->(r);

MATCH (e:Entity {name:'Product'}),          (r:Repository {name:'ProductRepository'})          MERGE (e)-[:PERSISTED_BY]->(r);
MATCH (e:Entity {name:'Category'}),         (r:Repository {name:'CategoryRepository'})         MERGE (e)-[:PERSISTED_BY]->(r);
MATCH (e:Entity {name:'User'}),             (r:Repository {name:'UserRepository'})             MERGE (e)-[:PERSISTED_BY]->(r);
MATCH (e:Entity {name:'PluginDescriptor'}), (r:Repository {name:'PluginDescriptorRepository'}) MERGE (e)-[:PERSISTED_BY]->(r);
MATCH (e:Entity {name:'PluginObject'}),     (r:Repository {name:'PluginObjectRepository'})     MERGE (e)-[:PERSISTED_BY]->(r);

MATCH (r:Repository), (db:ExternalSystem {name:'PostgreSQL'})
MERGE (r)-[:STORED_IN]->(db);

// -----------------------------------------------------------------------------
// Permissions
// -----------------------------------------------------------------------------
MERGE (p:Permission {name:'READ'});
MERGE (p:Permission {name:'EDIT'});
MERGE (p:Permission {name:'PLUGIN_MANAGEMENT'});
MATCH (e:Entity {name:'User'}), (p:Permission)
MERGE (e)-[:DEFINES]->(p);

// -----------------------------------------------------------------------------
// API endpoints — products
// -----------------------------------------------------------------------------
MERGE (e:ApiEndpoint {id:'GET /api/products'})         SET e.method='GET',    e.path='/api/products',          e.controller='ProductController';
MERGE (e:ApiEndpoint {id:'GET /api/products/{id}'})    SET e.method='GET',    e.path='/api/products/{id}',     e.controller='ProductController';
MERGE (e:ApiEndpoint {id:'POST /api/products'})        SET e.method='POST',   e.path='/api/products',          e.controller='ProductController', e.permission='EDIT';
MERGE (e:ApiEndpoint {id:'PUT /api/products/{id}'})    SET e.method='PUT',    e.path='/api/products/{id}',     e.controller='ProductController', e.permission='EDIT';
MERGE (e:ApiEndpoint {id:'DELETE /api/products/{id}'}) SET e.method='DELETE', e.path='/api/products/{id}',     e.controller='ProductController', e.permission='EDIT';

MERGE (a:Action {qname:'product.list'})   SET a.description='List products with optional filters.';
MERGE (a:Action {qname:'product.get'})    SET a.description='Get product by id.';
MERGE (a:Action {qname:'product.create'}) SET a.description='Create product.';
MERGE (a:Action {qname:'product.update'}) SET a.description='Update product.';
MERGE (a:Action {qname:'product.delete'}) SET a.description='Delete product.';

MATCH (m:Module {name:'product'}), (a:Action) WHERE a.qname STARTS WITH 'product.'
MERGE (m)-[:CONTAINS]->(a);
MATCH (m:Module {name:'product'}), (e:ApiEndpoint) WHERE e.controller='ProductController'
MERGE (m)-[:CONTAINS]->(e);
MATCH (a:Action), (ent:Entity {name:'Product'}) WHERE a.qname STARTS WITH 'product.'
MERGE (a)-[:OPERATES_ON]->(ent);

MATCH (a:Action {qname:'product.list'}),   (e:ApiEndpoint {id:'GET /api/products'})         MERGE (a)-[:EXPOSED_BY]->(e);
MATCH (a:Action {qname:'product.get'}),    (e:ApiEndpoint {id:'GET /api/products/{id}'})    MERGE (a)-[:EXPOSED_BY]->(e);
MATCH (a:Action {qname:'product.create'}), (e:ApiEndpoint {id:'POST /api/products'})        MERGE (a)-[:EXPOSED_BY]->(e);
MATCH (a:Action {qname:'product.update'}), (e:ApiEndpoint {id:'PUT /api/products/{id}'})    MERGE (a)-[:EXPOSED_BY]->(e);
MATCH (a:Action {qname:'product.delete'}), (e:ApiEndpoint {id:'DELETE /api/products/{id}'}) MERGE (a)-[:EXPOSED_BY]->(e);

// -----------------------------------------------------------------------------
// API endpoints — categories
// -----------------------------------------------------------------------------
MERGE (e:ApiEndpoint {id:'GET /api/categories'})         SET e.method='GET',    e.path='/api/categories',         e.controller='CategoryController';
MERGE (e:ApiEndpoint {id:'GET /api/categories/{id}'})    SET e.method='GET',    e.path='/api/categories/{id}',    e.controller='CategoryController';
MERGE (e:ApiEndpoint {id:'POST /api/categories'})        SET e.method='POST',   e.path='/api/categories',         e.controller='CategoryController', e.permission='EDIT';
MERGE (e:ApiEndpoint {id:'PUT /api/categories/{id}'})    SET e.method='PUT',    e.path='/api/categories/{id}',    e.controller='CategoryController', e.permission='EDIT';
MERGE (e:ApiEndpoint {id:'DELETE /api/categories/{id}'}) SET e.method='DELETE', e.path='/api/categories/{id}',    e.controller='CategoryController', e.permission='EDIT';

MERGE (a:Action {qname:'category.list'})   SET a.description='List categories.';
MERGE (a:Action {qname:'category.get'})    SET a.description='Get category by id.';
MERGE (a:Action {qname:'category.create'}) SET a.description='Create category.';
MERGE (a:Action {qname:'category.update'}) SET a.description='Update category.';
MERGE (a:Action {qname:'category.delete'}) SET a.description='Delete category.';

MATCH (m:Module {name:'category'}), (a:Action) WHERE a.qname STARTS WITH 'category.'
MERGE (m)-[:CONTAINS]->(a);
MATCH (m:Module {name:'category'}), (e:ApiEndpoint) WHERE e.controller='CategoryController'
MERGE (m)-[:CONTAINS]->(e);
MATCH (a:Action), (ent:Entity {name:'Category'}) WHERE a.qname STARTS WITH 'category.'
MERGE (a)-[:OPERATES_ON]->(ent);

MATCH (a:Action {qname:'category.list'}),   (e:ApiEndpoint {id:'GET /api/categories'})         MERGE (a)-[:EXPOSED_BY]->(e);
MATCH (a:Action {qname:'category.get'}),    (e:ApiEndpoint {id:'GET /api/categories/{id}'})    MERGE (a)-[:EXPOSED_BY]->(e);
MATCH (a:Action {qname:'category.create'}), (e:ApiEndpoint {id:'POST /api/categories'})        MERGE (a)-[:EXPOSED_BY]->(e);
MATCH (a:Action {qname:'category.update'}), (e:ApiEndpoint {id:'PUT /api/categories/{id}'})    MERGE (a)-[:EXPOSED_BY]->(e);
MATCH (a:Action {qname:'category.delete'}), (e:ApiEndpoint {id:'DELETE /api/categories/{id}'}) MERGE (a)-[:EXPOSED_BY]->(e);

// -----------------------------------------------------------------------------
// API endpoints — auth + health
// -----------------------------------------------------------------------------
MERGE (e:ApiEndpoint {id:'POST /api/auth/login'}) SET e.method='POST', e.path='/api/auth/login', e.controller='AuthController',  e.public=true;
MERGE (e:ApiEndpoint {id:'GET /api/health'})      SET e.method='GET',  e.path='/api/health',     e.controller='HealthController', e.public=true;
MERGE (a:Action {qname:'auth.login'}) SET a.description='Username/password to JWT.';

MATCH (m:Module {name:'api'}), (e:ApiEndpoint) WHERE e.id IN ['POST /api/auth/login','GET /api/health']
MERGE (m)-[:CONTAINS]->(e);
MATCH (m:Module {name:'api'}), (a:Action {qname:'auth.login'})
MERGE (m)-[:CONTAINS]->(a);
MATCH (a:Action {qname:'auth.login'}), (ent:Entity {name:'User'})
MERGE (a)-[:OPERATES_ON]->(ent);
MATCH (a:Action {qname:'auth.login'}), (e:ApiEndpoint {id:'POST /api/auth/login'})
MERGE (a)-[:EXPOSED_BY]->(e);

// -----------------------------------------------------------------------------
// API endpoints — plugin management
// -----------------------------------------------------------------------------
MERGE (e:ApiEndpoint {id:'GET /api/plugins'})                                    SET e.method='GET',    e.path='/api/plugins',                                    e.controller='PluginController';
MERGE (e:ApiEndpoint {id:'GET /api/plugins/{pluginId}'})                          SET e.method='GET',    e.path='/api/plugins/{pluginId}',                          e.controller='PluginController';
MERGE (e:ApiEndpoint {id:'PUT /api/plugins/{pluginId}/manifest'})                 SET e.method='PUT',    e.path='/api/plugins/{pluginId}/manifest',                 e.controller='PluginController', e.permission='PLUGIN_MANAGEMENT';
MERGE (e:ApiEndpoint {id:'PATCH /api/plugins/{pluginId}/enabled'})                SET e.method='PATCH',  e.path='/api/plugins/{pluginId}/enabled',                  e.controller='PluginController', e.permission='PLUGIN_MANAGEMENT';
MERGE (e:ApiEndpoint {id:'DELETE /api/plugins/{pluginId}'})                       SET e.method='DELETE', e.path='/api/plugins/{pluginId}',                          e.controller='PluginController', e.permission='PLUGIN_MANAGEMENT';
MERGE (e:ApiEndpoint {id:'GET /api/plugins/{pluginId}/products/{productId}/data'})    SET e.method='GET',    e.path='/api/plugins/{pluginId}/products/{productId}/data',    e.controller='PluginDataController';
MERGE (e:ApiEndpoint {id:'PUT /api/plugins/{pluginId}/products/{productId}/data'})    SET e.method='PUT',    e.path='/api/plugins/{pluginId}/products/{productId}/data',    e.controller='PluginDataController', e.permission='EDIT';
MERGE (e:ApiEndpoint {id:'DELETE /api/plugins/{pluginId}/products/{productId}/data'}) SET e.method='DELETE', e.path='/api/plugins/{pluginId}/products/{productId}/data',    e.controller='PluginDataController', e.permission='EDIT';
MERGE (e:ApiEndpoint {id:'GET /api/plugins/{pluginId}/objects'})                                  SET e.method='GET',    e.path='/api/plugins/{pluginId}/objects',                                  e.controller='PluginObjectController';
MERGE (e:ApiEndpoint {id:'GET /api/plugins/{pluginId}/objects/{objectType}'})                     SET e.method='GET',    e.path='/api/plugins/{pluginId}/objects/{objectType}',                     e.controller='PluginObjectController';
MERGE (e:ApiEndpoint {id:'GET /api/plugins/{pluginId}/objects/{objectType}/{objectId}'})          SET e.method='GET',    e.path='/api/plugins/{pluginId}/objects/{objectType}/{objectId}',          e.controller='PluginObjectController';
MERGE (e:ApiEndpoint {id:'PUT /api/plugins/{pluginId}/objects/{objectType}/{objectId}'})          SET e.method='PUT',    e.path='/api/plugins/{pluginId}/objects/{objectType}/{objectId}',          e.controller='PluginObjectController', e.permission='EDIT';
MERGE (e:ApiEndpoint {id:'DELETE /api/plugins/{pluginId}/objects/{objectType}/{objectId}'})       SET e.method='DELETE', e.path='/api/plugins/{pluginId}/objects/{objectType}/{objectId}',          e.controller='PluginObjectController', e.permission='EDIT';

MATCH (eng:PluginEngine), (e:ApiEndpoint) WHERE e.controller IN ['PluginController','PluginDataController','PluginObjectController']
MERGE (eng)-[:CONTAINS]->(e);

MERGE (a:Action {qname:'plugin.register'})    SET a.description='Upload manifest, register plugin.';
MERGE (a:Action {qname:'plugin.enable'})      SET a.description='Enable / disable plugin.';
MERGE (a:Action {qname:'plugin.delete'})      SET a.description='Remove plugin.';
MERGE (a:Action {qname:'plugin.list'})        SET a.description='List enabled plugins.';
MERGE (a:Action {qname:'pluginData.read'})    SET a.description='Read per-product plugin data.';
MERGE (a:Action {qname:'pluginData.set'})     SET a.description='Set per-product plugin data.';
MERGE (a:Action {qname:'pluginObject.crud'})  SET a.description='CRUD on plugin-owned objects.';

MATCH (eng:PluginEngine), (a:Action) WHERE a.qname IN ['plugin.register','plugin.enable','plugin.delete','plugin.list','pluginData.read','pluginData.set','pluginObject.crud']
MERGE (eng)-[:CONTAINS]->(a);

MATCH (a:Action) WHERE a.qname STARTS WITH 'plugin.'  WITH a MATCH (e:Entity {name:'PluginDescriptor'}) MERGE (a)-[:OPERATES_ON]->(e);
MATCH (a:Action {qname:'pluginData.read'}),   (e:Entity {name:'Product'})       MERGE (a)-[:OPERATES_ON]->(e);
MATCH (a:Action {qname:'pluginData.set'}),    (e:Entity {name:'Product'})       MERGE (a)-[:OPERATES_ON]->(e);
MATCH (a:Action {qname:'pluginObject.crud'}), (e:Entity {name:'PluginObject'})  MERGE (a)-[:OPERATES_ON]->(e);

MATCH (a:Action {qname:'plugin.register'}), (e:ApiEndpoint {id:'PUT /api/plugins/{pluginId}/manifest'})  MERGE (a)-[:EXPOSED_BY]->(e);
MATCH (a:Action {qname:'plugin.enable'}),   (e:ApiEndpoint {id:'PATCH /api/plugins/{pluginId}/enabled'}) MERGE (a)-[:EXPOSED_BY]->(e);
MATCH (a:Action {qname:'plugin.delete'}),   (e:ApiEndpoint {id:'DELETE /api/plugins/{pluginId}'})        MERGE (a)-[:EXPOSED_BY]->(e);
MATCH (a:Action {qname:'plugin.list'}),     (e:ApiEndpoint {id:'GET /api/plugins'})                       MERGE (a)-[:EXPOSED_BY]->(e);
MATCH (a:Action {qname:'pluginData.read'}), (e:ApiEndpoint {id:'GET /api/plugins/{pluginId}/products/{productId}/data'})    MERGE (a)-[:EXPOSED_BY]->(e);
MATCH (a:Action {qname:'pluginData.set'}),  (e:ApiEndpoint {id:'PUT /api/plugins/{pluginId}/products/{productId}/data'})    MERGE (a)-[:EXPOSED_BY]->(e);
MATCH (a:Action {qname:'pluginData.set'}),  (e:ApiEndpoint {id:'DELETE /api/plugins/{pluginId}/products/{productId}/data'}) MERGE (a)-[:EXPOSED_BY]->(e);
MATCH (a:Action {qname:'pluginObject.crud'}), (e:ApiEndpoint) WHERE e.controller='PluginObjectController' MERGE (a)-[:EXPOSED_BY]->(e);

// -----------------------------------------------------------------------------
// API endpoints — OAuth2 metadata
// -----------------------------------------------------------------------------
MERGE (e:ApiEndpoint {id:'GET /.well-known/oauth-authorization-server'})
  SET e.method='GET', e.path='/.well-known/oauth-authorization-server', e.controller='OAuth2MetadataController', e.public=true;
MERGE (e:ApiEndpoint {id:'GET /api/oauth2/client-info'})
  SET e.method='GET', e.path='/api/oauth2/client-info', e.controller='OAuth2MetadataController';
MATCH (m:Module {name:'oauth2'}), (e:ApiEndpoint) WHERE e.controller='OAuth2MetadataController' MERGE (m)-[:CONTAINS]->(e);
MATCH (m:Module {name:'oauth2'}), (xs:ExternalSystem {name:'OAuth2 Authorization Server'}) MERGE (m)-[:USES]->(xs);

// -----------------------------------------------------------------------------
// Permission requirements on endpoints
// -----------------------------------------------------------------------------
MATCH (e:ApiEndpoint) WHERE e.permission='EDIT'              WITH e MATCH (p:Permission {name:'EDIT'})              MERGE (e)-[:REQUIRES]->(p);
MATCH (e:ApiEndpoint) WHERE e.permission='PLUGIN_MANAGEMENT' WITH e MATCH (p:Permission {name:'PLUGIN_MANAGEMENT'}) MERGE (e)-[:REQUIRES]->(p);

// -----------------------------------------------------------------------------
// Frontend pages (Core)
// -----------------------------------------------------------------------------
// CorePage and PluginPage both also carry the :Page super-label so questions
// like "every page that uses endpoint X" don't have to UNION over two labels.
MERGE (p:CorePage:Page {id:'core:/login'})              SET p.path='/login',                p.file='src/main/frontend/src/pages/LoginPage.tsx';
MERGE (p:CorePage:Page {id:'core:/products'})           SET p.path='/products',             p.file='src/main/frontend/src/pages/ProductListPage.tsx';
MERGE (p:CorePage:Page {id:'core:/products/:id'})       SET p.path='/products/:id',         p.file='src/main/frontend/src/pages/ProductDetailPage.tsx';
MERGE (p:CorePage:Page {id:'core:/products/new'})       SET p.path='/products/new',         p.file='src/main/frontend/src/pages/ProductFormPage.tsx';
MERGE (p:CorePage:Page {id:'core:/categories'})         SET p.path='/categories',           p.file='src/main/frontend/src/pages/CategoryListPage.tsx';
MERGE (p:CorePage:Page {id:'core:/categories/new'})     SET p.path='/categories/new',       p.file='src/main/frontend/src/pages/CategoryFormPage.tsx';
MERGE (p:CorePage:Page {id:'core:/plugins'})            SET p.path='/plugins',              p.file='src/main/frontend/src/pages/PluginListPage.tsx';
MERGE (p:CorePage:Page {id:'core:/plugins/:pluginId/detail'}) SET p.path='/plugins/:pluginId/detail', p.file='src/main/frontend/src/pages/PluginDetailPage.tsx';
MERGE (p:CorePage:Page {id:'core:/plugins/new'})        SET p.path='/plugins/new',          p.file='src/main/frontend/src/pages/PluginFormPage.tsx';
MERGE (p:CorePage:Page {id:'core:/oauth2/authorize'})   SET p.path='/oauth2/authorize';

MATCH (fe:Frontend {name:'aj-frontend'}), (p:CorePage)
MERGE (fe)-[:CONTAINS]->(p);

// Page → Endpoint usage
MATCH (p:CorePage {id:'core:/login'}),         (e:ApiEndpoint {id:'POST /api/auth/login'})    MERGE (p)-[:USES]->(e);
MATCH (p:CorePage {id:'core:/products'}),      (e:ApiEndpoint {id:'GET /api/products'})       MERGE (p)-[:USES]->(e);
MATCH (p:CorePage {id:'core:/products/:id'}),  (e:ApiEndpoint {id:'GET /api/products/{id}'})  MERGE (p)-[:USES]->(e);
MATCH (p:CorePage {id:'core:/products/new'}),  (e:ApiEndpoint {id:'POST /api/products'})      MERGE (p)-[:USES]->(e);
MATCH (p:CorePage {id:'core:/products/new'}),  (e:ApiEndpoint {id:'PUT /api/products/{id}'})  MERGE (p)-[:USES]->(e);
MATCH (p:CorePage {id:'core:/products/new'}),  (e:ApiEndpoint {id:'GET /api/categories'})     MERGE (p)-[:USES]->(e);
MATCH (p:CorePage {id:'core:/categories'}),    (e:ApiEndpoint {id:'GET /api/categories'})     MERGE (p)-[:USES]->(e);
MATCH (p:CorePage {id:'core:/categories/new'}),(e:ApiEndpoint {id:'POST /api/categories'})    MERGE (p)-[:USES]->(e);
MATCH (p:CorePage {id:'core:/categories/new'}),(e:ApiEndpoint {id:'PUT /api/categories/{id}'}) MERGE (p)-[:USES]->(e);
MATCH (p:CorePage {id:'core:/plugins'}),       (e:ApiEndpoint {id:'GET /api/plugins'})        MERGE (p)-[:USES]->(e);
MATCH (p:CorePage {id:'core:/plugins/:pluginId/detail'}), (e:ApiEndpoint {id:'GET /api/plugins/{pluginId}'}) MERGE (p)-[:USES]->(e);
MATCH (p:CorePage {id:'core:/plugins/new'}),   (e:ApiEndpoint {id:'PUT /api/plugins/{pluginId}/manifest'}) MERGE (p)-[:USES]->(e);

// Plugin shell
MERGE (s:PluginShell {name:'plugin-shell'})
  SET s.file='src/main/frontend/src/plugins/PluginContext.tsx',
      s.responsibilities='Initializes plugin SDK; embeds plugin iframes; routes /plugins/:pluginId/*.';
MATCH (fe:Frontend {name:'aj-frontend'}), (s:PluginShell {name:'plugin-shell'})
MERGE (fe)-[:CONTAINS]->(s);

// -----------------------------------------------------------------------------
// Plugins — warehouse
// -----------------------------------------------------------------------------
MERGE (p:Plugin {id:'warehouse'})
  SET p.name='Warehouse',
      p.description='Manages warehouse inventory and stock levels.',
      p.path='plugins/warehouse',
      p.manifest='plugins/warehouse/manifest.json';
MATCH (sys:System {name:'aj'}), (p:Plugin {id:'warehouse'}) MERGE (sys)-[:CONTAINS]->(p);
MATCH (host:Host {name:'aj-host'}), (p:Plugin {id:'warehouse'}) MERGE (host)-[:EMBEDS]->(p);

MERGE (pe:PluginEntity {qname:'warehouse:warehouse'})
  SET pe.name='warehouse', pe.objectType='warehouse',
      pe.fields='name, address, ...',
      pe.note='Stored as PluginObject rows with pluginId=warehouse.';
MERGE (pe:PluginEntity {qname:'warehouse:stock'})
  SET pe.name='stock', pe.objectType='stock',
      pe.fields='productId, warehouseId, quantity',
      pe.entityBoundTo='Product';
MATCH (p:Plugin {id:'warehouse'}), (pe:PluginEntity) WHERE pe.qname IN ['warehouse:warehouse','warehouse:stock'] MERGE (p)-[:OWNS]->(pe);
MATCH (pe:PluginEntity), (po:Entity {name:'PluginObject'}) WHERE pe.qname IN ['warehouse:warehouse','warehouse:stock'] MERGE (pe)-[:STORED_AS]->(po);
MATCH (pe:PluginEntity {qname:'warehouse:stock'}), (e:Entity {name:'Product'}) MERGE (pe)-[:BOUND_TO]->(e);

MERGE (xe:ExtendedEntity {qname:'warehouse:Product'})
  SET xe.name='Product (warehouse extension)', xe.via='product.pluginData.warehouse';
MATCH (p:Plugin {id:'warehouse'}), (xe:ExtendedEntity {qname:'warehouse:Product'}) MERGE (p)-[:EXTENDS]->(xe);
MATCH (xe:ExtendedEntity {qname:'warehouse:Product'}), (e:Entity {name:'Product'}) MERGE (xe)-[:EXTENDS]->(e);

MERGE (pp:PluginPage:Page {id:'warehouse:/'})
  SET pp.path='/', pp.title='Warehouse', pp.extensionPoint='menu.main', pp.priority=100;
MERGE (pp:PluginPage:Page {id:'warehouse:/product-stock'})
  SET pp.path='/product-stock', pp.title='Stock Info', pp.extensionPoint='product.detail.tabs', pp.priority=50;
MERGE (pp:PluginPage:Page {id:'warehouse:/product-availability'})
  SET pp.path='/product-availability', pp.title='Availability', pp.extensionPoint='product.detail.info', pp.priority=10;
MERGE (pp:PluginPage:Page {id:'warehouse:filter:stock'})
  SET pp.title='In Stock filter', pp.extensionPoint='product.list.filters', pp.priority=10;

MATCH (p:Plugin {id:'warehouse'}), (pp:PluginPage) WHERE pp.id STARTS WITH 'warehouse:' MERGE (p)-[:CONTAINS]->(pp);
MATCH (pp:PluginPage {id:'warehouse:/product-stock'}),       (cp:CorePage {id:'core:/products/:id'}) MERGE (pp)-[:EXTENDS]->(cp);
MATCH (pp:PluginPage {id:'warehouse:/product-availability'}),(cp:CorePage {id:'core:/products/:id'}) MERGE (pp)-[:EXTENDS]->(cp);
MATCH (pp:PluginPage {id:'warehouse:filter:stock'}),         (cp:CorePage {id:'core:/products'})     MERGE (pp)-[:EXTENDS]->(cp);

MATCH (p:Plugin {id:'warehouse'}), (e:ApiEndpoint) WHERE e.id IN [
  'GET /api/plugins/{pluginId}/objects',
  'GET /api/plugins/{pluginId}/objects/{objectType}',
  'PUT /api/plugins/{pluginId}/objects/{objectType}/{objectId}',
  'GET /api/products',
  'GET /api/plugins/{pluginId}/products/{productId}/data',
  'PUT /api/plugins/{pluginId}/products/{productId}/data'
] MERGE (p)-[:USES]->(e);

// -----------------------------------------------------------------------------
// Plugins — box-size
// -----------------------------------------------------------------------------
MERGE (p:Plugin {id:'box-size'})
  SET p.name='Box Size',
      p.description='Tracks box dimensions (L x W x H in cm) per product.',
      p.path='plugins/box-size',
      p.manifest='plugins/box-size/manifest.json';
MATCH (sys:System {name:'aj'}), (p:Plugin {id:'box-size'}) MERGE (sys)-[:CONTAINS]->(p);
MATCH (host:Host {name:'aj-host'}), (p:Plugin {id:'box-size'}) MERGE (host)-[:EMBEDS]->(p);

MERGE (xe:ExtendedEntity {qname:'box-size:Product'})
  SET xe.name='Product (box-size extension)', xe.via='product.pluginData.box-size',
      xe.fields='length, width, height';
MATCH (p:Plugin {id:'box-size'}), (xe:ExtendedEntity {qname:'box-size:Product'}) MERGE (p)-[:EXTENDS]->(xe);
MATCH (xe:ExtendedEntity {qname:'box-size:Product'}), (e:Entity {name:'Product'}) MERGE (xe)-[:EXTENDS]->(e);

MERGE (pp:PluginPage:Page {id:'box-size:/product-box'})
  SET pp.path='/product-box', pp.title='Box Size', pp.extensionPoint='product.detail.tabs', pp.priority=60;
MERGE (pp:PluginPage:Page {id:'box-size:/product-box-badge'})
  SET pp.path='/product-box-badge', pp.title='Box Size Badge', pp.extensionPoint='product.detail.info', pp.priority=20;

MATCH (p:Plugin {id:'box-size'}), (pp:PluginPage) WHERE pp.id STARTS WITH 'box-size:' MERGE (p)-[:CONTAINS]->(pp);
MATCH (pp:PluginPage {id:'box-size:/product-box'}),       (cp:CorePage {id:'core:/products/:id'}) MERGE (pp)-[:EXTENDS]->(cp);
MATCH (pp:PluginPage {id:'box-size:/product-box-badge'}), (cp:CorePage {id:'core:/products/:id'}) MERGE (pp)-[:EXTENDS]->(cp);

MATCH (p:Plugin {id:'box-size'}), (e:ApiEndpoint) WHERE e.id IN [
  'GET /api/plugins/{pluginId}/products/{productId}/data',
  'PUT /api/plugins/{pluginId}/products/{productId}/data'
] MERGE (p)-[:USES]->(e);

// -----------------------------------------------------------------------------
// Plugins — ai-description
// -----------------------------------------------------------------------------
MERGE (p:Plugin {id:'ai-description'})
  SET p.name='AI Description',
      p.description='Generates AI-powered product descriptions (BAML / LLM).',
      p.path='plugins/ai-description',
      p.manifest='plugins/ai-description/manifest.json';
MATCH (sys:System {name:'aj'}), (p:Plugin {id:'ai-description'}) MERGE (sys)-[:CONTAINS]->(p);
MATCH (host:Host {name:'aj-host'}), (p:Plugin {id:'ai-description'}) MERGE (host)-[:EMBEDS]->(p);

MERGE (xe:ExtendedEntity {qname:'ai-description:Product'})
  SET xe.name='Product (ai-description extension)', xe.via='product.pluginData.ai-description',
      xe.fields='description, generatedAt';
MATCH (p:Plugin {id:'ai-description'}), (xe:ExtendedEntity {qname:'ai-description:Product'}) MERGE (p)-[:EXTENDS]->(xe);
MATCH (xe:ExtendedEntity {qname:'ai-description:Product'}), (e:Entity {name:'Product'}) MERGE (xe)-[:EXTENDS]->(e);

MERGE (pp:PluginPage:Page {id:'ai-description:/product-tab'})
  SET pp.path='/product-tab', pp.title='AI Description', pp.extensionPoint='product.detail.tabs', pp.priority=70;
MATCH (p:Plugin {id:'ai-description'}), (pp:PluginPage {id:'ai-description:/product-tab'}) MERGE (p)-[:CONTAINS]->(pp);
MATCH (pp:PluginPage {id:'ai-description:/product-tab'}), (cp:CorePage {id:'core:/products/:id'}) MERGE (pp)-[:EXTENDS]->(cp);

MATCH (p:Plugin {id:'ai-description'}), (e:ApiEndpoint) WHERE e.id IN [
  'GET /api/plugins/{pluginId}/products/{productId}/data',
  'PUT /api/plugins/{pluginId}/products/{productId}/data'
] MERGE (p)-[:USES]->(e);
MATCH (p:Plugin {id:'ai-description'}), (xs:ExternalSystem {name:'BAML / LLM provider'}) MERGE (p)-[:USES]->(xs);

// -----------------------------------------------------------------------------
// Standards (subset, with file links)
// -----------------------------------------------------------------------------
MERGE (s:Standard {id:'backend.models'})       SET s.title='JPA Entity Modeling',     s.path='.maister/docs/standards/backend/models.md';
MERGE (s:Standard {id:'backend.jooq'})         SET s.title='jOOQ Query Standards',    s.path='.maister/docs/standards/backend/jooq.md';
MERGE (s:Standard {id:'backend.queries'})      SET s.title='Database Queries',        s.path='.maister/docs/standards/backend/queries.md';
MERGE (s:Standard {id:'backend.migrations'})   SET s.title='Database Migrations',     s.path='.maister/docs/standards/backend/migrations.md';
MERGE (s:Standard {id:'backend.security'})     SET s.title='Security (JWT)',          s.path='.maister/docs/standards/backend/security.md';
MERGE (s:Standard {id:'backend.plugin-auth'})  SET s.title='Plugin Authentication',   s.path='.maister/docs/standards/backend/plugin-auth.md';
MERGE (s:Standard {id:'backend.api'})          SET s.title='API Design',              s.path='.maister/docs/standards/backend/api.md';
MERGE (s:Standard {id:'testing.backend'})      SET s.title='Backend Testing',         s.path='.maister/docs/standards/testing/backend-testing.md';
MERGE (s:Standard {id:'testing.frontend'})     SET s.title='Frontend Testing',        s.path='.maister/docs/standards/testing/frontend-testing.md';

MATCH (e:Entity)      WHERE e.name IN ['Product','Category','User','PluginDescriptor'] WITH e MATCH (s:Standard {id:'backend.models'})  MERGE (e)-[:GOVERNED_BY]->(s);
MATCH (r:Repository {name:'ProductRepository'}),     (s:Standard {id:'backend.queries'}) MERGE (r)-[:GOVERNED_BY]->(s);
MATCH (r:Repository {name:'PluginObjectRepository'}),(s:Standard {id:'backend.jooq'})    MERGE (r)-[:GOVERNED_BY]->(s);
MATCH (m:Module {name:'api'}),       (s:Standard {id:'backend.api'})       MERGE (m)-[:GOVERNED_BY]->(s);
MATCH (m:Module {name:'security'}),  (s:Standard {id:'backend.security'})  MERGE (m)-[:GOVERNED_BY]->(s);
MATCH (m:Module {name:'oauth2'}),    (s:Standard {id:'backend.security'})  MERGE (m)-[:GOVERNED_BY]->(s);
MATCH (p:Plugin),                    (s:Standard {id:'backend.plugin-auth'}) MERGE (p)-[:GOVERNED_BY]->(s);
