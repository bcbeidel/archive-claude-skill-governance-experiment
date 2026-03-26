---
name: Audit Skill Implementation
description: Build the audit-skill that evaluates Claude Code skills against 7 risk dimensions with deterministic scoring and governance-ready reports
type: plan
status: executing
branch: feature/audit-skill
related:
  - docs/designs/2026-03-25-audit-skill.design.md
  - docs/context/scoring-methodology.context.md
  - docs/context/dimension-criteria.context.md
  - docs/context/scoring-calibration.context.md
  - docs/research/2026-03-25-llm-skill-risk-scoring.research.md
---

## Goal

Build the audit-skill — a Claude Code skill that reads any skill directory,
scores it across 7 risk dimensions using a deterministic rubric, and produces
a governance-ready risk report. Include test skills for validation and
self-referential audit.

## Scope

**Must have:**
- `skills/audit-skill/SKILL.md` with evaluation instructions
- `skills/audit-skill/references/scoring-rubric.md` with full criteria
- `skills/audit-skill/references/report-template.md` with output format
- 3 test skills (low/medium/high risk) with known expected scores
- `_index.md` files per AGENTS.md conventions
- Feature branch → PR → merge to development
- CHANGELOG.md entry with PR link

**Won't have:**
- GitHub Actions workflows (Cycle 2)
- Deployment pipeline (Cycle 3)
- Governance documentation (Cycle 4)
- Python/shell scoring scripts
- Runtime analysis or external dependencies

## Approach

All work on a feature branch `feature/audit-skill` off `development`.
Create the audit-skill files first, then test skills, then validate.
The audit-skill uses progressive disclosure: SKILL.md contains the
evaluation workflow and points to reference files for detailed rubric
and report format.

Key design decisions (from research):
- Hybrid scoring: average + escalation triggers (not pure average)
- Criteria grounded in Anthropic enterprise risk tiers + OWASP
- Meta's Rule of Two for prompt injection scoring
- Calibration examples embedded in rubric for consistency

## File Changes

| Action | Path |
|--------|------|
| create | `skills/audit-skill/SKILL.md` |
| create | `skills/audit-skill/references/scoring-rubric.md` |
| create | `skills/audit-skill/references/report-template.md` |
| create | `skills/audit-skill/_index.md` |
| create | `skills/test-skills/low-risk-skill/SKILL.md` |
| create | `skills/test-skills/medium-risk-skill/SKILL.md` |
| create | `skills/test-skills/high-risk-skill/SKILL.md` |
| create | `skills/test-skills/_index.md` |
| create | `skills/_index.md` |
| create | `CHANGELOG.md` |

## Tasks

### Chunk 1: Audit Skill Core

- [x] **Task 1: Create feature branch and directory structure** <!-- sha:bc05b2e -->
  Create `feature/audit-skill` branch off `development`. Create directory
  structure: `skills/audit-skill/references/`, `skills/test-skills/`.
  Commit the empty structure.
  **Verify:** `ls skills/audit-skill/references/` succeeds.

- [x] **Task 2: Write scoring rubric reference** <!-- sha:a14c797 -->
  Create `skills/audit-skill/references/scoring-rubric.md` with the full
  7-dimension criteria from `docs/context/dimension-criteria.context.md`,
  scoring methodology from `docs/context/scoring-methodology.context.md`,
  and calibration examples from `docs/context/scoring-calibration.context.md`.
  This is the rubric the audit-skill reads during evaluation. Include
  framework citations (OWASP, NIST, Anthropic enterprise) for each dimension.
  Commit.
  **Verify:** File exists and contains all 7 dimensions with score tables.

- [x] **Task 3: Write report template reference** <!-- sha:c4d9655 -->
  Create `skills/audit-skill/references/report-template.md` defining the
  output format: header with skill name and date, scorecard table (dimension,
  score, justification), escalation triggers section, overall rating with
  explanation, per-dimension recommendations, framework references footer.
  Commit.
  **Verify:** File exists and contains the template structure.

- [x] **Task 4: Write audit-skill SKILL.md** <!-- sha:ac89ad6 -->
  Create `skills/audit-skill/SKILL.md` with:
  - YAML frontmatter (name: `audit-skill`, description per Anthropic
    conventions — third person, specific, includes trigger keywords)
  - Evaluation workflow: accept input path → read target skill directory
    → extract observable facts → read scoring rubric → score each dimension
    → apply escalation triggers → compute overall rating → generate report
    using template
  - References to `references/scoring-rubric.md` and
    `references/report-template.md` (one level deep, per best practices)
  - Keep SKILL.md body under 500 lines
  Commit.
  **Verify:** `head -5 skills/audit-skill/SKILL.md` shows valid YAML
  frontmatter with name and description fields.

### Chunk 2: Test Skills

- [x] **Task 5: Create low-risk test skill** <!-- sha:beab1a9 -->
  Create `skills/test-skills/low-risk-skill/SKILL.md` — a read-only
  skill that summarizes markdown files. Uses only Read and Glob. No
  scripts, no network, no external deps. Expected rating: LOW (avg ~1.4).
  Commit.
  **Verify:** File exists with valid YAML frontmatter.

- [x] **Task 6: Create medium-risk test skill** <!-- sha:c21a3fa -->
  Create `skills/test-skills/medium-risk-skill/SKILL.md` — a code
  formatting skill that uses Read, Glob, Edit. Modifies files across the
  project. No scripts, no network. Expected rating: MEDIUM (avg ~2.4).
  Commit.
  **Verify:** File exists with valid YAML frontmatter.

- [x] **Task 7: Create high-risk test skill** <!-- sha:1b598ac -->
  Create `skills/test-skills/high-risk-skill/SKILL.md` — a deployment
  skill using unrestricted Bash, accessing env vars for credentials,
  making network calls, referencing MCP tools, with external deps.
  Expected rating: HIGH (avg ~4.4).
  Also create `skills/test-skills/high-risk-skill/scripts/deploy.sh`
  (a stub script referencing curl, env vars, etc.) to make the risk
  indicators observable.
  Commit.
  **Verify:** File exists with valid YAML frontmatter; scripts/ dir exists.

### Chunk 3: Index Files and Finalization

- [x] **Task 8: Create _index.md files** <!-- sha:aefd425 -->
  Create index files per AGENTS.md conventions:
  - `skills/_index.md` — lists audit-skill and test-skills directories
  - `skills/audit-skill/_index.md` — lists SKILL.md and references/
  - `skills/test-skills/_index.md` — lists all 3 test skills
  Commit.
  **Verify:** All 3 _index.md files exist.

- [x] **Task 9: Create CHANGELOG.md** <!-- sha:0227bb0 -->
  Create `CHANGELOG.md` with initial entry for this cycle. Use format:
  `## [Unreleased]` section with the audit-skill addition. PR link will
  be added after PR creation.
  Commit.
  **Verify:** `head -10 CHANGELOG.md` shows valid changelog structure.

- [x] **Task 10: Create PR and merge** <!-- PR #1, sha:b065ef2 -->
  Push `feature/audit-skill` branch. Create PR to `development` with
  summary of changes. After merge, update CHANGELOG.md with the PR link.
  **Verify:** PR is merged to development; `git log development --oneline -1`
  shows the merge.

## Validation

After all tasks complete, validate against the design's acceptance criteria:

1. **Low-risk test produces LOW**: Invoke audit-skill against
   `skills/test-skills/low-risk-skill/` — report should show avg <= 2.0,
   overall LOW, no escalation triggers.

2. **High-risk test produces HIGH**: Invoke audit-skill against
   `skills/test-skills/high-risk-skill/` — report should show avg > 3.5,
   overall HIGH, multiple escalation triggers.

3. **Self-audit passes**: Invoke audit-skill against
   `skills/audit-skill/` — report should show LOW or MEDIUM rating.

4. **Report completeness**: Each report contains all 7 dimensions with
   scores (1-5), justifications, and at least one recommendation per
   elevated dimension.

5. **Determinism**: Run audit-skill against the same test skill twice —
   scores and overall rating must be identical.
