# Changelog

All notable changes to ARIA will be documented in this file.

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
