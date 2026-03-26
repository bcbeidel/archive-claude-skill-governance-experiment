---
name: Multi-Surface Plugin
description: Restructure repo as Claude Code plugin with multi-surface deployment to Claude Code, Claude API, and claude.ai
type: plan
status: completed
branch: feature/multi-surface-plugin
related:
  - docs/designs/2026-03-25-multi-surface-plugin.design.md
---

## Goal

Restructure the repo as a Claude Code plugin with automated delivery to
all three surfaces: Claude Code (plugin install), Claude API (deploy
pipeline), and claude.ai (ZIP artifacts via `make package`).

## Scope

**Must have:**
- `.claude-plugin/plugin.json` manifest
- `Makefile` with `package` target generating ZIPs in `dist/`
- Updated `deploy-skills.sh` with orphan reconciliation
- `.github/workflows/release.yml` triggered by git tags
- Updated `README.md` with all three distribution paths
- CHANGELOG.md update with PR link

**Won't have:**
- Automated claude.ai upload (no API exists)
- Version bump enforcement in CI
- Slack/email notifications on release

## Approach

All work on feature branch `feature/multi-surface-plugin` off `development`.
Build in order: plugin manifest, Makefile, deploy script update, release
workflow, README update.

## File Changes

| Action | Path |
|--------|------|
| create | `.claude-plugin/plugin.json` |
| create | `Makefile` |
| create | `.github/workflows/release.yml` |
| modify | `.github/scripts/deploy-skills.sh` |
| modify | `README.md` |
| modify | `CHANGELOG.md` |
| modify | `.gitignore` |

## Tasks

### Chunk 1: Plugin Structure

- [x] **Task 1: Create feature branch and plugin manifest** <!-- sha:a8d9562 -->
  Create `feature/multi-surface-plugin` off `development`. Create
  `.claude-plugin/plugin.json` with name `skill-governance`, description,
  version `1.0.0`, author. Add `dist/` to `.gitignore`. Commit.
  **Verify:** `cat .claude-plugin/plugin.json | jq .name` returns
  `skill-governance`. `claude --plugin-dir . --help` doesn't error
  (plugin is loadable).

- [x] **Task 2: Create Makefile with package target** <!-- sha:193b6a2 -->
  Create `Makefile` at repo root with:
  - `package` target: finds all `skills/*/SKILL.md`, zips each skill
    directory into `dist/<skill-name>.zip` with SKILL.md at root
  - `clean` target: removes `dist/`
  - `list-skills` target: lists discovered skills
  Commit.
  **Verify:** `make package` creates ZIP files in `dist/`, each
  containing SKILL.md at the expected path. `make clean` removes `dist/`.

### Chunk 2: Deploy and Release

- [x] **Task 3: Add orphan reconciliation to deploy-skills.sh** <!-- sha:995e879 -->
  Update `.github/scripts/deploy-skills.sh` to:
  - After deploying, compare existing API skills against repo skills
  - Warn about orphans (deployed but not in repo) in the summary
  - Accept `--delete-orphans` flag to delete orphaned skills
    (delete all versions first, then skill)
  Commit.
  **Verify:** `bash -n .github/scripts/deploy-skills.sh` passes.

- [x] **Task 4: Create release.yml workflow** <!-- sha:ba7b5c6 -->
  Create `.github/workflows/release.yml` triggered on tag push (`v*`).
  Steps: checkout, `make package`, create GitHub Release with
  `gh release create` attaching `dist/*.zip`. Commit.
  **Verify:** YAML parses as valid.

### Chunk 3: Documentation

- [x] **Task 5: Update README with three distribution paths** <!-- sha:af211e9 -->
  Add a "Distribution" section to README covering:
  - Claude Code: plugin install instructions
  - Claude API: automatic on production merge
  - claude.ai: `make package` then manual upload, or download from
    GitHub Release
  - Releasing: how to tag and create a release
  - Orphan cleanup: how to use `--delete-orphans`
  Commit.
  **Verify:** `grep -c 'Claude Code\|Claude API\|claude.ai' README.md`
  returns matches for all three.

- [x] **Task 6: Update CHANGELOG and create PR** <!-- PR #7, sha:0532a73 -->
  Add entry for multi-surface plugin. Push branch, create PR to
  development, merge, update CHANGELOG with PR link.
  **Verify:** PR merged.

## Validation

1. **Plugin loadable**: `claude --plugin-dir . --print "list skills"
   --max-turns 1 --dangerously-skip-permissions 2>&1 | head -5`
   doesn't show plugin loading errors

2. **ZIP packaging**: `make package && ls dist/*.zip` shows one ZIP
   per skill, each containing SKILL.md

3. **YAML syntax**: Both workflow files parse as valid YAML

4. **Deploy script syntax**: `bash -n .github/scripts/deploy-skills.sh`

5. **Orphan flag**: `grep -q 'delete-orphans' .github/scripts/deploy-skills.sh`

6. **README completeness**: README mentions all three surfaces
   (Claude Code, Claude API, claude.ai)

7. **No hardcoded values**: `grep -r 'bcbeidel' .claude-plugin/ Makefile
   .github/workflows/release.yml` returns no matches
