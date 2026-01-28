#!/bin/bash
# scripts/github/issue-create.sh
# Create GitHub issues with labels and project linking
#
# Usage:
#   ./issue-create.sh --title "Issue title" --body "Body text"
#   ./issue-create.sh --title "Issue title" --template path/to/template.md --project 2

set -e

# Default configuration
DEFAULT_PROJECT=1
DEFAULT_PRIORITY="P2-medium"
DEFAULT_AGENT_TYPE="agent:any"

# Color output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Help function
show_help() {
  cat << EOF
Usage: $(basename "$0") [OPTIONS]

Create a GitHub issue with labels and link to project board.

REQUIRED OPTIONS:
  --title TEXT              Issue title (required)
  --body TEXT               Issue body text
  --template FILE           Path to template file (use instead of --body)

OPTIONAL OPTIONS:
  --labels "label1,label2"  Comma-separated labels (in addition to auto-labels)
  --project NUMBER          Project number (default: $DEFAULT_PROJECT)
  --priority P0|P1|P2|P3    Priority level (default: $DEFAULT_PRIORITY)
                            P0-critical, P1-high, P2-medium, P3-low
  --complexity XS|S|M|L|XL  Complexity estimate
  --agent-type TYPE         Agent type (default: $DEFAULT_AGENT_TYPE)
                            Options: agent:any, agent:code-reviewer,
                                     agent:backend-developer, agent:frontend-developer,
                                     agent:architect
  --phase NUMBER            Phase number (1-7)
  --help                    Show this help message

EXAMPLES:
  # Simple issue with body text
  ./issue-create.sh --title "Add authentication" --body "Implement JWT auth"

  # Issue from template with custom labels
  ./issue-create.sh \\
    --title "Setup database" \\
    --template .github/ISSUE_TEMPLATE/task.md \\
    --labels "backend,database" \\
    --priority P1-high \\
    --complexity M \\
    --phase 2

  # Urgent issue for specific agent
  ./issue-create.sh \\
    --title "Fix production bug" \\
    --body "Users cannot login" \\
    --priority P0-critical \\
    --agent-type agent:backend-developer

OUTPUT:
  Returns issue number and URL on success.
  Exits with non-zero code on failure.

EOF
}

# Parse arguments
TITLE=""
BODY=""
TEMPLATE=""
LABELS=""
PROJECT="$DEFAULT_PROJECT"
PRIORITY="$DEFAULT_PRIORITY"
COMPLEXITY=""
AGENT_TYPE="$DEFAULT_AGENT_TYPE"
PHASE=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --title)
      TITLE="$2"
      shift 2
      ;;
    --body)
      BODY="$2"
      shift 2
      ;;
    --template)
      TEMPLATE="$2"
      shift 2
      ;;
    --labels)
      LABELS="$2"
      shift 2
      ;;
    --project)
      PROJECT="$2"
      shift 2
      ;;
    --priority)
      PRIORITY="$2"
      shift 2
      ;;
    --complexity)
      COMPLEXITY="$2"
      shift 2
      ;;
    --agent-type)
      AGENT_TYPE="$2"
      shift 2
      ;;
    --phase)
      PHASE="$2"
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
if [ -z "$TITLE" ]; then
  echo -e "${RED}Error: --title is required${NC}" >&2
  echo "Use --help for usage information." >&2
  exit 1
fi

if [ -z "$BODY" ] && [ -z "$TEMPLATE" ]; then
  echo -e "${RED}Error: Either --body or --template is required${NC}" >&2
  echo "Use --help for usage information." >&2
  exit 1
fi

if [ -n "$BODY" ] && [ -n "$TEMPLATE" ]; then
  echo -e "${RED}Error: Cannot use both --body and --template${NC}" >&2
  exit 1
fi

if [ -n "$TEMPLATE" ] && [ ! -f "$TEMPLATE" ]; then
  echo -e "${RED}Error: Template file not found: $TEMPLATE${NC}" >&2
  exit 1
fi

# Build label string
# Format: "priority,complexity,agent-type,phase,custom-labels"
LABEL_PARTS=()

# Always add priority
LABEL_PARTS+=("$PRIORITY")

# Add optional labels
[ -n "$COMPLEXITY" ] && LABEL_PARTS+=("$COMPLEXITY")
[ -n "$AGENT_TYPE" ] && LABEL_PARTS+=("$AGENT_TYPE")
[ -n "$PHASE" ] && LABEL_PARTS+=("phase:$PHASE")

# Add custom labels
if [ -n "$LABELS" ]; then
  IFS=',' read -ra CUSTOM_LABELS <<< "$LABELS"
  LABEL_PARTS+=("${CUSTOM_LABELS[@]}")
fi

# Join labels with commas
FINAL_LABELS=$(IFS=','; echo "${LABEL_PARTS[*]}")

# Create issue
echo "Creating issue: $TITLE"
echo "Labels: $FINAL_LABELS"
echo ""

if [ -n "$TEMPLATE" ]; then
  # Use template file
  ISSUE_URL=$(gh issue create \
    --title "$TITLE" \
    --body-file "$TEMPLATE" \
    --label "$FINAL_LABELS")
else
  # Use body text
  ISSUE_URL=$(gh issue create \
    --title "$TITLE" \
    --body "$BODY" \
    --label "$FINAL_LABELS")
fi

if [ -z "$ISSUE_URL" ]; then
  echo -e "${RED}Error: Failed to create issue${NC}" >&2
  exit 1
fi

# Extract issue number from URL
ISSUE_NUMBER=$(echo "$ISSUE_URL" | grep -oP '\d+$')

echo -e "${GREEN}✓${NC} Issue created: #$ISSUE_NUMBER"
echo "   URL: $ISSUE_URL"
echo ""

# Add to project
echo "Adding issue to project #$PROJECT..."

gh issue edit "$ISSUE_NUMBER" --add-project "$PROJECT" 2>/dev/null || {
  echo -e "${RED}Warning: Failed to add issue to project #$PROJECT${NC}" >&2
  echo "   You may need to add it manually." >&2
  echo ""
}

echo -e "${GREEN}✓${NC} Issue #$ISSUE_NUMBER added to project"
echo ""

# Output for script consumption
echo "ISSUE_NUMBER=$ISSUE_NUMBER"
echo "ISSUE_URL=$ISSUE_URL"

exit 0
