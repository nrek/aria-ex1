# CLAUDE.md — ARIA

## What This Is

ARIA (Anchored Reasoning and Insight Architecture) — a Claude Code plugin for structured knowledge management. Captures session knowledge, enforces decision frameworks, and promotes validated insights into durable documents.

## Project Structure

```
aria/
├── README.md          ← GitHub-facing intro
├── LICENSE            ← CC BY-NC-SA 4.0
├── CHANGELOG.md       ← Version history
├── CLAUDE.md          ← You are here
├── plugin/            ← The installable plugin
│   ├── .claude-plugin/
│   │   └── plugin.json
│   ├── bin/           ← Hook scripts (bash)
│   ├── skills/        ← Skill definitions (SKILL.md files)
│   └── template/      ← Knowledge folder templates
└── docs/              ← Extended documentation (future)
```

## Key Conventions

- **`plugin/` is the installable unit** — everything inside it is what users copy to their plugins directory
- **Template files** in `plugin/template/` are either plugin-managed (diffable on `/setup`) or user-owned (created once, never overwritten). See `plugin/skills/setup/SKILL.md` for the authoritative list.
- **Version** lives in `plugin/.claude-plugin/plugin.json`
- **Hook scripts** in `plugin/bin/` are bash — they read config from `~/.claude/aria-knowledge.local.md`
- **Skills** are markdown files — each skill is a `SKILL.md` with YAML frontmatter

## Development Workflow

1. Edit files in `plugin/`
2. To test, copy `plugin/` to `~/.claude/plugins/marketplaces/local-desktop-app-uploads/aria-knowledge/`
3. Restart Claude Code to pick up changes

## Rules

- Follow the universal rules in `Projects/CLAUDE.md`
- The plugin's own template content (working-rules, change-decision-framework, enforcement-mechanisms) is both shipped content AND documentation of how the plugin works — edits to these have dual impact
- Bump version in `plugin.json` when making release-worthy changes
