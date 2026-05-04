#!/usr/bin/env bash
# worktree-remove.sh — clean up a feature worktree + its branch (if mergeable).
#
# Usage:
#   bash bin/worktree-remove.sh <slug> [--force]
#
# Env vars:
#   WT_BASE             default: ../worktrees
#   WT_BRANCH_PREFIX    default: feat/
#
# By default, refuses to remove if branch has unmerged commits.
# Pass --force to skip the merge check.
#
# Exit codes:
#   0 = removed cleanly
#   1 = bad usage
#   2 = unmerged commits (use --force) or git error

set -euo pipefail

SLUG="${1:-}"
FORCE=0
if [ "${2:-}" = "--force" ]; then FORCE=1; fi

if [ -z "$SLUG" ]; then
  echo "usage: $0 <slug> [--force]" >&2
  exit 1
fi

WT_BASE="${WT_BASE:-../worktrees}"
WT_BRANCH_PREFIX="${WT_BRANCH_PREFIX:-feat/}"

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "error: not inside a git repository" >&2
  exit 2
fi

REPO_ROOT=$(git rev-parse --show-toplevel)
WT_PATH="$REPO_ROOT/$WT_BASE/$SLUG"
WT_BRANCH="${WT_BRANCH_PREFIX}${SLUG}"

if [ ! -d "$WT_PATH" ]; then
  echo "error: worktree path does not exist: $WT_PATH" >&2
  exit 2
fi

# Check for uncommitted changes inside the worktree.
if [ -z "${FORCE:+x}" ] || [ "$FORCE" -eq 0 ]; then
  if [ -n "$(git -C "$WT_PATH" status --porcelain 2>/dev/null)" ]; then
    echo "error: worktree has uncommitted changes" >&2
    echo "  commit / stash them, or pass --force." >&2
    exit 2
  fi
fi

# Remove the worktree itself.
echo "[worktree-remove] removing $WT_PATH"
if [ "$FORCE" -eq 1 ]; then
  git worktree remove --force "$WT_PATH"
else
  git worktree remove "$WT_PATH"
fi

# Try to delete the branch if it's been merged. If not, leave it (safe default).
if git show-ref --verify --quiet "refs/heads/$WT_BRANCH"; then
  if git branch -d "$WT_BRANCH" 2>/dev/null; then
    echo "[worktree-remove] deleted merged branch $WT_BRANCH"
  else
    echo "[worktree-remove] branch $WT_BRANCH has unmerged commits — keeping it"
    echo "  delete manually: git branch -D $WT_BRANCH"
  fi
fi

echo "✓ done"
