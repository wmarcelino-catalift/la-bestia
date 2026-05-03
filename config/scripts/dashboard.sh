#!/usr/bin/env bash
# dashboard.sh — real-time agent activity viewer.
# Usage:
#   watch -n 1 bash .claude/scripts/dashboard.sh
#   OR run once for a snapshot.
export PATH="$HOME/bin:$PATH"

PROJ="${CLAUDE_PROJECT_DIR:-$(pwd)}"
LIVE="$PROJ/.claude/logs/live-activity.jsonl"
AGENTS_LOG="$PROJ/.claude/logs/agents.jsonl"

NOW=$(date +%s)
BRANCH=$(git branch --show-current 2>/dev/null || echo "?")
DIRTY=$(git status --short 2>/dev/null | wc -l | tr -d ' ')

# Header
echo "╔══════════════════════════════════════════════════════════╗"
echo "║  🐺 LA BESTIA — Agent Dashboard                          ║"
echo "╠══════════════════════════════════════════════════════════╣"
printf "║  Branch: %-20s  Uncommitted: %-6s     ║\n" "$BRANCH${DIRTY:+*}" "$DIRTY"
echo "╠══════════════════════════════════════════════════════════╣"

# Active agents (started but no completion in last 60s)
echo "║  ACTIVE AGENTS                                           ║"
ACTIVE=0
for f in "$PROJ/.claude/logs/.agent_start_"* 2>/dev/null; do
  [ -f "$f" ] || continue
  AGENT_NAME=$(basename "$f" | sed 's/\.agent_start_//')
  START=$(cat "$f" 2>/dev/null)
  ELAPSED=$((NOW - START))
  printf "║  ⚡ %-20s  running %ds                    ║\n" "$AGENT_NAME" "$ELAPSED"
  ACTIVE=$((ACTIVE + 1))
done
[ $ACTIVE -eq 0 ] && echo "║  — none running                                          ║"

echo "╠══════════════════════════════════════════════════════════╣"

# Recent agent history (last 8 completions)
echo "║  RECENT ACTIVITY                                         ║"
if command -v jq >/dev/null 2>&1 && [ -f "$LIVE" ]; then
  tail -40 "$LIVE" 2>/dev/null | \
    jq -r 'select(.event == "post" and .agent != "unknown" and .agent != "Bash") |
      "\(.ts | split("T")[1] | split("Z")[0])  \(.agent)  \(if .duration then "\(.duration)s" else "?" end)  \(.desc // "" | .[0:35])"' \
    2>/dev/null | tail -8 | while IFS= read -r line; do
      printf "║  %-58s║\n" "$line"
    done
else
  # Fallback without jq
  if [ -f "$AGENTS_LOG" ]; then
    tail -8 "$AGENTS_LOG" | while IFS= read -r line; do
      AGENT=$(echo "$line" | grep -o '"agent":"[^"]*"' | cut -d'"' -f4)
      TIME=$(echo "$line" | grep -o '"ts":"[^"]*"' | cut -d'"' -f4 | cut -d'T' -f2 | cut -d'Z' -f1)
      printf "║  %-10s  %-45s║\n" "$TIME" "$AGENT"
    done
  else
    echo "║  — no activity yet                                       ║"
  fi
fi

echo "╠══════════════════════════════════════════════════════════╣"

# Session stats
echo "║  SESSION STATS                                           ║"
if [ -f "$AGENTS_LOG" ]; then
  TOTAL=$(wc -l < "$AGENTS_LOG" 2>/dev/null | tr -d ' ')
  UNIQUE=$(command -v jq >/dev/null && jq -r '.agent' "$AGENTS_LOG" 2>/dev/null | sort -u | tr '\n' ' ' || echo "?")
  printf "║  Total calls: %-5s  Agents used: %-26s║\n" "$TOTAL" "${UNIQUE:0:28}"
fi

# Cost via ccusage if available
if command -v ccusage >/dev/null 2>&1; then
  COST=$(ccusage daily --json 2>/dev/null | jq -r '.totals.totalCost // empty' 2>/dev/null)
  [ -n "$COST" ] && printf "║  Cost today: \$%-46s║\n" "$COST"
fi

echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo "  Run: watch -n 2 'bash .claude/scripts/dashboard.sh'"
