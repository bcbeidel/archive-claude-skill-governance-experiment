---
name: Skill Audit Workflow Design
description: GitHub Actions workflow that audits skills on PR changes, posts risk reports as comments, and enforces risk-based approval gates via commit status checks
type: design
status: approved
related:
  - docs/designs/2026-03-25-audit-skill.design.md
  - docs/prompts/plugin-governance-template.prompt.md
---

## Purpose

A GitHub Actions workflow that automatically audits skills on PR changes,
posts risk reports as comments, and enforces risk-based approval gates
via commit status checks.

## Behavior

1. **Trigger**: PR opened/synchronized/reopened against `development` or
   `production`, OR a pull request review is submitted
2. **Detect**: Compare PR branch against base — identify new/modified files
   under `skills/`. Group by skill directory (a skill = a directory
   containing SKILL.md)
3. **Skip**: If no skill files changed, post a comment "No skill changes
   detected" and set status check to success
4. **Audit**: For each changed skill, invoke Claude Code CLI:
   `claude -p "Audit the skill at <path> following the audit-skill workflow"`
   with the audit-skill available in the repo
5. **Post**: Post one consolidated PR comment with all audit reports. Update
   (edit) existing comment on re-runs rather than posting duplicates
6. **Gate**: For each audited skill, extract the overall rating. Determine
   required approvals: LOW=1, MEDIUM=2, HIGH=3. Take the maximum across all
   changed skills. Query current PR approval count via GitHub API. Set
   commit status `skill-audit/approval-gate` to success/failure based on
   whether approvals >= required
7. **Label**: Apply `risk:LOW`, `risk:MEDIUM`, or `risk:HIGH` label to the
   PR for visibility

## Components

- `.github/workflows/skill-audit.yml` — the workflow definition
- `.github/scripts/detect-skill-changes.sh` — detects changed skills from
  git diff
- `.github/scripts/post-audit-comment.sh` — posts/updates the PR comment
- `.github/scripts/check-approvals.sh` — queries approvals and sets commit
  status

## Constraints

- `ANTHROPIC_API_KEY` must be in GitHub Secrets
- Workflow must be idempotent — re-runs update existing comments, not
  duplicate
- The audit-skill is invoked as-is from the repo, not duplicated into the
  workflow
- No hardcoded org-specific values
- Status check name is consistent so branch protection can reference it

## Acceptance Criteria

1. PR with a new skill in `skills/` triggers the workflow and posts an
   audit report comment
2. PR with no skill changes posts "No skill changes detected" and passes
   the status check
3. Re-pushing to a PR updates the existing audit comment rather than
   posting a new one
4. Status check blocks merge when approvals < required for the risk level
5. Status check passes when approvals >= required
6. PR gets labeled with the correct risk level
