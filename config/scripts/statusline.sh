#!/usr/bin/env bash
# Statusline custom: branch | model | session tokens | last agent
# Output goes to Claude Code's bottom statusline.

set -u

# Read JSON from stdin (Claude Code sends session info)
INPUT=$(cat 2>/dev/null || echo "{}")

# Branch
if git rev-parse --git-dir >/dev/null 2>&1; then
  BRANCH=$(git branch --show-current 2>/dev/null || echo "?")
  DIRTY=$(git status --short 2>/dev/null | wc -l | tr -d ' ')
  [ "$DIRTY" -gt 0 ] && BRANCH="$BRANCH*"
else
  BRANCH="-"
fi

# Model (from input)
MODEL=$(echo "$INPUT" | jq -r '.model.display_name // .model.id // "?"' 2>/dev/null)
[ "$MODEL" = "null" ] && MODEL="?"

# Session cost (ccusage if available, else nothing)
COST=""
if command -v ccusage >/dev/null 2>&1; then
  TODAY=$(ccusage daily --json 2>/dev/null | jq -r '.totals.totalCost // empty' 2>/dev/null)
  [ -n "$TODAY" ] && COST=" | \$$TODAY today"
fi

# Last agent invoked (from log)
LAST_AGENT=""
LOG="$HOME/.claude/logs/agents.jsonl"
if [ -f "$LOG" ]; then
  LAST=$(tail -1 "$LOG" 2>/dev/null | jq -r '.agent // empty' 2>/dev/null)
  [ -n "$LAST" ] && LAST_AGENT=" | last: $LAST"
fi

# CWD basename
CWD_NAME=$(basename "$PWD")

echo "🐺 $CWD_NAME [$BRANCH] | $MODEL$COST$LAST_AGENT"
