---
description: "Build or verify group STITCH.md linking frontend and backend CODEMAPs. Modes: create, verify, diff, section. Drift log uses workspace analyze_projects.py when available. Trigger: '/stitch create <group>', '/stitch verify <group>'."
argument-hint: "<create|verify|diff|section> <group> [section-name]"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# /stitch — Cross-repo stitch layer

## Step 0: Load config

Read `~/.claude/aria-ex1.local.md`. Resolve `repo_groups.<group>`. If missing, stop: register the group via `/setup`.

Extract: `backend`, `frontends[]`, `stitch_path`.

## Step 1: Resolve paths

From the user's workspace root (where they run Claude), resolve:

- `BACKEND_ROOT` = path to backend folder
- `FRONTEND_ROOTS` = each frontend folder
- `STITCH_FILE` = `stitch_path` resolved relative to workspace root (if relative)

Require `BACKEND_ROOT/CODEMAP.md` and each frontend `CODEMAP.md` for `create`. If missing, list what's missing and stop.

## Step 2: Template

Start from `${CLAUDE_PLUGIN_ROOT}/template/stitch/STITCH.template.md`.

Fill **Group identity** with repo names and optional `git rev-parse HEAD` per repo if `git` works.

## Step 3: Build sections 2–5

Use the per-repo CODEMAPs to populate:

- **Auth stitch** — token path FE → BE with file paths.
- **Endpoint stitch** — union of RTK/fetch callers → Django routes (normalize paths like `analyze_projects`).
- **Entity stitch** — when traceable from CODEMAP tables.
- **Integration stitch** — merge integration rows from backend CODEMAP; note FE usage if mentioned in FE CODEMAP.

## Step 4: Drift log (deterministic)

Prefer running the workspace script (adjust path to user workspace):

```bash
python analyze_projects.py --frontend <frontend-folder-name> --backend <backend-folder-name>
```

If `analyze_projects.py` is not found, fall back: grep FE for `/api/` strings and compare to backend `urls.py` patterns (document method in drift section).

Paste summarized orphan FE / orphan BE lines into **Drift log**.

## Modes

| Mode | Behavior |
|------|----------|
| `create <group>` | Write full `STITCH_FILE` |
| `verify <group>` | Re-read STITCH tables; check files still exist; flag stale rows |
| `diff <group>` | Run analyze_projects (or fallback) only; print drift |
| `section <group> <n>` | Rebuild section `n` only |

## Rules

- Tables over narrative.
- Every file path must exist on disk when written.
- Do not invent endpoints not evidenced in CODEMAP or code.
