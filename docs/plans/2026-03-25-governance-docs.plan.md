---
name: Governance Documentation
description: Complete README.md rewrite and docs/governance/ directory to finalize the template repository
type: plan
status: completed
branch: feature/governance-docs
related:
  - docs/designs/2026-03-25-governance-docs.design.md
---

## Goal

Write comprehensive README.md as the single source of governance
documentation, setup instructions, and usage guides. Create
docs/governance/ directory to satisfy the template output format.

## Scope

**Must have:**
- `README.md` complete rewrite (overview, quickstart, structure,
  governance policy, step-by-step guides)
- `docs/governance/_index.md` pointing to README sections
- CHANGELOG.md update with PR link
- Feature branch → PR → merge to development

**Won't have:**
- New code or scripts
- Separate governance guide (consolidated into README)
- Automated branch protection setup

## Approach

All work on feature branch `feature/governance-docs` off `development`.
README is the main deliverable. `docs/governance/` exists as a pointer
directory per the required output format.

## File Changes

| Action | Path |
|--------|------|
| modify | `README.md` |
| create | `docs/governance/_index.md` |
| modify | `CHANGELOG.md` |

## Tasks

- [x] **Task 1: Create feature branch** <!-- sha:n/a -->
  Create `feature/governance-docs` off `development`.
  **Verify:** `git branch --show-current` shows `feature/governance-docs`.

- [x] **Task 2: Write README.md** <!-- sha:d080f1d -->
  Complete rewrite of README.md with sections:
  - Overview (what the template does, one paragraph)
  - Quickstart (fork → configure secrets → branch protection → done)
  - Repository structure (file tree with descriptions)
  - Governance policy (branch protection settings, approval tiers,
    audit trail, status check)
  - Step-by-step: Adding a new skill
  - Step-by-step: Reviewing an audit report
  - Step-by-step: Deploying to production
  Organization-agnostic with placeholders where needed.
  Commit.
  **Verify:** `grep -c '##' README.md` shows at least 7 sections.

- [x] **Task 3: Create docs/governance/_index.md** <!-- sha:ea5a2e5 -->
  Create directory index pointing to README governance sections.
  Commit.
  **Verify:** File exists with valid YAML frontmatter.

- [x] **Task 4: Update CHANGELOG.md** <!-- sha:0ddf69a -->
  Add entry for governance documentation. Commit.
  **Verify:** `grep -i 'governance\|readme' CHANGELOG.md` returns match.

- [x] **Task 5: Create PR and merge** <!-- PR #4, sha:15fc13d -->
  Push branch, create PR to development, merge, update CHANGELOG
  with PR link.
  **Verify:** PR merged; `git log development --oneline -1` shows merge.

## Validation

1. **README sections**: README contains all required sections
   (overview, quickstart, structure, governance, adding skill,
   reviewing audit, deploying)

2. **Quickstart completeness**: README mentions `ANTHROPIC_API_KEY`,
   branch protection, and `skill-audit/approval-gate` status check

3. **Step-by-step guides**: README contains numbered steps for adding
   a skill, reviewing an audit, and deploying to production

4. **Repository structure**: README contains a file tree showing
   skills/, .github/, docs/, evals/

5. **No hardcoded values**: `grep -i 'bcbeidel\|claude-automode-experiment' README.md`
   returns no matches (except GitHub template references if needed)

6. **docs/governance/ exists**: Directory exists with _index.md
