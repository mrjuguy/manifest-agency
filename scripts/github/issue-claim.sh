#!/bin/bash
# scripts/github/issue-claim.sh
# Claim a GitHub issue for an agent
#
# Usage:
#   ./issue-claim.sh 42 --agent backend-developer

set -e

# Configuration
CACHE_FILE=".cache/github/project-fields.json"

# Color output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Help function
show_help() {
  cat << EOF
Usage: $(basename "$0") ISSUE_NUMBER --agent AGENT_NAME

Claim a GitHub issue by setting the "Claimed By" field and Status to "Claimed".

REQUIRED ARGUMENTS:
  ISSUE_NUMBER              Issue number to claim (positional)
  --agent AGENT_NAME        Agent name claiming the issue (required)

EXAMPLES:
  # Claim issue #42 for backend-developer
  ./issue-claim.sh 42 --agent backend-developer

  # Claim issue #123 for code-reviewer
  ./issue-claim.sh 123 --agent code-reviewer

REQUIREMENTS:
  - Issue must be added to project board first
  - Field cache must exist (run project-bootstrap.sh first)

OUTPUT:
  Updates project item fields and adds claim comment to issue.
  Exits with non-zero code on failure.

EOF
}

# Parse arguments
ISSUE_NUMBER=""
AGENT_NAME=""

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
    --agent)
      AGENT_NAME="$2"
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

if [ -z "$AGENT_NAME" ]; then
  echo -e "${RED}Error: --agent is required${NC}" >&2
  echo "Use --help for usage information." >&2
  exit 1
fi

# Check for cached field IDs
if [ ! -f "$CACHE_FILE" ]; then
  echo -e "${RED}Error: Field cache not found: $CACHE_FILE${NC}" >&2
  echo "Run project-bootstrap.sh first to create the cache." >&2
  exit 1
fi

echo "Claiming issue #$ISSUE_NUMBER for agent: $AGENT_NAME"
echo ""

# Extract project ID and field IDs from cache
PROJECT_ID=$(jq -r '.data.user.projectV2.id' "$CACHE_FILE")
CLAIMED_BY_FIELD_ID=$(jq -r '.data.user.projectV2.fields.nodes[] | select(.name=="Claimed By") | .id' "$CACHE_FILE")
STATUS_FIELD_ID=$(jq -r '.data.user.projectV2.fields.nodes[] | select(.name=="Status") | .id' "$CACHE_FILE")
CLAIMED_OPTION_ID=$(jq -r '.data.user.projectV2.fields.nodes[] | select(.name=="Status") | .options[] | select(.name=="Claimed") | .id' "$CACHE_FILE")

if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" = "null" ]; then
  echo -e "${RED}Error: Could not extract project ID from cache${NC}" >&2
  exit 1
fi

if [ -z "$CLAIMED_BY_FIELD_ID" ] || [ "$CLAIMED_BY_FIELD_ID" = "null" ]; then
  echo -e "${RED}Error: 'Claimed By' field not found in cache${NC}" >&2
  exit 1
fi

if [ -z "$STATUS_FIELD_ID" ] || [ "$STATUS_FIELD_ID" = "null" ]; then
  echo -e "${RED}Error: 'Status' field not found in cache${NC}" >&2
  exit 1
fi

if [ -z "$CLAIMED_OPTION_ID" ] || [ "$CLAIMED_OPTION_ID" = "null" ]; then
  echo -e "${RED}Error: 'Claimed' status option not found in cache${NC}" >&2
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

# Update "Claimed By" field (text field)
echo "Setting 'Claimed By' to: $AGENT_NAME..."

gh api graphql -f query='
  mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!, $text: String!) {
    updateProjectV2ItemFieldValue(input: {
      projectId: $projectId
      itemId: $itemId
      fieldId: $fieldId
      value: { text: $text }
    }) {
      projectV2Item {
        id
      }
    }
  }' -f projectId="$PROJECT_ID" \
     -f itemId="$PROJECT_ITEM_ID" \
     -f fieldId="$CLAIMED_BY_FIELD_ID" \
     -f text="$AGENT_NAME" > /dev/null

echo -e "${GREEN}✓${NC} 'Claimed By' field updated"
echo ""

# Update Status to "Claimed" (single select field)
echo "Setting Status to: Claimed..."

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
     -f optionId="$CLAIMED_OPTION_ID" > /dev/null

echo -e "${GREEN}✓${NC} Status updated to 'Claimed'"
echo ""

# Add claim comment to issue
CLAIM_TIME=$(date -u +"%Y-%m-%d %H:%M:%S UTC")
COMMENT_BODY="## 🤖 Issue Claimed

**Agent:** \`$AGENT_NAME\`
**Claimed at:** $CLAIM_TIME

This issue has been claimed and work will begin shortly.

<!-- agent:metadata
status: claimed
agent: $AGENT_NAME
claimed_at: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
-->"

echo "Adding claim comment..."
gh issue comment "$ISSUE_NUMBER" --body "$COMMENT_BODY" > /dev/null

echo -e "${GREEN}✓${NC} Claim comment added"
echo ""

echo "=========================================="
echo -e "${GREEN}✓ Issue #$ISSUE_NUMBER claimed successfully${NC}"
echo "=========================================="
echo ""
echo "Agent: $AGENT_NAME"
echo "Status: Claimed"
echo "Time: $CLAIM_TIME"

exit 0
