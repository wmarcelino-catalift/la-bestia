#!/usr/bin/env bash
# Render a Mermaid flow diagram from .claude/logs/agents.jsonl for a session.
# Usage:
#   bash .claude/scripts/flow-diagram.sh                 # latest session, stdout
#   bash .claude/scripts/flow-diagram.sh <session_id>    # specific session
#   bash .claude/scripts/flow-diagram.sh --save          # save to .claude/vault/inbox/

set -u

PROJ="${CLAUDE_PROJECT_DIR:-$(pwd)}"
LOG="$PROJ/.claude/logs/agents.jsonl"
VAULT="$PROJ/.claude/vault"

if [ ! -f "$LOG" ]; then
  echo "No agent log yet at $LOG. Run a session first." >&2
  exit 1
fi
if ! command -v jq >/dev/null 2>&1; then
  echo "jq required. Install: winget install jqlang.jq" >&2
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

if [ -z "$SESSION" ]; then
  SESSION=$(jq -r '.session' "$LOG" 2>/dev/null | tail -1)
fi
if [ -z "$SESSION" ] || [ "$SESSION" = "unknown" ]; then
  echo "No session_id available in log entries." >&2
  exit 1
fi

OUT=$(mktemp)
{
  echo '```mermaid'
  echo "flowchart TD"
  echo "  Main([Main thread])"
  jq -r --arg sid "$SESSION" 'select(.session == $sid and .event == "agent") | "  Main --> \(.agent)[\"\(.agent)<br/><small>\(.desc | gsub("\""; "") | .[0:60])</small>\"]"' "$LOG"
  echo '```'
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
