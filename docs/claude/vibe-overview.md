# Vibe Coding with Claude Code – Overview and Mindset

## 1. What is “vibe coding”?

"Vibe coding" is a conversational, outcome‑focused way of building software where you describe what you want in natural language and let an AI coding agent handle most of the implementation details.

Instead of starting from a detailed spec or architecture, you:
- Start from product vision and user experience
- Explore the space with the AI in natural language
- Iterate in short cycles, constantly running and testing the app

Claude Code is particularly well suited for this style because it:
- Lives in your terminal and can read/write your files and run commands
- Keeps lightweight, project‑specific memory via `CLAUDE.md`
- Has plan / explore modes and safety rails around file edits & shell commands

Used well, vibe coding feels like pairing with a strong junior–mid engineer who can generate large amounts of correct boilerplate and glue code, while you focus on direction, constraints, and review.

---

## 2. When vibe coding is a good fit

Vibe coding shines when:
- You have a clear *product outcome* but are flexible on implementation details
- The domain is familiar enough that you can review and judge the output
- You’re building greenfield apps, features, prototypes, or internal tools
- You can run and test the system frequently (web apps, CLIs, small services)

It is *not* a good fit when:
- The system is safety‑critical (medical, finance, infrastructure) and errors are unacceptable
- You can’t realistically run an end‑to‑end test environment
- You don’t have the experience to evaluate whether the design or code is acceptable

In those cases, use Claude more as a design assistant (for docs, diagrams, and suggestions) and keep humans in control of final code.

---

## 3. Core principles of vibe coding with Claude Code

### 3.1 Start from product vision, not implementation

Begin with a prompt that describes:
- What you’re building (one paragraph)
- Who it is for and the key user flows
- Constraints that matter (stack, hosting, performance, security basics)

Example opening message (you paste this into Claude Code after opening the repo directory):

> I want to build a web app that lets small teams create and share AI‑assisted meeting notes. The core flows are: create a meeting, upload audio or paste a transcript, generate structured notes and action items, and share a read‑only link.
> 
> Constraints: Next.js 15 + React, Postgres, Prisma, Tailwind. Host on Vercel with a single Postgres instance. I care about fast page loads and simple deployments.
> 
> Before writing any code, propose a step‑by‑step plan and an initial slice we can ship in a day.

You then review and refine the plan *before* any code changes.

### 3.2 Work in vertical slices

Instead of building "the whole backend" or "all auth" at once, slice features vertically:
- A minimal end‑to‑end slice that a user can actually use
- Then incremental improvements (validation, better UI, extra flows)

Ask Claude to always aim for a single thin vertical, for example:

> Let’s ship a first vertical slice: a page where I can create a meeting with a title and description, store it in the database, and list existing meetings. Keep the implementation minimal but production‑ready.

### 3.3 Use Plan Mode and small diffs

Vibe coding is *not* "dump a paragraph and let the model rewrite your repo".

Best practice is:
- Use explore / plan mode to have Claude read files, inspect the codebase, and propose an approach
- Only then approve specific edits
- Keep each change to a manageable diff (for example, a few files or a single feature), so you can review it yourself

Whenever Claude proposes a big change, push it to break the work into smaller, reviewable steps.

### 3.4 Treat Claude as a junior engineer you trust but verify

Mentally model Claude Code as:
- Fast at boilerplate, wiring, and repetitive refactors
- Pretty good at architecture and design suggestions
- Fallible on edge cases, security, performance, and long‑range consequences

So your job becomes:
- Define direction and constraints
- Ask for explicit plans and reasoning before edits
- Enforce tests and manual verification
- Reject or adjust anything that doesn’t meet your standards

### 3.5 Keep constraints and preferences explicit

Vibe coding fails when expectations live only in your head.
Capture your preferences in two places:
- A well‑maintained `CLAUDE.md` with project‑level guardrails (architecture, code style, testing, deployment)
- Per‑session instructions in your prompts (for example, "use small diffs", "ask for confirmation before running migrations")

Update `CLAUDE.md` whenever you correct Claude on something you *never* want it to do again.

### 3.6 Always close the loop with tests and manual checks

For every slice:
- Ask Claude to generate or update tests
- Run the tests yourself
- Manually exercise the UI or API as a user

Never accept "looks good" without:
- Running commands locally
- Checking logs / console
- Confirming that behavior matches your original vision

---

## 4. Practical vibe coding workflows

### 4.1 A basic vibe coding loop

1. **Open Claude Code in your project directory** (or let it initialize a new one).
2. **Describe the product vision and constraints**.
3. **Ask for a plan and first thin vertical slice**.
4. **Approve or edit the plan** until the next step feels unambiguous.
5. **Have Claude implement that slice** (with plan mode and small diffs).
6. **Run tests and the app locally**, report issues back to Claude.
7. **Iterate** until that slice feels shippable.
8. **Repeat** for the next slice.

You can keep this loop going all day; Claude will accumulate context from your feedback and `CLAUDE.md`.

### 4.2 Example prompts for common moments

- Kickoff after vision:
  > Summarize the requirements in your own words, then propose a 5–7 step plan. For each step, include: goal, files likely to change, and how we’ll test it.

- Before edits:
  > You’re in plan mode. Read the relevant files and refine the plan for the next slice, but don’t edit anything yet. Show me a checklist I can approve.

- During implementation:
  > Implement only step 1 of the checklist. Show me the diff only, with brief comments on risky parts. Ask before running any commands.

- After a failed run:
  > Here is the error and stack trace from `npm test`. Diagnose the root cause, then propose the smallest code change that fixes it. Again, show me a diff only.

- When things drift:
  > Compare the current implementation against our original vision and constraints. List any mismatches or shortcuts we took. Suggest a prioritized cleanup list.

---

## 5. Guardrails and anti‑patterns

### 5.1 Guardrails to put in place

- **Never accept large, unreviewed diffs.** Keep changes small enough that you can read them in a few minutes.
- **Pin key technologies early.** Specify the framework, language version, and major libraries to avoid churn.
- **Protect critical files.** Tell Claude not to touch specific configs, infra code, or legacy modules without explicit permission.
- **Enforce tests.** Make it a rule that any new behavior must be covered by tests or at least a documented, manual test plan.
- **Reset context periodically.** For long sessions, summarize the current state and restart Claude with a fresh context plus `CLAUDE.md` and your latest docs.

### 5.2 Common failure modes

- **One giant prompt, one giant change.** Asking for "build the entire app" in one shot usually yields brittle, hard‑to‑debug code.
- **No `CLAUDE.md`.** Without persistent project instructions, you waste time re‑teaching the same constraints every session.
- **Letting Claude design the system with zero review.** You should *always* review architectures, data models, and APIs before they get baked into code.
- **Treating AI output as automatically correct.** Even strong models hallucinate, misread requirements, or miss edge cases.
- **Under‑specifying non‑functional requirements.** If you care about performance, accessibility, observability, or security, state that upfront and keep repeating it.

---

## 6. Leveling up your vibe coding

Once you’re comfortable with the basics, you can:
- Introduce **subagents** for specialized tasks (security review, test writing, documentation)
- Use **skills** to encode reusable workflows (for example, a skill that always sets up Next.js + Tailwind + auth in your preferred way)
- Orchestrate **agent teams** for parallel work on large codebases (for example, multiple agents reviewing different services in parallel)
- Add **hooks** and CI integration so Claude’s work is automatically linted, tested, and surfaced in PRs

The mindset stays the same: you are the lead; Claude and its agents are fast, capable collaborators. Vibe coding is about turning your intent and feedback into working software as directly as possible, while keeping enough structure and discipline that you trust what you ship.
