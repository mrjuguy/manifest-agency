# Worker Execute Command

Execute work from a GitHub issue in an isolated worktree.

## Usage

```
/worker:execute <issue_number>
/worker:execute <issue_number> --force   # Override stale lock
/worker:execute <issue_number> --status  # Check status only
```

## Instructions

When this command is invoked, follow these steps:

### 1. Parse Arguments

Extract from the command arguments:
- `ISSUE_NUMBER` (required) - The GitHub issue number
- `--force` flag (optional) - Override stale lock
- `--status` flag (optional) - Show status and exit

If no issue number provided, ask the user for it.

### 2. Status Mode (if --status flag)

If `--status` was passed, run these commands and report results:

```bash
# Check for lock file
ls -la .worker/locks/issue-${ISSUE_NUMBER}.lock 2>/dev/null || echo "No lock file"

# Find and display recent log
LATEST_LOG=$(ls -t .worker/logs/issue-${ISSUE_NUMBER}-*.jsonl 2>/dev/null | head -1)
if [ -n "$LATEST_LOG" ]; then
  echo "Log file: $LATEST_LOG"
  tail -10 "$LATEST_LOG" | jq -r '"[\(.event_type)] \(.data)"'
fi
```

Then stop - do not continue to execution.

### 3. Initialize Logging

```bash
# Source the logger library and initialize
source .claude/skills/worker/lib/logger.sh
init_logging ${ISSUE_NUMBER}
log_event "worker_start" --arg issue "${ISSUE_NUMBER}"
```

### 4. Acquire Lock

```bash
# Source lock library and acquire
source .claude/skills/worker/lib/lock.sh
acquire_lock ${ISSUE_NUMBER} ${FORCE_FLAG:-false}
```

If lock acquisition fails:
- Report the error to the user
- Suggest using `--force` if lock is stale
- Stop execution

### 5. Check Current State

```bash
# Get current labels
LABELS=$(gh issue view ${ISSUE_NUMBER} --json labels -q '.labels[].name')
echo "$LABELS"
```

**If `worker:awaiting-approval` label exists:**
- Check for thumbs-up reaction on the "Execution Plan" comment
- If approved: proceed to step 8 (Execution)
- If not approved: inform user and exit cleanly

**If `worker:executing` label exists:**
- Issue already being worked - check for stale state
- May need `--force` to restart

### 6. Parse Issue

```bash
# Source parser and extract issue data
source .claude/skills/worker/lib/parser.sh
parse_issue_body ${ISSUE_NUMBER}

# These variables are now set:
# ISSUE_TITLE, ISSUE_SUMMARY, ISSUE_ACCEPTANCE, ISSUE_LABELS
echo "Title: $ISSUE_TITLE"
echo "Summary: $ISSUE_SUMMARY"
```

If parsing fails (missing Summary or Acceptance Criteria):
- Post error comment to issue
- Release lock and exit

### 7. Generate and Post Plan

Add `worker:planning` label:
```bash
gh issue edit ${ISSUE_NUMBER} --add-label "worker:planning"
```

Create an execution plan based on the issue content. The plan should include:
- What files will be modified
- What approach will be taken
- Any risks or considerations

Post the plan as a comment:
```bash
gh issue comment ${ISSUE_NUMBER} --body "## Execution Plan

**Issue:** #${ISSUE_NUMBER} - ${ISSUE_TITLE}

**Summary:**
${ISSUE_SUMMARY}

**Acceptance Criteria:**
${ISSUE_ACCEPTANCE}

**Based on:** \`main @ $(git rev-parse --short HEAD)\`

---

**Proposed Approach:**

[Your specific implementation plan here]

---

**Next:** React with :+1: to approve execution

<!-- agent:metadata
status: awaiting_approval
agent: claude-worker
plan_generated_at: $(date -u +%Y-%m-%dT%H:%M:%SZ)
-->"
```

Update labels:
```bash
gh issue edit ${ISSUE_NUMBER} --remove-label "worker:planning" --add-label "worker:awaiting-approval"
```

**STOP HERE** - Inform the user:
- Plan has been posted to the issue
- They need to review and react with thumbs-up to approve
- Re-run this command after approval

Release lock and exit cleanly.

### 8. Execute Work (After Approval)

This step is reached when re-running after approval was detected in step 5.

Update label:
```bash
gh issue edit ${ISSUE_NUMBER} --remove-label "worker:awaiting-approval" --add-label "worker:executing"
```

Create worktree:
```bash
./scripts/worktree-create.sh "issue/${ISSUE_NUMBER}" main
cd "../$(basename $(pwd))-issue-${ISSUE_NUMBER}"
```

**Implement the work:**
- Read the acceptance criteria carefully
- Make the necessary code changes
- Verify each criterion is satisfied
- Stage changes with `git add <specific-files>`

### 9. Commit and Create PR

Commit with proper message:
```bash
git add <files>
git commit -m "${ISSUE_TITLE}

Resolves #${ISSUE_NUMBER}

Co-Authored-By: Claude Worker <claude@anthropic.com>"

git push -u origin "issue/${ISSUE_NUMBER}"
```

Create PR:
```bash
./scripts/github/pr-create.sh --issue ${ISSUE_NUMBER}
```

### 10. Complete

Post completion comment:
```bash
gh issue comment ${ISSUE_NUMBER} --body "## Work Complete

Created PR #[PR_NUMBER]

<!-- agent:metadata
status: complete
agent: claude-worker
-->"
```

Update labels:
```bash
gh issue edit ${ISSUE_NUMBER} --remove-label "worker:executing" --add-label "worker:complete"
```

Release lock and report success.

## State Machine

```
ready → planning → awaiting-approval → executing → complete
                                    ↘ failed/partial
```

## Labels

| Label | State |
|-------|-------|
| worker:planning | Generating execution plan |
| worker:awaiting-approval | Waiting for human approval |
| worker:executing | Work in progress |
| worker:complete | PR created |
| worker:partial | Interrupted |
| worker:failed | Error occurred |

## Library Files

- `.claude/skills/worker/lib/logger.sh` - JSON event logging
- `.claude/skills/worker/lib/lock.sh` - Atomic lock management
- `.claude/skills/worker/lib/parser.sh` - Issue body parsing

## Recovery

If something goes wrong:
1. Check status: `/worker:execute <issue> --status`
2. View logs: `cat .worker/logs/issue-<N>-*.jsonl | jq .`
3. Force restart: `/worker:execute <issue> --force`
4. Clean worktree: `./scripts/worktree-remove.sh issue/<N>`
