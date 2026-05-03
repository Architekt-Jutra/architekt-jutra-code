#!/bin/bash
set -e

# --- 1. Start Neo4j ---
/opt/neo4j/bin/neo4j start

echo "Waiting for Neo4j..."
for i in $(seq 1 30); do
    if /opt/neo4j/bin/cypher-shell -a bolt://127.0.0.1:7687 "RETURN 1" > /dev/null 2>&1; then
        echo "Neo4j ready after ${i}s"
        break
    fi
    if [ "$i" -eq 30 ]; then
        echo "WARNING: Neo4j did not start within 30s, continuing anyway"
    fi
    sleep 1
done

# --- 2. Seed the graph ---
echo "Seeding knowledge graph..."
/opt/neo4j/bin/cypher-shell -a bolt://127.0.0.1:7687 -f /opt/kg-seed/schema.cypher
/opt/neo4j/bin/cypher-shell -a bolt://127.0.0.1:7687 -f /opt/kg-seed/static-nodes.cypher
echo "Knowledge graph seeded."

# --- 3. Initialize MCP state ---
mkdir -p /tmp/mcp-state
cp /opt/mcp-seeds/initial_feature_gates.json /tmp/mcp-state/feature_gates.json

# --- 4. Hand off to agent runner ---
#
# Note: MCP servers are NOT started here. They are spawned on-demand by
# Claude Code via stdio (per variant's claude_config.json — the MCP client
# invokes `python3 /opt/mcp-servers/<name>/server.py` each trial).
#
# Neo4j remains running as a sidecar for aj-knowledge-graph.
exec "$@"
