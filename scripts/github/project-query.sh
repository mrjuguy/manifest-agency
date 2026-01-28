#!/usr/bin/env bash
#
# project-query.sh - Query GitHub Project items with filters
#
# Enables agents to discover available work matching their capabilities.
# Filters project items by status, claimed state, agent type, phase, priority.
#
# Usage:
#   project-query.sh [options]
#
# Options:
#   --status <status>       Filter by status (Ready, In Progress, etc.)
#   --unclaimed             Filter where Claimed By is empty
#   --agent-type <type>     Filter by agent type label
#   --phase <number>        Filter by phase
#   --priority <P0|P1|P2|P3> Filter by priority
#   --limit <number>        Max items (default: 50)
#   --format <fmt>          Output format: json|table|list (default: table)
#   --project <number>      Project number (default: 1)
#   --help                  Show this help
#
# Examples:
#   # Find unclaimed Ready issues for any agent
#   project-query.sh --status Ready --unclaimed
#
#   # Find all in-progress work
#   project-query.sh --status "In Progress"
#
#   # Find work by phase
#   project-query.sh --phase 2
#
#   # Find P0 priority items
#   project-query.sh --priority P0-critical
#
#   # Find work for specific agent type
#   project-query.sh --agent-type "agent:backend-developer" --unclaimed
#

set -euo pipefail

# --- Default values ---
PROJECT_NUMBER="1"
LIMIT="50"
FORMAT="table"
STATUS=""
UNCLAIMED=false
AGENT_TYPE=""
PHASE=""
PRIORITY=""

# --- Parse arguments ---
while [[ $# -gt 0 ]]; do
  case $1 in
    --status)
      STATUS="$2"
      shift 2
      ;;
    --unclaimed)
      UNCLAIMED=true
      shift
      ;;
    --agent-type)
      AGENT_TYPE="$2"
      shift 2
      ;;
    --phase)
      PHASE="$2"
      shift 2
      ;;
    --priority)
      PRIORITY="$2"
      shift 2
      ;;
    --limit)
      LIMIT="$2"
      shift 2
      ;;
    --format)
      FORMAT="$2"
      shift 2
      ;;
    --project)
      PROJECT_NUMBER="$2"
      shift 2
      ;;
    --help)
      sed -n '2,/^$/p' "$0" | sed 's/^# //; s/^#//'
      exit 0
      ;;
    *)
      echo "Error: Unknown option $1"
      echo "Run with --help for usage"
      exit 1
      ;;
  esac
done

# --- Validation ---
if ! command -v jq > /dev/null 2>&1; then
  echo "Error: jq is required for filtering"
  exit 1
fi

# --- Query project items ---
echo "Querying project #$PROJECT_NUMBER..." >&2

PROJECT_DATA=$(gh project item-list "$PROJECT_NUMBER" --owner "@me" --format json --limit "$LIMIT" 2>&1)

if [ $? -ne 0 ]; then
  echo "Error querying project: $PROJECT_DATA" >&2
  exit 1
fi

# --- Build jq filter ---
JQ_FILTER='.items[]'

# Filter by status
if [ -n "$STATUS" ]; then
  # The field access depends on gh CLI output structure
  # Typically: .fieldValueByName or direct field access
  JQ_FILTER="$JQ_FILTER | select(.status.name? == \"$STATUS\" or .status? == \"$STATUS\")"
fi

# Filter by unclaimed
if [ "$UNCLAIMED" = true ]; then
  # Check if Claimed By field is null or empty
  JQ_FILTER="$JQ_FILTER | select(
    (.\"claimed by\"? == null or .\"claimed by\"? == \"\") or
    (.claimedBy? == null or .claimedBy? == \"\") or
    (has(\"fieldValueByName\") and (.fieldValueByName[\"Claimed By\"]? == null or .fieldValueByName[\"Claimed By\"]? == \"\"))
  )"
fi

# Filter by agent type
if [ -n "$AGENT_TYPE" ]; then
  JQ_FILTER="$JQ_FILTER | select(
    (.\"agent type\"? == \"$AGENT_TYPE\") or
    (.agentType? == \"$AGENT_TYPE\") or
    (.labels[]? | contains(\"$AGENT_TYPE\"))
  )"
fi

# Filter by phase
if [ -n "$PHASE" ]; then
  JQ_FILTER="$JQ_FILTER | select(
    (.phase? == \"phase:$PHASE\" or .phase? == \"$PHASE\") or
    (.labels[]? | contains(\"phase:$PHASE\"))
  )"
fi

# Filter by priority
if [ -n "$PRIORITY" ]; then
  JQ_FILTER="$JQ_FILTER | select(
    (.priority? == \"$PRIORITY\" or .priority.name? == \"$PRIORITY\") or
    (.labels[]? | contains(\"$PRIORITY\"))
  )"
fi

# --- Apply filter and format output ---
FILTERED_DATA=$(echo "$PROJECT_DATA" | jq -c "$JQ_FILTER" 2>/dev/null || echo "[]")

case "$FORMAT" in
  json)
    # Output as JSON array
    echo "$FILTERED_DATA" | jq -s '.'
    ;;

  table)
    # Output as formatted table
    echo "Issue | Title | Status | Priority | Phase | Claimed By"
    echo "------|-------|--------|----------|-------|------------"
    echo "$FILTERED_DATA" | jq -r '
      [
        (.number? // .id? // "N/A"),
        (.title? // .content.title? // "Untitled"),
        (.status? // .status.name? // "N/A"),
        (.priority? // .priority.name? // "N/A"),
        (.phase? // "N/A"),
        (.\"claimed by\"? // .claimedBy? // "Unclaimed")
      ] | @tsv
    ' | column -t -s $'\t'
    ;;

  list)
    # Output as simple list: issue number and title
    echo "$FILTERED_DATA" | jq -r '
      "#\(.number? // .id? // "N/A") - \(.title? // .content.title? // "Untitled")"
    '
    ;;

  *)
    echo "Error: Unknown format '$FORMAT'"
    echo "Valid formats: json, table, list"
    exit 1
    ;;
esac

# Count results
RESULT_COUNT=$(echo "$FILTERED_DATA" | jq -s 'length')
echo "" >&2
echo "Found $RESULT_COUNT items" >&2

exit 0
