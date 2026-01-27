# Technology Stack

**Project:** Manifest Automations AI Agency
**Researched:** 2026-01-26
**Overall Confidence:** MEDIUM-HIGH

## Executive Summary

The 2026 multi-agent orchestration ecosystem has matured significantly with standardized protocols (MCP, A2A), production-ready frameworks (LangGraph, Google ADK), and enterprise infrastructure. For this project, we recommend a **hybrid Python/TypeScript stack** with Python for orchestrators (Gemini + LangGraph) and TypeScript for GitHub integration and worker coordination. This reflects the current industry pattern where Python dominates AI agent frameworks while TypeScript excels at platform integration.

## Recommended Stack

### Core Orchestration Layer

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| **Python** | 3.11+ | Gemini orchestrator runtime | Industry standard for AI agent frameworks. 3.11+ required for performance improvements and modern async features. | HIGH |
| **Google ADK (Python)** | latest | Declarative agent config via YAML | Official Google framework for agent orchestration, supports YAML-based agent definitions matching our manifest approach. Powers Google's production agents (Agentspace, GCES). | HIGH |
| **LangGraph** | 1.0.7+ | Multi-agent workflow orchestration | Fastest framework with lowest latency (benchmark verified). Graph-based state management ideal for complex orchestration. Python version actively maintained (v1.0.7 released Jan 22, 2026). | HIGH |
| **Gemini API** | Gemini 3 Pro | Agentic orchestration model | Gemini 3 Pro Preview designed specifically for agentic orchestration with thinking_level parameter, stateful tool use via Thought Signatures. Native Google ecosystem integration. | HIGH |

**Rationale:** Python + LangGraph + ADK is the 2026 standard for multi-agent orchestration. LangGraph benchmarks show it's the fastest framework with lowest latency, and Google ADK's YAML-first approach aligns perfectly with our declarative agent manifests. Gemini 3 Pro's agentic capabilities (thinking_level, Thought Signatures) are purpose-built for orchestration workloads.

### GitHub Coordination Layer

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| **Node.js** | 20 LTS | GitHub integration runtime | LTS stability for production systems. Required for Octokit. | HIGH |
| **TypeScript** | 5.x | Type-safe GitHub automation | Type safety critical for multi-agent coordination. TypeScript surpassed Python in GitHub's 2025 language report, indicating ecosystem momentum. | HIGH |
| **Octokit.js** | 5.0.5+ | GitHub API client | Official GitHub SDK, actively maintained (updated Jan 24, 2026). All-batteries-included SDK integrating REST, GraphQL, webhooks, and OAuth. | HIGH |
| **@octokit/webhooks** | latest | GitHub event listening | Required for reactive agent coordination based on GitHub events (issues, PRs, comments). | MEDIUM |

**Rationale:** GitHub is our single source of truth. Octokit.js is the official GitHub SDK with active maintenance and TypeScript-first design. Separating orchestration (Python) from platform integration (TypeScript) follows the 2026 pattern of using the right language for each domain.

### State Management & Memory

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| **Redis Stack** | 7.4+ | Agent state, memory, coordination | Sub-millisecond hot state access, native vector search for context retrieval, pub/sub for multi-agent messaging. LangGraph checkpointer integration. Industry standard for production agent systems. | HIGH |
| **LangGraph Checkpointer** | built-in | Workflow state persistence | Native integration with Redis for state snapshots. Enables graceful failover and recovery. | HIGH |

**Rationale:** Redis is the 2026 standard for AI agent state management. Every production agent framework guide mentions Redis for checkpointing, memory, and coordination. LangGraph has native Redis checkpointer support. Redis Streams + Pub/Sub handle multi-agent messaging patterns.

### Trust Enforcement & Quality Gates

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| **pre-commit** | 4.0+ | Local hook framework | Multi-language pre-commit hooks for trust enforcement. Standard tool for preventing secrets, enforcing standards before commits reach Git. | HIGH |
| **Husky** | 9.x | Git hooks (TypeScript projects) | TypeScript ecosystem standard for Git hooks. Simpler for Node.js projects than pre-commit. | MEDIUM |
| **GitHub Actions** | N/A | CI/CD and pre-receive enforcement | Server-side enforcement point. Pre-receive hooks that apply universally regardless of local hook bypass. Required for trust level validation. | HIGH |

**Rationale:** Layered enforcement: pre-commit catches issues locally (fast feedback), GitHub Actions provides server-side enforcement (can't be bypassed). Pre-commit is language-agnostic and runs checks before code enters Git history. Critical for trust system where agents at different levels have different permissions.

### Git Worktree Management

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| **git worktree** | Git 2.43+ | Parallel agent isolation | Native Git feature for multiple working directories sharing history. Each Claude worker gets isolated worktree preventing context pollution. Emerged as 2026 standard pattern for parallel AI agents. | HIGH |
| **worktrunk** | latest (Jan 2026) | Worktree orchestration CLI | Purpose-built CLI for managing worktrees with AI agents. Simplifies create/cleanup/status for multiple parallel workers. Released Jan 2026 specifically for this use case. | MEDIUM |

**Rationale:** Git worktrees solve the "multiple agents, same repo" problem elegantly. Each agent works in isolation, no stashing, no context switching. Cursor's Parallel Agents and other tools proved this pattern in production. Worktree + submodules gives us project isolation with shared tooling.

### Agent Configuration & Manifests

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| **YAML** | 1.2 | Agent manifest format | Industry standard for declarative config. Google ADK, Microsoft Agent Framework, and lettactl all use YAML for agent definitions. Human-readable, git-friendly, tooling-rich. | HIGH |
| **Pydantic** | 2.x | Manifest validation (Python) | Type-safe YAML parsing with validation. Standard for Python config validation. | HIGH |
| **Zod** | 3.x | Manifest validation (TypeScript) | Type-safe schema validation for TypeScript. Standard in TS ecosystem. | HIGH |

**Rationale:** YAML is the 2026 standard for agent configuration across Google ADK, Microsoft Agent Framework, and lettactl. Declarative, version-controlled, and human-readable. Pydantic and Zod provide runtime validation ensuring manifests are well-formed before agents start.

### Observability & Monitoring

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| **LangSmith** | latest | Agent observability | Zero-overhead agent tracing (0% in benchmarks). Native LangGraph integration, real-time monitoring, automatic trace capture. Led Coinbase to reduce build times from 12 weeks to <1 week. Now available in AWS Marketplace for enterprise deployment. | HIGH |
| **OpenTelemetry** | 1.x | Standard telemetry | Vendor-neutral observability. Microsoft + Outshift introducing multi-agent semantic conventions to OTel in 2026. LangSmith supports OTel export for unified stack. | MEDIUM |

**Rationale:** LangSmith is purpose-built for AI agents with zero overhead and native LangGraph support. OpenTelemetry provides vendor neutrality and emerging multi-agent standards. Combined approach: LangSmith for development/debugging, OTel for production observability integration.

### Model Context Protocol (MCP)

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| **MCP SDK** | latest | Standardized agent communication | Open standard from Anthropic for agent-to-tool and agent-to-agent communication. Supported by OpenAI, Google A2A protocol announced as MCP complement. 1000+ community MCP servers exist. 2026 multimodal support (images, video, audio). | HIGH |
| **MCP Servers** | varies | Reusable agent tools | Community ecosystem of pre-built MCP servers for common integrations (databases, APIs, file systems). Prevents rebuilding integrations. | MEDIUM |

**Rationale:** MCP is becoming the HTTP of agent systems. OpenAI announced support across all products (including ChatGPT), Google launched Agent2Agent (A2A) as MCP complement. Standardization layer prevents vendor lock-in and enables tool reuse across Claude/Gemini/OpenAI agents. 1000+ servers represent established ecosystem.

### Container Orchestration & Development

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| **Docker** | 27+ | Agent containerization | Docker Compose 2.38.1+ added native agent support. Define agents, models, MCP tools in compose.yaml. Docker Offload (beta) for remote GPU compute. | HIGH |
| **Docker Compose** | 2.38.1+ | Multi-agent local dev | Official support for agentic applications (released 2025-2026). Single compose.yaml defines models, agents, MCP tools. Integrates with LangGraph, ADK, Vercel AI SDK. | HIGH |

**Rationale:** Docker brought native agent support to Compose in 2026, making multi-agent local development trivial. Docker Offload enables transparent GPU compute offload. Compose files are declarative, version-controlled, and shareable. Eliminates "works on my machine" for multi-agent systems.

## Alternatives Considered

| Category | Recommended | Alternative | Why Not | Confidence |
|----------|-------------|-------------|---------|------------|
| **Orchestration Framework** | LangGraph + ADK | CrewAI | CrewAI excellent for role-based teams but less flexible for complex state management and conditional logic. LangGraph's graph-based approach provides more control for our orchestrator->worker pattern. | HIGH |
| **Orchestration Framework** | LangGraph + ADK | AutoGen | AutoGen frames everything as conversations. Less suitable for hierarchical orchestration where Gemini coordinates Claude workers. LangGraph's explicit state graphs better match our needs. | HIGH |
| **Orchestration Framework** | LangGraph + ADK | OpenAI Swarm | Lightweight but too simple. Lacks production features (state management, observability, checkpointing). Good for demos, not production multi-agent systems. | HIGH |
| **State Management** | Redis | PostgreSQL | Postgres can store state but lacks sub-millisecond access, vector search, and pub/sub patterns. Redis purpose-built for hot state + agent coordination. | HIGH |
| **State Management** | Redis | SQLite (LangGraph default) | SQLite fine for single-agent dev but doesn't scale to multi-agent coordination. No pub/sub, no distributed access. | HIGH |
| **Git Hooks** | pre-commit | Custom scripts | Pre-commit provides multi-language hook management, auto-updates, and ecosystem. Custom scripts lack standardization and maintenance burden. | HIGH |
| **Observability** | LangSmith | Langfuse | Langfuse good open-source option but LangSmith's zero overhead (0% in benchmarks) and native LangGraph integration make it clear choice. Can switch later if needed. | MEDIUM |
| **Observability** | LangSmith | AgentOps | AgentOps emerging but less mature. LangSmith has enterprise features (AWS Marketplace, VPC deployment) and proven track record (Coinbase use case). | MEDIUM |
| **Language (Orchestration)** | Python | TypeScript | Python dominates AI agent frameworks. LangGraph Python more mature than JS version (1.0.7 vs 1.1.0 but Python has longer track record). ADK has better Python support. | HIGH |
| **Language (GitHub)** | TypeScript | Python | Octokit.js is official GitHub SDK. TypeScript provides better type safety for API integration. Python SDK (PyGithub) less actively maintained. | MEDIUM |
| **Manifest Format** | YAML | JSON | YAML more human-readable, better for git diffs, supports comments. JSON is valid YAML subset so we can parse both if needed. | MEDIUM |

## Supporting Libraries

### Python (Orchestrator)

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| **google-generativeai** | latest | Gemini API client | Required for Gemini orchestrator communication |
| **langchain-google-genai** | latest | LangChain + Gemini integration | Connecting Gemini models to LangGraph workflows |
| **redis-py** | 5.x | Redis Python client | State management, checkpointing |
| **pydantic** | 2.x | Data validation | Agent manifest validation, config parsing |
| **pyyaml** | 6.x | YAML parsing | Reading agent manifest files |
| **httpx** | 0.27+ | Async HTTP client | Async API calls (better than requests for agents) |
| **structlog** | 24.x | Structured logging | JSON logs for observability integration |

### TypeScript (GitHub Integration)

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| **octokit** | 5.0.5+ | GitHub API client | All GitHub interactions |
| **@octokit/webhooks** | latest | Webhook handling | Reactive agent triggers |
| **zod** | 3.x | Schema validation | Validating GitHub payloads, manifest schemas |
| **tsx** | latest | TypeScript execution | Run TS directly without build step (dev convenience) |
| **dotenv** | 16.x | Environment config | Local development secrets |

### Shared/Infrastructure

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| **pre-commit** | 4.0+ | Git hook management | Trust enforcement, code quality |
| **ruff** | latest | Python linting/formatting | Fast linter replacing black+flake8+isort |
| **eslint** | 9.x | TypeScript linting | Code quality for TS components |
| **prettier** | 3.x | Code formatting | Consistent formatting across JS/TS/YAML/MD |

## Installation

### Python Environment

```bash
# Create virtual environment
python3.11 -m venv .venv
source .venv/bin/activate  # Linux/Mac
# .venv\Scripts\activate  # Windows

# Core orchestration
pip install langgraph==1.0.7
pip install google-generativeai
pip install langchain-google-genai
pip install redis[hiredis]

# Supporting libraries
pip install pydantic pyyaml httpx structlog

# Development
pip install pre-commit ruff pytest pytest-asyncio
```

### TypeScript Environment

```bash
# Initialize Node.js project
npm init -y

# Core GitHub integration
npm install octokit @octokit/webhooks

# Supporting libraries
npm install zod dotenv

# Development
npm install -D typescript tsx @types/node
npm install -D eslint prettier @typescript-eslint/parser @typescript-eslint/eslint-plugin
```

### Infrastructure

```bash
# Install Redis Stack (includes RedisJSON, RediSearch for vectors)
# Linux (Docker recommended)
docker run -d --name redis-stack -p 6379:6379 -p 8001:8001 redis/redis-stack:latest

# Or native install
# Mac: brew install redis-stack
# Linux: https://redis.io/docs/latest/operate/oss_and_stack/install/install-stack/

# Install pre-commit
pip install pre-commit
# or: brew install pre-commit

# Install worktree CLI (optional)
# cargo install worktrunk
# or download binary from https://github.com/max-sixty/worktrunk/releases
```

### Docker Compose Setup

```yaml
# docker-compose.yml
version: '3.8'

services:
  redis:
    image: redis/redis-stack:latest
    ports:
      - "6379:6379"
      - "8001:8001"  # RedisInsight UI
    volumes:
      - redis-data:/data

  orchestrator:
    build: ./orchestrator
    environment:
      - GEMINI_API_KEY=${GEMINI_API_KEY}
      - REDIS_URL=redis://redis:6379
      - LANGSMITH_API_KEY=${LANGSMITH_API_KEY}
    depends_on:
      - redis
    volumes:
      - ./orchestrator:/app
      - ./agents:/agents:ro  # Read-only agent manifests

  github-coordinator:
    build: ./github-coordinator
    environment:
      - GITHUB_TOKEN=${GITHUB_TOKEN}
      - REDIS_URL=redis://redis:6379
    depends_on:
      - redis
    ports:
      - "3000:3000"  # Webhook listener

volumes:
  redis-data:
```

```bash
# Start entire stack
docker compose up -d
```

## Configuration

### Environment Variables

```bash
# .env.example
# Gemini Orchestration
GEMINI_API_KEY=your_gemini_api_key
GEMINI_MODEL=gemini-3.0-pro-preview

# GitHub Integration
GITHUB_TOKEN=ghp_your_personal_access_token
GITHUB_WEBHOOK_SECRET=your_webhook_secret

# State Management
REDIS_URL=redis://localhost:6379
REDIS_PASSWORD=  # Leave empty for local dev

# Observability
LANGSMITH_API_KEY=your_langsmith_key
LANGSMITH_PROJECT=manifest-automations
OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318  # If using OTel

# Trust System
AGENT_TRUST_LEVEL=1  # 0-4, controls permissions
```

### Pre-commit Configuration

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.7.0
    hooks:
      - id: ruff
        args: [--fix]
      - id: ruff-format

  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v5.0.0
    hooks:
      - id: check-yaml
      - id: check-json
      - id: detect-private-key
      - id: check-merge-conflict
      - id: trailing-whitespace

  - repo: local
    hooks:
      - id: trust-level-check
        name: Verify agent trust level
        entry: python scripts/check_trust_level.py
        language: system
        pass_filenames: false
```

## Version Management

### Python Dependencies (pyproject.toml)

```toml
[project]
name = "manifest-automations-orchestrator"
version = "0.1.0"
requires-python = ">=3.11"

dependencies = [
    "langgraph>=1.0.7",
    "google-generativeai>=0.8.0",
    "langchain-google-genai>=2.0.0",
    "redis[hiredis]>=5.0.0",
    "pydantic>=2.0.0",
    "pyyaml>=6.0.0",
    "httpx>=0.27.0",
    "structlog>=24.0.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=8.0.0",
    "pytest-asyncio>=0.23.0",
    "ruff>=0.7.0",
    "pre-commit>=4.0.0",
]
```

### TypeScript Dependencies (package.json)

```json
{
  "name": "manifest-automations-github",
  "version": "0.1.0",
  "type": "module",
  "engines": {
    "node": ">=20.0.0"
  },
  "dependencies": {
    "octokit": "^5.0.5",
    "@octokit/webhooks": "^13.0.0",
    "zod": "^3.23.0",
    "dotenv": "^16.4.0"
  },
  "devDependencies": {
    "typescript": "^5.6.0",
    "tsx": "^4.7.0",
    "@types/node": "^20.11.0",
    "eslint": "^9.0.0",
    "prettier": "^3.3.0"
  }
}
```

## Architecture Implications

### Hybrid Language Strategy

**Python Services:**
- Gemini orchestrators (Flash, Pro, Deep Think)
- LangGraph workflow graphs
- Agent state management
- Complex reasoning/planning

**TypeScript Services:**
- GitHub API integration (issues, PRs, projects)
- Webhook receivers
- Real-time event coordination
- Trust level enforcement (GitHub Actions)

**Communication:**
- Redis Pub/Sub for Python <-> TypeScript messaging
- Redis Streams for task queues
- MCP for tool/data sharing

### Deployment Pattern

**Development:**
- Docker Compose for local multi-service orchestration
- Hot reload for both Python and TypeScript
- Local Redis instance
- LangSmith for debugging

**Production:**
- Containerized services (Docker)
- Redis Cloud or self-hosted Redis cluster
- GitHub Actions for CI/CD and trust enforcement
- LangSmith or OpenTelemetry for observability
- Agent manifests in git (version controlled)

## Known Limitations

### Python vs TypeScript Split

**Limitation:** Two languages increases cognitive load and requires bilingual developers.

**Mitigation:** Clear service boundaries. Python = AI/orchestration, TypeScript = GitHub/platform. Communication through Redis and MCP, not direct function calls.

**Alternative:** Pure Python stack with PyGithub. Less optimal (Octokit is official SDK, TypeScript has better types) but possible if team is Python-only.

### LangGraph Learning Curve

**Limitation:** LangGraph's graph-based approach is conceptually different from sequential programming. Steeper learning curve than simpler frameworks.

**Mitigation:** LangGraph is fastest in benchmarks and provides most control. Investment in learning pays off for complex orchestration. Start with simple linear graphs, add complexity incrementally.

### Redis as Single Point of Failure

**Limitation:** All state flows through Redis. If Redis dies, entire system halts.

**Mitigation:** Redis Sentinel for high availability, Redis Cluster for horizontal scaling. Regular snapshots to disk. In MVP, single Redis instance is acceptable; production requires HA setup.

### MCP Ecosystem Maturity

**Limitation:** MCP announced Nov 2024, still evolving. Some features (multimodal support) coming in 2026. API may change.

**Mitigation:** Isolate MCP interactions behind adapters. If MCP changes, update adapters without touching core logic. Ecosystem momentum (OpenAI support, 1000+ servers) suggests MCP is here to stay.

## Confidence Assessment

| Component | Confidence | Reason |
|-----------|------------|--------|
| Python for orchestration | HIGH | Industry standard, all major frameworks Python-first |
| LangGraph | HIGH | Benchmarks prove performance, active development (Jan 2026 release) |
| Google ADK | HIGH | Official Google framework, powers production agents |
| Gemini 3 Pro | HIGH | Purpose-built for agentic workflows, Thought Signatures for stateful execution |
| TypeScript for GitHub | MEDIUM-HIGH | Octokit official but could use Python. TypeScript chosen for type safety. |
| Redis | HIGH | Universal standard for agent state in 2026 ecosystem |
| Git worktrees | HIGH | Proven pattern (Cursor Parallel Agents), multiple 2026 blog posts/tools |
| MCP | MEDIUM-HIGH | Strong momentum (OpenAI, Google, 1000+ servers) but still evolving |
| Docker Compose agents | MEDIUM | Official support added 2025-2026, documented in Docker blog |
| LangSmith | HIGH | Zero overhead, native integration, enterprise adoption (Coinbase) |
| OpenTelemetry | MEDIUM | Standards emerging (Microsoft semantic conventions) but still in progress |
| pre-commit | HIGH | Industry standard for 10+ years, language-agnostic |

## Sources

### Multi-Agent Orchestration Frameworks
- [Top 9 AI Agent Frameworks as of January 2026 | Shakudo](https://www.shakudo.io/blog/top-9-ai-agent-frameworks)
- [Top 5 Open-Source Agentic AI Frameworks in 2026](https://research.aimultiple.com/agentic-frameworks/)
- [LangGraph Multi-Agent Orchestration: Complete Framework Guide 2025](https://latenode.com/blog/ai-frameworks-technical-infrastructure/langgraph-multi-agent-orchestration/langgraph-multi-agent-orchestration-complete-framework-guide-architecture-analysis-2025)
- [Agent Orchestration 2026: LangGraph, CrewAI & AutoGen Guide | Iterathon](https://iterathon.tech/blog/ai-agent-orchestration-frameworks-2026)

### LangGraph
- [LangGraph](https://www.langchain.com/langgraph)
- [How to Continuously Improve Your LangGraph Multi-Agent System](https://galileo.ai/blog/evaluate-langgraph-multi-agent-telecom)
- [@langchain/langgraph - npm](https://www.npmjs.com/package/@langchain/langgraph) - v1.1.0
- [langgraph · PyPI](https://pypi.org/project/langgraph/) - v1.0.7 (Jan 22, 2026)

### Gemini API & Google ADK
- [Using Tools & Agents with Gemini API | Google AI for Developers](https://ai.google.dev/gemini-api/docs/tools)
- [Building AI Agents with Google Gemini 3 and Open Source Frameworks](https://developers.googleblog.com/building-ai-agents-with-google-gemini-3-and-open-source-frameworks/)
- [Agent Development Kit: Making it easy to build multi-agent applications](https://developers.googleblog.com/en/agent-development-kit-easy-to-build-multi-agent-applications/)
- [Agent Config - Agent Development Kit](https://google.github.io/adk-docs/agents/config/)

### GitHub Integration
- [GitHub Octokit](https://github.com/octokit)
- [octokit - npm](https://www.npmjs.com/package/octokit) - v5.0.5
- [From Copilot to Agents: GitHub's multi agent leap in 2026](https://therelaymag.com/from-copilot-to-agents-githubs-multi-agent-leap-in-2026)
- [Why GitHub Agent HQ matters for engineering teams in 2026](https://www.eficode.com/blog/why-github-agent-hq-matters-for-engineering-teams-in-2026)

### Git Worktrees for Multi-Agent
- [How Git Worktrees Changed My AI Agent Workflow | Nx Blog](https://nx.dev/blog/git-worktrees-ai-agents)
- [Git Worktrees: The Secret Weapon for Running Multiple AI Coding Agents in Parallel](https://medium.com/@mabd.dev/git-worktrees-the-secret-weapon-for-running-multiple-ai-coding-agents-in-parallel-e9046451eb96)
- [Use Git Worktree To Run Many Claude Code Agents | Medium](https://medium.com/@lorenzozar/use-git-worktree-to-run-multiple-claude-code-agents-a1d47ef972d5)
- [GitHub - max-sixty/worktrunk](https://github.com/max-sixty/worktrunk)

### YAML Agent Configuration
- [Avoiding Multi-agent System Complexity with YAML](https://medium.com/the-savvy-canary/avoiding-multi-agent-system-complexity-with-yaml-f4f958610930)
- [GitHub - nouamanecodes/lettactl](https://github.com/nouamanecodes/lettactl)
- [Declarative Workflows - Overview | Microsoft Learn](https://learn.microsoft.com/en-us/agent-framework/user-guide/workflows/declarative-workflows)

### Model Context Protocol (MCP)
- [What is Model Context Protocol (MCP)? | IBM](https://www.ibm.com/think/topics/model-context-protocol)
- [MCP & Multi-Agent AI: Building Collaborative Intelligence 2026](https://onereach.ai/blog/mcp-multi-agent-ai-collaborative-intelligence/)
- [What Is MCP (Model Context Protocol)? The 2026 Guide](https://generect.com/blog/what-is-mcp/)

### State Management & Redis
- [AI agent orchestration for production systems | Redis](https://redis.io/blog/ai-agent-orchestration/)
- [Mastering Agent Memory with LangGraph and Redis](https://redis.io/guides/mastering-agent-memory-with-langgraph-and-redis/)
- [Building a product management agent with Redis and LangGraph](https://redis.io/tutorials/howtos/product-management-agent-langgraph/)

### Pre-commit Hooks & Trust
- [How Pre-Commit Security Hooks Shape Trust in Software Development](https://hoop.dev/blog/how-pre-commit-security-hooks-shape-trust-in-software-development/)
- [Git Hooks: Prevent Secrets Exposure with Pre-Commit and Pre-Receive Protection](https://orca.security/resources/blog/git-hooks-prevent-secrets/)
- [pre-commit](https://pre-commit.com/)

### TypeScript AI Frameworks
- [Top 5 TypeScript AI Agent Frameworks You Should Know in 2026](https://techwithibrahim.medium.com/top-5-typescript-ai-agent-frameworks-you-should-know-in-2026-5a2a0710f4a0)
- [Mastra - The Typescript AI framework](https://mastra.ai/)
- [VoltAgent - Open Source TypeScript AI Agent Framework](https://voltagent.dev/)

### Python Asyncio Orchestration
- [Orchestrating multiple agents - OpenAI Agents SDK](https://openai.github.io/openai-agents-python/multi_agent/)
- [GitHub - microsoft/agent-framework](https://github.com/microsoft/agent-framework)
- [multi-agent-orchestrator · PyPI](https://pypi.org/project/multi-agent-orchestrator/)

### Docker & Containerization
- [Docker Brings Compose to the AI Agent Era](https://www.docker.com/blog/build-ai-agents-with-docker-compose/)
- [GitHub - docker/compose-for-agents](https://github.com/docker/compose-for-agents)
- [Agentic AI applications | Docker Docs](https://docs.docker.com/guides/agentic-ai/)

### Observability
- [LangSmith - Observability](https://www.langchain.com/langsmith/observability)
- [Top 5 AI Agent Observability Platforms 2026 Guide](https://o-mega.ai/articles/top-5-ai-agent-observability-platforms-the-ultimate-2026-guide)
- [AI Agent Observability - Evolving Standards and Best Practices | OpenTelemetry](https://opentelemetry.io/blog/2025/ai-agent-observability/)

## Next Steps

1. **Prototype Integration** - Build minimal Gemini orchestrator calling Claude worker via GitHub issue creation. Validates Python->GitHub->Claude flow.

2. **Redis State Setup** - Configure LangGraph Redis checkpointer, verify state persistence across restarts.

3. **Worktree Automation** - Script worktree creation/cleanup for parallel Claude workers. Test with 2-3 concurrent agents.

4. **Agent Manifest Schema** - Define YAML schema for agent definitions (roles, trust levels, tools). Validate with Pydantic/Zod.

5. **Trust Hook Implementation** - Build pre-commit hooks that check trust level against operation (read-only vs write). Test bypass detection.

6. **Observability Setup** - Integrate LangSmith, verify trace capture for multi-agent workflows. Validate zero overhead claim.

7. **MCP Server Evaluation** - Survey existing MCP servers for GitHub, file system, and common tool integrations. Build custom MCP servers if gaps exist.

8. **Production Docker Setup** - Extend docker-compose.yml with all services, configure health checks, volume mounts, secrets management.
