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
CHECKLIST="SESSION CHECK: (1) Review and append any uncaptured Insight blocks to insights-backlog.md (2) Review and append any uncaptured cross-project decisions to decisions-backlog.md (3) Suggest /extract if meaningful work was completed this session."

# Escape for JSON
CHECKLIST_ESCAPED=$(kt_json_escape "$CHECKLIST")
echo '{"systemMessage":"'"$CHECKLIST_ESCAPED"'"}'
