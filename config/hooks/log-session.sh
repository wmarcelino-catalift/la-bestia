#!/usr/bin/env bash
# Stop hook
# Writes a placeholder to vault inbox for later curation.

VAULT="$HOME/Obsidian/claude-brain"
INBOX="$HOME/.claude/logs/sessions"
mkdir -p "$INBOX"

CWD=$(pwd)
PROJECT=$(basename "$CWD")
SLUG=$(echo "$PROJECT" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
TS=$(date '+%Y-%m-%d_%H%M')
FILE="$INBOX/session-${TS}-${SLUG}.md"

cat > "$FILE" <<EOF
---
created: $(date -u +'%Y-%m-%dT%H:%M:%SZ')
project: $PROJECT
type: session-summary
status: inbox
---

# Session $TS — $PROJECT

**cwd**: $CWD
$(git rev-parse --git-dir >/dev/null 2>&1 && echo "**branch**: $(git branch --show-current 2>/dev/null)
**uncommitted**: $(git status --short 2>/dev/null | wc -l | tr -d ' ')
**last commit**: $(git log -1 --pretty=format:'%h %s' 2>/dev/null)")

## TODO (curar)
- [ ] ¿Qué se decidió?
- [ ] ¿Qué se aprendió?
- [ ] ¿Qué quedó pendiente?
- [ ] Linkear a [[projects/$SLUG/index]]
EOF

# Also append timestamp to per-project activity log
LOG_DIR="$HOME/.claude/logs/sessions"
mkdir -p "$LOG_DIR"
echo "[$(date '+%Y-%m-%d %H:%M')] $PROJECT ($CWD)" >> "$LOG_DIR/all.log"

# Auto-rotate HOT.md (archive entries older than 7 days)
bash "$HOME/.claude/scripts/curate-hot.sh" 2>/dev/null

exit 0
