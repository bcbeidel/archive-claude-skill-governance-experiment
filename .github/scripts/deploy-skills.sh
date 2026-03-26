#!/usr/bin/env bash
# deploy-skills.sh
# Deploys all skills from skills/ to a Claude organization workspace
# via the Anthropic Skills API.
#
# Required environment variables:
#   ANTHROPIC_API_KEY - API key for the target workspace
#
# Optional environment variables:
#   SKILLS_DIR - Directory containing skills (default: skills)
#   API_BASE   - API base URL (default: https://api.anthropic.com)
#
# Flags:
#   --delete-orphans  Remove skills from API that are no longer in the repo
#
# For each skill directory containing SKILL.md:
#   1. Extract name from YAML frontmatter → use as display_title
#   2. Zip the skill directory
#   3. Check if skill already exists (list + match by display_title)
#   4. Create new skill or new version of existing skill
#   5. Log result

set -uo pipefail

: "${ANTHROPIC_API_KEY:?ANTHROPIC_API_KEY is required}"

DELETE_ORPHANS=false
for arg in "$@"; do
  case "$arg" in
    --delete-orphans) DELETE_ORPHANS=true ;;
  esac
done

SKILLS_DIR="${SKILLS_DIR:-skills}"
API_BASE="${API_BASE:-https://api.anthropic.com}"
API_HEADERS=(
  -H "x-api-key: ${ANTHROPIC_API_KEY}"
  -H "anthropic-version: 2023-06-01"
  -H "anthropic-beta: skills-2025-10-02"
)

CREATED=0
UPDATED=0
FAILED=0
SKIPPED=0

# --- Helper Functions ---

extract_name() {
  # Extract 'name' field from SKILL.md YAML frontmatter
  local skill_md="$1"
  sed -n '/^---$/,/^---$/p' "$skill_md" | grep '^name:' | head -1 | sed 's/^name:[[:space:]]*//'
}

list_existing_skills() {
  # Fetch all custom skills, paginating if needed. Output: id<tab>display_title per line.
  local page=""
  local has_more="true"

  while [ "$has_more" = "true" ]; do
    local url="${API_BASE}/v1/skills?source=custom&limit=100"
    if [ -n "$page" ]; then
      url="${url}&page=${page}"
    fi

    local response
    response=$(curl -s -w "\n%{http_code}" "$url" "${API_HEADERS[@]}" 2>/dev/null)
    local http_code
    http_code=$(echo "$response" | tail -1)
    local body
    body=$(echo "$response" | sed '$d')

    if [ "$http_code" != "200" ]; then
      echo "Warning: Failed to list skills (HTTP ${http_code})" >&2
      return 1
    fi

    echo "$body" | jq -r '.data[] | [.id, .display_title] | @tsv' 2>/dev/null

    has_more=$(echo "$body" | jq -r '.has_more // false' 2>/dev/null)
    page=$(echo "$body" | jq -r '.next_page // empty' 2>/dev/null)
  done
}

find_skill_id() {
  # Find skill ID by display_title from the cached skill list
  local title="$1"
  local skill_list="$2"
  echo "$skill_list" | awk -F'\t' -v title="$title" '$2 == title { print $1; exit }'
}

create_skill() {
  local title="$1"
  local zip_path="$2"
  local zip_name
  zip_name=$(basename "$zip_path")

  local response
  response=$(curl -s -w "\n%{http_code}" -X POST "${API_BASE}/v1/skills" \
    "${API_HEADERS[@]}" \
    -F "display_title=${title}" \
    -F "files[]=@${zip_path};filename=${zip_name}" 2>/dev/null)

  local http_code
  http_code=$(echo "$response" | tail -1)
  local body
  body=$(echo "$response" | sed '$d')

  if [ "$http_code" = "200" ] || [ "$http_code" = "201" ]; then
    local skill_id
    skill_id=$(echo "$body" | jq -r '.id // "unknown"' 2>/dev/null)
    echo "  CREATED: ${title} → ${skill_id}"
    return 0
  else
    echo "  FAILED to create ${title} (HTTP ${http_code})" >&2
    echo "  Response: $(echo "$body" | head -c 200)" >&2
    return 1
  fi
}

update_skill() {
  local skill_id="$1"
  local zip_path="$2"
  local zip_name
  zip_name=$(basename "$zip_path")

  local response
  response=$(curl -s -w "\n%{http_code}" -X POST \
    "${API_BASE}/v1/skills/${skill_id}/versions" \
    "${API_HEADERS[@]}" \
    -F "files[]=@${zip_path};filename=${zip_name}" 2>/dev/null)

  local http_code
  http_code=$(echo "$response" | tail -1)
  local body
  body=$(echo "$response" | sed '$d')

  if [ "$http_code" = "200" ] || [ "$http_code" = "201" ]; then
    local version
    version=$(echo "$body" | jq -r '.version // "unknown"' 2>/dev/null)
    echo "  UPDATED: ${skill_id} → version ${version}"
    return 0
  else
    echo "  FAILED to update ${skill_id} (HTTP ${http_code})" >&2
    echo "  Response: $(echo "$body" | head -c 200)" >&2
    return 1
  fi
}

delete_skill() {
  local skill_id="$1"
  local title="$2"

  # Delete all versions first (API requirement)
  local versions
  versions=$(curl -s "${API_BASE}/v1/skills/${skill_id}/versions?limit=100" \
    "${API_HEADERS[@]}" 2>/dev/null \
    | jq -r '.data[].version' 2>/dev/null || true)

  for version in $versions; do
    curl -s -X DELETE \
      "${API_BASE}/v1/skills/${skill_id}/versions/${version}" \
      "${API_HEADERS[@]}" --silent 2>/dev/null || true
  done

  # Delete the skill
  local response
  response=$(curl -s -w "\n%{http_code}" -X DELETE \
    "${API_BASE}/v1/skills/${skill_id}" \
    "${API_HEADERS[@]}" 2>/dev/null)
  local http_code
  http_code=$(echo "$response" | tail -1)

  if [ "$http_code" = "200" ]; then
    echo "  DELETED: ${title} (${skill_id})"
    return 0
  else
    echo "  FAILED to delete ${title} (HTTP ${http_code})" >&2
    return 1
  fi
}

# --- Main ---

echo "=== Skill Deployment ==="
echo "Skills directory: ${SKILLS_DIR}"
echo ""

# Discover skills
SKILL_DIRS=$(find "$SKILLS_DIR" -name "SKILL.md" -maxdepth 2 | sed 's|/SKILL.md$||' | sort)

if [ -z "$SKILL_DIRS" ]; then
  echo "No skills found in ${SKILLS_DIR}/"
  exit 0
fi

echo "Skills found:"
for dir in $SKILL_DIRS; do
  echo "  - ${dir}"
done
echo ""

# Fetch existing skills once
echo "Fetching existing skills from API..."
EXISTING_SKILLS=$(list_existing_skills 2>/dev/null || true)
echo "Found $(echo "$EXISTING_SKILLS" | grep -c '.' || echo 0) existing skills"
echo ""

# Deploy each skill
for SKILL_DIR in $SKILL_DIRS; do
  SKILL_MD="${SKILL_DIR}/SKILL.md"
  SKILL_NAME=$(extract_name "$SKILL_MD")

  if [ -z "$SKILL_NAME" ]; then
    echo "[SKIP] ${SKILL_DIR} — no 'name' field in SKILL.md frontmatter"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  echo "[DEPLOY] ${SKILL_DIR} (name: ${SKILL_NAME})"

  # Zip the skill directory
  ZIP_PATH="/tmp/${SKILL_NAME}.zip"
  (cd "$(dirname "$SKILL_DIR")" && zip -r "$ZIP_PATH" "$(basename "$SKILL_DIR")" -x '*.gitkeep') > /dev/null 2>&1

  if [ ! -f "$ZIP_PATH" ]; then
    echo "  FAILED: Could not create zip"
    FAILED=$((FAILED + 1))
    continue
  fi

  # Check if skill exists
  EXISTING_ID=$(find_skill_id "$SKILL_NAME" "$EXISTING_SKILLS")

  if [ -n "$EXISTING_ID" ]; then
    if update_skill "$EXISTING_ID" "$ZIP_PATH"; then
      UPDATED=$((UPDATED + 1))
    else
      FAILED=$((FAILED + 1))
    fi
  else
    if create_skill "$SKILL_NAME" "$ZIP_PATH"; then
      CREATED=$((CREATED + 1))
    else
      FAILED=$((FAILED + 1))
    fi
  fi

  # Cleanup
  rm -f "$ZIP_PATH"
  echo ""
done

# Orphan reconciliation
ORPHANED=0
DELETED=0

# Build list of repo skill names
REPO_SKILL_NAMES=""
for SKILL_DIR in $SKILL_DIRS; do
  NAME=$(extract_name "${SKILL_DIR}/SKILL.md")
  if [ -n "$NAME" ]; then
    REPO_SKILL_NAMES="${REPO_SKILL_NAMES} ${NAME}"
  fi
done

# Check each existing API skill against repo
if [ -n "$EXISTING_SKILLS" ]; then
  while IFS=$'\t' read -r SKILL_ID DISPLAY_TITLE; do
    [ -z "$SKILL_ID" ] && continue
    if ! echo "$REPO_SKILL_NAMES" | grep -qw "$DISPLAY_TITLE"; then
      ORPHANED=$((ORPHANED + 1))
      if [ "$DELETE_ORPHANS" = "true" ]; then
        echo "[DELETE] ${DISPLAY_TITLE} (${SKILL_ID}) — not in repo"
        if delete_skill "$SKILL_ID" "$DISPLAY_TITLE"; then
          DELETED=$((DELETED + 1))
        else
          FAILED=$((FAILED + 1))
        fi
      else
        echo "[ORPHAN] ${DISPLAY_TITLE} (${SKILL_ID}) — deployed but not in repo"
      fi
    fi
  done <<< "$EXISTING_SKILLS"
fi

# Summary
echo ""
echo "=== Deployment Summary ==="
echo "Created:  ${CREATED}"
echo "Updated:  ${UPDATED}"
echo "Failed:   ${FAILED}"
echo "Skipped:  ${SKIPPED}"
echo "Orphaned: ${ORPHANED}"
if [ "$DELETE_ORPHANS" = "true" ]; then
  echo "Deleted:  ${DELETED}"
fi

if [ "$ORPHANED" -gt 0 ] && [ "$DELETE_ORPHANS" = "false" ]; then
  echo ""
  echo "To remove orphaned skills, re-run with --delete-orphans"
fi

if [ "$FAILED" -gt 0 ]; then
  exit 1
fi
