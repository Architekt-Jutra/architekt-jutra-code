"""aj-knowledge-graph MCP server.

Exposes three tools over a Neo4j-backed Operational Topology Graph (OTG):
  - get_graph_schema: returns ontology summary (labels + edges).
  - find_nodes: search nodes by label and attribute filters.
  - get_neighbors: traverse edges from a node.

All responses are compact JSON (no indentation).
"""

from __future__ import annotations

import sys
from pathlib import Path

from mcp.server.fastmcp import FastMCP
from neo4j import GraphDatabase
from neo4j.exceptions import ServiceUnavailable

# Import shared helpers
sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "shared"))
from seed_loader import compact  # noqa: E402

mcp = FastMCP("aj-knowledge-graph")

_BOLT_URI = "bolt://127.0.0.1:7687"
_driver = None

_VALID_NODE_LABELS = [
    "Service", "Datastore", "Endpoint", "Dependency",
    "FeatureGate", "Revision", "Team", "Person",
]

_VALID_EDGE_TYPES = [
    "owned_by", "member_of", "exposes", "uses_datastore",
    "uses_dependency", "affects", "authored_by", "gates",
]

_SCHEMA_TEXT = """Operational Topology Graph (OTG) — schema.

Node labels:
  Service(name, tier, runtime, release_channel, lifecycle)
  Datastore(name, kind, capacity_tier)
  Endpoint(path, method, version)
  Dependency(name, vendor, kind)
  FeatureGate(name, state, description)
  Revision(id, target_kind, target, kind, at, summary)
  Team(name, kind)
  Person(handle, email)

Edge types:
  (Service | Datastore | Dependency | FeatureGate)-[:owned_by]->(Team)
  (Person)-[:member_of]->(Team)
  (Service)-[:exposes]->(Endpoint)
  (Service)-[:uses_datastore]->(Datastore)
  (Service)-[:uses_dependency]->(Dependency)
  (Revision)-[:affects]->(Service | Datastore | Dependency | FeatureGate)
  (Revision)-[:authored_by]->(Person)
  (FeatureGate)-[:gates]->(Service)

The graph contains topology and change history (Revisions). It does NOT
contain time-series metrics, log entries, or trace spans — query those via
aj-metrics, aj-traces, aj-changes."""


def _get_driver():
    global _driver
    if _driver is None:
        _driver = GraphDatabase.driver(_BOLT_URI)
    return _driver


def _driver_or_error() -> tuple[object, str | None]:
    try:
        return _get_driver(), None
    except ServiceUnavailable:
        return None, "Knowledge graph unavailable: Neo4j is not reachable."


def _node_summary(record_value) -> dict:
    props = dict(record_value)
    labels = sorted(record_value.labels)
    name = props.get("name") or props.get("handle") or props.get("id") or props.get("path", "")
    return {"id": _node_id(record_value), "label": labels[0] if labels else "", "name": name}


def _node_full(record_value) -> dict:
    props = dict(record_value)
    labels = sorted(record_value.labels)
    props["_labels"] = labels
    props["_id"] = _node_id(record_value)
    return props


def _node_id(record_value) -> str:
    """Compute a stable, human-readable id from business keys.

    Returns 'label:business_key' for reference in get_neighbors, e.g. 'Service:ai-description'.
    """
    props = dict(record_value)
    labels = sorted(record_value.labels)
    label = labels[0] if labels else "Node"
    key = (
        props.get("name")
        or props.get("handle")
        or props.get("id")
        or f"{props.get('path','')}-{props.get('method','')}-{props.get('version','')}"
    )
    return f"{label}:{key}"


def _parse_node_id(node_id: str) -> tuple[str, str]:
    """Split 'Label:key' back into (label, business_key). Raises ValueError if malformed."""
    if ":" not in node_id:
        raise ValueError(f"node_id must be in form 'Label:key', got {node_id!r}")
    label, key = node_id.split(":", 1)
    if label not in _VALID_NODE_LABELS:
        raise ValueError(f"unknown label '{label}' in node_id; valid: {_VALID_NODE_LABELS}")
    return label, key


def _key_field_for_label(label: str) -> str:
    """Business key field for each label."""
    return {
        "Service": "name", "Datastore": "name", "Dependency": "name",
        "FeatureGate": "name", "Team": "name",
        "Revision": "id", "Person": "handle",
        "Endpoint": "path",  # special — not commonly addressed by id
    }[label]


# ---------------------------------------------------------------------------
# Tool: get_graph_schema
# ---------------------------------------------------------------------------

@mcp.tool()
def get_graph_schema() -> str:
    """Return the OTG schema — node labels with attributes and edge types with source/target.

    Call this first to understand what the graph contains. Returns plain text (not JSON)."""
    return _SCHEMA_TEXT


# ---------------------------------------------------------------------------
# Tool: find_nodes
# ---------------------------------------------------------------------------

@mcp.tool()
def find_nodes(label: str, filters: dict | None = None) -> str:
    """Find nodes by label (e.g. 'Service', 'Revision') with optional attribute filters.

    Without filters: returns summary (id, label, name) per node.
    With filters: returns full attributes for matching nodes.

    Args:
        label: One of: Service, Datastore, Endpoint, Dependency, FeatureGate, Revision, Team, Person.
        filters: Optional dict of attribute-value pairs matched exactly.
                 Example: {"target": "warehouse", "kind": "deploy"}
    """
    if label not in _VALID_NODE_LABELS:
        return compact({"error": f"unknown label '{label}'", "valid_labels": _VALID_NODE_LABELS})

    driver, err = _driver_or_error()
    if err:
        return compact({"error": err})

    filters = filters or {}

    where_clauses = [f"n.`{k}` = ${k}" for k in filters]
    where = ("WHERE " + " AND ".join(where_clauses)) if where_clauses else ""
    query = f"MATCH (n:{label}) {where} RETURN n"

    with driver.session() as session:
        result = session.run(query, filters)
        if filters:
            nodes = [_node_full(record["n"]) for record in result]
        else:
            nodes = [_node_summary(record["n"]) for record in result]

    return compact(nodes)


# ---------------------------------------------------------------------------
# Tool: get_neighbors
# ---------------------------------------------------------------------------

@mcp.tool()
def get_neighbors(
    node_id: str,
    edge: str | None = None,
    direction: str = "out",
) -> str:
    """Traverse edges from a node, returning neighbor summaries (id, label, name).

    Args:
        node_id: 'Label:business_key', e.g. 'Service:ai-description'.
        edge: Optional edge type filter (e.g. 'uses_datastore', 'owned_by').
        direction: 'out' (default), 'in', or 'both'.
    """
    if direction not in ("out", "in", "both"):
        return compact({"error": f"invalid direction '{direction}'; use 'in', 'out', or 'both'"})
    if edge and edge not in _VALID_EDGE_TYPES:
        return compact({"error": f"unknown edge '{edge}'", "valid_edges": _VALID_EDGE_TYPES})

    driver, err = _driver_or_error()
    if err:
        return compact({"error": err})

    try:
        label, key = _parse_node_id(node_id)
    except ValueError as e:
        return compact({"error": str(e)})
    key_field = _key_field_for_label(label)

    rel = f":`{edge}`" if edge else ""
    if direction == "out":
        pattern = f"(n)-[r{rel}]->(neighbor)"
    elif direction == "in":
        pattern = f"(n)<-[r{rel}]-(neighbor)"
    else:
        pattern = f"(n)-[r{rel}]-(neighbor)"

    query = f"""
        MATCH (n:{label}) WHERE n.`{key_field}` = $key
        MATCH {pattern}
        RETURN type(r) AS edge, neighbor
    """

    with driver.session() as session:
        result = session.run(query, {"key": key})
        records = [
            {"edge": record["edge"], "node": _node_summary(record["neighbor"])}
            for record in result
        ]

    if not records:
        with driver.session() as session:
            check = session.run(
                f"MATCH (n:{label}) WHERE n.`{key_field}` = $key RETURN n LIMIT 1",
                {"key": key},
            )
            if not check.single():
                return compact({"error": "node not found", "node_id": node_id})
        return compact([])

    return compact(records)


# ---------------------------------------------------------------------------

if __name__ == "__main__":
    mcp.run()
