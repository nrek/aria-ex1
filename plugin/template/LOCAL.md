# aria-ex1 local configuration

Copy this structure to `~/.claude/aria-ex1.local.md` (or run `/setup`).

```yaml
---
version: 1
repo_groups:
  example_group:
    backend: backend-repo-folder-name
    frontends:
      - frontend-repo-folder-name
    stitch_path: backend-repo-folder-name/STITCH.md
rules:
  critical_paths: ""
---
```

## Fields

- **repo_groups** — keys are group ids used with `/stitch create <group>`. Each group lists `backend` and `frontends` as **folder names** relative to your workspace root (sibling repos). **stitch_path** is where `STITCH.md` is written (usually under the backend repo).
- **rules.critical_paths** — comma-separated path fragments; any edit whose path matches `*/<fragment>/*` is treated as protected (full change assessment).

Optional: add a `.md/blueprints/<group>.md` in your workspace as a reference document for your product group architecture. Skills do not auto-read it, but you can reference it in prompts when running `/codemap` or `/stitch`.
