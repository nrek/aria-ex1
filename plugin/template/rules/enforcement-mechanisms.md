# Enforcement mechanisms (summary)

Ranked soft → hard:

1. **CLAUDE.md** — session-wide expectations.
2. **Hook prompts (PreToolUse / PostToolUse)** — fire at tool boundaries; used for change assessment and scope checks on every edit in aria-ex1.
3. **Required output format + `[Rule 22]` markers** — auditable fields in hook text; the `[Rule 22]` marker is the greppable compliance artifact.
4. **`permissionDecision: deny`** — the PreToolUse hook structurally blocks Edit/Write when the `[Rule 22]` marker is absent from the preceding text in the same assistant turn. Fail-open on detector error.
5. **Permission deny lists** — system-level blocks in Claude Code settings (optional).

The change decision framework in [`change-decision-framework.md`](change-decision-framework.md) is implemented via hooks (2–4). Layer when useful: CLAUDE.md states intent; hooks enforce at action time; required format proves compliance; deny mechanism prevents ordering violations.
