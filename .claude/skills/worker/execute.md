# Worker Execute Skill

Execute work from a GitHub issue in an isolated worktree.

## Usage

```bash
claude --skill worker:execute --issue 42
claude --skill worker:execute --issue 42 --force    # Override stale lock
claude --skill worker:execute --issue 42 --status   # Show execution status
```

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| --issue N | Yes | GitHub issue number to execute |
| --force | No | Override stale lock (use after crash detection) |
| --status | No | Show status from log file instead of executing |

## Workflow

1. **Lock acquisition** - Prevent concurrent execution
2. **Issue parsing** - Extract Summary, Acceptance Criteria from issue body
3. **Plan generation** - Analyze work and create execution plan
4. **Approval gate** - Post plan as comment, wait for reaction
5. **Worktree creation** - Isolate work from main branch
6. **Execution** - Perform the work (Claude's implementation)
7. **Commit & PR** - Single commit, create PR with metadata
8. **Cleanup** - Release lock, update issue status

## State Machine

```
    +---------+
    | ready   | (issue exists, no worker label)
    +----+----+
         |
         v acquire_lock + parse
    +----+----+
    | planning| (worker:planning label)
    +----+----+
         |
         v post plan comment
    +----+--------+
    | awaiting-  | (worker:awaiting-approval label)
    | approval   | (exit, wait for human approval)
    +----+--------+
         |
         v re-run after approval
    +----+----+
    |executing| (worker:executing label)
    +----+----+
         |
         v create PR
    +----+----+
    |complete | (worker:complete label)
    +---------+

Error states:
- worker:partial (interrupted during execution)
- worker:failed (error during execution)
```

## Labels

| Label | Meaning |
|-------|---------|
| worker:planning | Worker is analyzing issue and generating plan |
| worker:awaiting-approval | Plan posted, waiting for human approval |
| worker:executing | Worker is implementing the work |
| worker:complete | Work complete, PR created |
| worker:partial | Execution interrupted, partial work may exist |
| worker:failed | Execution failed, see error comment |

## Implementation

<!-- SKILL_IMPLEMENTATION -->
```bash
#!/usr/bin/env bash
#
# Worker Execute Skill Implementation
# Orchestrates GitHub issue -> work -> PR lifecycle
#

set -euo pipefail

# --- Configuration ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git rev-parse --show-toplevel)"
WORKER_DIR="$REPO_ROOT/.worker"
LIB_DIR="$REPO_ROOT/.claude/skills/worker/lib"
SCRIPTS_DIR="$REPO_ROOT/scripts"

# --- Source libraries ---
source "$LIB_DIR/logger.sh"
source "$LIB_DIR/lock.sh"
source "$LIB_DIR/parser.sh"

# --- Parse arguments ---
ISSUE_NUMBER=""
FORCE_LOCK=false
STATUS_ONLY=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --issue)
      ISSUE_NUMBER="$2"
      shift 2
      ;;
    --force)
      FORCE_LOCK=true
      shift
      ;;
    --status)
      STATUS_ONLY=true
      shift
      ;;
    --help)
      echo "Usage: claude --skill worker:execute --issue N [--force] [--status]"
      echo ""
      echo "Options:"
      echo "  --issue N   Issue number to execute (required)"
      echo "  --force     Override stale lock"
      echo "  --status    Show execution status from logs"
      exit 0
      ;;
    *)
      echo "[error] Unknown option: $1"
      exit 1
      ;;
  esac
done

# Validate required arguments
if [ -z "$ISSUE_NUMBER" ]; then
  echo "[error] --issue is required"
  echo "Usage: claude --skill worker:execute --issue N"
  exit 1
fi

# --- Status mode ---
if [ "$STATUS_ONLY" = true ]; then
  echo "[worker] Status for issue #${ISSUE_NUMBER}"
  echo ""

  # Check lock status
  check_lock_status "$ISSUE_NUMBER" 2>/dev/null || true
  echo ""

  # Find latest log file
  LOG_PATTERN="$WORKER_DIR/logs/issue-${ISSUE_NUMBER}-*.jsonl"
  LATEST_LOG=$(ls -t $LOG_PATTERN 2>/dev/null | head -1 || echo "")

  if [ -n "$LATEST_LOG" ]; then
    echo "Latest log: $LATEST_LOG"
    echo ""
    echo "Recent events:"
    tail -5 "$LATEST_LOG" | jq -r '"  [\(.event_type)] \(.data | tostring)"'
  else
    echo "No log files found for issue #${ISSUE_NUMBER}"
  fi

  exit 0
fi

# --- Main execution ---
echo "[worker] Starting execution for issue #${ISSUE_NUMBER}"
echo ""

# Initialize logging
init_logging "$ISSUE_NUMBER"
log_event "worker_start" --arg issue "$ISSUE_NUMBER" --arg force "$FORCE_LOCK"

# Acquire lock
if ! acquire_lock "$ISSUE_NUMBER" "$FORCE_LOCK"; then
  log_event "lock_failed" --arg issue "$ISSUE_NUMBER"
  exit 1
fi

# Signal handler for graceful shutdown
WORKER_STATE="initializing"
handle_signal() {
  local signal="$1"
  log_event "signal_received" --arg signal "$signal" --arg state "$WORKER_STATE"

  if [ "$WORKER_STATE" = "executing" ]; then
    echo ""
    echo "[worker] Interrupted during execution - work may be incomplete"
    gh issue edit "$ISSUE_NUMBER" --add-label "worker:partial" 2>/dev/null || true
  fi

  log_session_end "interrupted" "$?"
  exit 130
}
trap 'handle_signal SIGTERM' SIGTERM
trap 'handle_signal SIGINT' SIGINT

# --- Check current issue state ---
WORKER_STATE="checking_state"
log_event "state_check" --arg issue "$ISSUE_NUMBER"

ISSUE_LABELS=$(gh issue view "$ISSUE_NUMBER" --json labels -q '.labels[].name' 2>/dev/null || echo "")

# If awaiting approval, check for approval
if echo "$ISSUE_LABELS" | grep -q "worker:awaiting-approval"; then
  echo "[worker] Issue in awaiting-approval state - checking for approval..."

  # Check for thumbs up reaction on plan comment
  PLAN_COMMENT_ID=$(gh api "/repos/{owner}/{repo}/issues/${ISSUE_NUMBER}/comments" \
    --jq '.[] | select(.body | contains("## Execution Plan")) | .id' 2>/dev/null | tail -1)

  if [ -n "$PLAN_COMMENT_ID" ]; then
    APPROVAL_COUNT=$(gh api "/repos/{owner}/{repo}/issues/comments/${PLAN_COMMENT_ID}/reactions" \
      --jq '[.[] | select(.content == "+1")] | length' 2>/dev/null || echo "0")

    if [ "$APPROVAL_COUNT" -gt 0 ]; then
      echo "[worker] Approval received - proceeding with execution"
      log_event "approval_received" --arg comment_id "$PLAN_COMMENT_ID"

      # Remove awaiting-approval, add executing
      gh issue edit "$ISSUE_NUMBER" \
        --remove-label "worker:awaiting-approval" \
        --add-label "worker:executing" 2>/dev/null || true

      # Skip to execution phase
      WORKER_STATE="approved"
    else
      echo "[worker] Plan not yet approved"
      echo ""
      echo "To approve: Add a thumbs up reaction to the Execution Plan comment"
      echo "Then re-run: claude --skill worker:execute --issue $ISSUE_NUMBER"
      log_session_end "awaiting_approval" "0"
      exit 0
    fi
  else
    echo "[error] Could not find plan comment - issue may be in inconsistent state"
    exit 1
  fi
fi

# --- Parse issue (if not approved yet) ---
if [ "$WORKER_STATE" != "approved" ]; then
  WORKER_STATE="parsing"
  echo "[worker] Parsing issue #${ISSUE_NUMBER}..."

  if ! parse_issue_body "$ISSUE_NUMBER"; then
    log_event "parse_failed" --arg issue "$ISSUE_NUMBER"
    gh issue comment "$ISSUE_NUMBER" --body "## Worker Error

Failed to parse issue body. Please ensure the issue has:
- \`## Summary\` section
- \`## Acceptance Criteria\` section

See issue template for expected format." 2>/dev/null || true
    log_session_end "parse_error" "1"
    exit 1
  fi

  log_event "issue_parsed" \
    --arg title "$ISSUE_TITLE" \
    --arg summary "$ISSUE_SUMMARY" \
    --arg acceptance "$ISSUE_ACCEPTANCE"

  echo "[worker] Issue: $ISSUE_TITLE"
  echo "[worker] Labels: $ISSUE_LABELS"

  # Validate required sections
  if ! validate_issue_for_worker; then
    log_session_end "validation_error" "1"
    exit 1
  fi

  # --- Generate execution plan ---
  WORKER_STATE="planning"
  echo ""
  echo "[worker] Generating execution plan..."

  # Set planning label
  gh issue edit "$ISSUE_NUMBER" --add-label "worker:planning" 2>/dev/null || true

  # Get current commit SHA for traceability
  BASE_SHA=$(git rev-parse HEAD)

  # Plan comment body
  PLAN_BODY="## Execution Plan

**Issue:** #${ISSUE_NUMBER} - ${ISSUE_TITLE}

**Summary:**
${ISSUE_SUMMARY}

**Acceptance Criteria:**
${ISSUE_ACCEPTANCE}

**Based on:** \`main @ ${BASE_SHA:0:7}\`

---

**Proposed approach:**

_Claude will analyze the issue and propose specific implementation steps here._

---

**Next:** React with :+1: to approve execution

<!-- agent:metadata
status: awaiting_approval
agent: claude-worker
plan_generated_at: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
base_sha: $BASE_SHA
-->"

  # Post plan comment
  echo "[worker] Posting execution plan..."
  gh issue comment "$ISSUE_NUMBER" --body "$PLAN_BODY" 2>/dev/null

  log_event "plan_posted" --arg base_sha "$BASE_SHA"

  # Update labels
  gh issue edit "$ISSUE_NUMBER" \
    --remove-label "worker:planning" \
    --add-label "worker:awaiting-approval" 2>/dev/null || true

  echo ""
  echo "[worker] Plan posted to issue #${ISSUE_NUMBER}"
  echo ""
  echo "Next steps:"
  echo "  1. Review the execution plan in the issue comment"
  echo "  2. React with thumbs up to approve"
  echo "  3. Re-run: claude --skill worker:execute --issue $ISSUE_NUMBER"

  log_session_end "awaiting_approval" "0"
  exit 0
fi

# --- Execution phase (reached after approval) ---
WORKER_STATE="executing"
START_TIME=$(date +%s)

echo ""
echo "[worker] Starting execution..."
log_event "execution_start" --arg timestamp "$START_TIME"

# Re-parse issue to get current data
parse_issue_body "$ISSUE_NUMBER"

# Create worktree
BRANCH_NAME="issue/${ISSUE_NUMBER}"
WORKTREE_PATH="../$(basename "$REPO_ROOT")-issue-${ISSUE_NUMBER}"

echo "[worker] Creating worktree: $WORKTREE_PATH"
"$SCRIPTS_DIR/worktree-create.sh" "$BRANCH_NAME" "main"

log_event "worktree_created" \
  --arg path "$WORKTREE_PATH" \
  --arg branch "$BRANCH_NAME"

# Change to worktree
cd "$WORKTREE_PATH"
echo "[worker] Working in: $(pwd)"

# ===== EXECUTION PLACEHOLDER =====
# This is where Claude performs the actual work based on the issue
# The skill provides the orchestration framework; Claude provides the implementation
#
# Example work patterns:
# - Read acceptance criteria
# - Modify files as needed
# - Run tests
# - Stage changes with: git add <files>
#
# Claude should:
# 1. Analyze ISSUE_SUMMARY and ISSUE_ACCEPTANCE
# 2. Implement the required changes
# 3. Verify acceptance criteria are met
# 4. Stage all changes
# ==================================

echo ""
echo "[worker] Execution complete - creating commit..."

# Single commit with all changes
git add -A

COMMIT_MSG="$(echo "$ISSUE_TITLE" | sed 's/\[.*\]//' | xargs)

Resolves #${ISSUE_NUMBER}

Changes:
- Implementation per acceptance criteria

Co-Authored-By: Claude Worker <claude@anthropic.com>"

if git diff --cached --quiet; then
  echo "[warning] No changes to commit"
  log_event "no_changes" --arg issue "$ISSUE_NUMBER"
else
  git commit -m "$COMMIT_MSG"
fi

# Push branch
echo "[worker] Pushing branch..."
git push -u origin "$BRANCH_NAME"

log_event "branch_pushed" --arg branch "$BRANCH_NAME"

# Create PR
echo "[worker] Creating PR..."
cd "$REPO_ROOT"

PR_OUTPUT=$("$SCRIPTS_DIR/github/pr-create.sh" \
  --issue "$ISSUE_NUMBER" \
  --agent "claude-worker" \
  --worktree "$WORKTREE_PATH" \
  --start-time "$START_TIME")

PR_URL=$(echo "$PR_OUTPUT" | grep "URL:" | awk '{print $2}')
PR_NUMBER=$(echo "$PR_URL" | grep -oE '[0-9]+$')

log_event "pr_created" \
  --arg pr_number "$PR_NUMBER" \
  --arg pr_url "$PR_URL"

# Calculate duration
END_TIME=$(date +%s)
DURATION_SECONDS=$((END_TIME - START_TIME))
DURATION_MINUTES=$((DURATION_SECONDS / 60))
DURATION="${DURATION_MINUTES}min"

# Post completion comment
COMPLETE_BODY="## Work Complete

Created PR #${PR_NUMBER}

<details>
<summary>Execution Summary</summary>

**Duration:** $DURATION
**Branch:** \`$BRANCH_NAME\`
**Commits:** 1

**Acceptance Criteria Status:**
$(echo "$ISSUE_ACCEPTANCE" | sed 's/- \[ \]/- [x]/g')

</details>

<!-- agent:metadata
status: complete
agent: claude-worker
completed_at: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
duration: $DURATION
pr_number: $PR_NUMBER
-->"

gh issue comment "$ISSUE_NUMBER" --body "$COMPLETE_BODY" 2>/dev/null

# Update labels
gh issue edit "$ISSUE_NUMBER" \
  --remove-label "worker:executing" \
  --add-label "worker:complete" 2>/dev/null || true

# Update project status
"$SCRIPTS_DIR/github/issue-update-status.sh" "$ISSUE_NUMBER" "In Review" 2>/dev/null || true

echo ""
echo "[worker] Execution complete"
echo "  PR: $PR_URL"
echo "  Duration: $DURATION"

log_event "execution_complete" \
  --arg pr_number "$PR_NUMBER" \
  --arg duration "$DURATION"

log_session_end "complete" "0"
```
<!-- END_SKILL_IMPLEMENTATION -->

## Error Handling

The worker skill handles the following error cases:

1. **Lock conflicts** - Another worker running for same issue
2. **Stale locks** - Previous worker crashed, use --force
3. **Parse errors** - Issue missing required sections
4. **Interruption** - SIGINT/SIGTERM during execution
5. **No changes** - Nothing to commit (warning, not error)
6. **GitHub API errors** - Retried automatically (see lock.sh)

All errors are logged to `.worker/logs/` and posted as GitHub comments.

## Manual Recovery

If execution fails or is interrupted:

1. Check status: `claude --skill worker:execute --issue 42 --status`
2. View logs: `tail .worker/logs/issue-42-*.jsonl`
3. If stale lock: `claude --skill worker:execute --issue 42 --force`
4. Check worktree: `git worktree list`
5. Clean up if needed: `./scripts/worktree-remove.sh issue/42`

## Next Steps

After implementation in Phase 3:

- **Phase 4:** Add AI-powered plan generation (Claude analyzes issue and writes specific steps)
- **Phase 5:** Orchestrator dispatches workers automatically
- **Phase 6:** Multiple concurrent workers with task scheduling
