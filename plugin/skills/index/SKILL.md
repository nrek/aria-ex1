---
description: "Reindex workspace markdown into SQLite. Trigger: '/index' or '/index --full'."
argument-hint: "[--full] [--path=rel]"
allowed-tools: Read, Bash
---

# /index

Refresh `workspace_index.sqlite` from markdown sources.

```bash
# Full reindex + prune deleted paths
python3 ${CLAUDE_PLUGIN_ROOT}/bin/aria-ex1-index --full

# Single file
python3 ${CLAUDE_PLUGIN_ROOT}/bin/aria-ex1-index --path .md/handoff/myproject/2026-05-26T12-00-00Z.md
```

Report indexed / skipped / removed counts from CLI output.
