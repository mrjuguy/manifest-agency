#!/usr/bin/env bash
# worktree-create.sh - Create a new worktree with sibling naming pattern
# Usage: ./scripts/worktree-create.sh <branch-name> [base-branch]
#
# Creates worktree at ../<repo-name>-<branch-name>/
# Example: ./scripts/worktree-create.sh feature-auth main
#          Creates ../manifest-automations-feature-auth/

set -euo pipefail

BRANCH_NAME="${1:-}"
BASE_BRANCH="${2:-main}"

if [[ -z "$BRANCH_NAME" ]]; then
    echo "Usage: $0 <branch-name> [base-branch]"
    echo "  branch-name: Name for the new branch (e.g., feature-auth)"
    echo "  base-branch: Branch to base off (default: main)"
    exit 1
fi

# Get repo root and name
REPO_ROOT="$(git rev-parse --show-toplevel)"
REPO_NAME="$(basename "$REPO_ROOT")"

# Sibling naming pattern: ../<repo-name>-<branch-name>
WORKTREE_PATH="$(dirname "$REPO_ROOT")/${REPO_NAME}-${BRANCH_NAME}"

# Check if branch already exists
if git show-ref --verify --quiet "refs/heads/$BRANCH_NAME" 2>/dev/null; then
    echo "Error: Branch '$BRANCH_NAME' already exists."
    echo "Use a different name or delete the existing branch first."
    exit 1
fi

# Check if worktree path already exists
if [[ -d "$WORKTREE_PATH" ]]; then
    echo "Error: Directory already exists: $WORKTREE_PATH"
    exit 1
fi

# Create worktree with new branch
echo "Creating worktree..."
echo "  Branch: $BRANCH_NAME (based on $BASE_BRANCH)"
echo "  Path: $WORKTREE_PATH"

git worktree add -b "$BRANCH_NAME" "$WORKTREE_PATH" "$BASE_BRANCH"

echo ""
echo "Worktree created successfully!"
echo ""
echo "To work in the new worktree:"
echo "  cd \"$WORKTREE_PATH\""
echo ""
echo "To remove when done:"
echo "  ./scripts/worktree-remove.sh $BRANCH_NAME"
