#!/usr/bin/env bash
set -euo pipefail
git fetch -p origin
for b in $(git branch --format='%(refname:short)' --merged main | grep '^dev-'); do
  git branch -d "$b" || true
  git push origin --delete "$b" 2>/dev/null || true
done
echo "✅ cleaned merged dev- branches" 