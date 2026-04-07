#!/bin/sh
# pre-edit-check.sh — PreToolUse hook for Edit|Write
# Checks if the file being edited is in a planning path.
# If so, allows abbreviated Rule 22 assessment.
# Otherwise, requires full assessment.

# Read the tool input to get the file path
# The hook receives tool input via stdin as JSON
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | grep -o '"file_path":"[^"]*"' | head -1 | sed 's/"file_path":"//;s/"//')

# Planning paths where abbreviated assessment is permitted
IS_PLANNING=false
case "$FILE_PATH" in
  */docs/specs/*|*/docs/plans/*) IS_PLANNING=true ;;
esac

# Protected filenames that always require full assessment
IS_PROTECTED=false
BASENAME=$(basename "$FILE_PATH" 2>/dev/null)
case "$BASENAME" in
  CLAUDE.md|working-rules.md|change-decision-framework.md|enforcement-mechanisms.md|settings.local.json|plugin.json)
    IS_PROTECTED=true ;;
esac

# Check if file is inside the knowledge folder
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/config.sh"
if [ "$KT_CONFIGURED" = "true" ] && [ -n "$KT_KNOWLEDGE_FOLDER" ]; then
  case "$FILE_PATH" in
    "$KT_KNOWLEDGE_FOLDER"/*) IS_PROTECTED=true ;;
  esac

  # Check user-configured critical paths (comma-separated glob patterns)
  if [ -n "$KT_CRITICAL_PATHS" ] && [ "$IS_PROTECTED" = "false" ]; then
    OLD_IFS="$IFS"
    IFS=','
    for PATTERN in $KT_CRITICAL_PATHS; do
      # Strip trailing /* or * to get directory prefix
      PREFIX=$(echo "$PATTERN" | sed 's|/\*$||;s|\*$||')
      case "$FILE_PATH" in
        */$PREFIX/*) IS_PROTECTED=true; break ;;
      esac
    done
    IFS="$OLD_IFS"
  fi
fi

if [ "$IS_PLANNING" = "true" ] && [ "$IS_PROTECTED" = "false" ]; then
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"PLANNING PATH — abbreviated assessment permitted. Output: Planning edit — [filename]. If this file is NOT a planning/spec document, STOP and use full Rule 22 assessment instead."}}'
else
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"Rule 22 — Assess impact (HIGH or LOW) and output the required format before proceeding. HIGH: full 7-step (Change, Intake, Criteria, Solutions, Rank, Validate, Execute). LOW: abbreviated (Change, Solutions, Execute with scope/secondary check). STOP if not completed."}}'
fi
