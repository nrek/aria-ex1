# ARIA-EX1 execution method

ARIA-EX1 is an execution-first workspace layer for AI-assisted development. Markdown remains the human-readable source of truth; `workspace_index.sqlite` is the local query and status index.

## Intake classification

Every raw request is classified before it becomes engineering work:

- `execution_ready` — can proceed with a tiered task spec
- `needs_product_decision` — stakeholder boundary not settled
- `needs_technical_discovery` — engineering must investigate before scope is fixed
- `needs_scope_split` — one ticket hides multiple deliverables
- `blocked_by_design` / `blocked_by_access` / `blocked_by_data`
- `defer` / `reject`

## Developer-ready boundary

Work moves to `ready` only when it includes objective, scope, non-goals (standard/full), likely files, layer implications, QA, DoD, open assumptions, owner/role, and status.

## Stakeholder boundary

> Stakeholder intent is clear, but implementation authority is not yet established. Engineering can proceed only after the acceptance boundary is confirmed.

## Authority order

1. Human decisions and signed-off specs
2. Code evidence (CODEMAP, STITCH, repo files)
3. Indexed handoffs and plans
4. Generated summaries (never promoted silently to truth)
