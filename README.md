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

## What's Included

- **6 skills:** `/setup`, `/extract`, `/audit-knowledge`, `/audit-config`, `/backlog`, `/rules`
- **Session hooks:** Start (audit cadence checks), Pre/Post edit (decision framework), Stop (knowledge capture)
- **Knowledge templates:** Working rules, change decision framework, enforcement mechanisms, and folder structure for organizing rules, approaches, decisions, guides, and references

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

## License

[CC BY-NC-SA 4.0](LICENSE) — Free to use and modify. Must be attributed, non-commercial, and derivatives must share alike.

## Support

If ARIA is useful to you, consider buying me a coffee via PayPal (mikeprasad@gmail.com) or [Venmo](https://venmo.com/mikeprasad).
