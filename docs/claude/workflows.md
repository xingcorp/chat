# High-Performance Workflows for Vibe Coding with Claude Code

This document focuses on concrete workflows you can follow day‑to‑day when building software with Claude Code. It assumes you’ve already set up the CLI and `CLAUDE.md`.

---

## 1. The Core Loop: Explore → Plan → Code → Verify

The single most important discipline is separating **understanding** from **execution**.

### 1.1 Explore

Goal: understand the current state of the codebase and requirements.

Typical actions:
- Ask Claude to summarize key parts of the repo
- Have it map dependencies or data flows
- Clarify ambiguous requirements, edge cases, and constraints

Example prompts:
- "Give me a high‑level map of this repo: apps, packages, and how they talk to each other."
- "Trace how a request flows from the HTTP entrypoint to the database for the `POST /api/orders` endpoint."

### 1.2 Plan

Goal: agree on a concrete, testable plan before touching code.

Ask Claude to:
- Propose a step‑by‑step checklist
- Identify which files will change
- Describe how to validate success

Prompt template:
> You are in plan mode. Do not edit files. Propose a plan to implement [feature]. Include: goal, files to inspect/change, and tests or manual checks. Keep it under 10 steps.

You should revise and approve this plan before moving on.

### 1.3 Code

Goal: implement *one small chunk* of the plan as a safe, reviewable diff.

Guidelines:
- Ask Claude to tackle only 1–2 steps at a time
- Require diff‑style output with short commentary
- Keep changes bounded to specific folders/files

Prompt template:
> Implement only step 1 of the approved plan. Show me the diff first, with a short explanation of any risky changes. Ask before running commands.

### 1.4 Verify

Goal: confirm reality matches expectations.

Actions:
- Run tests and linters
- Start the app and manually exercise new behavior
- Check logs, database, and external systems if relevant

Then report back:
- Paste failing test output or logs
- Describe any UX/UI mismatches

Prompt template:
> Here is the failing test output. Diagnose root cause and propose the smallest code change needed. Show only the diff.

Repeat the loop until the feature is complete, then move to the next thin slice.

---

## 2. Vibe-Coding a New Full-Stack App

This section walks through a concrete, repeatable pattern for building a new web app from scratch.

### 2.1 Kickoff and scaffolding

1. Create an empty directory and open a Claude Code session there.
2. Paste a vision‑level prompt:
   - What the app does
   - Who it is for
   - Target stack (for example, Next.js + Postgres + Prisma)
3. Ask Claude to:
   - Propose an architecture
   - List major components and pages
   - Suggest a minimal, shippable MVP

Then:
- Approve or edit the architecture
- Let Claude scaffold the project (using `create-next-app`, `pnpm`, etc.)

Example prompt:
> Propose the file/folder structure, data model, and initial pages for this app. Then, once we agree, scaffold the project using the official Next.js starter. Ask before running commands.

### 2.2 Building the first vertical slice

Focus on a single, end‑to‑end happy path, for example:
- Create an item (todo, note, meeting, document)
- Persist it
- Display it in a list

Workflow:
1. Use Explore/Plan to define exactly what this slice needs.
2. Implement backend API or server actions.
3. Implement UI components and routing.
4. Wire up the state management.
5. Add tests (unit + basic e2e where possible).

Keep all changes small enough to review.

### 2.3 Iterating with vibe coding

Once the first slice works, you can:
- Add more fields, filters, and views
- Improve design (ask Claude to refine CSS or Tailwind classes)
- Integrate auth, emails, or third‑party APIs

Each improvement should be a separate Plan → Code → Verify cycle.

Prompt ideas:
- "Make this page responsive for mobile and tablet, using our existing design language."
- "Add server‑side validation and clear error messages for this form." 
- "Refactor this module into smaller components without changing behavior."

---

## 3. Test-Driven Development (TDD) with Claude Code

You can combine vibe coding with a disciplined TDD loop.

### 3.1 TDD loop

1. Describe the behavior you want in natural language.
2. Ask Claude to write or update tests first.
3. Run the tests; confirm they fail for the right reason.
4. Ask Claude to implement the minimal code to make them pass.
5. Refactor with Claude’s help while keeping tests green.

Prompt template:
> We’re doing TDD. Based on the requirements below, write tests only. Do not change implementation yet. Use our existing test framework and conventions.

Then:
> The tests fail with this output. Implement the minimal code to make them pass. Show only the diff.

### 3.2 Where TDD is most valuable with AI

- Core domain logic and business rules
- Security‑sensitive paths (auth, permissions, financial calculations)
- Critical integrations (payments, external services)

TDD gives you confidence that aggressive refactors or AI‑generated code haven’t broken invariants.

---

## 4. Codebase Understanding, Refactors, and Migrations

Vibe coding is not only about greenfield work—it’s also powerful for understanding and evolving large, existing systems.

### 4.1 Mapping and documentation

Use Claude to:
- Generate high‑level architecture diagrams (in Markdown or Mermaid)
- Document modules and services
- Summarize legacy code paths

Prompt ideas:
- "Explain the responsibility of each module under `src/services/` and how they collaborate."
- "Generate a Mermaid diagram of the main request/response flow for the checkout process."

### 4.2 Safe refactoring

For refactors:
- Start with clear goals (for example, extract a module, remove duplication, upgrade a dependency)
- Ensure tests exist or have Claude help you add coverage first
- Use very small diffs, especially when renaming or moving files

Prompt template:
> Plan a safe refactor to [goal]. List preconditions (tests, backups), steps, and rollback strategy. Don’t change any code yet.

Then:
> Implement only step 1 of the refactor, ensuring tests stay green.

### 4.3 Large-scale migrations

For big changes (framework upgrades, breaking API changes):
- Do a discovery pass: have Claude enumerate all impacted modules
- Design a phased migration plan with feature flags or dual writes
- Use scripts and code mods that Claude helps generate, but run them under your control

Always gate large migrations behind CI and code review.

---

## 5. Collaboration Workflows: Claude + Git + CI

### 5.1 Branch-based development

A healthy pattern:
- Create a feature branch per task
- Let Claude work primarily on that branch
- Keep commits small and descriptive

You can:
- Ask Claude to draft commit messages
- Have it prepare PR descriptions, changelogs, and migration notes

Prompt ideas:
- "Summarize the diffs in this branch and propose a PR description with risks and testing steps."

### 5.2 GitHub Actions / CI integration

With Claude Code actions in CI, you can:
- Have Claude review PRs and suggest improvements
- Run automated tests, linting, and security scans on AI‑generated changes
- Gate merges on CI and human review

Pattern:
- Use CI for trust‑but‑verify
- Treat Claude’s comments as suggestions, not authority

### 5.3 Pairing with human teammates

Ways to combine human and AI effectively:
- Humans own architecture, constraints, and final reviewers
- Claude handles mechanical work: boilerplate, repetitive changes, documentation, test scaffolding
- Humans curate `CLAUDE.md`, commands, and skills over time

Set norms:
- Claude‑authored code is reviewed to the same standard as human code
- People are responsible for any changes they merge, regardless of who wrote them

---

## 6. Advanced Vibe Coding: Skills, Subagents, and Hooks (Preview)

Once basic workflows feel natural, you can layer advanced features:

- **Skills**: Capture complex workflows as reusable, auto‑triggered capabilities (for example, "build and deploy a preview environment for a feature branch").
- **Subagents**: Spin up specialized personas for tasks like performance tuning, security review, or documentation, each with its own prompt and allowed tools.
- **Hooks**: Run scripts automatically when Claude edits files or runs tools, for example, to:
  - Re‑run tests when certain directories change
  - Send observability events for multi‑agent monitoring
  - Enforce policies on sensitive paths

These advanced tools don’t change the core loop—they amplify it. You still work in Explore → Plan → Code → Verify cycles, but more and more of the routine work is encoded into automation.

The more deliberately you design your workflows, the more "vibe coding" turns from a chaotic experiment into a reliable, repeatable way to ship serious software with Claude Code at your side.
