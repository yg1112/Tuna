#!/usr/bin/env bash
set -euo pipefail

REPO="yg1112/Tuna"
BRANCH="main"

curl -s -X PUT -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  -d '{
    "required_status_checks": {
      "strict": true,
      "checks": [ { "context": "Tuna CI / test" } ]
    },
    "required_pull_request_reviews": {
      "dismiss_stale_reviews": true,
      "required_approving_review_count": 1
    },
    "enforce_admins": true,
    "restrictions": null,
    "required_linear_history": true,
    "allow_force_pushes": false,
    "allow_deletions": false
  }' \
"https://api.github.com/repos/${REPO}/branches/${BRANCH}/protection"
echo "✅ Branch protection applied to ${BRANCH}" 