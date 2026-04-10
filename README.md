# ARIA — Anchored Reasoning and Insight Architecture

ARIA is a Claude Code plugin that gives AI coding sessions persistent memory and structured discipline. It manages a complete knowledge lifecycle — capturing insights, decisions, and feedback during sessions, staging them in backlogs for human review, and promoting what matters into a searchable, tag-indexed knowledge base. Session hooks prevent knowledge loss during context compaction, surface relevant knowledge when tasks are created, and enforce a change decision framework at every file edit, requiring visible impact assessment and scope verification before and after changes. The result is that each session builds on the last instead of starting from scratch.

Beyond knowledge capture, ARIA provides active tooling for codebase understanding and session workflow. `/codemap` generates feature-organized maps that trace full-stack flows across entire repositories. `/ask` researches questions and saves answers directly as knowledge docs. `/intake` bulk-imports from files, URLs, or directories. `/audit-config` and `/audit-knowledge` detect drift, staleness, and gaps on configurable cadences. `/wrapup` handles end-of-session handoff — updating progress files, prompting for commits, and ensuring the next session can pick up cleanly. Everything is plain markdown, works as an Obsidian vault, and follows a core philosophy: the AI captures, the human promotes.

## How It Works

### Knowledge Lifecycle

Knowledge moves through a pipeline: **Capture → Review → Promote.**

- `/extract` — Scan conversations for uncaptured insights, decisions, feedback, and references. Deduplicates against existing entries.
- `/clip` — Quick-save URLs or text snippets to intake without leaving the session.
- `/ask` — Research a question, check existing knowledge first, save the answer directly as a knowledge doc.
- `/intake` — Bulk import from files, directories, or URLs with preview before staging.
- `/backlog` — View and manage pending items across all three backlogs.
- `/audit-knowledge` — Review backlogs and memory for promotable knowledge. Detects emerging themes across entries. Checks codemap staleness.
- `/index` — Rebuild the tag index. Normalizes tags, flags untagged files, suggests cross-references, updates project mappings.
- `/context` — Load relevant knowledge by topic using the tag index with project expansion.
- `/rules` — Quick lookup into the 24 working rules by number or keyword.
- `/stats` — Knowledge base health dashboard — file counts, backlog depth, audit status, tag coverage, gaps.

### Decision Discipline

A change decision framework (Rule 22) is enforced at every Edit/Write via hooks.

- **PreToolUse hook** — Before every file edit: assess impact (HIGH/LOW), state alternatives considered, define scope.
- **PostToolUse hook** — After every edit: verify scope wasn't exceeded, check for secondary impact on parents/siblings/dependents.
- Configurable critical paths that always require full impact assessment.
- Ships 24 working rules, a 7-step change decision framework with real examples, and enforcement mechanisms documentation.

### Codebase Understanding

`/codemap` generates feature-organized reference documents from any repository.

- Scans repos, detects frameworks, traces full-stack flows (routes → hooks → state → views → models → integrations).
- Four modes: `create` (full generation), `inventory` (quick index), `update` (incremental via git diff), `section` (rebuild one section).
- Produces navigable CODEMAP.md with a directory table for selective section loading.
- **PreToolUse hook** on Glob/Grep — Reminds to check CODEMAP.md before exploring a codebase directly.

### Session Workflow

Hooks and skills that keep sessions continuous across compaction and between conversations.

- `/wrapup` — End-of-session handoff: reviews work, updates PROGRESS.md/CLAUDE.md/memory, prompts for commit and `/extract`, verifies the next session can pick up.
- `/setup` — Configure knowledge folder, validate structure, diff managed files against plugin version, detect companion plugins.
- `/audit-config` — Scan CLAUDE.md files, configs, and docs for drift, broken references, and staleness.
- `/help` — Quick command reference.
- **SessionStart hook** — Checks audit cadences, prompts when review is overdue. First-run welcome for new users. Periodic update check.
- **PreCompact hook** — Saves transcript snapshot before context compaction.
- **PostCompact hook** — Prompts to review captured snapshot after compaction.
- **TaskCreated hook** — Surfaces relevant knowledge files when tasks are created (tag index matching).
- `auto_capture` toggle gates all automatic features.

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
