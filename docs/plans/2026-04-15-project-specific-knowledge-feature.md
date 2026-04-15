# ARIA Feature Plan: Project-Specific Knowledge

**Date:** 2026-04-15
**Status:** Draft (planning, not yet implemented)
**Context:** Knowledge audit on 2026-04-15 introduced `knowledge/projects/` subdirectory structure to capture project-specific architecture decisions and patterns that don't yet warrant cross-project promotion. This plan formalizes the structure as an optional ARIA feature.

## Goal

Make project-specific knowledge a **first-class, opt-in feature** of ARIA — with skill support, configuration, surfacing, and lifecycle management — without forcing the structure on users who don't need it.

## Current State (Manual)

After the 2026-04-15 audit, knowledge folder structure is:

```
knowledge/
├── approaches/           (cross-project, validated 2+ projects)
├── decisions/            (cross-project ADRs)
├── rules/
├── guides/
├── references/
└── projects/             (project-specific — NEW)
    ├── README.md
    ├── cs-builder/
    │   ├── decisions/
    │   ├── patterns/
    │   └── (optionally guides/, references/)
    ├── cs/
    ├── df/
    │   ├── decisions/
    │   ├── patterns/
    │   └── guides/
    ├── ss/                (currently empty)
    └── aria/
        └── decisions/
```

**Manual conventions:**
- Files tagged with project tag (`cs-builder`, `df`, etc.)
- Cross-references from project docs use `../../../` to reach cross-project trees
- Project CLAUDE.md files have a "Knowledge Repository" section pointing to `knowledge/projects/{project}/`
- No automation — promotion ladder (project → approach → rule) is human judgment

## Why Make This a Feature

**For users new to ARIA:** Without explicit support, they won't know to create `projects/` subdirectories or how to organize project-specific vs cross-project knowledge. They'll either dump everything cross-project (noise) or skip capturing project-specific (loss).

**For existing users:** Manual structure works but lacks tooling — `/audit-knowledge` doesn't differentiate project-specific findings from cross-project ones; `/extract` doesn't know to suggest project subdirectories; `/index` treats projects/ as flat tree.

**For the promotion ladder:** Without surfacing, project-specific patterns can't be detected as candidates for cross-project promotion when they appear in 2+ projects.

## Proposed Feature

### Phase 1: Configuration & Detection (high value, low complexity)

**Add to `aria-knowledge.local.md`:**

```yaml
projects:
  enabled: true                      # Opt-in toggle
  list:                              # Project tags ARIA recognizes
    - { tag: cs-builder, path: cs/cs-space-builder }
    - { tag: cs, path: cs }
    - { tag: ss, path: ss }
    - { tag: df, path: df }
    - { tag: aria, path: aria }
  default_subdirs:                   # Standard subdirs auto-created on first promotion
    - decisions
    - patterns
  optional_subdirs:                  # Created on demand
    - guides
    - references
  promotion_threshold: 2             # Min projects with same pattern before suggesting cross-project promotion
```

If `projects.enabled: false` (default for new installs), all current behavior is preserved. ARIA continues to work flat.

### Phase 2: Setup Skill Updates

**`/setup` enhancements:**
- Detect existing `projects/` subdirectory; if present, ask user to confirm or update the project list
- For new installs: ask "Do you want project-specific knowledge support?" — if yes, prompt for project tags and paths (defaults inferred from working directory siblings)
- Generate `projects/README.md` and per-project `README.md` files
- Add a `## Knowledge Repository` section to each project's CLAUDE.md (if writable) pointing to `knowledge/projects/{project}/`

### Phase 3: Audit Skill Updates

**`/audit-knowledge` enhancements:**
- **Step 5e (NEW):** Cross-project pattern detection — scan `projects/{*}/patterns/` for files with similar tags or filenames across projects. If a pattern appears in ≥`promotion_threshold` projects, surface as a "Promote to cross-project approach?" candidate
- **Step 6 categorization:** When presenting Category C items, suggest project subdirectory destination based on file tags (e.g., insight tagged [cs-builder] → suggest `projects/cs-builder/patterns/`)
- **Step 7 promotion:** When user approves a promotion to a project subdirectory, validate the project exists in config; offer to add it if not

### Phase 4: Extract & Index Skill Updates

**`/extract` enhancements:**
- Detect current working directory; if it matches a configured project path, default extraction destination to that project's backlog scope
- Tag captured items with the project tag automatically

**`/index` enhancements:**
- Add `## Projects` section listing each project with its file count + last-updated date
- Detect "candidate for promotion" patterns (appears in ≥N project trees) and surface in index
- Per-project tag indexes for quick lookup

### Phase 5: Context Skill Updates

**`/context {project}` enhancements:**
- When user runs `/context cs-builder`, load all `projects/cs-builder/**/*.md` plus cross-project files tagged `cs-builder`
- Smart loading priority: project decisions first, then patterns, then cross-project tagged content

### Phase 6: Hook Integration (lowest priority)

**SessionStart hook:**
- If working directory matches a configured project path, automatically suggest `/context {project}` to load project knowledge
- This is opt-in via `auto_load_project_context: true` in config

**Stop hook:**
- When session ends in a project directory, prompt to extract project-specific findings (not just generic /extract)

## Where to Integrate

| Component | File | Type of change |
|-----------|------|----------------|
| Config schema | `plugin/template/aria-knowledge.local.md` | Add `projects:` block with defaults |
| Setup skill | `plugin/skills/setup/SKILL.md` | Add Step 7+ for project setup |
| Audit skill | `plugin/skills/audit-knowledge/SKILL.md` | Add Step 5e (cross-project pattern detection); update Step 6 categorization |
| Extract skill | `plugin/skills/extract/SKILL.md` | Add CWD-based project detection; auto-tag |
| Index skill | `plugin/skills/index/SKILL.md` | Add Projects section; add promotion candidate detection |
| Context skill | `plugin/skills/context/SKILL.md` | Add per-project loading mode |
| Knowledge folder template | `plugin/template/knowledge/projects/README.md` | Ship the README that explains the structure |
| OVERVIEW.md | `plugin/OVERVIEW.md` | Document the projects/ tier as a new ARIA concept |
| README.md | `aria/README.md` + `plugin/README.md` | Mention project-specific knowledge as an opt-in feature |

## How to Leverage (User Workflows)

### Workflow 1: New project bootstrap
```
$ cd ~/Projects/new-project
$ # In Claude session:
> /setup add-project new-project
[ARIA creates knowledge/projects/new-project/{decisions,patterns}/ and adds knowledge pointer to project CLAUDE.md]
```

### Workflow 2: Capture project decision during work
```
> [discussion of architectural decision]
> /extract
[ARIA detects CWD in cs-builder, auto-tags entries with "cs-builder", offers projects/cs-builder/decisions/ as destination]
```

### Workflow 3: Cross-project promotion alert
```
> /audit-knowledge
[Step 5e detects "agentic-ui-patterns" appears in projects/cs-builder/ AND projects/ss/ — suggests promoting to /knowledge/approaches/]
> [User approves; ARIA moves files, updates cross-references, removes project-specific copies]
```

### Workflow 4: Load project context at session start
```
$ cd ~/Projects/cs/cs-space-builder
$ # In Claude session:
[SessionStart hook detects project, suggests:]
> "You're working in cs-space-builder. Load project knowledge? (y/n)"
> y
[ARIA loads projects/cs-builder/ + cross-project items tagged cs-builder]
```

## Migration Path for Existing Users

Users with existing flat knowledge folders shouldn't be forced into projects/ structure. Migration is opt-in:

1. **Stay flat:** `projects.enabled: false` — current behavior preserved
2. **Lazy migration:** Enable `projects` config but don't move anything. New project-specific captures go into `projects/`. Existing files stay where they are. Audit can suggest moves over time.
3. **Bulk migration:** Run `/setup migrate-to-projects` (new sub-skill) — scans existing files for project tags, suggests moves, applies on approval. This is what the 2026-04-15 audit did manually.

## Open Questions

1. **Project detection method:** CWD-based or git-remote-based? CWD is simpler but breaks if project paths are nonstandard. Git-remote handles forks/clones better.

2. **Cross-project decision numbering:** Currently top-level `decisions/` has 007, 009 (old 001-006, 008 moved to projects/). Should new cross-project ADRs continue from 010? Or restart? Or use a different scheme (year-based, e.g., 2026-001)?

3. **Project subdirectory structure:** Standard set (decisions, patterns) or fully customizable? Recommendation: standard with optional extension (decisions, patterns required; guides, references optional).

4. **Promotion direction:** Always project → cross-project? Or sometimes the reverse (a cross-project rule turns out to be project-specific)? Plan should support demotion too.

5. **Multi-project tags:** What if a pattern applies to cs-builder AND cs? Tag with both? Put in `projects/cs/` (parent) or `projects/cs-builder/` (specific)? Recommendation: tag with both, place in the more specific subdir, cross-link.

6. **ss/ folder is currently empty:** Should `/index` warn about empty project folders, or stay silent until they have content? Recommendation: silent — let user populate at their pace.

7. **Index tagging for projects/ files:** The current 2026-04-15 index uses inline tags from each file's frontmatter. Should projects/ files get an automatic project tag derived from their path (so users don't have to remember to tag)? Recommendation: yes, derive project tag from path; user can add additional tags.

## Dependencies & Risks

**Dependencies:**
- Existing `/index` skill already scans entire knowledge tree recursively — no change needed for basic discovery
- Config parser already handles YAML frontmatter and `aria-knowledge.local.md` — extension is straightforward
- Skills currently use markdown-based decision flow — adding new steps is consistent with existing pattern

**Risks:**
- **User confusion:** "Should this go in approaches or projects/cs-builder/patterns?" The config default + auto-suggestion should mitigate
- **Cross-reference complexity:** Moving files breaks relative paths — need a `/audit-knowledge` step that auto-fixes path references when files move (Phase 3-4 should include this)
- **Promotion judgment errors:** Auto-suggesting cross-project promotion at threshold=2 might be too aggressive. Could start at 3 and tune based on usage
- **Backward compatibility:** Existing users with flat structure shouldn't see any prompts unless they opt in — `projects.enabled: false` default ensures this

## Suggested Implementation Order

1. **Phase 1 (config schema)** — minimal change, unlocks everything else
2. **Phase 2 (setup skill)** — enables new users to opt in cleanly
3. **Phase 5 (context skill)** — high-leverage for daily use
4. **Phase 3 (audit skill)** — most complex; requires careful UX design for promotion candidate detection
5. **Phase 4 (extract + index skill)** — moderate complexity, builds on Phase 3
6. **Phase 6 (hook integration)** — lowest priority, opt-in only

Each phase ships independently. Phase 1 alone enables manual project structure with no automation; subsequent phases progressively automate.

## Validated By

- Manual implementation of project-specific structure on 2026-04-15 (this session)
- 4-agent project scan revealed 17 net-new project-specific items across cs-builder, df, ss, aria — suggests this structure has real demand
- Pre-staged 13 decisions + 4 insights to backlog for next audit promotion — validates the "project-specific captures graduate to cross-project" lifecycle

## Related

- `~/Projects/knowledge/projects/README.md` — current manual implementation
- `~/Projects/knowledge/projects/aria/decisions/002-knowledge-extraction-architecture.md` — existing extraction architecture this extends
- `~/Projects/knowledge/projects/aria/decisions/008-skill-knowledge-connections.md` — pattern for skill-knowledge integration this would extend
