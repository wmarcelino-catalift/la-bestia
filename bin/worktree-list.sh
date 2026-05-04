#!/usr/bin/env bash
# worktree-list.sh — list active worktrees with branch, last commit, and dirty state.
#
# Usage:
#   bash bin/worktree-list.sh

set -u

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "error: not inside a git repository" >&2
  exit 2
fi

# Parse `git worktree list --porcelain` into a tab-separated table.
WT_DATA=$(git worktree list --porcelain)

# Header.
printf "%-40s %-30s %-10s %s\n" "PATH" "BRANCH" "DIRTY" "LAST COMMIT"
printf "%-40s %-30s %-10s %s\n" "----" "------" "-----" "-----------"

# Iterate through worktrees.
WT_PATH=""
WT_BRANCH=""
echo "$WT_DATA" | while IFS= read -r line; do
  case "$line" in
    "worktree "*)
      WT_PATH="${line#worktree }"
      ;;
    "branch "*)
      WT_BRANCH="${line#branch refs/heads/}"
      # Now we have both; emit the row.
      DIRTY="clean"
      if [ -n "$(git -C "$WT_PATH" status --porcelain 2>/dev/null)" ]; then
        DIRTY="dirty"
      fi
      LAST=$(git -C "$WT_PATH" log -1 --pretty=format:'%h %s' 2>/dev/null | cut -c1-60)
      # Shorten path for display: relative to caller's cwd if possible.
      DISPLAY_PATH="$WT_PATH"
      if command -v realpath >/dev/null 2>&1; then
        DISPLAY_PATH=$(realpath --relative-to="$(pwd)" "$WT_PATH" 2>/dev/null || echo "$WT_PATH")
      fi
      printf "%-40s %-30s %-10s %s\n" "$DISPLAY_PATH" "$WT_BRANCH" "$DIRTY" "$LAST"
      WT_PATH=""
      WT_BRANCH=""
      ;;
    "detached")
      DIRTY="clean"
      [ -n "$(git -C "$WT_PATH" status --porcelain 2>/dev/null)" ] && DIRTY="dirty"
      LAST=$(git -C "$WT_PATH" log -1 --pretty=format:'%h %s' 2>/dev/null | cut -c1-60)
      printf "%-40s %-30s %-10s %s\n" "$WT_PATH" "(detached)" "$DIRTY" "$LAST"
      WT_PATH=""
      ;;
  esac
done
