---
name: Audit Skill Design
description: Design spec for a Claude Code skill that evaluates skill directories against 7 risk dimensions and produces governance-ready risk reports
type: design
status: approved
related:
  - docs/prompts/plugin-governance-template.prompt.md
---

## Purpose

A Claude Code skill that evaluates any skill directory for security and
governance risk. It reads a target skill's SKILL.md and directory contents,
scores 7 risk dimensions using a deterministic rubric, and produces a
human-readable risk report with remediation recommendations.

## Behavior

1. **Input**: User provides a skill directory path (e.g., `skills/some-skill/`)
2. **Read**: Skill reads target directory — SKILL.md content, file listing of
   references/ and scripts/, any config files
3. **Extract**: Identify observable facts: tools referenced, permissions
   requested, external URLs/APIs, file system access patterns, data handling,
   dependencies
4. **Score**: Evaluate each of 7 dimensions against the rubric (1-5 scale)
5. **Rate**: Compute overall risk: LOW (avg <= 2), MEDIUM (avg <= 3.5),
   HIGH (avg > 3.5)
6. **Report**: Output markdown report with scorecard table, per-dimension
   justification, overall rating, and recommendations

## Components

- `skills/audit-skill/SKILL.md` — skill definition with evaluation instructions
- `skills/audit-skill/references/scoring-rubric.md` — detailed criteria per
  dimension per level (keeps SKILL.md focused, rubric in reference)
- `skills/audit-skill/references/report-template.md` — output format template
- `evals/test-skills/` — test skills with known risk profiles for validation:
  - `evals/test-skills/low-risk-skill/` — read-only, no network, no shell
  - `evals/test-skills/high-risk-skill/` — shell access, network, file writes,
    external deps
  - `evals/test-skills/medium-risk-skill/` — some file writes, limited scope

## Risk Dimensions

Each dimension scored 1-5 based on observable criteria:

| Score | Meaning |
|-------|---------|
| 1 | Minimal — no access/exposure in this dimension |
| 2 | Low — limited, well-scoped access |
| 3 | Moderate — some access with partial safeguards |
| 4 | Elevated — broad access or weak safeguards |
| 5 | Critical — unrestricted access or no safeguards |

### 1. Permission Scope
What tools/resources does the skill access?
- 1: No tool use beyond Read
- 2: Read-only tools (Read, Glob, Grep)
- 3: File modification tools (Edit, Write)
- 4: Bash with constrained commands
- 5: Bash with unrestricted shell access

### 2. Data Exposure
Can the skill read, transmit, or log sensitive data?
- 1: No data access beyond its own directory
- 2: Reads project files, no transmission
- 3: Reads project files, outputs summaries
- 4: Accesses environment variables or config files
- 5: Accesses credentials, secrets, or transmits data externally

### 3. Prompt Injection Surface
How vulnerable is the skill to injection via user input or tool results?
- 1: No external input processing
- 2: Processes structured input with clear boundaries
- 3: Processes user-provided text with some guardrails
- 4: Incorporates external content into prompts
- 5: Directly executes or evaluates user-provided content

### 4. Blast Radius
What is the worst-case impact if the skill misbehaves?
- 1: No side effects (read-only analysis)
- 2: Modifies files in a scoped directory
- 3: Modifies files across the project
- 4: Executes system commands or modifies config
- 5: Can affect external systems, deploy code, or delete data

### 5. Reversibility
Are the skill's actions reversible or destructive?
- 1: Pure read operations, fully reversible
- 2: File edits, reversible via git
- 3: Creates/deletes files, reversible with effort
- 4: System-level changes, partially reversible
- 5: Destructive or irreversible actions (force push, data deletion)

### 6. Semantic Overlap
Does the skill duplicate or conflict with existing skills?
- 1: Unique purpose, no overlap
- 2: Tangential overlap, clearly distinct
- 3: Partial overlap with clear differentiation
- 4: Significant overlap, consolidation recommended
- 5: Near-duplicate of existing skill

### 7. Dependency Risk
External dependencies, version pinning, supply chain concerns.
- 1: No external dependencies
- 2: References only built-in tools
- 3: Uses well-known, pinned dependencies
- 4: Uses external APIs or unpinned dependencies
- 5: Complex dependency chain or unvetted external code

## Overall Rating

- **LOW**: Average score <= 2.0
- **MEDIUM**: Average score <= 3.5
- **HIGH**: Average score > 3.5

## Constraints

- Rubric criteria must be observable from the skill directory — no runtime analysis
- Scoring must be reproducible: same skill, same scores across runs
- Reports must be understandable by a security reviewer unfamiliar with the skill
- No hardcoded org-specific values
- Follows AGENTS.md document conventions (frontmatter, _index.md per directory)

## Acceptance Criteria

1. Running audit-skill against `evals/test-skills/low-risk-skill/` produces LOW rating
2. Running audit-skill against `evals/test-skills/high-risk-skill/` produces HIGH rating
3. Running audit-skill against itself produces a passing report (LOW or MEDIUM)
4. Report contains all 7 dimensions with scores, justifications, and recommendations
5. Two consecutive runs against the same skill produce identical ratings
