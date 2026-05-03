"""aj-metrics MCP server.

Time-series with 5-minute buckets for 24h preceding incident anchor.
All data pre-generated into mcp-seeds/metrics.json."""

from __future__ import annotations

import sys
from pathlib import Path

from mcp.server.fastmcp import FastMCP

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "shared"))
from seed_loader import compact, load_seed  # noqa: E402

mcp = FastMCP("aj-metrics")


def _seed():
    return load_seed("metrics.json")["metrics"]


@mcp.tool()
def list_metrics(service: str | None = None) -> str:
    """List available metrics (service, metric, unit). Optional service filter."""
    metrics = _seed()
    if service:
        metrics = [m for m in metrics if m["service"] == service]
    return compact([{"service": m["service"], "metric": m["metric"], "unit": m["unit"]} for m in metrics])


@mcp.tool()
def query_metric(service: str, metric: str, window_start: str, window_end: str) -> str:
    """Return buckets ({t, p50, p99, avg, count}) for service/metric within [window_start, window_end].

    Timestamps are ISO 8601 strings (e.g. '2026-04-17T14:00:00Z'). Endpoints inclusive."""
    for m in _seed():
        if m["service"] == service and m["metric"] == metric:
            clipped = [b for b in m["buckets"] if window_start <= b["t"] <= window_end]
            return compact({
                "service": m["service"],
                "metric": m["metric"],
                "unit": m["unit"],
                "buckets": clipped,
            })
    return compact({"error": f"no metric '{metric}' for service '{service}'"})


@mcp.tool()
def list_services_with_metrics() -> str:
    """Return the deduplicated list of service names that have any metrics."""
    return compact(sorted({m["service"] for m in _seed()}))


if __name__ == "__main__":
    mcp.run()
