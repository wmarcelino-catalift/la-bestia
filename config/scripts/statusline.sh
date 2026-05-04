#!/usr/bin/env bash
# Statusline (v3.0) — single line printed in Claude Code's status bar.
# Source: agents.jsonl + ccusage + JSON input on stdin.
#
# Output shape:
#   🐺 La Bestia · <model> [· ⚡<active>] [· <last-agent> (<ago>)] · $<sess>/<today>w<week> [· ctx <%>]
#
# Budget alerts:
#   today > $20 → prefix "⚠"
#   today > $50 → prefix "🚨"
#
# Performance budget: < 100ms p99.
export PATH="$HOME/bin:$PATH"

PROJ="${CLAUDE_PROJECT_DIR:-$(pwd)}"
INPUT=$(cat 2>/dev/null || echo "{}")
LOG="$PROJ/.claude/logs/agents.jsonl"
NOW=$(date +%s)

# ── Model ────────────────────────────────────────────────────────────────────
MODEL="?"
if command -v jq >/dev/null 2>&1; then
  MODEL=$(echo "$INPUT" | jq -r '.model.display_name // .model.id // "?"' 2>/dev/null)
  [ "$MODEL" = "null" ] || [ -z "$MODEL" ] && MODEL="?"
  MODEL=$(echo "$MODEL" | sed 's/claude-//;s/-2[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]//;s/sonnet/snnt/;s/opus/opus/;s/haiku/haiku/')
fi

# ── Last post-agent ──────────────────────────────────────────────────────────
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

# ── Active agents ────────────────────────────────────────────────────────────
ACTIVE_COUNT=$(ls "$PROJ/.claude/logs/.agent_start_"* 2>/dev/null | wc -l | tr -d ' ')
THINKING=""
if [ "$ACTIVE_COUNT" -gt 0 ]; then
  ACTIVE_NAMES=$(ls "$PROJ/.claude/logs/.agent_start_"* 2>/dev/null | sed 's/.*\.agent_start_//' | tr '\n' '+' | sed 's/+$//')
  THINKING=" ⚡${ACTIVE_NAMES}"
fi

# ── Cost (session + today + week) ────────────────────────────────────────────
COST=""
ALERT=""
if command -v ccusage >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
  CCUSAGE_JSON=$(ccusage daily --json 2>/dev/null || echo "{}")
  TODAY=$(echo "$CCUSAGE_JSON" | jq -r '.totals.totalCost // empty' 2>/dev/null)

  # Sum costs for last 7 days from ccusage daily output
  WEEK=$(echo "$CCUSAGE_JSON" | jq -r '
    [.daily[]? | select(.date >= (now - 86400*7 | strftime("%Y-%m-%d")))] | map(.totalCost) | add // empty
  ' 2>/dev/null)

  # Approximate session $ — sum durations × per-second rate isn't precise,
  # but we can use today as a proxy and let the operator see trends.
  if [ -n "$TODAY" ]; then
    if [ -n "$WEEK" ]; then
      COST=" · \$${TODAY}d/\$${WEEK}w"
    else
      COST=" · \$${TODAY}d"
    fi

    # Budget alerts on today's spend
    TODAY_INT=$(printf '%.0f' "$TODAY" 2>/dev/null || echo 0)
    if [ "$TODAY_INT" -ge 50 ] 2>/dev/null; then
      ALERT="🚨 "
    elif [ "$TODAY_INT" -ge 20 ] 2>/dev/null; then
      ALERT="⚠ "
    fi
  fi
fi

# ── Context window % (from input.transcript_path or input.token_usage) ───────
CTX_HINT=""
if command -v jq >/dev/null 2>&1; then
  # Claude Code may pass token usage in the input JSON — try common paths
  CTX_USED=$(echo "$INPUT" | jq -r '.context.used // .tokens.used // .usage.input_tokens // empty' 2>/dev/null)
  CTX_MAX=$(echo "$INPUT"  | jq -r '.context.max  // .tokens.max  // .usage.max_tokens   // 200000' 2>/dev/null)
  if [ -n "$CTX_USED" ] && [ "$CTX_USED" != "null" ] && [ "$CTX_MAX" -gt 0 ] 2>/dev/null; then
    PCT=$(( CTX_USED * 100 / CTX_MAX ))
    if [ "$PCT" -ge 70 ]; then
      CTX_HINT=" · ctx ${PCT}% (consider /compact)"
    elif [ "$PCT" -ge 40 ]; then
      CTX_HINT=" · ctx ${PCT}%"
    fi
  fi
fi

echo "${ALERT}🐺 La Bestia · ${MODEL}${THINKING}${LAST_AGENT}${COST}${CTX_HINT}"
