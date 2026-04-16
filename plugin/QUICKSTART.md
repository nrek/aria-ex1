# Quick start — aria-ex1

## 1. Configure

Run `/setup`. It should produce `~/.claude/aria-ex1.local.md` like:

```yaml
---
version: 1
repo_groups:
  myproduct:
    backend: my-backend-repo-folder
    frontends: [my-frontend-repo-folder]
    stitch_path: my-backend-repo-folder/STITCH.md
rules:
  critical_paths: ""
---
```

Adjust folder names to match directories **next to each other** on disk (typical multi-repo workspace).

## 2. Codemap each repo

From each repository root (where `CLAUDE.md` or `.git` lives):

- `/codemap create` — full pass; confirm detection, then fill sections.
- `/codemap inventory` — read-only scan, no file written.
- `/codemap update` — refresh changed sections.
- `/codemap section <name>` — rebuild one section.

## 3. Stitch the group

After each repo has `CODEMAP.md`:

- `/stitch create myproduct` — writes `STITCH.md` at `stitch_path`.
- `/stitch verify myproduct` — checks table rows still resolve.
- `/stitch diff myproduct` — drift log only.

## 4. Distill a task

- `/distill "Fix typo in login button"` — micro tier.
- `/distill "Add Stripe webhook handler" --group=myproduct` — uses CODEMAP + STITCH as context.

## 5. Hooks

Edits trigger pre/post assessment prompts. Exploration (Glob/Grep) nudges you toward `CODEMAP.md` first.
