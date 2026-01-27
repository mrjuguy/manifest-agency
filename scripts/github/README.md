# GitHub Coordination Scripts

Scripts for managing GitHub Projects v2 as the authoritative coordination layer for multi-agent orchestration.

## Overview

These scripts use the GitHub CLI (`gh`) and GraphQL API to:
- Create and configure GitHub Projects with custom fields
- Manage issue lifecycle (claim, status updates, linking)
- Track agent metadata and work state
- Provide programmatic access to project data

**Design principle:** GitHub as the single source of truth - all orchestration state lives in GitHub Issues, Projects, and PR metadata.

## Prerequisites

- **gh CLI**: v2.86.0 or higher ([install](https://cli.github.com/))
- **jq**: v1.7+ for JSON parsing ([install](https://jqlang.github.io/jq/download/))
- **Authentication**: GitHub token with `repo` and `read:project` scopes

Verify installation:
```bash
gh --version  # Should be >= 2.86.0
jq --version  # Should be >= 1.7
gh auth status  # Verify token scopes
```

## Quick Start

1. **Bootstrap the project** (one-time setup):
   ```bash
   bash scripts/github/project-bootstrap.sh
   ```

2. **Create views manually** (GitHub API limitation):
   - Visit your GitHub Projects page
   - Create views: "All Work" (Board), "Ready Queue" (Table), "By Phase" (Table)
   - See [View Creation](#manual-view-creation) section

3. **Start using scripts** to manage issues and PRs

## Script Reference

### project-bootstrap.sh

**Purpose:** Create and configure GitHub Project with custom fields for agent coordination.

**Features:**
- Idempotent - safe to run multiple times
- Creates project "Manifest Automations" if missing
- Adds 6 custom fields: Status, Claimed By, Priority, Complexity, Agent Type, Phase
- Caches field IDs to `.cache/github/project-fields.json` for subsequent scripts

**Usage:**
```bash
bash scripts/github/project-bootstrap.sh
```

**What it creates:**

1. **GitHub Project**: "Manifest Automations"
   - Located at: `https://github.com/users/YOUR_USERNAME/projects/N`
   - Type: Projects v2 (not Classic)

2. **Custom Fields**:
   - **Status** (Single Select): Backlog, Ready, Claimed, In Progress, In Review, Done
   - **Claimed By** (Text): Agent identifier (e.g., "backend-developer")
   - **Priority** (Single Select): P0-critical, P1-high, P2-medium, P3-low
   - **Complexity** (Single Select): XS, S, M, L, XL
   - **Agent Type** (Single Select): agent:any, agent:code-reviewer, agent:backend-developer, agent:frontend-developer, agent:architect
   - **Phase** (Single Select): phase:1, phase:2, phase:3, phase:4, phase:5, phase:6, phase:7

3. **Cache File**: `.cache/github/project-fields.json`
   - Contains field IDs and option IDs for API calls
   - TTL: 1 hour (regenerate if older)
   - Used by all other scripts

**Exit codes:**
- `0` - Success (project ready)
- `1` - Failure (auth, API error)

---

### issue-create.sh

**Purpose:** Create GitHub issues with labels and automatically link to project board.

**Usage:**
```bash
./issue-create.sh --title "TITLE" --body "BODY" [OPTIONS]

# Or with template:
./issue-create.sh --title "TITLE" --template path/to/template.md [OPTIONS]
```

**Required parameters:**
- `--title TEXT` - Issue title
- `--body TEXT` OR `--template FILE` - Issue description (mutually exclusive)

**Optional parameters:**
- `--labels "label1,label2"` - Comma-separated custom labels
- `--project NUMBER` - Project number (default: 1)
- `--priority P0|P1|P2|P3` - Priority level (default: P2-medium)
- `--complexity XS|S|M|L|XL` - Complexity estimate
- `--agent-type TYPE` - Agent type (default: agent:any)
- `--phase NUMBER` - Phase number (1-7)

**Examples:**
```bash
# Simple issue
./issue-create.sh \
  --title "Implement JWT authentication" \
  --body "Add JWT token generation and validation"

# Issue from template with full metadata
./issue-create.sh \
  --title "Setup PostgreSQL database" \
  --template templates/issue-database.md \
  --labels "backend,database" \
  --priority P1-high \
  --complexity M \
  --agent-type agent:backend-developer \
  --phase 2

# Urgent bug for any agent
./issue-create.sh \
  --title "Fix login crash" \
  --body "App crashes on login with null pointer" \
  --priority P0-critical \
  --agent-type agent:any
```

**Output:**
Returns issue number and URL:
```
ISSUE_NUMBER=42
ISSUE_URL=https://github.com/...
```

**Exit codes:**
- `0` - Success (issue created)
- `1` - Validation error or API failure

---

### issue-claim.sh

**Purpose:** Claim an issue for an agent and update project status.

**Usage:**
```bash
./issue-claim.sh ISSUE_NUMBER --agent AGENT_NAME
```

**Required parameters:**
- `ISSUE_NUMBER` - Issue number to claim (positional)
- `--agent AGENT_NAME` - Agent identifier (e.g., "backend-developer")

**What it does:**
1. Sets "Claimed By" field to agent name
2. Updates Status to "Claimed"
3. Adds claim comment with timestamp and metadata

**Examples:**
```bash
# Backend agent claims issue #42
./issue-claim.sh 42 --agent backend-developer

# Code reviewer claims issue #123
./issue-claim.sh 123 --agent code-reviewer
```

**Requirements:**
- Issue must be added to project first
- Field cache must exist (run `project-bootstrap.sh` first)

**Exit codes:**
- `0` - Success (issue claimed)
- `1` - Issue not found, not in project, or API failure

---

### issue-update-status.sh

**Purpose:** Update GitHub issue status in project board.

**Usage:**
```bash
./issue-update-status.sh ISSUE_NUMBER --status STATUS
```

**Required parameters:**
- `ISSUE_NUMBER` - Issue number to update (positional)
- `--status STATUS` - New status value

**Valid status values:**
- `Backlog` - Not yet ready
- `Ready` - Ready for claiming
- `Claimed` - Claimed by an agent
- `In Progress` - Work in progress
- `In Review` - PR opened
- `Done` - Completed and merged

**Examples:**
```bash
# Move issue to In Progress
./issue-update-status.sh 42 --status "In Progress"

# Mark issue as done
./issue-update-status.sh 123 --status Done

# Move back to backlog
./issue-update-status.sh 456 --status Backlog
```

**Requirements:**
- Issue must be added to project board first
- Field cache must exist

**Exit codes:**
- `0` - Success (status updated)
- `1` - Invalid status, issue not in project, or API failure

---

### issue-comment.sh

**Purpose:** Post structured comments to GitHub issues with progress metadata.

**Usage:**
```bash
./issue-comment.sh ISSUE_NUMBER --message "MESSAGE" [OPTIONS]
```

**Required parameters:**
- `ISSUE_NUMBER` - Issue number (positional)
- `--message "TEXT"` - Human-readable comment

**Optional progress metadata:**
- `--agent AGENT_NAME` - Agent posting the comment
- `--status STATUS` - Current status (claimed, implementing, testing, blocked, complete)
- `--progress N` - Progress percentage (0-100)
- `--elapsed TIME` - Time elapsed (e.g., "5m 23s", "1h 15m")
- `--current-task "TEXT"` - Current task description
- `--blockers "TEXT"` - Blocker description (triggers 'blocked' label)

**Examples:**
```bash
# Simple comment
./issue-comment.sh 42 --message "Starting work on this issue"

# Progress update
./issue-comment.sh 42 \
  --message "Implementing JWT refresh logic" \
  --agent backend-developer \
  --status implementing \
  --progress 40 \
  --elapsed "8m 15s" \
  --current-task "Writing token rotation"

# Completion
./issue-comment.sh 42 \
  --message "Implementation complete, ready for review" \
  --agent backend-developer \
  --status complete \
  --progress 100

# Blocker report (adds 'blocked' label)
./issue-comment.sh 42 \
  --message "Blocked on API credentials" \
  --agent backend-developer \
  --status blocked \
  --blockers "Waiting for Stripe API key from #45"
```

**Comment format:**
```markdown
## 🤖 Progress Update

[Message]

**Progress Details:**
- **Status:** `implementing`
- **Progress:** 40%
- **Elapsed:** 8m 15s

**Current Task:** Writing token rotation

<!-- agent:progress
agent: backend-developer
status: implementing
progress: 40
elapsed: 8m 15s
timestamp: 2026-01-27T14:30:00Z
-->
```

**Exit codes:**
- `0` - Success (comment posted)
- `1` - Issue not found or API failure

---

### pr-create.sh

**Purpose:** Create pull requests with structured agent metadata.

**Usage:**
```bash
./pr-create.sh --issue NUMBER --agent NAME [OPTIONS]
```

**Required parameters:**
- `--issue NUMBER` - Issue this PR closes
- `--agent NAME` - Agent identifier

**Optional parameters:**
- `--worktree PATH` - Worktree path (for metadata)
- `--start-time EPOCH` - Unix timestamp when work started (for duration)
- `--title TITLE` - Override auto-generated title
- `--base BRANCH` - Base branch (default: main)
- `--draft` - Create as draft PR

**Environment variables:**
- `AGENT_TRUST_LEVEL` - Trust level (default: 2)
- `AGENT_MODEL` - Model name (default: claude-sonnet-4.5)

**Examples:**
```bash
# Basic PR
./pr-create.sh \
  --issue 42 \
  --agent backend-developer

# PR with duration tracking
./pr-create.sh \
  --issue 42 \
  --agent backend-developer \
  --start-time 1769508282

# Draft PR to develop branch
./pr-create.sh \
  --issue 123 \
  --agent frontend-developer \
  --base develop \
  --draft

# PR with custom title and metadata
AGENT_TRUST_LEVEL=3 AGENT_MODEL=claude-opus-4 ./pr-create.sh \
  --issue 42 \
  --agent architect \
  --title "Refactor authentication system" \
  --worktree ../manifest-feature-auth
```

**PR body structure:**
```markdown
## Summary
<!-- Brief description of changes -->

## Changes
- Change 1
- Change 2

## Testing
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing complete

Closes #42

---
**Agent Metadata**
| Field | Value |
|-------|-------|
| Agent | backend-developer |
| Issue | #42 |
| Worktree | feature/42-auth |
| Duration | 8min |
| Model | claude-sonnet-4.5 |
| Trust Level | 2 |
| Commits | 3 |
```

**Exit codes:**
- `0` - Success (PR created, returns URL)
- `1` - Validation error, no commits, or API failure

---

### project-query.sh

**Purpose:** Query GitHub Project items with filters to discover available work.

**Usage:**
```bash
./project-query.sh [OPTIONS]
```

**Filter options:**
- `--status STATUS` - Filter by status (Ready, In Progress, etc.)
- `--unclaimed` - Filter where Claimed By is empty
- `--agent-type TYPE` - Filter by agent type label
- `--phase NUMBER` - Filter by phase
- `--priority P0|P1|P2|P3` - Filter by priority
- `--limit NUMBER` - Max items (default: 50)
- `--format FORMAT` - Output format: json, table, list (default: table)
- `--project NUMBER` - Project number (default: 1)

**Examples:**
```bash
# Find unclaimed Ready issues for any agent
./project-query.sh --status Ready --unclaimed

# Find all in-progress work
./project-query.sh --status "In Progress"

# Find work by phase
./project-query.sh --phase 2

# Find P0 priority items
./project-query.sh --priority P0-critical

# Find work for specific agent type (JSON output)
./project-query.sh \
  --agent-type "agent:backend-developer" \
  --unclaimed \
  --format json
```

**Output formats:**

**table** (default):
```
Issue | Title                    | Status | Priority | Phase   | Claimed By
------|--------------------------|--------|----------|---------|------------
42    | Implement JWT auth       | Ready  | P1-high  | phase:2 | Unclaimed
43    | Setup database schema    | Ready  | P2-medium| phase:2 | Unclaimed
```

**list**:
```
#42 - Implement JWT auth
#43 - Setup database schema
```

**json**:
```json
[
  {
    "number": 42,
    "title": "Implement JWT auth",
    "status": "Ready",
    "priority": "P1-high",
    "phase": "phase:2",
    "claimed by": null
  }
]
```

**Exit codes:**
- `0` - Success (items returned)
- `1` - Project not found or API failure

---

### project-update-field.sh

**Purpose:** Generic field update script for any GitHub Project field.

**Usage:**
```bash
./project-update-field.sh ISSUE_NUMBER --field NAME --value VALUE
```

**Required parameters:**
- `ISSUE_NUMBER` - Issue number (positional)
- `--field NAME` - Field name (Status, Priority, Complexity, etc.)
- `--value VALUE` - New value for the field

**Optional parameters:**
- `--project NUMBER` - Project number (default: 1)

**Supported fields:**
- **Status** - Backlog, Ready, Claimed, In Progress, In Review, Done
- **Priority** - P0-critical, P1-high, P2-medium, P3-low
- **Complexity** - XS, S, M, L, XL
- **Agent Type** - agent:any, agent:code-reviewer, agent:backend-developer, etc.
- **Phase** - phase:1 through phase:7
- **Claimed By** - Any text (agent identifier)

**Examples:**
```bash
# Update priority
./project-update-field.sh 42 --field Priority --value P1-high

# Update complexity estimate
./project-update-field.sh 42 --field Complexity --value M

# Update phase
./project-update-field.sh 42 --field Phase --value "phase:3"

# Set agent type
./project-update-field.sh 42 --field "Agent Type" --value "agent:backend-developer"

# Update claimed by (text field)
./project-update-field.sh 42 --field "Claimed By" --value "gsd-executor-01"
```

**Field type detection:**
- Automatically detects field type (text vs. single select)
- Text fields: Value set directly
- Single select fields: Looks up option ID from cache

**Exit codes:**
- `0` - Success (field updated)
- `1` - Field not found, invalid value, or API failure

---

## Worker Skill

The worker skill provides automated execution of GitHub issues in isolated worktrees with approval workflow and comprehensive observability.

### Overview

The worker skill orchestrates the complete lifecycle of executing work from a GitHub issue:

1. **Parse** issue for Summary and Acceptance Criteria
2. **Generate** execution plan and post to issue
3. **Wait** for human approval (thumbs up reaction)
4. **Create** isolated git worktree
5. **Execute** the work (Claude implements based on issue content)
6. **Commit** changes with proper message
7. **Create** pull request with agent metadata
8. **Update** issue status and labels

**Key features:**
- Label-based state machine (survives crashes)
- Approval workflow (exit and resume pattern)
- Structured JSON logging
- Lock-based concurrency control
- Comprehensive error handling

### Usage

**Basic invocation:**
```bash
./scripts/worker/execute.sh --issue 42
```

**With options:**
```bash
# Override stale lock after crash
./scripts/worker/execute.sh --issue 42 --force

# Check execution status
./scripts/worker/execute.sh --issue 42 --status
```

### Workflow

**First run (Planning Phase):**
```bash
# User invokes worker
./scripts/worker/execute.sh --issue 42

# Worker actions:
# 1. Acquires lock
# 2. Parses issue body (Summary, Acceptance Criteria)
# 3. Adds "worker:planning" label
# 4. Posts execution plan as comment
# 5. Updates to "worker:awaiting-approval" label
# 6. Exits cleanly (no waiting/polling)

# User reviews plan in GitHub issue comment
# User adds thumbs up reaction to approve
```

**Second run (Execution Phase):**
```bash
# User re-runs after approval
./scripts/worker/execute.sh --issue 42

# Worker actions:
# 1. Acquires lock
# 2. Detects "worker:awaiting-approval" label
# 3. Checks for thumbs up on plan comment
# 4. Updates to "worker:executing" label
# 5. Creates worktree: ../manifest-automations-issue-42/
# 6. Executes work (Claude implements based on Summary/Acceptance)
# 7. Stages all changes
# 8. Creates single commit: "Resolves #42"
# 9. Pushes branch: issue/42
# 10. Creates PR with metadata
# 11. Posts completion comment
# 12. Updates to "worker:complete" label
# 13. Releases lock
```

### State Machine

The worker uses GitHub labels as the state machine, ensuring state survives process crashes:

| Label | Description | Next States |
|-------|-------------|-------------|
| `worker:planning` | Analyzing issue, generating plan | awaiting-approval |
| `worker:awaiting-approval` | Plan posted, waiting for approval | executing, failed |
| `worker:executing` | Implementing the work | complete, partial, failed |
| `worker:complete` | Work done, PR created | - |
| `worker:partial` | Interrupted during execution | executing (resume) |
| `worker:failed` | Execution error | executing (retry) |

**State transitions:**
```
issue created
    │
    v (first run)
┌─────────────┐
│  planning   │ (parsing issue, generating plan)
└──────┬──────┘
       │ (posts plan comment)
       v
┌─────────────┐
│  awaiting-  │ (exits, waits for human approval)
│  approval   │
└──────┬──────┘
       │ (re-run after thumbs up)
       v
┌─────────────┐
│  executing  │ (creates worktree, implements work)
└──────┬──────┘
       │ (creates PR)
       v
┌─────────────┐
│  complete   │ (done)
└─────────────┘

Error states:
├─ partial (interrupted, work may be incomplete)
└─ failed (error occurred, see error comment)
```

### Issue Format

Worker requires structured issue format with specific sections:

```markdown
## Summary

Brief description of what needs to be implemented.

## Acceptance Criteria

- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3
```

**Required sections:**
- `## Summary` - High-level description
- `## Acceptance Criteria` - Checklist of requirements

Missing sections will cause parse error with helpful comment.

### Configuration

Worker configuration lives in `.worker/config.json`:

```json
{
  "command_timeout_seconds": 600,
  "lock_staleness_threshold_seconds": 1800,
  "github_api_retry_attempts": 3,
  "github_api_retry_backoff_base": 2,
  "github_api_max_rate_limit_wait_seconds": 300
}
```

**Key settings:**
- **command_timeout_seconds** (600): Max time for single command
- **lock_staleness_threshold_seconds** (1800): When lock considered stale
- **github_api_retry_attempts** (3): Number of retry attempts
- **github_api_max_rate_limit_wait_seconds** (300): Max wait for rate limit

### File Structure

```
.worker/
├── config.json              # Worker configuration
├── locks/                   # Lock directories (gitignored)
│   └── issue-42.lock/
│       └── metadata.json    # Lock metadata
└── logs/                    # JSON event logs (gitignored)
    └── issue-42-20260127-183045.jsonl

.claude/skills/worker/
├── execute.md               # Main worker skill
├── lib/
│   ├── logger.sh           # JSON event logging
│   ├── lock.sh             # Lock management
│   └── parser.sh           # Issue body parsing
└── templates/
    ├── plan-comment.md     # Plan comment template
    ├── start-comment.md    # Start notification
    ├── complete-comment.md # Completion comment
    └── failure-comment.md  # Error comment
```

### Recovery Procedures

**Stale lock detected:**
```bash
# Check status first
./scripts/worker/execute.sh --issue 42 --status

# View log file for crash details
tail .worker/logs/issue-42-*.jsonl | jq .

# Override stale lock if safe
./scripts/worker/execute.sh --issue 42 --force
```

**Execution failed:**
```bash
# Worker posts failure comment with:
# - Error phase
# - Error message
# - Full error details
# - Log file path
# - Recovery options

# Recovery options:
# 1. Fix issue, then re-run
# 2. Post "retry" comment and re-run
# 3. Post "skip" comment to skip failed step
# 4. Post "commit-partial" to commit incomplete work
# 5. Post "abort" to clean up and abandon
```

**Interrupted execution (partial state):**
```bash
# Worker adds "worker:partial" label
# Work may be partially complete in worktree

# Check worktree status
git worktree list
cd ../manifest-automations-issue-42/
git status

# Resume or restart
./scripts/worker/execute.sh --issue 42
```

### Example Session

**Complete end-to-end example:**

```bash
# 1. Create issue in GitHub UI or via CLI
gh issue create --title "[Feature] Add user authentication" --body "## Summary
Add JWT-based authentication to the API.

## Acceptance Criteria
- [ ] JWT token generation endpoint
- [ ] Token validation middleware
- [ ] Refresh token rotation
- [ ] Unit tests for auth module"

# Output: Created issue #42

# 2. First worker run (planning)
./scripts/worker/execute.sh --issue 42

# Output:
# [worker] Starting execution for issue #42
# [worker] Parsing issue #42...
# [worker] Issue: [Feature] Add user authentication
# [worker] Generating execution plan...
# [worker] Posting execution plan...
# [worker] Plan posted to issue #42
#
# Next steps:
#   1. Review the execution plan in the issue comment
#   2. React with thumbs up to approve
#   3. Re-run: ./scripts/worker/execute.sh --issue 42

# 3. Review plan in GitHub issue, add thumbs up reaction

# 4. Second worker run (execution)
./scripts/worker/execute.sh --issue 42

# Output:
# [worker] Starting execution for issue #42
# [worker] Issue in awaiting-approval state - checking for approval...
# [worker] Approval received - proceeding with execution
# [worker] Starting execution...
# [worker] Creating worktree: ../manifest-automations-issue-42
# [worker] Working in: /path/to/../manifest-automations-issue-42
# [worker] Execution complete - creating commit...
# [worker] Pushing branch...
# [worker] Creating PR...
# [worker] Execution complete
#   PR: https://github.com/user/repo/pull/123
#   Duration: 3min

# 5. PR automatically created, issue updated to "In Review"
# 6. After PR merges, GitHub Actions updates issue to "Done"
```

### Integration with Scripts

Worker skill delegates to existing scripts for specific operations:

**Worktree management:**
- `scripts/worktree-create.sh` - Creates isolated worktree
- `scripts/worktree-remove.sh` - Cleans up after merge

**GitHub operations:**
- `scripts/github/pr-create.sh` - Creates PR with agent metadata
- `scripts/github/issue-update-status.sh` - Updates project status
- `scripts/github/issue-comment.sh` - Posts progress comments

**Worker libraries:**
- `.claude/skills/worker/lib/logger.sh` - Structured event logging
- `.claude/skills/worker/lib/lock.sh` - Lock acquisition and staleness detection
- `.claude/skills/worker/lib/parser.sh` - Issue body section extraction

---

## Agent Workflows

Common workflows for agents and orchestrators.

### Agent Claiming and Completing Work

```bash
# 1. Find unclaimed work matching capabilities
./project-query.sh --status Ready --unclaimed --agent-type agent:backend-developer

# Output:
# Issue | Title                    | Status | Priority | Phase   | Claimed By
# ------|--------------------------|--------|----------|---------|------------
# 42    | Implement JWT auth       | Ready  | P1-high  | phase:2 | Unclaimed

# 2. Claim the issue
./issue-claim.sh 42 --agent backend-developer-01

# 3. Create worktree for isolated development
cd ../
./Manifest-Automations/scripts/worktree-create.sh feature/42-jwt-auth

# 4. Work on the feature...
cd Manifest-Automations-feature-42-jwt-auth/
git add src/auth/jwt.ts
git commit -m "feat(auth): implement JWT token generation"

# 5. Update progress periodically
./scripts/github/issue-comment.sh 42 \
  --message "JWT generation complete, working on validation" \
  --agent backend-developer-01 \
  --status implementing \
  --progress 50 \
  --elapsed "12m 30s"

# 6. Create PR when done
./scripts/github/pr-create.sh \
  --issue 42 \
  --agent backend-developer-01 \
  --start-time 1769508282

# PR creation automatically:
# - Links to issue via "Closes #42"
# - Triggers GitHub Actions to update status to "In Review"
# - Adds agent metadata table

# 7. GitHub Actions automation (when PR merges):
# - Updates issue status to "Done"
# - GitHub's native "Closes #42" closes the issue
# - Adds completion comment
```

### Orchestrator Assigning Work

```bash
# 1. Create issue for task
./issue-create.sh \
  --title "Implement feature X" \
  --template templates/task-template.md \
  --priority P1-high \
  --complexity M \
  --agent-type agent:backend-developer \
  --phase 2

# Output:
# ISSUE_NUMBER=43
# ISSUE_URL=https://github.com/...

# 2. Optionally assign specific agent
./project-update-field.sh 43 --field "Claimed By" --value "backend-agent-01"

# 3. Update status to signal readiness
./issue-update-status.sh 43 --status Ready

# Agent can now discover and claim the work
```

### Monitoring Progress

```bash
# Check all in-progress work
./project-query.sh --status "In Progress" --format table

# Check work by phase
./project-query.sh --phase 2 --format table

# Find blocked items
./project-query.sh --status "In Progress" --format json | \
  jq '.[] | select(.labels[]? | contains("blocked"))'

# Check unclaimed work by priority
./project-query.sh --unclaimed --priority P0-critical
./project-query.sh --unclaimed --priority P1-high
```

---

## GitHub Actions Setup

The `.github/workflows/project-status.yml` workflow automates status transitions on PR events.

### Workflow Features

- **PR opened/ready_for_review**: Updates linked issue status to "In Review"
- **PR merged**: Updates linked issue status to "Done"
- **Automatic issue closure**: GitHub's native "Closes #N" closes the issue
- **Structured comments**: Adds completion comments with metadata

### Required Secret: PROJECT_PAT

The workflow requires a Personal Access Token with project permissions.

**Why needed:**
- `secrets.GITHUB_TOKEN` has `repo` scope but lacks project permissions
- Projects API requires `read:project` scope
- Solution: Create Personal Access Token (PAT) with correct scopes

**Setup instructions:**

1. **Generate PAT:**
   - Go to GitHub Settings → Developer settings → Personal access tokens → Fine-grained tokens
   - Click "Generate new token"
   - Set token name: `Manifest Automations Project PAT`
   - Set expiration: 90 days (or as required)
   - **Repository access:** Select "Only select repositories" → "Manifest Automations"
   - **Permissions:**
     - Repository permissions:
       - Contents: Read and write
       - Issues: Read and write
       - Pull requests: Read and write
     - Organization permissions (if user project):
       - Projects: Read and write

2. **Add as repository secret:**
   - Go to repository Settings → Secrets and variables → Actions
   - Click "New repository secret"
   - Name: `PROJECT_PAT`
   - Value: (paste token)
   - Click "Add secret"

3. **Verify workflow:**
   - Create test PR with "Closes #N" in body
   - Check Actions tab for workflow run
   - Verify issue status updated in project board

### Alternative: GitHub App (future)

For production use, consider creating a GitHub App with project permissions instead of using a PAT. Benefits:
- No expiration
- Better security (app identity vs. user token)
- Granular permissions
- Audit trail

---

## Manual View Creation

**Note:** GitHub Projects v2 API does not support view creation via GraphQL. Views must be created manually through the UI.

### Recommended Views

**1. All Work (Board View)**
- **Layout:** Board
- **Group by:** Status
- **Sort by:** Priority (drag P0 to top)
- **Purpose:** Default kanban view of all work

**2. Ready Queue (Table View)**
- **Layout:** Table
- **Filter:** Status = "Ready"
- **Columns:** Title, Priority, Complexity, Agent Type, Phase
- **Sort by:** Priority (ascending)
- **Purpose:** Agents discover available work

**3. By Phase (Table View)**
- **Layout:** Table
- **Group by:** Phase
- **Columns:** Title, Status, Priority, Claimed By
- **Sort by:** Priority within each phase
- **Purpose:** Track progress across project phases

**4. In Progress (Table View)**
- **Layout:** Table
- **Filter:** Status = "In Progress" OR Status = "In Review"
- **Columns:** Title, Claimed By, Priority, Labels
- **Purpose:** Monitor active work

**5. Blocked (Table View)**
- **Layout:** Table
- **Filter:** Labels contains "blocked"
- **Columns:** Title, Claimed By, Priority, Status
- **Purpose:** Surface blockers requiring attention

### Creating Views

1. Visit your project: `https://github.com/users/YOUR_USERNAME/projects/N`
2. Click '+' next to view tabs
3. Select "New view"
4. Choose layout (Board or Table)
5. Configure:
   - **Filters:** Add field filters
   - **Group by:** Select grouping field
   - **Sort:** Set sort order
   - **Columns (Table only):** Select visible fields
6. Click "Save view"
7. Name the view

---

## Cache Structure

The `.cache/github/project-fields.json` file contains project metadata and field definitions.

**Example structure:**
```json
{
  "data": {
    "user": {
      "projectV2": {
        "id": "PVT_kwDOACL67M4AZbcd",
        "fields": {
          "nodes": [
            {
              "id": "PVTF_lADOACL67M4AZbcdzgC1234",
              "name": "Status",
              "dataType": "SINGLE_SELECT",
              "options": [
                {"id": "abc123", "name": "Backlog"},
                {"id": "def456", "name": "Ready"},
                {"id": "ghi789", "name": "Claimed"},
                {"id": "jkl012", "name": "In Progress"},
                {"id": "mno345", "name": "In Review"},
                {"id": "pqr678", "name": "Done"}
              ]
            },
            {
              "id": "PVTF_lADOACL67M4AZbcdzgC5678",
              "name": "Claimed By",
              "dataType": "TEXT"
            }
          ]
        }
      }
    }
  }
}
```

**Usage in scripts:**
```bash
# Extract field ID
STATUS_FIELD_ID=$(jq -r '.data.user.projectV2.fields.nodes[] | select(.name=="Status") | .id' .cache/github/project-fields.json)

# Extract option ID
CLAIMED_OPTION_ID=$(jq -r '.data.user.projectV2.fields.nodes[] | select(.name=="Status") | .options[] | select(.name=="Claimed") | .id' .cache/github/project-fields.json)
```

**Cache TTL:**
- Generated by `project-bootstrap.sh`
- Valid for 1 hour
- Regenerate if fields change or cache is stale

---

## Troubleshooting

### "Resource not accessible by integration"

**Cause:** GitHub token missing required scopes.

**Fix:**
```bash
# Check current scopes
gh auth status

# Refresh token with correct scopes
gh auth refresh --scopes repo,read:project,workflow
```

### "jq: command not found"

**Cause:** jq not installed.

**Fix:**
```bash
# Windows (Chocolatey)
choco install jq

# Windows (Scoop)
scoop install jq

# macOS (Homebrew)
brew install jq

# Linux (apt)
sudo apt-get install jq

# Verify
jq --version
```

### "Project not found" after creation

**Cause:** User vs Organization project mismatch.

**Fix:** Bootstrap script creates user projects. For organization projects:
1. Modify GraphQL queries to use `organization(login: $org)` instead of `user(login: $owner)`
2. Update `OWNER` variable to organization name
3. Ensure PAT has organization project permissions

### "Issue not in project"

**Cause:** Issue not added to project board.

**Fix:**
```bash
# Add issue to project
gh issue edit ISSUE_NUMBER --add-project PROJECT_NUMBER

# Or recreate issue with auto-linking
./issue-create.sh --title "..." --body "..." --project PROJECT_NUMBER
```

### "Field cache not found"

**Cause:** `.cache/github/project-fields.json` missing.

**Fix:**
```bash
# Run bootstrap to create cache
bash scripts/github/project-bootstrap.sh

# Or manually fetch fields
gh api graphql -f query='...' > .cache/github/project-fields.json
```

### Rate limit errors

**Cause:** Too many GraphQL API calls in short time.

**Fix:**
```bash
# Check rate limit
gh api rate_limit | jq '.resources.graphql'

# Wait for reset time
# Or use cache more aggressively (cache field lookups)
```

### GitHub Actions workflow not triggering

**Cause:** Missing PROJECT_PAT secret or incorrect permissions.

**Fix:**
1. Verify PROJECT_PAT secret exists in repository settings
2. Check token has `repo` and `read:project` scopes
3. Verify workflow file in `.github/workflows/` directory
4. Check Actions tab for error messages
5. Test with dummy PR

---

## References

- [GitHub Projects v2 API](https://docs.github.com/en/issues/planning-and-tracking-with-projects/automating-your-project/using-the-api-to-manage-projects)
- [GitHub CLI Manual](https://cli.github.com/manual/)
- [GraphQL API Reference](https://docs.github.com/en/graphql/reference)
- [GraphQL Rate Limits](https://docs.github.com/en/graphql/overview/rate-limits-and-query-limits-for-the-graphql-api)
- [GitHub Actions Workflow Syntax](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)
- Phase 02 Research: `.planning/phases/02-github-coordination/02-RESEARCH.md`
- Phase 02 Context: `.planning/phases/02-github-coordination/02-CONTEXT.md`

---

## Contributing

When adding new scripts:
1. Follow existing naming pattern: `resource-action.sh`
2. Include `--help` flag with usage documentation
3. Use positional arguments for primary resource (issue number, etc.)
4. Validate required parameters and provide clear error messages
5. Use colored output: `GREEN` for success, `RED` for errors, `YELLOW` for warnings
6. Cache field lookups to minimize API calls
7. Update this README with usage examples
8. Add to [Agent Workflows](#agent-workflows) if relevant

---

*Last updated: 2026-01-27*
*Phase: 02-github-coordination*
