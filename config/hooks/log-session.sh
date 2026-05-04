#!/usr/bin/env bash
# Stop hook — write a session summary from git + agents.jsonl.
# No vault. No external viewer. Output: <project>/.claude/logs/sessions/session-<ts>.md
set -u

PROJ="${CLAUDE_PROJECT_DIR:-$(pwd)}"
INBOX="$PROJ/.claude/logs/sessions"
LOG="$PROJ/.claude/logs/agents.jsonl"
mkdir -p "$INBOX"

CWD=$(pwd)
PROJECT=$(basename "$CWD")
TS=$(date '+%Y-%m-%d_%H%M')
FILE="$INBOX/session-${TS}.md"

BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
UNCOMMITTED=$(git status --short 2>/dev/null | wc -l | tr -d ' ')
LAST_COMMIT=$(git log -1 --pretty=format:'%h %s' 2>/dev/null || echo "none")

# Agents used in last 24h, ranked by frequency
AGENTS_USED=""
if command -v jq >/dev/null 2>&1 && [ -f "$LOG" ]; then
  CUTOFF=$(($(date +%s) - 86400))
  AGENTS_USED=$(tail -500 "$LOG" 2>/dev/null | \
    jq -r "select(.epoch != null and .epoch > $CUTOFF and .event == \"post\" and .agent != null and .agent != \"unknown\" and .agent != \"Bash\") | .agent" 2>/dev/null | \
    sort | uniq -c | sort -rn | \
    awk '{print "- " $2 " (" $1 "x)"}' | head -8)
fi

# Files modified since last commit (best-effort)
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
  echo "## Agents used (last 24h)"
  if [ -n "$AGENTS_USED" ]; then
    echo "$AGENTS_USED"
  else
    echo "- none recorded"
  fi
  echo ""
  echo "## Files modified"
  echo "$FILES_MODIFIED"
  echo ""
  echo "## Pending (run /wrap-up to populate)"
  echo "- [ ] ..."
} > "$FILE"

echo "[$(date '+%Y-%m-%d %H:%M')] $PROJECT · $BRANCH" >> "$INBOX/all.log"

exit 0
