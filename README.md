<p align="left">
  <img src="aria-icon-rounded.png" width="120" alt="aria-ex1">
</p>

# aria-ex1 — Execution-First

A Claude Code plugin forked from [aria-knowledge](https://github.com/mikeprasad/aria-knowledge). It optimizes for **execution**: compartmentalized per-repo `CODEMAP.md`, a workspace-level `STITCH.md` that binds frontend↔backend with verified refs, and `/distill` to turn ambiguous tasks into right-sized specs (micro / standard / full tiers). No knowledge lifecycles, backlogs, or intake pipelines.

## Commands

| Command | Purpose |
|---------|---------|
| `/setup` | Create `~/.claude/aria-ex1.local.md` with repo-group registry |
| `/codemap` | Generate or update **per-repo** `CODEMAP.md` (stack-aware: Django, Next.js, Laravel, Expo, …) |
| `/stitch` | Build or verify group `STITCH.md` (endpoint / entity / drift vs CODEMAPs) |
| `/distill` | Transform raw task text into a tiered task spec (`TASK.schema.md`) |
| `/rules` | Look up working rules by number or keyword |
| `/help` | Command reference |

## Hooks

On every **Edit** / **Write**: impact, alternatives, and scope are asserted before the write; scope is rechecked after. On **Glob** / **Grep**: reminds you to read the repo `CODEMAP.md` Directory (and group `STITCH.md` when applicable) before wide exploration.

## Install

1. Copy the `plugin/` folder into your Claude Code plugins directory, or add this repo as a local marketplace plugin.
2. Run `/setup` to create `aria-ex1.local.md`.
3. Point `repo_groups` at your backend + frontend folder names; run `/codemap` per repo, then `/stitch create <group>`.

## License

[CC BY-NC-SA 4.0](LICENSE)
