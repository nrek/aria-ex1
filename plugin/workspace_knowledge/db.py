from __future__ import annotations

import hashlib
import sqlite3
from contextlib import contextmanager
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterator

from .paths import SCHEMA_PATH, SCHEMA_VERSION, find_workspace_root, resolve_db_path


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


def workspace_id_for(root: Path) -> str:
    norm = str(root.resolve()).replace("\\", "/").lower()
    return hashlib.sha256(norm.encode()).hexdigest()[:32]


@contextmanager
def connect(db_path: Path | None = None) -> Iterator[sqlite3.Connection]:
    path = db_path or resolve_db_path()
    path.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(path)
    conn.row_factory = sqlite3.Row
    try:
        yield conn
        conn.commit()
    finally:
        conn.close()


def init_db(conn: sqlite3.Connection) -> None:
    schema = SCHEMA_PATH.read_text(encoding="utf-8")
    conn.executescript(schema)
    conn.execute(
        """
        INSERT INTO schema_meta (key, value, updated_at)
        VALUES ('schema_version', ?, datetime('now'))
        ON CONFLICT(key) DO UPDATE SET value = excluded.value, updated_at = excluded.updated_at
        """,
        (SCHEMA_VERSION,),
    )


def ensure_workspace(conn: sqlite3.Connection, root: Path | None = None) -> str:
    ws_root = (root or find_workspace_root()).resolve()
    wid = workspace_id_for(ws_root)
    conn.execute(
        """
        INSERT INTO workspaces (id, root_path, name, updated_at)
        VALUES (?, ?, ?, datetime('now'))
        ON CONFLICT(id) DO UPDATE SET
          root_path = excluded.root_path,
          updated_at = datetime('now')
        """,
        (wid, str(ws_root).replace("\\", "/"), ws_root.name),
    )
    return wid


def fts5_available(conn: sqlite3.Connection) -> bool:
    try:
        conn.execute("CREATE VIRTUAL TABLE IF NOT EXISTS _fts_probe USING fts5(x)")
        conn.execute("DROP TABLE IF EXISTS _fts_probe")
        return True
    except sqlite3.OperationalError:
        return False


def log_index_event(
    conn: sqlite3.Connection,
    event_type: str,
    *,
    path: str | None = None,
    status: str = "ok",
    message: str | None = None,
) -> None:
    conn.execute(
        """
        INSERT INTO index_events (event_type, path, status, message)
        VALUES (?, ?, ?, ?)
        """,
        (event_type, path, status, message),
    )


def delete_document(conn: sqlite3.Connection, doc_id: str) -> None:
    conn.execute("DELETE FROM documents_fts WHERE document_id = ?", (doc_id,))
    conn.execute("DELETE FROM sections WHERE document_id = ?", (doc_id,))
    conn.execute("DELETE FROM plans WHERE document_id = ?", (doc_id,))
    conn.execute("DELETE FROM documents WHERE id = ?", (doc_id,))


def upsert_fts(
    conn: sqlite3.Connection,
    doc_id: str,
    title: str | None,
    summary: str | None,
    body: str,
    project: str | None,
    kind: str,
) -> None:
    conn.execute("DELETE FROM documents_fts WHERE document_id = ?", (doc_id,))
    conn.execute(
        """
        INSERT INTO documents_fts (document_id, title, summary, body, project, kind)
        VALUES (?, ?, ?, ?, ?, ?)
        """,
        (doc_id, title or "", summary or "", body, project or "", kind),
    )


def upsert_document(conn: sqlite3.Connection, row: dict[str, Any]) -> None:
    conn.execute(
        """
        INSERT INTO documents (
            id, workspace_id, repo_id, kind, status, project, path, title, summary,
            body, body_hash, created_at, updated_at, indexed_at,
            plan_status, linear_task_id, files_changed, deploy_commands,
            tags_json, folder_status, status_mismatch, metadata_json
        ) VALUES (
            :id, :workspace_id, :repo_id, :kind, :status, :project, :path, :title, :summary,
            :body, :body_hash, :created_at, :updated_at, datetime('now'),
            :plan_status, :linear_task_id, :files_changed, :deploy_commands,
            :tags_json, :folder_status, :status_mismatch, :metadata_json
        )
        ON CONFLICT(workspace_id, path) DO UPDATE SET
            kind = excluded.kind,
            status = excluded.status,
            project = excluded.project,
            title = excluded.title,
            summary = excluded.summary,
            body = excluded.body,
            body_hash = excluded.body_hash,
            updated_at = excluded.updated_at,
            indexed_at = datetime('now'),
            plan_status = excluded.plan_status,
            linear_task_id = excluded.linear_task_id,
            files_changed = excluded.files_changed,
            deploy_commands = excluded.deploy_commands,
            tags_json = excluded.tags_json,
            folder_status = excluded.folder_status,
            status_mismatch = excluded.status_mismatch,
            metadata_json = excluded.metadata_json
        """,
        row,
    )
    upsert_fts(
        conn,
        row["id"],
        row.get("title"),
        row.get("summary"),
        row["body"],
        row.get("project"),
        row["kind"],
    )


def upsert_plan(conn: sqlite3.Connection, row: dict[str, Any]) -> None:
    conn.execute(
        """
        INSERT INTO plans (
            document_id, status, name, overview, project, linear_task_id,
            todo_total, todo_done, status_changed_at
        ) VALUES (
            :document_id, :status, :name, :overview, :project, :linear_task_id,
            :todo_total, :todo_done, :status_changed_at
        )
        ON CONFLICT(document_id) DO UPDATE SET
            status = excluded.status,
            name = excluded.name,
            overview = excluded.overview,
            project = excluded.project,
            linear_task_id = excluded.linear_task_id,
            todo_total = excluded.todo_total,
            todo_done = excluded.todo_done,
            status_changed_at = COALESCE(plans.status_changed_at, excluded.status_changed_at)
        """,
        row,
    )


def replace_sections(
    conn: sqlite3.Connection, document_id: str, sections: list[dict[str, Any]]
) -> None:
    conn.execute("DELETE FROM sections WHERE document_id = ?", (document_id,))
    for s in sections:
        conn.execute(
            """
            INSERT INTO sections (id, document_id, heading, section_at, body, body_hash, ordinal)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            """,
            (
                s["id"],
                document_id,
                s.get("heading"),
                s.get("section_at"),
                s["body"],
                s.get("body_hash"),
                s["ordinal"],
            ),
        )


def list_indexed_paths(conn: sqlite3.Connection, workspace_id: str) -> set[str]:
    rows = conn.execute(
        "SELECT path FROM documents WHERE workspace_id = ?", (workspace_id,)
    ).fetchall()
    return {r["path"] for r in rows}


def prune_missing(
    conn: sqlite3.Connection, workspace_id: str, existing_paths: set[str]
) -> int:
    indexed = list_indexed_paths(conn, workspace_id)
    removed = 0
    for path in indexed - existing_paths:
        doc_id_row = conn.execute(
            "SELECT id FROM documents WHERE workspace_id = ? AND path = ?",
            (workspace_id, path),
        ).fetchone()
        if doc_id_row:
            delete_document(conn, doc_id_row["id"])
            removed += 1
    return removed
