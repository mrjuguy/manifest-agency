#!/usr/bin/env bash
# worktree-list.sh - List all worktrees with their status
# Usage: ./scripts/worktree-list.sh [--porcelain]
#
# Inspired by Container Use's `list` command for observability

set -euo pipefail

PORCELAIN="${1:-}"

if [[ "$PORCELAIN" == "--porcelain" ]]; then
    # Machine-readable output
    git worktree list --porcelain
else
    # Human-readable output with formatting
    echo "Active Worktrees"
    echo "================"
    echo ""

    # Get main worktree info
    MAIN_WORKTREE="$(git rev-parse --show-toplevel)"
    echo "Main:     $MAIN_WORKTREE"
    echo ""

    # List all worktrees
    git worktree list | while read -r line; do
        WORKTREE_PATH=$(echo "$line" | awk '{print $1}')
        COMMIT=$(echo "$line" | awk '{print $2}')
        BRANCH=$(echo "$line" | awk '{print $3}' | tr -d '[]')

        # Skip main worktree (already shown)
        if [[ "$WORKTREE_PATH" == "$MAIN_WORKTREE" ]]; then
            continue
        fi

        # Get last commit date for staleness indication
        LAST_COMMIT_DATE=$(git -C "$WORKTREE_PATH" log -1 --format="%cr" 2>/dev/null || echo "unknown")

        echo "Worktree: $WORKTREE_PATH"
        echo "  Branch: $BRANCH"
        echo "  Commit: $COMMIT"
        echo "  Last activity: $LAST_COMMIT_DATE"
        echo ""
    done

    # Count
    TOTAL=$(git worktree list | wc -l)
    echo "Total: $TOTAL worktree(s)"
fi
