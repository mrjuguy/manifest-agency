# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-01-26)

**Core value:** Complete loop where CEO dispatches intent, orchestrator routes, Claude executes, results land in GitHub with status reporting back.
**Current focus:** Phase 3 - Single Worker

## Current Position

Phase: 3 of 7 (Single Worker)
Plan: 3 of 4
Status: In progress
Last activity: 2026-01-27 — Completed 03-03-PLAN.md (Worker Execution Skill)

Progress: [████░░░░░░] 48%

## Performance Metrics

**Velocity:**
- Total plans completed: 11
- Average duration: 3 min
- Total execution time: 0.57 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01-foundation | 3 | 6min | 2min |
| 02-github-coordination | 5 | 20min | 4min |
| 03-single-worker | 3 | 8min | 3min |

**Recent Trend:**
- Last 5 plans: 02-04 (4min), 02-05 (10min), 03-01 (2min), 03-02 (4min), 03-03 (2min)
- Trend: Implementation tasks run consistently fast (2-4min), documentation tasks longer (10min)

*Updated after each plan completion*

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- GitHub as coordination layer (auditable, human-readable, no proprietary state)
- Hook-based trust (enforcement at execution boundaries, not runtime)
- Declarative agent definitions (CEO invokes intent, agents encode implementation)
- Dynamic worktrees (isolation without merge conflicts, outcome-based cleanup)
- Agents as disposable resources (scale to work, not the other way around)

**From 01-01 (Repository Foundation):**
- Local git config for submodule behavior (not global)
- LF line endings normalized across platform via .gitattributes

**From 01-02 (Agent Manifest Schema):**
- JSON Schema draft-07 for wide IDE compatibility
- Strict validation (additionalProperties: false) to catch typos
- Optional triggers for both direct invocation and auto-routing
- Provider-specific extensions in providers.* namespace

**From 01-03 (Worktree Automation):**
- Sibling naming pattern for worktrees (../repo-name-branch-name/)
- Safety checks in remove script (uncommitted changes detection)
- Outcome-based cleanup (report stale, manual removal)
- Observability-first with list command (human and machine-readable)

**From 02-01 (Prerequisites):**
- Cache directory structure preserved in git via .gitkeep files while ignoring cached content
- Template placeholders use UPPERCASE format for script substitution
- Progress comments use HTML comment blocks for machine parsing

**From 02-02 (GitHub Project Board):**
- View creation is manual-only due to GitHub API limitation (no createProjectV2View mutation)
- Field ID caching in .cache/github/ with TTL approach reduces API calls 100x
- Inline JSON construction with jq avoids external file dependencies
- Idempotency pattern: check for resource existence before creation

**From 02-03 (Issue Lifecycle Management):**
- Issue number as positional argument (not --issue flag) for natural CLI usage
- Progress metadata embedded in HTML comments for machine parsing without visual clutter
- Blocker comments automatically add 'blocked' label for visibility
- GraphQL project item lookup pattern: query repository issue projectItems

**From 02-04 (PR Management and Project Queries):**
- PR metadata captured in structured table (agent, duration, model, trust level)
- Query script supports multiple output formats (json, table, list) for different consumers
- Generic update script handles both text and single select fields via type detection
- Template loading and placeholder replacement pattern for PR bodies

**From 02-05 (GitHub Actions and Documentation):**
- GitHub Actions workflow uses PROJECT_PAT secret for Projects API access (GITHUB_TOKEN lacks project permissions)
- Workflow handles PR opened/ready_for_review and merged events for status automation
- PR body "Closes #N" pattern triggers both GitHub native issue closure and custom status automation
- Comprehensive README structure: Prerequisites → Quick Start → Script Reference → Workflows → Troubleshooting

**From 03-01 (Worker Infrastructure Setup):**
- Worker configuration in .worker/config.json (600s command timeout, 1800s lock staleness)
- GitHub API retry strategy (3 attempts with exponential backoff, 5 min max rate limit wait)
- .gitkeep pattern for directory preservation from Phase 2 applied to worker infrastructure
- Warning threshold at 80% of timeout for early detection

**From 03-02 (Worker Core Libraries):**
- mkdir-based atomic locking (flock not available on Windows/MINGW64)
- Lock directories instead of lock files with metadata.json for staleness detection
- jq for all JSON generation to ensure proper escaping in logs
- awk for robust multi-line section extraction from issue bodies
- Trap-based cleanup ensures lock release on EXIT/SIGTERM/SIGINT

**From 03-03 (Worker Execution Skill):**
- State machine via GitHub labels - survives crashes, human-visible in UI
- Approval workflow: post plan, exit cleanly, resume on re-run after thumbs up reaction
- Execution placeholder pattern: skill provides orchestration, Claude provides implementation
- 6 worker states: planning, awaiting-approval, executing, complete, partial, failed
- Exit-and-resume pattern for human approval gates (no polling/waiting)

### Pending Todos

None yet.

### Blockers/Concerns

None yet.

## Session Continuity

Last session: 2026-01-27T23:59:14Z
Stopped at: Completed 03-03-PLAN.md (Worker Execution Skill)
Resume file: None
