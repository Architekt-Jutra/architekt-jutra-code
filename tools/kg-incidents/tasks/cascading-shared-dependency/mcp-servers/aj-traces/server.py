"""aj-traces MCP server.

Distributed-trace lookups backed by mcp-seeds/traces.json."""

from __future__ import annotations

import sys
from pathlib import Path

from mcp.server.fastmcp import FastMCP

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "shared"))
from seed_loader import compact, load_seed  # noqa: E402

mcp = FastMCP("aj-traces")


def _seed():
    return load_seed("traces.json")["traces"]


def _matches_service(t, service):
    if not service:
        return True
    if t["root_service"] == service:
        return True
    return any(span["service"] == service for span in t["spans"])


def _matches_endpoint(t, endpoint):
    if not endpoint:
        return True
    if t["root_endpoint"] == endpoint:
        return True
    return any(span["endpoint"] == endpoint for span in t["spans"])


@mcp.tool()
def search_traces(
    service: str | None = None,
    endpoint: str | None = None,
    window_start: str | None = None,
    window_end: str | None = None,
    min_duration_ms: int | None = None,
    limit: int = 20,
) -> str:
    """Search traces by optional filters. Returns summaries: trace_id, root_service,
    root_endpoint, total_duration_ms, span_count, started_at. Use get_trace for spans.

    Args:
        service: Match if the service is the root or appears in any span.
        endpoint: Match if the endpoint is the root or appears in any span.
        window_start, window_end: ISO 8601, clips by started_at.
        min_duration_ms: Minimum total_duration_ms.
        limit: Max number of results (default 20).
    """
    out = []
    for t in _seed():
        if not _matches_service(t, service):
            continue
        if not _matches_endpoint(t, endpoint):
            continue
        if window_start and t["started_at"] < window_start:
            continue
        if window_end and t["started_at"] > window_end:
            continue
        if min_duration_ms is not None and t["total_duration_ms"] < min_duration_ms:
            continue
        out.append({
            "trace_id": t["trace_id"],
            "root_service": t["root_service"],
            "root_endpoint": t["root_endpoint"],
            "total_duration_ms": t["total_duration_ms"],
            "span_count": t["span_count"],
            "started_at": t["started_at"],
        })
        if len(out) >= limit:
            break
    return compact(out)


@mcp.tool()
def get_trace(trace_id: str) -> str:
    """Return full span tree for a trace."""
    for t in _seed():
        if t["trace_id"] == trace_id:
            return compact(t)
    return compact({"error": f"trace '{trace_id}' not found"})


if __name__ == "__main__":
    mcp.run()
