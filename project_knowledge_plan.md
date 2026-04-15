# ARIA Implementation Plan: Project-Specific Knowledge Management

**Status:** Implemented (v2.8.0–v2.8.2). This is the pre-implementation design doc — see CHANGELOG.md for what actually shipped. Notable divergence: `session-stop-check.sh` was removed in v2.8.2 (never registered in plugin.json).
**Target version:** v2.8.0
**Date drafted:** 2026-04-15
**Companion design doc:** `aria/docs/plans/2026-04-15-project-specific-knowledge-feature.md` (architectural rationale + open questions)

---

## TL;DR

Add an opt-in `projects/` tier to ARIA's knowledge folder for project-specific architecture decisions and patterns that don't yet warrant cross-project promotion. Validated by manual implementation in the user's knowledge folder on 2026-04-15 — this plan formalizes that pattern as a first-class plugin feature.

**Total scope:** ~14 file changes across 6 phases, plus 1 new template subdirectory.
**Estimated effort:** ~13 hours total, splittable into 6 independently-shippable phases.
**Recommended MVP:** Phases 1+2+5 (~4 hours) ships end-to-end usable feature; Phases 3, 4, 6 add automation incrementally.

---

## Background: Why This Exists

The user's knowledge folder previously had a flat structure:
```
knowledge/
├── approaches/     (cross-project patterns)
├── decisions/      (cross-project ADRs)
├── rules/
├── guides/
├── references/
```

This structure forced a binary choice when capturing knowledge:
- **Cross-project tier:** appropriate for patterns validated in 2+ projects, but too narrow a bar for genuinely valuable single-project knowledge
- **Memory files:** good for status tracking ("where are we now") but not for preserving architectural decisions over the long term

Result: project-specific architecture decisions either got dumped into the cross-project tree (creating noise) or weren't captured at all (loss). On 2026-04-15, an audit revealed ~17 net-new project-specific items across cs-builder, df, ss, and aria that had been invisible to the knowledge graph because the docs were embedded in project READMEs and not surfaced via tags.

The manual fix on 2026-04-15:
1. Created `knowledge/projects/{cs-builder,cs,aria,df,ss}/{decisions,patterns,...}/`
2. Moved 10 existing project-specific files from cross-project tree to project subfolders
3. Promoted ~21 new project-specific items from agent scans
4. Updated 5 project CLAUDE.md files with knowledge pointer sections
5. Rebuilt index.md to surface project-specific files via project tags

This plan generalizes that one-time manual fix into a repeatable opt-in plugin feature.

---

## Current State of ARIA Plugin

**Plugin structure (relevant subset):**
```
aria/plugin/
├── .claude-plugin/plugin.json
├── README.md
├── bin/
│   ├── config.sh                 ← parses YAML config, exposes KT_* env vars
│   ├── session-start-check.sh    ← cadence-based audit prompts
│   ├── session-stop-check.sh     ← extraction prompts
│   └── (other hooks)
├── skills/
│   ├── setup/SKILL.md            ← scaffolds knowledge folder, diffs templates
│   ├── audit-knowledge/SKILL.md  ← review backlogs, promote items
│   ├── extract/SKILL.md          ← capture knowledge mid-session
│   ├── index/SKILL.md            ← rebuild tag index
│   ├── context/SKILL.md          ← load files by tag
│   └── (10 other skills)
└── template/
    ├── README.md, OVERVIEW.md, LOCAL.md
    ├── intake/                   ← backlog files (user-owned)
    ├── logs/                     ← audit logs (user-owned)
    ├── rules/                    ← Rule 22 + framework files (plugin-managed)
    ├── approaches/, decisions/, references/, guides/, archive/  ← directory stubs
```

**Existing infrastructure that helps:**
- `config.sh` already parses YAML frontmatter cleanly via sed; adding new fields is mechanical
- `setup` skill has a robust **template-managed vs user-owned** dichotomy; `projects/README.md` becomes plugin-managed; per-project files become user-owned
- `context` skill already does **project tag expansion** via the `## Projects` section in `index.md` (e.g., `/context ss` expands to include all SS-relevant tags)
- `audit-knowledge` skill has the **promotion ladder** concept; just needs to know about projects/ as a destination
- The plugin's diff-on-update pattern (Step 4 of /setup) handles new template files cleanly without breaking existing user installs

**What's missing:**
- Config flag to enable/disable project tier
- Templates for `projects/` subdirectory and per-project READMEs
- Skill awareness of `projects/{tag}/**/*.md` paths
- Auto-tagging by CWD detection (extract skill)
- Cross-project promotion candidate detection (audit + index)

---

## Phase 1: Config Schema (Foundation)

**Effort:** ~2 hours
**Unlocks:** Everything else can read the flag.

### Files to change

| File | Change |
|------|--------|
| `plugin/bin/config.sh` | Add 3 new env var parsers: `KT_PROJECTS_ENABLED`, `KT_PROJECTS_LIST`, `KT_PROJECTS_PROMOTION_THRESHOLD` |
| `plugin/skills/setup/SKILL.md` Step 6 (Advanced Options) | Add prompt: "Enable project-specific knowledge? (default: false)" + (if yes) "Which projects? Comma-separated `tag:path` pairs:" |
| `plugin/skills/setup/SKILL.md` Step 7 | Update YAML template to emit project fields when enabled |

### Config schema

```yaml
projects_enabled: false              # Opt-in default; existing users see no change
projects_list: cs-builder:cs/cs-space-builder,df:df,ss:ss,aria:aria,cs:cs
projects_promotion_threshold: 2      # Min projects with same pattern before suggesting promotion
```

**Format choice:** Comma-separated `tag:relative-path` mapping kept simple for shell parsing in `config.sh`. Paths are relative to the user's primary working directory parent (typically `~/Projects/`). YAML nested structures would require a YAML parser upgrade in the hooks; not worth the complexity for this feature.

### Implementation notes

In `config.sh`:
```sh
KT_PROJECTS_ENABLED=$(sed -n '/^---$/,/^---$/p' "$KT_CONFIG" | grep '^projects_enabled:' | sed 's/^projects_enabled: *//')
KT_PROJECTS_LIST=$(sed -n '/^---$/,/^---$/p' "$KT_CONFIG" | grep '^projects_list:' | sed 's/^projects_list: *//')
KT_PROJECTS_PROMOTION_THRESHOLD=$(sed -n '/^---$/,/^---$/p' "$KT_CONFIG" | grep '^projects_promotion_threshold:' | sed 's/^projects_promotion_threshold: *//')

# Defaults
KT_PROJECTS_ENABLED=${KT_PROJECTS_ENABLED:-false}
KT_PROJECTS_PROMOTION_THRESHOLD=${KT_PROJECTS_PROMOTION_THRESHOLD:-2}

# Validate
case "$KT_PROJECTS_ENABLED" in
  true|false) ;;
  *) KT_PROJECTS_ENABLED=false ;;
esac
case "$KT_PROJECTS_PROMOTION_THRESHOLD" in
  ''|*[!0-9]*) KT_PROJECTS_PROMOTION_THRESHOLD=2 ;;
esac
```

Helper function for project list parsing (add to config.sh):
```sh
# Returns the project tag for a given path, or empty if not in any configured project
kt_project_for_path() {
  path="$1"
  if [ -z "$KT_PROJECTS_LIST" ]; then
    return
  fi
  # Iterate comma-separated entries
  IFS=','
  for entry in $KT_PROJECTS_LIST; do
    tag="${entry%%:*}"
    proj_path="${entry#*:}"
    case "$path" in
      *"$proj_path"*) printf '%s' "$tag"; return ;;
    esac
  done
  unset IFS
}
```

### Verification

- Run a fresh /setup with `projects_enabled: false`; confirm hooks behave identically to v2.7.x (no new prompts)
- Run /setup with `projects_enabled: true` and a project list; confirm config file roundtrips cleanly via `config.sh` parsing
- Source `config.sh` and verify `kt_project_for_path "~/Projects/cs/cs-space-builder/CLAUDE.md"` returns `cs-builder`

---

## Phase 2: Setup Skill — Scaffolding + Diffing

**Effort:** ~1 hour
**Depends on:** Phase 1
**Unlocks:** New users + existing users can opt in cleanly.

### Files to change

| File | Change |
|------|--------|
| `plugin/skills/setup/SKILL.md` Step 3 | Add: "If `projects_enabled: true`, also create `projects/{tag}/` directories with `decisions/` and `patterns/` subdirs per the project list" |
| `plugin/skills/setup/SKILL.md` Step 4 | Add `projects/README.md` to "Files to diff" (plugin-managed); add per-project READMEs to "Never diff" (user-owned) |
| `plugin/template/projects/README.md` | NEW — ship the projects/ explainer (use the file already created at `~/Projects/knowledge/projects/README.md` as the template source) |

### New shipped template content

Create `plugin/template/projects/README.md` based on the existing `projects/README.md` already created in the user's knowledge folder. Generalize:
- Replace specific project examples (cs-builder, df, ss, aria, cs) with placeholder examples
- Keep the 3-tier promotion ladder explanation (project → cross-project approach → universal rule)
- Keep the structure example
- Add: "This file is shipped by ARIA. Project subdirectories below are user-owned — your customizations are never overwritten by /setup updates."

### Per-project README pattern

When `/setup` creates each project subdirectory, generate a minimal per-project README:

```markdown
# {Project Name} Project Knowledge

Project-specific architecture decisions, patterns, and gotchas for {project name}.

## Structure

- `decisions/` — Architecture Decision Records (ADRs)
- `patterns/` — Reusable patterns specific to this project
- `guides/` (optional) — Operational knowledge specific to this project
- `references/` (optional) — External resources specific to this project

## Promotion

When a pattern in this folder is validated in another project, promote it to `knowledge/approaches/` and remove the project-specific copy. See `knowledge/projects/README.md` for the full promotion ladder.
```

### Existing manual `projects/` folder (migration case)

**Primary scenario:** a user already has `projects/` from a manual migration (the user running this plan has exactly this state after the 2026-04-15 audit). When the new /setup first runs in this state:

1. **Detect:** scan knowledge folder for existing `projects/{tag}/` subdirectories
2. **If found AND `projects_enabled` is unset in config:**
   - Prompt: "Detected existing `projects/` folder with N subdirectories: [list]. Enable project-specific knowledge tier? (y/n)"
   - If yes: auto-populate `projects_list` from the detected subdirectories, prompting only for the path mapping (tag → project path)
   - If no: leave config unset; don't touch the existing folder
3. **If found AND `projects_enabled: false` explicitly in config:** leave untouched (respect user's choice); note in verbose output that the existing folder is visible but automation is disabled
4. **If found AND `projects_enabled: true`:** verify each detected subdirectory is in `projects_list`; prompt to add any missing ones

**Never auto-delete or auto-rewrite** existing `projects/` content. The /setup skill only creates missing structure; it never destroys user content.

### Verification

- Fresh `/setup` with `projects_enabled: true` and project list `myproject:src` creates `projects/myproject/{decisions,patterns}/` with both READMEs
- Re-run `/setup` after editing `projects/myproject/README.md` (user-owned) — confirm it's NOT overwritten
- Re-run `/setup` after the plugin updates `projects/README.md` (plugin-managed) — confirm diff prompt appears
- **Existing-projects case:** run `/setup` in a folder that already has manually-created `projects/cs-builder/` etc.; confirm auto-detection prompt appears and `projects_list` gets populated correctly

---

## Phase 3: Audit Skill — Step 5e (Cross-Project Pattern Detection)

**Effort:** ~3 hours
**Depends on:** Phase 1
**Unlocks:** Highest-leverage feature — detects when project-specific patterns deserve promotion to cross-project.

### Files to change

| File | Change |
|------|--------|
| `plugin/skills/audit-knowledge/SKILL.md` | Add Step 5e between 5d (codemap staleness) and Step 6 (present findings) |
| `plugin/skills/audit-knowledge/SKILL.md` Step 6 | Add to suggested locations: when a Category C item is tagged with a project tag, suggest `projects/{tag}/{decisions or patterns}/` |
| `plugin/skills/audit-knowledge/SKILL.md` Step 7 | Add: when promoting a Category C item to a project subfolder, validate the project exists in config; offer to add it if not |

### Step 5e specification

```markdown
## Step 5e: Cross-Project Pattern Detection

If `projects_enabled: false`, skip this step silently.

Scan `{knowledge_folder}/projects/{*}/patterns/*.md` for files that may represent the same pattern across multiple projects.

**Detection heuristics:**
1. **Filename similarity:** files with similar kebab-case names (e.g., `state-management-patterns.md` in two projects)
2. **Tag overlap:** files sharing 3+ tags excluding the project tag itself
3. **Title/summary similarity:** files whose H1 or first paragraph share key terms

**Threshold:** if a pattern appears in ≥`projects_promotion_threshold` projects (default 2), surface as a candidate.

For each candidate, present:
- File paths in the projects where the pattern appears
- Shared tags
- Suggested cross-project location (typically `approaches/{shared-tag-based-name}.md`)
- Recommended action: "Promote to cross-project approach? Y/N/skip"

If user approves promotion:
1. Synthesize content from the project-specific files (ask user to review the merged draft before committing)
2. Write the new cross-project file
3. Update each project-specific file to reference the cross-project version (or remove the duplicate, depending on whether the project-specific context still has unique value)
4. Update `knowledge/index.md`
```

### Step 6 update

Add to "suggested location" determination:

```markdown
For Category C items:
- Check item's tags against the configured project tags (`KT_PROJECTS_LIST`)
- If a tag matches a project, suggest `projects/{tag}/{decisions if it's a decision, patterns if it's a reusable pattern}/`
- If no project tag matches but content is clearly project-specific (mentions cs-builder, ss, etc.), prompt user to confirm the project tag before suggesting location
```

### Step 7 update

Add validation:

```markdown
When user approves promotion to a project subdirectory:
1. Verify `projects/{tag}/` exists in the user's knowledge folder
2. If not, prompt: "Project '{tag}' is not in your config. Add it now? (yes adds to projects_list and creates the directory)"
3. If yes: edit `aria-knowledge.local.md` to append the new tag, then create `projects/{tag}/{decisions,patterns}/` with READMEs
```

### Provenance preservation (`originally_at` convention)

When Step 5e promotion moves/synthesizes files across the projects/ ↔ cross-project boundary, git may fail to detect the move as a rename (especially if content is extended/synthesized during the move — the 50% similarity threshold falls short). This happened on 2026-04-15 with cs-builder ADR 004.

**Convention:** When a promoted file's content changes significantly from its source, add a YAML frontmatter field to the new file:

```yaml
---
Last updated: 2026-04-15
tags: [architecture, patterns]
originally_at: projects/cs-builder/patterns/state-sync.md (merged with projects/ss/patterns/state-sync.md on 2026-04-15 during cross-project promotion)
---
```

Benefits:
- Human-readable provenance survives git history truncation
- `grep -r "originally_at:" knowledge/` enumerates all consolidations
- No history rewrite needed; one-line metadata

**Implementation note:** Step 5e's promotion routine should auto-generate this field when it creates a cross-project file from multiple project sources.

### Verification

- Manually plant 2 files with overlapping tags in `projects/cs-builder/patterns/` and `projects/ss/patterns/`
- Run `/audit-knowledge`; confirm Step 5e surfaces them as a candidate
- Approve promotion; confirm new file lands in `approaches/` with synthesized content AND `originally_at` frontmatter
- Re-run audit; confirm the same files no longer trigger the suggestion

---

## Phase 4: Extract + Index Skill Updates

**Effort:** ~3 hours
**Depends on:** Phase 1
**Unlocks:** Auto-tagging + index visibility for project files.

### Files to change

| File | Change |
|------|--------|
| `plugin/skills/extract/SKILL.md` Step 0 | Add: detect CWD; if it matches a configured project path (via `kt_project_for_path` from config.sh), set `current_project` and use it for default tagging |
| `plugin/skills/extract/SKILL.md` Step 3 | Add: when writing to backlogs, auto-prepend `current_project` tag if detected |
| `plugin/skills/index/SKILL.md` | Add: `## Projects` section per project enumerating files and last-update dates; "candidate for promotion" detection (mirrors audit Step 5e logic) |
| `plugin/skills/index/SKILL.md` | Update tag derivation: files in `projects/{tag}/**` get `tag` automatically appended to their tag set even if not in YAML frontmatter |

### Extract Step 0 update

```markdown
## Step 0: Resolve Config and Detect Project

Read `~/.claude/aria-knowledge.local.md` and extract `knowledge_folder`.

If `projects_enabled: true`:
- Get current working directory
- Iterate `projects_list` entries; for each `tag:path`, check if CWD contains the path substring
- If matched, set `current_project = tag` for use in subsequent steps
- If not matched, leave `current_project` unset (no auto-tagging)
```

### Extract Step 3 update

```markdown
When appending to backlogs:
- If `current_project` is set, prepend the project tag to each entry's source line:
  - Example: instead of `### 2026-04-15 — feedback — User clarifies...`
  - Write: `### 2026-04-15 — cs-builder — feedback — User clarifies...`
- This makes downstream audit promotion auto-suggest the right project subfolder
```

### Index skill — auto-tag derivation

```markdown
When scanning files for tags:
1. Read YAML frontmatter `tags:` field as the explicit tag set
2. If file path matches `projects/{tag}/**/*.md`, also add `{tag}` to the file's tag set
3. Use the union for index entries

This means project files don't need to manually include the project tag in their frontmatter — it's derived from location.
```

### Index skill — Projects section

```markdown
After the existing tag indexes, add:

## Projects

### {project tag}
- Files: N
- Last updated: {most recent file's date}
- Patterns: {count}
- Decisions: {count}
- Cross-project promotion candidates: {if any from Step 5e-style scan, list them}
```

### Verification

- In a session with CWD inside a configured project path, run /extract; confirm the project tag appears in backlog entries
- Run `/index`; confirm Projects section is populated correctly and project files are tagged correctly even without explicit YAML tags

---

## Phase 5: Context Skill Updates

**Effort:** ~1 hour
**Depends on:** Phase 1
**Unlocks:** End-to-end usable feature once Phases 1+2 ship.

### Files to change

| File | Change |
|------|--------|
| `plugin/skills/context/SKILL.md` Step 4 | When a query matches a project tag, ALSO load all files under `projects/{tag}/**` (not just files cross-tagged with the project) |
| `plugin/skills/context/SKILL.md` Step 5 | When presenting summary, group results: "Project-specific" first, "Cross-project" second |

### Step 4 update

```markdown
For each tag in the query:
1. Check if it matches a project tag in `## Projects` section of index.md
2. If yes: gather files in two categories:
   - **Project-specific:** all files under `projects/{tag}/**`
   - **Cross-project tagged:** files in cross-project tree (approaches/, decisions/, etc.) that have this tag in their YAML
3. Present both sets, with project-specific first
```

### Step 5 update

```markdown
Format the summary:

```
Found N files matching: [tags] ([OR|AND])

## Project-specific
- projects/{tag}/decisions/...
- projects/{tag}/patterns/...

## Cross-project
- approaches/...
- decisions/...
```

If only project-specific or only cross-project results exist, omit the empty section.
```

### Verification

- Run `/context cs-builder`; confirm files load from both `projects/cs-builder/` and cross-project tree (e.g., `approaches/agentic-ui-patterns.md` which is tagged for cs-builder validation)
- Run `/context aria`; confirm aria ADRs surface from `projects/aria/decisions/`

---

## Phase 6: Hook Integration (Optional, Lowest Priority)

**Effort:** ~2 hours
**Depends on:** Phase 1
**Unlocks:** Convenience automation; double opt-in (config flag + hook flag).

### Files to change

| File | Change |
|------|--------|
| `plugin/bin/session-start-check.sh` | If `KT_PROJECTS_ENABLED=true` AND `KT_AUTO_LOAD_PROJECT_CONTEXT=true` AND CWD matches a configured project path, suggest `/context {project}` |
| `plugin/bin/session-stop-check.sh` | If session ends in a project directory, prompt to extract project-specific findings |
| `plugin/bin/config.sh` | Add `KT_AUTO_LOAD_PROJECT_CONTEXT` parser (default false; second opt-in) |

### Why double opt-in

Hook prompts are a high-friction surface. Even users who enable `projects_enabled` may not want session-start prompts. The second flag (`auto_load_project_context: false` default) lets power users enable hook automation without forcing it on all `projects_enabled: true` users.

### Verification

- With `auto_load_project_context: false`, start a session in a project directory — confirm no new prompts appear
- With `auto_load_project_context: true`, start a session in a project directory — confirm prompt appears suggesting `/context cs-builder` (or whichever project)

---

## Cross-Cutting: Documentation

**Effort:** ~1 hour

| File | Change |
|------|--------|
| `plugin/template/OVERVIEW.md` | Add a section explaining the projects/ tier as a new ARIA concept |
| `plugin/README.md` | Mention project-specific knowledge as opt-in feature |
| `aria/README.md` | User-facing description |
| `aria/CHANGELOG.md` | New version entry (e.g., v2.8.0 — Project-Specific Knowledge) |

---

## Implementation Order

| Order | Phase | Effort | Cumulative | Unlocks |
|-------|-------|--------|------------|---------|
| 1 | Phase 1 (config) | 2h | 2h | Everything else can read the flag |
| 2 | Phase 2 (setup) | 1h | 3h | New users can opt in cleanly |
| 3 | Phase 5 (context) | 1h | 4h | **MVP — end-to-end usable** |
| 4 | Phase 4 (extract + index) | 3h | 7h | Auto-tagging + index visibility |
| 5 | Phase 3 (audit) | 3h | 10h | Cross-project promotion detection (highest-leverage) |
| 6 | Phase 6 (hooks) | 2h | 12h | Convenience automation |
| 7 | Cross-cutting docs | 1h | 13h | Marketplace-readiness |

**Recommended MVP for v2.8.0:** Phases 1+2+5 (4 hours). Ship structural feature; let users adopt; build automation in v2.9.0+.

**Alternative full v2.8.0:** All 6 phases (~13 hours). Ships complete feature in one release.

---

## Key Design Decisions

These were identified during the planning phase. Some are recommendations; others are genuinely open. Decide before implementing the affected phase.

### 1. `projects_list` format in config

| Option | Pros | Cons |
|--------|------|------|
| Comma-separated `tag:path` (recommended) | Simple shell parsing in config.sh | No nesting; tag and path can't contain commas or colons |
| YAML nested | Native YAML; supports rich structure | Requires upgrading config.sh parsing |
| Separate file (`projects.list`) | Cleanest for large project lists | Two config files to manage |

**Lean: comma-separated.** Only escape needed: if a project tag contains a colon, document that constraint. Realistic project tags don't have colons or commas.

### 2. Project detection in extract skill

| Option | Pros | Cons |
|--------|------|------|
| CWD-based (recommended) | Simple; matches user's mental model | Breaks if user has nonstandard project paths |
| Git-remote-based | Handles forks, clones, multiple workdirs | Requires `git` calls in the skill |
| Both with fallback | Maximally robust | More complex; rarely needed |

**Lean: CWD-based.** Add note in skill: "If your projects don't live under standard paths, your config can map exact paths."

### 3. Pattern detection threshold

| Option | Pros | Cons |
|--------|------|------|
| Hardcoded 2 | Simplest | Inflexible; some users may want 3+ |
| Configurable (recommended) | Tunable per user/team | One more config field |

**Lean: configurable, default 2.** Add `projects_promotion_threshold` to Phase 1 config schema (already in proposed schema).

### 4. Cross-project ADR numbering after restructure

| Option | Pros | Cons |
|--------|------|------|
| Continue from 010 (recommended) | Preserves sequence; easy to know "what's next" | Skips numbers (007, 009 only currently) |
| Restart from 001 | Clean slate | Loses backward references |
| Year-based (e.g., 2026-001) | Self-dating | Different from current style |

**Lean: continue from 010.** Cross-project ADRs are a separate namespace from project ADRs.

### 5. Auto-tagging behavior in extract

| Option | Pros | Cons |
|--------|------|------|
| Auto-prepend project tag (recommended) | Zero-config for users in project directories | May miss cross-project work happening in a project dir |
| Suggest only, don't auto-add | More conservative | Requires user click per extract |

**Lean: auto-prepend.** Users can edit before backlog write if needed. Aligns with "LLM captures, human promotes" — auto-capture is fine; promotion requires human review.

### 6. Migration for existing users

| Option | Pros | Cons |
|--------|------|------|
| Document manually (recommended for v2.8.0) | Lowest effort to ship | Each user manually moves files |
| Build `/setup migrate-to-projects` sub-skill | Automated | Adds complexity; only useful if 2+ users actually migrate |

**Lean: document only initially.** Build the sub-skill if/when users request it.

### 7. Multi-project tags

What if a pattern applies to cs-builder AND cs (parent)?

**Recommendation:** Tag with both project tags, place in the more specific subdir (`projects/cs-builder/`), cross-link from `projects/cs/README.md`. Document this convention in `projects/README.md`.

### 8. Empty project folders

Should `/index` warn about empty project folders, or stay silent until they have content?

**Recommendation:** Silent. Let user populate at their pace. The Projects section in index.md should still list configured projects with "0 files" so the user sees what's available.

### 9. Index tagging for projects/ files

Should files in `projects/{tag}/**` get an automatic project tag derived from their path?

**Recommendation:** Yes (already in Phase 4 plan). Users don't have to remember to tag; can still add additional tags in YAML.

---

## Risks

1. **User confusion** — "Should this go in approaches or projects/cs-builder/patterns?" Mitigation: Phase 3's audit suggestion + Phase 4's auto-tagging biases toward the right answer.

2. **Cross-reference path complexity** — Moving files breaks relative paths. Mitigation: Phase 3-4 should include a path-fix helper that runs after promotions. The 2026-04-15 manual restructure used sed batches; this can be encapsulated.

3. **Promotion judgment errors** — Auto-suggesting cross-project promotion at threshold=2 might be too aggressive. Mitigation: configurable; can start at 3 in defaults if observed false-positive rate is high.

4. **Backward compatibility** — Existing users with flat structure shouldn't see any prompts unless they opt in. Mitigation: `projects_enabled: false` default ensures this. All Phase 2-5 changes check the flag before activating.

5. **Empty `projects/` folder confusion** — Users who enable but don't populate may wonder if it's working. Mitigation: setup skill creates per-project READMEs that explain the structure; index shows configured projects even if empty.

---

## Edge Cases & Testing

### Edge cases to handle explicitly in code

| Scenario | Expected behavior |
|----------|-------------------|
| `projects_enabled: true`, `projects_list` empty | Hooks/skills behave as if disabled. `/setup` prompts user to add projects; does NOT error. |
| `projects_enabled: false`, existing `projects/` folder on disk | Leave folder untouched. Skills ignore it. `/setup` notes it exists but respects the flag. |
| Old config (no `projects_*` fields) loaded in new hook code | `config.sh` defaults apply (`projects_enabled: false`). No migration nudge — user upgrades on demand via `/setup`. |
| `projects_list` references a path that doesn't exist on disk | `/setup` warns once, continues; skills that iterate entries skip missing paths silently. |
| Project tag contains a colon or comma | `/setup` validates input and rejects with error message pointing to the constraint. |
| Two config entries with the same tag but different paths | Second entry wins (standard shell behavior). `/setup` should detect duplicates during input and warn. |
| User moves a project's physical directory | Detected on next hook fire — CWD no longer matches. User updates config via `/setup`. |
| File in `projects/{tag}/` with no YAML frontmatter | Index auto-derives tag from path; file indexed with just that tag. `/audit-knowledge` flags as untagged candidate for enrichment. |

### Test scenarios for implementation verification

Before shipping each phase, run these scenarios against a scratch knowledge folder (e.g., `/tmp/test-knowledge/`):

**Fresh install tests:**
1. No existing knowledge folder, `projects_enabled: false` → folder created without `projects/`, hooks behave like v2.7.x
2. No existing knowledge folder, `projects_enabled: true`, 3-project list → folder created with `projects/{tag}/{decisions,patterns}/` for each, READMEs populated
3. Empty `projects_list` with `projects_enabled: true` → prompts user to add projects; no folder created yet

**Upgrade tests (existing v2.7.x user):**
4. Existing flat knowledge folder, re-run `/setup` → no new prompts, no new folders, config unchanged
5. Existing flat folder, user opts into projects during re-run → `projects/` scaffolded, existing files untouched
6. Existing folder with manual `projects/` (your existing state) → detection prompt appears; user confirms; `projects_list` auto-populated

**Skill behavior tests:**
7. `/context cs-builder` loads both `projects/cs-builder/**` and cross-project tagged files
8. `/extract` in CWD matching a project path auto-tags entries; outside a project path, no auto-tag
9. `/audit-knowledge` Step 5e detects 2 planted look-alike patterns; approves promotion with `originally_at` field written
10. `/index` shows project counts, staleness per project, and any promotion candidates

**Regression tests:**
11. Run the existing v2.7.x test suite (if any) with new code → all pass
12. Diff a user's config file before/after `/setup --no-changes` → should be identical byte-for-byte when nothing changed

### Testing approach recommendation

Do NOT test against the user's real `~/Projects/knowledge/` folder during implementation. Create a sandbox:

```bash
mkdir -p /tmp/aria-test-knowledge
cp ~/.claude/aria-knowledge.local.md /tmp/aria-test-config.md
# Edit the copy to point knowledge_folder at /tmp/aria-test-knowledge
# Swap KT_CONFIG in config.sh temporarily, or run hooks with the env var overridden
```

This avoids polluting the real knowledge base with test content during development.

---

## Version Strategy

**Recommendation: single v2.8.0 release for the MVP** (Phases 1+2+5).

Rationale:
- Ship as one coherent feature; users don't need to understand phase numbers
- Phase 1 alone (config flag with no effect) has no user-visible value
- Phases 2 and 5 together unlock the "create structure + use it" loop
- Total effort at MVP scope (~4 hours) is appropriate for a minor version bump

**Subsequent releases for additional phases:**
- v2.9.0: Phase 4 (extract + index auto-tagging) — richer automation
- v2.10.0: Phase 3 (audit Step 5e cross-project detection) — highest-leverage but most complex
- v2.11.0: Phase 6 (hook automation) — opt-in convenience

**Alternative if shipping all-at-once:** single v3.0.0 for Phases 1-6 + docs. Use 3.0.0 (major bump) because this meaningfully changes the knowledge folder structure convention.

**Either way, CHANGELOG entries must clearly mark the feature as opt-in** — users of v2.7.x should be able to upgrade to any v2.8+ or v3.0 without any behavior change unless they explicitly opt in via `/setup`.

---

## Success Criteria

After v2.8.0 ships, a user should be able to:

1. Run `/setup` and answer "yes" to enable project-specific knowledge with their list of projects
2. See `projects/{tag}/{decisions,patterns}/` directories created with explanatory READMEs
3. Run `/extract` while working in a project directory and have findings auto-tagged with the project
4. Run `/audit-knowledge` and have Category C items routed to project subfolders by default
5. Run `/context cs-builder` and load both project-specific files AND cross-project files tagged for cs-builder
6. After several audits with overlapping patterns across projects, see promotion candidates surfaced for cross-project knowledge

The user's manual implementation on 2026-04-15 is the proof-of-concept — every workflow above has been validated by hand.

---

## References

- **Companion design doc** (architectural rationale, alternatives considered, broader open questions): `aria/docs/plans/2026-04-15-project-specific-knowledge-feature.md`
- **Manual implementation precedent**: `~/Projects/knowledge/projects/` (created 2026-04-15)
- **Audit log entry documenting the manual implementation**: `~/Projects/knowledge/logs/knowledge-audit-log.md` 2026-04-15 entry
- **Related ADRs being captured by the manual implementation**:
  - `~/Projects/knowledge/projects/aria/decisions/009-three-pillar-architecture.md`
  - `~/Projects/knowledge/projects/aria/decisions/010-llm-captures-human-promotes.md`
  - `~/Projects/knowledge/projects/aria/decisions/011-plugin-installed-copy-diffability.md`
  - `~/Projects/knowledge/projects/aria/patterns/internal-patterns.md`

---

## How to Pick This Up in a New Session

1. Read this file (`aria/project_knowledge_plan.md`) and the companion design doc
2. Confirm scope with the user (MVP / full / specific phase)?
3. Confirm Key Design Decisions §1-9 above (most have recommendations; flag any you want to reconsider)
4. Use the existing `aria-knowledge.local.md` config in `~/.claude/` to test the new fields without breaking the user's current setup
5. Test in a separate fresh knowledge folder (e.g., `/tmp/test-knowledge/`) before applying changes to the user's real knowledge folder
6. Bump version in `plugin/.claude-plugin/plugin.json` for each shipped phase (or for the v2.8.0 release)
7. Add CHANGELOG entries per phase
8. After implementation, run a real `/setup --update` against the user's existing config to verify backward compatibility (existing users with `projects_enabled: false` should see zero behavior change)
