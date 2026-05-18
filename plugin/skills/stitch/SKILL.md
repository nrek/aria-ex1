---
description: "Build or verify group STITCH.md linking frontend and backend CODEMAPs. Modes: create, verify, diff, section. Drift log uses CODEMAPs first with labeled fallback. Trigger: '/stitch create <group>', '/stitch verify <group>'."
argument-hint: "<create|verify|diff|section> <group> [section-name] [--append|--out=path|--no-archive]"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# /stitch — Cross-repo stitch layer

Generate a cross-repo binding artifact (`STITCH.md`) for a product group. Prefer tables over narrative. Drift detection uses CODEMAP endpoint sections by default, with explicit opt-in before coarse grep fallback.

## Step 0: Load config

Read `~/.claude/aria-ex1.local.md`. Resolve `repo_groups.<group>`. If missing, stop: register the group via `/setup`.

Extract: `backend`, `frontends[]`, `stitch_path`.

## Step 1: Resolve paths & output target

From the user's workspace root (where they run Claude), resolve:

- `BACKEND_ROOT` = path to backend folder
- `FRONTEND_ROOTS` = each frontend folder
- `STITCH_FILE` = `stitch_path` resolved relative to workspace root (if relative)
- If `--out=<path>` is passed, use that path for full `create` output instead of `stitch_path`.

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

## Step 4: Drift log (create + diff modes)

Use this precedence order and label the chosen source in the output.

1. **User script, if explicitly available** — if the workspace has `analyze-stitch.*`, `analyze_projects.py`, or a user-provided drift command, ask before running it. Label output: `Drift source: user script (<script>)`.

2. **CODEMAP-based (default expected path)** — check loaded CODEMAPs for endpoint-bearing sections:
   - Backend: URLConf tree, routes, controllers, views, or endpoint tables.
   - Frontend: API client, RTK Query, fetch wrappers, route callers, or endpoint tables.
   - If both sides are present, normalize discovered rows to `method + path` tuples when methods are available, diff the sets, and label: `Drift source: CODEMAPs (sections: <backend section>, <frontend section>)`.

3. **Missing CODEMAP sections** — if required endpoint sections are absent, stop and present:

   ```text
   STITCH drift detection requires endpoint sections in both CODEMAPs.
   Missing:
     - <backend>/CODEMAP.md: <missing section>
     - <frontend>/CODEMAP.md: <missing section>

   Recommended: run /codemap section <name> in the affected repo(s), then re-run /stitch.
   Fallback: proceed with grep-based drift (coarse; catches presence/absence, misses methods and non-REST conventions).

   Choose: [C]odemap first / [G]rep fallback / [S]kip drift
   ```

4. **Grep fallback (only after user chooses it)** — grep frontend files for API path strings and backend route files for route patterns. Label: `Drift source: grep fallback (coarse)`.

Populate the Drift log with:
- Orphan frontend calls not found in backend routes.
- Backend endpoints not found in frontend callers.
- Unknown rows where method/path normalization was incomplete.
- The drift source label and any limitations.

## Step 5: Write STITCH.md (create mode)

**Overwrite safety** mirrors `/distill`:
- If `STITCH_FILE` exists and is non-empty, first-run behavior: emit a one-time notice explaining the auto-archive default.
- Default: move existing `STITCH_FILE` to `.aria-stitch/archive/STITCH-YYYY-MM-DD-HHMMSS.md`, then write fresh output to `STITCH_FILE`.
- Archive directory `.aria-stitch/archive/` is created next to `STITCH_FILE` lazily on first archive.

**Flags override defaults:**
- `--append` — add a new dated section below existing content. Warn: append on `/stitch create` is rare; `section <n>` is usually the right incremental mode.
- `--out=<path>` — write to the specified path. Existing configured `STITCH_FILE` is untouched; no archive.
- `--no-archive` — overwrite existing `STITCH_FILE` without archiving. Destructive opt-in; display a warning before proceeding.

## Modes

| Mode | Behavior |
|------|----------|
| `create <group>` | Execute Steps 0-5. Write full `STITCH_FILE`. |
| `verify <group>` | Re-read STITCH tables; check files still exist; flag stale rows |
| `diff <group>` | Run drift detection only (Step 4). Print drift summary; do not modify `STITCH_FILE`. |
| `section <group> <n>` | Rebuild section `n` in-place in `STITCH_FILE`. Skips overwrite safety; only that section changes. |

## Rules

- Tables over narrative.
- Every file path must exist on disk when written.
- Do not invent endpoints not evidenced in CODEMAP or code.
