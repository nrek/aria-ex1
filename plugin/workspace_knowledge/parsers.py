from __future__ import annotations

import hashlib
import json
import re
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

try:
    import yaml
except ImportError:  # pragma: no cover
    yaml = None  # type: ignore[assignment]

from .paths import LEGACY_PLAN_FOLDER_STATUS, PLAN_STATUSES, PREFIX_PROJECT_MAP

HANDOFF_TS_RE = re.compile(
    r"^(\d{4}-\d{2}-\d{2}T\d{2}-\d{2}-\d{2}Z)\.md$", re.IGNORECASE
)
FOLLOWUP_RE = re.compile(
    r"^##\s+Follow-up\s+[—\-]\s+(\d{4}-\d{2}-\d{2}T[\d\-]+Z)\s*$",
    re.MULTILINE,
)
LINEAR_RE = re.compile(r"\b(CXL-\d+)\b", re.IGNORECASE)
FILES_CHANGED_RE = re.compile(
    r"^[-*]\s*\*?\*?Files?\s+changed:?\*?\*?\s*(.+)$",
    re.MULTILINE | re.IGNORECASE,
)
H1_RE = re.compile(r"^#\s+(.+)$", re.MULTILINE)


@dataclass
class ParsedDoc:
    frontmatter: dict[str, Any]
    body: str
    title: str | None
    plan_status: str | None
    project: str | None
    linear_task_id: str | None
    files_changed: list[str]
    deploy_commands: list[str]
    tags: list[str]
    todo_total: int
    todo_done: int
    name: str | None
    overview: str | None


def doc_id_for_path(rel_path: str) -> str:
    return hashlib.sha256(rel_path.replace("\\", "/").encode()).hexdigest()[:32]


def _minimal_yaml_load(block: str) -> dict[str, Any]:
    meta: dict[str, Any] = {}
    for line in block.splitlines():
        line = line.strip()
        if not line or line.startswith("#") or ":" not in line:
            continue
        key, _, val = line.partition(":")
        key = key.strip()
        val = val.strip().strip("'\"")
        if val.lower() in ("true", "false"):
            meta[key] = val.lower() == "true"
        else:
            meta[key] = val
    return meta


def split_frontmatter(text: str) -> tuple[dict[str, Any], str]:
    if not text.startswith("---"):
        return {}, text
    parts = text.split("---", 2)
    if len(parts) < 3:
        return {}, text
    block = parts[1]
    if yaml is not None:
        try:
            meta = yaml.safe_load(block) or {}
        except yaml.YAMLError:
            meta = _minimal_yaml_load(block)
    else:
        meta = _minimal_yaml_load(block)
    if not isinstance(meta, dict):
        meta = {}
    return meta, parts[2].lstrip("\n")


def parse_iso_from_filename(name: str) -> str | None:
    m = HANDOFF_TS_RE.match(name)
    if not m:
        return None
    stamp = m.group(1)
    date_part, time_part = stamp.split("T", 1)
    time_part = time_part.rstrip("Z")
    try:
        hh, mm, ss = time_part.split("-")
        iso = f"{date_part}T{hh}:{mm}:{ss}Z"
        dt = datetime.strptime(iso, "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=timezone.utc)
        return dt.isoformat().replace("+00:00", "Z")
    except ValueError:
        return stamp


def infer_project_from_prefix(filename: str) -> str | None:
    upper = filename.upper()
    for prefix, project in PREFIX_PROJECT_MAP:
        if upper.startswith(prefix):
            return project
    return None


def status_from_plan_path(path: Path) -> str | None:
    for part in path.parts:
        if part in PLAN_STATUSES:
            return part
        if part in LEGACY_PLAN_FOLDER_STATUS:
            return LEGACY_PLAN_FOLDER_STATUS[part]
    return None


def extract_deploy_commands(body: str) -> list[str]:
    blocks: list[str] = []
    in_bash = False
    buf: list[str] = []
    for line in body.splitlines():
        if line.strip().startswith("```bash"):
            in_bash = True
            buf = []
            continue
        if in_bash and line.strip() == "```":
            if buf:
                blocks.append("\n".join(buf))
            in_bash = False
            continue
        if in_bash:
            buf.append(line)
    return blocks


def extract_files_changed(body: str, frontmatter: dict[str, Any]) -> list[str]:
    if isinstance(frontmatter.get("files_changed"), list):
        return [str(x) for x in frontmatter["files_changed"]]
    found: list[str] = []
    for m in FILES_CHANGED_RE.finditer(body):
        chunk = m.group(1).strip()
        parts = re.split(r"[,;]\s*", chunk)
        found.extend(p.strip() for p in parts if p.strip())
    return found


def count_todos(frontmatter: dict[str, Any]) -> tuple[int, int]:
    todos = frontmatter.get("todos")
    if not isinstance(todos, list):
        return 0, 0
    total = len(todos)
    done = sum(
        1
        for t in todos
        if isinstance(t, dict)
        and str(t.get("status", "")).lower() in ("completed", "done", "cancelled")
    )
    return total, done


def parse_document(
    rel_path: str,
    text: str,
    *,
    kind: str,
    path_obj: Path,
) -> ParsedDoc:
    frontmatter, body = split_frontmatter(text)
    h1 = H1_RE.search(body)
    title = (
        frontmatter.get("name")
        or frontmatter.get("title")
        or (h1.group(1).strip() if h1 else None)
        or path_obj.stem
    )

    linear = frontmatter.get("linear_task_id")
    if linear:
        linear = str(linear).upper()
    else:
        lm = LINEAR_RE.search(body)
        linear = lm.group(1).upper() if lm else None

    project = frontmatter.get("project")
    if project:
        project = str(project)
    elif kind == "handoff":
        project = path_obj.parent.name if path_obj.parent.name != "handoff" else None
    elif kind in ("plan", "task"):
        project = infer_project_from_prefix(path_obj.name)

    plan_status = frontmatter.get("status")
    if plan_status:
        plan_status = str(plan_status).lower().replace("-", "_")
        if plan_status == "in queue":
            plan_status = "in_queue"
        if plan_status == "in progress":
            plan_status = "in_progress"
    elif kind == "plan":
        plan_status = status_from_plan_path(path_obj)

    if plan_status and plan_status not in PLAN_STATUSES:
        plan_status = None

    tags = frontmatter.get("tags")
    tag_list: list[str] = []
    if isinstance(tags, list):
        tag_list = [str(t) for t in tags]
    elif isinstance(tags, str) and tags:
        tag_list = [tags]

    todo_total, todo_done = count_todos(frontmatter)
    overview = frontmatter.get("overview")
    if overview is not None:
        overview = str(overview)

    return ParsedDoc(
        frontmatter=frontmatter,
        body=body,
        title=str(title) if title else path_obj.stem,
        plan_status=plan_status,
        project=project,
        linear_task_id=linear,
        files_changed=extract_files_changed(body, frontmatter),
        deploy_commands=extract_deploy_commands(body),
        tags=tag_list,
        todo_total=todo_total,
        todo_done=todo_done,
        name=str(frontmatter["name"]) if frontmatter.get("name") else None,
        overview=overview,
    )


def split_handoff_sections(document_id: str, body: str) -> list[dict[str, Any]]:
    matches = list(FOLLOWUP_RE.finditer(body))
    if not matches:
        return [
            {
                "id": hashlib.sha256(f"{document_id}:0".encode()).hexdigest()[:32],
                "heading": None,
                "section_at": None,
                "body": body.strip(),
                "body_hash": hashlib.sha256(body.encode()).hexdigest(),
                "ordinal": 0,
            }
        ]
    sections: list[dict[str, Any]] = []
    preamble = body[: matches[0].start()].strip()
    if preamble:
        sections.append(
            {
                "id": hashlib.sha256(f"{document_id}:preamble".encode()).hexdigest()[:32],
                "heading": "preamble",
                "section_at": None,
                "body": preamble,
                "body_hash": hashlib.sha256(preamble.encode()).hexdigest(),
                "ordinal": 0,
            }
        )
    for i, m in enumerate(matches):
        start = m.start()
        end = matches[i + 1].start() if i + 1 < len(matches) else len(body)
        chunk = body[start:end].strip()
        sections.append(
            {
                "id": hashlib.sha256(f"{document_id}:{i+1}".encode()).hexdigest()[:32],
                "heading": m.group(0).strip(),
                "section_at": m.group(1),
                "body": chunk,
                "body_hash": hashlib.sha256(chunk.encode()).hexdigest(),
                "ordinal": i + 1,
            }
        )
    return sections


def dumps_json(value: Any) -> str | None:
    if value is None:
        return None
    return json.dumps(value, ensure_ascii=False)


def infer_kind_from_path(rel: str) -> str | None:
    rel = rel.replace("\\", "/")
    if rel.endswith("CODEMAP.md"):
        return "codemap"
    if rel.endswith("STITCH.md"):
        return "stitch"
    if rel.startswith(".md/handoff/") or rel.startswith(".aria-ex1/handoffs/"):
        return "handoff"
    if rel.startswith(".md/blueprints/"):
        return "blueprint"
    if rel.startswith(".cursor/plans/") or rel.startswith(".aria-ex1/plans/"):
        return "plan"
    if rel.startswith(".cursor/rules/"):
        return "rule"
    if rel.startswith(".aria-ex1/distilled/") or rel.endswith("TASK.md"):
        return "task"
    if rel.startswith(".aria-ex1/decisions/"):
        return "decision"
    return None
