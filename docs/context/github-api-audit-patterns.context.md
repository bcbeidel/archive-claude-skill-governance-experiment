---
name: GitHub API Audit Patterns
description: API endpoints and shell patterns for commit statuses, PR review counting, idempotent comments, changed file detection, and workflow triggers needed by the skill-audit workflow
type: context
sources:
  - https://docs.github.com/en/rest/commits/statuses?apiVersion=2022-11-28
  - https://docs.github.com/en/rest/pulls/reviews?apiVersion=2022-11-28
  - https://docs.github.com/en/rest/issues/comments?apiVersion=2022-11-28
  - https://docs.github.com/en/rest/pulls/pulls?apiVersion=2022-11-28
  - https://docs.github.com/en/actions/writing-workflows/choosing-when-your-workflow-runs/events-that-trigger-workflows
related:
  - docs/research/2026-03-25-skill-audit-workflow.research.md
  - docs/research/2026-03-25-github-api-pr-audit-patterns.research.md
  - docs/context/claude-code-ci-invocation.context.md
  - docs/designs/2026-03-25-skill-audit-workflow.design.md
---

## Commit Status API

Set a custom status check on a commit. Branch protection matches the
`context` string by name (case-insensitive).

```bash
gh api --method POST \
  "repos/{owner}/{repo}/statuses/${SHA}" \
  -f state="success" \
  -f context="skill-audit/approval-gate" \
  -f description="1/1 approvals met (LOW risk)"
```

States: `error`, `failure`, `pending`, `success`. Re-posting the same
context + SHA is idempotent — it overwrites the previous status.

## PR Review Counting

Fetch reviews, group by user, take each user's last review, count
approvals. The API has no server-side state filter.

```bash
APPROVALS=$(gh api --paginate \
  "repos/{owner}/{repo}/pulls/${PR_NUMBER}/reviews" \
  --jq '
    [.[] | {login: .user.login, state: .state}]
    | group_by(.login)
    | map(last)
    | [.[] | select(.state == "APPROVED")]
    | length
  ')
```

## Idempotent PR Comments

Use a hidden HTML marker to find-and-update rather than duplicate.

```bash
MARKER="<!-- skill-audit-results -->"

COMMENT_ID=$(gh api \
  "repos/{owner}/{repo}/issues/${PR_NUMBER}/comments" \
  --jq ".[] | select(.body | contains(\"${MARKER}\")) | .id")

if [ -n "$COMMENT_ID" ]; then
  gh api --method PATCH \
    "repos/{owner}/{repo}/issues/comments/${COMMENT_ID}" \
    -f body="${MARKER}${BODY}"
else
  gh api --method POST \
    "repos/{owner}/{repo}/issues/${PR_NUMBER}/comments" \
    -f body="${MARKER}${BODY}"
fi
```

PRs are issues in GitHub's data model — the Issues Comments API works.

## Detecting Changed Skills

List files changed in a PR, filter to `skills/` directory, extract
unique skill directories:

```bash
CHANGED_SKILLS=$(gh api --paginate \
  "repos/{owner}/{repo}/pulls/${PR_NUMBER}/files" \
  --jq '[.[] | select(.filename | startswith("skills/")) | .filename]
    | map(split("/")[0:2] | join("/"))
    | unique | .[]')
```

This returns paths like `skills/my-skill` for each changed skill.

## Workflow Triggers

Trigger on both code changes and review submissions:

```yaml
on:
  pull_request:
    types: [opened, synchronize, reopened]
    branches: [development, production]
  pull_request_review:
    types: [submitted]
```

`github.event.pull_request.number` and
`github.event.pull_request.head.sha` are available in both event types.

## Required Permissions

```yaml
permissions:
  contents: read          # Read repo files
  pull-requests: write    # Post comments, add labels
  statuses: write         # Set commit status checks
```

## Approval Thresholds

| Rating | Required Approvals |
|--------|-------------------|
| LOW    | 1 |
| MEDIUM | 2 |
| HIGH   | 3 |

When multiple skills change, use the maximum risk rating across all.
