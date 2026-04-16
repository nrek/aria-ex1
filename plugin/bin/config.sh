#!/bin/sh
# config.sh — shared config reader for aria-ex1 hooks
# Sourced by pre-edit-check.sh, post-edit-check.sh, pre-explore-codemap-check.sh

KT_CONFIG="${KT_CONFIG:-$HOME/.claude/aria-ex1.local.md}"
KT_CONFIGURED=false
KT_CONFIG_ERROR=""
KT_CRITICAL_PATHS=""

# Escape a string for safe embedding in JSON values (used by pre-explore hook).
kt_json_escape() {
  printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/	/\\t/g' | tr '\n' ' '
}

if [ -f "$KT_CONFIG" ]; then
  KT_CONFIGURED=true
  # critical_paths: under rules: or top-level (comma-separated glob-ish prefixes)
  KT_CRITICAL_PATHS=$(sed -n '/^---$/,/^---$/p' "$KT_CONFIG" | grep 'critical_paths:' | head -1 | sed 's/^[[:space:]]*critical_paths:[[:space:]]*//;s/^"//;s/"$//')
fi
