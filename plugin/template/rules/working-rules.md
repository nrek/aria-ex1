# Working Rules (execution subset)

**Last updated:** 2026-04-16

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

### 30. Signal context pressure

Say when the window is full; do not silently skip process steps.

---

## Related

- [`change-decision-framework.md`](change-decision-framework.md)
- [`enforcement-mechanisms.md`](enforcement-mechanisms.md)
