---
description: "Load relevant knowledge by topic. Queries the tag index and presents matching promoted files for selective loading into context. Use when user says '/context stripe', '/context api pagination', '/context ss', 'load knowledge about...', 'what do we know about...'."
argument-hint: "<tag1> [tag2] [AND tag3]"
allowed-tools: Read, Glob, Grep
---

# /context — On-Demand Knowledge Retrieval

Query the knowledge tag index and load relevant promoted files into the conversation context.

## Step 0: Resolve Config

Read `~/.claude/aria-knowledge.local.md` and extract `knowledge_folder`.

If the config file doesn't exist, stop: "aria-knowledge is not configured. Run /setup to get started."

## Step 1: Read Index

Read `{knowledge_folder}/index.md`.

If the file doesn't exist, stop: "No knowledge index found. Run `/index` to build it."

Parse the index to extract:
- `## Projects` section — project name/key and their relevant tags
- `## Known Tags` section — the canonical tag list
- `## Tag Index` section — tag → file mappings for known tags
- `## Other Tags` section — tag → file mappings for freeform tags

## Step 2: Parse Query

The user's argument is a space-separated list of tags with optional `AND` keyword.

**Parsing rules:**
- Split on spaces
- If the token `AND` (case-insensitive) appears, use **intersection mode** — a file must have ALL specified tags
- Otherwise, use **union mode** (default) — a file matches if it has ANY of the specified tags
- Remove `AND` tokens from the tag list

Examples:
- `/context stripe` → tags: [`stripe`], mode: OR
- `/context api pagination` → tags: [`api`, `pagination`], mode: OR
- `/context api AND pagination` → tags: [`api`, `pagination`], mode: AND
- `/context ss` → tags: [`ss`], mode: OR (with project expansion)

If no argument provided, stop: "Usage: `/context <tag1> [tag2] [AND tag3]`. Run `/index` to see available tags."

## Step 3: Project Tag Expansion

For each tag in the query, check if it matches a project key in the `## Projects` section (e.g., `ss`, `cs`, `df`, `aria`).

If a tag matches a project:
1. Keep the project tag itself in the search
2. Also add all of that project's "Relevant tags" to the search
3. Notify the user:
   ```
   Expanded `ss` to include: api, django, nextjs, stripe, supabase, database, deployment
   ```

Project expansion only applies in union (OR) mode. In AND mode, project tags are treated as literal tags (a file must be tagged `ss` specifically).

## Step 4: Match Files

Scan the `## Tag Index` and `## Other Tags` sections for entries matching the query tags.

**Union mode (OR):** Collect all files that appear under any of the query tags. Deduplicate — each file appears once even if it matches multiple tags.

**Intersection mode (AND):** Collect files that appear under ALL of the query tags. A file must be listed under every specified tag.

For each matching file, collect:
- File path (relative to knowledge folder)
- Description (from the index entry)
- All tags the file carries (scan all tag sections for this file path)

## Step 5: Present Summary

If matches found:

```
Found N files matching: [tags] ([OR|AND])

1. approaches/api-pagination.md — Cursor-based pagination patterns [api, pagination, stripe]
2. decisions/003-cursor-vs-offset.md — Why we chose cursor pagination [api, stripe]
3. references/stripe-webhook-patterns.md — Webhook signature verification [stripe, webhooks]

Load which files? (all / numbers / none)
```

Show the file's tags in brackets after the description so the user can see why each file matched.

**If no matches:**

```
No files match tag(s): [tags]

Known tags: api, architecture, css, database, ...
Run `/index` to rebuild if you've recently added files.
```

## Step 6: Load Selected Files

Based on user response:
- **"all"** — read and present the full content of every matched file
- **Numbers (e.g., "1 3" or "1,3")** — read and present only the specified files
- **"none"** — stop, don't load anything

For each selected file:
1. Read `{knowledge_folder}/{file_path}`
2. Present the full file content

After loading, confirm: "Loaded N knowledge files into context."

## Rules

- **Read-only** — this skill never modifies any files
- **Index-only** — queries the index, not the files themselves (until loading)
- **Promoted files only** — does not search backlogs, intake, rules, or logs
- **No full-text search** — tag-based matching only. If the user needs content search, suggest using Grep directly
- **Present before loading** — always show the summary and let the user choose which files to load
