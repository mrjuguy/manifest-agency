#!/usr/bin/env bash
# parser.sh - GitHub issue body section extraction
#
# Usage:
#   source .claude/skills/worker/lib/parser.sh
#   parse_issue_body 42
#   echo "$ISSUE_SUMMARY"
#   echo "$ISSUE_ACCEPTANCE"

# Parsed issue content (set by parse_issue_body)
ISSUE_TITLE=""
ISSUE_BODY=""
ISSUE_SUMMARY=""
ISSUE_CONTEXT=""
ISSUE_ACCEPTANCE=""
ISSUE_SUBTASKS=""
ISSUE_DEPENDENCIES=""
ISSUE_NOTES=""
ISSUE_LABELS=""

# Parse issue body and extract sections
# Arguments: issue_number
# Returns: 0 on success, 1 on failure
# Sets: ISSUE_* variables
parse_issue_body() {
  local issue="$1"

  # Fetch issue data
  local issue_json
  issue_json=$(gh issue view "$issue" --json title,body,labels 2>&1)

  if [ $? -ne 0 ]; then
    echo "[error] Failed to fetch issue #${issue}: $issue_json"
    return 1
  fi

  # Extract fields
  ISSUE_TITLE=$(echo "$issue_json" | jq -r '.title')
  ISSUE_BODY=$(echo "$issue_json" | jq -r '.body')
  ISSUE_LABELS=$(echo "$issue_json" | jq -r '.labels[].name' | tr '\n' ',' | sed 's/,$//')

  if [ -z "$ISSUE_BODY" ] || [ "$ISSUE_BODY" = "null" ]; then
    echo "[error] Issue #${issue} has no body"
    return 1
  fi

  # Extract sections using ## headers
  # Pattern: capture content between ## Section and next ## or end of file
  ISSUE_SUMMARY=$(extract_section "Summary")
  ISSUE_CONTEXT=$(extract_section "Context")
  ISSUE_ACCEPTANCE=$(extract_section "Acceptance Criteria")
  ISSUE_SUBTASKS=$(extract_section "Subtasks")
  ISSUE_DEPENDENCIES=$(extract_section "Dependencies")
  ISSUE_NOTES=$(extract_section "Notes")

  # Validate required sections
  if [ -z "$ISSUE_SUMMARY" ]; then
    echo "[warning] Issue #${issue} missing Summary section"
  fi

  if [ -z "$ISSUE_ACCEPTANCE" ]; then
    echo "[warning] Issue #${issue} missing Acceptance Criteria section"
  fi

  return 0
}

# Extract content of a named section from ISSUE_BODY
# Arguments: section_name
# Returns: Section content (may be empty)
extract_section() {
  local section_name="$1"

  # Use awk to extract content between ## Section and next ##
  echo "$ISSUE_BODY" | awk -v section="## $section_name" '
    $0 ~ section { found=1; next }
    /^## / && found { exit }
    found { print }
  ' | sed 's/^[[:space:]]*//' | sed '/^$/d'
}

# Get parsed issue as JSON (for logging)
get_parsed_issue_json() {
  jq -nc \
    --arg title "$ISSUE_TITLE" \
    --arg summary "$ISSUE_SUMMARY" \
    --arg acceptance "$ISSUE_ACCEPTANCE" \
    --arg labels "$ISSUE_LABELS" \
    '{
      title: $title,
      summary: $summary,
      acceptance: $acceptance,
      labels: $labels
    }'
}

# Check if issue has required sections for worker execution
# Returns: 0 if valid, 1 if missing required sections
validate_issue_for_worker() {
  local errors=0

  if [ -z "$ISSUE_SUMMARY" ]; then
    echo "[error] Missing required section: Summary"
    errors=$((errors + 1))
  fi

  if [ -z "$ISSUE_ACCEPTANCE" ]; then
    echo "[error] Missing required section: Acceptance Criteria"
    errors=$((errors + 1))
  fi

  if [ $errors -gt 0 ]; then
    echo ""
    echo "Issue must have ## Summary and ## Acceptance Criteria sections"
    return 1
  fi

  return 0
}
