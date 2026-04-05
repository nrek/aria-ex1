# Changelog

All notable changes to ARIA will be documented in this file.

## [2.3.1] - 2026-04-06

### Added
- Known Issues section in README documenting the Claude Code "hook error" UI bug (anthropics/claude-code#17088)
- Note in OVERVIEW.md template hooks section about the same cosmetic display issue

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
