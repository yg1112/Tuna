#!/usr/bin/env bash
set -euo pipefail

REPO="yg1112/Tuna"
PR_NUMBER="${1:?need PR number}"
CI_NAME="Tuna CI / test"

# 1) get head SHA of the PR
HEAD_SHA=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
    "https://api.github.com/repos/$REPO/pulls/$PR_NUMBER" | jq -r .head.sha)

echo "🕒 Waiting for $CI_NAME on $HEAD_SHA …"

while true; do
  STATUS=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
     "https://api.github.com/repos/$REPO/commits/$HEAD_SHA/status" | \
     jq -r --arg name "$CI_NAME" '.statuses[] | select(.context==$name) | .state' | head -n1)

  case "$STATUS" in
    success) echo "✅ CI green"; break ;;
    failure|error) echo "❌ CI failed"; exit 1 ;;
    pending|"") ;; # keep waiting
  esac
  sleep 30
done

echo "🔀 Merging PR #$PR_NUMBER"
curl -s -X PUT -H "Authorization: token $GITHUB_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"merge_method":"squash"}' \
  "https://api.github.com/repos/$REPO/pulls/$PR_NUMBER/merge" | jq . 