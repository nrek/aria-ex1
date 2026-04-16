---
description: "Look up working rules by number or keyword. Reads plugin template rules. Trigger: '/rules', '/rules 22', '/rules dependencies'."
argument-hint: "[number or keyword]"
allowed-tools: Read, Grep
---

# /rules — Rule lookup

## Step 0: Resolve paths

- **Plugin rules:** `${CLAUDE_PLUGIN_ROOT}/template/rules/working-rules.md`
- **User rules (optional):** `${CLAUDE_PLUGIN_ROOT}/template/rules/user-rules.md` (same directory; user may symlink a shared copy)

If `working-rules.md` is missing, stop with an error (plugin install incomplete).

## Step 1: Arguments

- No arg → **index**: list all `### N.` headings from both files.
- Number → extract that rule’s body (through next `###` or `---`).
- Keyword → search titles and bodies; list matches with source label.

## Step 2: Output

Present rule text verbatim. If both files define the same number (unlikely in user-rules if using `U` prefix), show both and warn.

Do not require `aria-ex1.local.md` for this skill.
