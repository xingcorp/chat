# Designing and Using Skills with Claude Code

This guide explains how to design, build, and operate **Skills** for Claude, with a focus on using them effectively in Claude Code and in multi‑agent setups.

Skills turn your best workflows into reusable, task‑driven capabilities that activate automatically when Claude needs them.

---

## 1. What Are Skills?

A **Skill** is a folder that contains:
- A `SKILL.md` file that describes what the skill does and when it should run
- Optional scripts, templates, and resources the skill uses

Claude can:
- Discover skills based on their descriptions
- Load them on demand when a task matches their scope
- Use them consistently across **Claude Code**, **Claude.ai**, and the **Claude API / Agent SDK**.

Key properties:
- **Task-focused**: each skill solves a specific recurring task or workflow
- **Composable**: multiple skills can be activated together
- **Portable**: same structure works across products
- **Efficient**: progressive disclosure prevents overloading the context window

---

## 2. When to Use Skills (vs. Commands, Subagents, MCP)

Skills sit alongside other Claude Code extension mechanisms:

- **Slash commands**: manually triggered, ideal for actions you explicitly run (for example, `/sprint`, `/ship`).
- **Subagents**: alternative personas with focused prompts and tool sets, good for reviews and specialized roles.
- **MCP servers**: connectors to external systems (APIs, SaaS tools, databases).
- **Skills**: auto‑triggered workflows that combine instructions, tools, and sometimes commands.

Use a Skill when:
- The workflow is repeatable and well understood.
- You want Claude to "just know" how to do something whenever it’s relevant.
- The task typically involves multiple steps, tools, or files.

Examples:
- "Set up a new feature branch with tests, fixtures, and a preview environment."
- "Generate an incident timeline and initial postmortem from logs and tickets."
- "Update release notes and changelog based on merged PRs."

---

## 3. Anatomy of a Good Skill

A typical Skill folder:

```text
skills/
  incident-timeline/
    SKILL.md
    templates/
      timeline.md
    scripts/
      fetch_logs.py
      fetch_tickets.py
```

### 3.1 SKILL.md contents

`SKILL.md` usually contains:
- **Name** and short description
- **When to use** – conditions or triggers
- **What it does** – the steps it performs
- **Inputs/outputs** – parameters, expected artifacts
- **Constraints** – environments, tools, or safety considerations

Guidelines:
- Be explicit about WHEN and WHEN NOT to use the skill.
- Use clear, task‑oriented language (for example, "Use this to…").
- Keep it focused—avoid mixing unrelated workflows.

Example sketch:

```markdown
# Incident Timeline Skill

Use this skill when:
- There has been a production incident affecting users, and
- We have access to logs, metrics, and an incident tracking system.

What this skill does:
- Fetches logs and metrics for the incident window.
- Pulls related tickets and deployment events.
- Produces a draft incident timeline and key events.

Do NOT use this skill for:
- Local development issues or test environments.
- Non‑user‑facing internal bugs.
```

### 3.2 Scripts and resources

Skills can include:
- Shell or Python scripts
- Templates (Markdown, YAML, JSON)
- Helper configuration files

Best practices:
- Keep scripts idempotent and safe to re‑run.
- Treat them like normal code: tests, reviews, CI.
- Avoid baking secrets into skill folders; use environment variables or secret stores.

---

## 4. Designing Skills from Existing Workflows

A good way to design skills is to start from workflows you already run manually with Claude Code.

### 4.1 Identify candidates

Look for workflows that are:
- Repeated several times a week
- Multi‑step and error‑prone when done manually
- Important enough to justify standardization

Examples:
- Setting up new projects or services
- Onboarding a new engineer to a codebase
- Running accessibility or security reviews on PRs
- Creating release notes and changelogs

### 4.2 Extract the implicit playbook

For each candidate:
1. Describe the goal in natural language.
2. List the concrete steps you (and Claude) usually follow.
3. Note the tools and files involved.
4. Capture common pitfalls and decisions.

You can ask Claude to help:
> Based on our last few sessions doing [workflow], summarize the steps we followed, including commands, files, and decisions.

Use this as the basis for `SKILL.md` and any scripts.

### 4.3 Encode constraints and boundaries

Be explicit about:
- Environments (local vs staging vs prod)
- Required permissions
- Paths and file patterns the skill may touch
- Unsafe actions that require human approval

The more precise your constraints, the more safely Claude can run the skill without supervision.

---

## 5. Using Skills in Claude Code

### 5.1 Skill discovery

Claude discovers skills by:
- Scanning configured skill directories (for example, under `.claude/skills` or a shared skills repo)
- Reading `SKILL.md` and building an internal index of capabilities

When you describe a task in Claude Code, it:
- Matches your request against known skills
- Loads relevant ones on demand
- Applies their instructions and scripts

### 5.2 Activating skills

There are two main activation paths:

1. **Automatic** – you describe a task and Claude decides: "This matches skill X" and uses it.
2. **Guided** – you ask Claude explicitly:
   > Check if we have a skill that can help with [task]. If so, describe what it does and propose using it.

This guided pattern is useful when you’re still building trust in new skills.

### 5.3 Combining skills with commands and subagents

Skills work best when composed with other features:

- A **slash command** (`/ship`) can:
  - Call a skill to prepare release notes
  - Invoke a subagent to perform a targeted review
  - Run deployment scripts via MCP

- A **subagent** can:
  - Use a skill as its standard playbook (for example, `security-auditor` always uses the `security-scan` skill when analyzing diffs)

This composition keeps the core logic in skills while commands and subagents handle triggering and role‑based behavior.

---

## 6. Skills with MCP and External Systems

Skills become especially powerful when paired with MCP servers.

### 6.1 Example: incident response skill

Skill: `incident-response`
- Uses MCP servers for:
  - Logs (observability platform)
  - Metrics
  - Ticketing system
- Steps:
  - Pull events for the incident time window
  - Correlate error spikes with deployments
  - Generate a timeline and summary
  - Draft a postmortem template

This entire orchestration is described in `SKILL.md` and implemented via scripts that call MCP tools.

### 6.2 RAG-like skills

You can build skills that:
- Load domain documents (runbooks, standards, design docs)
- Index or chunk them
- Use them to answer questions or drive workflows

The skill encapsulates:
- Where the documents are
- How to retrieve them
- How to interpret them for a specific task

---

## 7. Versioning, Distribution, and Governance

### 7.1 Version control and releases

Treat skills as proper software artifacts:
- Store them in git repos
- Use semantic versioning for skill versions
- Document changes in a changelog

When updating skills:
- Communicate changes to users (developers, operators)
- Test in non‑production environments first

### 7.2 Distribution patterns

Common approaches:
- **Monorepo under `.claude/skills`** – simplest for a single team
- **Shared skills repo** – cloned as a submodule or dependency into multiple projects
- **Marketplace / registry** – for sharing skills across organizations

Regardless of distribution, ensure:
- Clear README and installation instructions
- Example usage snippets
- Compatibility notes (required tools, environments, MCP servers)

### 7.3 Governance

Because skills can run powerful workflows:
- Define ownership per skill (team or individual)
- Set review and approval processes for changes
- Audit skill runs via logs or hooks

For sensitive areas (infra, data migrations, user‑facing operations):
- Require human approvals before certain skill steps execute
- Encode checks into scripts (for example, require explicit `--prod` flags)

---

## 8. Skill Design Patterns

Here are some patterns that work well in practice.

### 8.1 Template skills

Skills that help *create other skills* or standard configs.
- Example: `skill-creator` that walks you through designing a new skill and scaffolds the folder.
- Benefit: consistent structure and fewer errors.

### 8.2 Guardrail skills

Skills focused on enforcing standards:
- Checking for style guide violations
- Ensuring certain headers or metrics are present
- Verifying compliance with security checklists

They run alongside other workflows to keep quality high.

### 8.3 Pipeline skills

Skills that orchestrate multi‑step pipelines, such as:
- Build → test → package → deploy → notify
- Generate dataset → train model → evaluate → report

These often coordinate multiple MCP tools and subagents.

---

## 9. Getting Started: Your First Skill

A simple path to your first skill:

1. Pick a small, high‑value workflow (for example, generating a release summary from merged PRs).
2. Run it manually with Claude Code a few times; refine the steps until they feel stable.
3. Ask Claude to draft a `SKILL.md` describing the workflow.
4. Turn any repeated scripts into files under `scripts/`.
5. Test the skill end‑to‑end on a non‑critical repo.
6. Start using it regularly and refine based on feedback.

Over time, your skills library becomes a codified version of your team’s best practices. Claude stops being a generic assistant and becomes an operator that knows *how your organization works*, because you’ve taught it through skills.

Used well, skills are one of the highest‑leverage ways to make vibe coding with Claude Code **fast**, **consistent**, and **safe**.
