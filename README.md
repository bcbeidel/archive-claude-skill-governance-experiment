# Claude Skill Governance Template

A template repository for managing, reviewing, and deploying Claude Code
skills with built-in governance. Fork this repo to get automated risk
auditing, approval gates, and deployment pipelines for your organization's
Claude skills.

```
                          skills/
                       (source of truth)
                             |
               +-------------+-------------+
               |                           |
          feature branch              make package
               |                           |
         Pull Request                  dist/*.zip
               |                           |
     +---------+---------+                 |
     |                   |                 |
 Audit Workflow    Approval Gate      claude.ai
     |                   |          (manual upload)
 Risk Report        LOW  = 1 review
 (PR comment)       MED  = 2 reviews
     |              HIGH = 3 reviews
     |                   |
     +--------+----------+
              |
     Merge to production
              |
    +---------+---------+
    |                   |
Deploy Pipeline    git tag v1.x
    |                   |
Claude API       GitHub Release
(automatic)      (ZIP artifacts)
    |
Claude Code
(plugin install)
```

## Table of Contents

- [Quickstart](#quickstart)
- [Repository Structure](#repository-structure)
- [Governance Policy](#governance-policy)
- [Adding a New Skill](#adding-a-new-skill)
- [Reviewing an Audit Report](#reviewing-an-audit-report)
- [Deploying to Production](#deploying-to-production)
- [Distribution](#distribution)
- [Releasing](#releasing)
- [Audit-Skill Details](#audit-skill-details)

---

## Quickstart

Get working governance in your organization in 4 steps.

### Step 1: Fork the Repository

Fork this repo into your GitHub organization. Clone it locally.

### Step 2: Configure GitHub Secrets

Add your Anthropic API key as a repository secret:

1. Go to **Settings > Secrets and variables > Actions**
2. Click **New repository secret**
3. Name: `ANTHROPIC_API_KEY`
4. Value: Your Anthropic API key (workspace-scoped)

This key is used by the audit workflow (to invoke Claude for skill
evaluation) and the deployment workflow (to upload skills via the
Skills API).

### Step 3: Create Branches

Create the `development` and `production` branches:

```bash
git checkout -b development
git push -u origin development

git checkout -b production
git push -u origin production
```

### Step 4: Configure Branch Protection

In **Settings > Branches**, add protection rules for both `development`
and `production`:

**For `development`:**
- Require a pull request before merging
- Require status checks to pass before merging
  - Add required check: `skill-audit/approval-gate`
- Do not allow bypassing the above settings

**For `production`:**
- Require a pull request before merging
- Require status checks to pass before merging
  - Add required check: `skill-audit/approval-gate`
- Require approvals (minimum 1)
- Do not allow bypassing the above settings

The `skill-audit/approval-gate` status check is set by the audit
workflow. It will appear as a required check after the first PR that
modifies a skill triggers the workflow.

**Done.** Your organization now has automated skill governance.

---

## Repository Structure

```
.claude-plugin/
  plugin.json                 # Plugin manifest (name, version, description)
skills/
  audit-skill/                # Built-in risk audit skill
    SKILL.md                  # Skill definition (evaluation workflow)
    references/
      scoring-rubric.md       # 7-dimension scoring criteria
      report-template.md      # Audit report output format
.github/
  workflows/
    skill-audit.yml           # PR-triggered audit workflow
    deploy-skills.yml         # Production deployment workflow
    release.yml               # Tag-triggered release with ZIP artifacts
  scripts/
    detect-skill-changes.sh   # Detects changed skills in a PR
    post-audit-comment.sh     # Posts/updates audit report PR comments
    check-approvals.sh        # Enforces risk-based approval gates
    deploy-skills.sh          # Deploys skills via Anthropic Skills API
evals/
  test-skills/                # Test fixtures for audit validation
    low-risk-skill/           # Expected: LOW rating
    medium-risk-skill/        # Expected: MEDIUM rating
    high-risk-skill/          # Expected: HIGH rating
docs/
  research/                   # Research findings with citations
  context/                    # Distilled context from research
  designs/                    # Design specifications
  plans/                      # Implementation plans
Makefile                      # make package — generates ZIPs for claude.ai
CHANGELOG.md                  # Change history with PR links
```

---

## Governance Policy

### Branch Model

| Branch | Purpose | Protection |
|--------|---------|------------|
| `development` | Integration branch for skill development | PR-only, audit status check required |
| `production` | Deployed skills — merges here trigger deployment | PR-only, audit status check required |
| `feature/*` | Individual skill work | No protection (short-lived) |

All changes flow through pull requests. Direct pushes to `development`
and `production` are blocked by branch protection.

### Risk-Based Approval Requirements

When a PR modifies files in `skills/`, the audit workflow automatically:

1. Runs the audit-skill against each changed skill
2. Posts a risk report as a PR comment
3. Labels the PR with the risk level
4. Sets a commit status check based on approval count

| Risk Rating | Required Approvals | Label |
|-------------|-------------------|-------|
| LOW | 1 | `risk:LOW` |
| MEDIUM | 2 | `risk:MEDIUM` |
| HIGH | 3 | `risk:HIGH` |

The `skill-audit/approval-gate` status check blocks merge until the
required number of approvals is met. When multiple skills change in one
PR, the highest risk rating determines the approval requirement.

### Audit Trail

Every deployed skill has a traceable lineage:

```
Feature Branch → PR → Audit Report (PR comment) → Approvals → Merge → Deployment
```

- **PR**: Contains the skill changes with full diff
- **Audit Report**: Posted as a PR comment with 7-dimension scorecard
- **Approvals**: Recorded as GitHub reviews, counted by the approval gate
- **Deployment**: Triggered automatically on merge to `production`
- **CHANGELOG.md**: Links each change to its PR

### Risk Dimensions

The audit-skill evaluates skills across 7 dimensions, grounded in
established security frameworks:

| Dimension | What It Measures | Framework |
|-----------|-----------------|-----------|
| Permission Scope | Tools and resources the skill accesses | OWASP LLM06, Anthropic Enterprise |
| Data Exposure | Sensitive data access and transmission | OWASP LLM02, Anthropic Enterprise |
| Prompt Injection Surface | Vulnerability to injection attacks | OWASP LLM01, Meta's Rule of Two |
| Blast Radius | Worst-case impact of misbehavior | OWASP ASI08, CSA CBRA |
| Reversibility | Whether actions can be undone | CSA CBRA |
| Semantic Overlap | Duplication with existing skills | Anthropic Enterprise |
| Dependency Risk | External dependencies and supply chain | OWASP ASI04, SLSA, OpenSSF |

Each dimension is scored 1-5 with observable, binary criteria. The overall
rating uses a hybrid approach: average baseline with automatic escalation
triggers for high-risk patterns.

---

## Adding a New Skill

### Step 1: Create a Feature Branch

```bash
git checkout development
git pull origin development
git checkout -b feature/my-new-skill
```

### Step 2: Create the Skill Directory

```bash
mkdir -p skills/my-new-skill
```

### Step 3: Write SKILL.md

Create `skills/my-new-skill/SKILL.md` with YAML frontmatter:

```yaml
---
name: my-new-skill
description: Brief description of what this skill does and when to use it.
---

# My New Skill

## Instructions
[Step-by-step guidance for Claude to follow]
```

Requirements:
- `name`: max 64 characters, lowercase letters/numbers/hyphens only
- `description`: max 1024 characters, non-empty, third person
- Body: under 500 lines for optimal performance

### Step 4: Add Supporting Files (Optional)

```
skills/my-new-skill/
  SKILL.md              # Required
  references/           # Optional: additional docs
  scripts/              # Optional: utility scripts
```

### Step 5: Commit and Open a PR

```bash
git add skills/my-new-skill/
git commit -m "Add my-new-skill"
git push -u origin feature/my-new-skill
```

Open a PR targeting `development`. The audit workflow will automatically
run and post a risk report.

### Step 6: Address the Audit Report

Review the audit report posted as a PR comment. If the risk rating is
higher than expected, follow the recommendations to reduce risk. Push
fixes and the audit will re-run.

### Step 7: Get Approvals and Merge

Get the required number of approvals for the risk level. The
`skill-audit/approval-gate` status check will turn green when met.
Merge the PR.

---

## Reviewing an Audit Report

When the audit workflow runs, it posts a comment on the PR containing
a risk report for each changed skill.

### What to Look For

1. **Overall Risk Rating**: LOW, MEDIUM, or HIGH at the top of the report
2. **Scorecard**: A table showing each dimension's score (1-5) with
   justifications citing specific evidence from the skill files
3. **Escalation Triggers**: Any conditions that automatically elevated
   the risk rating (e.g., unrestricted Bash access, credential handling)
4. **Recommendations**: Actionable suggestions for dimensions scoring 3+

### Red Flags

- **Permission Scope 4-5**: The skill uses Bash — verify commands are
  constrained and necessary
- **Data Exposure 5**: The skill handles credentials or transmits data
  externally — verify this is intended
- **Prompt Injection 5**: The skill satisfies Meta's Rule of Two (processes
  untrusted input + accesses sensitive data + changes state) — ensure
  safeguards are in place
- **Dependency Risk 4-5**: MCP tool references or unpinned dependencies —
  verify these are trusted and necessary

### Approving

After reviewing the audit report:
- If the scores are justified and risks are acceptable, approve the PR
- If scores seem too high, work with the skill author on remediation
- If you disagree with a score, document why in your review comment

---

## Deploying to Production

### Step 1: Merge to Development

All skill changes must first be merged to `development` via PR with
a passing audit and sufficient approvals.

### Step 2: Create a Production PR

```bash
git checkout production
git pull origin production
git checkout development
git pull origin development
gh pr create --base production --head development \
  --title "Deploy: [description of changes]"
```

### Step 3: Review and Merge

The audit workflow runs again on the production PR. Get required
approvals. Merge the PR.

### Step 4: Automatic Deployment

On merge to `production`, the `deploy-skills.yml` workflow automatically:
1. Discovers all skills in `skills/`
2. Uploads each to your Claude workspace via the Skills API
3. Creates new skills or updates existing ones
4. Reports deployment results in the workflow log

### Verifying Deployment

Check the workflow run in **Actions > Deploy Skills** to see which skills
were created, updated, or failed.

---

## Distribution

Skills in this repo deploy to three surfaces. Each uses the same `skills/`
directory as the source of truth.

### Claude Code (Plugin Install)

This repo is structured as a Claude Code plugin. Team members install it
from your plugin marketplace:

```
/plugin install <your-marketplace-url>
```

Skills auto-discover on install. Updates via `/plugin update`.

### Claude API (Automatic)

On merge to `production`, the `deploy-skills.yml` workflow automatically
uploads all skills to your Claude API workspace via the Skills API. These
skills are available in Messages API calls with `container.skills`.

The deploy script detects orphaned skills (deployed but removed from repo)
and warns in the summary. To remove orphans:

```bash
ANTHROPIC_API_KEY=<key> .github/scripts/deploy-skills.sh --delete-orphans
```

### claude.ai (Manual ZIP Upload)

claude.ai requires manual upload through the admin UI. Generate ZIP files:

```bash
make package
# → dist/audit-skill.zip
# → dist/hello-world.zip
```

Then upload each ZIP:
1. Go to **Organization Settings > Skills > + Add**
2. Select the ZIP file
3. Set default state (enabled/disabled)

ZIP files are also attached to GitHub Releases for download.

> **Note:** Custom Skills on claude.ai do not sync with the API or Claude
> Code. Each surface must be updated independently. This is an Anthropic
> platform limitation.

---

## Releasing

### Create a Release

1. Update the version in `.claude-plugin/plugin.json`
2. Commit and merge to `production`
3. Tag and push:

```bash
git tag v1.0.0
git push origin v1.0.0
```

4. The `release.yml` workflow creates a GitHub Release with:
   - Skill ZIP files attached as downloadable assets
   - Auto-generated release notes
   - Instructions for each deployment surface

### Version Strategy

- Use [semantic versioning](https://semver.org/) in `.claude-plugin/plugin.json`
- Bump **patch** for skill content changes (rubric updates, report tweaks)
- Bump **minor** for new skills added
- Bump **major** for breaking changes (scoring methodology changes, API changes)

---

## Audit-Skill Details

The audit-skill at `skills/audit-skill/` is itself a Claude Code skill
that evaluates other skills. It:

- Reads a target skill directory (SKILL.md, scripts, references)
- Extracts observable facts (tools, commands, data patterns, URLs)
- Scores 7 risk dimensions using a deterministic rubric
- Generates a report with scorecard, justifications, and recommendations

The scoring rubric is at `skills/audit-skill/references/scoring-rubric.md`.
The report template is at `skills/audit-skill/references/report-template.md`.

The audit-skill passes its own audit with a LOW rating (average 1.7/5.0).

### Scoring Methodology

- Each dimension scored 1-5 with observable, binary criteria
- Overall rating: average of all 7 scores
- Escalation triggers override the average:
  - Any single score of 5 → at least MEDIUM
  - Any two scores of 4+ → HIGH
  - Anthropic high-concern patterns → at least MEDIUM

See `skills/audit-skill/references/scoring-rubric.md` for the complete
criteria and calibration examples.
