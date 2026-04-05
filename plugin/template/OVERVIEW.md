# ARIA Knowledge

**Anchored Reasoning and Insight Architecture**

A structured knowledge management system for AI-assisted development. Built for teams that use Claude Code (or similar AI coding tools) and want to stop losing what they learn between sessions.

## The Problem

Every time an AI session ends, context disappears. Your insights, decisions, and corrections vanish into compacted conversation history. The next session starts from scratch — or worse, repeats the same mistakes you already corrected.

Over time, valuable knowledge accumulates in scattered places: CLAUDE.md files, auto-memory, session plans, Slack threads, mental notes. Some of it contradicts other parts of it. None of it gets reviewed. The knowledge that matters most — the hard-won lessons from debugging, the architectural decisions made under pressure, the feedback you gave three sessions ago — has no durable home.

This isn't a tooling problem. It's a knowledge lifecycle problem. You need a system that captures knowledge when it's fresh, stages it for review, and promotes the good stuff into durable, findable documents — while letting the rest fade naturally.

## The Approach

Knowledge Repository treats knowledge like code: it moves through a pipeline with clear stages, review gates, and promotion criteria.

### Capture

During work sessions, knowledge is captured automatically and on-demand:

- **Insight blocks** surface non-obvious technical observations as they happen
- **Extraction** (`/extract`) scans conversations before context compaction destroys them, dumping findings into staging backlogs
- **Session cleanup** prompts you to capture decisions and insights before ending a session

Nothing captured at this stage is canonical. It's raw signal waiting for review.

### Review

On a configurable cadence, the knowledge audit (`/audit-knowledge`) scans your backlogs, memory files, and plans. It categorizes everything it finds:

- **Already captured** — knowledge that's already in your docs or CLAUDE.md files
- **Implementation-specific** — session plans, debug steps, one-time fixes (valuable in the moment, not reusable)
- **Worth extracting** — validated approaches, cross-project decisions, patterns that will save time next month

The audit also detects **emerging themes** — clusters of related insights that individually don't justify a knowledge file but together reveal a pattern worth documenting. This is how the knowledge base grows organically rather than through forced curation.

Nothing gets promoted without your explicit approval.

### Promote

Approved knowledge moves to its permanent home based on what type it is. Each type has a specific purpose, format, and location:

| Type | Purpose | Example |
|------|---------|---------|
| **Rules** | Principles and constraints that govern how you work | "Decisions must be logically justified" |
| **Approaches** | Validated methodologies confirmed through real use | "How we structure Linear tickets" |
| **Decisions** | Architectural choices with context, alternatives, and consequences | "We chose cursor pagination over offset" |
| **Guides** | Operational knowledge about how things work in your environment | "How to set up Claude Code for the team" |
| **References** | External research, evaluations, and bookmarked resources | "Stripe vs Paddle comparison" |

This taxonomy is complete — every type of reusable knowledge fits into exactly one category. If it doesn't fit any of them, it's either ephemeral (belongs in session notes) or not yet validated (stays in the backlog until it is).

## The Plugin

Knowledge Repository is powered by **aria-knowledge**, a Claude Code plugin that automates the capture-review-promote lifecycle.

### Skills

| Skill | What it does |
|-------|-------------|
| `/setup` | Configure your knowledge folder, validate structure, set audit cadences |
| `/extract` | Scan the current conversation for uncaptured knowledge and dump it to backlogs |
| `/audit-knowledge` | Review backlogs and memory for promotable knowledge, detect themes, present findings |
| `/audit-config` | Check CLAUDE.md files, configs, and docs for drift, broken references, and staleness |
| `/backlog` | View and manage pending items across all backlogs |
| `/rules` | Quick lookup into your working rules by number or keyword |

### Hooks

The plugin includes hooks that fire automatically during sessions:

- **Session start** checks audit cadences and prompts when reviews are overdue
- **Pre-edit** enforces structured decision-making before every code change (impact assessment, alternatives considered, scope defined)
- **Post-edit** verifies that changes stayed within the decided scope
- **Session end** prompts for knowledge capture before context is lost

The pre/post edit hooks implement a change decision framework that prevents common failure modes: rewriting code that should have been extended, touching files outside the decision scope, skipping alternatives analysis. The enforcement is prompt-based — it shapes reasoning at the moment of action rather than blocking execution.

> **Note:** Claude Code displays a "hook error" label next to tool calls that trigger these hooks. This is a [known Claude Code UI bug](https://github.com/anthropics/claude-code/issues/17088) — the hooks exit successfully and work correctly. The label is cosmetic.

### Enforcement Philosophy

The plugin uses a layered enforcement model, from softest to hardest:

1. **CLAUDE.md rules** — loaded at session start, set expectations
2. **Hook prompts** — injected at tool boundaries, enforce process at the point of action
3. **Required output format** — forces every reasoning step to be visible and auditable
4. **Permission deny lists** — hard blocks for operations that should never happen

Most enforcement lives at layers 2-3. The goal isn't to prevent mistakes through restriction — it's to make the decision process visible so mistakes are caught before they're committed.

## Design Principles

### Opinionated defaults, easy customization

The plugin ships with a complete set of working rules, a change decision framework, and enforcement mechanisms. These are real rules refined through real projects — not generic placeholders. You can use them as-is, modify them, or replace them entirely. The `/setup` wizard diffs your files against new plugin versions so you can selectively adopt updates.

### Human review gates

Nothing is auto-promoted. Extraction dumps to backlogs; audits present findings; you decide what to keep. This prevents knowledge base bloat and ensures everything that gets promoted has been validated by a human.

### Signal accumulation over forced curation

Individual insights rarely justify a standalone document. But patterns of insights do. The audit process watches for thematic clusters across backlog entries and proposes synthesis documents when evidence reaches a threshold. Knowledge files emerge from accumulated evidence, not from premature formalization.

### Stable identifiers

Rules use permanent numeric IDs — they're never renumbered. When a rule is retired, it keeps its number and gets marked `[RETIRED]`. This prevents reference drift across the many files that cite rule numbers.

### Archive, don't delete

When knowledge is superseded, the old version moves to `archive/` with a pointer from the original location. Nothing is lost, and the decision trail remains auditable.

## Why Human-Anchored Knowledge

LLMs have an extraordinary ability to intake, synthesize, and organize information at scale. This is genuinely powerful — and it's the basis for approaches like Andrej Karpathy's "LLM Knowledge Base" pattern, where the LLM acts as a librarian that compiles raw sources into a structured wiki, maintains it through linting passes, and surfaces connections across hundreds of documents. In that model, "you rarely ever write or edit the wiki manually; it's the domain of the LLM."

That approach works well for **research and exploration** — domains where breadth matters, where false connections are cheap to discard, and where the goal is surfacing patterns across large bodies of information. The LLM's ability to read everything and find non-obvious links is genuinely its superpower.

But operational knowledge is different.

When you're building software with a team, the knowledge that governs your work — your rules, your architectural decisions, your validated approaches — has consequences. A wrong rule gets enforced on every edit. A bad architectural decision shapes months of implementation. An inaccurate guide sends a new team member down the wrong path. The cost of a false positive in your operational knowledge base isn't "oh, that connection wasn't useful" — it's real work built on a wrong foundation.

This is the core problem with LLM-compiled knowledge for operational use: **LLMs are confident synthesizers, not reliable validators.** They will find patterns, write articulate summaries, and create convincing connections — even when the underlying observation was a one-time anomaly, a misunderstood edge case, or an outdated practice. At research scale, this is noise that washes out. At operational scale, it becomes load-bearing misinformation.

Knowledge Repository takes a different position: **the LLM captures, the human promotes.**

The intake pipeline is deliberately broad — insights, decisions, feedback, project context, and references all flow into backlogs during work sessions. The LLM is excellent at this: noticing what was discussed, structuring it consistently, deduplicating against what's already captured. This is high-volume, low-stakes work where LLM judgment is reliable.

But the promotion boundary — where something moves from "captured observation" to "canonical knowledge that shapes future work" — requires human judgment. Not because the LLM can't write a convincing rule, but because it can't reliably distinguish between:

- A pattern that worked once vs. a pattern that should be applied everywhere
- A decision that was contextually correct vs. a decision that should set precedent
- An observation that was insightful vs. an observation that was coincidental

This makes the system slower than a fully LLM-maintained wiki. Backlogs accumulate. Reviews happen on a cadence, not in real-time. Knowledge files emerge over days and weeks, not minutes.

But what gets promoted is **anchored** — validated by someone who understands the operational context, who knows which observations are load-bearing and which are noise, who can judge whether a pattern from Project A actually applies to Project B.

But human review alone isn't enough either. Humans bring their own biases — intuition that feels right but isn't validated, preferences mistaken for principles, decisions driven by familiarity rather than merit. The system accounts for this too: **both the LLM and the human can be wrong.**

This is why the change decision framework exists. Before any change, the LLM must identify alternatives, present them with objective criteria, and rank options with explicit reasoning — not just execute the first idea. The human reviews the analysis, not a recommendation served on a platter. Decisions must be logically or empirically justified, not just intuitively appealing. The framework enforces this at the tool boundary: every edit requires a visible impact assessment, and every assessment requires options considered.

The result is a system where the LLM's breadth of intake is filtered through structured analysis, and the human's contextual judgment is anchored by objective criteria. Neither party gets to shortcut the process.

Both systems contain knowledge. The difference is what the knowledge is organized for.

Karpathy's system is a **library** — an AI librarian that organizes, indexes, cross-references, and surfaces connections across a growing collection of documents. Its knowledge is organized for **exploration**: making information findable, revealing non-obvious relationships, scaling to large bodies of research. You go to it when you need to understand a topic. The more it knows, the better it works.

Knowledge Repository is closer to a **trained mind**. It also holds knowledge — rules, approaches, decisions, guides — but that knowledge is organized for **execution**. The rules encode how you think about changes. The decision framework structures how you evaluate options. The enforcement hooks embed that discipline into the moment of action, not just the moment of reflection. The more validated it is, the better it works.

In technical terms: Karpathy's system builds a **knowledge graph** — a rich model of a domain optimized for retrieval and connection. Knowledge Repository builds an **inference engine** — a system of validated rules and decision patterns optimized for making correct choices under real constraints. Both contain knowledge, but one measures success by "did I find the right information?" and the other by "did I make the right decision?"

Consider two surgeons. One has read every paper on a procedure — she can cite studies, compare techniques, explain the history of each approach. Her knowledge is organized for understanding. The other has performed the procedure a hundred times and learned from each outcome — she knows that when she sees a particular complication, she does this specific thing, because the last three times she tried the alternative, it failed. Her knowledge is organized for action. Both surgeons are knowledgeable. But you want the second one in the operating room.

The tradeoff is explicit: **breadth and speed for accuracy and trust.** In a research context, you'd choose the library. In an operational context — where your knowledge base actively shapes how code gets written, decisions get made, and teams get onboarded — you'd choose the trained mind.

Crucially, the trained mind **develops with the user.** Rules emerge from real mistakes — when something fails, the system captures why and encodes the lesson so it doesn't repeat. Feedback corrections compound across sessions. The decision framework gets sharper through use as edge cases get documented and patterns get validated. Over time, the system becomes more reliable and more contextually accurate, not just larger. It's an expert system that grows expertise, not just volume.

And the two approaches aren't competing — they're complementary. You can use Karpathy's pattern, Obsidian Web Clipper, or any research tool to build broad topical knowledge, then feed the valuable parts into `intake/clippings/` or `references/` for this system to review, validate, and promote. The library feeds the mind. Research exploration generates raw signal; the knowledge repository filters it into operational knowledge you can build on.

Neither system is universally better. They solve different problems. The question is whether you need to explore a topic, or execute on one.

## Getting Started

1. Install the aria-knowledge plugin in Claude Code
2. Run `/setup` to configure your knowledge folder and preferences
3. Start working — the plugin captures knowledge automatically via hooks
4. Run `/extract` when you finish a task or before switching context
5. Run `/audit-knowledge` when prompted (or any time) to review and promote

The knowledge folder is plain markdown — it works great as an [Obsidian](https://obsidian.md) vault. We recommend using [Obsidian Web Clipper](https://obsidian.md/clipper) to save articles and references directly into `intake/clippings/`, where ARIA's audit process can review and promote them.

See [README.md](README.md) for the folder structure, conventions, and operational details. See [LOCAL.md](LOCAL.md) for format templates and detailed usage guidance.
