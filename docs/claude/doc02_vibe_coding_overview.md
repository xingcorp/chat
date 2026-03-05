# Vibe Coding Overview and Mindset

## 1. Definition and History

- **Vibe coding** refers to building software by describing goals in natural language and letting an AI coding agent handle most of the implementation【634461890318456†L9-L18】.  The term was popularized in early 2025 and matured into a mainstream practice by 2026【634461890318456†L9-L18】.
- Unlike low‑code platforms, vibe coding still generates full source code—including backend, frontend and infrastructure—rather than visual block configurations【634461890318456†L79-L100】.

## 2. Benefits and Use Cases

- **Rapid prototyping and full‑stack generation:** AI accelerates scaffolding and boilerplate work, enabling you to build MVPs and internal tools quickly【887089587630106†L31-L48】.
- **Lower barrier to entry:** Non‑developers can turn ideas into working software, while developers focus on product vision and constraints【887089587630106†L120-L180】.
- **Best fit:** Greenfield projects, prototypes, features and tools that you can run and test frequently.  Avoid using vibe coding for safety‑critical systems unless you treat it purely as a design assistant.

## 3. Challenges and Responsibilities

- **Hallucinations and malicious packages:** AI may hallucinate code or install unsafe dependencies.  Human review, tests and security checks remain essential【149066924147065†L1379-L1452】.
- **Limited domains:** Vibe coding is less suitable for systems where correctness is paramount (healthcare, finance, infrastructure).  In such cases, use AI for design and documentation rather than execution.

## 4. Core Principles

- **Start from product vision:** Describe what you’re building, who it’s for and key user flows.  Provide tech stack and performance/security constraints up front【33647531426933†L179-L209】.
- **Work in vertical slices:** Deliver thin, end‑to‑end slices rather than building entire layers at once【33647531426933†L244-L279】.  Each slice should be testable and deployable.
- **Plan and explore before coding:** Use Plan Mode to explore the codebase, research patterns and design an implementation plan【190373145820492†L208-L229】.  Review and refine the plan before proceeding.
- **Think of Claude as a junior engineer:** Define direction and constraints, ask for explicit plans, and enforce tests and manual verification【33647531426933†L244-L279】.
- **Make constraints explicit:** Capture preferences and rules in `CLAUDE.md` and per‑session prompts; update them when you correct Claude【33647531426933†L244-L279】.
- **Close the loop:** For every slice, generate tests, run them locally and manually exercise the new behaviour.  Never accept untested code【33647531426933†L244-L279】.

## 5. New Capabilities (2026)

Recent releases expanded vibe coding with persistent tasks, planning tools and specialized agents.

### 5.1 Persistent Tasks

Claude Code 2.1.16 introduced **Tasks**, replacing per‑session to‑do lists with durable task graphs.  Tasks support directed acyclic graphs (DAGs) to enforce dependencies and are stored in `~/.claude/tasks`.  This allows multiple sessions and subagents to coordinate via the `CLAUDE_CODE_TASK_LIST_ID` environment variable【384420799970136†L31-L83】.  Tasks enable writer/reviewer patterns, ensure tasks are completed in order and persist across context clears【384420799970136†L86-L100】.

### 5.2 Plan Mode Enhancements

Plan Mode is Claude’s architectural planning feature.  It explores the codebase, researches best practices and produces a structured plan before any code is written【190373145820492†L208-L229】.  Use Plan Mode for features spanning multiple files, architectural decisions or complex refactors; skip it for simple edits.  It prevents wasted work, isolates exploration into specialized agents and offers structured decision‑making via multiple‑choice questions【190373145820492†L312-L337】.

### 5.3 Explore Agent

Explore Agent is a specialized agent that uses a faster, cheaper model to analyze codebases, map dependencies and answer architectural questions.  It isolates context so your main conversation stays focused, and provides comprehensive analysis across multiple files【190373145820492†L348-L367】.

### 5.4 Background Processes

Newer versions allow you to launch long‑running research tasks or background operations while continuing other work.  This fosters parallelism and helps maintain momentum in complex projects.

By following these principles and leveraging features like Tasks, Plan Mode and Explore Agents, you can transform vibe coding into a disciplined, repeatable way of shipping software.