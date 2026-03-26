---
name: Governance Documentation Design
description: Complete README.md rewrite as single source of governance documentation, setup instructions, and usage guides
type: design
status: approved
related:
  - docs/prompts/plugin-governance-template.prompt.md
  - docs/designs/2026-03-25-audit-skill.design.md
  - docs/designs/2026-03-25-skill-audit-workflow.design.md
  - docs/designs/2026-03-25-deploy-skills-workflow.design.md
---

## Purpose

Finalize the template repository with a comprehensive README.md that serves
as the single source of documentation — governance policy, setup
instructions, and usage guides — so a new organization can fork, configure,
and have working skill governance within 30 minutes.

## Components

- `README.md` — complete rewrite covering:
  - Overview (what this template does)
  - Quickstart (fork, configure secrets, set branch protection)
  - Repository structure
  - Governance policy (branch protection, approval tiers, audit trail)
  - Step-by-step: Adding a new skill
  - Step-by-step: Reviewing an audit report
  - Step-by-step: Deploying to production

## Constraints

- Organization-agnostic — no hardcoded values, use placeholders
- Self-contained — a new org can set up from README alone
- README can exceed 800 words (acknowledged deviation, justified by scope)

## Acceptance Criteria

1. README contains quickstart with GitHub Secrets and branch protection setup
2. README contains governance policy (approval tiers, audit trail)
3. README contains step-by-step instructions for adding, reviewing, deploying
4. README contains repository structure overview
5. No hardcoded org-specific values
6. Self-contained — no required reading of other files to get started
