# aria-knowledge

An active knowledge and development discipline plugin for Claude Code. Captures session knowledge, enforces structured decisions, and maps codebases — so each session builds on the last.

**Knowledge Lifecycle** — capture, stage, review, promote. Insights flow into backlogs during sessions. You decide what becomes canonical.

**Decision Discipline** — change decision framework enforced at every file edit via hooks. Impact assessment, alternatives analysis, scope verification.

**Understanding & Retrieval** — tag index, contextual retrieval with project expansion, cross-reference suggestions, session-start surfacing, bidirectional linking. Feature-organized codebase maps with full-stack flow tracing, framework detection, and staleness tracking.

## Quick Start

1. Run `/setup` to configure your knowledge folder
2. Start working — hooks capture knowledge automatically
3. Run `/extract` after tasks to save insights
4. Run `/audit-knowledge` to review and promote

See [QUICKSTART.md](QUICKSTART.md) for a detailed walkthrough of your first 3 sessions.

## Commands

| Command | Description |
|---------|-------------|
| `/setup` | Configure knowledge folder and plugin settings |
| `/extract` | Capture insights and decisions from the current conversation |
| `/audit-knowledge` | Review backlogs and promote to knowledge files |
| `/audit-config` | Check configs and docs for drift |
| `/context [tags]` | Load relevant knowledge by topic |
| `/index` | Rebuild the tag-based knowledge index |
| `/rules [number]` | Look up a working rule |
| `/backlog [type]` | View pending intake items |
| `/stats` | Knowledge base health dashboard |
| `/ask [question]` | Research a question, save answer as a knowledge doc |
| `/clip [url/text]` | Quick-save a URL or snippet to intake |
| `/intake [path/url]` | Bulk import knowledge from files, directories, or URLs |
| `/codemap [mode]` | Generate or update a feature-organized codebase map (create/inventory/update/section) |
| `/wrapup` | End-of-session handoff — update PROGRESS.md/CLAUDE.md/memory, commit, extract |
| `/help` | Command reference |

## How It Works

**Capture** — Session hooks and `/extract` catch insights, decisions, and feedback as they happen.
**Review** — Configurable audit cadences surface what's worth keeping.
**Promote** — You decide what becomes canonical. Nothing is auto-promoted.

## License

CC BY-NC-SA 4.0 — See [LICENSE](LICENSE) for details.
