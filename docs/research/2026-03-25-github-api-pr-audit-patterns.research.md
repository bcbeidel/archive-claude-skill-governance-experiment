---
name: GitHub REST API Patterns for PR Audit Workflows
description: API endpoints, request formats, and implementation patterns for commit statuses, PR reviews, idempotent comments, changed file detection, and event triggers needed by a PR audit workflow
type: research
sources:
  - https://docs.github.com/en/rest/commits/statuses?apiVersion=2022-11-28
  - https://docs.github.com/en/rest/pulls/reviews?apiVersion=2022-11-28
  - https://docs.github.com/en/rest/issues/comments?apiVersion=2022-11-28
  - https://docs.github.com/en/rest/pulls/pulls?apiVersion=2022-11-28
  - https://docs.github.com/en/rest/branches/branch-protection?apiVersion=2022-11-28
  - https://docs.github.com/en/actions/writing-workflows/choosing-when-your-workflow-runs/events-that-trigger-workflows
  - https://github.com/peter-evans/create-or-update-comment
  - https://github.com/peter-evans/find-comment
related:
  - docs/research/2026-03-25-llm-skill-risk-scoring.research.md
---

## Key Takeaways

- Commit statuses are set per SHA via `POST /repos/{owner}/{repo}/statuses/{sha}` with a `context` string that branch protection matches by name.
- PR reviews must be fetched in full and filtered client-side; the API has no server-side state filter. The `state` field value for approvals is `APPROVED`.
- Idempotent PR comments use a hidden HTML marker (`<!-- marker -->`) to find-then-update. Both `gh api` with `--jq` and the `peter-evans/find-comment` + `peter-evans/create-or-update-comment` actions support this.
- Changed files come from `GET /repos/{owner}/{repo}/pulls/{pull_number}/files` (max 3000 files) or `gh pr diff --name-only`.
- To trigger on both new commits and new reviews, a workflow needs both `pull_request` and `pull_request_review` event triggers.

---

## 1. Commit Status API

**Source:** https://docs.github.com/en/rest/commits/statuses?apiVersion=2022-11-28

### Create a Commit Status

```
POST /repos/{owner}/{repo}/statuses/{sha}
```

| Parameter     | Type   | Required | Description                                                      |
|---------------|--------|----------|------------------------------------------------------------------|
| `state`       | string | yes      | One of: `error`, `failure`, `pending`, `success`                 |
| `context`     | string | no       | Label distinguishing this status from others. Default: `default` |
| `description` | string | no       | Short human-readable summary (max ~140 chars recommended)        |
| `target_url`  | string | no       | URL linking to the full details (e.g., CI build output)          |

Example with `gh`:

```bash
gh api \
  --method POST \
  repos/{owner}/{repo}/statuses/${COMMIT_SHA} \
  -f state="success" \
  -f context="skill-audit" \
  -f description="All skills passed audit" \
  -f target_url="https://github.com/${REPO}/actions/runs/${RUN_ID}"
```

### How Branch Protection References Status Checks

Branch protection rules contain a `contexts` array (or the newer `checks` array) listing required status check names. The `context` string you set on a commit status must exactly match (case-insensitive) an entry in this array.

```
GET  /repos/{owner}/{repo}/branches/{branch}/protection/required_status_checks
PATCH /repos/{owner}/{repo}/branches/{branch}/protection/required_status_checks
```

The `checks` array offers finer control by pairing a `context` name with an optional `app_id` to pin which GitHub App must provide that status. For a custom workflow status, the `context` field alone is sufficient.

### Idempotency

Posting a status with the same `context` and `sha` overwrites the previous status for that context. This is inherently idempotent -- re-running a workflow safely updates the status.

---

## 2. Pull Request Reviews API

**Source:** https://docs.github.com/en/rest/pulls/reviews?apiVersion=2022-11-28

### List Reviews

```
GET /repos/{owner}/{repo}/pulls/{pull_number}/reviews
```

Returns reviews in chronological order. Paginated (default 30, max 100 per page).

Each review object includes:

| Field                | Type     | Notes                                                  |
|----------------------|----------|--------------------------------------------------------|
| `id`                 | integer  | Numeric review ID                                      |
| `user.login`         | string   | Reviewer username                                      |
| `state`              | string   | `APPROVED`, `CHANGES_REQUESTED`, `COMMENTED`, `DISMISSED`, `PENDING` |
| `submitted_at`       | datetime | When the review was submitted                          |
| `commit_id`          | string   | SHA the review was submitted against                   |
| `author_association` | string   | `OWNER`, `MEMBER`, `CONTRIBUTOR`, etc.                 |
| `body`               | string   | Review body text                                       |

### Counting Unique Approvers

The API has no server-side filter for review state. Fetch all reviews and filter client-side. A reviewer can submit multiple reviews; only their latest review matters for approval status.

With `gh` CLI:

```bash
# Count unique approvers using gh pr view
gh pr view ${PR_NUMBER} --json reviews \
  --jq '[.reviews[] | select(.state == "APPROVED") | .author.login] | unique | length'
```

With `gh api` (handles pagination for large review lists):

```bash
gh api --paginate \
  repos/{owner}/{repo}/pulls/${PR_NUMBER}/reviews \
  --jq '[.[] | select(.state == "APPROVED") | .user.login] | unique | length'
```

**Important caveat:** A reviewer who first approves, then requests changes, then approves again will appear multiple times. To get the true current state, take only each user's most recent review:

```bash
gh api --paginate \
  repos/{owner}/{repo}/pulls/${PR_NUMBER}/reviews \
  --jq '
    [.[] | {login: .user.login, state: .state}]
    | group_by(.login)
    | map(last)
    | [.[] | select(.state == "APPROVED")]
    | length
  '
```

---

## 3. Idempotent PR Comments

### The Problem

A workflow that posts a PR comment on every run creates duplicates. The goal is one comment per workflow that gets updated on re-runs.

### Pattern: Hidden HTML Marker

Include an invisible HTML comment as a marker in the body. On subsequent runs, search for that marker to find the existing comment.

```html
<!-- skill-audit-results -->
```

This marker is invisible when rendered but detectable via API substring search.

### Approach A: `gh api` (No Third-Party Actions)

```bash
PR_NUMBER="${{ github.event.pull_request.number }}"
MARKER="<!-- skill-audit-results -->"

# Search for existing comment containing the marker
COMMENT_ID=$(gh api \
  "repos/{owner}/{repo}/issues/${PR_NUMBER}/comments" \
  --jq ".[] | select(.body | contains(\"${MARKER}\")) | .id")

BODY="${MARKER}
## Skill Audit Results
| Skill | Risk | Status |
|-------|------|--------|
| my-skill | low | passed |
"

if [ -n "$COMMENT_ID" ]; then
  gh api \
    --method PATCH \
    "repos/{owner}/{repo}/issues/comments/${COMMENT_ID}" \
    -f body="$BODY"
else
  gh api \
    --method POST \
    "repos/{owner}/{repo}/issues/${PR_NUMBER}/comments" \
    -f body="$BODY"
fi
```

**Relevant API endpoints:**

| Operation | Endpoint                                                  | Method |
|-----------|-----------------------------------------------------------|--------|
| List      | `/repos/{owner}/{repo}/issues/{issue_number}/comments`    | GET    |
| Create    | `/repos/{owner}/{repo}/issues/{issue_number}/comments`    | POST   |
| Update    | `/repos/{owner}/{repo}/issues/comments/{comment_id}`      | PATCH  |

Note: PRs are issues in GitHub's data model, so the Issues Comments API works for PR comments.

### Approach B: `peter-evans/find-comment` + `peter-evans/create-or-update-comment`

```yaml
- name: Find existing audit comment
  uses: peter-evans/find-comment@v4
  id: fc
  with:
    issue-number: ${{ github.event.pull_request.number }}
    comment-author: 'github-actions[bot]'
    body-includes: '<!-- skill-audit-results -->'

- name: Create or update audit comment
  uses: peter-evans/create-or-update-comment@v5
  with:
    comment-id: ${{ steps.fc.outputs.comment-id }}
    issue-number: ${{ github.event.pull_request.number }}
    body: |
      <!-- skill-audit-results -->
      ## Skill Audit Results
      ...
    edit-mode: replace
```

When `find-comment` returns an empty `comment-id` (evaluates to `0`), the action creates a new comment. When it finds a match, it updates via PATCH. The `edit-mode: replace` overwrites the entire body rather than appending.

**`find-comment` key inputs:** `issue-number`, `comment-author`, `body-includes` (substring match), `body-regex`, `direction` (`first`/`last`).

**`create-or-update-comment` key inputs:** `comment-id`, `issue-number`, `body`, `edit-mode` (`replace`/`append`).

---

## 4. Detecting Changed Files in a PR

### Option A: GitHub REST API

```
GET /repos/{owner}/{repo}/pulls/{pull_number}/files
```

Returns up to 3000 files. Each entry contains:

| Field               | Type   | Description                                              |
|---------------------|--------|----------------------------------------------------------|
| `filename`          | string | Full path of the changed file                            |
| `status`            | string | `added`, `removed`, `modified`, `renamed`, `copied`, `changed`, `unchanged` |
| `additions`         | int    | Lines added                                              |
| `deletions`         | int    | Lines removed                                            |
| `changes`           | int    | Total line changes                                       |
| `previous_filename` | string | Original name if renamed                                 |
| `patch`             | string | The diff content (optional, may be absent for binary)    |

Filter for files under a specific directory:

```bash
gh api --paginate \
  "repos/{owner}/{repo}/pulls/${PR_NUMBER}/files" \
  --jq '[.[] | select(.filename | startswith("skills/")) | .filename]'
```

### Option B: `gh pr diff --name-only`

```bash
gh pr diff ${PR_NUMBER} --name-only | grep '^skills/'
```

Simpler but returns only filenames, no metadata about additions/deletions/status.

### Option C: `gh pr view --json files`

```bash
gh pr view ${PR_NUMBER} --json files \
  --jq '[.files[] | select(.path | startswith("skills/")) | .path]'
```

Note: the `gh pr view --json files` output uses `path` (not `filename`) and includes `additions` and `deletions` fields.

### Option D: `git diff` (Within Actions Checkout)

```bash
git diff --name-only origin/main...HEAD -- skills/
```

Requires a full checkout with fetch-depth 0. Less reliable than the API for PRs from forks.

### Recommendation

Use the REST API (`gh api`) for the most complete data (status, additions, deletions, renames). Use `gh pr diff --name-only` for a quick filename-only check. Both handle fork PRs correctly without needing a deep clone.

---

## 5. PR Event Triggers

**Source:** https://docs.github.com/en/actions/writing-workflows/choosing-when-your-workflow-runs/events-that-trigger-workflows

### `pull_request` Event

Activity types (default triggers marked with *):

| Type                     | Description                           | Default |
|--------------------------|---------------------------------------|---------|
| `opened`                 | PR created                            | *       |
| `synchronize`            | New commits pushed                    | *       |
| `reopened`               | PR reopened                           | *       |
| `closed`                 | PR closed or merged                   |         |
| `edited`                 | Title, body, or base branch changed   |         |
| `ready_for_review`       | Moved from draft to ready             |         |
| `converted_to_draft`     | Converted to draft                    |         |
| `labeled` / `unlabeled`  | Label added/removed                   |         |
| `review_requested`       | Review requested                      |         |
| `assigned` / `unassigned`| Assignee changed                      |         |
| `locked` / `unlocked`    | Conversation locked/unlocked          |         |
| `enqueued` / `dequeued`  | Added to/removed from merge queue     |         |
| `auto_merge_enabled`     | Auto-merge toggled                    |         |

### `pull_request_review` Event

Activity types (all trigger by default):

| Type        | Description                   |
|-------------|-------------------------------|
| `submitted` | Review submitted              |
| `edited`    | Review body edited            |
| `dismissed` | Review dismissed              |

### Combined Workflow Trigger

To run an audit on both code changes and new reviews:

```yaml
on:
  pull_request:
    types: [opened, synchronize, reopened]
  pull_request_review:
    types: [submitted]
```

This triggers when:
1. A PR is opened, updated with new commits, or reopened.
2. A review is submitted (including approvals).

### Context Differences

The `github.event` payload differs between these triggers:
- `pull_request` events: `github.event.pull_request` is the PR object.
- `pull_request_review` events: `github.event.review` is the review object; the PR is at `github.event.pull_request`.

To get the PR number reliably in both cases: `${{ github.event.pull_request.number }}` works for both event types.

To get the head SHA:
- `pull_request`: `${{ github.event.pull_request.head.sha }}`
- `pull_request_review`: `${{ github.event.pull_request.head.sha }}` (also available)

---

## Takeaways

1. **Commit status `context` is the linchpin.** Set a descriptive context like `skill-audit/risk-check`. Branch protection matches this string exactly. Re-posting with the same context+SHA is idempotent.
2. **Reviews require client-side filtering.** Fetch all, group by user, take the last review per user, then count approvals. The `gh pr view --json reviews --jq` path is the most concise.
3. **Hidden HTML markers solve comment duplication.** The `gh api` approach avoids third-party action dependencies; the `peter-evans` actions provide a cleaner declarative YAML syntax.
4. **`gh api` with `--jq` and `startswith()` is the most robust way to detect changed files** under a specific directory, returning full metadata.
5. **Dual event triggers** (`pull_request` + `pull_request_review`) cover both code changes and approval events; `github.event.pull_request` is present in both payloads.
