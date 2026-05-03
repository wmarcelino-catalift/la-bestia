#!/usr/bin/env bash
export PATH="$HOME/bin:$PATH"

PROJ="${CLAUDE_PROJECT_DIR:-$(pwd)}"
INPUT=$(cat 2>/dev/null || echo "{}")
LOG="$PROJ/.claude/logs/live-activity.jsonl"
NOW=$(date +%s)

# Model
MODEL="?"
if command -v jq >/dev/null 2>&1; then
  MODEL=$(echo "$INPUT" | jq -r '.model.display_name // .model.id // "?"' 2>/dev/null)
  [ "$MODEL" = "null" ] || [ -z "$MODEL" ] && MODEL="?"
  # Shorten model name
  MODEL=$(echo "$MODEL" | sed 's/claude-//;s/-2[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]//;s/sonnet/snnt/;s/opus/opus/;s/haiku/haiku/')
fi

# Last agent + elapsed time
LAST_AGENT=""
if command -v jq >/dev/null 2>&1 && [ -f "$LOG" ]; then
  LAST_LINE=$(tail -20 "$LOG" 2>/dev/null | jq -r 'select(.event == "post" and .agent != null and .agent != "unknown" and .agent != "Bash") | "\(.epoch) \(.agent) \(.duration // 0)"' 2>/dev/null | tail -1)
  if [ -n "$LAST_LINE" ]; then
    LAST_EPOCH=$(echo "$LAST_LINE" | awk '{print $1}')
    LAST_NAME=$(echo "$LAST_LINE" | awk '{print $2}')
    LAST_DUR=$(echo "$LAST_LINE" | awk '{print $3}')
    ELAPSED=$((NOW - LAST_EPOCH))
    if [ $ELAPSED -lt 60 ]; then
      AGO="${ELAPSED}s ago"
    elif [ $ELAPSED -lt 3600 ]; then
      AGO="$((ELAPSED/60))m ago"
    else
      AGO="$((ELAPSED/3600))h ago"
    fi
    [ "$LAST_DUR" -gt 0 ] 2>/dev/null && DUR_STR=" ${LAST_DUR}s" || DUR_STR=""
    LAST_AGENT=" · ${LAST_NAME}${DUR_STR} (${AGO})"
  fi
fi

# Active agents (files with .agent_start_ prefix = agent currently running)
ACTIVE_COUNT=$(ls "$PROJ/.claude/logs/.agent_start_"* 2>/dev/null | wc -l | tr -d ' ')
THINKING=""
if [ "$ACTIVE_COUNT" -gt 0 ]; then
  ACTIVE_NAMES=$(ls "$PROJ/.claude/logs/.agent_start_"* 2>/dev/null | sed 's/.*\.agent_start_//' | tr '\n' '+' | sed 's/+$//')
  THINKING=" ⚡${ACTIVE_NAMES}"
fi

# Cost today
COST=""
if command -v ccusage >/dev/null 2>&1; then
  TODAY=$(ccusage daily --json 2>/dev/null | jq -r '.totals.totalCost // empty' 2>/dev/null)
  [ -n "$TODAY" ] && COST=" · \$${TODAY}"
fi

echo "🐺 La Bestia · ${MODEL}${THINKING}${LAST_AGENT}${COST}"
