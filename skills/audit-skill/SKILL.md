---
name: audit-skill
description: Evaluates Claude Code skill directories for security and governance risk across 7 dimensions (permission scope, data exposure, prompt injection, blast radius, reversibility, semantic overlap, dependency risk). Produces a scorecard with overall LOW/MEDIUM/HIGH rating and remediation recommendations. Use when auditing a skill, reviewing a skill for security, or assessing skill risk before deployment.
---

# Skill Risk Audit

Evaluate any Claude Code skill directory for security and governance risk.
Produces a deterministic risk report with a scorecard, overall rating, and
actionable recommendations.

## Quick Start

When asked to audit a skill, follow the evaluation workflow below. The
target is always a skill directory containing a SKILL.md file.

## Evaluation Workflow

### Step 1: Accept Input

Accept the target skill directory path from the user. Confirm the path
contains a SKILL.md file. If not found, report an error.

### Step 2: Read Target Skill

Read all contents of the target skill directory:

1. Read the target SKILL.md — extract the `name` and `description` from
   YAML frontmatter, and the full instruction body.
2. List all files in the skill directory and subdirectories (references/,
   scripts/, etc.).
3. Read any additional files referenced in SKILL.md.
4. Read any scripts in scripts/ directory.

### Step 3: Extract Observable Facts

From the skill contents, identify and record:

- **Tools referenced:** Which Claude tools does the skill instruct to use?
  (Read, Glob, Grep, Edit, Write, Bash, Agent, WebFetch, WebSearch, etc.)
- **Command patterns:** What specific Bash commands are referenced?
  (git, npm, curl, python, etc.)
- **File access patterns:** What paths does the skill read or write?
  Scoped to its directory? Project-wide? Outside the project (../, ~/)?
- **Data handling:** Does the skill access env vars, config files, or
  credentials? Does it reference sensitive patterns (API_KEY, TOKEN,
  PASSWORD, SECRET)?
- **External references:** URLs, API endpoints, MCP tool references
  (ServerName:tool_name patterns).
- **Dependencies:** Package imports, install commands, external code.
- **Input sources:** Where does the skill get its input? User args, file
  contents, tool results, external URLs?
- **Output actions:** What does the skill do with its results? Report to
  user only, or write files, execute commands, send data?
- **Instruction patterns:** Any directives to ignore safety rules, hide
  actions, or alter behavior conditionally?

### Step 4: Score Each Dimension

Read the scoring rubric: [references/scoring-rubric.md](references/scoring-rubric.md)

For each of the 7 dimensions, match the observable facts from Step 3
against the rubric's indicator table. Select the score level whose
indicators best match what was found. Record:

- The score (1-5)
- The specific indicator that determined the score
- A one-sentence justification citing observable evidence

**Dimensions:**
1. Permission Scope
2. Data Exposure
3. Prompt Injection Surface
4. Blast Radius
5. Reversibility
6. Semantic Overlap
7. Dependency Risk

Check for auto-escalation conditions on each dimension (see rubric).

### Step 5: Compute Overall Rating

1. **Average:** Sum all 7 scores, divide by 7, round to one decimal.
2. **Escalation triggers:**
   - Any single score of 5 → at least MEDIUM
   - Any two scores of 4+ → HIGH
   - Anthropic high-concern combinations (code execution + network,
     instruction manipulation, hardcoded credentials) → at least MEDIUM
3. **Final rating:**
   - Average <= 2.0 AND no triggers → **LOW**
   - Average <= 3.5 AND no HIGH triggers → **MEDIUM**
   - Average > 3.5 OR HIGH triggers → **HIGH**

### Step 6: Generate Report

Read the report template: [references/report-template.md](references/report-template.md)

Generate the complete report following the template. Ensure:

- All 7 dimensions appear in the scorecard with scores and justifications
- Escalation triggers section is populated (or states "None")
- Recommendations provided for every dimension scoring 3 or higher
- Skill summary lists actual files, tools, and external references found
- Framework references footer is included

Present the report to the user.

## Important Rules

- **Score what you observe, not what you infer.** If the skill doesn't
  reference Bash, don't score it as if it might use Bash.
- **Cite evidence in justifications.** Not "this seems risky" but
  "SKILL.md references `curl` command on line 15."
- **Apply the rubric exactly.** Don't interpolate between levels. If the
  indicators for score 3 match but not score 4, the score is 3.
- **Check auto-escalation conditions.** These override normal scoring
  for specific high-risk patterns.
- **Be consistent.** The same skill must produce the same scores every
  time. Use only the observable criteria in the rubric.
