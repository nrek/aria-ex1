from __future__ import annotations

import json
import re
import sqlite3
from datetime import datetime, timedelta, timezone
from typing import Any

from . import db
from .paths import BLUEPRINT_ALIASES, find_workspace_root


def _snippet(text: str, max_len: int = 400) -> str:
    t = (text or "").strip()
    if len(t) <= max_len:
        return t
    return t[: max_len - 3] + "..."


def _fts_query(query: str) -> str:
    """Normalize user input for FTS5 (dots and bare punctuation break MATCH)."""
    cleaned = re.sub(r"[^\w\s\-]", " ", query, flags=re.UNICODE)
    parts = [p for p in cleaned.split() if p.strip()]
    if not parts:
        return query.replace('"', '""')
    return " ".join(parts)


def knowledge_search(
    conn: sqlite3.Connection,
    *,
    query: str,
    workspace_id: str,
    project: str | None = None,
    kind: str | None = None,
    plan_status: str | None = None,
    limit: int = 15,
) -> list[dict[str, Any]]:
    if db.fts5_available(conn):
        clauses = ["documents_fts MATCH ?"]
        params: list[Any] = [_fts_query(query)]
        joins = "JOIN documents d ON d.id = documents_fts.document_id"
        clauses.append("d.workspace_id = ?")
        params.append(workspace_id)
        if project:
            clauses.append("d.project = ?")
            params.append(project)
        if kind:
            clauses.append("d.kind = ?")
            params.append(kind)
        if plan_status:
            clauses.append("d.plan_status = ?")
            params.append(plan_status)
        where = " AND ".join(clauses)
        params.append(limit)
        rows = conn.execute(
            f"""
            SELECT d.path, d.kind, d.project, d.title, d.plan_status, d.status,
                   d.updated_at, d.indexed_at,
                   snippet(documents_fts, 3, '**', '**', '…', 48) AS snippet,
                   bm25(documents_fts) AS rank
            FROM documents_fts
            {joins}
            WHERE {where}
            ORDER BY rank
            LIMIT ?
            """,
            params,
        ).fetchall()
        return [dict(r) for r in rows]

    like = f"%{query}%"
    clauses = ["(d.body LIKE ? OR d.title LIKE ? OR d.summary LIKE ?)", "d.workspace_id = ?"]
    params: list[Any] = [like, like, like, workspace_id]
    if project:
        clauses.append("d.project = ?")
        params.append(project)
    if kind:
        clauses.append("d.kind = ?")
        params.append(kind)
    if plan_status:
        clauses.append("d.plan_status = ?")
        params.append(plan_status)
    params.append(limit)
    rows = conn.execute(
        f"""
        SELECT d.path, d.kind, d.project, d.title, d.plan_status, d.status,
               d.updated_at, d.indexed_at,
               substr(d.body, 1, 300) AS snippet,
               0 AS rank
        FROM documents d
        WHERE {" AND ".join(clauses)}
        ORDER BY d.updated_at DESC
        LIMIT ?
        """,
        params,
    ).fetchall()
    return [dict(r) for r in rows]


def knowledge_recent(
    conn: sqlite3.Connection,
    *,
    workspace_id: str,
    project: str | None = None,
    hours: int = 48,
    kind: str | None = None,
    limit: int = 10,
) -> list[dict[str, Any]]:
    since = (datetime.now(timezone.utc) - timedelta(hours=hours)).isoformat().replace(
        "+00:00", "Z"
    )
    clauses = ["workspace_id = ?", "(updated_at >= ? OR created_at >= ?)"]
    params: list[Any] = [workspace_id, since, since]
    if project:
        clauses.append("project = ?")
        params.append(project)
    if kind:
        clauses.append("kind = ?")
        params.append(kind)
    params.append(limit)
    rows = conn.execute(
        f"""
        SELECT path, kind, project, title, updated_at, plan_status, status,
               substr(body, 1, 800) AS excerpt
        FROM documents
        WHERE {" AND ".join(clauses)}
        ORDER BY updated_at DESC
        LIMIT ?
        """,
        params,
    ).fetchall()
    return [dict(r) for r in rows]


def knowledge_get(conn: sqlite3.Connection, path: str, workspace_id: str) -> dict[str, Any] | None:
    row = conn.execute(
        "SELECT * FROM documents WHERE workspace_id = ? AND path = ?",
        (workspace_id, path.replace("\\", "/")),
    ).fetchone()
    if not row:
        return None
    out = dict(row)
    for key in ("files_changed", "deploy_commands", "tags_json", "metadata_json"):
        if out.get(key):
            try:
                out[key] = json.loads(out[key])
            except json.JSONDecodeError:
                pass
    return out


def knowledge_blueprint(
    conn: sqlite3.Connection,
    project: str,
    *,
    workspace_id: str,
    max_chars: int = 2000,
) -> dict[str, Any] | None:
    root = find_workspace_root()
    alias = project.lower().strip()
    filename = BLUEPRINT_ALIASES.get(alias)
    bp_dir = root / ".md" / "blueprints"
    candidates = []
    if filename:
        candidates.append(bp_dir / filename)
    candidates.append(bp_dir / f"{alias}.md")
    for c in candidates:
        if c.is_file():
            rel = c.relative_to(root).as_posix()
            doc = knowledge_get(conn, rel, workspace_id)
            if doc:
                doc["excerpt"] = _snippet(doc.get("body", ""), max_chars)
                return doc
    row = conn.execute(
        """
        SELECT path, title, substr(body, 1, ?) AS excerpt
        FROM documents
        WHERE workspace_id = ? AND kind = 'blueprint'
          AND (project = ? OR path LIKE ?)
        LIMIT 1
        """,
        (max_chars, workspace_id, alias, f"%.md/blueprints/%{alias}%"),
    ).fetchone()
    return dict(row) if row else None


def recent_sections(
    conn: sqlite3.Connection,
    *,
    workspace_id: str,
    project: str,
    hours: int = 48,
    limit: int = 8,
) -> list[dict[str, Any]]:
    since = (datetime.now(timezone.utc) - timedelta(hours=hours)).isoformat().replace(
        "+00:00", "Z"
    )
    rows = conn.execute(
        """
        SELECT d.path, d.project, s.heading, s.section_at,
               substr(s.body, 1, 600) AS excerpt, s.ordinal
        FROM sections s
        JOIN documents d ON d.id = s.document_id
        WHERE d.workspace_id = ?
          AND d.kind = 'handoff'
          AND d.project = ?
          AND (s.section_at >= ? OR d.updated_at >= ?)
        ORDER BY COALESCE(s.section_at, d.updated_at) DESC
        LIMIT ?
        """,
        (workspace_id, project, since, since, limit),
    ).fetchall()
    return [dict(r) for r in rows]


def build_context(
    conn: sqlite3.Connection,
    *,
    workspace_id: str,
    project: str | None = None,
    group: str | None = None,
    hours: int = 72,
    linear_task_id: str | None = None,
    limit: int = 12,
) -> dict[str, Any]:
    proj = project or group
    ctx: dict[str, Any] = {
        "project": proj,
        "hours": hours,
        "recent_documents": [],
        "recent_sections": [],
        "plans_in_queue": [],
        "execution_items": [],
    }
    if proj:
        ctx["recent_documents"] = knowledge_recent(
            conn, workspace_id=workspace_id, project=proj, hours=hours, limit=limit
        )
        ctx["recent_sections"] = recent_sections(
            conn, workspace_id=workspace_id, project=proj, hours=hours, limit=6
        )
        bp = knowledge_blueprint(conn, proj, workspace_id=workspace_id)
        if bp:
            ctx["blueprint"] = {
                "path": bp.get("path"),
                "title": bp.get("title"),
                "excerpt": bp.get("excerpt"),
            }
    else:
        ctx["recent_documents"] = knowledge_recent(
            conn, workspace_id=workspace_id, hours=hours, limit=limit
        )

    plan_rows = conn.execute(
        """
        SELECT d.path, p.status, p.name, p.project
        FROM plans p
        JOIN documents d ON d.id = p.document_id
        WHERE d.workspace_id = ?
          AND p.status IN ('in_queue', 'in_progress')
        ORDER BY d.updated_at DESC
        LIMIT 10
        """,
        (workspace_id,),
    ).fetchall()
    ctx["plans_in_queue"] = [dict(r) for r in plan_rows]

    exec_clauses = ["workspace_id = ?"]
    exec_params: list[Any] = [workspace_id]
    if linear_task_id:
        exec_clauses.append("linear_task_id = ?")
        exec_params.append(linear_task_id.upper())
    elif proj:
        exec_clauses.append(
            "(metadata_json LIKE ? OR title LIKE ?)"
        )
        exec_params.extend([f"%{proj}%", f"%{proj}%"])

    exec_rows = conn.execute(
        f"""
        SELECT id, title, status, tier, linear_task_id, priority
        FROM execution_items
        WHERE {" AND ".join(exec_clauses)}
        ORDER BY updated_at DESC
        LIMIT 10
        """,
        exec_params,
    ).fetchall()
    ctx["execution_items"] = [dict(r) for r in exec_rows]

    if linear_task_id:
        doc = conn.execute(
            """
            SELECT path, title, kind FROM documents
            WHERE workspace_id = ? AND linear_task_id = ?
            LIMIT 5
            """,
            (workspace_id, linear_task_id.upper()),
        ).fetchall()
        ctx["linked_documents"] = [dict(r) for r in doc]

    return ctx
