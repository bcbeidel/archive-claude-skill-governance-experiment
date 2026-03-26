---
name: Skills API Deploy Patterns
description: Exact curl commands and API patterns for creating, versioning, and listing skills via the Anthropic Skills API for the deploy-skills workflow
type: context
sources:
  - https://platform.claude.com/docs/en/build-with-claude/skills-guide
  - https://platform.claude.com/docs/en/api/skills/create-skill
  - https://platform.claude.com/docs/en/api/skills/create-skill-version
  - https://platform.claude.com/docs/en/api/skills/list-skills
related:
  - docs/research/2026-03-25-skills-api-upload.research.md
  - docs/designs/2026-03-25-deploy-skills-workflow.design.md
---

## Required Headers

All Skills API requests need these three headers:

```bash
-H "x-api-key: $ANTHROPIC_API_KEY"
-H "anthropic-version: 2023-06-01"
-H "anthropic-beta: skills-2025-10-02"
```

## Create Skill (New)

Upload a zip file with `display_title`:

```bash
curl -X POST "https://api.anthropic.com/v1/skills" \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "anthropic-beta: skills-2025-10-02" \
  -F "display_title=${TITLE}" \
  -F "files[]=@${ZIP_PATH};filename=${ZIP_NAME}"
```

Response includes `id` (format: `skill_01AbCd...`) and `latest_version`.

## Create Version (Existing Skill)

Same format but no `display_title`, POST to version endpoint:

```bash
curl -X POST "https://api.anthropic.com/v1/skills/${SKILL_ID}/versions" \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "anthropic-beta: skills-2025-10-02" \
  -F "files[]=@${ZIP_PATH};filename=${ZIP_NAME}"
```

## List and Match Existing Skills

No name-based filter — must list all and match client-side:

```bash
curl -s "https://api.anthropic.com/v1/skills?source=custom&limit=100" \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "anthropic-beta: skills-2025-10-02" \
  | jq -r ".data[] | select(.display_title == \"${TITLE}\") | .id"
```

If match found → create new version. If no match → create new skill.
Paginate with `has_more` and `next_page` if >100 skills.

## Deploy Script Flow

```
For each skills/*/SKILL.md:
  1. Extract `name` from SKILL.md YAML frontmatter → use as display_title
  2. Zip the skill directory
  3. List existing skills, search for matching display_title
  4. If found: POST /v1/skills/{id}/versions with zip
  5. If not found: POST /v1/skills with display_title + zip
  6. Log result (created/updated/failed)
```

## Constraints

- Max 8MB per upload
- SKILL.md must be at the root of the zip
- `name` field: max 64 chars, lowercase letters/numbers/hyphens only
- `description` field: max 1024 chars, non-empty
