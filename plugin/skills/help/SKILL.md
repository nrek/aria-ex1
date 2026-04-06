---
description: "Show available aria-knowledge commands. Use when user says '/help', 'aria help', 'what commands are available', 'list commands', 'what can aria do'."
argument-hint: ""
allowed-tools: ""
---

# /help — aria-knowledge Commands

Print the command reference table. No config or file access needed.

## Output

```
## aria-knowledge Commands

| Command | Description |
|---------|-------------|
| /setup | Configure knowledge folder, audit cadences, and plugin settings |
| /extract | Capture insights, decisions, and feedback from the current conversation |
| /audit-knowledge | Review backlogs, promote to knowledge files, rebuild index |
| /audit-config | Check project configs and docs for drift and broken references |
| /context [tags] | Load relevant knowledge files by topic (supports AND/OR, project expansion) |
| /index | Rebuild the tag-based knowledge index with cross-references |
| /rules [number] | Look up a working rule by number or keyword |
| /backlog [type] | View and manage pending intake items |
| /stats | Knowledge base health dashboard — file counts, backlogs, audit status |
| /clip [url or text] | Quick-save a URL or text snippet to intake for later review |
| /help | This command reference |

Run /setup to configure. See QUICKSTART.md for a walkthrough of your first 3 sessions.
```
