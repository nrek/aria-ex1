# Working Rules (execution subset)

**Last updated:** 2026-04-22

These rules apply across projects. Numbers are stable IDs — do not renumber. For team-specific additions see [`user-rules.md`](user-rules.md).

---

### 1. Scope tasks tightly, but keep the whole system in view

Break work into focused steps; still verify integration impact.

### 2. Let errors guide where you add context

Add CLAUDE.md / rules when mistakes repeat — not preemptively.

### 7. Flag uncertainty — don’t assume

Say so and ask rather than guessing.

### 8. Start from needs, best practices, and context

Understand requirements before solutions.

### 9. Decisions must be logically or empirically justified

Action follows explicit reasoning.

### 12. Minimize dependencies

Weigh value vs maintenance, security, coupling.

### 13. Simplest solution wins unless complexity has clear advantage

Validate simplicity; complexity needs measurable benefit.

### 14. Abstraction has diminishing returns

Each layer needs justification.

### 15. Test at boundaries and edge cases

Not only happy paths.

### 17. Fail gracefully — handle the unhappy path

Explicit errors; no silent failures.

### 20. Always validate before assuming completion

At least one verification pass per step.

### 22. Follow the change decision framework

Every material change follows the sequence in [`change-decision-framework.md`](change-decision-framework.md). Hooks reinforce this on edits.

### 25. Check secondary impact on every change

Parents, siblings, dependents — after every edit.

### 26. Declare scope before building from references

Say what changes vs what is preserved before large rewrites.

### 28. Write only as much as needed

Accurate, concise, precise.

### 18a. Specific case: Producer–consumer ordering

When a schema, config field, or interface exists primarily to serve a specific consumer, design them together. Don't ship the schema alone against a speculative consumer (creates two migrations when the real consumer lands) or a consumer against a placeholder schema (creates fragile coupling).

### 30. Signal context pressure

Say when the window is full; do not silently skip process steps.

### 32. Halt on direct contradiction with a written directive

If a user request directly contradicts a written directive (rule in `working-rules.md`, instruction in the currently-invoked skill's prompt, or recorded decision), halt before any tool call, name the contradiction verbatim, and ask for explicit override. Trigger is literal textual contradiction only — perceived expectations and inferred intent don't trigger (handled by Rule 7); scope-creep concerns remain governed by Rule 22.

---

## Related

- [`change-decision-framework.md`](change-decision-framework.md)
- [`enforcement-mechanisms.md`](enforcement-mechanisms.md)
