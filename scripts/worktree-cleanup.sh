#!/usr/bin/env bash
# worktree-cleanup.sh - Clean up stale worktrees based on inactivity
# Usage: ./scripts/worktree-cleanup.sh [--dry-run] [--days=7]
#
# Prunes worktree administrative files and optionally removes inactive worktrees

set -euo pipefail

DRY_RUN=false
DAYS=7

# Parse options
for arg in "$@"; do
    case $arg in
        --dry-run)
            DRY_RUN=true
            ;;
        --days=*)
            DAYS="${arg#*=}"
            ;;
        *)
            echo "Unknown option: $arg"
            exit 1
            ;;
    esac
done

echo "Worktree Cleanup"
echo "================"
echo "Inactivity threshold: $DAYS days"
if [[ "$DRY_RUN" == true ]]; then
    echo "Mode: DRY RUN (no changes will be made)"
fi
echo ""

# First, prune any stale administrative files (worktrees manually deleted)
echo "Pruning stale administrative files..."
if [[ "$DRY_RUN" == true ]]; then
    git worktree prune --dry-run --verbose
else
    git worktree prune --verbose
fi
echo ""

# Get repo info
REPO_ROOT="$(git rev-parse --show-toplevel)"
REPO_NAME="$(basename "$REPO_ROOT")"

# Check each worktree for staleness
echo "Checking worktrees for inactivity..."
STALE_COUNT=0

git worktree list --porcelain | while read -r line; do
    if [[ "$line" == worktree\ * ]]; then
        WORKTREE_PATH="${line#worktree }"

        # Skip main worktree
        if [[ "$WORKTREE_PATH" == "$REPO_ROOT" ]]; then
            continue
        fi

        # Get last commit timestamp
        LAST_COMMIT=$(git -C "$WORKTREE_PATH" log -1 --format="%ct" 2>/dev/null || echo "0")
        NOW=$(date +%s)
        AGE_DAYS=$(( (NOW - LAST_COMMIT) / 86400 ))

        if [[ $AGE_DAYS -gt $DAYS ]]; then
            BRANCH=$(git -C "$WORKTREE_PATH" branch --show-current 2>/dev/null || echo "detached")
            echo "  STALE: $WORKTREE_PATH (inactive $AGE_DAYS days, branch: $BRANCH)"
            ((STALE_COUNT++)) || true

            if [[ "$DRY_RUN" != true ]]; then
                echo "    -> Would need manual removal or --force"
                echo "    -> Run: ./scripts/worktree-remove.sh $BRANCH"
            fi
        fi
    fi
done

echo ""
echo "Cleanup complete."
echo "Note: Stale worktrees are reported but not automatically removed."
echo "Use worktree-remove.sh to remove specific worktrees."
