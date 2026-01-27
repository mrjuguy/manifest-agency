# Architecture Patterns: Multi-Agent AI Orchestration Systems

**Domain:** Multi-Agent AI Orchestration / AI-Powered Development Agency
**Researched:** 2026-01-26
**Confidence:** HIGH (verified via official Microsoft, Google, and IBM documentation)

## Recommended Architecture

Multi-agent AI orchestration systems in 2026 follow a **layered, hierarchical architecture** with standardized communication protocols. The recommended approach combines:

1. **Hierarchical orchestration** for strategic coordination (Gemini orchestrators)
2. **Protocol-based communication** (A2A for agent-to-agent, MCP for tool integration)
3. **External source-of-truth** (GitHub for state management)
4. **Hook-based guardrails** (trust enforcement at execution boundaries)

```
┌─────────────────────────────────────────────────────────────────┐
│  Layer 7: CEO Interface (Mission Control)                       │
│  └─ Anti-Gravity Inbox, Briefings, Decision Points              │
├─────────────────────────────────────────────────────────────────┤
│  Layer 6: Orchestration Agents (Gemini Flash/Pro/Deep Think)    │
│  └─ Task decomposition, routing, status aggregation             │
│  └─ Communicate via: A2A protocol                               │
├─────────────────────────────────────────────────────────────────┤
│  Layer 5: Coordination Layer (GitHub as Source of Truth)        │
│  └─ Issues (work items), Projects (kanban), PRs (completions)   │
│  └─ Audit trail, version control, state persistence             │
├─────────────────────────────────────────────────────────────────┤
│  Layer 4: Worker Agents (Claude via GSD)                        │
│  └─ Execute commands/skills, spawn sub-agents                   │
│  └─ Report via: gh CLI to GitHub                                │
├─────────────────────────────────────────────────────────────────┤
│  Layer 3: Tool Integration (MCP Protocol)                       │
│  └─ File system, terminals, APIs, external services             │
│  └─ Standardized tool access across all agents                  │
├─────────────────────────────────────────────────────────────────┤
│  Layer 2: Trust & Guardrails (Hook System)                      │
│  └─ Pre-hooks: Command sanitization, scope validation           │
│  └─ Post-hooks: Output validation, audit logging                │
├─────────────────────────────────────────────────────────────────┤
│  Layer 1: Foundation (Agent Definitions + Infrastructure)       │
│  └─ YAML manifests, model selection, tool permissions           │
│  └─ Worktree management, git submodules                         │
└─────────────────────────────────────────────────────────────────┘
```

**Data Flow Direction:**
- **Top-down:** Human intent → Orchestrators → Workers → Tools
- **Bottom-up:** Results → GitHub → Orchestrators → Mission Control
- **Horizontal:** Agent-to-agent via A2A protocol, agent-to-tool via MCP

## Component Boundaries

### Layer 7: CEO Interface
| Responsibility | Inputs | Outputs | Communicates With |
|----------------|--------|---------|-------------------|
| Human decision-making and strategic direction | Status reports, briefings, escalations | High-level directives, approvals | Layer 6 (Orchestrators) |
| Mission visibility | Aggregated task completions, blockers, anomalies | Course corrections, priority changes | Anti-Gravity IDE interface |

**Boundaries:**
- Does NOT write code or execute tasks directly
- Does NOT manage individual agent conversations
- DOES provide vision, decisions, approvals

---

### Layer 6: Orchestration Agents
| Responsibility | Inputs | Outputs | Communicates With |
|----------------|--------|---------|-------------------|
| Task decomposition and routing | CEO directives, GitHub issue state | Dispatched work items, status summaries | Layer 5 (GitHub), Layer 4 (Workers), Layer 7 (CEO) |
| Progress monitoring and aggregation | Worker completions, PR status, blockers | Daily briefings, escalations | A2A protocol for agent coordination |
| Dynamic agent spawning | Workload assessment | Sub-agent creation/cleanup | Worker agents via dispatch commands |

**Model Selection:**
- **Flash:** Simple routing, status aggregation, routine decisions (fast)
- **Pro:** Complex task decomposition, multi-step planning (balanced)
- **Deep Think:** Strategic planning, ambiguous problems (deliberate)

**Boundaries:**
- Does NOT execute code directly
- Does NOT access tools directly (delegates to workers)
- DOES coordinate, route, monitor, report

---

### Layer 5: Coordination Layer (GitHub)
| Responsibility | Inputs | Outputs | Communicates With |
|----------------|--------|---------|-------------------|
| Single source of truth for project state | gh CLI commands from workers/orchestrators | Issue state, PR diffs, project status | All agent layers (via gh CLI) |
| Audit trail and version control | Commits, PR reviews, issue updates | Git history, blame, timeline | Git hooks for trust enforcement |
| Work item management | Issue creation, status changes, assignments | Kanban view, dependency tracking | Human reviewers, automation |

**Why GitHub:**
- Auditable (every action logged)
- Human-readable (issues/PRs not proprietary formats)
- Standard tooling (gh CLI, git, webhooks)
- External to agent system (agents can fail, GitHub persists)

**Boundaries:**
- Does NOT execute agent logic
- Does NOT make decisions
- DOES persist ALL state changes

---

### Layer 4: Worker Agents (Claude)
| Responsibility | Inputs | Outputs | Communicates With |
|----------------|--------|---------|-------------------|
| Execute commands, skills, and sub-tasks | Dispatched work from orchestrators | Code, PRs, issue updates, status reports | Layer 3 (Tools via MCP), Layer 5 (GitHub via gh CLI), Layer 6 (Orchestrators via status updates) |
| Spawn sub-agents for parallelization | Task complexity assessment | Parallel execution of subtasks | Sub-agents (scoped, constrained) |
| Report progress and results | Task execution state | gh issue comments, PR creation, status changes | GitHub coordination layer |

**Dispatch Mechanism:**
```bash
# Orchestrator invokes worker via cross-surface terminal control
claude-code --prompt "Implement auth module per spec" \
            --skill "@/agents/skills/backend-service" \
            --context "issue:GH-142"
```

**Boundaries:**
- Does NOT make strategic decisions (executes defined plans)
- Does NOT coordinate across projects (orchestrators do that)
- DOES execute, report, spawn scoped sub-agents

---

### Layer 3: Tool Integration (MCP)
| Responsibility | Inputs | Outputs | Communicates With |
|----------------|--------|---------|-------------------|
| Standardized tool/API access | Agent tool requests via MCP protocol | File operations, terminal execution, API responses | Worker agents, external systems |
| Abstract implementation details | Tool invocation requests | Normalized responses | File system, terminals, APIs |

**Why MCP:**
- Universal adapter for tools, APIs, data sources
- Eliminates custom integration code per agent
- Standardizes capability access

**Boundaries:**
- Does NOT make decisions about WHAT to execute
- Does NOT track state (agents/GitHub do that)
- DOES provide standardized access to capabilities

---

### Layer 2: Trust & Guardrails
| Responsibility | Inputs | Outputs | Communicates With |
|----------------|--------|---------|-------------------|
| Enforce execution constraints | Pre-execution: Command payloads | Sanitized/rejected commands | Worker agents, orchestrators |
| Validate outcomes | Post-execution: Command results | Audit logs, escalation triggers | Audit systems, trust ledger |

**Hook Architecture:**
- **Pre-hooks:** Command sanitization, scope validation, resource limits
- **Post-hooks:** Output validation, audit logging, escalation triggers

**Why Hooks (not runtime permissions):**
- Enforcement at execution boundaries
- Simpler than runtime permission systems
- Auditable decision trail
- Fail-safe (hook failure = operation blocked)

**Boundaries:**
- Does NOT execute business logic
- Does NOT store state
- DOES enforce constraints, log actions

---

### Layer 1: Foundation
| Responsibility | Inputs | Outputs | Communicates With |
|----------------|--------|---------|-------------------|
| Agent identity and capabilities | YAML manifests | Agent definitions, tool permissions | All layers (configuration source) |
| Project isolation | Git submodules, worktrees | Isolated development environments | Version control, file system |

**Agent Manifest Structure:**
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

**Worktree Strategy:**
- **Dynamic creation:** Per task, per agent
- **Outcome-based cleanup:** Success = auto-cleanup, failure = preserve for debugging
- **Isolation:** Prevents merge conflicts during parallel work

**Boundaries:**
- Does NOT execute operations
- Does NOT change at runtime
- DOES define identity, permissions, structure

---

## Data Flow Patterns

### 1. CEO Dispatches Work (Top-Down)

```
CEO (Anti-Gravity)
    │
    ├─ "Implement OAuth2 authentication"
    │
    ▼
Orchestrator (Gemini Pro)
    │
    ├─ Decomposes to: [Backend API, Frontend integration, Docs update]
    ├─ Creates GitHub issues: GH-142, GH-143, GH-144
    ├─ Assigns to workers
    │
    ▼
Worker Agent (Claude via GSD)
    │
    ├─ Reads issue GH-142 from GitHub
    ├─ Executes skill: @/agents/skills/backend-service
    ├─ Uses MCP for file access, terminal
    ├─ Creates PR, updates issue
    │
    ▼
GitHub (Coordination Layer)
    │
    ├─ PR created, issue status updated
    │
    ▼
Orchestrator (Status Aggregation)
    │
    ├─ Detects completion, aggregates results
    │
    ▼
CEO (Mission Control Inbox)
    │
    └─ Receives briefing: "OAuth2 complete, pending review"
```

---

### 2. Worker Reports Results (Bottom-Up)

```
Worker Agent (Claude)
    │
    ├─ Completes task
    ├─ Executes: gh pr create --title "feat: auth" --body "Closes #142"
    ├─ Executes: gh issue close 142 --reason completed
    │
    ▼
GitHub (State Change)
    │
    ├─ PR created, issue closed
    ├─ Triggers webhook/polling by orchestrator
    │
    ▼
Orchestrator (Gemini Flash)
    │
    ├─ Detects state change via gh CLI polling
    ├─ Updates task ledger
    ├─ Aggregates into daily briefing
    │
    ▼
CEO Inbox (Anti-Gravity)
    │
    └─ Status: "GH-142 complete, awaiting merge"
```

---

### 3. Agent-to-Agent Coordination (Horizontal via A2A)

```
Orchestrator A (Project Alpha Lead)
    │
    ├─ Needs design system component from Project Beta
    ├─ Discovers Agent Card for Project Beta's Design Agent
    ├─ Authenticates via A2A protocol
    │
    ▼
A2A Communication (HTTPS + JSON-RPC 2.0)
    │
    ├─ Task: "Export button component library"
    ├─ Message: Specification, version requirements
    │
    ▼
Orchestrator B (Project Beta Lead)
    │
    ├─ Receives task, validates scope
    ├─ Delegates to Design Agent worker
    │
    ▼
Worker Agent (Claude)
    │
    ├─ Generates artifacts (component files)
    ├─ Returns via A2A response
    │
    ▼
Orchestrator A
    │
    ├─ Receives artifacts
    ├─ Dispatches integration to own worker
    │
    └─ Updates GitHub with cross-project reference
```

---

### 4. Trust Enforcement (Hook-Based)

```
Worker Agent
    │
    ├─ Attempts: rm -rf /important/data
    │
    ▼
Pre-Hook (Command Sanitization)
    │
    ├─ Detects destructive operation
    ├─ Validates against agent scope
    ├─ REJECTS (scope violation)
    │
    ▼
Trust Ledger
    │
    ├─ Logs rejection
    ├─ Increments violation counter
    ├─ Triggers escalation if threshold exceeded
    │
    ▼
Orchestrator
    │
    ├─ Receives escalation
    ├─ Notifies CEO via Mission Control
    │
    └─ Awaits human decision
```

---

## Orchestration Patterns (Applied to This Architecture)

### Primary Pattern: Hierarchical Task Decomposition

**Use in system:** CEO provides high-level directive → Orchestrator decomposes → Workers execute

**Why this pattern:**
- Complex, ambiguous problems ("build an AI agency")
- Multi-level planning required
- Top-down delegation matches org structure

**Component mapping:**
- **Root agent:** CEO (human strategic direction)
- **Parent agents:** Gemini orchestrators (task decomposition)
- **Leaf agents:** Claude workers (execution)

**Alternative patterns considered:**
- **Sequential:** Too rigid for dynamic project needs
- **Swarm:** Too complex, coordination overhead excessive
- **Coordinator (flat):** Doesn't scale beyond ~7 agents

---

### Secondary Pattern: Handoff Orchestration

**Use in system:** Orchestrators dynamically route work based on agent expertise

**Why this pattern:**
- Expertise requirements unknown upfront (dynamic task routing)
- Agent specialization varies (backend, frontend, DevOps, etc.)

**Component mapping:**
- **Routing logic:** Orchestrator evaluates task, checks agent manifests
- **Handoff trigger:** Skill/tool mismatch detected
- **Full context transfer:** GitHub issue contains full specification

---

### Tertiary Pattern: Parallel Orchestration

**Use in system:** Sub-agents spawned by workers for concurrent execution

**Why this pattern:**
- Independent subtasks (frontend + backend development)
- Time-sensitive scenarios (parallel PR reviews)

**Component mapping:**
- **Parallel executor:** Worker agent spawns sub-agents
- **Aggregation:** Worker collects sub-agent results
- **Synchronization:** GitHub state convergence

---

## Communication Protocols

### A2A (Agent-to-Agent)

**Components:**
1. **Agent Card (JSON):** Declares capabilities, version, auth requirements
2. **Task:** Work unit with unique ID, lifecycle states
3. **Message:** Communication unit (requests/responses)
4. **Artifact:** Tangible outputs (code, documents, configs)

**Workflow:**
1. **Discovery:** Client agent fetches remote agent card
2. **Authentication:** OAuth 2.0 / API keys
3. **Communication:** HTTPS + JSON-RPC 2.0, async/streaming support

**Use in system:**
- Cross-project orchestrator collaboration
- Agent discovery (find specialists)
- Secure delegation with audit trail

---

### MCP (Model Context Protocol)

**Purpose:** Universal adapter for tools, APIs, data sources

**Use in system:**
- File system access (read/write code)
- Terminal execution (git, npm, docker commands)
- API integration (external services)

**Why critical:**
- Eliminates custom integration code per agent
- Standardizes capability access across Claude/Gemini
- Simplifies agent definitions (declare tools, MCP handles implementation)

---

### GitHub gh CLI

**Purpose:** Bridge between agents and coordination layer

**Use in system:**
```bash
# Orchestrator assigns work
gh issue edit 142 --add-assignee "claude-worker-01" --project-status "In Progress"

# Worker completes task
gh pr create --title "feat: auth module" --body "Closes #142"
gh issue close 142 --reason completed

# Orchestrator aggregates status
gh issue list --assignee "@me" --state open --json title,number,status
```

**Why gh CLI (not REST API directly):**
- Simpler for agents (natural language → CLI easier than API payloads)
- Built-in retry/error handling
- Human-auditable commands (exactly what human would run)

---

## Patterns to Follow

### Pattern 1: External State Management

**What:** Never store authoritative state in agent memory/databases. Always use external source of truth (GitHub).

**When:** Any multi-agent system requiring coordination, auditability, recovery

**Why:**
- **Agents are disposable:** Can restart/replace without losing state
- **Humans can intervene:** Direct GitHub access for course correction
- **Audit trail:** Every state change logged in git history
- **Recovery:** System state reconstructable from GitHub even if all agents fail

**Example:**
```typescript
// GOOD: GitHub as source of truth
async function getTaskStatus(taskId: string) {
  const issue = await gh.issue.get(taskId);
  return issue.state; // "open", "in_progress", "completed"
}

// BAD: Agent memory as source of truth
const taskStatus = new Map<string, string>();
function getTaskStatus(taskId: string) {
  return taskStatus.get(taskId); // Lost on agent restart
}
```

---

### Pattern 2: Hook-Based Trust Enforcement

**What:** Enforce constraints at execution boundaries (pre/post hooks), not runtime permission checks.

**When:** Need guardrails without complex runtime permission systems

**Why:**
- **Simpler:** Hooks intercept at command execution, not scattered throughout code
- **Fail-safe:** Hook failure = operation blocked automatically
- **Auditable:** Every enforcement decision logged
- **Declarative:** Define rules in hook configs, not application logic

**Example:**
```yaml
# Pre-hook: Command sanitization
pre_hooks:
  - name: prevent_destructive_ops
    trigger: command_contains("rm -rf")
    action: reject
    log: "Blocked destructive operation"

# Post-hook: Output validation
post_hooks:
  - name: validate_pr_created
    trigger: command_matches("gh pr create")
    validate: github_has_new_pr()
    on_failure: escalate_to_orchestrator
```

---

### Pattern 3: Declarative Agent Manifests

**What:** Define agent identity, capabilities, and constraints in YAML, not code.

**When:** Need agent spawning, discovery, and permission management

**Why:**
- **CEO invokes intent, agents encode implementation:** Human says "review this PR", manifest defines which agent has review skills
- **Version control:** Agent definitions tracked in git
- **Discovery:** Orchestrators query manifests to find specialists
- **Model selection at design time:** Flash for speed, Pro for complexity, encoded in manifest

**Example:**
```yaml
# Backend specialist
name: backend-api-developer
model: claude-sonnet-4.5
tools:
  - file_system
  - terminal
  - gh_cli
skills:
  - "@/agents/skills/api-development"
  - "@/agents/skills/database-migration"
constraints:
  scope: "src/backend/**"
  max_file_size_mb: 10
triggers:
  - label: "backend"
  - skill: "api-development"
```

---

### Pattern 4: Outcome-Based Worktree Cleanup

**What:** Create git worktrees dynamically per task. Cleanup based on outcome (success = remove, failure = preserve).

**When:** Parallel development by multiple agents on same repo

**Why:**
- **Isolation:** Prevents merge conflicts during concurrent work
- **Debugging:** Failed attempts preserved for human investigation
- **Efficiency:** Successful work auto-cleaned, no manual maintenance

**Example:**
```bash
# Worker creates worktree for task
git worktree add ../project-feature-gh-142 feature/auth-module

# On success (PR merged)
git worktree remove ../project-feature-gh-142

# On failure (tests failed)
# Worktree preserved, orchestrator escalates to human
echo "Worktree preserved at ../project-feature-gh-142 for debugging"
```

---

### Pattern 5: Layered Observability

**What:** Each layer emits structured logs, aggregated bottom-up for CEO visibility.

**When:** Need to debug multi-agent coordination without drowning in logs

**Why:**
- **Layer 1-3:** Detailed execution logs (for debugging specific operations)
- **Layer 4:** Task-level summaries (worker progress)
- **Layer 6:** Project-level aggregations (orchestrator briefings)
- **Layer 7:** Strategic summaries (CEO daily briefing)

**Example:**
```typescript
// Layer 4 (Worker): Detailed execution
logger.debug("Executing skill: backend-service", { issue: "GH-142", step: 3 });

// Layer 6 (Orchestrator): Task summary
logger.info("Task GH-142 completed", {
  duration: "45m",
  worker: "claude-worker-01",
  outcome: "PR created"
});

// Layer 7 (CEO Inbox): Daily briefing
logger.summary("OAuth2 implementation complete", {
  issues_closed: 3,
  prs_merged: 2,
  blockers: 0
});
```

---

## Anti-Patterns to Avoid

### Anti-Pattern 1: The "God Agent"

**What:** Single agent tries to handle too many distinct tasks

**Why bad:**
- Context windows explode (too much context per request)
- Tool confusion (too many tools, agent hallucinates which to use)
- Hallucination rate increases (diluted attention)

**Consequences:**
- Unpredictable behavior
- Difficult to debug (unclear which "mode" agent is in)
- Can't scale (single bottleneck)

**Instead:** Create specialized agents with narrow, well-defined responsibilities. Use orchestrators for routing.

**Detection:**
- Agent manifest has > 10 tools
- Agent handles > 5 distinct workflow types
- Error rate increases as task diversity grows

---

### Anti-Pattern 2: Agents Managing State Directly

**What:** Storing authoritative state in agent memory, vector databases, or custom state managers

**Why bad:**
- State lost on agent restart/failure
- No human visibility (can't inspect/correct)
- No audit trail (state changes invisible)
- Multi-agent race conditions (conflicting updates)

**Consequences:**
- System unrecoverable after failures
- Debugging impossible (state opaque)
- Trust violations undetectable

**Instead:** Use GitHub as single source of truth. Agents read/write via gh CLI.

**Detection:**
- Agent code contains in-memory maps/caches for task state
- Database tables for "current work items"
- No GitHub issue for an "in-progress" task

---

### Anti-Pattern 3: Premature Multi-Agent Complexity

**What:** Building 10-agent system before validating single agent can't handle task

**Why bad:**
- Coordination overhead outweighs benefits (< 7 agents often unnecessary)
- Debugging nightmares (which agent caused the issue?)
- Wasted development time (simpler solution exists)

**Consequences:**
- Higher operational costs (more models, more compute)
- Increased latency (handoff overhead)
- Brittle system (more failure points)

**Instead:** Start with single agent. Add agents only when clear specialization benefit or parallelization need exists.

**Detection:**
- System has > 7 agents without hierarchical structure
- Agents frequently hand off to each other for same task
- Removing an agent doesn't degrade capability

---

### Anti-Pattern 4: Circular Agent Dependencies

**What:** Agent A delegates to Agent B, which delegates back to Agent A

**Why bad:**
- Infinite loops (no exit condition)
- Exponential context growth (each handoff adds context)
- Token costs explode (repeated re-processing)

**Consequences:**
- System hangs (timeouts required)
- Unpredictable behavior (loop exit undefined)
- Resource exhaustion (memory/token limits hit)

**Instead:** Enforce directed acyclic graph (DAG) for agent delegation. Orchestrators delegate down, workers report up.

**Detection:**
- Same task ID appears multiple times in agent call stack
- Context window warnings increase over time
- Timeout errors on complex tasks

---

### Anti-Pattern 5: Synchronous Orchestrator Blocking

**What:** Orchestrator waits synchronously for worker completion before routing next task

**Why bad:**
- Serializes parallel work (eliminates benefit of multi-agent)
- Orchestrator becomes bottleneck (idle during worker execution)
- Inefficient resource use (workers idle waiting for dispatch)

**Consequences:**
- System throughput limited by orchestrator blocking time
- Parallel tasks run sequentially (defeats purpose)
- Poor scalability (adding workers doesn't help)

**Instead:** Use asynchronous task dispatch. Orchestrator delegates via GitHub issue assignment, workers report completion via PR/issue updates. Orchestrator polls/webhooks for state changes.

**Detection:**
- Orchestrator CPU usage low during worker execution
- Tasks with no dependencies still run sequentially
- Adding workers doesn't improve throughput

---

### Anti-Pattern 6: Unbounded Context Accumulation

**What:** Passing entire conversation histories between agents without summarization

**Why bad:**
- Context windows overflow (hit model limits)
- Agents lose focus (buried in irrelevant history)
- Token costs explode (paying to re-process old context)

**Consequences:**
- Quality degrades (agent confused by noise)
- Latency increases (more tokens to process)
- Errors increase (truncation cuts important context)

**Instead:** Summarize context at handoff boundaries. GitHub issues contain only relevant specification, not full conversation history.

**Detection:**
- Context length warnings in logs
- Agent responses reference old, irrelevant information
- Token costs increase superlinearly with task count

---

### Anti-Pattern 7: Missing Observability

**What:** Deploying multi-agent system without logging, tracing, or monitoring

**Why bad:**
- Debugging becomes guesswork (can't see what agents did)
- Cost attribution impossible (don't know which agent costs what)
- Performance issues undetectable (no metrics)

**Consequences:**
- Incident response slow (no visibility into failures)
- Cost overruns unexpected (no early warning)
- Root cause analysis takes hours (manual log diving)

**Instead:** Implement structured logging at every layer, distributed tracing for multi-agent workflows, metrics on cost/latency/success rate.

**Detection:**
- Can't answer "which agent failed and why?" in < 5 minutes
- Monthly cost surprises (no budget tracking)
- Performance regressions discovered by users, not monitoring

---

## Scalability Considerations

### At 1-5 Projects (MVP)

| Concern | Approach |
|---------|----------|
| Orchestrator load | Single Gemini orchestrator handles all projects |
| Worker count | 3-5 Claude workers (generalists) |
| GitHub rate limits | Standard gh CLI, no optimization needed |
| State size | Issues/PRs in single repo per project |
| Cost | Optimize for learning, not cost efficiency |
| Monitoring | Manual review of Mission Control briefings |

**Build focus:** Prove the loop (CEO → Orchestrator → Worker → GitHub → CEO). Validate workflows, not scale.

---

### At 10-50 Projects (Growth)

| Concern | Approach |
|---------|----------|
| Orchestrator load | One orchestrator per project cluster (e.g., frontend, backend, data) |
| Worker count | 10-20 workers, introduce specialists (API dev, UI dev, DevOps) |
| GitHub rate limits | Caching layer (redis) for issue/PR metadata, reduce gh CLI calls |
| State size | Submodules per project, worktrees cleaned aggressively |
| Cost | Migrate simple tasks to Flash, reserve Pro for complex decomposition |
| Monitoring | Automated daily briefings with anomaly detection |

**Build focus:** Specialization (agent roles), efficiency (reduce redundant gh calls), automation (briefing generation).

---

### At 100+ Projects (Scale)

| Concern | Approach |
|---------|----------|
| Orchestrator load | Hierarchical orchestrators (meta-orchestrator routes to project orchestrators) |
| Worker count | 50+ workers, fully specialized roles, sub-agent spawning for parallelization |
| GitHub rate limits | GraphQL API for bulk queries, webhooks instead of polling, multi-org structure |
| State size | Separate GitHub orgs per domain, aggressive worktree/branch cleanup |
| Cost | Model routing (Flash → Pro → Deep Think escalation), prompt caching, batch operations |
| Monitoring | Real-time dashboards, SLO tracking, automated escalation rules |

**Build focus:** Meta-orchestration (orchestrators managing orchestrators), cost optimization (minimize expensive model usage), reliability (SLO enforcement, circuit breakers).

---

## Build Order & Dependencies

Based on component boundaries and data flow, recommended build order:

### Phase 1: Foundation (Weeks 1-2)
**Build:** Layer 1 (Agent definitions), Layer 5 (GitHub setup), Layer 3 (MCP integration)

**Why first:**
- No higher layers work without foundation
- GitHub must exist before agents can read/write
- MCP required for any tool access

**Dependencies:** None (greenfield)

**Validation:** Can create GitHub issue manually, read it via gh CLI, MCP can access file system

---

### Phase 2: Single Worker (Weeks 3-4)
**Build:** Layer 4 (One Claude worker), basic GSD command execution

**Why second:**
- Proves agent can execute and report
- Establishes worker → GitHub flow
- No orchestration needed yet (human acts as orchestrator)

**Dependencies:** Phase 1 complete

**Validation:** Human creates GitHub issue, Claude worker picks it up, creates PR, updates issue

---

### Phase 3: Trust Guardrails (Week 5)
**Build:** Layer 2 (Pre/post hooks for command sanitization, output validation)

**Why third:**
- Before orchestrators exist, establish trust boundaries
- Easier to test with single worker
- Prevents runaway agents once orchestration begins

**Dependencies:** Phase 2 complete (need worker to test hooks against)

**Validation:** Worker attempts forbidden operation, hook blocks it, audit log created

---

### Phase 4: Single Orchestrator (Weeks 6-7)
**Build:** Layer 6 (One Gemini orchestrator), dispatch mechanism (claude-code invocation)

**Why fourth:**
- Now have trusted workers, can delegate to them
- Proves orchestrator → worker → GitHub loop
- Establishes A2A protocol basics

**Dependencies:** Phase 3 complete (workers must be trusted before orchestration)

**Validation:** Orchestrator receives task, decomposes to subtasks, assigns to worker via GitHub, worker completes, orchestrator aggregates status

---

### Phase 5: CEO Interface (Week 8)
**Build:** Layer 7 (Mission Control integration, daily briefing generation)

**Why fifth:**
- All automation complete, now surface to human
- Orchestrator must exist to generate briefings
- Completes the full loop

**Dependencies:** Phase 4 complete (orchestrator must aggregate status)

**Validation:** CEO receives daily briefing in Anti-Gravity inbox, issues directive, sees result next day

---

### Phase 6: Specialization (Weeks 9-12)
**Build:** Multiple worker types (backend, frontend, DevOps), agent manifest-based routing

**Why sixth:**
- Foundation proven, now optimize via specialization
- Orchestrator logic complex (needs working baseline first)

**Dependencies:** Phase 5 complete (basic loop working)

**Validation:** Task requiring frontend work routes to frontend specialist, not generalist

---

### Phase 7: Parallelization (Weeks 13-16)
**Build:** Sub-agent spawning, parallel orchestration pattern, worktree management

**Why seventh:**
- Serialization proven, now add concurrency
- Complex (requires mature orchestrator)

**Dependencies:** Phase 6 complete (need specialists to parallelize)

**Validation:** Single task spawns 3 sub-agents, all work concurrently, results converge in GitHub

---

### Phase 8: Scale & Monitoring (Weeks 17+)
**Build:** Hierarchical orchestrators, observability layers, cost optimization

**Why last:**
- Only needed at scale
- Requires all patterns working first

**Dependencies:** Phase 7 complete (full system operational)

**Validation:** 10+ concurrent projects managed without human intervention, < 5% error rate, cost within budget

---

## Key Architectural Decisions for Roadmap

### Decision 1: Layered vs Flat Architecture
**Recommendation:** Layered (7 layers as defined)

**Rationale:**
- Clear separation of concerns (CEO strategy, orchestrator coordination, worker execution)
- Easier to test (mock layers independently)
- Scalable (can replace layer implementation without affecting others)

**Roadmap impact:** Early phases focus on lower layers (foundation first), higher layers later

---

### Decision 2: GitHub as External State vs Internal State Management
**Recommendation:** GitHub as single source of truth

**Rationale:**
- Auditability (git history = audit log)
- Human accessibility (can intervene directly)
- Recovery (state persists even if all agents fail)
- Standard tooling (gh CLI, git, webhooks)

**Roadmap impact:** Phase 1 must establish GitHub patterns before agents built

---

### Decision 3: Hook-Based vs Runtime Permission System
**Recommendation:** Hook-based guardrails

**Rationale:**
- Simpler implementation (intercept at boundaries, not scattered checks)
- Fail-safe (hook failure = operation blocked)
- Auditable (every enforcement decision logged)

**Roadmap impact:** Phase 3 builds hooks before orchestration (prevents runaway agents)

---

### Decision 4: Sequential vs Parallel Build Order
**Recommendation:** Sequential build of layers, then parallelize within layers

**Rationale:**
- Foundation must exist first (can't skip layers)
- Parallelization within phase (e.g., multiple workers built concurrently in Phase 6)
- De-risks integration (each phase validates previous)

**Roadmap impact:** Phases 1-5 strictly sequential, Phases 6-8 allow parallel work

---

### Decision 5: Single Orchestrator vs Distributed Orchestrators
**Recommendation:** Start single, evolve to hierarchical at scale

**Rationale:**
- Single orchestrator simpler to debug (Phase 4)
- Hierarchical needed at 100+ projects (Phase 8)
- Premature distribution = unnecessary complexity

**Roadmap impact:** Phase 4 builds one orchestrator, Phase 8 adds meta-orchestrator if needed

---

## Sources

**Official Documentation (HIGH confidence):**
- [Google Cloud: Multi-Agent Design Patterns](https://docs.cloud.google.com/architecture/choose-design-pattern-agentic-ai-system) - 8 patterns, component boundaries
- [Microsoft Azure: AI Agent Orchestration Patterns](https://learn.microsoft.com/en-us/azure/architecture/ai-ml/guide/ai-agent-design-patterns) - 5 orchestration patterns, data flows
- [IBM: Agent2Agent (A2A) Protocol](https://www.ibm.com/think/topics/agent2agent-protocol) - Protocol components, communication structure

**Industry Research (MEDIUM-HIGH confidence):**
- [InfoQ: Google's Eight Essential Multi-Agent Design Patterns](https://www.infoq.com/news/2026/01/multi-agent-design-patterns/) - Pattern analysis
- [AIMultiple: The 7 Layers of Agentic AI Stack in 2026](https://research.aimultiple.com/agentic-ai-stack/) - Layer boundaries, build dependencies
- [Ruh AI: AI Agent Protocols 2026 Complete Guide](https://www.ruh.ai/blogs/ai-agent-protocols-2026-complete-guide) - MCP, A2A, protocol comparison
- [OneReach AI: MCP vs A2A Protocols](https://onereach.ai/blog/guide-choosing-mcp-vs-a2a-protocols/) - Protocol use cases

**Architecture Patterns (MEDIUM confidence):**
- [CrewAI Blog: Agentic Systems Architecture](https://blog.crewai.com/agentic-systems-with-crewai/) - System design patterns
- [DataCamp: CrewAI vs LangGraph vs AutoGen](https://www.datacamp.com/tutorial/crewai-vs-langgraph-vs-autogen) - Framework comparison
- [Cloud Geometry: Multi-Agent Systems Architecture](https://www.cloudgeometry.com/blog/from-solo-act-to-orchestra-why-multi-agent-systems-demand-real-architecture) - Anti-patterns

**Anti-Patterns & Pitfalls (MEDIUM confidence):**
- [DEV Community: Multi-Agent Systems Complete 2026 Guide](https://dev.to/eira-wexford/how-to-build-multi-agent-systems-complete-2026-guide-1io6) - Common mistakes
- [Composio: Why AI Agent Pilots Fail 2026](https://composio.dev/blog/why-ai-agent-pilots-fail-2026-integration-roadmap) - Integration traps
- [VentureBeat: More Agents Isn't Reliable Path](https://venturebeat.com/orchestration/research-shows-more-agents-isnt-a-reliable-path-to-better-enterprise-ai) - Efficiency research

**Security & Trust (MEDIUM confidence):**
- [Medium: AI Agent Identity & Zero-Trust 2026](https://medium.com/@raktims2210/ai-agent-identity-zero-trust-the-2026-playbook-for-securing-autonomous-systems-in-banks-e545d077fdff) - Zero-trust architecture
- [DEV: Zero Trust Agentic AI Architecture](https://dev.to/dev_gupta_6707a7dccdfd729/zero-trust-agentic-ai-designing-autonomy-behind-guardrails-c2l) - Guardrail design
- [Microsoft Security: New Era of Agents Posture](https://www.microsoft.com/en-us/security/blog/2026/01/21/new-era-of-agents-new-era-of-posture/) - Security considerations
