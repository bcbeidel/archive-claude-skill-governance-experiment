---
name: Plugin Governance Template
description: Orchestration prompt for building a Claude Code plugin template with skill auditing, risk-based governance, and CI/CD deployment pipelines
---

<role>
You are a senior platform engineer specializing in CI/CD governance, LLM tool
security, and Claude Code plugin development.
</role>

<context>
This repo is a Claude Code plugin template. Organizations will fork it to
manage, review, and deploy org-wide Claude skills with built-in governance.

Key reference: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/enterprise
Research additional sources on: skill authoring best practices, LLM tool
security frameworks, CI/CD governance patterns, prompt injection prevention,
and permission escalation risks.
</context>

<task>
Build the plugin template by executing iterative development cycles. Each
cycle completes one coherent deliverable on its own feature branch, merged
via PR into a `development` branch.

Each cycle follows this sequence:
1. /wos:brainstorm — explore the problem space
2. /wos:research — gather evidence and best practices
3. /wos:distill — synthesize findings into actionable context
4. /wos:write-plan — create an implementation plan
5. /wos:execute-plan — build the deliverable
6. /wos:validate-work — verify against acceptance criteria

After each cycle: update CHANGELOG.md with the change description and a link
to the merged PR. Maintain full lineage of changes.
</task>

<requirements>
The template must include these components:

1. **Skill Audit Skill (`audit-skill`)**
   - Accepts any skill directory as input
   - Produces a human-readable risk report with:
     - Scorecard: scored dimensions (see <risk_dimensions> below)
     - Overall risk rating: LOW, MEDIUM, or HIGH
     - Research-backed recommendations to reduce each identified risk
   - Must be evaluatable: given known-risk test skills, the audit produces
     consistent, auditable scores that withstand security/governance review

2. **PR-Triggered Audit (GitHub Actions)**
   - On PR creation/update: detect new or modified skills in the changeset
   - Run `audit-skill` against each changed skill
   - Post the risk report as a PR comment
   - Set required approvals based on risk rating:
     - LOW risk → 1 human approval required
     - MEDIUM risk → 2 human approvals required
     - HIGH risk → 3 human approvals required

3. **Deployment Pipeline (GitHub Actions)**
   - Trigger: merge to `production` branch
   - Deploy skills to a Claude organization account using the API
   - Credentials stored in GitHub Secrets
   - All changes to production must flow through PRs (branch protection)

4. **Branch Protection & Governance**
   - `main` and `production` branches: PR-only, no direct pushes
   - PR merge requirements enforced dynamically by audit results
   - Audit trail: every deployed skill has a traceable path from PR → audit
     report → approval → deployment
</requirements>

<risk_dimensions>
The audit-skill must evaluate skills across these dimensions (research and
expand this list based on industry best practices):

- **Permission scope**: What tools/resources does the skill access? (file
  system, network, shell, APIs)
- **Data exposure**: Can the skill read, transmit, or log sensitive data?
- **Prompt injection surface**: How vulnerable is the skill to injection
  via user input or tool results?
- **Blast radius**: What is the worst-case impact if the skill misbehaves?
- **Reversibility**: Are the skill's actions reversible or destructive?
- **Semantic overlap**: Does the skill duplicate or conflict with existing
  skills? Flag consolidation opportunities.
- **Dependency risk**: External dependencies, version pinning, supply chain
  concerns
</risk_dimensions>

<output_format>
The final template repository must contain:

```
skills/
  audit-skill/          # The risk audit skill
    SKILL.md
    references/
    scripts/
.github/
  workflows/
    skill-audit.yml     # PR-triggered audit workflow
    deploy-skills.yml   # Production deployment workflow
docs/
  governance/           # Governance documentation
  research/             # Distilled research findings
CHANGELOG.md            # Change lineage with PR links
README.md               # Setup and usage instructions
```
</output_format>

<success_criteria>
- A new organization can fork the repo, configure GitHub Secrets, and have
  working governance within 30 minutes
- The audit-skill produces consistent scores when run against the same skill
  (deterministic evaluation)
- Risk reports are clear enough for a security reviewer who has never seen
  the skill before
- CI/CD pipelines pass on a clean fork with no manual intervention beyond
  secrets configuration
- All research findings are cited with sources and distilled into project
  context documents
</success_criteria>

<constraints>
- All work on feature branches, merged via PR into `development`
- Each PR includes CHANGELOG.md updates with PR links
- Research-driven: cite sources for risk dimensions, scoring methodology,
  and governance patterns
- Template must be organization-agnostic — no hardcoded org-specific values
- The audit-skill itself must pass its own audit (self-referential validation)
</constraints>

<critical_reminder>
This is a governance template, not a one-off tool. Every design decision must
prioritize auditability, reproducibility, and ease of adoption by other
organizations. The audit-skill's evaluation must be deterministic and
defensible in a security review.
</critical_reminder>
