---
description: "Scan Claude memory and plans for extractable knowledge. Use when user asks for 'knowledge audit', 'audit knowledge', 'check for extractable knowledge', 'scan memory', or at session start when audit cadence is exceeded."
argument-hint: ""
allowed-tools: Read, Glob, Grep, Write, Edit, Bash
---

# /audit-knowledge — Knowledge Repository Audit

Scan `~/.claude/` memory and plan files, compare against what's already in the knowledge folder and project-level docs, and surface anything worth extracting.

## Step 0: Resolve Config

Read `~/.claude/aria-knowledge.local.md` and extract `knowledge_folder` and `audit_cadence_knowledge`. If the file doesn't exist, stop: "aria-knowledge is not configured. Run /setup to get started."

Use `{knowledge_folder}` as the base path for all file operations in subsequent steps.

## Step 1: Read the Audit Log and Determine Mode

Read `{knowledge_folder}/logs/knowledge-audit-log.md`.

Note the "Last Audit" date and calculate days since.

**Determine how this skill was invoked:**

- **User-requested** (user said `/audit-knowledge`, "audit knowledge", "scan memory", etc.): **Always run the full audit**, regardless of how recently the last audit was. Skip directly to Step 2.
- **Session-start check** (triggered by the SessionStart hook): Check if the configured cadence has been exceeded.
  - If **cadence exceeded**: Prompt the user — *"It's been N days since the last knowledge audit. Want me to scan for extractable knowledge?"* If they agree, proceed to Step 2. If not, stop.
  - If **within cadence**: Report the last audit date and stop. *"Last knowledge audit was N day(s) ago (YYYY-MM-DD). Next check due in M days."*

## Step 2: Review Insights Backlog

Read `{knowledge_folder}/intake/insights-backlog.md`. **If the file is missing**, report it in Step 6 and suggest running `/setup` to repair the structure. Do not create it.

If there are entries below the `---` separator, these are insights captured during work sessions that need review.

For each insight entry, note it for presentation in Step 6 alongside Category C items. Insights are reviewed with the same approve/reject flow — promoted ones go to the appropriate knowledge file, rejected ones get cleared from the backlog.

## Step 2b: Review Decisions Backlog

Read `{knowledge_folder}/intake/decisions-backlog.md`. **If the file is missing**, report it in Step 6 and suggest running `/setup` to repair the structure. Do not create it.

If there are entries below the `---` separator, these are cross-project architectural decisions captured during work sessions that need review.

For each decision entry, note it for presentation in Step 6. Decisions are reviewed with the same approve/reject flow — promoted ones become full ADRs in `{knowledge_folder}/decisions/` (using ADR format), rejected ones get cleared from the backlog.

## Step 2c: Review Extraction Backlog

Read `{knowledge_folder}/intake/extraction-backlog.md`. **If the file is missing**, report it in Step 6 and suggest running `/setup` to repair the structure. Do not create it.

If there are entries below the `---` separator, these are feedback, project context, and reference items captured via `/extract` during work sessions.

For each entry, note it for presentation in Step 6. Feedback items are promoted to `~/.claude/projects/` memory as feedback memories. Project context items become project memories. Reference items become reference memories or go to `{knowledge_folder}/references/`. Rejected items get cleared from the backlog.

## Step 2d: Review Pre-Compact Captures

Scan `{knowledge_folder}/intake/pre-compact-captures/` for `.md` files. **If the directory doesn't exist or is empty**, skip silently to Step 3.

For each transcript snapshot found:
1. Note the filename (contains date and session ID, e.g., `2026-04-07_a1b2c3d4.md`)
2. Scan the transcript for extractable content — look for the same categories as `/extract`: Insight blocks, architectural decisions, feedback corrections, project context, and reference pointers
3. Note findings for presentation in Step 6 under a "Pre-Compact Captures" section

These are raw transcripts, so be selective — most conversation content is operational, not knowledge. Focus on the same high-value signals `/extract` looks for.

After the user reviews findings in Step 7:
- **Approved items** → append to the appropriate backlog file (insights-backlog.md, decisions-backlog.md, or extraction-backlog.md), then delete the snapshot file
- **Rejected items** → delete the snapshot file
- **Skip** → leave the snapshot for the next audit

## Step 3: Scan Memory Files

Read all `.md` files in `~/.claude/projects/` memory directories for the current project (excluding `MEMORY.md` itself).

**If the directory does not exist or contains no `.md` files:** report "No memory files found for the current project" in the Step 6 summary and skip to Step 4. Do not silently omit this section.

For each file, categorize:
- **(A) Already captured** — content is already in CLAUDE.md files, `{knowledge_folder}/`, or project docs
- **(B) Claude-implementation-specific** — operational details about Claude sessions, plans, or tooling that don't contain reusable knowledge
- **(C) Worth extracting** — contains validated approaches, non-obvious patterns, or cross-project knowledge not yet captured

## Step 4: Scan Plan Files

Read all files in `~/.claude/plans/`.

**If the directory does not exist or contains no files:** report "No plan files found" in the Step 6 summary and skip to Step 5. Do not silently omit this section.

Apply the same A/B/C categorization. Most plans are Category B (implementation-specific). Look specifically for:
- Validated approaches or patterns that could go in `{knowledge_folder}/approaches/`
- Cross-project decisions that could go in `{knowledge_folder}/decisions/`
- Rules or principles validated through experience that could go in `{knowledge_folder}/rules/`
- Operational knowledge (tool setup, architecture, onboarding) that could go in `{knowledge_folder}/guides/`

## Step 5: Cross-Reference with Knowledge Repository

Read the existing knowledge files to avoid duplicates:

```
{knowledge_folder}/README.md
{knowledge_folder}/rules/*.md
{knowledge_folder}/approaches/*.md
{knowledge_folder}/decisions/*.md
{knowledge_folder}/guides/**/*.md
{knowledge_folder}/references/*.md
```

Also check project-level CLAUDE.md and docs files in the current working directory for already-captured knowledge.

## Step 5b: Lint Knowledge Integrity

Using the knowledge files already read in Step 5, scan for internal problems across the existing knowledge base. This is not about what's missing — it's about what's broken or disconnected in what we already have.

Check for:

- **Contradictions** — rules, approaches, or decisions that conflict with each other (e.g., a rule says "always X" but an approach says "avoid X in this context" without acknowledging the rule)
- **Stale references** — file paths, rule numbers, tool names, or class names mentioned in knowledge files that no longer exist in the codebase or knowledge repo. Verify by checking the filesystem — don't rely on memory.
- **Superseded content** — decisions in `decisions/` or the decisions backlog that modify or override an existing approach or rule, but the approach/rule hasn't been updated to reflect this
- **Missing connections** — files that discuss the same concepts, patterns, or components but don't reference each other (e.g., an approach that implements a rule but doesn't cite it, or two decisions about the same system with no cross-link)

**Scope:** Only check files in `{knowledge_folder}/rules/`, `{knowledge_folder}/approaches/`, `{knowledge_folder}/decisions/`, `{knowledge_folder}/guides/`, and `{knowledge_folder}/references/`. Do not lint backlogs, logs, or templates.

**Threshold:** Only flag issues where the inconsistency is clear and actionable. "This rule could be interpreted as conflicting" is not a finding. "Rule 14 says max 3 abstraction layers; approach X recommends 5 without addressing why" IS a finding.

Note all findings for presentation in Step 6 under the new "Integrity Issues" section.

## Step 5c: Cross-Reference Backlog Against Promoted Docs

For each pending backlog entry (from Steps 2, 2b, 2c), check whether it overlaps with existing promoted knowledge files.

**How to match:**
1. If `{knowledge_folder}/index.md` exists, read it and use the tag index for matching. Extract keywords from the backlog entry and check if any match tags in the index.
2. If no index exists, fall back to keyword matching: scan headings and first paragraphs of files in `approaches/`, `decisions/`, `guides/`, `references/` for overlapping terms.

**Two types of overlap to detect:**

**Topic overlap** — the backlog entry covers a topic that already has a promoted doc:
- A backlog insight about pagination when `approaches/api-pagination.md` exists
- Flag: "This insight may relate to existing doc `approaches/api-pagination.md` — update existing rather than create new?"

**Potential invalidation** — the backlog entry describes a change that may affect existing promoted docs:
- A clipping about a new Stripe API version when `references/stripe-webhook-patterns.md` exists
- A decision that reverses or modifies an existing approach
- Flag: "New entry about [topic] — existing `[file]` may need review or update."

Note all cross-references for presentation in Step 6. These inform the user's promotion decisions — they're not blockers.

## Step 6: Present Findings

Present a table with ALL files scanned and their category. Only show details for Category C items.

Format:

```
## Knowledge Audit Results (YYYY-MM-DD)

**Last audit:** YYYY-MM-DD (N days ago)
**Files scanned:** X memory files, Y plan files

### Summary
- Category A (already captured): X files
- Category B (Claude-specific): Y files
- Category C (worth extracting): Z files

### Pending Insights (from insights-backlog.md)

For each insight entry:
- **Date / Project / Context:** from the entry header
- **Insight:** the bullet points
- **Suggested location:** where in the knowledge folder it should go (or "clear" if not worth keeping)

### Pending Decisions (from decisions-backlog.md)

For each decision entry:
- **Date / Project(s) / Context:** from the entry header
- **Decision:** what was decided and why
- **Recommendation:** promote to ADR in `{knowledge_folder}/decisions/` (with suggested filename) or "clear" if already captured elsewhere

### Pre-Compact Captures (from intake/pre-compact-captures/)

For each snapshot with extractable content:
- **Date / Session:** from the filename
- **Findings:** extracted insights, decisions, feedback, or references
- **Recommended action:** append to appropriate backlog and delete snapshot, or delete without extracting

If no snapshots exist or none had extractable content: omit this section.

### Category C Items (if any)

For each Category C item:
- **Source:** file path
- **Knowledge type:** approaches / decisions / rules / references
- **Suggested location:** where in the knowledge folder it should go
- **Content summary:** what would be extracted

### Integrity Issues (from Step 5b)

If Step 5b found any issues, present them:

For each issue:
- **Type:** contradiction / stale reference / superseded content / missing connection
- **Files involved:** which knowledge files are affected
- **Issue:** what's wrong
- **Suggested fix:** specific edit or addition to resolve it

If no issues found: "No integrity issues detected."

### Emerging Themes (cluster detection + synthesis drafts)

Review ALL current backlog entries (not just new ones) plus any Category C items for thematic clusters. Look for:
- **Multiple insights on the same topic** → may warrant a new approach in `approaches/`
- **Multiple decisions with shared rationale** → may warrant an approach documenting the underlying pattern
- **Recurring feedback corrections** (check memory feedback files) → may warrant a new rule in `rules/`

If clusters are detected, present each one with a **draft synthesis document**:

- **Theme:** [description of the pattern]
- **Evidence:** [which backlog entries / memory files point to this]
- **Recommendation:** create new approach, rule, or rule amendment — or "not yet — need more evidence"
- **Draft:** (only if recommendation is to create)

```markdown
# [Proposed Title]

## When to Use
[Synthesized from the cluster evidence — conditions where this applies]

## When NOT to Use
[Conditions where this pattern is wrong or doesn't apply]

## The Approach / The Rule
[Core content synthesized from the individual backlog entries]

## Related
[Links to existing knowledge files that connect to this theme]

## Validated By
[Which sessions/projects produced the evidence]
```

The draft is a starting point for review, not final content. The user may edit, reject, or ask for revisions before promotion. If there isn't enough evidence for a concrete draft, say so and present the theme without one.
```

### Stale Knowledge

If `{knowledge_folder}/index.md` exists, read its `## Stale Files` section. If it has entries, present them as action items:

```
## Stale Knowledge
- N files past review threshold:
  - [file path] ([age] months, threshold: [threshold] months)

For each: review and update Last updated date? Update content? Archive if no longer relevant?
```

If no index exists, skip this section with a note: "Run `/index` to enable staleness detection."

### Cross-Reference Findings (from Step 5c)

For each cross-reference found:
- **Type:** topic overlap | potential invalidation
- **Backlog entry:** which entry triggered the match
- **Existing file:** which promoted doc it overlaps with
- **Recommendation:** update existing, create new alongside, or review existing for staleness

## Step 7: Wait for User Review

**STOP here.** Do NOT extract anything automatically.

Present Category C items, pending insights, and pending decisions. Ask the user which ones to extract/promote. Only proceed after explicit approval.

- Approved insights → move to the appropriate knowledge file, clear from backlog
- Approved decisions → create full ADR in `{knowledge_folder}/decisions/`, clear from backlog
- Approved synthesis drafts → create the new file in the appropriate category, clear source entries from backlogs
- Approved integrity fixes → apply the fix (edit existing file, add cross-reference, archive superseded content)
- Rejected items → clear from their respective backlogs

### Cross-References on Promotion

When writing any new knowledge file during promotion, add a `## Related` section at the bottom linking to existing knowledge files that share concepts, context, or dependencies. To find related files:

1. Check which rules the new content implements, extends, or is an example of
2. Check which approaches or decisions discuss the same system, component, or pattern
3. Check if any existing file's `## Related` section should be updated to link back to the new file

Format:
```markdown
## Related
- [enforcement-mechanisms.md](../rules/enforcement-mechanisms.md) — this approach uses hook-based enforcement (mechanism tier 2-3)
- [001-compact-output-format.md](../decisions/001-compact-output-format.md) — decision that shaped the output format used here
```

Use relative paths. Each link should include a brief note explaining the relationship, not just the filename. Only link files with a genuine conceptual connection — don't link everything to everything.

If there are no Category C items, pending insights, or pending decisions, say so clearly:
> "Nothing new to extract. All knowledge-worthy items are already captured."

## Step 7b: Rebuild Knowledge Index

After all approved promotions and edits are complete, rebuild the knowledge index to capture the current state.

Run the full `/index` logic:
1. Scan all promoted folders for files and tags
2. Normalize tags (present conflicts for approval)
3. Suggest freeform-to-known tag promotions
4. Flag untagged files and offer to add tags
5. Update project-to-tag mappings
6. Detect stale files
7. Suggest cross-references between files with 2+ shared tags
8. Write `{knowledge_folder}/index.md`

**Batch the interactive prompts** — present all index health findings together rather than interrupting one at a time:

```
## Index Health
- N similar tags found: [list normalizations]
- N freeform tags eligible for promotion: [list]
- N untagged files: [list]
- N cross-reference suggestions: [list]
- Project mappings: [changes or "unchanged"]

[Approve normalizations? Promote tags? Tag files? Add cross-references?]
```

Apply approved changes, then write the final `index.md`.

If this is the first audit (no index exists yet), note: "Building knowledge index for the first time."

## Step 8: Update the Audit Log (always, even if nothing extracted)

After presenting findings (and completing any approved extractions), update `{knowledge_folder}/logs/knowledge-audit-log.md`:

```markdown
## Last Audit
- **Date:** YYYY-MM-DD
- **Result:** [describe outcome — e.g., "No new items" or "Extracted N items — brief description"]
```

## Rules

- **Never auto-extract** — always present findings for user review first
- **Be conservative with Category C** — if it's borderline, it's probably Category A or B
- **Check project docs thoroughly** — knowledge is often already captured in project-level CLAUDE.md, PROGRESS.md, or docs/ folders
- **Convert relative dates** — if a memory or plan references "last Thursday", convert to the actual date
- **Stale memories are not Category C** — outdated project status doesn't need extraction, it needs cleanup
- **Prioritize approaches and rules** — these are the highest-value extractions. Debug recipes, implementation plans, and one-time fixes are Category B
- **Watch for clusters** — individual backlog entries may not justify a knowledge file, but patterns of related entries do. The backlogs are signal generators, not just staging areas
