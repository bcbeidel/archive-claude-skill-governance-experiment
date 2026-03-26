# Changelog

All notable changes to the Claude Skill Governance Template.

## [0.1.0] - 2026-03-26

Initial experimental release.

### Added

- **Audit Skill** ([PR #1](https://github.com/bcbeidel/claude-skill-governance-template/pull/1))
  — Claude Code skill that evaluates skill directories
  across 7 risk dimensions (permission scope, data exposure, prompt
  injection surface, blast radius, reversibility, semantic overlap,
  dependency risk) and produces governance-ready risk reports with
  LOW/MEDIUM/HIGH ratings and remediation recommendations.
  - Scoring rubric grounded in Anthropic enterprise risk tiers, OWASP
    LLM Top 10, and Meta's Rule of Two
  - Hybrid rating: average baseline with escalation triggers
  - Self-referential validation (audit-skill passes its own audit)
- **Test Skills** — Three test skills with known risk profiles for
  validating audit scoring consistency (in `evals/test-skills/`):
  - `low-risk-skill` (expected: LOW)
  - `medium-risk-skill` (expected: MEDIUM)
  - `high-risk-skill` (expected: HIGH)
- **Research & Context** — Distilled findings from 35+ sources across
  OWASP, NIST, STRIDE/DREAD, Anthropic enterprise docs, and academic
  literature on LLM tool security
- **Skill Audit Workflow** ([PR #2](https://github.com/bcbeidel/claude-skill-governance-template/pull/2))
  — GitHub Actions workflow that automatically audits skills on PR changes:
  - Detects new/modified skills in PR changesets
  - Invokes Claude Code CLI to run audit-skill against each changed skill
  - Posts consolidated risk report as an idempotent PR comment
  - Enforces risk-based approval gates via commit status checks
    (LOW=1, MEDIUM=2, HIGH=3 required approvals)
  - Labels PRs with risk level (`risk:LOW`, `risk:MEDIUM`, `risk:HIGH`)
- **Deployment Pipeline** ([PR #3](https://github.com/bcbeidel/claude-skill-governance-template/pull/3))
  — GitHub Actions workflow that deploys skills on merge to `production`:
  - Uploads via Anthropic Skills API (create new or update existing)
  - Orphan detection and cleanup (`--delete-orphans` flag)
  - Path traversal protection on skill names
- **Multi-Surface Distribution** ([PR #7](https://github.com/bcbeidel/claude-skill-governance-template/pull/7))
  — Deploy to all three Claude surfaces from a single `skills/` directory:
  - Claude Code: plugin install (`.claude-plugin/plugin.json`)
  - Claude API: automatic on production merge
  - claude.ai: `make package` generates ZIPs for admin upload
  - Tag-triggered GitHub Releases with ZIP artifacts
- **Governance Documentation** ([PR #4](https://github.com/bcbeidel/claude-skill-governance-template/pull/4))
  — README with quickstart, governance policy, step-by-step guides,
  and architecture diagram
