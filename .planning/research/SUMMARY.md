# Research Summary: Manifest Automations AI Agency

**Domain:** Multi-Agent AI Orchestration / AI-Powered Development Agency
**Researched:** 2026-01-26
**Overall Confidence:** HIGH

---

## Executive Summary

The 2026 multi-agent orchestration ecosystem has matured with standardized protocols (MCP, A2A), production-ready frameworks (LangGraph, Google ADK), and enterprise infrastructure. For Manifest Automations, we recommend:

- **Hybrid Python/TypeScript stack** — Python for Gemini orchestration (LangGraph + ADK), TypeScript for GitHub integration (Octokit)
- **7-layer architecture** — CEO → Orchestrators → GitHub → Workers → Tools → Trust → Foundation
- **GitHub as single source of truth** — Issues, Projects, PRs for coordination (no proprietary state)
- **Hook-based trust enforcement** — Pre/post hooks at execution boundaries

---

## Key Findings

### Stack Recommendations

| Layer | Technology | Why |
|-------|------------|-----|
| **Orchestration** | Python + LangGraph + Google ADK | Industry standard, fastest framework, YAML-first agent definitions |
| **GitHub Integration** | TypeScript + Octokit | Official SDK, type safety, active maintenance |
| **State Management** | Redis Stack | Sub-millisecond access, vector search, pub/sub, LangGraph checkpointer |
| **Trust Enforcement** | pre-commit + GitHub Actions | Multi-language hooks locally, server-side enforcement in CI |
| **Observability** | LangSmith + OpenTelemetry | Zero overhead tracing, native LangGraph integration |
| **Agent Protocol** | MCP + A2A | MCP for tools, A2A for agent-to-agent communication |

### Table Stakes Features

1. Task decomposition & delegation
2. Multi-agent coordination
3. Agent-to-agent communication (MCP, A2A)
4. Tool/API integration
5. State management & persistence
6. Human-in-the-loop (47% of buyers require)
7. Error handling & recovery
8. Observability & logging (65% cite as primary challenge)
9. Security & access control
10. Workflow orchestration

### Differentiators (Competitive Advantage)

1. **Git-native operations** — Worktrees for parallel development
2. **Declarative agent definitions** — YAML manifests (agent-as-config)
3. **Earned autonomy / trust levels** — Progressive trust based on performance
4. **GitHub-as-coordination-layer** — Auditable, human-readable, no vendor lock-in
5. **Dynamic worktree management** — Outcome-based cleanup (success = remove, failure = preserve)
6. **Hook-based trust enforcement** — Pre/post hooks instead of runtime permissions
7. **Cross-surface terminal control** — Gemini dispatching to Claude via CLI

### Architecture: 7-Layer Model

```
Layer 7: CEO Interface (Mission Control)
Layer 6: Orchestration Agents (Gemini Flash/Pro/Deep Think)
Layer 5: Coordination Layer (GitHub as Source of Truth)
Layer 4: Worker Agents (Claude via GSD)
Layer 3: Tool Integration (MCP Protocol)
Layer 2: Trust & Guardrails (Hook System)
Layer 1: Foundation (Agent Definitions + Infrastructure)
```

**Data Flow:**
- Top-down: Human intent → Orchestrators → Workers → Tools
- Bottom-up: Results → GitHub → Orchestrators → Mission Control
- Horizontal: A2A for agent-to-agent, MCP for agent-to-tool

---

## Critical Pitfalls to Avoid

### Architectural

| Pitfall | Impact | Prevention |
|---------|--------|------------|
| **God Agent** | Hallucinations, debugging nightmare | Specialize from day one |
| **Context Overflow** | 40-60% budget overrun | Summarize at handoffs, set limits |
| **Shared Mutable State** | Race conditions, lost updates | Claim-based assignment, file ownership |
| **No Observability** | Debugging impossible | OpenTelemetry from Phase 1 |

### Operational

| Pitfall | Impact | Prevention |
|---------|--------|------------|
| **Weak Trust Boundaries** | Security breaches, blast radius | Pre/post hooks, sandboxing |
| **Deadlocks/Infinite Loops** | System hangs, cost explosion | Timeouts, circuit breakers |
| **Cost Runaway** | 2-5x budget, project cancellation | FinOps controls, alerts, semantic caching |

### Phase-Specific Warnings

| Phase | Watch Out For |
|-------|---------------|
| Phase 1 | God Agent, no observability, weak trust |
| Phase 2 | Missing coordinator, poor handoff design |
| Phase 3 | Shared state, deadlocks, worktree chaos |
| Phase 4 | Cost explosion, observability gaps |
| Phase 5 | Rate limits, GitHub API limits |

---

## Build Order Recommendation

### Phase 1: Foundation (Weeks 1-2)
- Agent definitions (YAML manifests)
- GitHub setup (issues, projects, PRs)
- MCP integration (file system, terminal)
- Observability setup (LangSmith)

### Phase 2: Single Worker (Weeks 3-4)
- One Claude worker with GSD
- Worker → GitHub flow
- Human acts as orchestrator

### Phase 3: Trust Guardrails (Week 5)
- Pre-hooks (command sanitization)
- Post-hooks (output validation)
- Audit logging

### Phase 4: Single Orchestrator (Weeks 6-7)
- One Gemini orchestrator
- Dispatch mechanism (claude-code CLI)
- Status aggregation

### Phase 5: CEO Interface (Week 8)
- Mission Control integration
- Daily briefing generation
- Full loop complete

### Phase 6+: Specialization & Scale
- Multiple worker types
- Parallel orchestration
- Hierarchical orchestrators

---

## Anti-Features (Don't Build)

1. **Custom dashboards** — Use Anti-Gravity Mission Control
2. **Proprietary state management** — Use GitHub
3. **Runtime permission systems** — Use hooks
4. **Over-engineered multi-agent** — Start simple, add agents only when proven necessary
5. **Agentic top-level orchestration** — Keep top-level deterministic
6. **Unstructured memory sharing** — Summarize at handoffs
7. **Overlapping agent responsibilities** — Clear boundaries

---

## Success Criteria

The system MUST have:

1. Specialized agents (not god agents)
2. Observability from day one
3. Trust boundaries with hooks
4. Explicit context handoff protocols
5. Coordinator pattern
6. State ownership boundaries
7. Cost instrumentation and alerts
8. Deadlock and timeout logic
9. Worktree lifecycle management
10. Framework choice aligned with team

---

## Confidence Assessment

| Area | Confidence | Reason |
|------|------------|--------|
| Stack (Python + LangGraph) | HIGH | Industry standard, benchmarks prove performance |
| Architecture (7-layer) | HIGH | Based on Google/Microsoft/IBM patterns |
| GitHub as coordination | MEDIUM-HIGH | Proven pattern, some rate limit concerns |
| Hook-based trust | HIGH | Enterprise security guidelines |
| Build order | HIGH | Dependencies clearly mapped |
| Pitfalls | HIGH | Based on 2026 production post-mortems |

---

*Synthesized from: STACK.md, FEATURES.md, ARCHITECTURE.md, PITFALLS.md*
*Last updated: 2026-01-26*
