#!/bin/bash
# scripts/github/issue-comment.sh
# Post structured comments to GitHub issues
#
# Usage:
#   ./issue-comment.sh 42 --message "Starting work"
#   ./issue-comment.sh 42 --message "In progress" --agent backend-dev --status implementing --progress 40

set -e

# Color output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Help function
show_help() {
  cat << EOF
Usage: $(basename "$0") ISSUE_NUMBER --message MESSAGE [OPTIONS]

Post a comment to a GitHub issue with optional progress metadata.

REQUIRED ARGUMENTS:
  ISSUE_NUMBER              Issue number to comment on (positional)
  --message "TEXT"          Human-readable comment message (required)

OPTIONAL PROGRESS METADATA:
  --agent AGENT_NAME        Agent posting the comment
  --status STATUS           Current status: claimed, implementing, testing, blocked, complete
  --progress N              Progress percentage (0-100)
  --elapsed TIME            Time elapsed (e.g., "5m 23s", "1h 15m")
  --current-task "TEXT"     Current task description
  --blockers "TEXT"         Blocker description (triggers 'blocked' label if set)

EXAMPLES:
  # Simple comment
  ./issue-comment.sh 42 --message "Starting work on this issue"

  # Progress update
  ./issue-comment.sh 42 \\
    --message "Implementing JWT refresh logic" \\
    --agent backend-developer \\
    --status implementing \\
    --progress 40 \\
    --elapsed "8m 15s" \\
    --current-task "Writing token rotation"

  # Completion
  ./issue-comment.sh 42 \\
    --message "Implementation complete, ready for review" \\
    --agent backend-developer \\
    --status complete \\
    --progress 100

  # Blocker report
  ./issue-comment.sh 42 \\
    --message "Blocked on API credentials" \\
    --agent backend-developer \\
    --status blocked \\
    --blockers "Waiting for Stripe API key from #45"

OUTPUT:
  Posts comment to issue.
  If --blockers is set, adds 'blocked' label to issue.
  Exits with non-zero code on failure.

EOF
}

# Parse arguments
ISSUE_NUMBER=""
MESSAGE=""
AGENT_NAME=""
STATUS=""
PROGRESS=""
ELAPSED=""
CURRENT_TASK=""
BLOCKERS="None"

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
    --message)
      MESSAGE="$2"
      shift 2
      ;;
    --agent)
      AGENT_NAME="$2"
      shift 2
      ;;
    --status)
      STATUS="$2"
      shift 2
      ;;
    --progress)
      PROGRESS="$2"
      shift 2
      ;;
    --elapsed)
      ELAPSED="$2"
      shift 2
      ;;
    --current-task)
      CURRENT_TASK="$2"
      shift 2
      ;;
    --blockers)
      BLOCKERS="$2"
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

if [ -z "$MESSAGE" ]; then
  echo -e "${RED}Error: --message is required${NC}" >&2
  echo "Use --help for usage information." >&2
  exit 1
fi

echo "Posting comment to issue #$ISSUE_NUMBER"
echo ""

# Build comment body
if [ -n "$AGENT_NAME" ]; then
  # Progress comment with metadata
  COMMENT_BODY="## 🤖 Progress Update

$MESSAGE
"

  # Add progress details section if any provided
  if [ -n "$STATUS" ] || [ -n "$PROGRESS" ] || [ -n "$ELAPSED" ]; then
    COMMENT_BODY+="
**Progress Details:**
"

    [ -n "$STATUS" ] && COMMENT_BODY+="
- **Status:** \`$STATUS\`"

    [ -n "$PROGRESS" ] && COMMENT_BODY+="
- **Progress:** $PROGRESS%"

    [ -n "$ELAPSED" ] && COMMENT_BODY+="
- **Elapsed:** $ELAPSED"
  fi

  # Add current task if provided
  if [ -n "$CURRENT_TASK" ]; then
    COMMENT_BODY+="

**Current Task:** $CURRENT_TASK"
  fi

  # Add blockers if not "None"
  if [ "$BLOCKERS" != "None" ]; then
    COMMENT_BODY+="

**⚠️ Blockers:** $BLOCKERS"
  fi

  # Add machine-parseable metadata in HTML comment
  COMMENT_BODY+="

<!-- agent:progress
agent: $AGENT_NAME"

  [ -n "$STATUS" ] && COMMENT_BODY+="
status: $STATUS"

  [ -n "$PROGRESS" ] && COMMENT_BODY+="
progress: $PROGRESS"

  [ -n "$ELAPSED" ] && COMMENT_BODY+="
elapsed: $ELAPSED"

  COMMENT_BODY+="
timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"

  if [ "$BLOCKERS" != "None" ]; then
    COMMENT_BODY+="
blockers: $BLOCKERS"
  fi

  COMMENT_BODY+="
-->"

else
  # Simple comment without metadata
  COMMENT_BODY="$MESSAGE"
fi

# Post comment
gh issue comment "$ISSUE_NUMBER" --body "$COMMENT_BODY" > /dev/null

echo -e "${GREEN}✓${NC} Comment posted"

# Handle blocker label
if [ "$BLOCKERS" != "None" ]; then
  echo ""
  echo "Adding 'blocked' label..."
  gh issue edit "$ISSUE_NUMBER" --add-label "blocked" 2>/dev/null || {
    echo -e "${RED}Warning: Failed to add 'blocked' label${NC}" >&2
  }
  echo -e "${GREEN}✓${NC} Issue marked as blocked"
fi

echo ""
echo "=========================================="
echo -e "${GREEN}✓ Comment posted to issue #$ISSUE_NUMBER${NC}"
echo "=========================================="

if [ -n "$AGENT_NAME" ]; then
  echo ""
  echo "Agent: $AGENT_NAME"
  [ -n "$STATUS" ] && echo "Status: $STATUS"
  [ -n "$PROGRESS" ] && echo "Progress: $PROGRESS%"
  [ -n "$BLOCKERS" ] && [ "$BLOCKERS" != "None" ] && echo "Blockers: $BLOCKERS"
fi

exit 0
