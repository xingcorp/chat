# Claude Code Setup & Environment Hardening

This guide focuses on getting your environment ready for serious vibe coding with Claude Code: installing the CLI, configuring project memory, and putting basic safety rails in place.

---

## 1. Install Claude Code and prerequisites

### 1.1 Accounts and access

- Create or sign in to an Anthropic account with access to Claude 4.x models.
- If you plan to use Claude Code heavily, ensure you have an appropriate billing setup or team / enterprise plan so you do not hit low free‑tier limits mid‑session.

### 1.2 CLI installation

Claude Code is distributed as an npm package.

Basic installation:
```bash
npm install -g @anthropic-ai/claude-code
```

Requirements:
- Node.js 18+ (LTS or newer)
- A shell environment Claude can use (bash, zsh, fish, PowerShell; on Windows, WSL is recommended for a smoother dev experience)

Update periodically:
```bash
claude update
```

### 1.3 Authenticate the CLI

Claude Code can authenticate against:
- Your Anthropic account (interactive login)
- Or an API key via environment variable

Interactive login (good for personal machines):
```bash
claude auth login
```
Follow the browser‑based flow.

API key (better for CI or shared devcontainers):
```bash
export ANTHROPIC_API_KEY="your-key-here"
claude auth status
```

Verify authentication before long sessions.

---

## 2. Project structure and `CLAUDE.md`

Claude Code relies heavily on `CLAUDE.md` files to carry project knowledge across sessions.

### 2.1 Generate an initial CLAUDE.md

From your project root, run:
```bash
claude
```
Then, inside the Claude Code session:
```text
/init
```

Claude will scan the repo to detect:
- Language(s), frameworks, and build tools
- Test frameworks and commands
- Obvious entrypoints and tooling

It will then propose a `CLAUDE.md`. Review and edit this file manually—treat it as important as `README.md`.

### 2.2 What to put in root `CLAUDE.md`

Keep it short, but high‑leverage:
- One‑line project description and high‑level architecture
- Tech stack (framework versions, language versions, major libraries)
- Canonical commands for:
  - Installing dependencies
  - Running tests
  - Running the dev server
  - Building for production
- Code style rules that differ from defaults (formatters, linting rules, naming conventions)
- Repository etiquette (branch naming, commit message style, PR conventions)
- Critical "gotchas" and non‑obvious behavior

Example skeleton:
```markdown
# Project

This is a multi‑tenant SaaS app built with Next.js 15, Prisma, and Postgres.

## Commands

- Install: pnpm install
- Dev: pnpm dev
- Test: pnpm test
- Lint: pnpm lint

## Code Style

- TypeScript only, no `any` unless unavoidable
- Use functional React components with hooks
- Prefer server components where possible

## Testing

- All new features require tests in `__tests__` or `*.test.tsx`

## Gotchas

- `TENANT_ID` must be set in env or requests will fail
- Database migrations must be run via `pnpm prisma migrate deploy`
```

### 2.3 Hierarchies of CLAUDE.md

For larger repos, use multiple levels:
- `~/CLAUDE.md` – your personal, global preferences for all projects
- `/repo/CLAUDE.md` – project‑level rules and context
- `/repo/apps/api/CLAUDE.md` – service‑specific rules

Claude automatically loads relevant files based on the current working directory. Keep each one concise and specific to its scope.

### 2.4 Local‑only overrides

For machine‑local preferences (API keys, paths, experimental flags):
- Use `CLAUDE.local.md` in the project root or home directory
- Add it to `.gitignore`

Put anything here that should never be committed but that Claude should still know while working locally.

---

## 3. Core configuration: `.claude/settings.json`

Claude Code uses a `.claude` directory at your project root for deeper configuration.

Typical layout:
```text
.claude/
  settings.json
  commands/
  hooks/
  agents/
  skills/
  rules/
```

Key `settings.json` fields to consider:

- **Model defaults**
  - Choose a default model per repo, for example:
    - Opus / Sonnet for complex reasoning & architecture
    - Haiku for fast, repetitive tasks or observability summarization

- **Safety / permissions**
  - Whether Claude must ask before:
    - Editing files
    - Creating/deleting files
    - Running shell commands
  - For normal development, keep prompts for shell execution on; only disable in tightly sandboxed environments.

- **Experimental features**
  - Plan mode defaults
  - Agent teams (if enabled in your version)
  - Remote control / integration with desktop or web clients

Use settings to standardize behavior across your team so every developer sees the same Claude behavior in a given repo.

---

## 4. Hardening your environment for safe vibe coding

### 4.1 Work in sandboxes and branches

- Use feature branches per task or experiment
- For riskier operations, work inside containers, devcontainers, or disposable VMs
- Avoid pointing Claude at production configuration or secrets

### 4.2 Secrets management

Never paste secrets into chat.

- Keep secrets in `.env` files managed by your normal tooling
- Tell Claude which keys exist and what they conceptually do, *without* revealing values
- For MCP servers or external tools, pass API keys via environment or secret stores, not plaintext in `settings.json`

### 4.3 File and directory protections

In `CLAUDE.md` and prompts, mark critical areas as protected, for example:

> Never modify files in `infra/terraform` or `k8s/` unless I explicitly ask you to.

You can also:
- Add hooks that validate or block changes to certain paths
- Use CI to enforce that only humans (or specific workflows) can modify infra code

### 4.4 Command execution guardrails

Establish norms such as:
- Claude must always show commands before running them
- Destructive commands (like `rm`, `drop`, `terraform apply`, `kubectl delete`) require explicit confirmation
- Database migrations must be run in a controlled way (local vs staging vs production)

Capture this both in `CLAUDE.md` and in your own responses.

---

## 5. Integrating editors, MCP, and external tools

### 5.1 Editor integration

Claude Code can pair well with IDEs like VS Code, Cursor, or JetBrains:
- Run Claude Code in a terminal pane alongside your editor
- Use the editor for fine‑grained edits and navigation
- Let Claude handle bulk diffs, scaffolding, and repetitive changes

If you use an editor‑native Anthropic integration, decide when to use:
- The IDE assistant (for small, local edits)
- The Claude Code CLI (for repo‑wide operations, planning, and automation)

### 5.2 MCP (Model Context Protocol)

MCP servers let Claude call external tools (APIs, databases, SaaS products) via a standard protocol.

Basic pattern:
- Configure MCP servers in `.claude/mcp.json` or `settings.json`
- Give Claude clear instructions in `CLAUDE.md` about how and when to use each server
- Use least privilege: give MCP servers only the scopes and APIs they genuinely need

MCP is powerful for vibe coding workflows like:
- Syncing with issue trackers (Linear, Jira, GitHub)
- Running observability queries (logs, traces, metrics)
- Orchestrating external workflows (automation tools, CI, cloud APIs)

### 5.3 Hooks, commands, and plugins (high‑leverage add‑ons)

As your setup matures, add:
- **Slash commands** – repeatable workflows ("/sprint", "/develop", "/ship")
- **Hooks** – scripts that run on lifecycle events (before/after tool use, before edits, etc.)
- **Plugins** – packages of commands, hooks, skills, and settings you can reuse across repos

These all live under `.claude/` and make your environment feel more like a programmable editor than a generic chat.

---

## 6. Team‑level standards

For teams using Claude Code together:

- Store `.claude/` (minus machine‑local secrets) in version control so everyone shares:
  - Commands
  - Hooks
  - Agent definitions
  - Skills and rules

- Document expectations in `CLAUDE.md`:
  - When to use Claude vs manual coding
  - How to treat Claude‑authored code in reviews
  - Minimum test and documentation standards

- Consider a recurring practice (weekly or sprintly) to:
  - Review and refine `CLAUDE.md`
  - Prune unused commands/agents/skills
  - Capture new patterns that worked well into reusable automation

With a solid setup, vibe coding sessions feel less like experiments and more like working with a well‑integrated, configurable teammate that knows your project and respects your guardrails.
