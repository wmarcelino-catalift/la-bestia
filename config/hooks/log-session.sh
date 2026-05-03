#!/usr/bin/env bash
# Stop hook — auto-generate session summary from git + agent logs.
export PATH="$HOME/bin:$PATH"

PROJ="${CLAUDE_PROJECT_DIR:-$(pwd)}"
INBOX="$PROJ/.claude/logs/sessions"
mkdir -p "$INBOX"

CWD=$(pwd)
PROJECT=$(basename "$CWD")
TS=$(date '+%Y-%m-%d_%H%M')
FILE="$INBOX/session-${TS}.md"

BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
UNCOMMITTED=$(git status --short 2>/dev/null | wc -l | tr -d ' ')
LAST_COMMIT=$(git log -1 --pretty=format:'%h %s' 2>/dev/null || echo "none")

# Agents used this session (from live log, last 2 hours)
AGENTS_USED=""
LIVE="$PROJ/.claude/logs/live-activity.jsonl"
if command -v jq >/dev/null 2>&1 && [ -f "$LIVE" ]; then
  CUTOFF=$(($(date +%s) - 86400))  # 24h window
  AGENTS_USED=$(tail -500 "$LIVE" 2>/dev/null | \
    jq -r "select(.epoch != null and .epoch > $CUTOFF and .event == \"post\" and .agent != null and .agent != \"unknown\" and .agent != \"Bash\") | .agent" 2>/dev/null | \
    sort | uniq -c | sort -rn | \
    awk '{print "- " $2 " (" $1 "x)"}' | head -8)
fi

# Files modified this session
FILES_MODIFIED=$(git diff --name-only HEAD~1..HEAD 2>/dev/null | head -10 | sed 's/^/- /' || echo "- (no commits this session)")

{
  echo "---"
  echo "created: $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
  echo "project: $PROJECT"
  echo "branch: $BRANCH"
  echo "---"
  echo ""
  echo "# Session $TS"
  echo ""
  echo "**branch**: $BRANCH | **uncommitted**: $UNCOMMITTED | **last**: $LAST_COMMIT"
  echo ""
  echo "## Agents used"
  if [ -n "$AGENTS_USED" ]; then
    echo "$AGENTS_USED"
  else
    echo "- none recorded"
  fi
  echo ""
  echo "## Files modified"
  echo "$FILES_MODIFIED"
  echo ""
  echo "## Pending (run /wrap-up to fill)"
  echo "- [ ] ..."
} > "$FILE"

echo "[$(date '+%Y-%m-%d %H:%M')] $PROJECT · $BRANCH" >> "$INBOX/all.log"

exit 0
