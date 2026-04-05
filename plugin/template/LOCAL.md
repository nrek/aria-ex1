# Knowledge Repository — Local Guide

Project-specific conventions, format templates, and usage details that extend the base [README.md](README.md). This file is yours — the aria-knowledge plugin will never overwrite it.

**Last updated:** (update when you edit this file)

## Extended Structure

<!-- Document any subdirectories or conventions you add beyond the base structure.
     Example: if you create guides/claude/ for Claude Code-specific docs, note it here
     so future sessions know where to look. -->

```
knowledge/
├── ...                              # (base structure — see README.md)
├── guides/
│   └── your-topic/                  # Group related guides into subdirectories
├── intake/
│   ├── clippings/                   # Web articles, threads, saved content
│   ├── notes/                       # Quick notes and observations
│   └── attachments/                 # Images, PDFs, supporting files
└── references/
    └── ...                          # Research papers, external docs
```

## Format Templates

### Approaches (`approaches/`)

```markdown
# [Approach Name]

**Last updated:** YYYY-MM-DD

## When to Use
[Conditions where this approach applies]

## When NOT to Use
[Conditions where this approach is wrong or doesn't apply]

## The Approach
[Description with examples]

## Validated By
[Project/session where this was tested and confirmed]

## Related
[Links to related rules, decisions, or other approaches]
```

### Decisions (`decisions/`)

```markdown
# [Number] — [Title]

**Status:** Accepted | Superseded | Deprecated
**Date:** YYYY-MM-DD

## Context
[What prompted this decision]

## Decision
[What we decided]

## Alternatives Considered
[What else we evaluated and why it was rejected]

## Consequences
[What this means going forward]

## Related
[Links to related rules, approaches, or other decisions]
```

### Guides (`guides/`)

```markdown
# [Guide Title]

**Last updated:** YYYY-MM-DD

## Overview
[What this guide covers and who it's for]

## [Sections as needed]
[Content organized by topic]

## Related
[Links to related guides, approaches, or references]
```

## What Belongs Where

| Content | Location | Reason |
|---------|----------|--------|
| Principles and constraints | `rules/` | "We must / must not" |
| Validated methodologies | `approaches/` | "How we do X (proven)" |
| Architectural choices | `decisions/` | "We chose X because Y" |
| Operational knowledge | `guides/` | "Here's how X works" |
| External research | `references/` | "What others say about X" |
| Retired content | `archive/` | "What we used to do" |
| Unprocessed input | `intake/` | "Not yet categorized" |
| Project-specific context | Project's CLAUDE.md | Loaded automatically per project |
| Session history | Project's PROGRESS.md | Ephemeral project state |

## What Does NOT Belong Here

- Code snippets or implementation details (those belong in the codebase)
- Ephemeral task context (use PROGRESS.md or session notes)
- Opinions without validation (approaches must be tested)
- Duplicated content from CLAUDE.md files (reference, don't copy)

## When to Read

Add your own "When to Read" mappings as your knowledge base grows:

| Scenario | Read |
|----------|------|
| Starting any session | `rules/working-rules.md` (or summary in your project's CLAUDE.md) |
| Before a code change triggers the Rule 22 hook | `rules/change-decision-framework.md` |
| Designing a new enforcement mechanism | `rules/enforcement-mechanisms.md` |
| *(add your own rows as your knowledge base grows)* | |

## Adding New Knowledge

1. Determine the right category (rules, approaches, decisions, guides, references)
2. Check if an existing file should be updated rather than creating a new one
3. Use the format template above for the category
4. Review with your team before committing

## How New Knowledge Files Emerge

The `intake/` backlogs are staging areas and signal generators. Over time, multiple backlog entries may cluster around a theme — repeated insights about the same problem space, or several related decisions that share underlying principles.

During the knowledge audit (`/audit-knowledge`), look for these clusters:

- **Multiple insights on the same topic** → may warrant a new approach or guide
- **Multiple decisions with shared rationale** → may warrant an approach documenting the pattern
- **Recurring feedback corrections** → may warrant a new rule

Not every insight becomes a knowledge file — but patterns of insights do.
