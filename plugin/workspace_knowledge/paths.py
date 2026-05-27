from __future__ import annotations

import os
from pathlib import Path

_PKG = Path(__file__).resolve().parent
PLUGIN_ROOT = _PKG.parent
SCHEMA_PATH = PLUGIN_ROOT / "template" / "db" / "schema.sql"

SCHEMA_VERSION = "1"
FTS5_REQUIRED = False

PLAN_STATUSES = frozenset({"draft", "backlog", "in_queue", "in_progress", "done"})
LEGACY_PLAN_FOLDER_STATUS = {
    "new": "draft",
    "built": "done",
    "backlog": "backlog",
    "draft": "draft",
    "in_queue": "in_queue",
    "in_progress": "in_progress",
    "done": "done",
}

PREFIX_PROJECT_MAP = [
    ("CS_", "commonspace"),
    ("SS_", "seersite"),
    ("INVIV_", "invivaria"),
    ("SYNQ_", "synq-forge"),
    ("PROMP_", "v5.prompli.com"),
    ("BI_", "blind-insight"),
    ("CXL_", "cxl-sentinel"),
    ("SAN_", "cxl-sentinel"),
]

BLUEPRINT_ALIASES: dict[str, str] = {
    "commonspace-app": "commonspace-app.md",
    "commonspace-ui-v3": "commonspace-ui-v3.md",
    "commonspace-mobile-ui": "commonspace-ui-v3.md",
    "seersite-server": "seersite-server.md",
    "seersite-frontend": "seersite-frontend.md",
    "invivaria-frontend": "invivaria-frontend.md",
    "invivaria-backend": "invivaria-backend.md",
    "synq-phalanx": "synq-phalanx.md",
    "synq-filters": "synq-filters.md",
    "synq-forge": "synq-forge.md",
    "synq-net-scrapers": "synq-net-scrapers.md",
    "v5.prompli.com": "v5.prompli.com.md",
    "blind-insight": "prompli-prompter-data-flow.md",
    "blind-llm": "prompli-prompter-data-flow.md",
}


def find_workspace_root(start: Path | None = None) -> Path:
    cur = (start or Path.cwd()).resolve()
    for _ in range(24):
        if (cur / ".aria-ex1").is_dir():
            return cur
        if (cur / ".md" / "handoff").is_dir():
            return cur
        if (cur / ".git").exists():
            return cur
        parent = cur.parent
        if parent == cur:
            break
        cur = parent
    return (start or Path.cwd()).resolve()


def resolve_db_path(workspace: Path | None = None) -> Path:
    env = os.environ.get("ARIA_EX1_DB_PATH", "").strip()
    if env:
        return Path(env).expanduser().resolve()
    root = workspace or find_workspace_root()
    aria_db = root / ".aria-ex1" / "workspace_index.sqlite"
    legacy = root / ".md" / "workspace_index.sqlite"
    if aria_db.exists():
        return aria_db
    if legacy.exists() and not (root / ".aria-ex1").is_dir():
        return legacy
    return aria_db


WORKSPACE_ROOT = find_workspace_root()
DB_PATH = resolve_db_path(WORKSPACE_ROOT)
