# Setup and Environment Hardening

## 1. Installing Claude Code

- **Requirements:** Node.js 18+ and a shell environment (bash, zsh, fish or PowerShell). Install the CLI globally via `npm install -g @anthropic-ai/claude-code`. Update periodically with `claude update` to receive new features and security fixes.
- **Authentication:** Authenticate the CLI using `claude auth login` for personal use or set `ANTHROPIC_API_KEY` as an environment variable for CI and shared containers. Verify your session with `claude auth status` before long sessions.

## 2. Project Structure & Memory

- **`CLAUDE.md`** serves as the project’s persistent memory.  Create this file in the root of every repository.  Include a one‑line project description, tech stack, canonical commands (install, test, dev, build), code style rules, testing requirements and any “gotchas”【821230275885680†L36-L74】.  Claude reads this file automatically at the start of each session.
- **Hierarchy:** Use multiple levels of `CLAUDE.md` to scope instructions: a personal `~/CLAUDE.md` for your global preferences, a project‑level `/repo/CLAUDE.md`, and service‑level files (e.g., `/repo/apps/api/CLAUDE.md`).  Keep each file concise and specific.
- **Local overrides:** For machine‑specific settings such as API keys, local paths or experimental flags, create `CLAUDE.local.md` and add it to `.gitignore`.

## 3. The `.claude/` Directory

Your project root should contain a `.claude/` folder with:

```text
.claude/
  settings.json
  commands/
  hooks/
  agents/
  skills/
  rules/
```

* **`settings.json`** – Configure default models (use Haiku for speed or Opus for complex reasoning), specify whether Claude must ask before editing files or running shell commands, and enable experimental features like Plan Mode, Tasks, Agent Teams or Remote Control.  This file ensures consistent behaviour across the team.
* **`commands/`** – Slash commands defined here are macros for repeatable workflows.  Commands orchestrate tasks, subagents and tools.
* **`hooks/`** – Scripts triggered before or after tool calls (e.g., run tests on file edits, block destructive commands).  Use hooks to enforce policies and emit telemetry.
* **`agents/`** – Definitions for subagents or agent teams with their own prompts and permissions.
* **`skills/`** – Reusable capabilities packaged with a `SKILL.md` and optional scripts (see the skills guide).
* **`rules/`** – Modular rules that apply to specific parts of the codebase (API standards, testing conventions).  Claude loads relevant rules based on file paths.

## 4. Hardening Your Environment

* **Isolated workspaces:** Use feature branches and isolated environments (containers, devcontainers or disposable VMs).  Never point Claude at production configuration or secrets.
* **Secrets management:** Never paste secrets into chat.  Store secrets in `.env` files or secret stores and tell Claude what keys exist without revealing values.  Avoid embedding API keys or secrets in `settings.json` or skills.
* **Protect critical areas:** Mark sensitive directories (e.g., `infra/terraform`, `k8s/`) as off‑limits in `CLAUDE.md` unless explicitly asked.  Create hooks to validate or block changes to these paths.
* **Command guardrails:** Require Claude to display commands before running them.  Explicitly confirm destructive commands (`rm`, `drop`, `terraform apply`, `kubectl delete`).  Standardize database migration commands and enforce them via hooks.

## 5. Editor & MCP Integration

* **Editor pairing:** Run Claude Code in a terminal pane alongside your IDE (VS Code, JetBrains, Cursor).  Use the editor for navigation, fine‑grained edits and diff review; use Claude for large diffs, scaffolding and automation.
* **MCP servers:** Model Context Protocol (MCP) servers expose external APIs (issue trackers, observability, automations).  Configure them in `.claude/mcp.json` and document how and when to use them in `CLAUDE.md`.  Grant only the scopes required for each task.

## 6. Commands, Hooks & Plugins

* **Slash commands:** Create reusable commands (e.g., `/sprint`, `/ship`) in `.claude/commands/`.  These orchestrate multi‑step workflows by invoking skills, subagents and tools.
* **Hooks:** Write scripts that trigger on lifecycle events—before edits, after tool calls or when sessions start/stop.  Use hooks to run tests automatically, enforce linting, block forbidden actions and collect telemetry.
* **Plugins:** Package commands, hooks, skills and settings into plugins stored under `.claude/`.  Share plugins across projects or teams via private registries or git submodules.

## 7. Team‑Level Standards

* **Version control:** Check in `.claude/` (excluding secrets) so all team members share commands, skills, agent definitions and rules.
* **Documentation:** State when to use Claude versus manual coding and define minimum test and documentation standards in `CLAUDE.md`【821230275885680†L36-L74】.
* **Continuous improvement:** Schedule regular reviews to refine `CLAUDE.md`, prune unused commands or agents and capture new patterns into skills.  A well‑maintained setup turns vibe coding sessions into predictable, repeatable workflows.