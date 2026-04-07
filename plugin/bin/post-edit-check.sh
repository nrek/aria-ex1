#!/bin/sh
# post-edit-check.sh — PostToolUse hook for Edit|Write
# Allows abbreviated scope check for planning paths.

# Read the tool input to get the file path
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | grep -o '"file_path":"[^"]*"' | head -1 | sed 's/"file_path":"//;s/"//')

# Planning paths where abbreviated scope check is permitted
IS_PLANNING=false
case "$FILE_PATH" in
  */docs/specs/*|*/docs/plans/*) IS_PLANNING=true ;;
esac

# Protected filenames that always require full scope check
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
fi

if [ "$IS_PLANNING" = "true" ] && [ "$IS_PROTECTED" = "false" ]; then
  echo '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"PLANNING PATH — abbreviated scope check. Output: Scope OK — planning doc."}}'
else
  echo '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"Scope check — verify: in scope, no extras, no unnecessary rewrites, matches decision, no secondary impact. Output: Scope PASS/FAIL/CONDITIONAL with context."}}'
fi
