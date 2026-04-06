# Knowledge Retrieval & Resurfacing — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a tag-based retrieval layer to ARIA so promoted knowledge is findable, loadable on demand, and actively maintained — not passive files on disk.

**Architecture:** Two new skills (`/index`, `/context`), extensions to `/audit-knowledge`, a session-start hook addition, and abbreviated Rule 22 hook support for planning paths. Skills are prompt-based (SKILL.md files). Hook changes include a session-start addition and two new bash scripts replacing the inline echo commands for pre/post-edit checks (enabling planning path detection).

**Tech Stack:** Markdown (SKILL.md skill definitions), Bash (hook script), YAML frontmatter conventions.

**Spec:** `aria/docs/specs/2026-04-06-knowledge-retrieval-design.md`

---

## File Map

### New files
| File | Responsibility |
|------|---------------|
| `plugin/skills/index/SKILL.md` | `/index` skill — scan, normalize tags, update project mappings, detect staleness, suggest cross-references, rebuild `index.md` |
| `plugin/skills/context/SKILL.md` | `/context` skill — query tag index, present matches, load selected files |
| `plugin/bin/pre-edit-check.sh` | PreToolUse hook — detects planning paths, outputs abbreviated or full Rule 22 prompt |
| `plugin/bin/post-edit-check.sh` | PostToolUse hook — detects planning paths, outputs abbreviated or full scope check prompt |

### Modified files
| File | What changes |
|------|-------------|
| `plugin/skills/audit-knowledge/SKILL.md` | Add cross-referencing pass (Step 5c), index rebuild call (Step 7b), staleness action items (Step 6 additions) |
| `plugin/bin/session-start-check.sh` | Add knowledge surfacing instruction to system message output |
| `plugin/template/README.md` | Add `index.md` to folder structure diagram and taxonomy table |
| `plugin/template/LOCAL.md` | Add `tags:` to format templates, document `/context` and `/index` in "When to Read" |
| `plugin/.claude-plugin/plugin.json` | Register new skills in description, update hook prompts for planning path abbreviation, bump version |
| `plugin/skills/setup/SKILL.md` | Add new config keys (`freeform_promotion_threshold`, `staleness_threshold_months`) to Step 6 and Step 7 |
| `plugin/bin/config.sh` | Parse new config keys from frontmatter |

---

### Task 1: Add new config keys to `config.sh`

**Files:**
- Modify: `plugin/bin/config.sh:18-50`

The new features need two config values read by skills: `freeform_promotion_threshold` and `staleness_threshold_months`. Skills read config via `~/.claude/aria-knowledge.local.md` directly (they're prompt-based, they just Read the file). But `config.sh` should also parse them so the hook scripts have access if needed in the future, and to keep config parsing centralized.

- [ ] **Step 1: Add parsing for new config keys**

In `plugin/bin/config.sh`, after the existing `KT_EXPLANATORY` parsing line (line 22), add parsing for the two new keys:

```bash
  KT_FREEFORM_THRESHOLD=$(sed -n '/^---$/,/^---$/p' "$KT_CONFIG" | grep '^freeform_promotion_threshold:' | sed 's/^freeform_promotion_threshold: *//')
  KT_STALENESS_MONTHS=$(sed -n '/^---$/,/^---$/p' "$KT_CONFIG" | grep '^staleness_threshold_months:' | sed 's/^staleness_threshold_months: *//')
```

After the existing defaults block (around line 27), add defaults:

```bash
  KT_FREEFORM_THRESHOLD=${KT_FREEFORM_THRESHOLD:-3}
  KT_STALENESS_MONTHS=${KT_STALENESS_MONTHS:-6}
```

After the existing numeric validation block (around line 44), add validation:

```bash
  case "$KT_FREEFORM_THRESHOLD" in
    ''|*[!0-9]*) KT_FREEFORM_THRESHOLD=3 ;;
  esac
  case "$KT_STALENESS_MONTHS" in
    ''|*[!0-9]*) KT_STALENESS_MONTHS=6 ;;
  esac
```

- [ ] **Step 2: Verify config.sh still parses correctly**

Run:
```bash
bash -n /Users/mikeprasad/Projects/aria/plugin/bin/config.sh
```
Expected: no output (syntax OK).

- [ ] **Step 3: Commit**

```bash
git add plugin/bin/config.sh
git commit -m "feat: parse freeform_promotion_threshold and staleness_threshold_months in config.sh"
```

---

### Task 2: Update `/setup` skill to offer new config keys

**Files:**
- Modify: `plugin/skills/setup/SKILL.md:86-109`

- [ ] **Step 1: Add new config keys to Step 6 (Cadence Configuration)**

In `plugin/skills/setup/SKILL.md`, find the Step 6 section. After the existing cadence configuration prompt, add:

```markdown
### Advanced Options

If the user asks about advanced options or re-runs setup with existing config, also offer:

> "Advanced settings (defaults are fine for most users):
> - **Freeform tag promotion threshold:** 3 (suggest promoting a freeform tag to known after it appears on this many files)
> - **Staleness threshold:** 6 months (flag knowledge files not updated within this period)
>
> Want to change either? (Enter new values or press enter to keep defaults)"

Record the values. If the user doesn't ask about advanced options during initial setup, use the defaults silently.
```

- [ ] **Step 2: Add new keys to Step 7 (Write Config)**

In the Step 7 config template, add the two new keys after `explanatory_plugin`:

```yaml
---
knowledge_folder: [path from Step 2]
audit_cadence_knowledge: [value from Step 6]
audit_cadence_config: [value from Step 6]
explanatory_plugin: [true/false from Step 5]
freeform_promotion_threshold: [value from Step 6, default 3]
staleness_threshold_months: [value from Step 6, default 6]
---
```

- [ ] **Step 3: Add new keys to Step 7b (Verify Config Round-Trip)**

In the verification checks list, add:

```markdown
   - `freeform_promotion_threshold` — confirm it's the integer from Step 6
   - `staleness_threshold_months` — confirm it's the integer from Step 6
```

- [ ] **Step 4: Commit**

```bash
git add plugin/skills/setup/SKILL.md
git commit -m "feat: add freeform_promotion_threshold and staleness_threshold_months to /setup"
```

---

### Task 3: Update template `LOCAL.md` with tag convention

**Files:**
- Modify: `plugin/template/LOCAL.md`

- [ ] **Step 1: Add `tags:` to all format templates**

In `plugin/template/LOCAL.md`, update each format template to include `tags:` in the frontmatter. Find the Approaches template (around line 30) and change:

```markdown
### Approaches (`approaches/`)

\`\`\`markdown
# [Approach Name]

**Last updated:** YYYY-MM-DD
```

to:

```markdown
### Approaches (`approaches/`)

\`\`\`markdown
---
Last updated: YYYY-MM-DD
tags: [tag1, tag2, tag3]
---

# [Approach Name]
```

Apply the same pattern to the Decisions template (add `tags:` after `Date:` in the frontmatter) and the Guides template (add frontmatter with `Last updated` and `tags`).

For Decisions, the frontmatter becomes:
```markdown
---
Status: Accepted | Superseded | Deprecated
Date: YYYY-MM-DD
tags: [tag1, tag2]
---

# [Number] — [Title]
```

For Guides:
```markdown
---
Last updated: YYYY-MM-DD
tags: [tag1, tag2]
---

# [Guide Title]
```

- [ ] **Step 2: Add `/context` and `/index` to "When to Read" table**

Find the "When to Read" table (around line 115) and add rows:

```markdown
| Working in a specific domain (API, CSS, Stripe, etc.) | Run `/context <topic>` to load relevant knowledge |
| After promoting knowledge or adding new files | Run `/index` to rebuild the tag index |
| Checking what knowledge exists for a topic | Run `/context <topic>` to see matches |
```

- [ ] **Step 3: Add tag convention documentation**

After the "Adding New Knowledge" section (around line 128), add a new section:

```markdown
## Tag Convention

Every promoted knowledge file should include a `tags:` field in its YAML frontmatter:

\`\`\`yaml
---
Last updated: YYYY-MM-DD
tags: [api, pagination, django]
---
\`\`\`

**Known tags** are maintained in `index.md` under `## Known Tags`. The initial set includes:

| Group | Tags |
|-------|------|
| Tech domain | `api`, `css`, `database`, `deployment`, `django`, `react`, `nextjs`, `react-native`, `tailwind`, `testing`, `infrastructure` |
| Cross-cutting | `architecture`, `performance`, `security`, `accessibility` |
| Tool/service | `stripe`, `linear`, `supabase`, `figma`, `claude-code` |
| Process | `process`, `decision-framework`, `enforcement` |
| Project | `cs`, `ss`, `df`, `aria` |

**Freeform tags** are valid — any tag works. Freeform tags that appear on 3+ files get suggested for promotion to the known set during `/index`. Similar tags (e.g., `api` vs `apis`) get flagged for normalization.
```

- [ ] **Step 4: Commit**

```bash
git add plugin/template/LOCAL.md
git commit -m "feat: add tag convention and /context /index references to LOCAL.md template"
```

---

### Task 4: Update template `README.md` with `index.md`

**Files:**
- Modify: `plugin/template/README.md`

- [ ] **Step 1: Add `index.md` to structure diagram**

In `plugin/template/README.md`, find the structure diagram (around line 10). Add `index.md` after `LOCAL.md`:

```
knowledge/
├── README.md
├── LOCAL.md                 # Project-specific guide (not managed by plugin)
├── index.md                 # Tag-based knowledge index (generated by /index)
├── intake/                  # Unprocessed input — backlogs and staging
```

- [ ] **Step 2: Add to Conventions section**

Find the Conventions section (around line 73). Add after the "Don't delete — archive" bullet:

```markdown
- **Tag your files:** Include `tags: [tag1, tag2]` in YAML frontmatter for all promoted files. See `LOCAL.md` for the tag convention.
- **`index.md` is generated:** Rebuilt by `/index` and `/audit-knowledge`. Never hand-edit it.
```

- [ ] **Step 3: Commit**

```bash
git add plugin/template/README.md
git commit -m "feat: add index.md to README.md template structure and conventions"
```

---

### Task 5: Create `/index` skill

**Files:**
- Create: `plugin/skills/index/SKILL.md`

This is the largest single task — the `/index` skill handles scanning, normalization, staleness detection, cross-reference suggestions, project mappings, and index generation.

- [ ] **Step 1: Create the skill directory**

```bash
mkdir -p /Users/mikeprasad/Projects/aria/plugin/skills/index
```

- [ ] **Step 2: Write the `/index` SKILL.md**

Create `plugin/skills/index/SKILL.md` with the following content:

```markdown
---
description: "Rebuild the knowledge tag index. Scans promoted files, normalizes tags, flags untagged files, suggests freeform-to-known promotions, detects stale files, suggests cross-references, updates project-to-tag mappings, and regenerates index.md. Use when user says '/index', 'rebuild index', 'update index', 'reindex knowledge'. Also called automatically by /audit-knowledge."
argument-hint: ""
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# /index — Knowledge Index Builder

Scan all promoted knowledge files, normalize tags, detect issues, and regenerate `{knowledge_folder}/index.md`.

## Step 0: Resolve Config

Read `~/.claude/aria-knowledge.local.md` and extract:
- `knowledge_folder` — base path for all operations
- `freeform_promotion_threshold` — minimum file count before suggesting promotion (default: 3)
- `staleness_threshold_months` — months before a file is flagged stale (default: 6)

If the config file doesn't exist, stop: "aria-knowledge is not configured. Run /setup to get started."

## Step 1: Scan Promoted Folders

Scan these directories for `.md` files (excluding directory README stubs that only contain a few lines of boilerplate):
- `{knowledge_folder}/approaches/`
- `{knowledge_folder}/decisions/`
- `{knowledge_folder}/guides/` (recursive — includes subdirectories)
- `{knowledge_folder}/references/`

**Do NOT scan:** `archive/`, `intake/`, `rules/`, `logs/`, or root-level files (`README.md`, `LOCAL.md`, `OVERVIEW.md`, `index.md`).

For each `.md` file found:
1. Read the file
2. Extract YAML frontmatter (content between `---` markers at the top of the file)
3. From frontmatter, extract:
   - `tags:` — array of tags (e.g., `tags: [api, pagination, django]`). If missing, record as untagged.
   - `Last updated:` or `Last updated:` — date string (YYYY-MM-DD). If missing, record as unknown.
4. Extract the first `#` heading as the file's description
5. Store: `{path, tags[], description, last_updated}`

Report: "Scanned N files in approaches/, decisions/, guides/, references/."

## Step 2: Read Existing Index

Read `{knowledge_folder}/index.md` if it exists.

Extract:
- `## Known Tags` section — the current canonical tag vocabulary (comma-separated list)
- `## Projects` section — current project-to-tag mappings

If `index.md` doesn't exist (first run), use the seeded known tags:

```
api, architecture, css, database, deployment, django, react, nextjs, react-native, tailwind, testing, infrastructure, performance, security, accessibility, stripe, linear, supabase, figma, claude-code, process, decision-framework, enforcement, cs, ss, df, aria
```

And leave the Projects section empty (will be populated in Step 6).

## Step 3: Tag Normalization

Compare all tags found across scanned files. Detect similar tags using these heuristics:
- **Plural/singular:** `api` vs `apis`, `test` vs `tests`
- **Hyphen variants:** `react-native` vs `reactnative` vs `react native`
- **Common abbreviations:** `db` vs `database`, `infra` vs `infrastructure`

For each pair of similar tags, check which one is in the Known Tags set. If one is known and the other isn't, the known one is the normalization target.

If both are unknown, prefer the more common one (appears on more files).

**Present conflicts to user:**

```
## Tag Normalization

Found similar tags:
1. `apis` (1 file) → normalize to `api` (4 files)? [y/n]
2. `reactnative` (1 file) → normalize to `react-native` (2 files)? [y/n]
```

For each approved normalization:
- Edit the source file's YAML frontmatter to replace the old tag with the normalized tag
- Record the change for the summary

If no similar tags found, skip this step silently.

## Step 4: Freeform-to-Known Tag Promotion

Identify tags that are NOT in the Known Tags set but appear on `{freeform_promotion_threshold}` or more files (default: 3).

**Present suggestions:**

```
## Freeform Tag Promotion

These freeform tags appear frequently:
1. `webhooks` — 4 files. Promote to known tags? [y/n]
2. `authentication` — 3 files. Promote to known tags? [y/n]
```

For each approved promotion:
- Add the tag to the Known Tags set (will be written to index.md in Step 8)
- Record for summary

If no tags qualify, skip this step silently.

## Step 5: Untagged File Resolution

For each file with no `tags:` in its frontmatter:

**Present list and offer to fix:**

```
## Untagged Files

Found N files without tags:
1. guides/claude/environment-architecture.md — "Environment Architecture"
   Suggested tags: [claude-code, architecture, infrastructure]
2. approaches/combo-class-pattern.md — "Combo Class Pattern"
   Suggested tags: [css, tailwind, df]

Add suggested tags? (all / numbers / skip)
```

For each file the user approves:
- Read the file
- If the file has existing YAML frontmatter (between `---` markers), add `tags: [tag1, tag2]` as a new line inside it
- If the file has no frontmatter, add a frontmatter block at the top:
  ```
  ---
  Last updated: YYYY-MM-DD
  tags: [tag1, tag2]
  ---
  ```
  (Use the file's existing `Last updated` date if found in the body, or today's date if none exists)
- Record the change for the summary

Tag suggestions are based on:
- Filename keywords (e.g., `api-pagination` → `api`, `pagination`)
- First heading keywords
- Content scan for known tag keywords
- Parent directory (e.g., file in `guides/claude/` → suggest `claude-code`)

## Step 6: Project-to-Tag Mapping Update

Read the root project CLAUDE.md to find the project table. The table is at `/Users/mikeprasad/Projects/CLAUDE.md` (or the closest ancestor directory containing a `CLAUDE.md` with a project table).

For each project listed in the table:
1. Read the project's CLAUDE.md (e.g., `cs/CLAUDE.md`, `ss/CLAUDE.md`)
2. Extract tech stack, tools, frameworks, and services mentioned
3. Match extracted keywords against the Known Tags set (including any newly promoted tags from Step 4)
4. Also check which tags appear on files that mention the project name in their path or content

Build a mapping:
```
cs — Commonspace: api, django, react, react-native, css, tailwind, stripe, supabase, database, deployment
ss — Seersite: api, django, nextjs, stripe, supabase, database, deployment
df — Designframe: css, tailwind, accessibility
aria — ARIA: claude-code, process, decision-framework, enforcement
```

Compare against existing mappings (from Step 2). If any changed:

```
## Project Mapping Updates

- cs: added `supabase` (found in cs/CLAUDE.md tech stack)
- ss: no changes
```

If this is the first run (no existing mappings), present the full initial mapping for confirmation.

## Step 7: Staleness Detection

For each scanned file, compare its `Last updated` date against today's date.

If the file's age exceeds `{staleness_threshold_months}` months (default: 6):
- Add to the stale files list with age and threshold info

This data is used when generating the `## Stale Files` section in Step 8. No user interaction here — just collection.

## Step 8: Cross-Reference Pass

For each pair of promoted files, compute tag overlap:
1. Count shared tags between the two files
2. If overlap >= 2 tags, check each file's `## Related` section for existing cross-references
3. If one or both files don't reference the other, record as a suggestion

Also check for **reverse link gaps**: if file A's `## Related` links to file B, but file B's `## Related` doesn't link to file A.

**Present suggestions:**

```
## Cross-Reference Suggestions

1. approaches/api-pagination.md <-> decisions/003-cursor-vs-offset.md
   Shared tags: api, pagination
   Neither references the other — add cross-links? [y/n]

2. references/stripe-webhook-patterns.md <-> guides/payments/checkout-flow.md
   Shared tags: stripe, cs
   checkout-flow.md links to stripe-webhook-patterns.md but not the reverse — add reverse link? [y/n]
```

For each approved cross-reference:
- If the file has a `## Related` section, append the new link:
  ```markdown
  - [Target File Title](../relative/path/to/target.md)
  ```
- If the file has no `## Related` section, add one at the end of the file:
  ```markdown

  ## Related
  - [Target File Title](../relative/path/to/target.md)
  ```
- Use relative paths from the source file to the target file

If no suggestions, skip this step silently.

## Step 9: Rebuild and Write `index.md`

Generate `{knowledge_folder}/index.md` with this structure:

```markdown
# Knowledge Index

Last rebuilt: YYYY-MM-DD

## Projects

### [project_key] — [project_name]
Relevant tags: tag1, tag2, tag3

(repeat for each project)

## Known Tags

tag1, tag2, tag3, tag4, ...

## Tag Index

### [known_tag]
- relative/path/to/file.md — File description

(repeat for each known tag that has matching files, sorted alphabetically)

## Other Tags

### [freeform_tag]
- relative/path/to/file.md — File description

(repeat for each freeform tag, sorted alphabetically)

## Stale Files

### relative/path/to/file.md
Last updated: YYYY-MM-DD (N months ago) — threshold: M months

(repeat for each stale file. Omit this section entirely if no stale files.)

## Untagged Files

- relative/path/to/file.md — File description (no tags in frontmatter)

(Omit this section entirely if no untagged files remain after Step 5.)
```

**File paths** in the index are relative to the knowledge folder root (e.g., `approaches/api-pagination.md`, not the absolute path).

**Tag Index entries** are sorted: known tags alphabetically, then other tags alphabetically. Within each tag, files are sorted alphabetically by path.

**A file appears under every tag it carries.** If `api-pagination.md` has `tags: [api, pagination, django]`, it appears under all three tag headings.

## Step 10: Report Summary

```
Index rebuilt successfully.

Files: N scanned, M tagged, K untagged
Tags: L unique (J known, F freeform)
Normalizations: P applied
Promotions: Q tags promoted to known
Stale files: S (threshold: T months)
Cross-references: R suggested, X added
Project mappings: updated/unchanged
```

## Rules

- **Never modify files outside the knowledge folder** except for the root CLAUDE.md read (read-only) in Step 6
- **Always present changes before making them** — normalizations, promotions, untagged fixes, and cross-references all require user approval
- **Preserve existing frontmatter** — when adding tags to a file, don't remove or modify other frontmatter fields
- **Relative paths in index** — all paths in index.md are relative to the knowledge folder root
- **Skip empty directories** — if approaches/ has no .md files, don't create an empty tag section
- **Directory README stubs are not knowledge files** — skip files that are only 1-5 lines of boilerplate (the README.md stubs in approaches/, decisions/, etc.)
```

- [ ] **Step 3: Commit**

```bash
git add plugin/skills/index/SKILL.md
git commit -m "feat: create /index skill for knowledge tag index management"
```

---

### Task 6: Create `/context` skill

**Files:**
- Create: `plugin/skills/context/SKILL.md`

- [ ] **Step 1: Create the skill directory**

```bash
mkdir -p /Users/mikeprasad/Projects/aria/plugin/skills/context
```

- [ ] **Step 2: Write the `/context` SKILL.md**

Create `plugin/skills/context/SKILL.md` with the following content:

```markdown
---
description: "Load relevant knowledge by topic. Queries the tag index and presents matching promoted files for selective loading into context. Use when user says '/context stripe', '/context api pagination', '/context ss', 'load knowledge about...', 'what do we know about...'."
argument-hint: "<tag1> [tag2] [AND tag3]"
allowed-tools: Read, Glob, Grep
---

# /context — On-Demand Knowledge Retrieval

Query the knowledge tag index and load relevant promoted files into the conversation context.

## Step 0: Resolve Config

Read `~/.claude/aria-knowledge.local.md` and extract `knowledge_folder`.

If the config file doesn't exist, stop: "aria-knowledge is not configured. Run /setup to get started."

## Step 1: Read Index

Read `{knowledge_folder}/index.md`.

If the file doesn't exist, stop: "No knowledge index found. Run `/index` to build it."

Parse the index to extract:
- `## Projects` section — project name/key and their relevant tags
- `## Known Tags` section — the canonical tag list
- `## Tag Index` section — tag → file mappings for known tags
- `## Other Tags` section — tag → file mappings for freeform tags

## Step 2: Parse Query

The user's argument is a space-separated list of tags with optional `AND` keyword.

**Parsing rules:**
- Split on spaces
- If the token `AND` (case-insensitive) appears, use **intersection mode** — a file must have ALL specified tags
- Otherwise, use **union mode** (default) — a file matches if it has ANY of the specified tags
- Remove `AND` tokens from the tag list

Examples:
- `/context stripe` → tags: [`stripe`], mode: OR
- `/context api pagination` → tags: [`api`, `pagination`], mode: OR
- `/context api AND pagination` → tags: [`api`, `pagination`], mode: AND
- `/context ss` → tags: [`ss`], mode: OR (with project expansion)

If no argument provided, stop: "Usage: `/context <tag1> [tag2] [AND tag3]`. Run `/index` to see available tags."

## Step 3: Project Tag Expansion

For each tag in the query, check if it matches a project key in the `## Projects` section (e.g., `ss`, `cs`, `df`, `aria`).

If a tag matches a project:
1. Keep the project tag itself in the search
2. Also add all of that project's "Relevant tags" to the search
3. Notify the user:
   ```
   Expanded `ss` to include: api, django, nextjs, stripe, supabase, database, deployment
   ```

Project expansion only applies in union (OR) mode. In AND mode, project tags are treated as literal tags (a file must be tagged `ss` specifically).

## Step 4: Match Files

Scan the `## Tag Index` and `## Other Tags` sections for entries matching the query tags.

**Union mode (OR):** Collect all files that appear under any of the query tags. Deduplicate — each file appears once even if it matches multiple tags.

**Intersection mode (AND):** Collect files that appear under ALL of the query tags. A file must be listed under every specified tag.

For each matching file, collect:
- File path (relative to knowledge folder)
- Description (from the index entry)
- All tags the file carries (scan all tag sections for this file path)

## Step 5: Present Summary

If matches found:

```
Found N files matching: [tags] ([OR|AND])

1. approaches/api-pagination.md — Cursor-based pagination patterns [api, pagination, stripe]
2. decisions/003-cursor-vs-offset.md — Why we chose cursor pagination [api, stripe]
3. references/stripe-webhook-patterns.md — Webhook signature verification [stripe, webhooks]

Load which files? (all / numbers / none)
```

Show the file's tags in brackets after the description so the user can see why each file matched.

**If no matches:**

```
No files match tag(s): [tags]

Known tags: api, architecture, css, database, ...
Run `/index` to rebuild if you've recently added files.
```

## Step 6: Load Selected Files

Based on user response:
- **"all"** — read and present the full content of every matched file
- **Numbers (e.g., "1 3" or "1,3")** — read and present only the specified files
- **"none"** — stop, don't load anything

For each selected file:
1. Read `{knowledge_folder}/{file_path}`
2. Present the full file content

After loading, confirm: "Loaded N knowledge files into context."

## Rules

- **Read-only** — this skill never modifies any files
- **Index-only** — queries the index, not the files themselves (until loading)
- **Promoted files only** — does not search backlogs, intake, rules, or logs
- **No full-text search** — tag-based matching only. If the user needs content search, suggest using Grep directly
- **Present before loading** — always show the summary and let the user choose which files to load
```

- [ ] **Step 3: Commit**

```bash
git add plugin/skills/context/SKILL.md
git commit -m "feat: create /context skill for on-demand knowledge retrieval"
```

---

### Task 7: Extend `/audit-knowledge` with cross-referencing and index rebuild

**Files:**
- Modify: `plugin/skills/audit-knowledge/SKILL.md`

This task adds three things: a cross-reference pass against promoted docs (new Step 5c), staleness action items in Step 6, and an index rebuild call after promotions (new Step 7b).

- [ ] **Step 1: Add Step 5c — Cross-Reference Backlog Against Promoted Docs**

In `plugin/skills/audit-knowledge/SKILL.md`, after Step 5b (Lint Knowledge Integrity, around line 107), add a new section:

```markdown
## Step 5c: Cross-Reference Backlog Against Promoted Docs

For each pending backlog entry (from Steps 2, 2b, 2c), check whether it overlaps with existing promoted knowledge files.

**How to match:**
1. If `{knowledge_folder}/index.md` exists, read it and use the tag index for matching. Extract keywords from the backlog entry and check if any match tags in the index.
2. If no index exists, fall back to keyword matching: scan headings and first paragraphs of files in `approaches/`, `decisions/`, `guides/`, `references/` for overlapping terms.

**Two types of overlap to detect:**

**Topic overlap** — the backlog entry covers a topic that already has a promoted doc:
- A backlog insight about pagination when `approaches/api-pagination.md` exists
- Flag: "This insight may relate to existing doc `approaches/api-pagination.md` — update existing rather than create new?"

**Potential invalidation** — the backlog entry describes a change that may affect existing promoted docs:
- A clipping about a new Stripe API version when `references/stripe-webhook-patterns.md` exists
- A decision that reverses or modifies an existing approach
- Flag: "New entry about [topic] — existing `[file]` may need review or update."

Note all cross-references for presentation in Step 6. These inform the user's promotion decisions — they're not blockers.
```

- [ ] **Step 2: Add staleness findings to Step 6**

In the Step 6 (Present Findings) section, after the "Emerging Themes" subsection (around line 193), add:

```markdown
### Stale Knowledge

If `{knowledge_folder}/index.md` exists, read its `## Stale Files` section. If it has entries, present them as action items:

```
## Stale Knowledge
- N files past review threshold:
  - [file path] ([age] months, threshold: [threshold] months)

For each: review and update `Last updated` date? Update content? Archive if no longer relevant?
```

If no index exists, skip this section with a note: "Run `/index` to enable staleness detection."

### Cross-Reference Findings (from Step 5c)

For each cross-reference found:
- **Type:** topic overlap | potential invalidation
- **Backlog entry:** which entry triggered the match
- **Existing file:** which promoted doc it overlaps with
- **Recommendation:** update existing, create new alongside, or review existing for staleness
```

- [ ] **Step 3: Add Step 7b — Index Rebuild**

After Step 7 (Wait for User Review) and before Step 8 (Update the Audit Log), add:

```markdown
## Step 7b: Rebuild Knowledge Index

After all approved promotions and edits are complete, rebuild the knowledge index to capture the current state.

Run the full `/index` logic:
1. Scan all promoted folders for files and tags
2. Normalize tags (present conflicts for approval)
3. Suggest freeform-to-known tag promotions
4. Flag untagged files and offer to add tags
5. Update project-to-tag mappings
6. Detect stale files
7. Suggest cross-references between files with 2+ shared tags
8. Write `{knowledge_folder}/index.md`

**Batch the interactive prompts** — present all index health findings together rather than interrupting one at a time:

```
## Index Health
- N similar tags found: [list normalizations]
- N freeform tags eligible for promotion: [list]
- N untagged files: [list]
- N cross-reference suggestions: [list]
- Project mappings: [changes or "unchanged"]

[Approve normalizations? Promote tags? Tag files? Add cross-references?]
```

Apply approved changes, then write the final `index.md`.

If this is the first audit (no index exists yet), note: "Building knowledge index for the first time."
```

- [ ] **Step 4: Renumber Step 8 to Step 8**

The existing "Step 8: Update the Audit Log" keeps its number since 7b is a sub-step. No renumbering needed — just verify the flow reads correctly: Step 7 → Step 7b → Step 8.

- [ ] **Step 5: Commit**

```bash
git add plugin/skills/audit-knowledge/SKILL.md
git commit -m "feat: add cross-referencing, staleness items, and index rebuild to /audit-knowledge"
```

---

### Task 8: Update session-start hook for knowledge surfacing

**Files:**
- Modify: `plugin/bin/session-start-check.sh`

- [ ] **Step 1: Add knowledge surfacing instruction to the system message**

In `plugin/bin/session-start-check.sh`, find the section that builds the `MESSAGES` variable and outputs it (around line 89-93). Before the final output block, add a check for the index file and append the knowledge surfacing instruction:

```bash
# Knowledge surfacing — prompt Claude to suggest /context after user states task
INDEX_FILE="$KT_KNOWLEDGE_FOLDER/index.md"
if [ -f "$INDEX_FILE" ]; then
  MESSAGES="${MESSAGES}KNOWLEDGE CONTEXT — After the user describes their task, check if the knowledge index exists at ${KT_KNOWLEDGE_FOLDER}/index.md. If it does, suggest a /context command with tags relevant to their stated task. Only suggest once per session. Do not block — just offer. Example: 'Before we start — you have knowledge docs that may be relevant. Want me to run /context api pagination?' "
fi
```

This goes after the config audit cadence check block (around line 86) and before the "Output only if there are messages" block (around line 89).

- [ ] **Step 2: Verify syntax**

Run:
```bash
bash -n /Users/mikeprasad/Projects/aria/plugin/bin/session-start-check.sh
```
Expected: no output (syntax OK).

- [ ] **Step 3: Commit**

```bash
git add plugin/bin/session-start-check.sh
git commit -m "feat: add knowledge surfacing instruction to session-start hook"
```

---

### Task 9: Update `plugin.json` — register skills, update hooks, bump version

**Files:**
- Modify: `plugin/.claude-plugin/plugin.json`

- [ ] **Step 1: Update the description to mention new skills**

Change the `description` field to include `/index` and `/context`:

```json
"description": "Knowledge repository management — audit memory/plans, scan configs for drift, extract session knowledge, manage backlogs, look up rules, build tag indexes, and load knowledge by topic. Includes Rule 22 enforcement hooks (with abbreviated mode for planning paths) and session start audit checks. IMPORTANT: All skills except /setup require ~/.claude/aria-knowledge.local.md to exist. If missing when any skill is invoked, stop and tell the user to run /setup."
```

- [ ] **Step 2: Update PreToolUse hook for planning path abbreviation**

Replace the existing PreToolUse hook command with a version that includes planning path detection. The hook command becomes a bash script that checks the file path:

```json
"PreToolUse": [
  {
    "matcher": "Edit|Write",
    "hooks": [
      {
        "type": "command",
        "command": "bash ${CLAUDE_PLUGIN_ROOT}/bin/pre-edit-check.sh",
        "timeout": 5
      }
    ]
  }
]
```

This requires a new script. Create `plugin/bin/pre-edit-check.sh`:

```bash
#!/bin/sh
# pre-edit-check.sh — PreToolUse hook for Edit|Write
# Checks if the file being edited is in a planning path.
# If so, allows abbreviated Rule 22 assessment.
# Otherwise, requires full assessment.

# Read the tool input to get the file path
# The hook receives tool input via stdin as JSON
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | grep -o '"file_path":"[^"]*"' | head -1 | sed 's/"file_path":"//;s/"//')

# Planning paths where abbreviated assessment is permitted
IS_PLANNING=false
case "$FILE_PATH" in
  */docs/specs/*|*/docs/plans/*) IS_PLANNING=true ;;
esac

# Protected filenames that always require full assessment
IS_PROTECTED=false
BASENAME=$(basename "$FILE_PATH" 2>/dev/null)
case "$BASENAME" in
  CLAUDE.md|working-rules.md|change-decision-framework.md|enforcement-mechanisms.md|settings.local.json|plugin.json)
    IS_PROTECTED=true ;;
esac

# Check if file is inside the knowledge folder
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/config.sh"
if [ "$KT_CONFIGURED" = "true" ] && [ -n "$KT_KNOWLEDGE_FOLDER" ]; then
  case "$FILE_PATH" in
    "$KT_KNOWLEDGE_FOLDER"/*) IS_PROTECTED=true ;;
  esac
fi

if [ "$IS_PLANNING" = "true" ] && [ "$IS_PROTECTED" = "false" ]; then
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"PLANNING PATH — abbreviated assessment permitted. Output: Planning edit — [filename]. If this file is NOT a planning/spec document, STOP and use full Rule 22 assessment instead."}}'
else
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"CHANGE DECISION CHECK (Rule 22) — Output this REQUIRED format before proceeding: Assess impact: HIGH (behavior, architecture, key logic, many dependents) or LOW (content, simple functions, docs). --- HIGH IMPACT FORMAT: Line 1: High Impact — [what] ([why high]). Then one line each: Change — [what + context]. Intake — [information gathered]. Criteria — [objective basis]. Solutions — [all options ranked, best first]. Rank — [winner + why]. Validate — [does it hold up? contradictions?]. Execute — [precise scope]. FLAG if Validate or Execute fails and newline with Proposed: or Question: for next step. --- LOW IMPACT FORMAT: Line 1: Low Impact — [what] ([why low]). Then: Change — [what + intake + criteria in one line]. Solutions — [options ranked, best first]. Execute — [decision; scope check, secondary impact check, functional impact]. If Execute flags: add FLAG and newline with Proposed: or Question: for clarification needed. --- If you have not completed this assessment, STOP and do so before proceeding."}}'
fi
```

- [ ] **Step 3: Update PostToolUse hook similarly**

Create `plugin/bin/post-edit-check.sh`:

```bash
#!/bin/sh
# post-edit-check.sh — PostToolUse hook for Edit|Write
# Allows abbreviated scope check for planning paths.

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | grep -o '"file_path":"[^"]*"' | head -1 | sed 's/"file_path":"//;s/"//')

IS_PLANNING=false
case "$FILE_PATH" in
  */docs/specs/*|*/docs/plans/*) IS_PLANNING=true ;;
esac

IS_PROTECTED=false
BASENAME=$(basename "$FILE_PATH" 2>/dev/null)
case "$BASENAME" in
  CLAUDE.md|working-rules.md|change-decision-framework.md|enforcement-mechanisms.md|settings.local.json|plugin.json)
    IS_PROTECTED=true ;;
esac

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/config.sh"
if [ "$KT_CONFIGURED" = "true" ] && [ -n "$KT_KNOWLEDGE_FOLDER" ]; then
  case "$FILE_PATH" in
    "$KT_KNOWLEDGE_FOLDER"/*) IS_PROTECTED=true ;;
  esac
fi

if [ "$IS_PLANNING" = "true" ] && [ "$IS_PROTECTED" = "false" ]; then
  echo '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"PLANNING PATH — abbreviated scope check. Output: Scope OK — planning doc."}}'
else
  echo '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"POST-EDIT SCOPE CHECK — Output this REQUIRED format after edit. Check: (1) Stay in scope? (2) Was anything extra touched? (3) Any unnecessary rewrites? (4) Do changes match decision? (5) Any secondary impact on parents/siblings/dependents? --- PASS: Scope PASS — [brief context why pass, including secondary status]. --- PASS WITH SECONDARY: Scope PASS CONDITIONAL — [what was done as planned]. Then newline: Secondary: [what needs attention]. Then newline: Proposed: [recommended action]. --- FAIL: Scope FAIL — [what failed, what was affected]. Then newline: Proposed: [concrete next step or fix]."}}'
fi
```

- [ ] **Step 4: Make the new scripts executable**

```bash
chmod +x /Users/mikeprasad/Projects/aria/plugin/bin/pre-edit-check.sh
chmod +x /Users/mikeprasad/Projects/aria/plugin/bin/post-edit-check.sh
```

- [ ] **Step 5: Update plugin.json hooks to use new scripts**

Replace the inline echo commands in PreToolUse and PostToolUse with the new script calls:

```json
"PreToolUse": [
  {
    "matcher": "Edit|Write",
    "hooks": [
      {
        "type": "command",
        "command": "bash ${CLAUDE_PLUGIN_ROOT}/bin/pre-edit-check.sh",
        "timeout": 5
      }
    ]
  }
],
"PostToolUse": [
  {
    "matcher": "Edit|Write",
    "hooks": [
      {
        "type": "command",
        "command": "bash ${CLAUDE_PLUGIN_ROOT}/bin/post-edit-check.sh",
        "timeout": 5
      }
    ]
  }
]
```

- [ ] **Step 6: Bump version**

Update `"version": "2.3.2"` to `"version": "2.4.0"` — this is a feature release (new skills + hook behavior change).

- [ ] **Step 7: Verify plugin.json is valid JSON**

```bash
python3 -c "import json; json.load(open('/Users/mikeprasad/Projects/aria/plugin/.claude-plugin/plugin.json'))"
```
Expected: no output (valid JSON).

- [ ] **Step 8: Verify new scripts have correct syntax**

```bash
bash -n /Users/mikeprasad/Projects/aria/plugin/bin/pre-edit-check.sh && echo "pre-edit OK"
bash -n /Users/mikeprasad/Projects/aria/plugin/bin/post-edit-check.sh && echo "post-edit OK"
```
Expected: "pre-edit OK" and "post-edit OK".

- [ ] **Step 9: Commit**

```bash
git add plugin/.claude-plugin/plugin.json plugin/bin/pre-edit-check.sh plugin/bin/post-edit-check.sh
git commit -m "feat: register /index and /context skills, add planning path hooks, bump to v2.4.0"
```

---

### Task 10: Copy updated plugin to install location and verify

**Files:**
- Source: `plugin/` (entire directory)
- Target: `~/.claude/plugins/marketplaces/local-desktop-app-uploads/aria-knowledge/`

- [ ] **Step 1: Copy plugin to install location**

```bash
cp -R /Users/mikeprasad/Projects/aria/plugin/* ~/.claude/plugins/marketplaces/local-desktop-app-uploads/aria-knowledge/
```

- [ ] **Step 2: Verify key files exist in install location**

```bash
ls -la ~/.claude/plugins/marketplaces/local-desktop-app-uploads/aria-knowledge/skills/index/SKILL.md
ls -la ~/.claude/plugins/marketplaces/local-desktop-app-uploads/aria-knowledge/skills/context/SKILL.md
ls -la ~/.claude/plugins/marketplaces/local-desktop-app-uploads/aria-knowledge/bin/pre-edit-check.sh
ls -la ~/.claude/plugins/marketplaces/local-desktop-app-uploads/aria-knowledge/bin/post-edit-check.sh
```
Expected: all four files exist.

- [ ] **Step 3: Verify scripts are executable**

```bash
test -x ~/.claude/plugins/marketplaces/local-desktop-app-uploads/aria-knowledge/bin/pre-edit-check.sh && echo "pre-edit executable"
test -x ~/.claude/plugins/marketplaces/local-desktop-app-uploads/aria-knowledge/bin/post-edit-check.sh && echo "post-edit executable"
```
Expected: both "executable" messages.

- [ ] **Step 4: Verify plugin.json version**

```bash
python3 -c "import json; d=json.load(open('$HOME/.claude/plugins/marketplaces/local-desktop-app-uploads/aria-knowledge/.claude-plugin/plugin.json')); print(f'Version: {d[\"version\"]}')"
```
Expected: "Version: 2.4.0"

- [ ] **Step 5: Commit all changes**

```bash
cd /Users/mikeprasad/Projects/aria
git add -A
git commit -m "chore: complete knowledge retrieval feature — v2.4.0"
```

- [ ] **Step 6: Note for testing**

Restart Claude Code to pick up the plugin changes. Then test:
1. `/index` — should scan and build index.md (will prompt about untagged files)
2. `/context api` — should read index and present matches (or "no matches" if no files tagged yet)
3. Session restart — should see knowledge surfacing instruction in hook output
4. Edit a file in `docs/specs/` — should get abbreviated Rule 22 prompt
5. Edit a file in `plugin/` — should get full Rule 22 prompt
