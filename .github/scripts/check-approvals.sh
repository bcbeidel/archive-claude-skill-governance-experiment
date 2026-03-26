#!/usr/bin/env bash
# check-approvals.sh
# Checks whether a PR has enough approvals for its risk level and sets
# a commit status accordingly.
#
# Required environment variables:
#   PR_NUMBER   - Pull request number
#   REPO        - Repository in owner/repo format
#   SHA         - Commit SHA to set the status on
#   RISK_RATING - One of: LOW, MEDIUM, HIGH
#
# Sets commit status "skill-audit/approval-gate" to success or failure.

set -euo pipefail

: "${PR_NUMBER:?PR_NUMBER is required}"
: "${REPO:?REPO is required}"
: "${SHA:?SHA is required}"
: "${RISK_RATING:?RISK_RATING is required}"

# Map risk rating to required approval count
case "$RISK_RATING" in
  LOW)    REQUIRED=1 ;;
  MEDIUM) REQUIRED=2 ;;
  HIGH)   REQUIRED=3 ;;
  *)
    echo "Error: Invalid RISK_RATING '${RISK_RATING}'. Must be LOW, MEDIUM, or HIGH." >&2
    exit 1
    ;;
esac

# Count unique approvers by taking each user's last review
APPROVALS=$(gh api --paginate \
  "repos/${REPO}/pulls/${PR_NUMBER}/reviews" \
  --jq '
    [.[] | {login: .user.login, state: .state}]
    | group_by(.login)
    | map(last)
    | [.[] | select(.state == "APPROVED")]
    | length
  ' 2>/dev/null || echo "0")

# Determine status
if [ "$APPROVALS" -ge "$REQUIRED" ]; then
  STATE="success"
  DESCRIPTION="${APPROVALS}/${REQUIRED} approvals met (${RISK_RATING} risk)"
else
  STATE="failure"
  DESCRIPTION="${APPROVALS}/${REQUIRED} approvals — need ${REQUIRED} for ${RISK_RATING} risk"
fi

# Set commit status
gh api --method POST \
  "repos/${REPO}/statuses/${SHA}" \
  -f state="${STATE}" \
  -f context="skill-audit/approval-gate" \
  -f description="${DESCRIPTION}" \
  -f target_url="https://github.com/${REPO}/pull/${PR_NUMBER}" \
  --silent

echo "${STATE}: ${DESCRIPTION}"
