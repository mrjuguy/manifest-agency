#!/bin/bash
# scripts/github/issue-update-status.sh
# Update GitHub issue status in project board
#
# Usage:
#   ./issue-update-status.sh 42 --status "In Progress"

set -e

# Configuration
CACHE_FILE=".cache/github/project-fields.json"

# Valid status values
VALID_STATUSES=("Backlog" "Ready" "Claimed" "In Progress" "In Review" "Done")

# Color output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Help function
show_help() {
  cat << EOF
Usage: $(basename "$0") ISSUE_NUMBER --status STATUS

Update the Status field for a GitHub issue in the project board.

REQUIRED ARGUMENTS:
  ISSUE_NUMBER              Issue number to update (positional)
  --status STATUS           New status value (required)

VALID STATUS VALUES:
  - Backlog
  - Ready
  - Claimed
  - In Progress
  - In Review
  - Done

EXAMPLES:
  # Move issue to In Progress
  ./issue-update-status.sh 42 --status "In Progress"

  # Mark issue as done
  ./issue-update-status.sh 123 --status Done

  # Move issue back to backlog
  ./issue-update-status.sh 456 --status Backlog

REQUIREMENTS:
  - Issue must be added to project board first
  - Field cache must exist (run project-bootstrap.sh first)

OUTPUT:
  Updates project item Status field.
  Exits with non-zero code on failure.

EOF
}

# Parse arguments
ISSUE_NUMBER=""
STATUS=""

if [ "$1" = "--help" ]; then
  show_help
  exit 0
fi

# First positional argument is issue number
if [ -n "$1" ] && [[ "$1" =~ ^[0-9]+$ ]]; then
  ISSUE_NUMBER="$1"
  shift
fi

while [[ $# -gt 0 ]]; do
  case $1 in
    --status)
      STATUS="$2"
      shift 2
      ;;
    --help)
      show_help
      exit 0
      ;;
    *)
      echo -e "${RED}Error: Unknown option: $1${NC}" >&2
      echo "Use --help for usage information." >&2
      exit 1
      ;;
  esac
done

# Validate required parameters
if [ -z "$ISSUE_NUMBER" ]; then
  echo -e "${RED}Error: Issue number is required${NC}" >&2
  echo "Use --help for usage information." >&2
  exit 1
fi

if [ -z "$STATUS" ]; then
  echo -e "${RED}Error: --status is required${NC}" >&2
  echo "Use --help for usage information." >&2
  exit 1
fi

# Validate status value
VALID_STATUS=false
for valid in "${VALID_STATUSES[@]}"; do
  if [ "$STATUS" = "$valid" ]; then
    VALID_STATUS=true
    break
  fi
done

if [ "$VALID_STATUS" = false ]; then
  echo -e "${RED}Error: Invalid status: $STATUS${NC}" >&2
  echo "Valid statuses: ${VALID_STATUSES[*]}" >&2
  exit 1
fi

# Check for cached field IDs
if [ ! -f "$CACHE_FILE" ]; then
  echo -e "${RED}Error: Field cache not found: $CACHE_FILE${NC}" >&2
  echo "Run project-bootstrap.sh first to create the cache." >&2
  exit 1
fi

echo "Updating issue #$ISSUE_NUMBER status to: $STATUS"
echo ""

# Extract project ID, field ID, and option ID from cache
PROJECT_ID=$(jq -r '.data.user.projectV2.id' "$CACHE_FILE")
STATUS_FIELD_ID=$(jq -r '.data.user.projectV2.fields.nodes[] | select(.name=="Status") | .id' "$CACHE_FILE")
STATUS_OPTION_ID=$(jq -r --arg status "$STATUS" '.data.user.projectV2.fields.nodes[] | select(.name=="Status") | .options[] | select(.name==$status) | .id' "$CACHE_FILE")

if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" = "null" ]; then
  echo -e "${RED}Error: Could not extract project ID from cache${NC}" >&2
  exit 1
fi

if [ -z "$STATUS_FIELD_ID" ] || [ "$STATUS_FIELD_ID" = "null" ]; then
  echo -e "${RED}Error: 'Status' field not found in cache${NC}" >&2
  exit 1
fi

if [ -z "$STATUS_OPTION_ID" ] || [ "$STATUS_OPTION_ID" = "null" ]; then
  echo -e "${RED}Error: Status option '$STATUS' not found in cache${NC}" >&2
  exit 1
fi

# Get repository information
REPO_INFO=$(gh repo view --json owner,name)
REPO_OWNER=$(echo "$REPO_INFO" | jq -r '.owner.login')
REPO_NAME=$(echo "$REPO_INFO" | jq -r '.name')

# Get project item ID for this issue
echo "Finding project item for issue #$ISSUE_NUMBER..."

ITEM_QUERY=$(gh api graphql -f query='
  query($owner: String!, $repo: String!, $issueNumber: Int!) {
    repository(owner: $owner, name: $repo) {
      issue(number: $issueNumber) {
        projectItems(first: 10) {
          nodes {
            id
            project {
              id
            }
          }
        }
      }
    }
  }' -f owner="$REPO_OWNER" -f repo="$REPO_NAME" -F issueNumber="$ISSUE_NUMBER")

PROJECT_ITEM_ID=$(echo "$ITEM_QUERY" | jq -r --arg projectId "$PROJECT_ID" '.data.repository.issue.projectItems.nodes[] | select(.project.id==$projectId) | .id')

if [ -z "$PROJECT_ITEM_ID" ] || [ "$PROJECT_ITEM_ID" = "null" ]; then
  echo -e "${RED}Error: Issue #$ISSUE_NUMBER is not in project${NC}" >&2
  echo "Add the issue to the project board first using:" >&2
  echo "  gh issue edit $ISSUE_NUMBER --add-project <project-number>" >&2
  exit 1
fi

echo -e "${GREEN}✓${NC} Found project item: $PROJECT_ITEM_ID"
echo ""

# Update Status field (single select field)
echo "Updating Status field..."

gh api graphql -f query='
  mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!, $optionId: String!) {
    updateProjectV2ItemFieldValue(input: {
      projectId: $projectId
      itemId: $itemId
      fieldId: $fieldId
      value: { singleSelectOptionId: $optionId }
    }) {
      projectV2Item {
        id
      }
    }
  }' -f projectId="$PROJECT_ID" \
     -f itemId="$PROJECT_ITEM_ID" \
     -f fieldId="$STATUS_FIELD_ID" \
     -f optionId="$STATUS_OPTION_ID" > /dev/null

echo -e "${GREEN}✓${NC} Status updated to: $STATUS"
echo ""

echo "=========================================="
echo -e "${GREEN}✓ Issue #$ISSUE_NUMBER status updated${NC}"
echo "=========================================="
echo ""
echo "New status: $STATUS"
echo "Updated at: $(date -u +"%Y-%m-%d %H:%M:%S UTC")"

exit 0
