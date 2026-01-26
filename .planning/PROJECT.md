# PROJECT: Manifest Automations

## What This Is

An AI-powered development agency where the human operates as CEO — providing vision, decisions, and course-correction while autonomous agents handle coordination and execution. The agency orchestrates multiple projects through a hierarchy of Gemini orchestrators dispatching work to GSD-enabled Claude workers.

## Core Value

**The ONE thing that must work:** A complete loop where the CEO dispatches intent, an orchestrator routes it to workers, Claude executes via GSD, and results land in GitHub with clear status reporting back to the CEO's inbox.

## Vision

Wake up, brew coffee, check the inbox. The inbox is Mission Control in Anti-Gravity — status reports accumulated overnight from orchestrator agents. Review reports, issue high-level directives. Orchestrators take intent and dispatch to Claude workers. Workers spin up sub-agents for parallelization when needed.

Not writing code line by line. Not context-switching between terminals. Walking the floor, checking in on teams, making decisions, pointing in the right direction. Leverage AI the way a CEO leverages an organization.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│  CEO (Human)                                            │
│  └─ Anti-Gravity Mission Control (inbox/briefings)      │
├─────────────────────────────────────────────────────────┤
│  GEMINI ORCHESTRATORS                                   │
│  └─ Model: Flash (fast), Pro (complex), Deep Think      │
│  └─ Dispatch via: claude-code --prompt --skill          │
│  └─ Cross-surface terminal control                      │
├─────────────────────────────────────────────────────────┤
│  GITHUB (coordination layer)                            │
│  └─ Issues = work items                                 │
│  └─ Projects = kanban state                             │
│  └─ PRs = completions                                   │
│  └─ Single source of truth                              │
├─────────────────────────────────────────────────────────┤
│  CLAUDE WORKERS (GSD-enabled)                           │
│  └─ Execute skills and commands                         │
│  └─ Report via gh CLI                                   │
│  └─ Spawn sub-agents for parallelization                │
├─────────────────────────────────────────────────────────┤
│  SUB-AGENTS                                             │
│  └─ Scoped to specific subtasks                         │
│  └─ Tightest constraints                                │
└─────────────────────────────────────────────────────────┘
```

## Key Components

### Agent Definitions

Declarative YAML manifests in `automations/agents/{name}.yaml`:

```yaml
name: code-reviewer
model: gemini-2.0-flash
tools:
  - gh_cli
  - file_read
description: Reviews PRs for style compliance and logic errors
triggers:
  - workflow: pr-review
  - skill: quick-audit
```

Model selection encoded at design time, not runtime. CEO invokes intent (workflows/skills), agent definitions encode which model fits.

### Dispatch Mechanism

Orchestrators invoke Claude workers via cross-surface terminal control:

```bash
claude-code --prompt "Implement auth module per spec" \
            --skill "@/agents/skills/backend-service" \
            --context "issue:GH-142"
```

### GitHub Integration

Agents interact via gh CLI:

```bash
# Orchestrator assigns work
gh issue edit 142 --add-assignee "claude-worker-01" --project-status "In Progress"

# Worker completes
gh pr create --title "feat: auth module" --body "Closes #142"
gh issue close 142 --reason completed
```

### Trust System (Experimental)

Hook-enforced guardrails, not runtime permissions:

**Pre-hooks:** Command sanitization, scope validation, resource limits
**Post-hooks:** Output validation, audit logging, escalation triggers

Trust flows down hierarchy with decreasing scope. Orchestrators can spawn; workers execute; sub-agents stay in lane.

### Project Structure

- **Agency root** contains project repos as **git submodules**
- **Worktrees** are **dynamic** — created per task, cleanup depends on outcome
  - Success → auto-cleanup after PR merged
  - Failure → preserve for debugging

### CEO Inbox

Comprehensive daily briefing via Anti-Gravity Mission Control:
- Task completion summary (finished, in progress, blocked)
- Decisions needed (items requiring human judgment)
- Anomalies/escalations (things that went wrong)

## Constraints

- Anti-Gravity as primary interface (Gemini orchestration layer)
- GitHub as single source of truth (no proprietary state management)
- GSD as execution layer for Claude workers
- Hook-based trust enforcement (not runtime permissions)
- Agents are disposable — hire when needed, sunset when project closes

## Reference Material

- [taches-cc-resources](https://github.com/glittercowboy/taches-cc-resources) — patterns for agent coordination
- [antigravity-awesome-skills](https://github.com/sickn33/antigravity-awesome-skills) — skill library
- [get-shit-done](https://github.com/glittercowboy/get-shit-done) — GSD execution layer

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] GSD operational for Claude workers
- [ ] GitHub configured as coordination layer (issues, projects, PRs)
- [ ] One Gemini orchestrator that can dispatch to GSD and report back
- [ ] Basic agent manifest structure (YAML definitions)
- [ ] Pre/post hooks for trust guardrails
- [ ] Multiple agent personas (specialists vs generalists)
- [ ] Workflow templates for repeatable patterns
- [ ] Dynamic worktree management
- [ ] CEO inbox reporting (daily briefing format)

### Out of Scope

- Custom dashboard (using Anti-Gravity Mission Control instead)
- Proprietary state management (GitHub is the source of truth)
- Runtime permission systems (hooks enforce trust, not runtime checks)

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| GitHub as coordination layer | Auditable, human-readable, no proprietary state | Pending |
| Hook-based trust | Enforcement at execution boundaries, not runtime | Experimental |
| Declarative agent definitions | CEO invokes intent, agents encode implementation | Pending |
| Dynamic worktrees | Isolation without merge conflicts, outcome-based cleanup | Pending |
| Agents as disposable resources | Scale to work, not the other way around | Pending |

---
*Last updated: 2026-01-26 after initialization*
