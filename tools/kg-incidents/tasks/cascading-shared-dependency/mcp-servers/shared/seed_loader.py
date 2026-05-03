"""Shared helpers for aj-* MCP servers.

Provides:
  - load_seed(filename): reads the JSON seed from mcp-seeds/ relative to task root.
  - compact(obj): json.dumps without indent, for token-efficient responses.
"""

from __future__ import annotations

import json
from functools import lru_cache
from pathlib import Path
from typing import Any


def _task_root() -> Path:
    """Return the task root (.../cascading-shared-dependency) regardless of server file location."""
    # Each server.py lives at .../mcp-servers/<server-name>/server.py
    # shared/seed_loader.py lives at .../mcp-servers/shared/seed_loader.py
    # Task root is two levels up from mcp-servers/.
    return Path(__file__).resolve().parent.parent.parent


@lru_cache(maxsize=None)
def load_seed(filename: str) -> Any:
    """Load a JSON seed file from mcp-seeds/ by filename (e.g. 'catalog.json')."""
    path = _task_root() / "mcp-seeds" / filename
    with path.open(encoding="utf-8") as f:
        return json.load(f)


def compact(obj: Any) -> str:
    """Serialize to JSON without indent — compact MCP responses save tokens."""
    return json.dumps(obj, ensure_ascii=False, separators=(",", ":"), default=str)
