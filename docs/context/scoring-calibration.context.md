---
name: Scoring Calibration
description: Reference examples showing expected scores for skills with known risk profiles, anchoring scorer consistency
type: context
sources:
  - https://platform.claude.com/docs/en/agents-and-tools/agent-skills/enterprise
  - https://infosec.mozilla.org/guidelines/risk/rapid_risk_assessment.html
related:
  - docs/research/2026-03-25-llm-skill-risk-scoring.research.md
  - docs/context/scoring-methodology.context.md
  - docs/context/dimension-criteria.context.md
  - docs/designs/2026-03-25-audit-skill.design.md
---

## Calibration Purpose

Calibration examples anchor scoring consistency (per Mozilla Rapid Risk
Assessment methodology). Each example shows a skill profile, expected
per-dimension scores, and the reasoning. These same profiles will be
implemented as test skills for validation.

## Example A: Low-Risk Read-Only Skill

**Profile**: A skill that reads markdown files in a project directory and
produces a summary. Uses only Read and Glob tools. No scripts, no network
access, no external dependencies.

| Dimension | Score | Reasoning |
|-----------|-------|-----------|
| Permission Scope | 2 | Read-only tools (Read, Glob) |
| Data Exposure | 2 | Reads project files, outputs summary to user |
| Prompt Injection | 2 | Processes file paths (structured input) |
| Blast Radius | 1 | No side effects — pure analysis |
| Reversibility | 1 | Read-only operations |
| Semantic Overlap | 1 | Unique, well-scoped purpose |
| Dependency Risk | 1 | No external dependencies |

**Average: 1.4 → Rating: LOW**

No escalation triggers. This is the baseline for a safe, well-scoped skill.

## Example B: Medium-Risk File Editor

**Profile**: A skill that reformats code files according to a style guide.
Uses Read, Glob, Edit tools. Modifies files in the project directory.
No scripts, no network, no external deps.

| Dimension | Score | Reasoning |
|-----------|-------|-----------|
| Permission Scope | 3 | Uses Edit (file modification) |
| Data Exposure | 3 | Reads across project, outputs modified files |
| Prompt Injection | 3 | Processes user text (style preferences) but only edits |
| Blast Radius | 3 | Modifies files across the project |
| Reversibility | 2 | All edits in git-tracked directories |
| Semantic Overlap | 2 | Could overlap with linter/formatter skills |
| Dependency Risk | 1 | No external dependencies |

**Average: 2.4 → Rating: MEDIUM**

No escalation triggers, but average exceeds 2.0 threshold.

## Example C: High-Risk Deployment Skill

**Profile**: A skill that deploys code to production via shell commands.
Uses Bash (unrestricted), accesses environment variables for credentials,
makes network calls to external APIs. References MCP server tools. Has
scripts that install packages.

| Dimension | Score | Reasoning |
|-----------|-------|-----------|
| Permission Scope | 5 | Unrestricted Bash access |
| Data Exposure | 5 | Accesses credentials via env vars, transmits externally |
| Prompt Injection | 5 | Rule of Two: processes input + sensitive access + state change |
| Blast Radius | 5 | Deploys to external systems, broad impact |
| Reversibility | 5 | Deployments are difficult/impossible to reverse |
| Semantic Overlap | 1 | Unique deployment purpose |
| Dependency Risk | 5 | MCP refs, unpinned deps, external APIs |

**Average: 4.4 → Rating: HIGH**

Multiple escalation triggers: single 5 (→ MEDIUM), two 4+ (→ HIGH),
Anthropic high-concern patterns (code execution + network + credentials).

## Example D: The Audit-Skill Itself

**Profile**: The audit-skill reads a target skill directory and produces a
risk report. Uses Read, Glob, Grep tools. No scripts, no network, no
file modification. Accesses files outside its own directory (the target
skill) but only reads them.

| Dimension | Score | Reasoning |
|-----------|-------|-----------|
| Permission Scope | 2 | Read-only tools (Read, Glob, Grep) |
| Data Exposure | 3 | Reads files outside its own directory (target skill) |
| Prompt Injection | 3 | Reads untrusted skill content, but only analyzes (no actions) |
| Blast Radius | 1 | No side effects — produces a report |
| Reversibility | 1 | Read-only operations |
| Semantic Overlap | 1 | Unique audit purpose |
| Dependency Risk | 1 | No external dependencies |

**Average: 1.7 → Rating: LOW**

No escalation triggers. The audit-skill passes its own audit. Note that
Prompt Injection scores 3 (not higher) because while it reads untrusted
content, it does not act on it — it only analyzes and reports.

## Boundary Cases

These cases test scoring edge conditions:

- **Bash with only `git status`**: Permission Scope = 4 (Bash with
  constrained commands), not 5
- **Reads .env file but doesn't transmit**: Data Exposure = 4 (accesses
  env/config), not 5
- **MCP tool reference without network access**: Dependency Risk = 4
  (MCP auto-escalation), not 5
- **Broad description ("helps with code")**: Semantic Overlap = 4
  (likely to steal triggers from other skills)
