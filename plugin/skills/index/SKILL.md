---
description: "Rebuild the knowledge tag index. Scans promoted files, normalizes tags, flags untagged files, suggests freeform-to-known promotions, detects stale files, suggests cross-references, updates project-to-tag mappings, and regenerates index.md. Use when user says '/index', 'rebuild index', 'update index', 'reindex knowledge'. Also called automatically by /audit-knowledge."
argument-hint: ""
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# /index — Knowledge Index Builder

Scan all promoted knowledge files, normalize tags, detect issues, and regenerate `{knowledge_folder}/index.md`.

## Step 0: Resolve Config

Read `~/.claude/aria-knowledge.local.md` and extract:
- `knowledge_folder` — base path for all operations
- `freeform_promotion_threshold` — minimum file count before suggesting promotion (default: 3)
- `staleness_threshold_months` — months before a file is flagged stale (default: 6)

If the config file doesn't exist, stop: "aria-knowledge is not configured. Run /setup to get started."

## Step 1: Scan Promoted Folders

Scan these directories for `.md` files (excluding directory README stubs that only contain a few lines of boilerplate):
- `{knowledge_folder}/approaches/`
- `{knowledge_folder}/decisions/`
- `{knowledge_folder}/guides/` (recursive — includes subdirectories)
- `{knowledge_folder}/references/`

**Do NOT scan:** `archive/`, `intake/`, `rules/`, `logs/`, or root-level files (`README.md`, `LOCAL.md`, `OVERVIEW.md`, `index.md`).

For each `.md` file found:
1. Read the file
2. Extract YAML frontmatter (content between `---` markers at the top of the file)
3. From frontmatter, extract:
   - `tags:` — array of tags (e.g., `tags: [api, pagination, django]`). If missing, record as untagged.
   - `Last updated:` — date string (YYYY-MM-DD). If missing, record as unknown.
4. Extract the first `#` heading as the file's description
5. Store: `{path, tags[], description, last_updated}`

Report: "Scanned N files in approaches/, decisions/, guides/, references/."

## Step 2: Read Existing Index

Read `{knowledge_folder}/index.md` if it exists.

Extract:
- `## Known Tags` section — the current canonical tag vocabulary (comma-separated list)
- `## Projects` section — current project-to-tag mappings

If `index.md` doesn't exist (first run), use the seeded known tags:

```
api, architecture, css, database, deployment, django, react, nextjs, react-native, tailwind, testing, infrastructure, performance, security, accessibility, stripe, linear, supabase, figma, claude-code, process, decision-framework, enforcement, cs, ss, df, aria
```

And leave the Projects section empty (will be populated in Step 6).

## Step 3: Tag Normalization

Compare all tags found across scanned files. Detect similar tags using these heuristics:
- **Plural/singular:** `api` vs `apis`, `test` vs `tests`
- **Hyphen variants:** `react-native` vs `reactnative` vs `react native`
- **Common abbreviations:** `db` vs `database`, `infra` vs `infrastructure`

For each pair of similar tags, check which one is in the Known Tags set. If one is known and the other isn't, the known one is the normalization target.

If both are unknown, prefer the more common one (appears on more files).

**Present conflicts to user:**

```
## Tag Normalization

Found similar tags:
1. `apis` (1 file) → normalize to `api` (4 files)? [y/n]
2. `reactnative` (1 file) → normalize to `react-native` (2 files)? [y/n]
```

For each approved normalization:
- Edit the source file's YAML frontmatter to replace the old tag with the normalized tag
- Record the change for the summary

If no similar tags found, skip this step silently.

## Step 4: Freeform-to-Known Tag Promotion

Identify tags that are NOT in the Known Tags set but appear on `{freeform_promotion_threshold}` or more files (default: 3).

**Present suggestions:**

```
## Freeform Tag Promotion

These freeform tags appear frequently:
1. `webhooks` — 4 files. Promote to known tags? [y/n]
2. `authentication` — 3 files. Promote to known tags? [y/n]
```

For each approved promotion:
- Add the tag to the Known Tags set (will be written to index.md in Step 9)
- Record for summary

If no tags qualify, skip this step silently.

## Step 5: Untagged File Resolution

For each file with no `tags:` in its frontmatter:

**Present list and offer to fix:**

```
## Untagged Files

Found N files without tags:
1. guides/claude/environment-architecture.md — "Environment Architecture"
   Suggested tags: [claude-code, architecture, infrastructure]
2. approaches/combo-class-pattern.md — "Combo Class Pattern"
   Suggested tags: [css, tailwind, df]

Add suggested tags? (all / numbers / skip)
```

For each file the user approves:
- Read the file
- If the file has existing YAML frontmatter (between `---` markers), add `tags: [tag1, tag2]` as a new line inside it
- If the file has no frontmatter, add a frontmatter block at the top:
  ```
  ---
  Last updated: YYYY-MM-DD
  tags: [tag1, tag2]
  ---
  ```
  (Use the file's existing `Last updated` date if found in the body, or today's date if none exists)
- Record the change for the summary

Tag suggestions are based on:
- Filename keywords (e.g., `api-pagination` → `api`, `pagination`)
- First heading keywords
- Content scan for known tag keywords
- Parent directory (e.g., file in `guides/claude/` → suggest `claude-code`)

## Step 6: Project-to-Tag Mapping Update

Read the root project CLAUDE.md to find the project table. Look for the closest ancestor directory containing a `CLAUDE.md` with a project table.

For each project listed in the table:
1. Read the project's CLAUDE.md (e.g., `cs/CLAUDE.md`, `ss/CLAUDE.md`)
2. Extract tech stack, tools, frameworks, and services mentioned
3. Match extracted keywords against the Known Tags set (including any newly promoted tags from Step 4)
4. Also check which tags appear on files that mention the project name in their path or content

Build a mapping:
```
cs — Commonspace: api, django, react, react-native, css, tailwind, stripe, supabase, database, deployment
ss — Seersite: api, django, nextjs, stripe, supabase, database, deployment
df — Designframe: css, tailwind, accessibility
aria — ARIA: claude-code, process, decision-framework, enforcement
```

Compare against existing mappings (from Step 2). If any changed:

```
## Project Mapping Updates

- cs: added `supabase` (found in cs/CLAUDE.md tech stack)
- ss: no changes
```

If this is the first run (no existing mappings), present the full initial mapping for confirmation.

## Step 7: Staleness Detection

For each scanned file, compare its `Last updated` date against today's date.

If the file's age exceeds `{staleness_threshold_months}` months (default: 6):
- Add to the stale files list with age and threshold info

This data is used when generating the `## Stale Files` section in Step 9. No user interaction here — just collection.

## Step 8: Cross-Reference Pass

For each pair of promoted files, compute tag overlap:
1. Count shared tags between the two files
2. If overlap >= 2 tags, check each file's `## Related` section for existing cross-references
3. If one or both files don't reference the other, record as a suggestion

Also check for **reverse link gaps**: if file A's `## Related` links to file B, but file B's `## Related` doesn't link to file A.

**Present suggestions:**

```
## Cross-Reference Suggestions

1. approaches/api-pagination.md <-> decisions/003-cursor-vs-offset.md
   Shared tags: api, pagination
   Neither references the other — add cross-links? [y/n]

2. references/stripe-webhook-patterns.md <-> guides/payments/checkout-flow.md
   Shared tags: stripe, cs
   checkout-flow.md links to stripe-webhook-patterns.md but not the reverse — add reverse link? [y/n]
```

For each approved cross-reference:
- If the file has a `## Related` section, append the new link:
  ```markdown
  - [Target File Title](../relative/path/to/target.md)
  ```
- If the file has no `## Related` section, add one at the end of the file:
  ```markdown

  ## Related
  - [Target File Title](../relative/path/to/target.md)
  ```
- Use relative paths from the source file to the target file

If no suggestions, skip this step silently.

## Step 8b: Entity Detection

Scan all promoted files for recurring proper nouns — tool names, service names, API names, framework names, and other named entities that appear across multiple knowledge files.

**How to detect entities:**
1. Scan headings, bold text, and inline code spans in promoted files for proper nouns and technical names
2. Filter to entities that appear in **2+ files** (single-file mentions aren't useful for cross-referencing)
3. Exclude entities that are already covered by tags (e.g., if "Stripe" is both a tag and an entity, the tag index already covers it)
4. Exclude common words that happen to be capitalized (sentence starters, section headings like "Overview", "Summary")

**Build an entity map:**
```
Stripe → approaches/payment-flow.md, references/stripe-webhook-patterns.md, decisions/003-payment-provider.md
Supabase → guides/infrastructure/supabase-setup.md, decisions/005-builder-architecture.md
Django → approaches/api-pagination.md, guides/api-auth.md
```

This data is used when generating the `## Entities` section in Step 9. No user interaction here — just collection.

## Step 9: Rebuild and Write `index.md`

Generate `{knowledge_folder}/index.md` with this structure:

```markdown
# Knowledge Index

Last rebuilt: YYYY-MM-DD

## Projects

### [project_key] — [project_name]
Relevant tags: tag1, tag2, tag3

(repeat for each project)

## Known Tags

tag1, tag2, tag3, tag4, ...

## Tag Index

### [known_tag]
- relative/path/to/file.md — File description

(repeat for each known tag that has matching files, sorted alphabetically)

## Other Tags

### [freeform_tag]
- relative/path/to/file.md — File description

(repeat for each freeform tag, sorted alphabetically)

## Stale Files

### relative/path/to/file.md
Last updated: YYYY-MM-DD (N months ago) — threshold: M months

(repeat for each stale file. Omit this section entirely if no stale files.)

## Untagged Files

- relative/path/to/file.md — File description (no tags in frontmatter)

(Omit this section entirely if no untagged files remain after Step 5.)

## Entities

### [Entity Name]
- relative/path/to/file1.md
- relative/path/to/file2.md

(Repeat for each entity appearing in 2+ files, sorted alphabetically. Omit this section entirely if no entities detected or all are already covered by tags.)
```

**File paths** in the index are relative to the knowledge folder root (e.g., `approaches/api-pagination.md`, not the absolute path).

**Tag Index entries** are sorted: known tags alphabetically, then other tags alphabetically. Within each tag, files are sorted alphabetically by path.

**A file appears under every tag it carries.** If `api-pagination.md` has `tags: [api, pagination, django]`, it appears under all three tag headings.

## Step 10: Report Summary

```
Index rebuilt successfully.

Files: N scanned, M tagged, K untagged
Tags: L unique (J known, F freeform)
Normalizations: P applied
Promotions: Q tags promoted to known
Stale files: S (threshold: T months)
Cross-references: R suggested, X added
Entities: E detected (across 2+ files)
Project mappings: updated/unchanged
```

## Rules

- **Never modify files outside the knowledge folder** except for the root CLAUDE.md read (read-only) in Step 6
- **Always present changes before making them** — normalizations, promotions, untagged fixes, and cross-references all require user approval
- **Preserve existing frontmatter** — when adding tags to a file, don't remove or modify other frontmatter fields
- **Relative paths in index** — all paths in index.md are relative to the knowledge folder root
- **Skip empty directories** — if approaches/ has no .md files, don't create an empty tag section
- **Directory README stubs are not knowledge files** — skip files that are only 1-5 lines of boilerplate (the README.md stubs in approaches/, decisions/, etc.)
