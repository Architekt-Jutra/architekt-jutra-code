---
name: aj-kg-query
description: Answer questions about the AJ platform (host application, modules, entities, endpoints, plugins, extension points, manifests, storage strategies, host bridge, features) by querying the AJ knowledge graph in Neo4j via the `neo4j-aj-kb` MCP server. Use whenever the user asks "what / which / how many / list / show me" about platform structure, plugin wiring, REST endpoints, module contents, plugin manifests, extension points, filters, plugin data storage, or feature traceability — instead of grepping the codebase.
---

# AJ Knowledge Graph Query Skill

Answer questions about the AJ platform by querying the knowledge graph instead of reading source. The KG models the system, host (frontend + backend), modules, entities, repositories, actions, API endpoints, plugins, manifests, extension points, plugin pages, plugin data storage, host bridge, SDK, features and actors. Source of truth: `tools/seed/aj-kg-ontology.cypher` (schema) + `tools/seed/aj-kg-seed-v2.cypher` (instance data).

## When to use this skill

Use when the question can be answered from structural facts about the platform:

- **Endpoints**: "list all endpoints of the X module", "which endpoint exposes action Y", "what does GET /api/products call".
- **Modules / entities / repositories**: "which entities live in module X", "what table does entity Y use", "is entity Z persisted via JPA or jOOQ".
- **Pages**: "which API does the product list page call", "what core pages does the frontend have".
- **Plugins**: "which plugins are registered/enabled", "what does the warehouse plugin contribute", "which extension points does plugin X expose".
- **Extension points & filters**: "what plugins extend product.detail.tabs", "which filters are declared for the product list".
- **Plugin storage**: "which plugins use plugin_objects", "which extended entities live in Product.pluginData", "what storage strategy does plugin X use".
- **Host bridge / SDK**: "what operations does the host bridge accept", "which endpoints can plugins reach".
- **Feature traceability**: "what backs the Manage Products feature", "trace feature X from page to repository".
- **Schema introspection**: "what entity types / relations / properties are declared".

Do **not** use the KG for: column-level entity fields (read the Java class), specific business logic inside a service method (read the source), or git history.

See `tools/questions.md` for a fuller catalog of answerable questions.

## How to use

1. **Load the MCP tool schemas first** (they're deferred):
   ```
   ToolSearch(query: "select:mcp__neo4j-aj-kb__aj-kb-get_neo4j_schema,mcp__neo4j-aj-kb__aj-kb-read_neo4j_cypher", max_results: 5)
   ```

2. **Pick the smallest query that answers the question.** Don't dump the whole graph. Filter by `name`, `id`, or `package` early. `toLower(...)` for fuzzy text matches.

3. **Use the labels in `references/labels.md`** to know what nodes and relationships exist. They mirror the ontology one-to-one.

4. **Always project specific properties**, never `RETURN *`. Order results so the same query produces the same output.

5. **Verify before recommending action.** A KG fact says "this existed when the seed was last run." If the user is about to act on it (edit, call, delete), cross-check with the file system. The working tree may have endpoints/entities the seed doesn't yet cover.

## Quick recipes

### Endpoints in a module
```cypher
MATCH (m:Module)-[:CONTAINS]->(e:APIEndpoints)
WHERE toLower(m.name) CONTAINS $module
RETURN m.name AS module, e.method AS method, e.uri AS uri, e.handler AS handler
ORDER BY e.uri, e.method;
```

### Entities in a module + their tables and repositories
```cypher
MATCH (m:Module)-[:CONTAINS]->(en:Entity)
OPTIONAL MATCH (en)-[:PERSISTED_BY]->(r:Repository)
RETURN m.name, en.name, en.fqcn, en.table,
       collect({name: r.name, kind: r.kind}) AS repositories
ORDER BY m.name, en.name;
```

### Action → endpoint → entity
```cypher
MATCH (a:Action)-[:OPERATES_ON]->(en:Entity),
      (en)-[:EXPOSED_BY]->(ep:APIEndpoints)
WHERE a.name = $actionName
RETURN a.name, a.kind, ep.method, ep.uri, en.name;
```

### Plugin extension points
```cypher
MATCH (pl:Plugin)-[:EXPOSES]->(ep:ExtensionPoint)
OPTIONAL MATCH (ep)-[:RENDERED_ON]->(cp:CorePage)
OPTIONAL MATCH (ep)-[:IMPLEMENTED_BY]->(pp:PluginPage)
RETURN pl.pluginId, ep.type, ep.label, ep.priority,
       cp.name AS rendered_on, pp.name AS plugin_page
ORDER BY pl.pluginId, ep.priority;
```

### Filters declared by a plugin
```cypher
MATCH (m:Manifest)-[:DECLARES]->(f:FilterDefinition)
OPTIONAL MATCH (f)-[:QUERIES]->(ee:ExtendedEntity)
RETURN m.name AS plugin, f.filterKey, f.filterType, f.label, f.priority,
       ee.name AS extends
ORDER BY f.priority;
```

### Plugin data storage
```cypher
MATCH (n)-[:STORED_VIA]->(s:StorageStrategy)
OPTIONAL MATCH (s)-[:PERSISTED_IN]->(en:Entity)
RETURN labels(n)[0] AS kind, n.name AS subject,
       s.kind AS strategy, s.location, s.scope,
       en.name AS host_entity;
```

### Feature traceability (page → endpoint → action → entity)
```cypher
MATCH (f:Feature)
OPTIONAL MATCH (f)-[:REALIZED_BY]->(pg)
OPTIONAL MATCH (f)-[:BACKED_BY]->(a:Action)-[:OPERATES_ON]->(en:Entity)
OPTIONAL MATCH (a)<-[:EXPOSED_BY]-(ep:APIEndpoints)
WHERE f.name = $featureName
RETURN f.name, f.owner, f.scope,
       collect(DISTINCT pg.name) AS pages,
       collect(DISTINCT ep.method + ' ' + ep.uri) AS endpoints,
       collect(DISTINCT en.name) AS entities;
```

### Schema introspection
```cypher
// All allowed (source) -[type]-> (target) triples
MATCH (s:EntityType)<-[:FROM]-(r:RelationRule)-[:HAS_TYPE]->(rt:RelationType),
      (r)-[:TO]->(t:EntityType)
RETURN s.name AS from, rt.name AS type, t.name AS to, r.description
ORDER BY s.name, rt.name, t.name;

// Properties of one concept
MATCH (et:EntityType {name: $concept})-[:HAS_PROPERTY]->(p:Property)
RETURN p.name, p.kind, p.values, p.description;
```

## Rules

- **Never invent labels or relationship names.** If unsure, run `mcp__neo4j-aj-kb__aj-kb-get_neo4j_schema(sample_size: 200)` (the default sample errors with `Variable None not defined` — pass an explicit integer).
- **Two layers, never overlap.** `:Ontology:*` nodes describe the schema; instance nodes (`:Module`, `:Plugin`, `:APIEndpoints`, …) carry the data. A question about the platform almost always wants instance nodes.
- **Disambiguate identical URIs by HTTP method.** `/api/products/{id}` is three endpoints (GET, PUT, DELETE).
- **The seed lags the working tree.** New controllers/entities added in uncommitted code may not be in the KG yet. When you suspect a gap, say so and offer to grep the source.
- **Present results as a small markdown table** (method/URI/handler, plugin/extension/page, etc.) — the user reads tables faster than JSON.
- **Don't paste the raw Cypher unless asked.** Run the query, summarise the answer; offer to show the query if useful.

## References

- `references/labels.md` — full list of node labels, relationship types, and property keys (mirrors `tools/kg-simple-demo/seed/aj-kg-ontology.cypher`).
- `tools/kg-simple-demo/seed/aj-kg-ontology.cypher` — authoritative schema definition.
- `tools/kg-simple-demo/seed/aj-kg-seed-v2.cypher` — instance data the queries run against.
