# TASK.schema — `/distill` output contract

Referenced by: `plugin/skills/distill/SKILL.md`

## Tiering

Auto-tier via complexity heuristic, or explicit `--tier=micro|standard|full`. See `/distill` SKILL.md Step 0.

## Section presence tags

- **`[R]`** — required whenever that tier emits output.
- **`[L]`** — include only if the task actually touches that layer (Frontend / Backend / Database). Omit entirely if not touched; never emit an empty heading.
- **`[O]`** — optional; include when non-empty (`standard` and `full` tiers).
- **`[F]`** — full tier only.

## Sections

| # | Section | Tag | Notes |
|---|---------|-----|-------|
| 1 | Objective | `[R]` | One sentence — what outcome this ticket achieves. |
| 2 | Scope | `[R]` | Bullets: files, modules, features touched. |
| 3 | Non-Goals | `[F]` | Explicit exclusions to prevent scope creep. |
| 4 | Assumptions | `[O]` | Blocking unknowns; if any is wrong, the spec falls apart. |
| 5 | Dependencies & API Requirements | `[R]` | Internal/external deps, APIs consumed, auth touched. Use `None` explicitly if none. |
| 6 | Frontend | `[L]` | Routes, hooks, state, component changes. |
| 7 | Backend | `[L]` | URLs, views, serializers, async jobs. |
| 8 | Database | `[L]` | Migrations, fields, backfills, indexes. Kept separate from Backend because DDL has distinct review risk. |
| 9 | Edge Cases | `[O]` | Things that could break; verify against them. |
| 10 | QA / Validation | `[R]` | How the ticket is verified: manual steps, tests to run, expected results. |
| 11 | Definition of Done | `[R]` | Checklist: merge criteria, deploy requirements, sign-offs. |

## Advisory vocabulary

Watered-down phrasing that typically signals incomplete thinking. Prefer concrete alternatives. Flagged by `/distill` Step 3 as soft warnings, not hard rejections.

| Phrase | Why avoid | Prefer |
|---|---|---|
| `flexible`, `extensible`, `scalable framework` | Too abstract; does not specify axis of extension. | Name the axis, such as "accepts additional payment providers via the adapter interface." |
| `we could also`, `alternatively`, `one option` | Hedges instead of deciding. | Pick the option; mention rejected alternatives in Non-Goals or Assumptions if they matter. |
| `potentially`, `might want to` | Defers commitment. | Commit for `full` tier or explicitly defer by moving the uncertainty to Assumptions as blocking. |

## Validation rules

- No empty `[L]` sections — omit entirely.
- At most one implementation approach per layer section — match Rule 22's Execute discipline.
- With `--group`, every file path cited in Scope / Frontend / Backend / Database sections must appear in the loaded CODEMAP or STITCH content.
- If the model invents a path not present in loaded context, move the uncertainty to **Assumptions** as blocking or remove the citation entirely.

## Output

Written to `TASK.md` in CWD by default. See `/distill` SKILL.md Step 4 for overwrite semantics, flag overrides, and archive behavior.
