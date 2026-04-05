# ARIA — Anchored Reasoning and Insight Architecture

A structured knowledge management plugin for Claude Code. Captures what you learn during AI-assisted development sessions, stages it for review, and promotes validated knowledge into durable, findable documents.

## The Problem

Every time an AI session ends, context disappears. Insights, decisions, and corrections vanish into compacted conversation history. ARIA gives that knowledge a durable home.

## How It Works

Knowledge moves through a pipeline: **Capture → Review → Promote**

- **Capture** — Session hooks and `/extract` catch insights, decisions, and feedback as they happen
- **Review** — Configurable audit cadences surface what's worth keeping vs. what's noise
- **Promote** — You decide what becomes canonical. Nothing is auto-promoted.

The plugin also enforces structured decision-making at the point of code changes (Rule 22), making the reasoning process visible and auditable.

## Features

- Configure knowledge folder location, structure, and audit cadences via `/setup`
- Validate folder structure against template and create missing directories/files
- Diff managed files against plugin version on setup, with keep/update/show-diff options
- Detect and check for companion plugin dependencies (explanatory-output-style)
- Scan conversations for uncaptured insights, decisions, feedback, project context, and references via `/extract`
- Deduplicate extracted knowledge against existing backlog entries
- Stage all captured knowledge in backlogs for human review — nothing is auto-promoted
- Review backlogs and memory files for promotable knowledge via `/audit-knowledge`
- Categorize findings as already-captured, implementation-specific, or worth-extracting
- Detect emerging themes across backlog entries that individually don't justify a doc but together reveal a pattern
- Scan CLAUDE.md files, configs, and docs for drift, broken references, and staleness via `/audit-config`
- View and manage pending items across all three backlogs via `/backlog`
- Quick lookup into working rules by number or keyword via `/rules`
- Check audit cadences at session start and prompt when knowledge or config review is overdue
- Enforce structured change decision framework (Rule 22) before every Edit/Write — requires visible impact assessment, alternatives analysis, and scope definition
- Classify changes as HIGH or LOW impact with format-specific reasoning requirements
- Flag changes that fail validation or exceed declared scope, with proposed next steps
- Verify scope after every Edit/Write — checks for extra changes, unnecessary rewrites, and secondary impact on parents/siblings/dependents
- Prompt for knowledge capture before session ends
- Ship 24 living working rules governing coding, architecture, and development decisions
- Ship a 7-step change decision framework with real examples and hook configuration
- Ship enforcement mechanisms documentation covering soft (prompt-driven) through hard (system-level) enforcement layers
- Provide cross-references between related rule files
- Create and maintain 11-directory taxonomy for organizing knowledge by type (rules, approaches, decisions, guides, references, archive, intake with notes/attachments/clippings, logs)
- Ship user-owned templates for project-specific conventions and directory stubs
- Maintain audit logs tracking when reviews ran and what they found
- Store configuration in `~/.claude/aria-knowledge.local.md` readable by hook scripts
- Work with Obsidian as a vault, including Web Clipper integration for `intake/clippings/`

## Install

### CLI

1. Copy the `plugin/` directory to your Claude Code plugins folder
2. Run `/setup` to configure your knowledge folder
3. Start working — the plugin captures knowledge automatically

### Desktop / IDE

1. Download the latest zip from [Releases](https://github.com/mikeprasad/aria-knowledge/releases)
2. In Claude Code, go to **Customize > Add Plugin > Local** and select the downloaded zip
3. Run `/setup` to configure your knowledge folder

## Works Well With Obsidian

The knowledge folder is plain markdown — it works great as an Obsidian vault. We recommend using [Obsidian Web Clipper](https://obsidian.md/clipper) to save articles and references directly into `intake/clippings/`, where ARIA's audit process can review and promote them.

## Philosophy

ARIA takes the position that **the LLM captures, the human promotes.** AI is excellent at noticing and structuring knowledge during sessions. But deciding what's load-bearing vs. noise requires human judgment.

See [plugin/template/OVERVIEW.md](plugin/template/OVERVIEW.md) for the full design rationale.

## Known Issues

- **"hook error" label on Pre/PostToolUse hooks** — Claude Code displays "hook error" next to every tool call that triggers a hook, even when the hook exits successfully (exit code 0) with valid JSON output. This is a [known Claude Code UI bug](https://github.com/anthropics/claude-code/issues/17088) — the Rule 22 enforcement hooks are working correctly. The label is cosmetic and does not indicate a problem with ARIA.

## License

[CC BY-NC-SA 4.0](LICENSE) — Free to use and modify. Must be attributed, non-commercial, and derivatives must share alike.

## Support

If ARIA is useful to you, consider buying me a coffee via PayPal (mikeprasad@gmail.com) or [Venmo](https://venmo.com/mikeprasad).
