#!/usr/bin/env python3
"""Verify Python sqlite3 and FTS5 availability for ARIA-EX1 workspace index."""

from __future__ import annotations

import json
import sys
from pathlib import Path

_PLUGIN = Path(__file__).resolve().parents[1]
if str(_PLUGIN) not in sys.path:
    sys.path.insert(0, str(_PLUGIN))

from workspace_knowledge.bootstrap import check_sqlite  # noqa: E402


def main() -> int:
    info = check_sqlite()
    print(json.dumps(info, indent=2))
    if info.get("error"):
        return 1
    if not info.get("sqlite3_module"):
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
