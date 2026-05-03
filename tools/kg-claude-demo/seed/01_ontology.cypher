// =============================================================================
// AJ KNOWLEDGE GRAPH — ONTOLOGY
// =============================================================================
// Defines the meta-model from the ontology diagram.
// Nodes carry an :Ontology label so we can distinguish schema from instances.
// Run BEFORE 02_instances.cypher.
// =============================================================================

// Clean slate (safe in demo / training environment).
MATCH (n) DETACH DELETE n;

// -----------------------------------------------------------------------------
// Constraints & indexes
// -----------------------------------------------------------------------------
CREATE CONSTRAINT system_name IF NOT EXISTS
  FOR (n:System) REQUIRE n.name IS UNIQUE;

CREATE CONSTRAINT host_name IF NOT EXISTS
  FOR (n:Host) REQUIRE n.name IS UNIQUE;

CREATE CONSTRAINT plugin_id IF NOT EXISTS
  FOR (n:Plugin) REQUIRE n.id IS UNIQUE;

CREATE CONSTRAINT module_name IF NOT EXISTS
  FOR (n:Module) REQUIRE n.name IS UNIQUE;

CREATE CONSTRAINT entity_qname IF NOT EXISTS
  FOR (n:Entity) REQUIRE n.qname IS UNIQUE;

CREATE CONSTRAINT repository_qname IF NOT EXISTS
  FOR (n:Repository) REQUIRE n.qname IS UNIQUE;

CREATE CONSTRAINT endpoint_id IF NOT EXISTS
  FOR (n:ApiEndpoint) REQUIRE n.id IS UNIQUE;

CREATE CONSTRAINT action_qname IF NOT EXISTS
  FOR (n:Action) REQUIRE n.qname IS UNIQUE;

CREATE CONSTRAINT page_id IF NOT EXISTS
  FOR (n:Page) REQUIRE n.id IS UNIQUE;

CREATE CONSTRAINT external_name IF NOT EXISTS
  FOR (n:ExternalSystem) REQUIRE n.name IS UNIQUE;

CREATE CONSTRAINT standard_id IF NOT EXISTS
  FOR (n:Standard) REQUIRE n.id IS UNIQUE;

// -----------------------------------------------------------------------------
// Ontology nodes (the meta-model itself, recorded as data so users can see it)
// -----------------------------------------------------------------------------
MERGE (:OntologyClass {name: 'System',         description: 'Top-level software product.'});
MERGE (:OntologyClass {name: 'Host',           description: 'Embeds plugins; has Frontend and Backend.'});
MERGE (:OntologyClass {name: 'Plugin',         description: 'Independently developed module that extends the Host.'});
MERGE (:OntologyClass {name: 'PluginEntity',   description: 'Entity owned by a plugin.'});
MERGE (:OntologyClass {name: 'ExtendedEntity', description: 'Host entity extended by a plugin via pluginData.'});
MERGE (:OntologyClass {name: 'Frontend',       description: 'UI layer: PluginShell, CorePages, embedded plugin pages.'});
MERGE (:OntologyClass {name: 'Backend',        description: 'Server-side: Modules + Core + Plugin engine.'});
MERGE (:OntologyClass {name: 'Module',         description: 'Domain backend module: Entities, Repositories, Actions, Endpoints.'});
MERGE (:OntologyClass {name: 'Core',           description: 'Microkernel core; hosts the plugin engine.'});
MERGE (:OntologyClass {name: 'PluginEngine',   description: 'Loads, validates, and dispatches to plugins.'});
MERGE (:OntologyClass {name: 'PluginShell',    description: 'Frontend container that embeds plugin iframes.'});
MERGE (:OntologyClass {name: 'CorePage',       description: 'First-party UI page (not provided by a plugin).'});
MERGE (:OntologyClass {name: 'PluginPage',     description: 'UI page contributed by a plugin.'});
MERGE (:OntologyClass {name: 'API',            description: 'Public surface used by the Frontend, Plugins, and External Systems.'});
MERGE (:OntologyClass {name: 'ApiEndpoint',    description: 'Single REST endpoint (METHOD + path).'});
MERGE (:OntologyClass {name: 'Action',         description: 'Backend operation that operates on an Entity and is exposed by an endpoint.'});
MERGE (:OntologyClass {name: 'Entity',         description: 'Persistent domain object.'});
MERGE (:OntologyClass {name: 'Repository',     description: 'Persists Entities.'});
MERGE (:OntologyClass {name: 'ExternalSystem', description: 'Third-party system used by the API or by a Plugin.'});
MERGE (:OntologyClass {name: 'Standard',       description: 'Coding standard / convention from .maister/docs/standards/.'});

// -----------------------------------------------------------------------------
// Relationship vocabulary (declared as a meta-edge between OntologyClass pairs
// for documentation; instance edges below use the same TYPE names).
// -----------------------------------------------------------------------------
MATCH (s:OntologyClass {name:'System'}),  (h:OntologyClass {name:'Host'})           MERGE (s)-[:META {type:'CONTAINS'}]->(h);
MATCH (s:OntologyClass {name:'System'}),  (p:OntologyClass {name:'Plugin'})         MERGE (s)-[:META {type:'CONTAINS'}]->(p);
MATCH (h:OntologyClass {name:'Host'}),    (f:OntologyClass {name:'Frontend'})       MERGE (h)-[:META {type:'HAS'}]->(f);
MATCH (h:OntologyClass {name:'Host'}),    (b:OntologyClass {name:'Backend'})        MERGE (h)-[:META {type:'HAS'}]->(b);
MATCH (h:OntologyClass {name:'Host'}),    (p:OntologyClass {name:'Plugin'})         MERGE (h)-[:META {type:'EMBEDS'}]->(p);
MATCH (f:OntologyClass {name:'Frontend'}),(s:OntologyClass {name:'PluginShell'})    MERGE (f)-[:META {type:'CONTAINS'}]->(s);
MATCH (f:OntologyClass {name:'Frontend'}),(c:OntologyClass {name:'CorePage'})       MERGE (f)-[:META {type:'CONTAINS'}]->(c);
MATCH (b:OntologyClass {name:'Backend'}), (m:OntologyClass {name:'Module'})         MERGE (b)-[:META {type:'CONTAINS'}]->(m);
MATCH (b:OntologyClass {name:'Backend'}), (c:OntologyClass {name:'Core'})           MERGE (b)-[:META {type:'CONTAINS'}]->(c);
MATCH (c:OntologyClass {name:'Core'}),    (e:OntologyClass {name:'PluginEngine'})   MERGE (c)-[:META {type:'CONTAINS'}]->(e);
MATCH (m:OntologyClass {name:'Module'}),  (e:OntologyClass {name:'Entity'})         MERGE (m)-[:META {type:'CONTAINS'}]->(e);
MATCH (m:OntologyClass {name:'Module'}),  (r:OntologyClass {name:'Repository'})     MERGE (m)-[:META {type:'CONTAINS'}]->(r);
MATCH (m:OntologyClass {name:'Module'}),  (a:OntologyClass {name:'Action'})         MERGE (m)-[:META {type:'CONTAINS'}]->(a);
MATCH (m:OntologyClass {name:'Module'}),  (ep:OntologyClass {name:'ApiEndpoint'})   MERGE (m)-[:META {type:'CONTAINS'}]->(ep);
MATCH (e:OntologyClass {name:'Entity'}),  (r:OntologyClass {name:'Repository'})     MERGE (e)-[:META {type:'PERSISTED_BY'}]->(r);
MATCH (a:OntologyClass {name:'Action'}),  (e:OntologyClass {name:'Entity'})         MERGE (a)-[:META {type:'OPERATES_ON'}]->(e);
MATCH (a:OntologyClass {name:'Action'}),  (ep:OntologyClass {name:'ApiEndpoint'})   MERGE (a)-[:META {type:'EXPOSED_BY'}]->(ep);
MATCH (p:OntologyClass {name:'Plugin'}),  (pp:OntologyClass {name:'PluginPage'})    MERGE (p)-[:META {type:'CONTAINS'}]->(pp);
MATCH (p:OntologyClass {name:'Plugin'}),  (pe:OntologyClass {name:'PluginEntity'})  MERGE (p)-[:META {type:'OWNS'}]->(pe);
MATCH (p:OntologyClass {name:'Plugin'}),  (xe:OntologyClass {name:'ExtendedEntity'}) MERGE (p)-[:META {type:'EXTENDS'}]->(xe);
MATCH (p:OntologyClass {name:'Plugin'}),  (api:OntologyClass {name:'API'})          MERGE (p)-[:META {type:'USES'}]->(api);
MATCH (api:OntologyClass {name:'API'}),   (xs:OntologyClass {name:'ExternalSystem'}) MERGE (api)-[:META {type:'USES'}]->(xs);
