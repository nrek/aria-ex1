#!/bin/sh
# config.sh — shared config reader for aria-knowledge hooks
# Sourced by session-start-check.sh and session-stop-check.sh

KT_CONFIG="$HOME/.claude/aria-knowledge.local.md"
KT_CONFIGURED=false
KT_CONFIG_ERROR=""

# Escape a string for safe embedding in JSON values.
# Handles backslashes, double quotes, tabs, and strips newlines.
kt_json_escape() {
  printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/	/\\t/g' | tr '\n' ' '
}

if [ -f "$KT_CONFIG" ]; then
  KT_CONFIGURED=true

  # Parse YAML frontmatter between --- markers
  KT_KNOWLEDGE_FOLDER=$(sed -n '/^---$/,/^---$/p' "$KT_CONFIG" | grep '^knowledge_folder:' | sed 's/^knowledge_folder: *//')
  KT_CADENCE_KNOWLEDGE=$(sed -n '/^---$/,/^---$/p' "$KT_CONFIG" | grep '^audit_cadence_knowledge:' | sed 's/^audit_cadence_knowledge: *//')
  KT_CADENCE_CONFIG=$(sed -n '/^---$/,/^---$/p' "$KT_CONFIG" | grep '^audit_cadence_config:' | sed 's/^audit_cadence_config: *//')
  KT_EXPLANATORY=$(sed -n '/^---$/,/^---$/p' "$KT_CONFIG" | grep '^explanatory_plugin:' | sed 's/^explanatory_plugin: *//')
  KT_FREEFORM_THRESHOLD=$(sed -n '/^---$/,/^---$/p' "$KT_CONFIG" | grep '^freeform_promotion_threshold:' | sed 's/^freeform_promotion_threshold: *//')
  KT_STALENESS_MONTHS=$(sed -n '/^---$/,/^---$/p' "$KT_CONFIG" | grep '^staleness_threshold_months:' | sed 's/^staleness_threshold_months: *//')
  KT_CADENCE_UPDATE=$(sed -n '/^---$/,/^---$/p' "$KT_CONFIG" | grep '^audit_cadence_update:' | sed 's/^audit_cadence_update: *//')
  KT_AUTO_CAPTURE=$(sed -n '/^---$/,/^---$/p' "$KT_CONFIG" | grep '^auto_capture:' | sed 's/^auto_capture: *//')
  KT_CRITICAL_PATHS=$(sed -n '/^---$/,/^---$/p' "$KT_CONFIG" | grep '^critical_paths:' | sed 's/^critical_paths: *//')

  # Defaults if not set
  KT_CADENCE_KNOWLEDGE=${KT_CADENCE_KNOWLEDGE:-3}
  KT_CADENCE_CONFIG=${KT_CADENCE_CONFIG:-14}
  KT_EXPLANATORY=${KT_EXPLANATORY:-false}
  KT_FREEFORM_THRESHOLD=${KT_FREEFORM_THRESHOLD:-3}
  KT_STALENESS_MONTHS=${KT_STALENESS_MONTHS:-6}
  KT_CADENCE_UPDATE=${KT_CADENCE_UPDATE:-30}
  KT_AUTO_CAPTURE=${KT_AUTO_CAPTURE:-true}
  # KT_CRITICAL_PATHS intentionally has no default — empty means no critical paths

  # Validate knowledge_folder is non-empty
  if [ -z "$KT_KNOWLEDGE_FOLDER" ]; then
    KT_CONFIGURED=false
    KT_CONFIG_ERROR="knowledge_folder could not be parsed from config file. Check for missing --- markers, Windows line endings, or malformed YAML."
  # Validate knowledge_folder is an absolute path
  elif case "$KT_KNOWLEDGE_FOLDER" in /*) false ;; *) true ;; esac; then
    KT_CONFIGURED=false
    KT_CONFIG_ERROR="knowledge_folder must be an absolute path (got: $KT_KNOWLEDGE_FOLDER)."
  # Validate knowledge_folder has no path traversal
  elif case "$KT_KNOWLEDGE_FOLDER" in *..*) true ;; *) false ;; esac; then
    KT_CONFIGURED=false
    KT_CONFIG_ERROR="knowledge_folder must not contain '..' (got: $KT_KNOWLEDGE_FOLDER)."
  fi

  # Validate cadence values are numeric, reset to defaults if not
  case "$KT_CADENCE_KNOWLEDGE" in
    ''|*[!0-9]*) KT_CADENCE_KNOWLEDGE=3 ;;
  esac
  case "$KT_CADENCE_CONFIG" in
    ''|*[!0-9]*) KT_CADENCE_CONFIG=14 ;;
  esac
  case "$KT_FREEFORM_THRESHOLD" in
    ''|*[!0-9]*) KT_FREEFORM_THRESHOLD=3 ;;
  esac
  case "$KT_STALENESS_MONTHS" in
    ''|*[!0-9]*) KT_STALENESS_MONTHS=6 ;;
  esac
  case "$KT_CADENCE_UPDATE" in
    ''|*[!0-9]*) KT_CADENCE_UPDATE=30 ;;
  esac
  case "$KT_AUTO_CAPTURE" in
    true|false) ;; # valid
    *) KT_AUTO_CAPTURE=true ;;
  esac
fi
