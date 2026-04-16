# TASK.schema — `/distill` output contract

Reference: `${CLAUDE_PLUGIN_ROOT}/template/distill/TASK.schema.md`

## Tiering

Auto-tier via complexity heuristic, or `--tier=micro|standard|full`. See `plugin/skills/distill/SKILL.md`.

## Section presence

- `[R]` required whenever that tier emits output
- `[L]` include only if the task touches that layer (Frontend / Backend / Database)
- `[O]` optional when non-empty (`standard`+)
- `[F]` full tier only

| # | Section | Tag | Notes |
|---|---------|-----|-------|
| 1 | Objective | `[R]` | One sentence |
| 2 | Scope | `[R]` | Bullets: files, modules, features |
| 3 | Non-Goals | `[F]` | Exclusions |
| 4 | Assumptions | `[O]` | Blocking unknowns |
| 5 | Dependencies & API Requirements | `[R]` | Internal/external deps, APIs consumed, auth touched — use `None` explicitly if none |
| 6 | Frontend | `[L]` | Routes, hooks, state |
| 7 | Backend | `[L]` | URLs, views, serializers, jobs |
| 8 | Database | `[L]` | Migrations, fields, backfills |
| 9 | Edge Cases | `[O]` | |
| 10 | QA / Validation | `[R]` | How to verify |
| 11 | Definition of Done | `[R]` | Checklist |

## Banned vocabulary (reject / rewrite)

`flexible`, `extensible`, `scalable framework`, `we could also`, `alternatively`, `one option`, `potentially`, `might want to`

## Validation

- No empty `[L]` sections — omit entirely
- At most one solution path per layer section
- With `--group`, file paths must exist in loaded CODEMAP/STITCH context
