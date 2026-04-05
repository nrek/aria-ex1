#!/bin/sh
# session-stop-check.sh — Stop hook for aria-knowledge
# Injects session cleanup checklist for Claude to evaluate

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/config.sh"

# If config file exists but failed validation, report the specific error
if [ -n "$KT_CONFIG_ERROR" ]; then
  MSG=$(kt_json_escape "aria-knowledge: $KT_CONFIG_ERROR Run /setup to reconfigure.")
  echo '{"systemMessage":"'"$MSG"'"}'
  exit 0
fi

# If not configured, nudge setup
if [ "$KT_CONFIGURED" = "false" ]; then
  echo '{"systemMessage":"aria-knowledge is installed but not configured. Run /setup to configure your knowledge folder and start capturing knowledge automatically."}'
  exit 0
fi

# Check knowledge folder exists
if [ ! -d "$KT_KNOWLEDGE_FOLDER" ]; then
  MSG=$(kt_json_escape "aria-knowledge: knowledge folder not found at $KT_KNOWLEDGE_FOLDER. Skipping session cleanup checklist.")
  echo '{"systemMessage":"'"$MSG"'"}'
  exit 0
fi

# Build cleanup checklist
CHECKLIST="SESSION CLEANUP (aria-knowledge) — Before ending, check:"

if [ "$KT_EXPLANATORY" = "true" ]; then
  CHECKLIST="$CHECKLIST (1) Were any Insight blocks output that were not appended to ${KT_KNOWLEDGE_FOLDER}/intake/insights-backlog.md? If yes, append them now using the format in that file."
  CHECKLIST="$CHECKLIST (2) Were any cross-project architectural decisions made this session that were not logged to ${KT_KNOWLEDGE_FOLDER}/intake/decisions-backlog.md? If yes, flag to user: This looks like a cross-project decision — want me to log it?"
  CHECKLIST="$CHECKLIST (3) Was meaningful work completed this session? If yes, prompt: Want me to run /extract before wrapping up?"
else
  CHECKLIST="$CHECKLIST (1) Were any cross-project architectural decisions made this session that were not logged to ${KT_KNOWLEDGE_FOLDER}/intake/decisions-backlog.md? If yes, flag to user: This looks like a cross-project decision — want me to log it?"
  CHECKLIST="$CHECKLIST (2) Was meaningful work completed this session? If yes, prompt: Want me to run /extract before wrapping up?"
fi

# Escape for JSON
CHECKLIST_ESCAPED=$(kt_json_escape "$CHECKLIST")
echo '{"systemMessage":"'"$CHECKLIST_ESCAPED"'"}'
