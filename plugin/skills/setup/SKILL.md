---
description: "Configure aria-knowledge plugin. Creates or validates a knowledge folder, checks dependencies, sets audit cadences, and writes config. Run on first install or after plugin updates. Trigger: '/setup', 'setup aria-knowledge', 'configure knowledge'."
argument-hint: ""
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# /setup — Knowledge Tools Configuration

Walk the user through configuring their knowledge folder and plugin settings. Safe to re-run at any time — only touches what needs updating.

## Step 1: Check for Existing Config

Read `~/.claude/aria-knowledge.local.md`.

- **If it exists:** show current settings and say "aria-knowledge is already configured. I'll check for updates." Then proceed to Step 2 in **update mode** — scan for missing structure, re-diff templated files, check dependencies.
- **If it doesn't exist:** say "Let's set up aria-knowledge. This will configure your knowledge folder and preferences." Proceed to Step 2 in **fresh mode**.

## Step 2: Knowledge Folder Location

Ask the user:
> "Where would you like your knowledge folder? You can:
> (a) Provide a path to an existing folder
> (b) Create a new one — I'll ask where to put it"

If **(a) existing path:**
- Verify the path exists and is a directory
- Proceed to Step 3 in **existing mode**

If **(b) create new:**
- Ask for the desired location (parent directory + folder name)
- Create the directory
- Proceed to Step 3 in **create mode**

## Step 3: Folder Structure Validation

Read the expected structure from `${CLAUDE_PLUGIN_ROOT}/template/`.

**Expected directories:** `intake/`, `intake/notes/`, `intake/attachments/`, `intake/clippings/`, `intake/pre-compact-captures/`, `logs/`, `rules/`, `approaches/`, `decisions/`, `guides/`, `references/`, `archive/`

**Expected files:** `README.md`, `OVERVIEW.md`, `LOCAL.md`, `intake/insights-backlog.md`, `intake/decisions-backlog.md`, `intake/extraction-backlog.md`, `logs/knowledge-audit-log.md`, `logs/config-audit-log.md`, `rules/working-rules.md`, `rules/change-decision-framework.md`, `rules/enforcement-mechanisms.md`, `guides/README.md`, `approaches/README.md`, `decisions/README.md`, `references/README.md`, `archive/README.md`

**User-owned files (created once from template, never overwritten or diffed):** `LOCAL.md` (project-specific guide), `guides/README.md`, `approaches/README.md`, `decisions/README.md`, `references/README.md`, `archive/README.md` (directory stubs users may customize).

**In create mode:** Create all directories and copy all template files.

**In existing mode:** Scan what's present vs missing.
- For missing **directories**: create them silently.
- For missing **files**: copy from template and note what was added.
- For existing **files**: do NOT overwrite — collect for diffing in Step 4.
- Report: "Created N directories, added N files, found N existing files to check."

## Step 4: File Diffing

For each templated file that already exists in the user's folder, compare against the plugin's shipped version in `${CLAUDE_PLUGIN_ROOT}/template/`.

**Files to diff:** `rules/working-rules.md`, `rules/change-decision-framework.md`, `rules/enforcement-mechanisms.md`, `README.md`, `OVERVIEW.md`

**Never diff:** `LOCAL.md` (user-owned), directory README stubs (`guides/README.md`, `approaches/README.md`, `decisions/README.md`, `references/README.md`, `archive/README.md`), backlog files (`intake/insights-backlog.md`, `intake/decisions-backlog.md`, `intake/extraction-backlog.md`), and audit log files (`logs/knowledge-audit-log.md`, `logs/config-audit-log.md`) — these contain user data or user-customizable content.

For each file with differences:
1. Notify: "[filename] differs from the plugin version."
2. Show a brief summary of what's different (not the full diff unless asked).
3. Offer options:
   - **Keep mine** — no change
   - **Use plugin version** — overwrite with template
   - **Show diff** — display the full diff, then ask again

If no files differ (or all are new), skip this step silently.

In **update mode** (re-run): always diff, even if the file was previously kept. The plugin version may have changed.

## Step 5: Dependency Check

Check if the `explanatory-output-style` plugin is installed:

```bash
find ~/.claude/plugins -name "explanatory-output-style" -type d 2>/dev/null | head -1
```

- **If found:** "explanatory-output-style plugin detected. Insight capture will be enabled."
- **If not found:** "The explanatory-output-style plugin generates Insight blocks that aria-knowledge can capture automatically. It's an official Anthropic plugin. Want to install it? (recommended, but optional)"
  - If user says yes: guide them to install it (the exact install mechanism depends on their Claude Code setup)
  - If user says no: "Insight capture will be disabled. You can enable it later by installing the plugin and re-running /setup."

Record the result as `true` or `false`.

## Step 6: Cadence Configuration

Present current or default cadences:
> "Audit cadences control how often you're prompted to review knowledge:
> - **Knowledge audit:** every 3 days (scans memory/plans for extractable knowledge)
> - **Config audit:** every 14 days (checks configs and docs for drift)
> - **Update check:** every 30 days (prompts to run /setup for plugin template updates)
>
> Want to change any cadence? (Enter new values or press enter to keep defaults)"

Record the values.

### Advanced Options

If the user asks about advanced options or re-runs setup with existing config, also offer:

> "Advanced settings (defaults are fine for most users):
> - **Freeform tag promotion threshold:** 3 (suggest promoting a freeform tag to known after it appears on this many files)
> - **Staleness threshold:** 6 months (flag knowledge files not updated within this period)
> - **Auto-capture on compaction:** true (save transcript snapshot before context compaction)
> - **Critical paths:** (empty) comma-separated path patterns that always require HIGH impact assessment (e.g., auth/*,payments/*,migrations/*)
>
> Want to change any? (Enter new values or press enter to keep defaults)"

Record the values. If the user doesn't ask about advanced options during initial setup, use the defaults silently.

## Step 7: Write Config

Write `~/.claude/aria-knowledge.local.md` with the collected settings:

```yaml
---
knowledge_folder: [path from Step 2]
audit_cadence_knowledge: [value from Step 6]
audit_cadence_config: [value from Step 6]
explanatory_plugin: [true/false from Step 5]
audit_cadence_update: [value from Step 6, default 30]
freeform_promotion_threshold: [value from Step 6, default 3]
staleness_threshold_months: [value from Step 6, default 6]
auto_capture: [true/false from Step 6, default true]
critical_paths: [comma-separated patterns from Step 6, default empty]
---
```

Add a markdown body below the frontmatter:

```markdown
# Knowledge Tools Configuration

Configured by /setup on [today's date].
```

In **update mode:** preserve any user-added content in the markdown body below the frontmatter when rewriting.

**Formatting rules** — the config file MUST follow these exact conventions or the hook scripts cannot parse it:
- Frontmatter delimiters must be exactly `---` on their own line (no leading spaces, no trailing content)
- Each key must start at column 1 with no indentation
- Keys use the exact names shown above (no quoting, no trailing spaces)
- Values must NOT be quoted — write `knowledge_folder: /path/to/folder`, not `knowledge_folder: "/path/to/folder"`
- `knowledge_folder` must be an absolute path (starts with `/`) and must not contain `..`
- Cadence values must be plain integers (no units, no quotes)
- No blank lines between frontmatter entries

## Step 7b: Verify Config Round-Trip

After writing the config file, read it back and verify that each value can be extracted using the same patterns that `config.sh` uses. This catches formatting issues before the user discovers them in the next session.

**Verification checks:**
1. Read `~/.claude/aria-knowledge.local.md`
2. Extract the frontmatter block (content between the first and second `---` lines)
3. For each key, verify the value matches what was intended:
   - `knowledge_folder` — grep for `^knowledge_folder:` and confirm the extracted path matches Step 2's value
   - `audit_cadence_knowledge` — confirm it's the integer from Step 6
   - `audit_cadence_config` — confirm it's the integer from Step 6
   - `explanatory_plugin` — confirm it's `true` or `false`
   - `audit_cadence_update` — confirm it's the integer from Step 6
   - `freeform_promotion_threshold` — confirm it's the integer from Step 6
   - `staleness_threshold_months` — confirm it's the integer from Step 6
   - `auto_capture` — confirm it's `true` or `false`
   - `critical_paths` — confirm it's a comma-separated string of path patterns (or empty)

**If any check fails:** rewrite the file with corrected formatting and verify again. Report which value failed and what was fixed.

**If all checks pass:** proceed to Step 8 silently.

## Step 8: Confirm

Output a summary:

```
Setup complete!
- Knowledge folder: [path]
- Knowledge audit: every [N] days
- Config audit: every [N] days
- Update check: every [N] days
- Insight capture: [enabled/disabled]
- Auto-capture on compaction: [enabled/disabled]
- Files added: [N]
- Files updated: [N]
- Files kept (user version): [N]
```
