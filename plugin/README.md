# aria-knowledge

Structured knowledge management for Claude Code. Captures session knowledge, enforces decision frameworks, and promotes validated insights into durable, findable documents.

**Knowledge Lifecycle** — auto capture, staging, review, promotion, staleness, archival. Pipeline from raw signal to validated knowledge.

**Decision Discipline & Enforcement** — decision-making rules, change framework, pre/post hooks, impact classification, scope verification, planning path abbreviation. Hook-enforced active application.

**Contextual Retrieval & Indexing** — tag index, /context with project expansion, /index with cross-reference suggestions, session-start surfacing, bidirectional linking. The right knowledge for each session at the right time.

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
| `/clip [url/text]` | Quick-save a URL or snippet to intake |
| `/intake [path/url]` | Bulk import knowledge from files, directories, or URLs |
| `/help` | Command reference |

## How It Works

**Capture** — Session hooks and `/extract` catch insights, decisions, and feedback as they happen.
**Review** — Configurable audit cadences surface what's worth keeping.
**Promote** — You decide what becomes canonical. Nothing is auto-promoted.

## License

CC BY-NC-SA 4.0 — See [LICENSE](LICENSE) for details.
