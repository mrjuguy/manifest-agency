#!/usr/bin/env bash
#
# pr-create.sh - Create PR with agent metadata
#
# Creates pull requests with structured metadata linking to issues,
# tracking agent execution metrics, and templated PR body.
#
# Usage:
#   pr-create.sh --issue <number> --agent <name> [options]
#
# Required:
#   --issue <number>      Issue this PR closes
#   --agent <name>        Agent identifier
#
# Optional:
#   --worktree <path>     Worktree path (for metadata)
#   --start-time <epoch>  Unix timestamp when work started
#   --title <title>       Override auto-generated title
#   --base <branch>       Base branch (default: main)
#   --draft               Create as draft PR
#   --help                Show this help
#
# Environment variables:
#   AGENT_TRUST_LEVEL     Trust level (default: 2)
#   AGENT_MODEL           Model name (default: claude-sonnet-4.5)
#
# Example:
#   pr-create.sh --issue 42 --agent backend-dev --start-time 1769508282
#

set -euo pipefail

# --- Configuration ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEMPLATE_PATH="$REPO_ROOT/templates/github/pr-body.md"

# --- Default values ---
BASE_BRANCH="main"
DRAFT_FLAG=""
TRUST_LEVEL="${AGENT_TRUST_LEVEL:-2}"
MODEL="${AGENT_MODEL:-claude-sonnet-4.5}"

# --- Parse arguments ---
ISSUE=""
AGENT=""
WORKTREE=""
START_TIME=""
TITLE=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --issue)
      ISSUE="$2"
      shift 2
      ;;
    --agent)
      AGENT="$2"
      shift 2
      ;;
    --worktree)
      WORKTREE="$2"
      shift 2
      ;;
    --start-time)
      START_TIME="$2"
      shift 2
      ;;
    --title)
      TITLE="$2"
      shift 2
      ;;
    --base)
      BASE_BRANCH="$2"
      shift 2
      ;;
    --draft)
      DRAFT_FLAG="--draft"
      shift
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
if [ -z "$ISSUE" ]; then
  echo "Error: --issue is required"
  exit 1
fi

if [ -z "$AGENT" ]; then
  echo "Error: --agent is required"
  exit 1
fi

# Check we're in a git repo
if ! git rev-parse --git-dir > /dev/null 2>&1; then
  echo "Error: Not in a git repository"
  exit 1
fi

# Check we're not on main/master
CURRENT_BRANCH=$(git branch --show-current)
if [[ "$CURRENT_BRANCH" == "main" || "$CURRENT_BRANCH" == "master" ]]; then
  echo "Error: Cannot create PR from main/master branch"
  echo "Current branch: $CURRENT_BRANCH"
  exit 1
fi

# Check issue exists
if ! gh issue view "$ISSUE" --json title > /dev/null 2>&1; then
  echo "Error: Issue #$ISSUE not found"
  exit 1
fi

# Check there are commits to push
COMMIT_COUNT=$(git rev-list --count "HEAD" "^$BASE_BRANCH" 2>/dev/null || echo "0")
if [ "$COMMIT_COUNT" -eq 0 ]; then
  echo "Error: No commits to create PR (branch is up to date with $BASE_BRANCH)"
  exit 1
fi

# --- Gather metadata ---
echo "Gathering metadata..."

# Issue metadata
ISSUE_TITLE=$(gh issue view "$ISSUE" --json title -q '.title')
ISSUE_LABELS=$(gh issue view "$ISSUE" --json labels -q '.labels[].name' | tr '\n' ',' | sed 's/,$//')

# Extract type from labels
TYPE="feat"  # default
if echo "$ISSUE_LABELS" | grep -qi "bug"; then
  TYPE="fix"
elif echo "$ISSUE_LABELS" | grep -qi "chore"; then
  TYPE="chore"
elif echo "$ISSUE_LABELS" | grep -qi "feature"; then
  TYPE="feat"
elif echo "$ISSUE_LABELS" | grep -qi "refactor"; then
  TYPE="refactor"
elif echo "$ISSUE_LABELS" | grep -qi "docs"; then
  TYPE="docs"
fi

# Calculate duration
DURATION="N/A"
if [ -n "$START_TIME" ]; then
  END_TIME=$(date +%s)
  DURATION_SECONDS=$((END_TIME - START_TIME))
  DURATION_MINUTES=$((DURATION_SECONDS / 60))
  if [ "$DURATION_MINUTES" -lt 60 ]; then
    DURATION="${DURATION_MINUTES}min"
  else
    DURATION_HOURS=$((DURATION_MINUTES / 60))
    DURATION_REMAINDER=$((DURATION_MINUTES % 60))
    DURATION="${DURATION_HOURS}h ${DURATION_REMAINDER}min"
  fi
fi

# Worktree name
WORKTREE_NAME="${WORKTREE:-$CURRENT_BRANCH}"

# --- Generate PR title ---
if [ -z "$TITLE" ]; then
  TITLE="$TYPE: $ISSUE_TITLE (#$ISSUE)"
fi

echo "PR Title: $TITLE"

# --- Build PR body ---
echo "Building PR body from template..."

if [ ! -f "$TEMPLATE_PATH" ]; then
  echo "Error: Template not found at $TEMPLATE_PATH"
  exit 1
fi

PR_BODY=$(cat "$TEMPLATE_PATH")

# Replace placeholders
PR_BODY="${PR_BODY//ISSUE_NUMBER/$ISSUE}"
PR_BODY="${PR_BODY//AGENT_NAME/$AGENT}"
PR_BODY="${PR_BODY//WORKTREE_NAME/$WORKTREE_NAME}"
PR_BODY="${PR_BODY//DURATION/$DURATION}"
PR_BODY="${PR_BODY//MODEL_NAME/$MODEL}"
PR_BODY="${PR_BODY//TRUST_LEVEL/$TRUST_LEVEL}"
PR_BODY="${PR_BODY//COMMIT_COUNT/$COMMIT_COUNT}"

# --- Create PR ---
echo "Creating PR..."
echo "  Base: $BASE_BRANCH"
echo "  Head: $CURRENT_BRANCH"
echo "  Commits: $COMMIT_COUNT"
echo "  Draft: ${DRAFT_FLAG:-false}"
echo ""

PR_URL=$(gh pr create \
  --title "$TITLE" \
  --body "$PR_BODY" \
  --base "$BASE_BRANCH" \
  --head "$CURRENT_BRANCH" \
  $DRAFT_FLAG)

echo ""
echo "✓ PR created successfully!"
echo "  URL: $PR_URL"

# Extract PR number from URL
PR_NUMBER=$(echo "$PR_URL" | grep -oE '[0-9]+$')
echo "  Number: #$PR_NUMBER"

exit 0
