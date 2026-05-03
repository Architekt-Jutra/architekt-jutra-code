# MCP — Neo4j + Opik

This folder contains the MCP (Model Context Protocol) configuration that
lets Claude Code talk to two services:

- **`neo4j-aj-kb`** — the knowledge graph (the star of the workshop).
- **`opik`** — Opik's own MCP, so Claude can introspect the trace data
  it's producing ("how many tool calls did the last turn make?").
  This is observability of the agent, by the agent.

## What participants get

`neo4j-aj-kb` exposes three tools:

| Tool                      | What it does                                        |
| ------------------------- | --------------------------------------------------- |
| `get_neo4j_schema`        | Returns labels, relationship types, and properties. |
| `read_neo4j_cypher`       | Runs read-only Cypher.                              |
| `write_neo4j_cypher`      | Runs write Cypher (we keep this on for demo agility — disable if you want strict read-only). |

`opik` exposes tools for listing projects, traces, and spans, plus
filtering by tags and time range. Useful for participants who want to
ask Claude to summarize its own behavior.

## Prerequisites

- `uv` / `uvx` installed (`brew install uv` on macOS)
- Neo4j running (`make up` from the parent folder)

## How to enable in Claude Code

Pick **one** of the three options below.

### Option A — Project-scoped (recommended for the workshop)

Copy `.mcp.json` into the project root **or** start `claude` from the
`knowledge-base/kg-claude-demo/mcp/` directory. Claude Code auto-discovers
`.mcp.json` in the working directory.

```bash
cd knowledge-base/kg-claude-demo/mcp
claude
```

The first prompt will ask whether to trust the project's MCP servers — accept.

### Option B — Add to user settings (`~/.claude.json`)

Append the entry from `.mcp.json` into the `"mcpServers"` block of your
`~/.claude.json`. Useful if you want the tool available across all repos.

### Option C — `claude mcp add`

```bash
claude mcp add neo4j-aj-kb \
  --command uvx \
  --args "mcp-neo4j-cypher@latest --transport stdio" \
  --env NEO4J_URI=bolt://localhost:7687 \
  --env NEO4J_USERNAME=neo4j \
  --env NEO4J_PASSWORD=aj-knowledge
```

## Toggling on / off during the workshop

Inside a Claude Code session:

- `/mcp` — list MCP servers and their connection status.
- Enable / disable a server via the `/mcp` UI without restarting Claude.

This is the toggle the workshop uses to demonstrate "with KG vs. without KG":

1. Disable `neo4j-aj-kb` and ask question Q1.
2. Enable it, ask the same Q1 — compare quality and speed.
3. Watch both runs in Opik (different traces, different tool-call patterns).

## Verifying the connection

Once Claude is running:

```
> /mcp
```

You should see both `neo4j-aj-kb` and `opik` as `connected`. Then ask:

```
> Use the Neo4j tool to return the schema of the knowledge graph.
```

Claude will call `get_neo4j_schema` and you'll see ~20 labels (System, Host, Plugin, Module, Entity, Repository, Action, ApiEndpoint, Page, Standard, ...) and a dozen relationship types (CONTAINS, EMBEDS, USES, EXTENDS, EXPOSED_BY, OPERATES_ON, PERSISTED_BY, GOVERNED_BY, REQUIRES, ...).
