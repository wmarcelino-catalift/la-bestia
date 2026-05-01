#!/usr/bin/env bash
# Generate a Mermaid flow diagram from agents.jsonl for the latest session (or a given session ID).
# Output: prints Mermaid to stdout, optionally writes to vault inbox.
#
# Usage:
#   bash ~/.claude/scripts/flow-diagram.sh                      # latest session, stdout
#   bash ~/.claude/scripts/flow-diagram.sh <session_id>         # specific session
#   bash ~/.claude/scripts/flow-diagram.sh --save               # latest, save to vault inbox

set -u

LOG="$HOME/.claude/logs/agents.jsonl"
VAULT="$HOME/Obsidian/claude-brain"

if [ ! -f "$LOG" ]; then
  echo "No agent log yet at $LOG. Run a session first." >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq required. Install: brew install jq" >&2
  exit 1
fi

SAVE=false
SESSION=""
for arg in "$@"; do
  case "$arg" in
    --save) SAVE=true ;;
    *) SESSION="$arg" ;;
  esac
done

# Default: latest session
if [ -z "$SESSION" ]; then
  SESSION=$(jq -r '.session' "$LOG" 2>/dev/null | tail -1)
fi

[ -z "$SESSION" ] || [ "$SESSION" = "unknown" ] && {
  echo "No session_id available in log entries." >&2
  exit 1
}

# Build Mermaid
OUT=$(mktemp)
{
  echo "\`\`\`mermaid"
  echo "flowchart TD"
  echo "  Main([Main thread])"

  # Each agent invocation as a node + edge from Main
  jq -r --arg sid "$SESSION" 'select(.session == $sid and .event == "agent") | "  Main --> \(.agent)[\"\(.agent)<br/><small>\(.desc | gsub("\""; "") | .[0:60])</small>\"]"' "$LOG"

  echo "\`\`\`"
} > "$OUT"

if $SAVE; then
  mkdir -p "$VAULT/inbox"
  TARGET="$VAULT/inbox/flow-$(date +%Y-%m-%d_%H%M)-${SESSION:0:8}.md"
  {
    echo "---"
    echo "created: $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
    echo "session: $SESSION"
    echo "type: flow-diagram"
    echo "---"
    echo ""
    echo "# Flow diagram — session ${SESSION:0:8}"
    echo ""
    cat "$OUT"
  } > "$TARGET"
  echo "Saved to: $TARGET"
else
  cat "$OUT"
fi

rm -f "$OUT"
