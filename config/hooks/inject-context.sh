#!/usr/bin/env bash
# SessionStart hook
# Outputs to stdout — Claude reads this as session-initial context.
# Order: HOT.md (vault) → project hot-context → project index in vault → git status

VAULT="$HOME/Obsidian/claude-brain"
CWD=$(pwd)
PROJECT_SLUG=$(basename "$CWD" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')

echo "## Session $(date '+%Y-%m-%d %H:%M')"
echo "**cwd**: $CWD"

# Git status
if git rev-parse --git-dir >/dev/null 2>&1; then
  BRANCH=$(git branch --show-current 2>/dev/null || echo "detached")
  UNCOMMITTED=$(git status --short 2>/dev/null | wc -l | tr -d ' ')
  LAST=$(git log -1 --pretty=format:'%h %s' 2>/dev/null)
  echo "**git**: $BRANCH | $UNCOMMITTED uncommitted | last: $LAST"
else
  echo "**git**: no git repo"
fi
echo ""

# Vault HOT.md (cross-project recent context)
if [ -f "$VAULT/HOT.md" ]; then
  echo "### Vault HOT.md"
  head -50 "$VAULT/HOT.md"
  echo ""
fi

# Project hot-context
if [ -f "memory/hot-context.md" ]; then
  echo "### Project hot-context"
  head -40 memory/hot-context.md
  echo ""
fi

# Project index in vault
if [ -f "$VAULT/projects/$PROJECT_SLUG/index.md" ]; then
  echo "### Vault project index ($PROJECT_SLUG)"
  head -40 "$VAULT/projects/$PROJECT_SLUG/index.md"
  echo ""
fi

exit 0
