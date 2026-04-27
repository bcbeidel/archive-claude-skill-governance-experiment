# Claude Skill Governance Experiment (Archived)

> **Archived 2026-04-27.** Point-in-time experiment. The repo is read-only;
> contents are preserved below as a reference snapshot. See *What to use
> instead* before forking this pattern.

## What this was

An experiment in building org-level governance for Claude Code skills:
PR-triggered audit (Claude-as-judge against a 7-dimension rubric),
risk-tiered approval gates, and multi-surface deployment (Claude Code
plugin, Claude API, claude.ai). Built March 2026 to answer "how do we
ship skills safely across the three distribution surfaces?"

## What we built

- An **audit skill** that scored other skills 1–5 across 7 dimensions
  (permission scope, data exposure, prompt injection surface, blast
  radius, reversibility, semantic overlap, dependency risk)
- A **GitHub Actions workflow** that ran the audit on PR, posted the
  report as a comment, labeled the PR with `risk:LOW/MEDIUM/HIGH`, and
  set a commit-status gate scaled to the severity
  (LOW=1 / MED=2 / HIGH=3 approvals)
- A **deploy pipeline** that uploaded skills to the Anthropic Skills API
  on merge to `production`, plus `make package` for claude.ai ZIP uploads
  and a tag-triggered GitHub Release with ZIP artifacts
- **Research** distilled from ~35 sources (OWASP LLM Top 10, NIST AI RMF,
  Anthropic enterprise docs, Meta's Rule of Two, CSA CBRA)

## Lessons learned

**1. Claude has three independent distribution surfaces, and they don't
sync.**
- Claude Code → plugin install from a marketplace
  (`.claude-plugin/plugin.json`, skills auto-discover)
- Claude API → multipart upload to `/v1/skills`, list-and-match by
  `display_title` (no name filter)
- claude.ai → manual ZIP upload through the admin UI

Custom Skills on claude.ai do not propagate to the API or to Claude
Code. Any governance design has to fan out to all three independently.

**2. Defer static skill analysis to Cisco's `skill-scanner` rather than
own it.**
Open source, maintained by a credible security org, tracks an evolving
threat surface (prompt injection patterns, exfil techniques, tool
abuse) faster than a small internal team can. Building and maintaining
a parallel rubric means perpetually chasing the threat landscape with
no security team behind it. https://github.com/cisco-ai-defense/skill-scanner

**3. Static analysis and LLM-as-judge are complementary, not
substitutes.**
Deterministic scanners are cheap, fast, and reproducible — the right
primitive for a broad pre-merge gate, but they miss semantic and
contextual risk. LLM judges catch novel and contextual risk but are
slow, non-deterministic, and cost API budget per PR. A serious pipeline
runs both: scanner as the cheap default gate, LLM judge reserved for
the cases where context actually matters. We chose only one and got
the worst of both.

**4. Risk tiering is the durable pattern.**
Not all skills carry equal risk and they shouldn't be gated equally.
The pattern of `severity label → commit status check → branch
protection with scaled approvals` is reusable with any scanner that
emits a severity. That is the part of this repo worth keeping. The
specific 7-dimension rubric is not.

**5. The Skills API shape captured here will rot.**
As of April 2026: multipart `POST /v1/skills`, `anthropic-beta:
skills-2025-10-02`, no name-based lookup, match by `display_title`.
Treat `docs/research/2026-03-25-skills-api-upload.research.md` as a
point-in-time snapshot, not current truth.

## What to use instead

For a team standing this up today:

1. **Distribute via plugins.** Publish skills from a Claude Code plugin
   marketplace; let teams install and update through `/plugin`.
   https://code.claude.com/docs/en/plugins
2. **Run Cisco's `skill-scanner` as the pre-merge gate.** Map its
   findings to severity labels; gate merges with branch protection.
   https://github.com/cisco-ai-defense/skill-scanner
3. **Use Anthropic's enterprise skill controls for the claude.ai
   surface.** Admin-level review and tiering for Custom Skills.
   https://platform.claude.com/docs/en/agents-and-tools/agent-skills/enterprise
4. **Layer LLM-as-judge selectively** — for high-severity skills, novel
   tool combinations, or anything the static scanner can't reason about.

## Repo contents (preserved as reference)

```
skills/audit-skill/        # 7-dimension audit skill (rubric + report template)
.github/workflows/         # PR audit, deploy, and release workflows
.github/scripts/           # Detection, comment-posting, approval-gate, deploy
evals/test-skills/         # Low/medium/high test fixtures
docs/research/             # Source-cited research with date stamps
docs/context/              # Distilled context derived from research
docs/designs/              # Design specs for each component
Makefile                   # make package — generates claude.ai ZIPs
CHANGELOG.md               # Build history with PR links
```

The original detailed README — quickstart, full governance policy, and
step-by-step guides — is available in the git history at commit
[`d95b8e2`](../../commit/d95b8e2).
