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

  # Defaults if not set
  KT_CADENCE_KNOWLEDGE=${KT_CADENCE_KNOWLEDGE:-3}
  KT_CADENCE_CONFIG=${KT_CADENCE_CONFIG:-14}
  KT_EXPLANATORY=${KT_EXPLANATORY:-false}

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
fi
