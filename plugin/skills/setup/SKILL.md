---
description: "Configure aria-ex1. Creates ~/.claude/aria-ex1.local.md with repo_groups registry and optional critical_paths. Trigger: '/setup', 'configure aria-ex1'."
argument-hint: ""
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# /setup — aria-ex1 configuration

## Step 1: Config file

Target: `~/.claude/aria-ex1.local.md`.

- If it **exists**: read it, show `repo_groups` keys and `rules.critical_paths`, offer to merge edits.
- If **missing**: create it from `${CLAUDE_PLUGIN_ROOT}/template/LOCAL.md` structure.

## Step 2: Repo groups

Ask which **product groups** to register (e.g. `myproduct`, `billing-service`). For each group collect:

- `backend` — folder name of the backend repo (sibling in the workspace)
- `frontends` — list of frontend folder names
- `stitch_path` — where to write `STITCH.md` (default: `{backend}/STITCH.md`)

Use **folder names**, not full paths, unless the user insists — paths are resolved from the workspace root where they open Claude Code.

## Step 3: Critical paths (optional)

Ask for comma-separated path fragments for `rules.critical_paths` (matches `*/fragment/*` for protected edits). Default empty.

## Step 4: Write file

Write YAML:

```yaml
---
version: 1
repo_groups:
  <group_id>:
    backend: <folder>
    frontends:
      - <folder>
    stitch_path: <folder>/STITCH.md
rules:
  critical_paths: ""
---
```

## Step 5: CODEMAP stubs (optional)

For each repo mentioned, if the user wants stubs: write a minimal `CODEMAP.md` at that repo root using `${CLAUDE_PLUGIN_ROOT}/template/codemap/CODEMAP.template.md`, replacing `{REPO_NAME}`, `{STACK}` with placeholders. Tell the user to run `/codemap create` to fill.

## Step 6: Done

Confirm path to config. Remind: skills except `/help` expect the config file to exist for group resolution; hooks work with empty `critical_paths`.
