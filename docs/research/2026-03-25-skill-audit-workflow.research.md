---
name: Skill Audit Workflow Technical Requirements
description: Technical research on Claude Code CLI in CI, GitHub APIs for status checks, PR reviews, idempotent comments, and changed file detection needed for the skill-audit GitHub Actions workflow
type: research
sources:
  - https://code.claude.com/docs/en/headless
  - https://code.claude.com/docs/en/cli-reference
  - https://code.claude.com/docs/en/github-actions
  - https://github.com/anthropics/claude-code-action
  - https://code.claude.com/docs/en/skills
  - https://code.claude.com/docs/en/authentication
  - https://docs.github.com/en/rest/commits/statuses?apiVersion=2022-11-28
  - https://docs.github.com/en/rest/pulls/reviews?apiVersion=2022-11-28
  - https://docs.github.com/en/rest/issues/comments?apiVersion=2022-11-28
  - https://docs.github.com/en/rest/pulls/pulls?apiVersion=2022-11-28
  - https://docs.github.com/en/actions/writing-workflows/choosing-when-your-workflow-runs/events-that-trigger-workflows
  - https://github.com/peter-evans/create-or-update-comment
related:
  - docs/designs/2026-03-25-skill-audit-workflow.design.md
  - docs/research/2026-03-25-github-api-pr-audit-patterns.research.md
---

## Key Findings

1. **Official GitHub Action exists**: `anthropics/claude-code-action@v1`
   handles Claude Code invocation in GitHub Actions with built-in PR
   commenting. However, for our custom audit workflow we need more control
   over output parsing and status checks, so we'll use the CLI directly.

2. **Claude Code CLI `-p` flag** is the key for CI: non-interactive mode
   that processes a prompt, writes to stdout, and exits. Combined with
   `--output-format json`, output is parseable for rating extraction.

3. **Skills auto-discover without `--bare`**: If we don't use `--bare`,
   Claude Code in `-p` mode loads CLAUDE.md, skills, and context from the
   repo. The audit-skill's description will match naturally when we prompt
   "Audit the skill at X".

4. **Commit status API is inherently idempotent**: posting the same
   `context` + SHA overwrites the previous status. Branch protection
   matches the `context` string by name.

5. **PR comments need a hidden marker** (`<!-- skill-audit-results -->`)
   to find-and-update rather than duplicate.

---

## Findings by Sub-Question

### 1. Claude Code CLI in GitHub Actions

**Installation:** `npm install -g @anthropic-ai/claude-code` or use `npx`.

**Non-interactive mode flags:**

| Flag | Purpose |
|------|---------|
| `-p` / `--print` | Required for CI. Processes prompt, prints to stdout, exits |
| `--output-format json` | Structured output with `result` field for parsing |
| `--max-turns N` | Limit agentic turns (prevents runaway) |
| `--allowedTools "Tool1,Tool2"` | Auto-approve specific tools |
| `--dangerously-skip-permissions` | Bypass all permission prompts |
| `--model <name>` | Model selection (sonnet, opus) |

**Authentication:** Set `ANTHROPIC_API_KEY` environment variable. In GitHub
Actions: `env: ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}`.

**Skill invocation in `-p` mode:** User-invoked `/skill-name` syntax is NOT
available in `-p` mode. Instead, describe the task naturally — without
`--bare`, skills auto-discover and Claude will use the audit-skill when
prompted to "audit the skill at X".

**Alternatively**, use `--append-system-prompt-file` to inject the skill's
SKILL.md directly as system prompt context.

**Output capture:**
```bash
RESULT=$(claude -p "Audit the skill at skills/my-skill/" \
  --output-format json \
  --max-turns 10 \
  --dangerously-skip-permissions)
REPORT=$(echo "$RESULT" | jq -r '.result')
```

**Confidence: HIGH** — T1 sources from official Anthropic documentation.

### 2. GitHub Commit Status API

**Endpoint:** `POST /repos/{owner}/{repo}/statuses/{sha}`

**Fields:** `state` (error/failure/pending/success), `context` (label name),
`description` (short summary), `target_url` (link to details).

**Branch protection** matches the `context` string exactly (case-insensitive).
Use a descriptive name like `skill-audit/approval-gate`.

**Idempotency:** Re-posting the same context + SHA overwrites the previous
status. Safe to re-run.

```bash
gh api --method POST \
  "repos/{owner}/{repo}/statuses/${SHA}" \
  -f state="success" \
  -f context="skill-audit/approval-gate" \
  -f description="1/1 approvals met (LOW risk)"
```

**Confidence: HIGH** — T1 GitHub official docs.

### 3. PR Reviews/Approvals API

**Endpoint:** `GET /repos/{owner}/{repo}/pulls/{pull_number}/reviews`

No server-side state filter — fetch all, filter client-side. A reviewer
can submit multiple reviews; take each user's last review.

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

**Confidence: HIGH** — T1 GitHub official docs.

### 4. Idempotent PR Comments

**Pattern:** Hidden HTML marker in comment body.

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

PRs are issues in GitHub's data model, so the Issues Comments API works.

**Confidence: HIGH** — T1 GitHub docs + widely used pattern.

### 5. Detecting Changed Files in a PR

**Best approach:**
```bash
gh api --paginate \
  "repos/{owner}/{repo}/pulls/${PR_NUMBER}/files" \
  --jq '[.[] | select(.filename | startswith("skills/")) | .filename]'
```

Returns full metadata (status, additions, deletions). Handles fork PRs
correctly. Max 3000 files.

**Quick alternative:** `gh pr diff ${PR_NUMBER} --name-only | grep '^skills/'`

**Grouping by skill directory:** Extract unique parent directories containing
SKILL.md to identify which skills changed:
```bash
CHANGED_FILES | sed 's|/[^/]*$||' | sort -u
```

**Confidence: HIGH** — T1 GitHub docs.

---

## Challenge

### Key Risk: Claude Code Output Parsing

The workflow needs to extract the overall risk rating (LOW/MEDIUM/HIGH) from
Claude's output. Two concerns:

1. **Format consistency**: The audit-skill produces a report following a
   template, but LLM output can vary slightly. Using `--output-format json`
   gives us structured access to the `result` field, but the rating is
   embedded in markdown text, not a structured field.

2. **Mitigation**: Use `grep -oP 'Overall Risk Rating: \K(LOW|MEDIUM|HIGH)'`
   to extract the rating from the report text. The report template has a
   consistent format (`## Overall Risk Rating: [LOW | MEDIUM | HIGH]`).
   Alternatively, use `--json-schema` to force structured output with the
   rating as a separate field.

### Key Risk: Workflow Permissions

The workflow needs to:
- Post PR comments (requires `issues: write` or `pull-requests: write`)
- Set commit statuses (requires `statuses: write`)
- Read PR files (requires `contents: read`)
- Add labels (requires `issues: write` or `pull-requests: write`)

These must be explicitly set in the workflow's `permissions` block.

---

## Claims

| # | Claim | Type | Source | Status |
|---|-------|------|--------|--------|
| 1 | `-p` flag enables non-interactive mode | attribution | CLI docs | verified |
| 2 | Skills auto-discover without `--bare` | attribution | Skills docs | verified |
| 3 | Commit status context is case-insensitive match | attribution | GitHub docs | verified |
| 4 | Reviews API has no server-side state filter | attribution | GitHub docs | verified |
| 5 | PR files API returns max 3000 files | statistic | GitHub docs | verified |
| 6 | PRs are issues in GitHub's data model | attribution | GitHub docs | verified |
