#!/usr/bin/env bash
# SessionStart hook (project-local).
# Order: vault HOT.md → project memory/hot-context.md → git status.

PROJ="${CLAUDE_PROJECT_DIR:-$(pwd)}"
VAULT="$PROJ/.claude/vault"
CWD=$(pwd)

echo "## Session $(date '+%Y-%m-%d %H:%M')"
echo "**cwd**: $CWD"

if timeout 5 git rev-parse --git-dir >/dev/null 2>&1; then
  BRANCH=$(timeout 3 git branch --show-current 2>/dev/null || echo "detached")
  UNCOMMITTED=$(timeout 3 git status --short 2>/dev/null | wc -l | tr -d ' ')
  LAST=$(timeout 3 git log -1 --pretty=format:'%h %s' 2>/dev/null)
  echo "**git**: $BRANCH | $UNCOMMITTED uncommitted | last: $LAST"
else
  echo "**git**: no git repo"
fi
echo ""

if [ -f "$VAULT/HOT.md" ]; then
  echo "### Vault HOT.md"
  head -50 "$VAULT/HOT.md"
  echo ""
fi

if [ -f "$PROJ/memory/hot-context.md" ]; then
  echo "### Project hot-context"
  head -40 "$PROJ/memory/hot-context.md"
  echo ""
fi

exit 0
