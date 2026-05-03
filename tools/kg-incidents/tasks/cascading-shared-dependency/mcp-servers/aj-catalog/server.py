"""aj-catalog MCP server.

Flat entity lookups — services, datastores, endpoints, dependencies, teams, people.
No inverse lookups (e.g., 'who uses this datastore') and no edge traversal —
those belong to aj-knowledge-graph.
"""

from __future__ import annotations

import sys
from pathlib import Path

from mcp.server.fastmcp import FastMCP

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "shared"))
from seed_loader import compact, load_seed  # noqa: E402

mcp = FastMCP("aj-catalog")


def _seed():
    return load_seed("catalog.json")


# ---------------------------------------------------------------------------
# Services
# ---------------------------------------------------------------------------

@mcp.tool()
def list_services(tier: str | None = None) -> str:
    """List services, optionally filtered by tier ('core' | 'extension' | 'integration').

    Returns summary per service: name, tier, lifecycle."""
    services = _seed()["services"]
    if tier:
        services = [s for s in services if s["tier"] == tier]
    summary = [{"name": s["name"], "tier": s["tier"], "lifecycle": s["lifecycle"]} for s in services]
    return compact(summary)


@mcp.tool()
def find_service(name: str) -> str:
    """Return full service record including owner_team, uses_datastore_names,
    uses_dependency_names (flat string lists), and exposed_endpoints (list of
    {path, method, version})."""
    for s in _seed()["services"]:
        if s["name"] == name:
            return compact(s)
    return compact({"error": f"service '{name}' not found"})


# ---------------------------------------------------------------------------
# Datastores
# ---------------------------------------------------------------------------

@mcp.tool()
def list_datastores(kind: str | None = None) -> str:
    """List datastores, optionally filtered by kind ('relational' | 'keyvalue' |
    'object' | 'stream'). Returns summary."""
    datastores = _seed()["datastores"]
    if kind:
        datastores = [d for d in datastores if d["kind"] == kind]
    return compact([{"name": d["name"], "kind": d["kind"], "capacity_tier": d["capacity_tier"]} for d in datastores])


@mcp.tool()
def find_datastore(name: str) -> str:
    """Return full datastore record with owner_team."""
    for d in _seed()["datastores"]:
        if d["name"] == name:
            return compact(d)
    return compact({"error": f"datastore '{name}' not found"})


# ---------------------------------------------------------------------------
# Endpoints
# ---------------------------------------------------------------------------

@mcp.tool()
def list_endpoints(exposed_by_service: str | None = None) -> str:
    """List endpoints. If exposed_by_service is provided, filter to that service's endpoints only."""
    out = []
    for s in _seed()["services"]:
        if exposed_by_service and s["name"] != exposed_by_service:
            continue
        for e in s["exposed_endpoints"]:
            out.append({**e, "exposed_by": s["name"]})
    return compact(out)


# ---------------------------------------------------------------------------
# Dependencies
# ---------------------------------------------------------------------------

@mcp.tool()
def list_dependencies() -> str:
    """List external dependencies (summary: name, vendor, kind)."""
    return compact([{"name": d["name"], "vendor": d["vendor"], "kind": d["kind"]} for d in _seed()["dependencies"]])


@mcp.tool()
def find_dependency(name: str) -> str:
    """Return full dependency record."""
    for d in _seed()["dependencies"]:
        if d["name"] == name:
            return compact(d)
    return compact({"error": f"dependency '{name}' not found"})


# ---------------------------------------------------------------------------
# Teams and Persons
# ---------------------------------------------------------------------------

@mcp.tool()
def list_teams(kind: str | None = None) -> str:
    """List teams, optionally filtered by kind ('product' | 'platform' | 'partner')."""
    teams = _seed()["teams"]
    if kind:
        teams = [t for t in teams if t["kind"] == kind]
    return compact([{"name": t["name"], "kind": t["kind"]} for t in teams])


@mcp.tool()
def find_team(name: str) -> str:
    """Return full team record including member handles."""
    for t in _seed()["teams"]:
        if t["name"] == name:
            return compact(t)
    return compact({"error": f"team '{name}' not found"})


@mcp.tool()
def find_person(handle: str) -> str:
    """Look up a person by handle (typically email)."""
    for p in _seed()["persons"]:
        if p["handle"] == handle:
            return compact(p)
    return compact({"error": f"person '{handle}' not found"})


if __name__ == "__main__":
    mcp.run()
