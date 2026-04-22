# Changelog

## 0.1.1 — 2026-04-22

Execution-reliability release. Adapts structural enforcement from aria-knowledge v2.10.5–v2.10.6 for aria-ex1's leaner execution-first context. Adds structural signal surfacing, Rule 22 marker convention, deny mechanism, test infrastructure, and consistency fixes across docs.

### Changed — `pre-edit-check.sh` rewrite with compliance detection

Full rewrite. The hook now parses the transcript for a `[Rule 22]` marker in the text blocks between the previous Edit/Write and the current one. If present: allows silently (zero-noise compliant path). If absent: returns `permissionDecision: deny` with a recovery message naming the expected format and any structural signals detected. Turn-scoped walk-back handles Opus 4.7's split-message architecture (text and tool_use in separate assistant messages). Fail-open on every detector error path: unreadable transcript, malformed JSONL, missing `tool_use_id`, missing `python3`, or python exception all fall through to allow.

### Changed — `post-edit-check.sh` scope markers + prose trim

Scope-check output format updated to `[Rule 22 · Scope] PASS`, `[Rule 22 · Scope] PASS CONDITIONAL`, `[Rule 22 · Scope] FAIL` (planning branch: `[Rule 22 · Scope] OK`). Markers are symmetric with pre-edit compliance blocks and greppable for audit trail. Redundant prose removed.

### Added — `kt_detect_signals()` in `config.sh`

Structural signal detection from file paths. Matches auth, migration, model, routing, and external-service patterns. Surfaced in the pre-edit hook's deny message when signals are detected, so the recovery block is informed by risk context. Zero user configuration required.

### Added — Rule 32 in `working-rules.md`

Halt on direct contradiction with a written directive. If a user request directly contradicts a written rule, skill instruction, or recorded decision, halt before any tool call, name the contradiction verbatim, and ask for explicit override. Motivated by literal-instruction-following behavior in Opus 4.7 where silent resolution of contradictions masked disagreements.

### Added — Rule 18a specific case (producer-consumer ordering)

When a schema, config field, or interface exists primarily to serve a specific consumer, design them together.

### Changed — `change-decision-framework.md` comprehensive update

- Fixed stale reference to `.claude/settings.local.json` (now correctly references plugin hooks)
- Added "Ordering (required)" section: marker must appear ABOVE the Edit/Write tool call
- Added "Rationalizations that do not apply" section: names and rejects 5 invalid arguments for skipping
- Added "Marker Convention" section: documents `[Rule 22]` and `[Rule 22 · Scope]` prefixes
- All format templates and examples prefixed with `[Rule 22]` / `[Rule 22 · Scope]` markers
- Step 6 (Validate Decision) extended with principle-consistency cross-check
- Hook Implementation section rewritten to describe the deny mechanism accurately

### Changed — `enforcement-mechanisms.md` updated

Now documents the `permissionDecision: deny` layer and `[Rule 22]` markers as enforcement surface.

### Fixed — Blueprint docs vs skill behavior mismatch

`LOCAL.md` previously claimed `/codemap` and `/stitch` "may read" blueprint files as seeds. Neither skill actually does this. Updated to accurately describe blueprints as optional reference documents.

### Fixed — Broken image reference in README

Removed `aria-icon-rounded.png` image tag; file did not exist in the repository.

### Added — `tests/` directory with hook regression protection

Test infrastructure for hook contracts. Three fixtures under `tests/fixtures/` capture the 4.7 split-message transcript shape in three scenarios (compliant, non-compliant, second-edit-without-fresh-marker). A repro script at `tests/repros/4-7-split-message.sh` invokes `pre-edit-check.sh` with each fixture and asserts the expected allow/deny outcome. A runner at `tests/run.sh` executes all repros and reports pass/fail.

### Added — `docs/v1.1-upstream-delta-ledger.md`

Structured ledger of every aria-knowledge addition from v2.8.4 through v2.10.6, classified by execution-first value (IMPORT / OPTIONAL / REJECT). Audit trail for what was ported and why.

### Added — `docs/v1.1-non-goals.md`

Explicit list of aria-knowledge features that will not enter aria-ex1, separated into "permanently out of scope" and "deferred to v1.2+".

### Dependencies

- **Requires `python3` on PATH** for the pre-edit compliance scanner. Graceful degradation: if python3 is missing, the hook fails open (allows all edits — compliance enforcement is lost but no edits are blocked).

### Upgrade notes

- **Reinstall required:** copy `plugin/` to your Claude Code plugins path to pick up the hook changes.
- **Template diffs:** `rules/working-rules.md` has new Rule 32 and Rule 18a. `rules/change-decision-framework.md` has new Ordering, Rationalizations, and Marker Convention sections plus updated format examples.
- **Regression protection:** run `sh tests/run.sh` from the repo root to verify hook scanner behavior.
- **First-edit teaching moment:** immediately after reinstall, the first Edit/Write in any session will be denied if Claude hasn't yet emitted a `[Rule 22]` marker. The deny message includes the expected format template; Claude self-recovers within one retry.

### Explicitly deferred to v1.2+

- Batch-manifest mechanism (multi-file plan execution ceremony reduction)
- Stack-aware cross-cutting candidates in `/codemap`
- Model recommendations in `/help`
- `config.sh` sed batching optimization

## 0.1.0 — 2026-04-16

- Fork from aria-knowledge v2.8.4. Execution-First refactor: strip knowledge capture/audit/intake; keep edit-time and explore hooks; add per-repo codemap, group stitch, tiered `/distill`.
