# Risk Report Template

Use this template to generate the audit report. Fill in all bracketed
sections based on the evaluation results.

---

## Output Format

```markdown
# Skill Risk Audit Report

**Skill:** [skill name from YAML frontmatter]
**Path:** [skill directory path]
**Date:** [current date YYYY-MM-DD]
**Auditor:** audit-skill v1.0

---

## Overall Risk Rating: [LOW | MEDIUM | HIGH]

**Average Score:** [X.X] / 5.0
**Escalation Triggers:** [list any triggered, or "None"]

---

## Scorecard

| Dimension | Score | Rating | Justification |
|-----------|-------|--------|---------------|
| Permission Scope | [1-5] | [Minimal/Low/Moderate/Elevated/Critical] | [one-sentence justification citing specific observable indicator] |
| Data Exposure | [1-5] | [Minimal/Low/Moderate/Elevated/Critical] | [one-sentence justification citing specific observable indicator] |
| Prompt Injection Surface | [1-5] | [Minimal/Low/Moderate/Elevated/Critical] | [one-sentence justification citing specific observable indicator] |
| Blast Radius | [1-5] | [Minimal/Low/Moderate/Elevated/Critical] | [one-sentence justification citing specific observable indicator] |
| Reversibility | [1-5] | [Minimal/Low/Moderate/Elevated/Critical] | [one-sentence justification citing specific observable indicator] |
| Semantic Overlap | [1-5] | [Minimal/Low/Moderate/Elevated/Critical] | [one-sentence justification citing specific observable indicator] |
| Dependency Risk | [1-5] | [Minimal/Low/Moderate/Elevated/Critical] | [one-sentence justification citing specific observable indicator] |

---

## Escalation Triggers

[If any escalation triggers were activated, list them here with explanation.
If none, state "No escalation triggers activated."]

- **[Trigger name]:** [Description of which condition was met and why]

---

## Recommendations

[For each dimension scoring 3 or higher, provide a specific, actionable
recommendation to reduce the score. Skip dimensions scoring 1-2.]

### [Dimension Name] (Score: [N])

**Risk:** [What the current score means in practical terms]
**Recommendation:** [Specific action to reduce the score]
**Target Score:** [What score the skill could achieve after remediation]

---

## Skill Summary

**Description:** [skill description from YAML frontmatter]
**Directory Contents:**
- [list of files and directories in the skill directory]

**Tools Referenced:** [list of Claude tools the skill instructs to use]
**External References:** [list of URLs, APIs, or MCP tools referenced, or "None"]

---

## Framework References

This audit evaluates skills against criteria derived from:
- [Anthropic Enterprise Skill Governance](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/enterprise) — Risk tier assessment and review checklist
- [OWASP Top 10 for LLM Applications 2025](https://genai.owasp.org/resource/owasp-top-10-for-llm-applications-2025/) — LLM06 Excessive Agency, LLM01 Prompt Injection
- [OWASP Top 10 for Agentic Applications](https://genai.owasp.org/resource/owasp-top-10-for-agentic-applications-for-2026/) — ASI02 Tool Misuse, ASI04 Supply Chain
- [NIST AI RMF](https://nvlpubs.nist.gov/nistpubs/ai/nist.ai.100-1.pdf) — AI Risk Management Framework
- [Meta's Rule of Two](https://simonwillison.net/2025/Nov/2/new-prompt-injection-papers/) — Prompt injection surface assessment
```

---

## Formatting Rules

1. **Justifications must cite observable evidence.** Not "this seems risky"
   but "SKILL.md references Bash tool with no command constraints (line 42)."

2. **Recommendations only for scores >= 3.** Dimensions scoring 1-2 are
   acceptable and need no remediation guidance.

3. **Escalation triggers section is always present.** If no triggers were
   activated, state "No escalation triggers activated."

4. **Skill Summary section documents what was found.** List actual files,
   tools, and external references discovered during the audit. This makes
   the report self-contained for reviewers who haven't seen the skill.

5. **Framework References section is always present.** This establishes
   the audit's methodological basis for security reviewers.
