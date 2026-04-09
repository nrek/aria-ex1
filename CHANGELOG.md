# Changelog

All notable changes to ARIA will be documented in this file.

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
