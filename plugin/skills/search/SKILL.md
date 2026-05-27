---
description: "Search workspace index via FTS. Trigger: '/search <query>'."
argument-hint: "<query> [--project=] [--kind=]"
allowed-tools: Read, Bash
---

# /search

```bash
python3 ${CLAUDE_PLUGIN_ROOT}/bin/aria-ex1-search "<query>" --json
```

Optional filters: `--project`, `--kind`, `--status` (plan status).

Return title, kind, path, snippet, and `updated_at` — not full document bodies unless the user asks for a specific path via `knowledge_get` / Read.

If the DB is missing, run `/setup-db` first.
