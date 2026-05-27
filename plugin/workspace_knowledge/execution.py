from __future__ import annotations

import hashlib
import json
import re
import sqlite3
from typing import Any

from . import db
from .paths import find_workspace_root

ADVISORY_RE = re.compile(
    r"\b(flexible|extensible|scalable framework|we could also|alternatively|"
    r"one option|potentially|might want to)\b",
    re.IGNORECASE,
)
OPTION_RE = re.compile(r"\b(option\s+[a-z0-9]|approach\s+[12])\b", re.IGNORECASE)


def bloat_score(text: str, *, tier: str = "standard") -> int:
    score = 0
    words = len(text.split())
    if len(OPTION_RE.findall(text)) > 0 or text.lower().count("alternatively") > 0:
        score += 2
    if tier == "full" and "## 3 Non-Goals" not in text and "Non-Goals" not in text:
        score += 2
    if "## 10 QA" not in text and "QA" not in text[:2000]:
        score += 2
    if "owner" not in text.lower() and "status" not in text.lower():
        score += 2
    if tier == "standard" and words > 1200:
        score += 1
    if tier == "micro" and words > 500:
        score += 1
    if ADVISORY_RE.search(text):
        score += 1
    if "Definition of Done" in text or "## 11" in text:
        score -= 2
    if "source" in text.lower() and "reference" in text.lower():
        score -= 1
    return max(0, score)


def upsert_execution_item(
    conn: sqlite3.Connection,
    *,
    workspace_id: str,
    title: str,
    objective: str,
    body: str,
    tier: str = "standard",
    linear_task_id: str | None = None,
    source_document_id: str | None = None,
    status: str = "draft",
    repo_group_id: str | None = None,
) -> str:
    eid = hashlib.sha256(f"{workspace_id}:{title}:{objective[:80]}".encode()).hexdigest()[
        :32
    ]
    layers = _detect_layers(body)
    bloat = bloat_score(body, tier=tier)
    conn.execute(
        """
        INSERT INTO execution_items (
            id, workspace_id, repo_group_id, source_document_id, linear_task_id,
            title, objective, status, tier, bloat_score,
            frontend_touched, backend_touched, database_touched,
            auth_touched, external_service_touched, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, datetime('now'))
        ON CONFLICT(id) DO UPDATE SET
            title = excluded.title,
            objective = excluded.objective,
            status = excluded.status,
            tier = excluded.tier,
            bloat_score = excluded.bloat_score,
            linear_task_id = COALESCE(excluded.linear_task_id, execution_items.linear_task_id),
            frontend_touched = excluded.frontend_touched,
            backend_touched = excluded.backend_touched,
            database_touched = excluded.database_touched,
            auth_touched = excluded.auth_touched,
            external_service_touched = excluded.external_service_touched,
            updated_at = datetime('now')
        """,
        (
            eid,
            workspace_id,
            repo_group_id,
            source_document_id,
            linear_task_id,
            title,
            objective,
            status,
            tier,
            bloat,
            int(layers["frontend"]),
            int(layers["backend"]),
            int(layers["database"]),
            int(layers["auth"]),
            int(layers["external"]),
        ),
    )
    return eid


def _detect_layers(text: str) -> dict[str, bool]:
    lower = text.lower()
    return {
        "frontend": "frontend" in lower or "react" in lower or "next.js" in lower,
        "backend": "backend" in lower or "api" in lower or "endpoint" in lower,
        "database": "database" in lower or "migration" in lower or "model" in lower,
        "auth": "auth" in lower or "permission" in lower,
        "external": any(
            s in lower
            for s in ("stripe", "twilio", "s3", "sendgrid", "algolia", "openai")
        ),
    }


def set_execution_status(
    conn: sqlite3.Connection, item_id: str, status: str
) -> bool:
    cur = conn.execute(
        """
        UPDATE execution_items SET status = ?, updated_at = datetime('now')
        WHERE id = ?
        """,
        (status, item_id),
    )
    return cur.rowcount > 0


def list_execution_items(
    conn: sqlite3.Connection,
    *,
    workspace_id: str,
    status: str | None = None,
    limit: int = 50,
) -> list[dict[str, Any]]:
    clauses = ["workspace_id = ?"]
    params: list[Any] = [workspace_id]
    if status:
        clauses.append("status = ?")
        params.append(status)
    params.append(limit)
    rows = conn.execute(
        f"""
        SELECT id, title, status, tier, linear_task_id, priority, bloat_score, updated_at
        FROM execution_items
        WHERE {" AND ".join(clauses)}
        ORDER BY updated_at DESC
        LIMIT ?
        """,
        params,
    ).fetchall()
    return [dict(r) for r in rows]


def get_execution_item(conn: sqlite3.Connection, item_id: str) -> dict[str, Any] | None:
    row = conn.execute(
        "SELECT * FROM execution_items WHERE id = ?", (item_id,)
    ).fetchone()
    return dict(row) if row else None
