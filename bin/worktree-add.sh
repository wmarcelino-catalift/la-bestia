#!/usr/bin/env bash
# worktree-add.sh — create a new git worktree for a feature.
#
# Usage:
#   bash bin/worktree-add.sh <slug>
#
# Env vars (override defaults):
#   WT_BASE             default: ../worktrees
#   WT_BRANCH_PREFIX    default: feat/
#   WT_BASE_BRANCH      default: main (the branch to fork from)
#
# Exit codes:
#   0 = worktree created
#   1 = bad usage
#   2 = git error (not a repo, branch exists, etc.)

set -euo pipefail

SLUG="${1:-}"
if [ -z "$SLUG" ]; then
  echo "usage: $0 <slug>" >&2
  echo "  slug:  short name for the feature, e.g. 'oauth-rbac'" >&2
  exit 1
fi

# Validate slug shape (kebab-case alphanumeric).
if [[ ! "$SLUG" =~ ^[a-z][a-z0-9-]{1,40}[a-z0-9]$ ]]; then
  echo "error: slug must be kebab-case alphanumeric, 3-42 chars" >&2
  exit 1
fi

WT_BASE="${WT_BASE:-../worktrees}"
WT_BRANCH_PREFIX="${WT_BRANCH_PREFIX:-feat/}"
WT_BASE_BRANCH="${WT_BASE_BRANCH:-main}"

# Must be inside a git repo.
if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "error: not inside a git repository" >&2
  exit 2
fi

REPO_ROOT=$(git rev-parse --show-toplevel)
WT_PATH="$REPO_ROOT/$WT_BASE/$SLUG"
WT_BRANCH="${WT_BRANCH_PREFIX}${SLUG}"

# Refuse to create a worktree inside the main repo (avoids confusion).
case "$WT_BASE" in
  /*)  : ;;                                       # absolute paths OK
  ../*) : ;;                                      # parent paths OK
  ./*|*)
    if [[ "$WT_BASE" != ../* ]]; then
      echo "warning: WT_BASE='$WT_BASE' is inside the repo. Recommended: '../worktrees'." >&2
    fi
  ;;
esac

# Refuse if branch already exists.
if git show-ref --verify --quiet "refs/heads/$WT_BRANCH"; then
  echo "error: branch '$WT_BRANCH' already exists" >&2
  echo "  remove it first: git branch -D $WT_BRANCH" >&2
  echo "  or pick a different slug." >&2
  exit 2
fi

# Refuse if path already exists.
if [ -e "$WT_PATH" ]; then
  echo "error: path '$WT_PATH' already exists" >&2
  exit 2
fi

mkdir -p "$(dirname "$WT_PATH")"

# Create the worktree.
echo "[worktree-add] $WT_BRANCH @ $WT_PATH (from $WT_BASE_BRANCH)"
git worktree add "$WT_PATH" -b "$WT_BRANCH" "$WT_BASE_BRANCH"

# Hint next steps.
cat <<EOF

✓ worktree ready: $WT_PATH
  branch:        $WT_BRANCH
  base:          $WT_BASE_BRANCH

Next steps:
  cd "$WT_PATH"
  claude
  > /flow "<feature description>"

Cleanup when done:
  bash bin/worktree-remove.sh $SLUG
EOF
