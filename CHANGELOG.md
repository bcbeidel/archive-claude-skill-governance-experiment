# Changelog

All notable changes to the Claude Code Plugin Governance Template.

## [Unreleased]

### Added

- **Audit Skill** ([PR #1](https://github.com/bcbeidel/claude-automode-experiment/pull/1))
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
  validating audit scoring consistency:
  - `low-risk-skill` (expected: LOW)
  - `medium-risk-skill` (expected: MEDIUM)
  - `high-risk-skill` (expected: HIGH)
- **Research & Context** — Distilled findings from 35 sources across
  OWASP, NIST, STRIDE/DREAD, Anthropic enterprise docs, and academic
  literature on LLM tool security
- **Skill Audit Workflow** — GitHub Actions workflow
  (`.github/workflows/skill-audit.yml`) that automatically audits skills
  on PR changes:
  - Detects new/modified skills in PR changesets
  - Invokes Claude Code CLI to run audit-skill against each changed skill
  - Posts consolidated risk report as an idempotent PR comment
  - Enforces risk-based approval gates via commit status checks
    (LOW=1, MEDIUM=2, HIGH=3 required approvals)
  - Labels PRs with risk level (`risk:LOW`, `risk:MEDIUM`, `risk:HIGH`)
