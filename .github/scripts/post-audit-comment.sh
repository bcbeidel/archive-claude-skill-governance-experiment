#!/usr/bin/env bash
# post-audit-comment.sh
# Posts or updates a PR comment with audit results using a hidden marker
# for idempotency.
#
# Required environment variables:
#   PR_NUMBER - Pull request number
#   REPO      - Repository in owner/repo format
#   BODY      - The comment body content (markdown)
#
# The script prepends a hidden HTML marker to the body. On re-runs, it
# finds the existing comment by marker and updates it rather than creating
# a duplicate.

set -euo pipefail

: "${PR_NUMBER:?PR_NUMBER is required}"
: "${REPO:?REPO is required}"
: "${BODY:?BODY is required}"

MARKER="<!-- skill-audit-results -->"
FULL_BODY="${MARKER}
${BODY}"

# Search for existing comment containing the marker
COMMENT_ID=$(gh api \
  "repos/${REPO}/issues/${PR_NUMBER}/comments" \
  --jq ".[] | select(.body | contains(\"${MARKER}\")) | .id" \
  2>/dev/null | head -1 || true)

if [ -n "$COMMENT_ID" ]; then
  # Update existing comment
  gh api --method PATCH \
    "repos/${REPO}/issues/comments/${COMMENT_ID}" \
    -f body="${FULL_BODY}" \
    --silent
  echo "Updated existing comment ${COMMENT_ID}"
else
  # Create new comment
  gh api --method POST \
    "repos/${REPO}/issues/${PR_NUMBER}/comments" \
    -f body="${FULL_BODY}" \
    --silent
  echo "Created new comment"
fi
