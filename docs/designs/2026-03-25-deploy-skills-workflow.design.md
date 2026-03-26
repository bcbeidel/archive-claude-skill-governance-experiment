---
name: Deploy Skills Workflow Design
description: GitHub Actions workflow that deploys all skills to a Claude organization workspace via the Skills API on merge to production
type: design
status: approved
related:
  - docs/designs/2026-03-25-skill-audit-workflow.design.md
  - docs/prompts/plugin-governance-template.prompt.md
---

## Purpose

A GitHub Actions workflow that deploys all skills from the `skills/`
directory to a Claude organization workspace via the Skills API on every
merge to `production`.

## Behavior

1. **Trigger**: Push to `production` branch (only via merged PRs given
   branch protection)
2. **Discover**: Find all skill directories in `skills/` (directories
   containing SKILL.md)
3. **For each skill**:
   - Zip the skill directory
   - List existing skills via `GET /v1/skills` to check if already
     exists (match by `display_title` derived from SKILL.md `name` field)
   - If exists: create new version via `POST /v1/skills/{id}/versions`
   - If new: create skill via `POST /v1/skills`
4. **Report**: Output a deployment summary showing each skill's status
   (created/updated/failed)

## Components

- `.github/workflows/deploy-skills.yml` — workflow definition
- `.github/scripts/deploy-skills.sh` — deployment logic

## Constraints

- `ANTHROPIC_API_KEY` must be in GitHub Secrets (workspace-scoped key)
- Beta headers required: `anthropic-beta: skills-2025-10-02`
- API version header: `anthropic-version: 2023-06-01`
- Max upload size: 8MB per skill
- No hardcoded org-specific values
- Skills that fail to deploy should not block other skills

## Acceptance Criteria

1. Workflow triggers only on push to `production` branch
2. Script discovers all skills in `skills/` with SKILL.md
3. Script handles both create (new skill) and update (new version) paths
4. Script uses correct API headers (api key, beta, version)
5. Failed skill deployments are logged but don't block other skills
6. Script is independently runnable with `ANTHROPIC_API_KEY` set
7. No hardcoded org values
