---
name: Deploy Skills Workflow
description: GitHub Actions workflow that deploys all skills to a Claude workspace via the Skills API on merge to production
type: plan
status: completed
branch: feature/deploy-skills
related:
  - docs/designs/2026-03-25-deploy-skills-workflow.design.md
  - docs/context/skills-api-deploy-patterns.context.md
  - docs/research/2026-03-25-skills-api-upload.research.md
---

## Goal

Build a GitHub Actions workflow that deploys all skills from `skills/` to a
Claude organization workspace via the Skills API on every merge to
`production`.

## Scope

**Must have:**
- `.github/workflows/deploy-skills.yml` triggered on push to production
- `.github/scripts/deploy-skills.sh` handling all deployment logic
- Create-vs-update logic (list existing, match by display_title)
- Zip upload via Skills API multipart form
- Deployment summary output
- Feature branch → PR → merge to development
- CHANGELOG.md update with PR link

**Won't have:**
- Selective deployment (deploys all skills every time)
- Rollback automation
- Skill deletion when removed from repo
- The `production` branch itself (documented, created by org on fork)

## Approach

All work on feature branch `feature/deploy-skills` off `development`.
Build the deploy script first (independently testable with
`ANTHROPIC_API_KEY`), then the minimal workflow that calls it.

The deploy script:
1. Finds all `skills/*/SKILL.md` directories
2. Extracts `name` from SKILL.md YAML frontmatter for display_title
3. Zips each skill directory
4. Lists existing custom skills via API
5. Creates new version if skill exists, creates new skill if not
6. Reports results

## File Changes

| Action | Path |
|--------|------|
| create | `.github/workflows/deploy-skills.yml` |
| create | `.github/scripts/deploy-skills.sh` |
| modify | `CHANGELOG.md` |

## Tasks

- [x] **Task 1: Create feature branch** <!-- sha:n/a (branch only) -->
  Create `feature/deploy-skills` branch off `development`. Commit.
  **Verify:** `git branch --show-current` shows `feature/deploy-skills`.

- [x] **Task 2: Write deploy-skills.sh** <!-- sha:0e7297c -->
  Create `.github/scripts/deploy-skills.sh` that:
  - Requires `ANTHROPIC_API_KEY` environment variable
  - Discovers all skills in `skills/` with SKILL.md
  - For each skill: extracts name from YAML frontmatter, zips the
    directory, lists existing skills to find match, creates or updates
  - Uses correct API headers (x-api-key, anthropic-version, anthropic-beta)
  - Logs each deployment result (created/updated/failed)
  - Continues on individual skill failure (doesn't block others)
  - Outputs a summary at the end
  - Make executable
  Commit.
  **Verify:** `bash -n .github/scripts/deploy-skills.sh` passes syntax check.

- [x] **Task 3: Write deploy-skills.yml workflow** <!-- sha:0a5cb06 -->
  Create `.github/workflows/deploy-skills.yml` with:
  - Trigger: push to `production` branch
  - Permissions: contents read
  - Steps: checkout, run deploy-skills.sh with ANTHROPIC_API_KEY from secrets
  Commit.
  **Verify:** `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/deploy-skills.yml'))"` validates YAML.

- [x] **Task 4: Update CHANGELOG.md** <!-- sha:ff9425f -->
  Add entry for deploy-skills workflow under `## [Unreleased]`. Commit.
  **Verify:** `grep 'deploy-skills' CHANGELOG.md` returns match.

- [x] **Task 5: Create PR and merge** <!-- PR #3, sha:60e191e -->
  Push branch, create PR to development, merge, update CHANGELOG with
  PR link.
  **Verify:** PR merged; `git log development --oneline -1` shows merge.

## Validation

1. **Script syntax**: `bash -n .github/scripts/deploy-skills.sh` passes

2. **YAML syntax**: `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/deploy-skills.yml'))"` passes

3. **Workflow trigger**: YAML contains `push: branches: [production]`

4. **API headers**: Script contains all 3 required headers
   (`x-api-key`, `anthropic-version: 2023-06-01`, `anthropic-beta: skills-2025-10-02`)

5. **Create-vs-update logic**: Script contains both `POST /v1/skills`
   (create) and `POST /v1/skills/.*/versions` (update) patterns

6. **Error resilience**: Script continues deploying other skills when
   one fails (no `set -e` on curl calls or explicit error handling)

7. **No hardcoded org values**: `grep -r 'bcbeidel\|claude-automode' .github/scripts/deploy-skills.sh` returns no matches
