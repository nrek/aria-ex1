---
description: "Extract uncaptured knowledge from the current conversation before it's lost to compaction. Use after completing a task, before switching context, before large exploratory work (multi-file reads, codebase scans), or when the user signals session end. Trigger: '/extract', 'extract knowledge', 'capture session knowledge'. Also prompt mid-session: 'Task complete — want me to run /extract?' and 'Switching context — want me to run /extract first?'"
argument-hint: ""
allowed-tools: Read, Glob, Grep, Write, Edit
---

# /extract — Pre-Compaction Knowledge Extraction

Scan the current conversation since the last extraction for uncaptured insights, decisions, feedback, project context, and references. Dump everything to backlogs for review at the next knowledge audit. No confirmation dialog — just scan, deduplicate, and append.

## Step 0: Resolve Config

Read `~/.claude/aria-knowledge.local.md` and extract `knowledge_folder`. If the file doesn't exist, stop: "aria-knowledge is not configured. Run /setup to get started."

Use `{knowledge_folder}` as the base path for all file operations in subsequent steps.

## Step 1: Determine Extraction Scope

Check if a previous extraction happened this session by looking for a timestamp marker. If this is the first extraction of the session, scan the entire conversation. If a previous extraction occurred, scan only from that point forward.

The timestamp is tracked as the last entry date in the backlogs from this session — check the most recent entry dates in:
- `{knowledge_folder}/intake/insights-backlog.md`
- `{knowledge_folder}/intake/decisions-backlog.md`
- `{knowledge_folder}/intake/extraction-backlog.md`

If no entries exist from today's date, treat the entire conversation as unscanned.

## Step 2: Scan Conversation for Uncaptured Knowledge

Review the conversation and categorize findings into five buckets:

### Insights
- Insight blocks that were output but NOT yet appended to `insights-backlog.md`
- Non-obvious technical observations discussed in conversation
- Patterns discovered during debugging or exploration
- Codebase behaviors that surprised either party

### Decisions
- Architectural or design choices made during the session
- Technology or approach selections with rationale
- Cross-project decisions that set precedents
- Scope decisions (what was included/excluded and why)

### Feedback
- Corrections from the user ("don't do X", "that's wrong", "not like that")
- Confirmed approaches ("yes exactly", "perfect", accepting an unusual choice)
- Workflow preferences expressed during the session
- Communication style preferences

### Project Context
- Status updates about what's in-flight or blocked
- Who is working on what and by when
- Sprint or milestone context
- Dependency or integration information

### References
- External URLs, tools, dashboards, or services mentioned
- Linear projects, Slack channels, or other system pointers
- Documentation locations discovered during the session

## Step 3: Deduplicate

For each finding, check against:
1. Existing entries in `{knowledge_folder}/intake/insights-backlog.md`
2. Existing entries in `{knowledge_folder}/intake/decisions-backlog.md`
3. Existing entries in `{knowledge_folder}/intake/extraction-backlog.md`
4. CLAUDE.md files in the current working directory (root and project-level)
5. Memory files in `~/.claude/projects/` for the current project
6. Knowledge files in `{knowledge_folder}/`

**Skip anything already captured.** Be conservative — if the content is substantively the same even with different wording, skip it.

**If any deduplication source cannot be read** (missing file, permissions error), note which source was skipped and include it in the Step 5 report: "Deduplication incomplete — could not read [file]. Some entries may be duplicates."

## Step 4: Append to Backlogs

Route each finding to the appropriate backlog file. Do NOT ask for confirmation — just append.

### Insights → `{knowledge_folder}/intake/insights-backlog.md`

Use existing format:
```markdown
### YYYY-MM-DD — [project] — [task context]
- Insight bullet 1
- Insight bullet 2
```

### Decisions → `{knowledge_folder}/intake/decisions-backlog.md`

Use existing format:
```markdown
### YYYY-MM-DD — [project(s)] — [decision context]
**Decision:** What was decided
**Why:** Rationale
**Alternatives considered:** What else was evaluated
```

### Feedback, Project Context, References → `{knowledge_folder}/intake/extraction-backlog.md`

Use this format:
```markdown
### YYYY-MM-DD — [type: feedback|project|reference] — [context]
**Content:** What was captured
**Source:** Where in the conversation this came from (brief description)
```

### Before appending:
- Remove the "(No pending ...)" placeholder if it exists — replace with the new entries
- If entries already exist, append below them with a blank line separator
- **If a backlog file is missing:** do not create it from scratch. Stop and tell the user: "Backlog file [name] is missing. Run /setup to repair the knowledge folder structure."

## Step 5: Report

After appending, output a brief summary:

```
## Extraction Complete

- **Insights:** N new (appended to insights-backlog.md)
- **Decisions:** N new (appended to decisions-backlog.md)
- **Feedback:** N new (appended to extraction-backlog.md)
- **Project context:** N new (appended to extraction-backlog.md)
- **References:** N new (appended to extraction-backlog.md)
- **Skipped:** N duplicates

Knowledge staged in backlogs for next audit to review and promote.
```

If nothing was found:
```
## Extraction Complete

No uncaptured knowledge found — everything from this session is already persisted.
```

## Rules

- **Never ask for confirmation** — scan and dump. The audit process handles review and promotion.
- **Be thorough but not noisy** — capture genuinely useful knowledge, not every minor exchange. "User asked to read a file" is not knowledge. "User explained that the auth middleware rewrite is driven by legal compliance" IS knowledge.
- **Convert relative dates** — "last Thursday" becomes the actual date (YYYY-MM-DD)
- **Project attribution** — always tag with the project (or "cross") when identifiable
- **Don't duplicate CLAUDE.md content** — if it's already a rule or convention in any CLAUDE.md, skip it
- **Feedback is high-value** — corrections and confirmed approaches are the most actionable extraction type. Capture the correction AND the reason if one was given.
- **Keep entries concise** — each backlog entry should be self-contained but brief. The audit process adds depth when promoting.
- **One extraction per natural breakpoint** — don't run multiple times for the same conversation segment
