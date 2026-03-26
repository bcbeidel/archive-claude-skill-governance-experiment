---
name: Skills API Upload Mechanics
description: Exact curl commands, headers, request/response formats for creating, versioning, and listing skills via the Anthropic Skills API
type: research
sources:
  - https://platform.claude.com/docs/en/build-with-claude/skills-guide
  - https://platform.claude.com/docs/en/api/skills/list-skills
  - https://platform.claude.com/docs/en/api/skills/create-skill
  - https://platform.claude.com/docs/en/api/skills/create-skill-version
  - https://platform.claude.com/docs/en/api/skills/list-skill-versions
related:
  - docs/designs/2026-03-25-deploy-skills-workflow.design.md
  - docs/research/2026-03-25-skill-audit-workflow.research.md
---

## Key Findings

1. **Upload via multipart form**: `POST /v1/skills` accepts `display_title`
   and `files[]` as multipart form fields. Files can be individual
   (`-F "files[]=@path;filename=path"`) or a zip.

2. **No name-based lookup**: The API has no filter parameter for
   `display_title` or `name`. Must list all custom skills and match
   client-side.

3. **Version creation is same format minus display_title**: `POST
   /v1/skills/{id}/versions` takes only `files[]`. Returns a version
   object with `name` from SKILL.md frontmatter.

4. **display_title vs name**: `display_title` is set at creation (API-level
   label). `name` comes from SKILL.md and appears on version objects.
   Use `display_title` for matching since it's on the Skill object directly.

5. **Required headers**: `x-api-key`, `anthropic-version: 2023-06-01`,
   `anthropic-beta: skills-2025-10-02`.

---

## API Patterns for Deploy Script

### Create Skill (new)

```bash
curl -X POST "https://api.anthropic.com/v1/skills" \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "anthropic-beta: skills-2025-10-02" \
  -F "display_title=My Skill" \
  -F "files[]=@skill.zip;filename=skill.zip"
```

Response: `{"id": "skill_01...", "display_title": "...", "latest_version": "..."}`

### Create Version (existing skill)

```bash
curl -X POST "https://api.anthropic.com/v1/skills/${SKILL_ID}/versions" \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "anthropic-beta: skills-2025-10-02" \
  -F "files[]=@skill.zip;filename=skill.zip"
```

Response: `{"version": "1759178010641129", "name": "...", "skill_id": "..."}`

### List Custom Skills

```bash
curl "https://api.anthropic.com/v1/skills?source=custom&limit=100" \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "anthropic-beta: skills-2025-10-02"
```

Response: `{"data": [{"id": "...", "display_title": "..."}], "has_more": false}`

### Matching Strategy

List all custom skills, iterate through `data` array, compare
`display_title` against the skill name derived from SKILL.md. If match
found, create new version. If no match, create new skill.

**Confidence: HIGH** — T1 source from Anthropic API docs.
