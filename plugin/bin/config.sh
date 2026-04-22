#!/bin/sh
# config.sh — shared config reader for aria-ex1 hooks
# Sourced by pre-edit-check.sh, post-edit-check.sh, pre-explore-codemap-check.sh

KT_CONFIG="${KT_CONFIG:-$HOME/.claude/aria-ex1.local.md}"
KT_CONFIGURED=false
KT_CONFIG_ERROR=""
KT_CRITICAL_PATHS=""

# Escape a string for safe embedding in JSON values.
kt_json_escape() {
  printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/	/\\t/g' | tr '\n' ' '
}

if [ -f "$KT_CONFIG" ]; then
  KT_CONFIGURED=true
  KT_CRITICAL_PATHS=$(sed -n '/^---$/,/^---$/p' "$KT_CONFIG" | grep 'critical_paths:' | head -1 | sed 's/^[[:space:]]*critical_paths:[[:space:]]*//;s/^"//;s/"$//')
fi

# kt_detect_signals FILE_PATH
# Detect structural signals from an edit's file path. Echoes comma-separated
# advisory labels to stdout. Empty string if no signals match.
kt_detect_signals() {
  _kt_sp="$1"
  [ -z "$_kt_sp" ] && return
  _kt_sig=""
  _kt_bn=$(basename "$_kt_sp" 2>/dev/null)
  _kt_bnlow=$(printf '%s' "$_kt_bn" | tr '[:upper:]' '[:lower:]')

  _kt_append_signal() {
    if [ -z "$_kt_sig" ]; then
      _kt_sig="$1"
    else
      _kt_sig="${_kt_sig}, $1"
    fi
  }

  case "$_kt_sp" in
    */auth/*|*/permissions/*|*/security/*|*/jwt/*|*/login/*) _kt_append_signal "auth" ;;
  esac

  case "$_kt_sp" in
    */migrations/*|*/migrate/*) _kt_append_signal "migration" ;;
  esac

  case "$_kt_bn" in
    models.py|schema.ts|schema.prisma|*.prisma) _kt_append_signal "model" ;;
  esac

  case "$_kt_bn" in
    urls.py|routes.ts|route.ts|middleware.ts) _kt_append_signal "routing" ;;
  esac

  case "$_kt_bnlow" in
    *stripe*|*twilio*|*sendgrid*|*algolia*|*openai*|*vercel*|*supabase*|*auth0*|*firebase*|*segment*)
      _kt_append_signal "external-service" ;;
  esac

  printf '%s' "$_kt_sig"
}