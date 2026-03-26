---
name: Claude Code CI Invocation
description: How to install, authenticate, and invoke Claude Code CLI in GitHub Actions for non-interactive skill auditing with parseable output
type: context
sources:
  - https://code.claude.com/docs/en/headless
  - https://code.claude.com/docs/en/cli-reference
  - https://code.claude.com/docs/en/github-actions
  - https://code.claude.com/docs/en/skills
  - https://code.claude.com/docs/en/authentication
related:
  - docs/research/2026-03-25-skill-audit-workflow.research.md
  - docs/context/github-api-audit-patterns.context.md
  - docs/designs/2026-03-25-skill-audit-workflow.design.md
---

## Installation

```bash
npm install -g @anthropic-ai/claude-code
```

Or use `npx @anthropic-ai/claude-code` to avoid global install.

## Authentication

Set `ANTHROPIC_API_KEY` as an environment variable. In GitHub Actions:

```yaml
env:
  ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
```

## Non-Interactive Invocation

The `-p` / `--print` flag is required for CI — it processes the prompt,
writes to stdout, and exits.

Key flags for the audit workflow:

| Flag | Purpose |
|------|---------|
| `-p "prompt"` | Non-interactive mode (required) |
| `--output-format json` | Structured output with `result` field |
| `--max-turns N` | Limit agentic turns to prevent runaway |
| `--dangerously-skip-permissions` | Bypass permission prompts in CI |
| `--model sonnet` | Model selection (sonnet for speed, opus for depth) |

## Skill Auto-Discovery

Without `--bare`, Claude Code in `-p` mode loads CLAUDE.md, skills, and
context from the repo. The audit-skill's description will match when
prompted naturally:

```bash
claude -p "Audit the skill at skills/my-skill/ following the audit-skill workflow" \
  --output-format json \
  --max-turns 10 \
  --dangerously-skip-permissions
```

No need for `/audit-skill` syntax (not available in `-p` mode) or
`--append-system-prompt-file`. Just describe the task.

## Output Capture and Rating Extraction

```bash
RESULT=$(claude -p "Audit the skill at ${SKILL_PATH}" \
  --output-format json \
  --max-turns 10 \
  --dangerously-skip-permissions)

# Extract the full report text
REPORT=$(echo "$RESULT" | jq -r '.result')

# Extract the risk rating
RATING=$(echo "$REPORT" | grep -oP 'Overall Risk Rating: \K(LOW|MEDIUM|HIGH)')
```

The report template uses `## Overall Risk Rating: [LOW | MEDIUM | HIGH]`
consistently, making grep extraction reliable.

## Alternative: Structured Output

For more robust parsing, use `--json-schema` to force a structured response:

```bash
claude -p "Audit the skill at ${SKILL_PATH}. Return the result as JSON." \
  --output-format json \
  --json-schema '{"type":"object","properties":{"rating":{"type":"string","enum":["LOW","MEDIUM","HIGH"]},"report":{"type":"string"}},"required":["rating","report"]}'
```

The rating then appears in `.structured_output.rating` — no grep needed.
