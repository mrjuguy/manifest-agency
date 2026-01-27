#!/usr/bin/env bash
# logger.sh - Structured JSON event logging for worker
#
# Usage:
#   source .claude/skills/worker/lib/logger.sh
#   init_logging 42
#   log_event "session_start" --arg issue "42" --arg agent "claude-worker"
#   log_event "error" --arg message "Failed" --arg exit_code "1"

# Global variables set by init_logging
LOG_FILE=""
SESSION_ID=""

# Initialize logging for an issue
# Sets LOG_FILE and SESSION_ID, creates log directory if needed
init_logging() {
  local issue="$1"

  LOG_FILE=".worker/logs/issue-${issue}-$(date +%s).jsonl"
  SESSION_ID="session-$(uuidgen 2>/dev/null || echo "$$-$(date +%s)")"

  mkdir -p "$(dirname "$LOG_FILE")"

  # Log session start automatically
  log_event "session_start" \
    --arg issue "$issue" \
    --arg agent "claude-worker" \
    --arg pwd "$PWD" \
    --arg timestamp_unix "$(date +%s)"
}

# Log a structured JSON event
# Arguments: event_type [--arg key value]...
log_event() {
  local event_type="$1"
  shift

  # Collect all --arg pairs into arrays for processing
  local -a arg_flags=()
  local -a arg_names=()

  # Parse --arg key value pairs
  while [ $# -gt 0 ]; do
    if [ "$1" = "--arg" ]; then
      arg_flags+=("--arg" "$2" "$3")
      arg_names+=("$2")
      shift 3
    else
      shift
    fi
  done

  # Build jq expression to construct data object from args
  local jq_expr='{'
  local first=true
  for name in "${arg_names[@]}"; do
    if [ "$first" = true ]; then
      first=false
    else
      jq_expr+=', '
    fi
    jq_expr+="$name: \$$name"
  done
  jq_expr+='}'

  # Build data object
  local data_json
  if [ ${#arg_flags[@]} -gt 0 ]; then
    data_json=$(jq -n "${arg_flags[@]}" "$jq_expr")
  else
    data_json='{}'
  fi

  # Emit structured event as single line
  jq -nc \
    --arg timestamp "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
    --arg event_type "$event_type" \
    --arg event_id "evt-$(date +%s%N)-$$" \
    --arg session_id "$SESSION_ID" \
    --argjson data "$data_json" \
    '{
      timestamp: $timestamp,
      event_type: $event_type,
      event_id: $event_id,
      session_id: $session_id,
      data: $data
    }' >> "$LOG_FILE"
}

# Log session end (should be called via trap or explicit call)
log_session_end() {
  local reason="${1:-normal}"
  local exit_code="${2:-0}"

  log_event "session_end" \
    --arg reason "$reason" \
    --arg exit_code "$exit_code"
}
