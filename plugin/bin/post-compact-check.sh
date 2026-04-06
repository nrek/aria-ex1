#!/bin/sh
# post-compact-check.sh — PostCompact hook for aria-knowledge
# Notifies user that pre-compaction snapshots exist for review

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/config.sh"

# Skip if not configured or config invalid
if [ "$KT_CONFIGURED" = "false" ] || [ -n "$KT_CONFIG_ERROR" ]; then
  exit 0
fi

# Skip if knowledge folder missing
if [ ! -d "$KT_KNOWLEDGE_FOLDER" ]; then
  exit 0
fi

# Skip if auto_capture disabled
if [ "$KT_AUTO_CAPTURE" = "false" ]; then
  exit 0
fi

# Check if any pre-compact snapshots exist
CAPTURES_DIR="$KT_KNOWLEDGE_FOLDER/intake/pre-compact-captures"
SNAPSHOT_COUNT=$(find "$CAPTURES_DIR" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')

if [ "$SNAPSHOT_COUNT" -gt 0 ]; then
  MSG=$(kt_json_escape "ARIA: ${SNAPSHOT_COUNT} pre-compaction transcript snapshot(s) saved in ${CAPTURES_DIR}/. Uncaptured knowledge from the prior conversation may exist. Prompt user: Want me to scan the pre-compaction snapshot for extractable knowledge before continuing?")
  echo '{"hookSpecificOutput":{"hookEventName":"PostCompact","additionalContext":"'"$MSG"'"}}'
fi
