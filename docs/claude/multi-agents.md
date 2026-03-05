# Multi-Agent Patterns with Claude Code

This guide covers how to design and run multi‑agent workflows with Claude Code: subagents, agent teams, and external orchestration, plus observability and safety patterns.

It assumes you are already comfortable with single‑agent workflows and have a solid `CLAUDE.md` and `.claude/settings.json` in place.

---

## 1. The Multi-Agent Landscape in Claude Code

There are three main layers of "multi‑agent" you can use around Claude Code:

1. **Subagents** – specialized personalities with their own prompts and tool sets, invoked automatically or via commands.
2. **Agent Teams** – multiple Claude Code sessions working in parallel on coordinated tasks, orchestrated by a team lead.
3. **External Orchestrators and Sandboxes** – scripts or services that spin up many Claude Code instances or API‑driven agents, often with separate compute sandboxes.

On top of that, **skills**, **hooks**, and **MCP servers** act as building blocks for composing agent behaviors.

The key design question: *Which work genuinely benefits from parallelization, and how do you keep it safe and observable?*

---

## 2. Subagents: Specialized Personalities Inside Claude Code

Subagents are preconfigured Claude personalities that:
- Have their own system prompts and descriptions
- Optionally use a constrained set of tools
- Can be invoked automatically based on task descriptions or explicitly

### 2.1 When to use subagents

Subagents are ideal for:
- Domain‑specific reviews (security, performance, accessibility, UX)
- Focused roles ("test writer", "doc writer", "migration planner")
- Tasks where you want a distinct "voice" and behavior separate from the main agent

Examples:
- `security-auditor` – scans diffs for common vulnerabilities
- `test-engineer` – writes and maintains tests
- `doc-writer` – converts behavior into human‑readable docs

### 2.2 Designing effective subagents

A typical subagent definition includes:
- **name** – short, role‑specific
- **description** – when it should be used
- **model** – haiku/sonnet/opus depending on complexity
- **tools** – which Claude Code tools it may call (Read, Write, Bash, MCP servers, etc.)
- **prompt** – detailed system instructions

Design guidelines:
- One clear responsibility per subagent
- Minimal tool access needed for that role
- Explicit boundaries (what it *must not* do)

Example behaviors to encode in the prompt:
- Output formats
- Checklists (for example, OWASP Top 10 items)
- What to do when input is ambiguous (ask clarifying questions vs proceed conservatively)

### 2.3 Subagent usage patterns

Common patterns:
- **Parallel review** – run security, performance, and code‑style subagents separately on the same diff
- **Pipeline** – planner agent → implementation agent → doc agent
- **On‑demand** – trigger a subagent only for specific commands (for example, "/security-review")

Subagents are still bounded by a single Claude Code session’s lifespan and context window, but they create mental and operational separation between different roles.

---

## 3. Agent Teams: Parallel Claude Code Sessions

Agent Teams extend beyond subagents by running *multiple full Claude Code sessions* in parallel, each with its own context window, tools, and tasks.

Conceptually:
- One session is the **team lead**.
- The team lead creates a task list and spawns teammate sessions.
- Each teammate works independently on its task(s), reporting progress.
- The team lead integrates results and decides on next steps.

### 3.1 When agent teams are useful

Agent teams shine for **read‑heavy, analysis‑heavy, or exploratory** work, such as:
- Reviewing huge codebases or many services at once
- Performing architecture or dependency audits
- Running large‑scale search and summarization across repos
- Exploring many alternative designs in parallel

They are riskier for write‑heavy work that touches overlapping files. For that, prefer:
- Single‑agent workflows
- Strong test suites and code review
- Clear file‑ownership rules

### 3.2 Enabling and configuring agent teams

Typical setup steps (details may vary by version):

1. Enable experimental agent team support in your Claude Code settings.
2. Define sensible limits in `settings.json`:
   - Maximum teammates
   - Default models per role
   - Time and cost bounds
3. Configure your terminal environment (for example, tmux panes) if you want visual side‑by‑side views of each agent.

### 3.3 Designing team structures

Common structures:

- **Horizontal review team**
  - Team lead: orchestrator and integrator
  - Teammate A: frontend expert
  - Teammate B: backend expert
  - Teammate C: infra/DevOps

- **Vertical feature team**
  - Team lead: product/architecture
  - Teammate A: API and data modeling
  - Teammate B: UI implementation
  - Teammate C: test engineering & docs

Design rules:
- Give each teammate a clear domain and file scope
- Avoid two agents editing the same file concurrently
- Prefer agents to *read* others’ outputs rather than racing to write

### 3.4 Lifecycle of an agent team run

A typical orchestration flow:

1. **Task formation**
   - You describe the high‑level goal and constraints to the team lead.
   - The team lead proposes a task breakdown.
2. **Team creation**
   - The team lead creates teammates with role prompts and tool sets.
3. **Parallel execution**
   - Each teammate executes its tasks, calling tools, reading code, and writing analyses.
4. **Integration and synthesis**
   - The team lead reviews outputs, resolves conflicts, and composes a unified result.
5. **Shutdown**
   - Teammates complete tasks and are terminated.

You can often jump into any teammate’s context to inspect or steer.

---

## 4. External Orchestration, Sandboxes, and Observability

Many advanced setups run **multiple Claude Code instances** (or API‑driven Claude agents) from outside the CLI for scale and isolation.

### 4.1 Sandboxed execution environments

To safely let agents make aggressive changes or run arbitrary code, teams use:
- Ephemeral containers or devcontainers
- Cloud sandboxes (for example, E2B‑style environments)
- Disposable VMs or remote workspaces

Pattern:
- A controller script spins up N sandboxes.
- Each sandbox runs a Claude Code instance or agent connected to a slice of the codebase or a specific task queue.
- Results are sent back to a central orchestrator for aggregation and review.

This allows many agents to run without risking your primary dev machine or production infra.

### 4.2 Observability with hooks

Claude Code hooks can emit telemetry for:
- Session start/stop
- Tool calls (file edits, bash commands, MCP calls)
- Errors and timeouts

An observability stack typically:

- Captures hook events via HTTP, message queues, or logs
- Stores them in a lightweight database
- Streams them to a dashboard with:
  - Per‑agent timelines
  - Active task counts
  - Error rates and slow operations

Benefits:
- You can see what dozens of agents are doing in real time.
- You can retroactively debug why an agent made a particular change.
- You can spot wasteful or dangerous patterns (for example, repeated re‑init of projects, redundant scans).

### 4.3 Multi-agent governance

Governance practices for large agent fleets:
- Define *allowed* and *forbidden* tools per agent type.
- Gate dangerous operations (infra changes, data deletion) behind human approval.
- Tag agents and tasks with ownership metadata (team, project, environment).
- Keep permanent logs of:
  - Prompts and plans
  - Diffs applied
  - Commands executed

Treat agents like employees: they should have managers, scopes, and audit trails.

---

## 5. Skills, MCP, and Multi-Agent Composition

**Skills**, **MCP servers**, and **subagents** work together to encode reusable workflows and connect agents to external systems.

### 5.1 Skills as reusable capabilities

A skill is essentially:
- A folder of instructions (`SKILL.md`) and optional scripts
- A narrow, task‑focused capability (for example, "Set up a new feature branch with tests and preview env")
- Auto‑loaded when Claude judges it relevant

Design skills that:
- Encode end‑to‑end workflows you repeat often
- Wrap MCP tools, git commands, scripts, and prompts into one reusable unit
- Are idempotent and safe to run repeatedly

Example use cases:
- Creating, deploying, and validating preview environments
- Performing accessibility reviews on UI diffs
- Generating incident postmortems from logs and metrics

### 5.2 MCP for connectivity

MCP servers expose external systems (CRMs, CI systems, observability stacks, automations, etc.) as tools.

Multi‑agent patterns include:
- Research agents that query docs, tickets, logs, and metrics via MCP
- Incident agents that page, open, and update issues
- Data agents that run analytical queries and summarize dashboards

Skills and subagents can wrap MCP usage so that:
- The same workflows work across Claude Code, Claude.ai, and API agents
- Individual agents only see the tools they need

### 5.3 Putting it together: example multi-agent workflow

A realistic multi‑agent incident workflow might look like:

1. **Incident lead agent** (main Claude Code session)
   - Receives a description of the incident
   - Spawns subagents:
     - `logs-investigator` (MCP to logs)
     - `metrics-analyst` (MCP to metrics)
     - `changes-reviewer` (MCP to git/GitHub)
2. Each subagent uses skills to:
   - Pull relevant time windows and services
   - Correlate spikes, errors, and recent deployments
3. The incident lead composes a timeline and likely root causes.
4. A `postmortem-writer` skill assembles a draft document.
5. Humans review, correct, and approve actions.

The same pattern works for code audits, schema migrations, and large redesigns.

---

## 6. Safety and Cost Management in Multi-Agent Setups

Multi‑agent systems can multiply both *impact* and *risk*. Put controls in place:

### 6.1 Safety

- Strictly separate **read‑only** and **read/write** agents.
- Run write‑capable agents only in sandboxes or feature branches.
- Keep destructive tools (deletes, production migrations) behind manual approval.
- Use hooks to:
  - Block commands outside allowed patterns
  - Require human approval for certain operations

### 6.2 Cost and resource control

- Prefer cheaper models (for example, haiku) for bulk analysis and summarization.
- Reserve top models for complex reasoning and final decisions.
- Limit concurrent agents and per‑task token budgets.
- Use context compaction or summarization when agents run long.

### 6.3 Human-in-the-loop checkpoints

Define clear checkpoints where a human must:
- Approve a plan before agents execute
- Approve diffs before merging
- Approve infra or schema changes
- Approve external side‑effects (notifications, customer‑visible changes)

Multi‑agent systems are most powerful when humans steer at key decision points while agents handle scale, exploration, and mechanical execution.

---

## 7. Designing Your Own Multi-Agent Topology

To design a topology for your team:

1. **List your recurring workflows** (build, test, review, deploy, debug, operate).
2. **Identify roles** that could be separate agents (planner, builder, reviewer, SRE, doc writer, etc.).
3. **Decide the minimum set of agents** that gives you leverage without chaos.
4. **Start small**:
   - One main agent
   - 1–2 subagents
   - A single, well‑tested skill
5. **Add observability** before scaling out.
6. **Iterate**: capture successful patterns into reusable skills, scripts, and templates.

Used thoughtfully, multi‑agent Claude Code setups feel less like managing one assistant and more like running a small, well‑instrumented engineering org—one where you design the org chart and the processes, and Claude handles the execution at machine speed.
