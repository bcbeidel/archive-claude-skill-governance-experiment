# Scoring Rubric

Deterministic risk evaluation criteria for Claude Code skills. Each of 7
dimensions is scored 1-5 using observable indicators. The overall risk
rating uses a hybrid approach: average baseline with escalation triggers.

## Per-Dimension Scoring Scale

| Score | Label | Meaning |
|-------|-------|---------|
| 1 | Minimal | No access or exposure in this dimension |
| 2 | Low | Limited, well-scoped access |
| 3 | Moderate | Some access with partial safeguards |
| 4 | Elevated | Broad access or weak safeguards |
| 5 | Critical | Unrestricted access or no safeguards |

All criteria are observable from the skill directory contents — no runtime
analysis, no subjective judgment. Each level is defined by specific
indicators (tool references, file patterns, URL presence) that can be
verified by reading the skill's files.

---

## Dimension 1: Permission Scope

*Framework: Anthropic enterprise "Tool invocations" risk indicator, OWASP
LLM06:2025 Excessive Agency — Excessive Functionality*

What tools and resources does the skill instruct Claude to use?

| Score | Indicators |
|-------|-----------|
| 1 | No tool use beyond reading its own files |
| 2 | Read-only tools only (Read, Glob, Grep) |
| 3 | File modification tools (Edit, Write) scoped to specific paths |
| 4 | Bash with constrained commands (e.g., git, npm, specific CLIs) |
| 5 | Unrestricted Bash, or Bash without command constraints |

**How to evaluate:** Search SKILL.md and referenced files for tool names
(Read, Glob, Grep, Edit, Write, Bash), command patterns, and permission
requests. Check scripts/ directory for executable files.

---

## Dimension 2: Data Exposure

*Framework: Anthropic enterprise "Hardcoded credentials" and "File system
access scope" indicators, OWASP LLM02:2025 Sensitive Information Disclosure*

Can the skill access, transmit, or log sensitive data?

| Score | Indicators |
|-------|-----------|
| 1 | Accesses only files within its own skill directory |
| 2 | Reads project files in scoped directories, no external output |
| 3 | Reads across the project, outputs summaries to user |
| 4 | Accesses env vars, config files, or paths outside project (../) |
| 5 | Accesses credentials/secrets, or transmits data to external URLs |

**Auto-escalation:** Hardcoded API keys, tokens, or passwords found in
any skill file → automatic score 5.

**How to evaluate:** Check for path patterns (../, ~/, /etc/), environment
variable references ($ENV, process.env, os.environ), URL patterns (http://,
https://), and credential-like strings (API_KEY, TOKEN, PASSWORD, SECRET).

---

## Dimension 3: Prompt Injection Surface

*Framework: Anthropic enterprise "Instruction manipulation" indicator,
OWASP LLM01:2025 Prompt Injection, Meta's "Rule of Two"*

How vulnerable is the skill to injection via user input or tool results?

| Score | Indicators |
|-------|-----------|
| 1 | No external input; operates on static/known content only |
| 2 | Processes structured input with clear boundaries (e.g., file paths) |
| 3 | Processes user-provided text but does not act on it (analysis only) |
| 4 | Incorporates external content into reasoning AND has tool access |
| 5 | Processes untrusted input AND accesses sensitive data AND changes state |

**Meta's Rule of Two:** A skill satisfying more than 2 of these 3
properties automatically scores 5:
- (A) Processes untrusted/external input
- (B) Accesses sensitive systems or private data
- (C) Changes state or communicates externally

**Auto-escalation:** Directives to ignore safety rules, hide actions from
users, or alter behavior conditionally → automatic score 5.

**How to evaluate:** Identify input sources (user arguments, file contents,
tool results, URLs). Check whether the skill acts on external content
(writes files, runs commands) or only analyzes it.

---

## Dimension 4: Blast Radius

*Framework: OWASP ASI08 Cascading Failures, CSA Capabilities-Based Risk
Assessment (CBRA) Impact dimension*

What is the worst-case impact if the skill misbehaves?

| Score | Indicators |
|-------|-----------|
| 1 | No side effects — pure read/analysis |
| 2 | Modifies files in a single, scoped directory |
| 3 | Modifies files across the project |
| 4 | Executes system commands, modifies config, or affects git state |
| 5 | Can affect external systems, deploy code, send data, or delete broadly |

**How to evaluate:** Trace the skill's actions from input to output. What
is the maximum scope of changes? Does it touch files outside a single
directory? Can it execute arbitrary commands?

---

## Dimension 5: Reversibility

*Framework: CSA CBRA, Anthropic's deployment lifecycle guidance*

Are the skill's actions reversible or destructive?

| Score | Indicators |
|-------|-----------|
| 1 | Pure read operations — fully reversible by definition |
| 2 | File edits within git-tracked directories — reversible via git |
| 3 | Creates/deletes files or modifies untracked content — reversible with effort |
| 4 | System-level changes (env vars, installed packages, config) — partially reversible |
| 5 | Destructive/irreversible actions (force push, data deletion, external API calls with side effects) |

**How to evaluate:** Check what the skill modifies. Are changes in
git-tracked files? Does it touch system config, environment, or external
services? Could its actions be undone with `git checkout` alone?

---

## Dimension 6: Semantic Overlap

*No direct framework mapping — unique to skill governance*

Does the skill duplicate or conflict with existing skills?

| Score | Indicators |
|-------|-----------|
| 1 | Unique purpose, no tool or description overlap with other skills |
| 2 | Tangential overlap — shares some tools but clearly distinct purpose |
| 3 | Partial overlap — similar description keywords, some shared workflows |
| 4 | Significant overlap — could confuse skill selection, consolidation recommended |
| 5 | Near-duplicate of an existing skill |

**When auditing in isolation:** Score based on description specificity and
breadth. Overly broad descriptions (Anthropic warns these "steal triggers
from existing Skills") score higher. A description like "helps with code"
would score 4; "audits skill directories for security risk" would score 1.

**How to evaluate:** Read the description field. Is it specific enough to
trigger only for relevant queries? Compare tools used against common skill
patterns. Flag descriptions over 200 characters that try to cover too
many use cases.

---

## Dimension 7: Dependency Risk

*Framework: OWASP ASI04 Agentic Supply Chain Vulnerabilities, SLSA v1.0
Supply-chain Levels, OpenSSF Scorecard*

External dependencies, version pinning, supply chain concerns.

| Score | Indicators |
|-------|-----------|
| 1 | No external dependencies — uses only built-in Claude tools |
| 2 | References well-known, pinned packages available in the runtime |
| 3 | References external packages with version constraints |
| 4 | References external APIs, unpinned dependencies, or MCP server tools |
| 5 | Complex dependency chain, unvetted external code, or dynamic code loading |

**Auto-escalation:** MCP server references (ServerName:tool_name pattern)
→ automatic minimum score 4 (per Anthropic's "High concern" classification).

**How to evaluate:** Check scripts/ for import statements, package.json,
requirements.txt, or pip/npm install commands. Search SKILL.md for MCP
tool references (Name:tool pattern), external URLs, and API endpoints.

---

## Overall Risk Rating

### Step 1: Compute Average

Sum all 7 dimension scores and divide by 7. Round to one decimal place.

### Step 2: Apply Escalation Triggers

Check these conditions in order:
1. Any single dimension scoring **5** → overall is at least **MEDIUM**
2. Any two dimensions scoring **4 or higher** → overall is **HIGH**
3. Any dimension matching Anthropic's "High concern" combinations:
   - Code execution (Permission Scope 4-5) + network access (Data Exposure 4-5)
   - Instruction manipulation (Prompt Injection 5)
   - Hardcoded credentials (Data Exposure 5)
   → overall is at least **MEDIUM**

### Step 3: Final Rating

| Condition | Rating |
|-----------|--------|
| Average <= 2.0 AND no escalation triggers | **LOW** |
| Average <= 3.5 AND no HIGH escalation triggers | **MEDIUM** |
| Average > 3.5 OR HIGH escalation triggers | **HIGH** |

---

## Calibration Examples

These reference examples anchor scoring consistency.

### Low-Risk: Read-Only Summary Skill

A skill that reads markdown files and produces a summary. Uses only Read
and Glob. No scripts, no network, no external deps.

| Dimension | Score | Reasoning |
|-----------|-------|-----------|
| Permission Scope | 2 | Read-only tools (Read, Glob) |
| Data Exposure | 2 | Reads project files, outputs summary to user |
| Prompt Injection | 2 | Processes file paths (structured input) |
| Blast Radius | 1 | No side effects |
| Reversibility | 1 | Read-only operations |
| Semantic Overlap | 1 | Unique, well-scoped purpose |
| Dependency Risk | 1 | No external dependencies |

**Average: 1.4 → LOW** (no escalation triggers)

### Medium-Risk: Code Formatter Skill

A skill that reformats code using Read, Glob, Edit. Modifies files across
the project. No scripts, no network.

| Dimension | Score | Reasoning |
|-----------|-------|-----------|
| Permission Scope | 3 | Uses Edit (file modification) |
| Data Exposure | 3 | Reads across project, outputs modified files |
| Prompt Injection | 3 | Processes user text but only edits |
| Blast Radius | 3 | Modifies files across the project |
| Reversibility | 2 | All edits in git-tracked directories |
| Semantic Overlap | 2 | Could overlap with linter skills |
| Dependency Risk | 1 | No external dependencies |

**Average: 2.4 → MEDIUM** (no escalation triggers, average > 2.0)

### High-Risk: Deployment Skill

A skill using unrestricted Bash, env var credentials, network calls, MCP
tools, and external deps.

| Dimension | Score | Reasoning |
|-----------|-------|-----------|
| Permission Scope | 5 | Unrestricted Bash |
| Data Exposure | 5 | Credentials via env vars, external transmission |
| Prompt Injection | 5 | Rule of Two: all three properties |
| Blast Radius | 5 | Deploys to external systems |
| Reversibility | 5 | Deployments are irreversible |
| Semantic Overlap | 1 | Unique deployment purpose |
| Dependency Risk | 5 | MCP refs, unpinned deps, external APIs |

**Average: 4.4 → HIGH** (multiple escalation triggers)

### Self-Audit: The Audit Skill

The audit-skill reads target skill directories and produces reports. Uses
Read, Glob, Grep. No file modification, no network, no scripts.

| Dimension | Score | Reasoning |
|-----------|-------|-----------|
| Permission Scope | 2 | Read-only tools (Read, Glob, Grep) |
| Data Exposure | 3 | Reads files outside its own directory |
| Prompt Injection | 3 | Reads untrusted skill content, but only analyzes |
| Blast Radius | 1 | No side effects — produces a report |
| Reversibility | 1 | Read-only operations |
| Semantic Overlap | 1 | Unique audit purpose |
| Dependency Risk | 1 | No external dependencies |

**Average: 1.7 → LOW** (no escalation triggers)

---

## Boundary Cases

- **Bash with only `git status`**: Permission Scope = 4 (constrained), not 5
- **Reads .env but doesn't transmit**: Data Exposure = 4, not 5
- **MCP tool reference without network**: Dependency Risk = 4 (auto-escalation)
- **Broad description ("helps with code")**: Semantic Overlap = 4
