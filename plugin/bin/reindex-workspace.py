#!/usr/bin/env python3
"""afterFileEdit hook: reindex workspace knowledge when meta markdown changes."""

from __future__ import annotations

import json
import sys
from pathlib import Path

_PLUGIN = Path(__file__).resolve().parents[1]
if str(_PLUGIN) not in sys.path:
    sys.path.insert(0, str(_PLUGIN))

WATCH_PREFIXES = (
    ".aria-ex1/",
    ".md/handoff/",
    ".md/blueprints/",
    ".cursor/plans/",
    ".cursor/rules/",
)


def _matches(rel: str) -> bool:
    if any(rel.startswith(p) for p in WATCH_PREFIXES):
        return True
    return rel.endswith("CODEMAP.md") or rel.endswith("STITCH.md")


def main() -> int:
    try:
        raw = sys.stdin.read()
        payload = json.loads(raw) if raw.strip() else {}
    except json.JSONDecodeError:
        return 0

    rel = (
        payload.get("file_path")
        or payload.get("path")
        or payload.get("filePath")
        or ""
    )
    rel = rel.replace("\\", "/")
    if not rel or not _matches(rel):
        return 0

    try:
        from workspace_knowledge.indexer import index_paths
        from workspace_knowledge.paths import find_workspace_root

        workspace = find_workspace_root(
            Path(payload.get("cwd") or payload.get("workspace_root") or ".")
        )
        path = (workspace / rel).resolve()
        if path.is_file():
            index_paths([path], workspace=workspace)
    except Exception:
        pass
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
