# Managing Memory and Configuration in Claude Code

Claude Code’s performance depends on how well you manage context and configure its environment.  This document explains how to write effective `CLAUDE.md` files, organise multi‑level memory, tune settings via `.claude/settings.json` and keep the context window under control.

## `CLAUDE.md`: your project’s brain

`CLAUDE.md` stores the persistent project knowledge that Claude loads at the start of each session.  It complements, but does not replace, your normal documentation.  A well‑crafted `CLAUDE.md` should be concise and high leverage.  Include:

* **A one‑line project description** and high‑level architecture overview.
* **Tech stack and major libraries** (language versions, frameworks, DB technologies).
* **Canonical commands** for installing dependencies, running tests, starting the dev server and building for production【821230275885680†L36-L74】.
* **Code style rules** that differ from defaults (e.g. TypeScript only, functional components).
* **Testing conventions** (where to put tests, when to write them).
* **Repository etiquette** – branch naming, commit message style and PR conventions.
* **Gotchas and constraints** – environment variables that must be set, modules that should not be modified, or performance/security considerations.

Do **not** cram entire specs or design docs into `CLAUDE.md`.  It is better to link to other documents and summarise them.  Keep the file short enough that Claude can digest it quickly【574041979857242†L124-L138】.  For long‑lived projects, refine `CLAUDE.md` regularly based on your interactions with Claude: whenever you correct the model on something you never want it to do again, encode that rule in `CLAUDE.md`.

### Hierarchies and local overrides

Claude automatically loads all `CLAUDE.md` files from the current directory up to the repository root and your home directory.  Use this hierarchy to scope instructions:

* **Personal memory (`~/CLAUDE.md`)** – preferences and habits that apply across all projects (e.g. your preferred code style, default stack).  Keep it short and avoid project‑specific details【523873900392618†L137-L170】.
* **Project memory (`/repo/CLAUDE.md`)** – high‑level architecture, commands, style rules and constraints for the repository【821230275885680†L36-L74】.
* **Service or directory memory (`/repo/apps/api/CLAUDE.md`)** – service‑specific conventions and gotchas.
* **Local overrides (`CLAUDE.local.md`)** – machine‑specific instructions (API keys, experimental flags) that should never be committed.  Add these files to `.gitignore`.

The nearer `CLAUDE.md` has precedence over more distant ones.  Keep each file focused on its scope to prevent duplication and confusion.

## `.claude/settings.json`: fine‑tuning behaviour

Inside `.claude/` you can define deeper configuration in `settings.json`.  Important fields include:

* **Default models.** Choose per‑repo defaults for tasks.  Use `opus` or `sonnet` for complex reasoning and architecture, `haiku` for fast summarisation and repetitive tasks【103746295110896†L141-L155】.
* **Safety and permissions.** Configure whether Claude must ask before editing files, creating/deleting files or running shell commands.  For most development, leave prompts on for shell execution; only disable them in tightly sandboxed environments【103746295110896†L112-L139】.
* **Experimental features.** Enable Plan Mode, agent teams, remote control or tasks.  Keep track of features that are still in preview and adjust once stable.
* **Model Context Protocol (MCP) servers.** Configure endpoints that allow Claude to call external APIs.  Document how and when to use each server in `CLAUDE.md`, and restrict tokens and scopes appropriately【103746295110896†L141-L155】.

Store the `.claude/` directory (minus secrets) in version control so that the entire team benefits from consistent configuration.

## Managing context: summarisation and isolation

Claude’s performance degrades when the conversation becomes long.  Use these strategies to preserve context:

* **Summarise regularly.** Ask Claude to summarise the current state of the project, open tasks or session history.  Use the summary as a fresh starting point and discard earlier messages.
* **Isolate tasks.** Delegate exploratory or deep work to subagents or agent teams, then summarise their findings back into the main thread.  This prevents context pollution【745847718543847†L69-L78】.
* **Compress large files.** When you need to discuss a file, ask Claude to summarise it or use tools to extract only the relevant parts rather than pasting the entire file.
* **Use tasks for long‑running objectives.** Persistent tasks store the plan in the filesystem.  You can clear the conversation to free tokens and later reload the plan without losing state【384420799970136†L31-L83】.

By actively managing context, you avoid the “lost in the middle” problem where key instructions are pushed out of the context window【745847718543847†L52-L63】.

## Combining memory with tasks

Tasks and memory serve different purposes: `CLAUDE.md` stores high‑level knowledge and constraints, while tasks store a queue of work items.  Together they enable multi‑session workflows:

1. **Create or load a task** for the goal at hand (e.g. “Add search to the notes app”).  Store the plan and its dependency graph.
2. **Use Plan Mode** and `CLAUDE.md` to design the approach.  Incorporate project constraints and preferences【190373145820492†L312-L337】.
3. **Resume later** by loading the task.  The project memory will re‑load automatically, and the task will remind Claude of the remaining steps.  Use the summary to refresh the context.
4. **Coordinate subagents or teammates** by assigning different task nodes.  Because tasks are persisted, multiple agents can pick up work without sharing a conversation history【384420799970136†L86-L100】.

## Continuous improvement

Treat memory and configuration as living documents.  Schedule regular reviews to:

* Update `CLAUDE.md` when you correct Claude’s misunderstandings or refine your standards.
* Prune outdated rules or obsolete commands.
* Adjust model defaults and permissions as your workflows evolve.
* Validate tasks and clear completed or obsolete tasks from the store.

By curating memory and settings, you ensure that Claude remains aligned with your project and organisation.  Good configuration makes the difference between chaotic conversations and a well‑orchestrated partnership with your AI coding assistant.