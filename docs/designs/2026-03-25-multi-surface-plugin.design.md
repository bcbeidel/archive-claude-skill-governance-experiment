---
name: Multi-Surface Plugin Design
description: Restructure repo as a Claude Code plugin with automated delivery to Claude Code, Claude API, and claude.ai via ZIP artifacts
type: design
status: approved
related:
  - docs/designs/2026-03-25-deploy-skills-workflow.design.md
  - docs/designs/2026-03-25-governance-docs.design.md
---

## Purpose

Restructure the repository as a Claude Code plugin with multi-surface
deployment support. A single `skills/` directory serves as the source of
truth, with automated delivery to Claude Code (plugin install), Claude API
(deploy pipeline), and claude.ai (ZIP artifacts for manual org upload).

## Components

- `.claude-plugin/plugin.json` — plugin manifest
- `.github/scripts/package-skills.sh` — generates ZIPs for claude.ai
- `.github/workflows/release.yml` — git tag triggers GitHub Release with ZIPs
- Updated `.github/scripts/deploy-skills.sh` — orphan reconciliation
- Updated `README.md` — all three distribution paths

## Behavior

**Plugin install (Claude Code):** Users run `/plugin install` from
marketplace. Skills auto-discover. Version from `plugin.json`.

**API deployment (Claude API):** Existing pipeline on production merge.
Deploy script warns about orphans, `--delete-orphans` flag for removal.

**ZIP artifacts (claude.ai):** Git tag → release workflow → ZIPs attached
to GitHub Release. Org Owners download and upload via admin UI.

**Orphan reconciliation:** Deploy script compares API skills against repo.
Default: warn. `--delete-orphans`: delete versions then skill.

## Constraints

- Manual semver in `plugin.json`
- ZIPs must have SKILL.md at root
- Orphan deletion: delete all versions first (API constraint)
- No hardcoded org values

## Acceptance Criteria

1. Repo installable as Claude Code plugin (`--plugin-dir .` works)
2. `package-skills.sh` generates valid ZIPs with SKILL.md at root
3. Git tag triggers release workflow with ZIP artifacts
4. Deploy script warns about orphaned skills
5. Deploy script with `--delete-orphans` removes orphans
6. README documents all three distribution paths
7. No existing functionality broken
