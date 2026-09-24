#!/usr/bin/env bash
# scripts/prune-merged-local-branches.sh
# Deletes local branches whose remote-tracking branch has disappeared
# (typically: merged upstream, then auto-deleted). Dry-run by default.
set -euo pipefail

YES=false
[[ "${1:-}" == "-y" || "${1:-}" == "--yes" ]] && YES=true

current_branch=$(git branch --show-current)
git fetch --prune --quiet

gone_branches=$(git branch -vv | awk -v cur="$current_branch" '
  $1 == cur { next }
  /: gone\]/ { sub(/^\*?[[:space:]]+/, ""); print $1 }
')

if [ -z "$gone_branches" ]; then
  echo "Nothing to clean up — no local branch has a deleted remote counterpart."
  exit 0
fi

echo "Local branches whose remote is gone:"
echo "$gone_branches" | sed 's/^/  /'

if ! $YES; then
  echo
  echo "Dry run only. Re-run with -y/--yes to delete them (git branch -D)."
  echo "Note: this repo squash-merges PRs, so the commits aren't ancestors of"
  echo "main — 'git branch -d' would refuse them as unmerged even though they"
  echo "really were. That's why this uses -D. 'gone' usually means merged +"
  echo "auto-deleted, but could also mean someone deleted the remote branch"
  echo "without merging — skim the list above before confirming."
  exit 0
fi

echo "$gone_branches" | xargs -r git branch -D
