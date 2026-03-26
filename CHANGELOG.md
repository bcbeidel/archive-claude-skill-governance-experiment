# Changelog

All notable changes to the Claude Code Plugin Governance Template.

## [Unreleased]

### Added

- **Audit Skill** — Claude Code skill that evaluates skill directories
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
