# Maintainer validation checklist

Use a **local multi-repo workspace** (sibling folders for backend + frontend). Paths below are placeholders — substitute your repo folder names.

## 1. Config

Ensure `~/.claude/aria-ex1.local.md` defines at least one `repo_groups` entry (see `plugin/template/LOCAL.md`).

## 2. Codemap

From each repository root:

```bash
cd your-api-repo    # invoke Claude: /codemap create
cd ../your-web-app  # /codemap create
```

## 3. Stitch

With each repo’s `CODEMAP.md` present:

- `/stitch create <group_id>` → writes `STITCH.md` at the configured `stitch_path`.

## 4. Drift vs a script

If you use a workspace-level script that compares frontend calls to backend routes (similar to a generic `analyze_projects.py` pattern), compare its orphan lists to section **6. Drift log** in `STITCH.md`.

Example invocation shape (adjust folder names):

```bash
python analyze_projects.py --frontend your-web-app --backend your-api-repo
```

## 5. Distill

- Micro: `/distill "Fix typo in footer copyright"` (no `--group`).
- With context: `/distill "Add payment webhook" --group=<group_id> --tier=full`.
