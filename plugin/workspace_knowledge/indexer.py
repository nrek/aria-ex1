from __future__ import annotations

import hashlib
from datetime import datetime, timezone
from pathlib import Path

from . import db, parsers
from .parsers import (
    doc_id_for_path,
    dumps_json,
    infer_kind_from_path,
    parse_document,
    parse_iso_from_filename,
    split_handoff_sections,
)
from .paths import find_workspace_root, resolve_db_path


def _rel(path: Path, root: Path) -> str:
    return path.relative_to(root).as_posix()


def _mtime_iso(path: Path) -> str:
    ts = path.stat().st_mtime
    return datetime.fromtimestamp(ts, tz=timezone.utc).isoformat().replace("+00:00", "Z")


def _summary(body: str, max_len: int = 400) -> str:
    t = body.strip()
    if len(t) <= max_len:
        return t
    return t[: max_len - 3] + "..."


def discover_files(workspace: Path) -> list[tuple[str, Path]]:
    out: list[tuple[str, Path]] = []
    root = workspace

    patterns: list[tuple[str, Path, str]] = [
        ("handoff", root / ".md" / "handoff", "**/*.md"),
        ("handoff", root / ".aria-ex1" / "handoffs", "**/*.md"),
        ("blueprint", root / ".md" / "blueprints", "*.md"),
        ("plan", root / ".cursor" / "plans", "**/*"),
        ("plan", root / ".aria-ex1" / "plans", "**/*.md"),
        ("rule", root / ".cursor" / "rules", "*.mdc"),
        ("task", root / ".aria-ex1" / "distilled", "**/*.md"),
        ("decision", root / ".aria-ex1" / "decisions", "**/*.md"),
    ]

    for kind, base, pattern in patterns:
        if not base.is_dir():
            continue
        for p in base.glob(pattern):
            if not p.is_file():
                continue
            if p.name.startswith("_") or p.name.startswith("."):
                continue
            if kind == "plan" and p.suffix.lower() not in (".md",) and not p.name.endswith(
                ".plan.md"
            ):
                continue
            out.append((kind, p))

    for name in ("CODEMAP.md", "STITCH.md"):
        for p in root.glob(f"**/{name}"):
            if not p.is_file():
                continue
            parts = len(p.relative_to(root).parts)
            if parts > 6:
                continue
            kind = "codemap" if name == "CODEMAP.md" else "stitch"
            out.append((kind, p))

    return out


def index_file(
    conn,
    path: Path,
    *,
    workspace_id: str,
    workspace_root: Path,
    kind: str | None = None,
) -> bool:
    if kind is None:
        kind = infer_kind_from_path(_rel(path, workspace_root))
    if not kind:
        return False

    rel_path = _rel(path, workspace_root)
    text = path.read_text(encoding="utf-8", errors="replace")
    body_hash = hashlib.sha256(text.encode()).hexdigest()

    existing = conn.execute(
        "SELECT body_hash FROM documents WHERE workspace_id = ? AND path = ?",
        (workspace_id, rel_path),
    ).fetchone()
    if existing and existing["body_hash"] == body_hash:
        return False

    parsed = parse_document(rel_path, text, kind=kind, path_obj=path)
    doc_id = doc_id_for_path(rel_path)

    created = parse_iso_from_filename(path.name) or _mtime_iso(path)
    updated = _mtime_iso(path)

    folder_status = parsers.status_from_plan_path(path) if kind == "plan" else None
    status_mismatch = 0
    if kind == "plan" and parsed.plan_status and folder_status:
        if parsed.plan_status != folder_status:
            status_mismatch = 1

    project = parsed.project
    if kind == "codemap" and not project:
        project = path.parent.name

    row = {
        "id": doc_id,
        "workspace_id": workspace_id,
        "repo_id": None,
        "kind": kind,
        "status": parsed.plan_status if kind == "plan" else None,
        "project": project,
        "path": rel_path,
        "title": parsed.title,
        "summary": _summary(parsed.body),
        "body": text,
        "body_hash": body_hash,
        "created_at": created,
        "updated_at": updated,
        "plan_status": parsed.plan_status,
        "linear_task_id": parsed.linear_task_id,
        "files_changed": dumps_json(parsed.files_changed),
        "deploy_commands": dumps_json(parsed.deploy_commands),
        "tags_json": dumps_json(parsed.tags),
        "folder_status": folder_status,
        "status_mismatch": status_mismatch,
        "metadata_json": None,
    }
    db.upsert_document(conn, row)

    if kind == "plan" and parsed.plan_status:
        db.upsert_plan(
            conn,
            {
                "document_id": doc_id,
                "status": parsed.plan_status,
                "name": parsed.name or parsed.title,
                "overview": parsed.overview,
                "project": parsed.project,
                "linear_task_id": parsed.linear_task_id,
                "todo_total": parsed.todo_total,
                "todo_done": parsed.todo_done,
                "status_changed_at": updated,
            },
        )
    elif kind == "plan":
        conn.execute("DELETE FROM plans WHERE document_id = ?", (doc_id,))

    if kind in ("handoff", "plan"):
        sections = split_handoff_sections(doc_id, parsed.body)
        db.replace_sections(conn, doc_id, sections)

    return True


def index_all(*, workspace: Path | None = None, prune: bool = True) -> dict[str, int]:
    root = (workspace or find_workspace_root()).resolve()
    stats = {"indexed": 0, "skipped": 0, "removed": 0, "warnings": 0}

    with db.connect(resolve_db_path(root)) as conn:
        db.init_db(conn)
        wid = db.ensure_workspace(conn, root)
        paths_seen: set[str] = set()

        for kind, path in discover_files(root):
            rel = _rel(path, root)
            paths_seen.add(rel)
            try:
                if index_file(
                    conn, path, workspace_id=wid, workspace_root=root, kind=kind
                ):
                    stats["indexed"] += 1
                else:
                    stats["skipped"] += 1
            except (OSError, ValueError) as exc:
                db.log_index_event(
                    conn, "index_file", path=rel, status="error", message=str(exc)
                )

        if prune:
            stats["removed"] = db.prune_missing(conn, wid, paths_seen)

        warnings = conn.execute(
            "SELECT COUNT(*) AS c FROM documents WHERE status_mismatch = 1"
        ).fetchone()
        stats["warnings"] = int(warnings["c"]) if warnings else 0

    return stats


def index_paths(paths: list[Path], *, workspace: Path | None = None) -> dict[str, int]:
    root = (workspace or find_workspace_root()).resolve()
    stats = {"indexed": 0, "skipped": 0}
    with db.connect(resolve_db_path(root)) as conn:
        db.init_db(conn)
        wid = db.ensure_workspace(conn, root)
        for path in paths:
            if not path.is_file():
                continue
            try:
                resolved = path.resolve()
                if index_file(conn, resolved, workspace_id=wid, workspace_root=root):
                    stats["indexed"] += 1
                else:
                    stats["skipped"] += 1
            except (OSError, ValueError):
                continue
    return stats
