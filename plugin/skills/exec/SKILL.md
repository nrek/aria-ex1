---
description: "Execution item workflow. Trigger: '/exec list', '/exec start <id>', etc."
argument-hint: "list|get|start|block|qa|done|reject|defer <id>"
allowed-tools: Read, Bash
---

# /exec

Queryable execution state in `execution_items` (populated by `/distill` when structured upsert is used).

```bash
python3 ${CLAUDE_PLUGIN_ROOT}/bin/aria-ex1-exec list --status=ready
python3 ${CLAUDE_PLUGIN_ROOT}/bin/aria-ex1-exec get <id> --json
python3 ${CLAUDE_PLUGIN_ROOT}/bin/aria-ex1-exec start <id>
python3 ${CLAUDE_PLUGIN_ROOT}/bin/aria-ex1-exec block <id> --reason="..."
python3 ${CLAUDE_PLUGIN_ROOT}/bin/aria-ex1-exec qa <id>
python3 ${CLAUDE_PLUGIN_ROOT}/bin/aria-ex1-exec done <id>
```

Statuses: `draft`, `needs_clarification`, `ready`, `in_progress`, `blocked`, `qa_ready`, `done`, `deferred`, `rejected`.
