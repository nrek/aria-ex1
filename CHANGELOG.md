# Changelog

All notable changes to ARIA will be documented in this file.

## [2.8.1] - 2026-04-15

### Added — User Rules Separation

A new `rules/user-rules.md` file separates user-created custom rules from plugin-shipped working rules, eliminating the numbering-collision risk where a user's added Rule 30 would conflict with a plugin-shipped Rule 30 on `/setup --update`.

- **New shipped template:** `plugin/template/rules/user-rules.md` — user-owned (never overwritten by `/setup`); ships with usage notes, U-prefix naming convention, and 4 sample rules across Team Rules / Personal Conventions / Retired sections (samples marked for deletion).
- **`/setup` updates:** `rules/user-rules.md` registered as user-owned alongside `LOCAL.md`; created once from template if missing; never diffed on subsequent runs.
- **`/rules` skill:** searches both `working-rules.md` and `user-rules.md`. Index mode shows them grouped ("Plugin Rules" + "Your Rules"). Lookup by number checks both files; warns on collisions. Search mode searches both.
- **`working-rules.md` pointer:** plugin's rules file now references `user-rules.md` in the "How to Use" section so users discover the separation naturally.

### Added — Two New Plugin Rules

- **Rule 30: Signal context pressure — don't silently degrade.** When the context window fills with file contents, tool results, and conversation history, say so explicitly rather than silently cutting corners. Long sessions are where discipline breaks down most. Context pressure is not permission to skip process steps — flag it instead of producing lower-quality output.
- **Rule 31: Diff rewrites against the original — verify nothing was dropped.** When rewriting, restructuring, or migrating a file, diff against the original to verify no content was silently lost. Complements Rule 26 (declare scope before building from references): Rule 26 prevents undeclared *additions*; Rule 31 prevents undeclared *omissions*.

Both rules originated from a parallel user's working-rules.md and were adopted into the official rule set after review confirmed they fill genuine gaps and apply universally.

### Backward Compatibility

- Existing v2.8.0 users without `user-rules.md`: `/rules` works exactly as before (searches only `working-rules.md`); next `/setup` run creates the user-rules.md template once.
- Pre-existing custom rules in `working-rules.md`: unaffected. The pointer at the top of `working-rules.md` documents where to put new custom rules going forward, but existing additions stay where they are unless the user chooses to migrate.

## [2.8.0] - 2026-04-15

### Added — Project-Specific Knowledge Tier (opt-in)

A new `projects/` tier in the knowledge folder for project-specific architecture decisions and patterns that don't yet warrant cross-project promotion. Sits between ephemeral memory files and cross-project knowledge in `approaches/`/`decisions/`/`rules/`. Validated by manual implementation in the maintainer's knowledge folder on 2026-04-15; this release formalizes the pattern as a first-class plugin feature.

**Opt-in default:** `projects_enabled: false`. Existing v2.7.x users see zero behavior change unless they opt in via `/setup`.

**Config schema (5 new fields)** — `projects_enabled`, `projects_list` (comma-separated `tag:path` pairs), `projects_remotes` (optional git-remote fallback), `projects_promotion_threshold` (default 2), `auto_load_project_context` (second opt-in for hook-driven session-start prompts).

**Setup skill (`/setup`)**
- New "Project tier scaffolding" sub-block in Step 3 — creates `projects/{tag}/{decisions,patterns}/` with auto-generated per-project READMEs from configured projects.
- Diff list updates in Step 4 — `projects/README.md` is plugin-managed (diffable on update); per-project READMEs and content under `projects/{tag}/**` are user-owned (never overwritten).
- Step 6 Advanced Options — new prompts for the 5 config fields with input validation (no `:` or `,` in tags).
- Existing-folder detection — auto-detects manually-created `projects/` folders during `/setup` re-run; auto-populates `projects_list` from detected subdirectories.

**Context skill (`/context`)** — when a query matches a project tag, also Globs `projects/{tag}/**/*.md` for project-specific files (excluding READMEs). Step 5 summary now groups results: "Project-specific" first, "Cross-project" second; empty project folders surfaced with informational note (Decision #8 — mention but don't nag).

**Extract skill (`/extract`)** — Step 0 detects current project from CWD via `kt_project_for_path` helper; Step 4 auto-prepends the project tag to backlog entry headers when CWD matches a configured project. Auto-tagging is a default, not an override (explicit project attribution from conversation context wins).

**Index skill (`/index`)** — Step 1 scans `projects/{tag}/**` in addition to cross-project tree; path-derived tag union (Decision #9 — files under `projects/cs-builder/` automatically carry the `cs-builder` tag even if not in YAML frontmatter); new Step 8d detects cross-project promotion candidates using filename/tag/title similarity heuristics; Step 9 enriches the Projects section with file counts, last-update dates, and promotion candidates list.

**Audit skill (`/audit-knowledge`)** — new Step 5e (Cross-Project Pattern Detection) mirrors `/index` Step 8d but runs an interactive promotion workflow: detects candidates, presents to user, synthesizes content from project-specific sources, writes the new cross-project file with `originally_at:` provenance frontmatter, and offers source-file disposition (default: stub-and-reference). Step 6 Category C routing biases toward project subfolders when item tags match configured projects. Step 7 validates the project subfolder exists in config when promoting; offers to add new projects on the fly.

**Hooks (double opt-in)**
- `session-start-check.sh` — when both `projects_enabled` AND `auto_load_project_context` are true AND CWD matches a configured project, suggests `/context {project}` to load project knowledge.
- `session-stop-check.sh` — when `projects_enabled` is true AND CWD matches a project, appends a 4th checklist item noting that `/extract` will auto-tag findings with the project tag.

**Provenance convention (`originally_at:`)** — when files are promoted/synthesized across the projects/ ↔ cross-project boundary, the new file gets a YAML frontmatter field documenting source(s). Greppable consolidation history that survives git history truncation.

**New shipped template** — `plugin/template/projects/README.md` documents the projects/ tier structure, promotion ladder (project → cross-project approach → universal rule), multi-project tagging convention, indexing behavior, and `originally_at:` provenance.

**Backward compatibility verified** — sandbox test suite confirms v2.7.x configs (no projects fields) load cleanly with all new vars defaulting safely; helper function returns empty when feature disabled; validation coerces malformed values to safe defaults.

### Changed
- `config.sh` — `KT_CONFIG` now uses `${VAR:-default}` override pattern (testability improvement; production callers see no behavior change).
- `context/SKILL.md` — "Index-only" rule replaced with explicit dual-source description (index for cross-project; filesystem for project tier).

### Documentation
- New `aria/project_knowledge_plan.md` — implementation plan with phase breakdown, key design decisions, and verification steps.
- New `aria/docs/plans/2026-04-15-project-specific-knowledge-feature.md` — companion design doc with architectural rationale, alternatives considered, and open questions.

## [2.7.5] - 2026-04-09

### Added
- CODEMAP-first enforcement — two mechanisms ensure CODEMAP.md is read before codebase exploration:
  - **SessionStart hook** detects CODEMAP.md files in project directories and reminds at session start.
  - **PreToolUse hook on Glob|Grep** fires once per project per session when exploring a directory that has a CODEMAP.md ancestor.

## [2.7.4] - 2026-04-09

### Added
- `/wrapup` skill — end-of-session handoff. Reviews session work, updates PROGRESS.md and CLAUDE.md if needed, prompts for commit, verifies next session can pick up cleanly, and prompts for `/extract`. Confirms before every write. Project-agnostic — detects project from cwd markers.

## [2.7.3] - 2026-04-09

### Added
- Rule 28 (concise, precise writing) — all communication should be semantically accurate, concise, and precise. Preserves detail and nuance while eliminating verbosity.

## [2.7.2] - 2026-04-09

### Added
- Rule 28 (template; renumbered to Rule 29 in v2.7.6) — evaluate tool cost before visual testing. Code-verifiable changes skip visual testing; unpredictable visual output warrants testing with user confirmation first.
- **Origin:** DOM reorder consumed ~15% session tokens on visual testing self-evident from the code diff.

## [2.7.1] - 2026-04-09

### Added
- Skill-to-knowledge connection discovery in `/index` (Step 8c) — scans plugin skill files and auto-discovers connections to knowledge files using 4 heuristics (explicit references, Related sections, name overlap, tag/keyword overlap). Stored in `## Skill Connections` section in `index.md`.
- Skill-knowledge drift detection in `/audit-knowledge` (Step 5b) — compares skill modification dates against connected knowledge file dates to flag when a skill evolves past its documentation.
- Index freshness check in `/audit-knowledge` (Step 1b) — verifies index.md is current before audit begins.

## [2.7.0] - 2026-04-09

### Added
- `/codemap` skill — generate feature-organized CODEMAP.md for any codebase. Scans repos, detects frameworks (Django, Next.js, Express, Rails, etc.), identifies features by clustering routes/models/views, traces full-stack flows per feature (frontend routes → hooks → Redux → backend views → models → integrations), and produces a navigable reference document
- Four codemap modes: `create` (full generation from scratch), `inventory` (quick index of files/routes/models), `update` (incremental refresh using git diff), `section` (rebuild a single section)
- Directory table at top of CODEMAP.md for selective section loading — new sessions read ~50 lines to orient, then load only relevant sections via offset/limit
- Mermaid diagrams for entity relationships (erDiagram), auth flows (flowchart), and dependency graphs (flowchart) — renderable in GitHub/Obsidian for team members
- Common Change Patterns section — "how to add X" procedural recipes per framework
- Integrations summary table — all external services with env keys and consuming features
- Build Log for tracking per-section completeness and staleness
- Security issues flagged inline at point of occurrence in feature sections
- Codemap staleness detection in `/audit-knowledge` (Step 5d) — scans for CODEMAP.md files, checks last-updated date against git changes, reports status (Current/Possibly stale/Stale)
- Codemap staleness findings in `/audit-knowledge` Step 6 report with token usage warning
- Codemap update guidance in `/audit-knowledge` Step 7 — directs users to run `/codemap update` in a separate session to avoid context blow-up

## [2.6.0] - 2026-04-07

### Added
- `/ask` skill — research a question, check existing knowledge first, save answer directly to promoted files (skips backlogs)
- `/intake` skill — bulk knowledge import from file paths, directories, glob patterns, or URLs with preview-before-staging and deduplication against existing knowledge
- Entity detection in `/index` (Step 8b) — scans promoted files for recurring proper nouns (tools, services, APIs) appearing in 2+ files, generates `## Entities` section in `index.md`
- Entity integrity checks in `/audit-knowledge` Step 5b — flags stale entity references and missing entities
- "Update existing" option in `/audit-knowledge` Step 7 — merge backlog items into existing promoted docs instead of always creating new files
- `digest-transcript.sh` — standalone script that extracts high-signal content from JSONL session transcripts (~1-2% of original token cost)
- `README.md` inside `plugin/` — usage-focused docs available when plugin is installed from marketplace
- `LICENSE` inside `plugin/` — CC BY-NC-SA 4.0 for marketplace requirement
- Discovery metadata in `plugin.json` — homepage, repository, license, keywords for marketplace searchability

### Changed
- `/audit-knowledge` Step 2d now runs transcript digest before reading pre-compact snapshots (default), reducing ~50K+ token reads to ~2-3K; use `detailed` flag for full review
- Session-start hook messages shortened ~50% across all 7 message types — collapsed redundant error branches into single flag-based pattern
- Session-stop hook shortened from ~100 to ~35 tokens
- Unregistered Stop hook from `plugin.json` — fired on every response (15-30 times per session), not just session end; `/extract` and PreCompact capture cover its checks. Script kept in `bin/` for optional re-enablement.

### Fixed
- Remove `category` field from `plugin.json` per validator warning (belongs in `marketplace.json`)

## [2.5.1] - 2026-04-07

### Fixed
- Register Stop hook in plugin.json — `session-stop-check.sh` was never executing (dead code)
- Guard empty `SESSION_ID` in task-context-check to prevent cooldown file collision across sessions
- Remove hardcoded `/Users/mikeprasad/Projects/CLAUDE.md` path from `/index` skill
- Fix `allowed-tools` frontmatter in `/help` skill (quoted empty string → bare empty)
- Use `mktemp` for temp files in task-context-check instead of predictable `$$` PID names
- Document intentional no-default for `KT_CRITICAL_PATHS` in config.sh

## [2.5.0] - 2026-04-07

### Added
- PreCompact hook — saves transcript snapshot to `intake/pre-compact-captures/` before context compaction, preserving knowledge that would otherwise be lost to summarization
- PostCompact hook — prompts user to review pre-compaction snapshots immediately after compaction
- TaskCreated hook — auto-context retrieval that matches task keywords against the tag index and surfaces relevant knowledge files with 30-second cooldown for batch creation
- `/clip` skill — quick-save URLs or text snippets to `intake/clippings/` without leaving the session
- `/stats` skill — read-only knowledge base health dashboard (file counts, backlog depth, audit status, tag stats, coverage gaps)
- `QUICKSTART.md` — concise "your first 3 sessions" guide for marketplace users
- First-run welcome message — friendly introduction on first session instead of audit prompts
- `auto_capture` config key (default: true) — gates all automatic features (pre-compact capture, post-compact prompt, task-created context retrieval)
- `critical_paths` config key (default: empty) — comma-separated path patterns that always require HIGH impact Rule 22 assessment
- `audit_cadence_update` config key (default: 30) — days between update check prompts, parsed from config file's own `/setup on` date
- `intake/pre-compact-captures/` directory in template structure
- `/help` skill — quick command reference table with descriptions for all available skills

### Changed
- `/setup` — new fields in cadence display (update check), advanced options (auto-capture, critical paths), config write, and verification
- `/audit-knowledge` — new Step 2d scans pre-compact captures for extractable knowledge, new Step 6 section presents findings
- `config.sh` — parses `audit_cadence_update`, `auto_capture`, and `critical_paths` with defaults and validation
- `session-start-check.sh` — first-run detection (skips audit prompts on fresh install), update check cadence using config file date
- `pre-edit-check.sh` — matches file paths against user-configured `critical_paths` patterns

## [2.4.0] - 2026-04-06

### Added
- `/index` skill — scans promoted knowledge files, normalizes tags, detects staleness, suggests cross-references between files with 2+ shared tags, updates project-to-tag mappings, and regenerates `index.md`
- `/context` skill — on-demand knowledge retrieval by topic tags with OR (default) and AND modes, project tag expansion (e.g., `/context ss` expands to all Seersite-relevant tags), summary-first presentation with selective file loading
- Tag convention — YAML frontmatter `tags: [tag1, tag2]` on all promoted knowledge files, with seeded known tags across tech domain, cross-cutting, tool/service, process, and project groups
- `index.md` generated artifact at knowledge folder root — tag-first index with Known Tags, Tag Index, Other Tags, Stale Files, and Untagged Files sections
- Staleness detection — flags promoted files not updated within configurable threshold (default: 6 months)
- Bidirectional cross-reference linking — `/index` suggests `## Related` links between files sharing 2+ tags, detects reverse link gaps
- Session-start knowledge surfacing — hook prompts Claude to suggest `/context` command after user states their task (when index exists)
- Planning path abbreviated Rule 22 — `pre-edit-check.sh` and `post-edit-check.sh` hook scripts detect `docs/specs/` and `docs/plans/` paths and allow one-line assessment instead of full framework, with protected filename safeguard for operational files (CLAUDE.md, working-rules.md, etc.)
- `freeform_promotion_threshold` config key (default: 3) — suggest promoting freeform tags to known after this many files
- `staleness_threshold_months` config key (default: 6) — flag knowledge files older than this

### Changed
- `/audit-knowledge` — new Step 5c cross-references backlog entries against promoted docs (topic overlap and potential invalidation detection), new Step 6 sections for Stale Knowledge and Cross-Reference Findings, new Step 7b rebuilds index after promotions
- `/setup` — offers advanced options for freeform promotion threshold and staleness threshold
- `plugin.json` hooks — PreToolUse and PostToolUse now use bash scripts (`pre-edit-check.sh`, `post-edit-check.sh`) instead of inline echo commands, enabling planning path detection
- `config.sh` — parses `freeform_promotion_threshold` and `staleness_threshold_months` with defaults and numeric validation
- `LOCAL.md` template — format templates now include `tags:` in frontmatter, new Tag Convention section, `/context` and `/index` added to When to Read table
- `README.md` template — `index.md` in structure diagram, tagging and index conventions added

## [2.3.2] - 2026-04-06

### Added
- `intake/clippings/`, `intake/notes/`, `intake/attachments/` subdirectories in template — new users now get the full content capture structure on `/setup`
- "Extended Structure" example section in `LOCAL.md` template — shows users how to document custom subdirectory organization
- Comprehensive feature list in README
- Obsidian Web Clipper recommendation in README and OVERVIEW template
- Support section with PayPal and Venmo in README
- Release download link in install instructions

### Changed
- Removed `setup_version` from config template (unused field)

### Fixed
- Documented known Claude Code "hook error" UI bug (anthropics/claude-code#17088) in README and OVERVIEW template

## [2.3.0] - 2026-04-05

### Added
- `OVERVIEW.md` template — full design philosophy and rationale, shipped with plugin
- `## Related` cross-references in `enforcement-mechanisms.md` template
- `OVERVIEW.md` added to `/setup` expected files and diff lists
- Project moved to standalone repository (`Projects/aria/`)

### Changed
- `README.md` template now references `OVERVIEW.md`

## [2.0.0] - Previous

- Initial versioned release with setup wizard, extraction, audits, backlogs, rules lookup
- Rule 22 enforcement hooks (PreToolUse/PostToolUse)
- Session start/stop hooks
- Knowledge folder templating system
