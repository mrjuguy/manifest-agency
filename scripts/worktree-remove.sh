#!/usr/bin/env bash
# worktree-remove.sh - Remove a worktree and optionally its branch
# Usage: ./scripts/worktree-remove.sh <branch-name> [--force] [--keep-branch]
#
# Options:
#   --force        Force removal even if there are uncommitted changes
#   --keep-branch  Don't delete the branch after removing worktree

set -euo pipefail

BRANCH_NAME="${1:-}"
FORCE=false
KEEP_BRANCH=false

# Parse options
shift || true
for arg in "$@"; do
    case $arg in
        --force)
            FORCE=true
            ;;
        --keep-branch)
            KEEP_BRANCH=true
            ;;
        *)
            echo "Unknown option: $arg"
            exit 1
            ;;
    esac
done

if [[ -z "$BRANCH_NAME" ]]; then
    echo "Usage: $0 <branch-name> [--force] [--keep-branch]"
    echo "  branch-name:  Name of the branch/worktree to remove"
    echo "  --force:      Force removal even with uncommitted changes"
    echo "  --keep-branch: Don't delete the branch after removing worktree"
    exit 1
fi

# Get repo root and name
REPO_ROOT="$(git rev-parse --show-toplevel)"
REPO_NAME="$(basename "$REPO_ROOT")"

# Sibling naming pattern
WORKTREE_PATH="$(dirname "$REPO_ROOT")/${REPO_NAME}-${BRANCH_NAME}"

# Check if worktree exists
if [[ ! -d "$WORKTREE_PATH" ]]; then
    echo "Error: Worktree not found: $WORKTREE_PATH"
    echo ""
    echo "Available worktrees:"
    git worktree list
    exit 1
fi

# Check for uncommitted changes
if git -C "$WORKTREE_PATH" status --porcelain | grep -q .; then
    if [[ "$FORCE" != true ]]; then
        echo "Error: Worktree has uncommitted changes."
        echo "Use --force to remove anyway, or commit/stash changes first."
        echo ""
        git -C "$WORKTREE_PATH" status --short
        exit 1
    fi
    echo "Warning: Removing worktree with uncommitted changes (--force)"
fi

# Remove worktree
echo "Removing worktree: $WORKTREE_PATH"

if [[ "$FORCE" == true ]]; then
    git worktree remove --force "$WORKTREE_PATH"
else
    git worktree remove "$WORKTREE_PATH"
fi

# Optionally delete branch
if [[ "$KEEP_BRANCH" != true ]]; then
    echo "Deleting branch: $BRANCH_NAME"
    git branch -d "$BRANCH_NAME" 2>/dev/null || git branch -D "$BRANCH_NAME"
fi

echo ""
echo "Worktree removed successfully!"
