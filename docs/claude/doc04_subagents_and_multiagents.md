# Subagents and Multi‑Agent Patterns in Claude Code

## Introduction

Claude Code supports several modes of parallelisation beyond a single chat session.  These include **subagents**, **agent teams**, and externally orchestrated instances that run in sandboxes.  Each has unique strengths and constraints.  Understanding when to employ each pattern—and how to configure them safely—allows you to scale your vibe coding workflows without sacrificing control or quality.

## Subagents

### What are subagents?

A subagent is a specialised Claude persona defined under `.claude/agents/` with its own system prompt, tool permissions and sometimes a different default model.  Subagents inherit the current codebase context but maintain their own isolated conversation history.  They are ideal for tasks requiring a focused role or alternative voice【763205023180404†L101-L112】.

### When to use subagents

Use a subagent when you need a distinct perspective on the code or output, such as:

* **Domain‑specific reviews** – security auditing, performance analysis, accessibility checks or UX critique【103746295110896†L112-L139】.
* **Focused roles** – a “test writer” that writes and maintains tests; a “doc writer” that produces human‑readable documentation【103746295110896†L112-L139】.
* **Pipelines** – chaining agents into a workflow, such as planner → implementer → reviewer【103746295110896†L141-L155】.
* **Parallel review** – running multiple subagents concurrently on the same diff to surface different concerns.

Avoid using subagents for tasks that require cross‑file edits on overlapping files, as all subagents share the same repository.  Subagents also consume context window independently; keep prompts concise and summarise results back into the main session to reduce context bloat【836363446235956†L126-L136】.

### Designing effective subagents

A good subagent definition includes:

* A short **name** and **description** indicating when it should be invoked.
* A chosen **model** appropriate to the role (e.g. `haiku` for fast summarisation, `sonnet` or `opus` for deeper reasoning).
* A minimal set of allowed **tools** (ReadFile, WriteFile, Bash, MCP servers) consistent with the agent’s responsibility【103746295110896†L112-L139】.
* A **system prompt** that spells out responsibilities, output format and boundaries—what the agent must not do.  Encourage the agent to ask clarifying questions when input is ambiguous.

Subagents can be invoked manually via slash commands (e.g. `/security-review`) or automatically by Claude Code when a task description matches their scope.  They operate within the lifespan of the parent session, making them lighter weight than agent teams.

## Agent teams

### Concept and lifecycle

Agent teams orchestrate multiple full Claude Code sessions concurrently.  One session acts as the **team lead**, which creates a task list and spawns several **teammate** sessions.  Each teammate has its own context window, tools and prompt, and works independently on assigned tasks.  The team lead integrates results and coordinates next steps【138937746514428†L124-L148】.

The typical lifecycle of an agent team involves:

1. **Task formation** – you describe the overall goal and constraints to the team lead.  The lead breaks it down into tasks.
2. **Team creation** – the lead spawns teammates with role prompts and tool sets.
3. **Parallel execution** – teammates execute tasks concurrently, performing reads, writes or analysis.
4. **Integration** – the lead reviews outputs, resolves conflicts and synthesises a unified result.
5. **Shutdown** – teammates complete tasks and terminate【138937746514428†L164-L178】.

### When to use agent teams

Agent teams excel at read‑heavy or exploratory tasks across large codebases or many services.  They are particularly useful for:

* Massive search and summarisation – scanning thousands of files or multiple repositories simultaneously【138937746514428†L124-L148】.
* Architecture or dependency audits – mapping how services communicate or analysing dependencies.
* Exploring alternative designs – having different teammates propose competing approaches.

Because agent teams run concurrently, they are riskier for write‑heavy changes.  Avoid concurrent edits to overlapping files and instead funnel write operations through a single agent or the team lead.  Use strong test suites and code review to verify modifications【138937746514428†L164-L178】.

### Configuring and controlling teams

Agent teams are still experimental; you must enable them in your `.claude/settings.json` under the `experimental` or `features` section.  Configuration fields include:

* **Maximum teammates** and concurrency limits to avoid runaway cost.
* **Default models** for each role.  Use cheaper models (`haiku`) for bulk analysis and more capable models (`sonnet` or `opus`) for synthesising results【103746295110896†L141-L155】.
* **Time and cost bounds** per team run to prevent infinite loops.

When designing a team structure, assign clear domains or file scopes to each teammate.  For example, separate frontend, backend and infrastructure roles, or design vertical feature teams (API, UI, tests)【138937746514428†L124-L148】.  Avoid having multiple agents edit the same file; instead, have them read each other’s outputs and merge changes through the team lead.

## External orchestrators and sandboxes

For very large multi‑agent systems, external scripts or services can spin up many Claude Code instances, each in its own sandbox.  These orchestrators run agents in isolated containers or VMs to protect your primary development machine and production infrastructure【103746295110896†L112-L139】.  A controller script distributes tasks, collects results and aggregates them.  This pattern is powerful for large‑scale audits, migrations or incident response, but it requires robust monitoring and governance.

## Safety, cost management and governance

Multi‑agent setups multiply both impact and risk.  To keep them under control:

* **Separate read‑only and write agents.** Run write‑capable agents only in sandboxes or on feature branches.  Keep destructive tools behind manual approval【103746295110896†L141-L155】.
* **Limit concurrency and choose appropriate models.** Use haiku for bulk reading and summarisation; reserve opus/sonnet for final decisions or complex reasoning.  Set token budgets and timeouts to control cost【103746295110896†L141-L155】.
* **Human-in‑the‑loop checkpoints.** Require human approval before executing risky operations (schema migrations, infrastructure changes, notifications).  Make the plan explicit and review diffs or outputs before merging【149066924147065†L1379-L1452】.
* **Observability and logging.** Use hooks to emit telemetry about tool calls and errors.  Store agent events in a database and visualise them to understand what each agent is doing and debug issues【103746295110896†L112-L139】.
* **Governance and ownership.** Define allowed and forbidden tools per agent.  Tag agents and tasks with metadata, enforce audit trails, and assign owners who review agent behaviour【103746295110896†L112-L139】.

## Designing your multi‑agent topology

To design an effective topology:

1. **List your recurring workflows** (build, test, review, deploy, debug, operate).
2. **Identify roles** that could be separate agents (planner, implementer, reviewer, SRE, doc writer).  Each role should have a clear scope and minimal tool set.
3. **Start small.** Begin with a single main agent and one or two subagents or teammates.  Validate the pattern and add observability before scaling up【103746295110896†L112-L139】.
4. **Iterate and refine.** Capture successful patterns into reusable skills, slash commands and scripts.  As your organisation grows, your agent topology will begin to resemble an engineering org chart—design it deliberately.

By understanding the strengths and trade‑offs of subagents, agent teams and external orchestration, you can harness parallelism without creating chaos.  Multi‑agent Claude setups allow you to delegate large analyses, independent reviews and exploratory research at machine speed while maintaining safety, structure and human oversight.