from __future__ import annotations

import shutil
import sqlite3
from pathlib import Path

from . import db
from .paths import PLUGIN_ROOT, find_workspace_root, resolve_db_path


def ensure_aria_dir(workspace: Path) -> Path:
    aria = workspace / ".aria-ex1"
    aria.mkdir(parents=True, exist_ok=True)
    for sub in ("plans", "handoffs", "decisions", "distilled", "logs"):
        (aria / sub).mkdir(exist_ok=True)
    return aria


def merge_gitignore(workspace: Path) -> bool:
    snippet_path = PLUGIN_ROOT / "template" / "db" / "gitignore.snippet"
    if not snippet_path.is_file():
        return False
    snippet = snippet_path.read_text(encoding="utf-8").strip()
    gi = workspace / ".gitignore"
    if gi.is_file():
        existing = gi.read_text(encoding="utf-8", errors="replace")
        if ".aria-ex1/workspace_index.sqlite" in existing:
            return False
        gi.write_text(existing.rstrip() + "\n\n" + snippet + "\n", encoding="utf-8")
        return True
    gi.write_text(snippet + "\n", encoding="utf-8")
    return True


def copy_schema_to_workspace(workspace: Path) -> Path:
    """Optional: copy schema.sql into .aria-ex1/ for workspace-local reference."""
    src = PLUGIN_ROOT / "template" / "db" / "schema.sql"
    dest = workspace / ".aria-ex1" / "schema.sql"
    if not dest.exists() or src.read_bytes() != dest.read_bytes():
        shutil.copy2(src, dest)
    return dest


def init_workspace(
    workspace: Path | None = None,
    *,
    full_index: bool = False,
) -> dict[str, object]:
    root = (workspace or find_workspace_root()).resolve()
    ensure_aria_dir(root)
    merge_gitignore(root)
    copy_schema_to_workspace(root)

    db_path = resolve_db_path(root)

    result: dict[str, object] = {
        "workspace_root": str(root),
        "db_path": str(db_path),
        "fts5": False,
        "schema_version": db.SCHEMA_VERSION,
    }

    with db.connect(db_path) as conn:
        db.init_db(conn)
        wid = db.ensure_workspace(conn, root)
        result["workspace_id"] = wid
        result["fts5"] = db.fts5_available(conn)
        if not result["fts5"]:
            db.log_index_event(
                conn,
                "bootstrap",
                status="warning",
                message="FTS5 unavailable; search will use LIKE fallback",
            )

    if full_index:
        from .indexer import index_all

        result["index_stats"] = index_all(workspace=root, prune=True)

    return result


def check_sqlite() -> dict[str, object]:
    import sys

    info: dict[str, object] = {
        "python": sys.version.split()[0],
        "sqlite3_module": True,
        "sqlite_version": sqlite3.sqlite_version,
        "fts5": False,
        "workspace_root": str(find_workspace_root()),
        "db_path": str(resolve_db_path()),
    }
    try:
        with db.connect() as conn:
            info["fts5"] = db.fts5_available(conn)
    except Exception as exc:
        info["error"] = str(exc)
    return info
