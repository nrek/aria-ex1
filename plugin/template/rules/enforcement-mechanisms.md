# Enforcement mechanisms (summary)

Ranked soft → hard:

1. **CLAUDE.md** — session-wide expectations.
2. **Hook prompts (PreToolUse / PostToolUse)** — fire at tool boundaries; used for change assessment and scope checks on every edit in aria-ex1.
3. **Required output format** — auditable fields in hook text.
4. **Permission deny lists** — system-level blocks in Claude Code settings (optional).

The change decision framework in [`change-decision-framework.md`](change-decision-framework.md) is implemented via hooks (2–3), not deny lists.

Layer when useful: CLAUDE.md states intent; hooks enforce at action time; required format proves compliance.
