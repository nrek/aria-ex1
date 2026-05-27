---
description: "Initialize ARIA-EX1 workspace_index.sqlite. Trigger: '/setup-db'."
argument-hint: "[--full]"
allowed-tools: Read, Bash
---

# /setup-db

Initialize the local workspace index under `.aria-ex1/`.

## Steps

1. From workspace root, run:
   ```bash
   python3 ${CLAUDE_PLUGIN_ROOT}/bin/check-sqlite.py
   python3 ${CLAUDE_PLUGIN_ROOT}/bin/aria-ex1-index --init --full
   ```
2. If FTS5 is unavailable, report degraded search (LIKE fallback) and continue.
3. Confirm `.gitignore` includes `.aria-ex1/workspace_index.sqlite` (bootstrap merges snippet when missing).
4. Print next commands: `aria-ex1-search`, `aria-ex1-context`, `/distill` with DB context.

Optional: pass workspace via `ARIA_EX1_DB_PATH` for a custom DB location.
