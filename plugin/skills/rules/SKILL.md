---
description: "Quick lookup into working rules. Use when user says '/rules', '/rules 22', '/rules dependencies', 'look up rule about...', 'what rule covers...', or references a specific rule number."
argument-hint: "[number or keyword]"
allowed-tools: Read, Grep
---

# /rules — Quick Rule Lookup

Look up rules from the user's working-rules.md file.

## Step 0: Resolve Config

Read `~/.claude/aria-knowledge.local.md` and extract `knowledge_folder`. If the file doesn't exist, stop: "aria-knowledge is not configured. Run /setup to get started."

Set the rules file path: `{knowledge_folder}/rules/working-rules.md`

If the rules file doesn't exist, stop: "No working-rules.md found in your knowledge folder."

## Step 1: Parse Argument

Check what argument was provided:
- **No argument:** go to Step 2 (index mode)
- **Number** (e.g., `22`): go to Step 3 (lookup by number)
- **Keyword** (e.g., `dependencies`): go to Step 4 (search mode)

## Step 2: Index Mode

Read the rules file. Extract all rule headings (lines matching `### N. [title]`). Output a numbered list of titles only:

```
## Working Rules Index

1. Scope tasks tightly, but keep the whole system in view
2. Let errors guide where you add context
3. Use reference implementations, but don't assume they're the best
...
```

## Step 3: Lookup by Number

Read the rules file. Find the heading matching the requested number (e.g., `### 22.`). Extract everything from that heading until the next heading of the same level or end of section. Output the full rule text.

If the number doesn't exist: "Rule [N] not found. There are [max] rules. Run /rules to see the index."

## Step 4: Search Mode

Read the rules file. Search rule titles and bodies for the keyword. Return all matching rules with their full text.

If no matches: "No rules match '[keyword]'. Run /rules to see the full index."

If multiple matches: show all of them with clear separation.
