---
name: Skill Audit Workflow
description: GitHub Actions workflow that audits skills on PR changes, posts risk reports, and enforces approval gates
type: plan
status: completed
branch: feature/skill-audit-workflow
related:
  - docs/designs/2026-03-25-skill-audit-workflow.design.md
  - docs/context/claude-code-ci-invocation.context.md
  - docs/context/github-api-audit-patterns.context.md
  - docs/research/2026-03-25-skill-audit-workflow.research.md
---

## Goal

Build a GitHub Actions workflow that detects skill changes in PRs, invokes
the audit-skill via Claude Code CLI, posts risk reports as PR comments,
and enforces risk-based approval gates via commit status checks.

## Scope

**Must have:**
- `.github/workflows/skill-audit.yml` triggered on PR and review events
- `.github/scripts/detect-skill-changes.sh` to find changed skills
- `.github/scripts/post-audit-comment.sh` for idempotent PR comments
- `.github/scripts/check-approvals.sh` for approval gate enforcement
- Risk labeling (`risk:LOW`, `risk:MEDIUM`, `risk:HIGH`)
- Feature branch → PR → merge to development
- CHANGELOG.md update with PR link

**Won't have:**
- Deployment pipeline (Cycle 3)
- Branch protection configuration (Cycle 4 — documented, not enforced)
- Actual Claude Code invocation testing (requires secrets in CI)
- Third-party actions (use `gh` CLI for all GitHub API interactions)

## Approach

All work on feature branch `feature/skill-audit-workflow` off `development`.
Build scripts first (independently testable), then the workflow that
orchestrates them. Scripts use `gh` CLI for all GitHub API calls — no
third-party action dependencies.

The workflow has two jobs:
1. **audit** — triggers on `pull_request` events, detects changes, runs
   Claude Code CLI, posts the report comment, applies risk label
2. **approval-gate** — triggers on both `pull_request` and
   `pull_request_review` events, checks approval count against risk
   level, sets commit status

Key patterns from research:
- Claude Code CLI: `-p` flag + `--output-format json` + `--max-turns 10`
- Idempotent comments: hidden HTML marker `<!-- skill-audit-results -->`
- Approval counting: `gh api` with jq group-by-user-last-review pattern
- Commit status: `skill-audit/approval-gate` context string

## File Changes

| Action | Path |
|--------|------|
| create | `.github/workflows/skill-audit.yml` |
| create | `.github/scripts/detect-skill-changes.sh` |
| create | `.github/scripts/post-audit-comment.sh` |
| create | `.github/scripts/check-approvals.sh` |
| modify | `CHANGELOG.md` |

## Tasks

### Chunk 1: Helper Scripts

- [x] **Task 1: Create feature branch and directory structure** <!-- sha:609fcf1 -->
  Create `feature/skill-audit-workflow` branch off `development`. Create
  `.github/workflows/` and `.github/scripts/` directories. Commit.
  **Verify:** `ls .github/scripts/` and `ls .github/workflows/` succeed.

- [x] **Task 2: Write detect-skill-changes.sh** <!-- sha:1d3069a -->
  Create `.github/scripts/detect-skill-changes.sh` that:
  - Accepts `PR_NUMBER` and `REPO` as environment variables
  - Uses `gh api` to list PR changed files
  - Filters to files under `skills/` directory
  - Groups by skill directory (extracts unique `skills/<name>` paths)
  - Validates each detected path contains a SKILL.md
  - Outputs a newline-separated list of changed skill paths
  - Outputs empty string if no skills changed
  - Make executable (`chmod +x`)
  Commit.
  **Verify:** `bash -n .github/scripts/detect-skill-changes.sh` passes
  syntax check.

- [x] **Task 3: Write post-audit-comment.sh** <!-- sha:a662743 -->
  Create `.github/scripts/post-audit-comment.sh` that:
  - Accepts `PR_NUMBER`, `REPO`, and `BODY` as environment variables
  - Uses hidden HTML marker `<!-- skill-audit-results -->` for idempotency
  - Searches existing PR comments for the marker
  - If found, updates (PATCH) the existing comment
  - If not found, creates (POST) a new comment
  - Make executable
  Commit.
  **Verify:** `bash -n .github/scripts/post-audit-comment.sh` passes
  syntax check.

- [x] **Task 4: Write check-approvals.sh** <!-- sha:88551d0 -->
  Create `.github/scripts/check-approvals.sh` that:
  - Accepts `PR_NUMBER`, `REPO`, `SHA`, and `RISK_RATING` as env vars
  - Maps rating to required approvals: LOW=1, MEDIUM=2, HIGH=3
  - Queries PR reviews via `gh api`, groups by user, takes last review
    per user, counts APPROVED
  - Sets commit status `skill-audit/approval-gate` via `gh api`:
    - success if approvals >= required
    - failure if approvals < required
    - description includes approval count and requirement
  - Make executable
  Commit.
  **Verify:** `bash -n .github/scripts/check-approvals.sh` passes
  syntax check.

### Chunk 2: Workflow

- [x] **Task 5: Write skill-audit.yml workflow** <!-- sha:b74c9e6 -->
  Create `.github/workflows/skill-audit.yml` with:
  - Triggers: `pull_request` (opened, synchronize, reopened) on
    development/production branches + `pull_request_review` (submitted)
  - Permissions: contents read, pull-requests write, statuses write
  - **audit job** (runs on pull_request events only):
    1. Checkout repo
    2. Install Claude Code CLI via npm
    3. Run detect-skill-changes.sh
    4. If no skills changed: post "No skill changes" comment, set
       status to success, exit
    5. For each changed skill: invoke `claude -p` with audit prompt,
       capture JSON output, extract report and rating
    6. Consolidate reports into one comment body
    7. Run post-audit-comment.sh with consolidated body
    8. Determine max risk rating across all skills
    9. Apply risk label (remove old risk labels first)
    10. Run check-approvals.sh with max rating
  - **approval-gate job** (runs on pull_request_review events):
    1. Checkout repo
    2. Find existing audit comment to extract current risk rating
    3. Run check-approvals.sh to re-evaluate
  - Environment: `ANTHROPIC_API_KEY` from secrets, `GH_TOKEN` from
    `github.token`
  Commit.
  **Verify:** `python -c "import yaml; yaml.safe_load(open('.github/workflows/skill-audit.yml'))"` validates YAML syntax.

### Chunk 3: Finalization

- [x] **Task 6: Update CHANGELOG.md** <!-- sha:546b519 -->
  Add entry for the skill-audit workflow under `## [Unreleased]`.
  Commit.
  **Verify:** `grep 'skill-audit' CHANGELOG.md` returns a match.

- [x] **Task 7: Create PR and merge** <!-- PR #2, sha:a7ba0fc -->
  Push `feature/skill-audit-workflow` branch. Create PR to `development`.
  After merge, update CHANGELOG.md with PR link.
  **Verify:** PR is merged; `git log development --oneline -1` shows merge.

## Validation

1. **YAML syntax**: `.github/workflows/skill-audit.yml` parses as valid YAML
   (`python -c "import yaml; yaml.safe_load(open('.github/workflows/skill-audit.yml'))"`)

2. **Script syntax**: All 3 scripts pass `bash -n` syntax check

3. **Workflow triggers**: YAML contains both `pull_request` and
   `pull_request_review` triggers with correct event types

4. **Permissions block**: YAML contains `permissions` with `contents: read`,
   `pull-requests: write`, `statuses: write`

5. **Idempotent comment pattern**: `post-audit-comment.sh` contains the
   hidden marker `<!-- skill-audit-results -->` and both PATCH and POST
   code paths

6. **Approval gate logic**: `check-approvals.sh` maps LOW→1, MEDIUM→2,
   HIGH→3 and sets commit status with context `skill-audit/approval-gate`

7. **No hardcoded org values**: `grep -r 'bcbeidel\|claude-automode' .github/`
   returns no matches (org-agnostic)
