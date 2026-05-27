# SQLite workspace index

## Locations

| Path | Purpose |
|------|---------|
| `<workspace>/.aria-ex1/workspace_index.sqlite` | Default DB (gitignored) |
| `<workspace>/.aria-ex1/schema.sql` | Copy of committed schema after `/setup-db` |
| `plugin/template/db/schema.sql` | Committed schema source |
| `<workspace>/.md/workspace_index.sqlite` | Legacy alternate if `ARIA_EX1_DB_PATH` unset and file exists |

Override with `ARIA_EX1_DB_PATH`.

## Setup

```bash
python3 plugin/bin/check-sqlite.py
python3 plugin/bin/aria-ex1-index --init --full
```

## CLI

| Command | Role |
|---------|------|
| `aria-ex1-index --init --full` | Bootstrap + full reindex |
| `aria-ex1-index --path <file>` | Incremental path reindex |
| `aria-ex1-search "<query>"` | FTS (or LIKE fallback) |
| `aria-ex1-context --group=<project> --hours=72` | Compact agent context JSON |
| `aria-ex1-exec list\|get\|start\|block\|qa\|done` | Execution item workflow |

## Indexed paths

- `.md/handoff/**`, `.md/blueprints/*`
- `.cursor/plans/**`, `.cursor/rules/*.mdc`
- `.aria-ex1/{handoffs,plans,distilled,decisions}/**`
- `CODEMAP.md`, `STITCH.md` (depth-limited walk)

## Hooks

`plugin/bin/reindex-workspace.py` is fail-open: indexing errors never block edits.
