#!/bin/sh
# pre-edit-check.sh — PreToolUse hook for Edit|Write
#
# v1.1: turn-scoped compliance detection adapted from aria-knowledge v2.10.6.
# Walks backward through the transcript's assistant messages, collecting text
# blocks up to the previous Edit/Write tool_use or user message (whicheve
# comes first). Scans those text blocks for a [Rule 22...] marker. Denies the
# tool call if no marker found; fail-open on any parse/detector error.
#
# Decision hierarchy (path classification):
#   1. Planning path (and not protected)  -> abbreviated variant expected
#   2. Protected path                     -> full variant expected
#   3. No batch manifests in aria-ex1     -> full variant
#
# Structural signals (auth, migration, model, routing, external-service) are
# surfaced in the deny message when detected, so the recovery block is
# informed by risk context.
#
# Safety: fail-open on any detector or parse failure.

INPUT=$(cat)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/config.sh"

FILE_PATH=$(echo "$INPUT" | grep -o '"file_path":"[^"]*"' | head -1 | sed 's/"file_path":"//;s/"//')
TRANSCRIPT=$(echo "$INPUT" | grep -o '"transcript_path":"[^"]*"' | head -1 | sed 's/"transcript_path":"//;s/"//')
TOOL_USE_ID=$(echo "$INPUT" | grep -o '"tool_use_id":"[^"]*"' | head -1 | sed 's/"tool_use_id":"//;s/"//')

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

SIGNALS=$(kt_detect_signals "$FILE_PATH")

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

EXPECTED="full"
if [ "$IS_PLANNING" = "true" ] && [ "$IS_PROTECTED" = "false" ]; then
  EXPECTED="planning"
fi

# Compliance detection: parse transcript, walk BACKWARD through assistant
# messages from the one containing our tool_use, collecting text blocks until
# we hit either (a) the previous Edit/Write tool_use, or (b) a user message.
COMPLIANT="unknown"
if [ -n "$TRANSCRIPT" ] && [ -n "$TOOL_USE_ID" ] && [ -f "$TRANSCRIPT" ]; then
  COMPLIANT=$(TRANSCRIPT="$TRANSCRIPT" TOOL_USE_ID="$TOOL_USE_ID" python3 - <<'PY' 2>/dev/null
import json, os, re, sys
try:
    path = os.environ["TRANSCRIPT"]
    tool_use_id = os.environ["TOOL_USE_ID"]
    MARKER = re.compile(r"\[Rule 22(\s\xb7\s[^\]]+)?\]")
    with open(path) as f:
        lines = f.readlines()

    target_line_idx = None
    target_content_idx = None
    for i, line in enumerate(lines):
        try:
            evt = json.loads(line)
        except Exception:
            continue
        if evt.get("type") != "assistant":
            continue
        content = evt.get("message", {}).get("content", [])
        if not isinstance(content, list):
            continue
        for j, b in enumerate(content):
            if isinstance(b, dict) and b.get("type") == "tool_use" and b.get("id") == tool_use_id:
                target_line_idx = i
                target_content_idx = j
                break
        if target_line_idx is not None:
            break

    if target_line_idx is None:
        print("unknown")
        sys.exit(0)

    found_prior_edit_in_target_msg = False
    text_blocks = []

    target_evt = json.loads(lines[target_line_idx])
    target_content = target_evt["message"]["content"]
    for b in target_content[:target_content_idx]:
        if isinstance(b, dict):
            if b.get("type") == "tool_use" and b.get("name") in ("Edit", "Write"):
                text_blocks = []
                found_prior_edit_in_target_msg = True
            elif b.get("type") == "text":
                text_blocks.append(b.get("text", ""))

    if not found_prior_edit_in_target_msg:
        for i in range(target_line_idx - 1, -1, -1):
            try:
                evt = json.loads(lines[i])
            except Exception:
                continue
            evt_type = evt.get("type")
            if evt_type == "user":
                break
            if evt_type != "assistant":
                continue
            content = evt.get("message", {}).get("content", [])
            if not isinstance(content, list):
                continue
            msg_text_blocks = []
            cap_reached = False
            for b in content:
                if isinstance(b, dict):
                    if b.get("type") == "tool_use" and b.get("name") in ("Edit", "Write"):
                        msg_text_blocks = []
                        cap_reached = True
                    elif b.get("type") == "text":
                        msg_text_blocks.append(b.get("text", ""))
            text_blocks = msg_text_blocks + text_blocks
            if cap_reached:
                break

    for txt in text_blocks:
        if MARKER.search(txt):
            print("yes")
            sys.exit(0)
    print("no")
except Exception:
    print("unknown")
PY
  )
  [ -z "$COMPLIANT" ] && COMPLIANT="unknown"
fi

# Fail-open: allow silently when compliant or when we couldn't verify.
if [ "$COMPLIANT" = "yes" ] || [ "$COMPLIANT" = "unknown" ]; then
  exit 0
fi

# Non-compliant: deny with recovery message naming the expected format
case "$EXPECTED" in
  planning)
    FMT='[Rule 22 · Planning] <filename>'
    ;;
  *)
    FMT='[Rule 22] Low Impact — <change> (<why low>) / Change — ... / Solutions — ... / Execute — ...  OR  [Rule 22] High Impact — <change> (<why high>) with full 7-step format per rules/change-decision-framework.md'
    ;;
esac

SIGNAL_NOTE=""
[ -n "$SIGNALS" ] && SIGNAL_NOTE=" Structural signals detected (${SIGNALS}) — full assessment required."

REASON="Rule 22 compliance block missing. Emit the [Rule 22] marker as a text output (not thinking) ABOVE this Edit/Write tool call in the same assistant turn, between the previous Edit/Write (if any) and this one. Then retry the same tool call.${SIGNAL_NOTE} Format: ${FMT}. See rules/change-decision-framework.md 'Ordering (required)'."
REASON_ESCAPED=$(kt_json_escape "$REASON")

printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$REASON_ESCAPED"
