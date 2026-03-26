#!/usr/bin/env bash
# detect-skill-changes.sh
# Detects new or modified skills in a PR by querying the GitHub API.
#
# Required environment variables:
#   PR_NUMBER - Pull request number
#   REPO      - Repository in owner/repo format (e.g., org/repo-name)
#
# Output:
#   Newline-separated list of changed skill directory paths (e.g., skills/my-skill)
#   Empty output if no skills changed.

set -euo pipefail

: "${PR_NUMBER:?PR_NUMBER is required}"
: "${REPO:?REPO is required}"

# Get all files changed in the PR, filter to skills/ directory
CHANGED_FILES=$(gh api --paginate \
  "repos/${REPO}/pulls/${PR_NUMBER}/files" \
  --jq '[.[] | select(.filename | startswith("skills/")) | .filename] | .[]' \
  2>/dev/null || true)

if [ -z "$CHANGED_FILES" ]; then
  exit 0
fi

# Extract unique skill directories (skills/<name>)
SKILL_DIRS=$(echo "$CHANGED_FILES" \
  | sed 's|^\(skills/[^/]*\)/.*|\1|' \
  | sort -u)

# Validate each detected skill directory contains a SKILL.md
for dir in $SKILL_DIRS; do
  if [ -f "${dir}/SKILL.md" ]; then
    echo "$dir"
  fi
done
