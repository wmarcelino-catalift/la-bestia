#!/usr/bin/env bash
# PreToolUse + PostToolUse: Task — tracks agent timing.
# Writes to agents.jsonl + live-activity.jsonl.
set -u
export PATH="$HOME/bin:$PATH"

PROJ="${CLAUDE_PROJECT_DIR:-$(pwd)}"
LOG="$PROJ/.claude/logs/agents.jsonl"
LIVE="$PROJ/.claude/logs/live-activity.jsonl"
mkdir -p "$(dirname "$LOG")"

TS=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
EPOCH=$(date +%s)
TOOL="${CLAUDE_TOOL_NAME:-unknown}"
EVENT="${1:-post}"

AGENT=""
DESC=""
DURATION=""

if command -v jq >/dev/null 2>&1; then
  INPUT="${CLAUDE_TOOL_INPUT:-{}}"
  AGENT=$(echo "$INPUT" | jq -r '.subagent_type // .agent_type // empty' 2>/dev/null)
  # Fix: strip newlines before truncating to avoid invalid JSONL
  DESC=$(echo "$INPUT" | jq -r '.description // .prompt // empty' 2>/dev/null | tr -d '\n\r' | cut -c1-80)

  START_FILE="$PROJ/.claude/logs/.agent_start_${AGENT:-task}"
  if [ "$EVENT" = "post" ] && [ -f "$START_FILE" ]; then
    START=$(cat "$START_FILE" 2>/dev/null)
    DURATION=$((EPOCH - START))
    rm -f "$START_FILE"
  elif [ "$EVENT" = "pre" ]; then
    echo "$EPOCH" > "$START_FILE"
  fi
fi

[ -z "$AGENT" ] && AGENT="$TOOL"

# Use jq for JSON-safe encoding (same approach as log-agents.sh)
if command -v jq >/dev/null 2>&1; then
  DESC_JSON=$(printf '%s' "$DESC" | jq -Rs .)
  CWD_JSON=$(basename "$(pwd)" | jq -Rs .)

  if [ -n "$AGENT" ] && [ "$AGENT" != "unknown" ]; then
    echo "{\"ts\":\"$TS\",\"event\":\"$EVENT\",\"agent\":\"$AGENT\",\"desc\":${DESC_JSON},\"duration\":${DURATION:-null}}" >> "$LOG"
  fi
  echo "{\"ts\":\"$TS\",\"epoch\":$EPOCH,\"event\":\"$EVENT\",\"agent\":\"$AGENT\",\"desc\":${DESC_JSON},\"duration\":${DURATION:-null},\"cwd\":${CWD_JSON}}" >> "$LIVE"
else
  # Fallback without jq — minimal safe output
  echo "{\"ts\":\"$TS\",\"epoch\":$EPOCH,\"event\":\"$EVENT\",\"agent\":\"$AGENT\",\"duration\":${DURATION:-null}}" >> "$LIVE"
fi

exit 0
