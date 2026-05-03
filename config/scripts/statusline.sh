#!/usr/bin/env bash
# Statusline: branch | model | last agent. Reads JSON session info from stdin.

set -u

INPUT=$(cat 2>/dev/null || echo "{}")
PROJ="${CLAUDE_PROJECT_DIR:-$(pwd)}"

if git rev-parse --git-dir >/dev/null 2>&1; then
  BRANCH=$(git branch --show-current 2>/dev/null || echo "?")
  DIRTY=$(git status --short 2>/dev/null | wc -l | tr -d ' ')
  [ "$DIRTY" -gt 0 ] && BRANCH="$BRANCH*"
else
  BRANCH="-"
fi

MODEL="?"
if command -v jq >/dev/null 2>&1; then
  MODEL=$(echo "$INPUT" | jq -r '.model.display_name // .model.id // "?"' 2>/dev/null)
  [ "$MODEL" = "null" ] && MODEL="?"
fi

AGENTS=""
LOG="$PROJ/.claude/logs/agents.jsonl"
if [ -f "$LOG" ] && command -v jq >/dev/null 2>&1; then
  # Últimos 3 agentes únicos de la sesión
  RECENT=$(tail -20 "$LOG" 2>/dev/null \
    | jq -r 'select(.agent != null) | .agent' 2>/dev/null \
    | awk '!seen[$0]++' | head -3 | tr '\n' ',' | sed 's/,$//')
  [ -n "$RECENT" ] && AGENTS=" · $RECENT"
fi

echo "🐺 La Bestia$AGENTS"
