#!/bin/sh
# post-edit-check.sh — PostToolUse hook for Edit|Write
# v1.1: trimmed prose, [Rule 22 · Scope] markers for greppable audit trail.

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | grep -o '"file_path":"[^"]*"' | head -1 | sed 's/"file_path":"//;s/"//')

IS_PLANNING=false
case "$FILE_PATH" in
  */docs/specs/*|*/docs/plans/*) IS_PLANNING=true ;;
esac

IS_PROTECTED=false
BASENAME=$(basename "$FILE_PATH" 2>/dev/null)
case "$BASENAME" in
  CLAUDE.md|working-rules.md|change-decision-framework.md|enforcement-mechanisms.md|settings.local.json|plugin.json)
    IS_PROTECTED=true ;;
esac

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/config.sh"
if [ "$KT_CONFIGURED" = "true" ] && [ -n "$KT_CRITICAL_PATHS" ] && [ "$IS_PROTECTED" = "false" ]; then
  OLD_IFS="$IFS"
  IFS=','
  for PATTERN in $KT_CRITICAL_PATHS; do
    PREFIX=$(echo "$PATTERN" | sed 's|/\*$||;s|\*$||;s/^[[:space:]]*//;s/[[:space:]]*$//')
    [ -z "$PREFIX" ] && continue
    case "$FILE_PATH" in
      */"$PREFIX"/*) IS_PROTECTED=true; break ;;
    esac
  done
  IFS="$OLD_IFS"
fi

if [ "$IS_PLANNING" = "true" ] && [ "$IS_PROTECTED" = "false" ]; then
  echo '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"PLANNING PATH — abbreviated scope check. Output: [Rule 22 · Scope] OK — planning doc."}}'
else
  echo '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"POST-EDIT SCOPE CHECK — Required output after every edit. Verify: (1) scope held, (2) nothing extra touched, (3) no unnecessary rewrites, (4) matches decision, (5) secondary impact on parents/siblings/dependents. Output one of: PASS: [Rule 22 · Scope] PASS — [why + secondary status]. CONDITIONAL: [Rule 22 · Scope] PASS CONDITIONAL — [what done as planned]. Newline: Secondary: [attention]. Newline: Proposed: [action]. FAIL: [Rule 22 · Scope] FAIL — [what failed + affected]. Newline: Proposed: [fix]."}}'
fi
