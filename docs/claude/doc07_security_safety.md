# Security and Safety in Claude Code

Using Claude Code effectively requires balancing power with caution.  This document summarises known security vulnerabilities affecting Claude Code, outlines best practices for hardening your environment and describes Anthropic’s security initiatives.

## Recent vulnerabilities and threats

Several supply‑chain and configuration vulnerabilities were disclosed in 2025–2026:

* **Malicious hooks and settings files** – Attackers could insert malicious shell commands into `.claude/settings.json` or hook scripts, causing remote code execution (RCE) when a repository is opened.  Projects cloned from untrusted sources could run arbitrary commands on the developer’s machine【334875101490523†L65-L76】.  Because these configuration files are automatically executed, API tokens and SSH keys could be exfiltrated via attacker‑controlled endpoints【998955037999592†L61-L87】.
* **MCP configuration hijacking** – A crafted `.claude/mcp.json` could redirect API calls to an attacker’s server, leaking secrets or enabling command injection【998955037999592†L91-L104】.  The configuration could be modified by any user with repository access, so forking a malicious project posed a silent risk【837344021841258†L138-L165】.
* **Hook bypass vulnerabilities** – CVE‑2025‑59356, CVE‑2025‑59536 and CVE‑2026‑21852 allowed attackers to trigger untrusted hooks without user approval and to bypass domain restrictions in WebFetch calls【14909062715458†L184-L215】.  These issues could lead to device takeover and API key theft【14909062715458†L219-L223】.

Security researchers stressed that these vulnerabilities highlight a new attack surface: configuration files in AI‑assisted development environments.  They urged developers to review changes to `.claude/` directories in pull requests and to keep their Claude Code installation up to date【118489271314982†L246-L297】.

## Best practices for safe vibe coding

To mitigate risks while using Claude Code and multi‑agent patterns:

* **Audit repositories before opening them.** Examine `.claude/` files (`settings.json`, `hooks/`, `mcp.json`, `agents/`, `skills/`) for unexpected commands or network calls.  Delete or neutralise untrusted hooks.  Never run Claude on a repository you haven’t audited.

* **Update Claude Code regularly.** Anthropic quickly patched the disclosed vulnerabilities; running the latest version ensures you receive security fixes【118489271314982†L300-L317】.

* **Use sandboxes and feature branches.** Work in isolated containers, devcontainers or temporary VMs.  Use feature branches to separate work from the main branch and to limit blast radius【103746295110896†L141-L155】.  Do not point Claude at production secrets or configuration.

* **Protect secrets.** Never paste API keys or passwords into chat.  Manage secrets via environment variables, secret stores or your platform’s secret manager.  If Claude needs to interact with external services via MCP, pass only the scopes and credentials it genuinely needs【103746295110896†L141-L155】.

* **Define and enforce permissions.** In `settings.json`, configure whether Claude must ask before editing files, creating new files or running shell commands.  Use pre‑tool hooks to deny dangerous operations (e.g. `rm -rf /`, `terraform apply` in prod).  For multi‑agent setups, restrict each agent’s tool set to the minimum necessary【103746295110896†L112-L139】.

* **Protect critical directories.** Mark infrastructure code, secret management, and other sensitive areas as off‑limits in `CLAUDE.md` and prompts.  Use hooks or CI to block modifications to these paths【118489271314982†L246-L297】.

* **Human approval for destructive actions.** Require manual approval before running migrations, deleting data, modifying infrastructure or sending external notifications.  Hooks can pause execution and ask for confirmation, or you can instruct Claude in your prompts to always require confirmation for certain commands【149066924147065†L1379-L1452】.

* **Observability and logging.** Use hooks to emit telemetry whenever Claude runs a tool.  Store these events in a log system so you can audit what actions were taken.  For multi‑agent systems, tag agent runs with metadata (team, task) and capture the prompts and diffs for later analysis【103746295110896†L112-L139】.

* **Secure your host environment.** Use OS‑level security features such as user namespaces, file permissions and network isolation.  Consider running Claude in a dedicated user account or container with limited access to the filesystem.  Keep your operating system and package manager up to date.

## Claude Code Security tool

In response to the growing complexity of AI‑assisted development, Anthropic introduced **Claude Code Security**.  This capability (available in limited research preview) scans codebases for vulnerabilities and proposes patches for human review.  Unlike traditional static analysis tools, it uses reasoning to understand cross‑file flows and business logic【391103500277547†L41-L63】.  The system found over 500 high‑severity vulnerabilities in testing and assigns severity ratings to surface the most important issues【177227847432786†L105-L115】.  It works by:

* Performing multi‑stage analysis to reduce false positives
* Reasoning about complex flows (injection, auth bypass, logic errors, memory corruption) that pattern‑matching tools miss【420680558206507†L146-L176】
* Producing a dashboard and proposed patches that require human approval before application【391103500277547†L41-L63】

Although promising, Claude Code Security does not replace your existing security tooling.  Use it to augment static analysis and manual review.  Continue to run vulnerability scanners, dependency checkers and penetration tests.  Monitor evolving research on AI‑assisted security: some analysts caution that new AI tools can create market hype and inadvertently overlook blind spots such as runtime vulnerabilities and CI/CD prompt injection【177227847432786†L116-L129】.

## Cultural practices and human responsibility

No security tool can replace human judgement.  As GuidePoint Security notes, AI hallucinations and malicious package suggestions remain a risk; developers are ultimately responsible for validating code and securing their systems【149066924147065†L1379-L1452】.  To build a security‑aware culture:

* Teach your team about the risks of AI‑generated code.  Require code review and verification for all AI‑authored changes.
* Document security standards in `CLAUDE.md`, and update them as new threats emerge.
* Encourage the habit of “trust, but verify” when working with AI assistants.
* Establish a post‑incident process that uses skills and tasks to generate timelines and root‑cause analyses, ensuring you learn from security incidents and improve your guardrails over time.

By combining technical hardening with cultural practices, you can leverage Claude Code safely.  Stay informed about the evolving threat landscape, audit your tools and configurations, and treat AI as a powerful collaborator—not an infallible security oracle.