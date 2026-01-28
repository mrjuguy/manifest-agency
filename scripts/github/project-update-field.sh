#!/usr/bin/env bash
#
# project-update-field.sh - Update any GitHub Project field
#
# Generic field update script providing flexibility for any project field.
# Handles both text and single select field types via GraphQL mutation.
#
# Usage:
#   project-update-field.sh <issue-number> --field <name> --value <value> [options]
#
# Required:
#   <issue-number>        Issue number to update (positional)
#   --field <name>        Field name (Status, Priority, Complexity, etc.)
#   --value <value>       New value for the field
#
# Optional:
#   --project <number>    Project number (default: 1)
#   --help                Show this help
#
# Examples:
#   # Update priority
#   project-update-field.sh 42 --field Priority --value P1-high
#
#   # Update complexity estimate
#   project-update-field.sh 42 --field Complexity --value M
#
#   # Update phase
#   project-update-field.sh 42 --field Phase --value "phase:3"
#
#   # Set agent type
#   project-update-field.sh 42 --field "Agent Type" --value "agent:backend-developer"
#
#   # Update claimed by (text field)
#   project-update-field.sh 42 --field "Claimed By" --value "gsd-executor-01"
#

set -euo pipefail

# --- Configuration ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CACHE_FILE="$REPO_ROOT/.cache/github/project-fields.json"

# --- Default values ---
PROJECT_NUMBER="1"
ISSUE_NUMBER=""
FIELD_NAME=""
FIELD_VALUE=""

# --- Parse arguments ---
if [[ $# -gt 0 && ! "$1" =~ ^-- ]]; then
  ISSUE_NUMBER="$1"
  shift
fi

while [[ $# -gt 0 ]]; do
  case $1 in
    --field)
      FIELD_NAME="$2"
      shift 2
      ;;
    --value)
      FIELD_VALUE="$2"
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
if [ -z "$ISSUE_NUMBER" ]; then
  echo "Error: Issue number is required (positional argument)"
  exit 1
fi

if [ -z "$FIELD_NAME" ]; then
  echo "Error: --field is required"
  exit 1
fi

if [ -z "$FIELD_VALUE" ]; then
  echo "Error: --value is required"
  exit 1
fi

if [ ! -f "$CACHE_FILE" ]; then
  echo "Error: Field cache not found at $CACHE_FILE"
  echo "Run project-bootstrap.sh first to create field cache"
  exit 1
fi

if ! command -v jq > /dev/null 2>&1; then
  echo "Error: jq is required"
  exit 1
fi

# --- Load field definitions ---
echo "Loading field definitions from cache..."

FIELD_DATA=$(jq -r ".data.organization.projectV2.fields.nodes[] | select(.name==\"$FIELD_NAME\")" "$CACHE_FILE")

if [ -z "$FIELD_DATA" ]; then
  echo "Error: Field '$FIELD_NAME' not found in cache"
  echo "Available fields:"
  jq -r '.data.organization.projectV2.fields.nodes[].name' "$CACHE_FILE"
  exit 1
fi

FIELD_ID=$(echo "$FIELD_DATA" | jq -r '.id')
FIELD_TYPE=$(echo "$FIELD_DATA" | jq -r '.__typename')

echo "Field: $FIELD_NAME"
echo "Type: $FIELD_TYPE"
echo "ID: $FIELD_ID"

# --- Get option ID for single select fields ---
OPTION_ID=""
if [ "$FIELD_TYPE" = "ProjectV2SingleSelectField" ]; then
  OPTION_ID=$(echo "$FIELD_DATA" | jq -r ".options[] | select(.name==\"$FIELD_VALUE\") | .id")

  if [ -z "$OPTION_ID" ]; then
    echo "Error: Value '$FIELD_VALUE' not found in field options"
    echo "Available options:"
    echo "$FIELD_DATA" | jq -r '.options[].name'
    exit 1
  fi

  echo "Option ID: $OPTION_ID"
fi

# --- Get project item ID for the issue ---
echo "Finding project item ID for issue #$ISSUE_NUMBER..."

# First get the issue node ID
ISSUE_NODE_ID=$(gh api graphql -f query='
  query($owner: String!, $repo: String!, $number: Int!) {
    repository(owner: $owner, name: $repo) {
      issue(number: $number) {
        id
      }
    }
  }
' -f owner="$(gh repo view --json owner -q .owner.login)" \
  -f repo="$(gh repo view --json name -q .name)" \
  -F number="$ISSUE_NUMBER" \
  -q '.data.repository.issue.id')

if [ -z "$ISSUE_NODE_ID" ]; then
  echo "Error: Issue #$ISSUE_NUMBER not found"
  exit 1
fi

echo "Issue node ID: $ISSUE_NODE_ID"

# Get project data to find item ID
PROJECT_NODE_ID=$(jq -r '.data.organization.projectV2.id' "$CACHE_FILE")

PROJECT_ITEM_ID=$(gh api graphql -f query='
  query($projectId: ID!, $contentId: ID!) {
    node(id: $projectId) {
      ... on ProjectV2 {
        items(first: 100) {
          nodes {
            id
            content {
              ... on Issue {
                id
              }
            }
          }
        }
      }
    }
  }
' -f projectId="$PROJECT_NODE_ID" \
  -f contentId="$ISSUE_NODE_ID" \
  -q ".data.node.items.nodes[] | select(.content.id==\"$ISSUE_NODE_ID\") | .id")

if [ -z "$PROJECT_ITEM_ID" ]; then
  echo "Error: Issue #$ISSUE_NUMBER not found in project #$PROJECT_NUMBER"
  echo "Issue may not be added to the project yet"
  exit 1
fi

echo "Project item ID: $PROJECT_ITEM_ID"

# --- Execute update mutation ---
echo "Updating field..."

if [ "$FIELD_TYPE" = "ProjectV2SingleSelectField" ]; then
  # Single select field - use option ID
  MUTATION_RESULT=$(gh api graphql -f query='
    mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!, $optionId: String!) {
      updateProjectV2ItemFieldValue(
        input: {
          projectId: $projectId
          itemId: $itemId
          fieldId: $fieldId
          value: {
            singleSelectOptionId: $optionId
          }
        }
      ) {
        projectV2Item {
          id
        }
      }
    }
  ' -f projectId="$PROJECT_NODE_ID" \
    -f itemId="$PROJECT_ITEM_ID" \
    -f fieldId="$FIELD_ID" \
    -f optionId="$OPTION_ID")
else
  # Text field - use text value
  MUTATION_RESULT=$(gh api graphql -f query='
    mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!, $text: String!) {
      updateProjectV2ItemFieldValue(
        input: {
          projectId: $projectId
          itemId: $itemId
          fieldId: $fieldId
          value: {
            text: $text
          }
        }
      ) {
        projectV2Item {
          id
        }
      }
    }
  ' -f projectId="$PROJECT_NODE_ID" \
    -f itemId="$PROJECT_ITEM_ID" \
    -f fieldId="$FIELD_ID" \
    -f text="$FIELD_VALUE")
fi

if [ $? -eq 0 ]; then
  echo ""
  echo "✓ Successfully updated field '$FIELD_NAME' to '$FIELD_VALUE' for issue #$ISSUE_NUMBER"
else
  echo ""
  echo "✗ Failed to update field"
  echo "$MUTATION_RESULT"
  exit 1
fi

exit 0
