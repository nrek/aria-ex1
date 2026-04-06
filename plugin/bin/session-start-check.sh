#!/bin/sh
# session-start-check.sh — SessionStart hook for aria-knowledge
# Checks audit cadences and prompts when audits are due

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
  MSG=$(kt_json_escape "aria-knowledge: configured knowledge folder does not exist at $KT_KNOWLEDGE_FOLDER. Run /setup to reconfigure.")
  echo '{"systemMessage":"'"$MSG"'"}'
  exit 0
fi

# Date arithmetic helper — returns epoch seconds for a YYYY-MM-DD date
# Supports macOS (date -j -f) and Linux (date -d)
# Returns empty string on failure (caller must check)
date_to_epoch() {
  date -j -f "%Y-%m-%d" "$1" +%s 2>/dev/null || date -d "$1" +%s 2>/dev/null
}

TODAY=$(date +%Y-%m-%d)
TODAY_EPOCH=$(date_to_epoch "$TODAY")

# Guard: if we can't compute today's epoch, date commands are incompatible
if [ -z "$TODAY_EPOCH" ]; then
  echo '{"systemMessage":"aria-knowledge: failed to compute today'\''s date as epoch. Date commands may not be compatible with this platform."}'
  exit 0
fi

KNOWLEDGE_LOG="$KT_KNOWLEDGE_FOLDER/logs/knowledge-audit-log.md"
CONFIG_LOG="$KT_KNOWLEDGE_FOLDER/logs/config-audit-log.md"

MESSAGES=""

# First-run detection — show welcome instead of audit prompts for new users
IS_FIRST_RUN=false
if [ -f "$KNOWLEDGE_LOG" ]; then
  if grep -q '(no audits yet)' "$KNOWLEDGE_LOG"; then
    IS_FIRST_RUN=true
  fi
else
  IS_FIRST_RUN=true
fi

if [ "$IS_FIRST_RUN" = "true" ]; then
  MESSAGES="WELCOME — aria-knowledge is set up and active. Here is what is running: (1) Knowledge capture — run /extract after completing tasks to save insights. (2) Decision discipline — Rule 22 checks appear before edits to ensure changes are intentional. (3) Audit prompts — you will be prompted to review captured knowledge periodically. Available commands: /context [topic] to load relevant knowledge, /rules to look up working rules, /backlog to see pending items, /stats for knowledge base health, /clip to save URLs or snippets. These features work automatically — just start working."
  MESSAGES_ESCAPED=$(kt_json_escape "$MESSAGES")
  echo '{"systemMessage":"'"$MESSAGES_ESCAPED"'"}'
  echo "$(date +%Y-%m-%dT%H:%M:%S) session-start-check: first-run welcome" >> "$KT_KNOWLEDGE_FOLDER/logs/hook-debug.log" 2>/dev/null
  exit 0
fi

# Check knowledge audit cadence
if [ -f "$KNOWLEDGE_LOG" ]; then
  LAST_KA_DATE=$(grep '^\- \*\*Date:\*\*' "$KNOWLEDGE_LOG" | head -1 | sed 's/.*\*\*Date:\*\* //' | sed 's/ .*//')
  if [ -n "$LAST_KA_DATE" ] && echo "$LAST_KA_DATE" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'; then
    LAST_KA_EPOCH=$(date_to_epoch "$LAST_KA_DATE")
    if [ -n "$LAST_KA_EPOCH" ]; then
      DAYS_SINCE_KA=$(( (TODAY_EPOCH - LAST_KA_EPOCH) / 86400 ))
      if [ "$DAYS_SINCE_KA" -ge "$KT_CADENCE_KNOWLEDGE" ]; then
        MESSAGES="${MESSAGES}KNOWLEDGE AUDIT CHECK — It has been ${DAYS_SINCE_KA} days since the last knowledge audit (configured cadence: every ${KT_CADENCE_KNOWLEDGE} days). Prompt user: It has been ${DAYS_SINCE_KA} days since the last knowledge audit. Want me to scan for extractable knowledge? "
      fi
    else
      MESSAGES="${MESSAGES}KNOWLEDGE AUDIT CHECK — Could not parse last audit date ($LAST_KA_DATE). Prompt user: Knowledge audit date could not be parsed. Want me to scan for extractable knowledge? "
    fi
  else
    MESSAGES="${MESSAGES}KNOWLEDGE AUDIT CHECK — No previous knowledge audit found. Prompt user: No knowledge audit has been run yet. Want me to scan for extractable knowledge? "
  fi
else
  MESSAGES="${MESSAGES}KNOWLEDGE AUDIT CHECK — Knowledge audit log not found. Prompt user: No knowledge audit has been run yet. Want me to scan for extractable knowledge? "
fi

# Check config audit cadence
if [ -f "$CONFIG_LOG" ]; then
  LAST_CA_DATE=$(grep '^\- \*\*Date:\*\*' "$CONFIG_LOG" | head -1 | sed 's/.*\*\*Date:\*\* //' | sed 's/ .*//')
  if [ -n "$LAST_CA_DATE" ] && echo "$LAST_CA_DATE" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'; then
    LAST_CA_EPOCH=$(date_to_epoch "$LAST_CA_DATE")
    if [ -n "$LAST_CA_EPOCH" ]; then
      DAYS_SINCE_CA=$(( (TODAY_EPOCH - LAST_CA_EPOCH) / 86400 ))
      if [ "$DAYS_SINCE_CA" -ge "$KT_CADENCE_CONFIG" ]; then
        MESSAGES="${MESSAGES}CONFIG AUDIT CHECK — It has been ${DAYS_SINCE_CA} days since the last config and docs audit (configured cadence: every ${KT_CADENCE_CONFIG} days). Prompt user: It has been ${DAYS_SINCE_CA} days since the last config audit. Want me to check for drift? "
      fi
    else
      MESSAGES="${MESSAGES}CONFIG AUDIT CHECK — Could not parse last audit date ($LAST_CA_DATE). Prompt user: Config audit date could not be parsed. Want me to check for drift? "
    fi
  else
    MESSAGES="${MESSAGES}CONFIG AUDIT CHECK — No previous config audit found. Prompt user: No config audit has been run yet. Want me to check for drift? "
  fi
else
  MESSAGES="${MESSAGES}CONFIG AUDIT CHECK — Config audit log not found. Prompt user: No config audit has been run yet. Want me to check for drift? "
fi

# Check update cadence — parse last /setup date from config file
LAST_SETUP_DATE=$(grep '/setup on ' "$KT_CONFIG" | tail -1 | sed 's|.*/setup on ||' | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}')
if [ -n "$LAST_SETUP_DATE" ]; then
  LAST_SETUP_EPOCH=$(date_to_epoch "$LAST_SETUP_DATE")
  if [ -n "$LAST_SETUP_EPOCH" ]; then
    DAYS_SINCE_SETUP=$(( (TODAY_EPOCH - LAST_SETUP_EPOCH) / 86400 ))
    if [ "$DAYS_SINCE_SETUP" -ge "$KT_CADENCE_UPDATE" ]; then
      MESSAGES="${MESSAGES}UPDATE CHECK — It has been ${DAYS_SINCE_SETUP} days since the last /setup run (configured cadence: every ${KT_CADENCE_UPDATE} days). Prompt user: It has been ${DAYS_SINCE_SETUP} days since you last ran /setup. Run /setup to check for plugin template updates. "
    fi
  fi
fi

# Knowledge surfacing — prompt Claude to suggest /context after user states task
INDEX_FILE="$KT_KNOWLEDGE_FOLDER/index.md"
if [ -f "$INDEX_FILE" ]; then
  MESSAGES="${MESSAGES}KNOWLEDGE CONTEXT — After the user describes their task, check if the knowledge index exists at ${KT_KNOWLEDGE_FOLDER}/index.md. If it does, suggest a /context command with tags relevant to their stated task. Only suggest once per session. Do not block — just offer. Example: 'Before we start — you have knowledge docs that may be relevant. Want me to run /context api pagination?' "
fi

# Output only if there are messages
if [ -n "$MESSAGES" ]; then
  MESSAGES_ESCAPED=$(kt_json_escape "$MESSAGES")
  echo '{"systemMessage":"'"$MESSAGES_ESCAPED"'"}'
fi

# Diagnostic log — confirms hook ran, distinguishes success from silent failure
echo "$(date +%Y-%m-%dT%H:%M:%S) session-start-check: messages=${#MESSAGES}" >> "$KT_KNOWLEDGE_FOLDER/logs/hook-debug.log" 2>/dev/null
