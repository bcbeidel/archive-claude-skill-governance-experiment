---
name: Scoring Methodology
description: How the audit-skill computes per-dimension scores and overall risk ratings using a hybrid approach grounded in Anthropic's risk tiers, DREAD, and FedRAMP
type: context
sources:
  - https://platform.claude.com/docs/en/agents-and-tools/agent-skills/enterprise
  - https://www.eccouncil.org/cybersecurity-exchange/threat-intelligence/dread-threat-modeling-intro/
  - https://owasp.org/www-community/OWASP_Risk_Rating_Methodology
  - https://secureframe.com/hub/fedramp/impact-levels
  - https://infosec.mozilla.org/guidelines/risk/rapid_risk_assessment.html
related:
  - docs/research/2026-03-25-llm-skill-risk-scoring.research.md
  - docs/context/dimension-criteria.context.md
  - docs/context/scoring-calibration.context.md
  - docs/designs/2026-03-25-audit-skill.design.md
---

## Scoring Model

Each of 7 risk dimensions is scored 1-5 using observable criteria. The
overall risk rating uses a **hybrid approach**: average baseline with
automatic escalation triggers.

### Per-Dimension Scoring (1-5)

| Score | Label | Meaning |
|-------|-------|---------|
| 1 | Minimal | No access or exposure in this dimension |
| 2 | Low | Limited, well-scoped access |
| 3 | Moderate | Some access with partial safeguards |
| 4 | Elevated | Broad access or weak safeguards |
| 5 | Critical | Unrestricted access or no safeguards |

Criteria at each level must be **observable from the skill directory** — no
runtime analysis, no subjective judgment. Each level is defined by specific
indicators (tool references, file patterns, URL presence) that can be
verified by reading the skill's contents.

### Overall Risk Rating

**Step 1 — Compute average** of all 7 dimension scores.

**Step 2 — Apply escalation triggers:**
- Any single dimension scoring **5** → overall rating is at least **MEDIUM**
- Any two dimensions scoring **4+** → overall rating is **HIGH**
- Any dimension matching Anthropic's "High concern" indicators (code
  execution + network access, instruction manipulation, hardcoded
  credentials) → overall rating is at least **MEDIUM**

**Step 3 — Final rating:**

| Condition | Rating |
|-----------|--------|
| Average <= 2.0 AND no escalation triggers | **LOW** |
| Average <= 3.5 AND no HIGH escalation triggers | **MEDIUM** |
| Average > 3.5 OR HIGH escalation triggers | **HIGH** |

### Design Rationale

- **Why hybrid, not pure average?** Pure averaging (DREAD, OWASP Risk
  Rating) can mask extreme single-dimension risks. A skill scoring 5 on
  Permission Scope but 1 elsewhere averages to ~1.6 (LOW) — unacceptable
  for a skill with unrestricted shell access. FedRAMP's high-water-mark is
  too conservative for a 7-dimension system. The hybrid balances nuance
  with safety.

- **Why 1-5, not 0-10?** Fewer levels reduce scorer variance and make
  criteria more distinct. DREAD's 0-10 range introduces ambiguity between
  adjacent scores. Five levels with binary/observable criteria at each
  level maximize reproducibility.

- **Why escalation triggers?** Anthropic's enterprise documentation
  identifies specific high-concern patterns (code execution, instruction
  manipulation, network access, credentials) that should always elevate
  risk regardless of other dimensions. Triggers encode this.

### Determinism Properties

The scoring is deterministic when:
1. Criteria are binary/observable (tool X is referenced: yes/no)
2. Each score level has explicit indicators, not ranges
3. Calibration examples anchor boundary cases
4. The same skill directory always produces the same report
