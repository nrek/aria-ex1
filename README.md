<p align="left">
  <img src="aria-icon-rounded.png" width="120" alt="aria-ex1">
</p>

# aria-ex1 — Execution-First

**aria-ex1** is a [Claude Code](https://docs.anthropic.com/en/docs/claude-code) plugin oriented toward **structured execution**: per-repository maps, optional cross-repo stitching, tiered task specs, and edit-time change discipline.

This project **began as a fork** of the open-source [**aria-knowledge**](https://github.com/mikeprasad/aria-knowledge) plugin, which provides a broad **knowledge lifecycle** (capture, review, promotion, audits, intake, and related skills). That design suits teams who want durable session memory and staged knowledge workflows. **aria-ex1** is a **narrower variant**: it keeps codemap-style mapping, cross-repo linking, distillable task specs, and the same class of edit hooks, but **does not ship** the knowledge-capture commands, backlogs, audit cadences, or compaction-adjacent flows. Choosing between them is a **product fit** question, not a judgment on either codebase.

**aria-ex1** offers a compact command set plus hooks that keep changes explicit and maps **per-repo** and **verifiable**.

---

## What aria-ex1 does

| Capability | What you get |
|------------|----------------|
| **Per-repo `CODEMAP.md`** | One map per git repository, with sections matched to the **detected stack** (e.g. Django: URLs, apps, migrations, middleware, Celery, signals; Next.js: routes, hooks, RTK Query, auth hydration). Backend and frontend repos each get an appropriate layout instead of one combined document for dissimilar stacks. |
| **Group `STITCH.md`** | For a **product group** (backend + one or more frontends), a separate file that **stitches** maps together: auth flow, endpoint tables, entities, integrations, and a **drift** section (FE vs BE) when you pair it with your own analysis scripts. |
| **`/distill`** | Turns vague tickets or notes into a **tiered** task spec (`micro` / `standard` / `full`): always includes objective, scope, dependencies/APIs, QA, and definition of done; adds frontend/backend/database sections **only when the work touches those layers**. |
| **Edit-time discipline** | Before every file write: visible impact, alternatives, and scope. After: scope check. Encourages one clear approach instead of speculative refactors. |
| **Explore nudges** | Before heavy **Glob** / **Grep**: reminds you to load the repo `CODEMAP.md` (and `STITCH.md` when it sits next to the map) so exploration stays anchored. |

---

## How it operates

```text
                    ┌─────────────────────────────────────┐
                    │  ~/.claude/aria-ex1.local.md        │
                    │  repo_groups, critical_paths        │
                    └─────────────────────────────────────┘
                                        │
          ┌─────────────────────────────┼─────────────────────────────┐
          ▼                             ▼                             ▼
   /codemap (per repo)           /stitch (per group)            /distill
          │                             │                             │
          ▼                             ▼                             │
   CODEMAP.md                   STITCH.md (tables)                    │
   in repo root                 at stitch_path                       │
          │                             │                             │
          └─────────────────────────────┴─────────────────────────────┘
                                        │
                                        ▼
                              Optional context for /distill
                              (--group loads maps + stitch)

Hooks (plugin.json) run automatically:
  PreToolUse Edit|Write  → change-decision prompt
  PostToolUse Edit|Write → scope verification prompt
  PreToolUse Glob|Grep   → read CODEMAP / STITCH first (once per project per session)
```

**Configuration** is the single source of truth for **which folders belong to which product group**. Skills resolve paths from your workspace; folder names in config are typically **sibling repo directories** (e.g. `my-api`, `my-web`).

**Rules** ship under `plugin/template/rules/` (change-decision framework, working-rules subset). `/rules` looks up by number or keyword — useful when you want the exact wording without loading the whole file.

See [plugin/QUICKSTART.md](plugin/QUICKSTART.md) for a minimal YAML example and command order.

---

## Installation

### Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed and able to load plugins.
- A workspace where backend and frontend (if any) are **separate clones** or folders you can name in config.

### Option A — Local plugin directory

1. Clone or download this repository.
2. Copy or symlink the **`plugin/`** directory into your Claude Code plugins location (exact path depends on your OS and Claude Code version — use **Customize → Plugins** in the app to see or add a local plugin).
3. Restart Claude Code if required.
4. In chat, run **`/setup`** so `~/.claude/aria-ex1.local.md` is created.

### Option B — Marketplace JSON (monorepo / dev)

If you use a `.claude-plugin/marketplace.json` that points at `./plugin`, add this repo as a marketplace source and install **aria-ex1** from the listing.

### After install

1. Edit **`~/.claude/aria-ex1.local.md`** (or complete `/setup`) and define at least one **`repo_groups`** entry: `backend`, `frontends`, `stitch_path`.
2. From **each** repository root, run **`/codemap`** (`create` first time, then `update` / `section` as needed).
3. Run **`/stitch create <group_id>`** to generate **`STITCH.md`** at the path you configured.
4. Use **`/distill`** for tasks; pass **`--group=<group_id>`** when the model should use your maps as context.

---

## Optimal usage and use cases

**Best fit**

- **Split stacks**: Django (or Laravel, etc.) in one repo; React / Next.js / Expo in another — you want maps that respect each codebase’s real layout.
- **API-heavy features**: You benefit from endpoint and entity tables in `STITCH.md` and a drift section aligned with automated FE/BE checks.
- **Underspecified tasks**: `/distill` scales output to complexity (tiered spec) so small edits stay lightweight and larger work still records dependencies, APIs, QA, and done criteria.

**Suggested workflow**

1. **Onboard a group once**: config → codemap each repo → stitch once → commit `CODEMAP.md` / `STITCH.md` to those repos (or your docs repo) so the whole team shares the same anchors.
2. **Keep maps fresh**: After meaningful merges, `/codemap update` or `/codemap section <name>` instead of regenerating everything.
3. **Distill before big edits**: Especially for cross-cutting work, run `/distill … --group=…` and attach the output to the issue or PR so scope is explicit.
4. **Use `critical_paths`**: List path fragments (comma-separated) for subsystems that must always get the **full** pre-edit assessment — see config in [plugin/template/LOCAL.md](plugin/template/LOCAL.md).

**When another tool may fit better**

- **Full knowledge lifecycle** (capture → review → promote, audits, intake, session backlogs): the [**aria-knowledge**](https://github.com/mikeprasad/aria-knowledge) project documents and implements that model end to end.
- **Substitutes for review or tests**: maps and `/distill` **support** execution and clarity; they do not replace human review, CI, or automated tests.

---

## Troubleshooting and managing

### Config and paths

| Symptom | What to check |
|--------|----------------|
| `/stitch` cannot find repos | `backend` / `frontends` in `aria-ex1.local.md` must match **folder names** under the workspace root you opened in Claude Code. Use relative names, not absolute paths, unless you have adapted the skill locally. |
| `STITCH.md` in the wrong place | Set **`stitch_path`** explicitly (often `{backend-folder}/STITCH.md`). |
| Hooks seem to ignore “protected” paths | Under `rules:`, set **`critical_paths`** to comma-separated fragments matching `*/fragment/*` in file paths. Ensure YAML is between `---` frontmatter delimiters. |

### Codemap

| Symptom | What to check |
|--------|----------------|
| Empty or shallow sections | Run **`/codemap inventory`** first to validate detection; confirm framework (Django vs Next.js) is correct before **`create`**. |
| Wrong repo | Run commands from the **repository root** (where `.git` or `CLAUDE.md` lives), or say which root to use. |
| File too large | Use **`/codemap section <name>`** to refresh one block; rely on the Directory table for partial reads. |

### Stitch

| Symptom | What to check |
|--------|----------------|
| Drift section empty or generic | Populate it from **your** FE/BE diff script or manual comparison; the skill describes the contract — automation is workspace-specific. |
| Endpoint rows feel wrong | Regenerate after **both** `CODEMAP.md` files are up to date; verify paths in tables point to real files. |

### Distill

| Symptom | What to check |
|--------|----------------|
| Spec too heavy for a tiny change | Pass **`--tier=micro`** or shorten the input so the heuristic scores low; see [plugin/template/distill/TASK.schema.md](plugin/template/distill/TASK.schema.md). |
| Missing layer sections | By design, Frontend/Backend/Database appear **only** when the task touches that layer. |
| Validation complaints (banned words, empty layers) | Replace terms disallowed in `TASK.schema.md`; remove empty layer headings rather than leaving placeholders. |

### Hooks

| Symptom | What to check |
|--------|----------------|
| Claude Code shows a **“hook error”** label next to tool calls | Known Claude Code UI issue: hooks can exit successfully yet still show the label. If the hook returns JSON with `additionalContext`, behavior is usually correct — treat the label as cosmetic unless tools actually fail. |
| Prompts feel noisy on docs-only edits | Planning-style paths (`*/docs/specs/*`, `*/docs/plans/*`) use **abbreviated** prompts in the bundled scripts; adjust paths in `plugin/bin/pre-edit-check.sh` / `post-edit-check.sh` if your layout differs. |

### Updating the plugin

- Replace the `plugin/` tree with the new release.
- Compare **`plugin/template/rules/`** if you vendor those files into a project — merge carefully.
- Bump version in **`plugin/.claude-plugin/plugin.json`** is the shipped version for releases.

---

## Commands (quick reference)

| Command | Purpose |
|---------|---------|
| `/setup` | Create or refine `~/.claude/aria-ex1.local.md` (repo groups, `critical_paths`) |
| `/codemap` | Create / inventory / update / section — **per-repo** `CODEMAP.md` |
| `/stitch` | Create / verify / diff / section — group **`STITCH.md`** |
| `/distill` | Tiered task spec; optional `--group`, `--tier` |
| `/rules` | Look up execution rules by number or keyword |
| `/help` | Short command list |

---

## Docs and license

- **Plugin README**: [plugin/README.md](plugin/README.md)  
- **Quick start**: [plugin/QUICKSTART.md](plugin/QUICKSTART.md)  
- **Privacy**: [PRIVACY.md](PRIVACY.md)  
- **License**: [CC BY-NC-SA 4.0](LICENSE)
