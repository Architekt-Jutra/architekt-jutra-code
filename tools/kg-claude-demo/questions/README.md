# Workshop questions

Twelve questions designed so that **without** the Neo4j MCP enabled, Claude
has to grep the repo, read multiple files, and build a partial mental model
on the fly. **With** the MCP enabled, the same questions become a single
Cypher hop.

Each entry below has:

- the question to paste into Claude Code,
- the **shape** of a good answer (what to expect),
- a hint Cypher query you can run directly in the Neo4j Browser
  (http://localhost:7474) to sanity-check what Claude should be saying.

> **Workshop flow.** For each question:
>
> 1. Disable `neo4j-aj-kb` in `/mcp`. Ask the question.
> 2. Note how long Claude takes and which tools it uses (Read/Grep/etc.).
> 3. Re-enable `neo4j-aj-kb`. Ask the same question.
> 4. Open Opik and compare both traces side by side.

---

## Warm-up — get a feel for the graph

### Q1. What is the high-level structure of the aj product?

> "Describe the high-level structure of the aj product — its host, its plugins, and the main backend modules."

**Without MCP:** reads README.md, scans `src/main/java/pl/devstyle/aj/`, lists `plugins/`. ~5–10 file reads.

**With MCP:**
```cypher
MATCH (sys:System {name:'aj'})-[:CONTAINS]->(child)
RETURN sys.name, labels(child) AS kind, child.name AS name, child.description AS description
ORDER BY kind, name;
```

---

### Q2. List every REST endpoint and its required permission.

> "List every REST endpoint exposed by the aj backend and the permission required to call it (if any)."

**Without MCP:** has to open every controller file (`ProductController`, `CategoryController`, `PluginController`, `PluginDataController`, `PluginObjectController`, `AuthController`, `HealthController`, `OAuth2MetadataController`) and parse `@GetMapping` / `@PostMapping` / `@PreAuthorize` attributes.

**With MCP:**
```cypher
MATCH (e:ApiEndpoint)
OPTIONAL MATCH (e)-[:REQUIRES]->(p:Permission)
RETURN e.method, e.path, e.controller, coalesce(p.name, '(public/authenticated)') AS permission
ORDER BY e.path, e.method;
```

---

## Impact analysis — the killer use case

### Q3. If I rename the `Product` entity, what breaks?

> "I'm planning to rename the `Product` entity to `Item`. Which files, controllers, plugins, frontend pages, and external systems will be impacted?"

**Without MCP:** grep "Product" — way too noisy; grep "class Product" + grep imports per module + open every plugin manifest.

**With MCP:**
```cypher
MATCH (e:Entity {name:'Product'})
OPTIONAL MATCH (e)<-[:OPERATES_ON]-(a:Action)-[:EXPOSED_BY]->(ep:ApiEndpoint)
OPTIONAL MATCH (e)-[:PERSISTED_BY]->(r:Repository)<-[:CONTAINS]-(m:Module)
OPTIONAL MATCH (e)<-[:EXTENDS]-(xe:ExtendedEntity)<-[:EXTENDS]-(p:Plugin)
OPTIONAL MATCH (page:Page)-[:USES]->(ep)
RETURN
  collect(DISTINCT m.name)        AS impactedModules,
  collect(DISTINCT ep.id)         AS impactedEndpoints,
  collect(DISTINCT p.id)          AS impactedPlugins,
  collect(DISTINCT page.id)       AS impactedPages;
```

---

### Q4. Which plugins extend the `Product` entity, and how?

> "Which plugins extend the `Product` entity, and through which mechanism?"

**Without MCP:** has to know about `pluginData` JSONB column + read every plugin's manifest + check what objectTypes they use.

**With MCP:**
```cypher
MATCH (p:Plugin)-[:EXTENDS]->(xe:ExtendedEntity)-[:EXTENDS]->(e:Entity {name:'Product'})
RETURN p.id AS plugin, xe.via AS mechanism, xe.fields AS fields
ORDER BY p.id;
```

---

### Q5. Which API endpoints does each plugin depend on?

> "For each plugin, which backend API endpoints does it depend on? Highlight any endpoint that, if changed, would break two or more plugins."

**Without MCP:** read every plugin's source for `fetch(...)` / SDK calls; cross-reference manually.

**With MCP:**
```cypher
MATCH (p:Plugin)-[:USES]->(e:ApiEndpoint)
WITH e, collect(p.id) AS plugins
RETURN e.id AS endpoint, plugins, size(plugins) AS pluginCount
ORDER BY pluginCount DESC, endpoint;
```

---

## Cross-module / cross-layer

### Q6. Find every page that calls a write endpoint that requires `EDIT`.

> "Which frontend pages call write endpoints that require the EDIT permission? I want to know what to test if we tighten EDIT-permission semantics."

**With MCP:**
```cypher
MATCH (page:Page)-[:USES]->(e:ApiEndpoint)-[:REQUIRES]->(perm:Permission {name:'EDIT'})
RETURN page.id AS page, page.file AS file, e.id AS endpoint
ORDER BY page;
```

---

### Q7. Show the path from a plugin click to the database.

> "Trace the call path from a user clicking 'Save' on the warehouse plugin's stock screen all the way to a PostgreSQL row."

**With MCP:**
```cypher
MATCH path = (p:Plugin {id:'warehouse'})
       -[:USES]->(e:ApiEndpoint)
       <-[:EXPOSED_BY]-(a:Action)
       -[:OPERATES_ON]->(ent:Entity)
       -[:PERSISTED_BY]->(r:Repository)
       -[:STORED_IN]->(db:ExternalSystem)
WHERE e.method IN ['PUT','POST']
RETURN p.id, e.id, a.qname, ent.name, r.qname, db.name
LIMIT 25;
```

---

### Q8. What governs how I should write a new entity?

> "I'm adding a new backend entity called `Order`. Which standards from `.maister/docs/standards/` apply to it, and what are the must-follow rules?"

**With MCP:**
```cypher
MATCH (e:Entity)-[:GOVERNED_BY]->(s:Standard)
RETURN DISTINCT s.id, s.title, s.path
ORDER BY s.id;
```

Then ask Claude to **read the listed standards files** and summarize the rules — the graph tells it *which* files to read instead of guessing.

---

## Architecture / explainability

### Q9. Explain the microkernel: who loads plugins and where do plugin objects live?

> "Walk me through the microkernel: which classes register plugins, where plugin manifests are stored, and how plugin-owned objects are persisted."

**With MCP:**
```cypher
MATCH (engine:PluginEngine)-[:CONTAINS]->(node)
RETURN labels(node) AS kind, node.name AS name, node.qname AS qname, node.path AS path
ORDER BY kind, name;
```

---

### Q10. Which extension points does each plugin contribute to?

> "Show me the extension-point coverage matrix: for each plugin, which extension points it uses, and at which priority."

**With MCP:**
```cypher
MATCH (p:Plugin)-[:CONTAINS]->(pp:Page)
WHERE pp.extensionPoint IS NOT NULL
RETURN p.id AS plugin, pp.extensionPoint AS extensionPoint, pp.path AS path,
       pp.title AS title, pp.priority AS priority
ORDER BY p.id, pp.priority DESC;
```

---

## Compliance / risk

### Q11. Which write endpoints are public?

> "Are there any write endpoints (POST/PUT/PATCH/DELETE) that are publicly accessible (no auth required)? This is a security audit question."

**With MCP:**
```cypher
MATCH (e:ApiEndpoint)
WHERE e.method IN ['POST','PUT','PATCH','DELETE']
  AND coalesce(e.public, false) = true
RETURN e.id, e.controller;
```

(Expected result: empty — but this is exactly the query an audit needs.)

---

### Q12. Which standards are not covered by any code yet?

> "Of the standards we documented, which ones aren't yet linked to any code? That's a hint that we have docs without enforcement."

**With MCP:**
```cypher
MATCH (s:Standard)
WHERE NOT (s)<-[:GOVERNED_BY]-()
RETURN s.id, s.title, s.path
ORDER BY s.id;
```

---

## Bonus — let the model write its own Cypher

The point of the demo is that Claude **doesn't need to memorize** the queries
above. Try open-ended questions like:

- "What would change if we deleted the `category` module?"
- "Which plugins would still work if PostgreSQL went read-only?"
- "Give me three refactor candidates based on the graph — modules with the most outbound dependencies."

The MCP tool exposes `get_neo4j_schema`, so Claude discovers the labels and
relationship types on its own and then drafts Cypher. Watch the tool calls
in Opik to see this happen.
