# Agent Instructions

## Knowledge Graph

You have a **Knowledge Graph** (`aj-knowledge-graph` MCP) — a Neo4j-backed graph containing the platform's topology, ownership, and change history. **Use it as your primary navigation tool for cross-entity questions (ownership, dependencies, co-users of shared resources, recent changes).**

### Available tools

- `get_graph_schema()` — call once to learn node labels and edge types
- `find_nodes(label, filters?)` — search nodes by label and attributes
- `get_neighbors(node_id, edge?, direction?)` — traverse edges from a node

### When to use the graph vs. other MCPs

The graph contains: Services, Datastores, Dependencies, Endpoints, FeatureGates, Revisions, Teams, Persons, and the edges between them (ownership, usage, change authorship). Use it when the question involves a **relationship** between entities.

Use domain MCPs (`aj-catalog`, `aj-metrics`, `aj-traces`, `aj-changes`) when you need detailed attributes, time-series data, individual spans, or full revision content.

## Other MCP tools

- `aj-catalog` — plain entity lookups (services, datastores, teams, persons)
- `aj-metrics` — time-series metrics per service
- `aj-traces` — distributed traces and spans
- `aj-changes` — revisions, feature gates, and state mutations

## Rules

- The graph contains **facts, not conclusions**. Correlate and reason yourself.
- Check ownership before modifying code — do not edit components owned by teams outside your authority.
- Follow existing architectural patterns in the codebase.
