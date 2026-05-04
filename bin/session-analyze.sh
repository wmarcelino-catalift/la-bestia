#!/usr/bin/env bash
# session-analyze.sh — comprehensive post-mortem report of a la-bestia session.
# Cross-references agents.jsonl, ccusage daily, git log, modified files.
# Output: markdown report ready to paste into a wrap-up note or PR description.
#
# Usage:
#   bash bin/session-analyze.sh                      # current project
#   bash bin/session-analyze.sh /path/to/project     # specific project
#   bash bin/session-analyze.sh - <jsonl-path>       # specific log file

set -euo pipefail

PROJ="${1:-${CLAUDE_PROJECT_DIR:-$(pwd)}}"
LOG=""

if [ "$PROJ" = "-" ]; then
  LOG="${2:-}"
  [ -z "$LOG" ] && { echo "✗ usage: $0 - <jsonl-path>" >&2; exit 2; }
  PROJ="$(dirname "$(dirname "$LOG")")"
else
  LOG="$PROJ/.claude/logs/agents.jsonl"
fi

[ -f "$LOG" ] || { echo "(no agents.jsonl found at $LOG)"; exit 0; }

PROJ_NAME=$(basename "$PROJ")

# ── Header ──
cat <<EOF
# Session analysis — $PROJ_NAME

> Generated $(date -u +'%Y-%m-%dT%H:%M:%SZ') · source: $LOG

EOF

# ── Top-level stats ──
TOTAL_LINES=$(wc -l < "$LOG" | tr -d ' ')
if command -v jq >/dev/null 2>&1; then
  FIRST_TS=$(head -1 "$LOG" | jq -r '.ts // empty' 2>/dev/null || echo "?")
  LAST_TS=$(tail -1 "$LOG" | jq -r '.ts // empty' 2>/dev/null || echo "?")

  POST_TASK=$(grep -c '"event":"post"' "$LOG" || true)
  AGENTS_COUNT=$(jq -rs 'map(select(.event=="post" and .agent != "Bash" and .agent != "unknown") | .agent) | unique | length' "$LOG" 2>/dev/null || echo "?")

  echo "## At a glance"
  echo ""
  echo "| Metric | Value |"
  echo "|---|---|"
  echo "| Project | \`$PROJ_NAME\` |"
  echo "| Log lines | $TOTAL_LINES |"
  echo "| First event | $FIRST_TS |"
  echo "| Last event | $LAST_TS |"
  echo "| Unique agents invoked | $AGENTS_COUNT |"
  echo "| Total post-events | $POST_TASK |"
  echo ""
fi

# ── Cost (if ccusage available) ──
if command -v ccusage >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
  TODAY=$(ccusage daily --json 2>/dev/null | jq -r '.totals.totalCost // empty' 2>/dev/null)
  if [ -n "$TODAY" ]; then
    echo "## Cost"
    echo ""
    echo "- **\$ today (all sessions)**: \$$TODAY"
    echo ""
  fi
fi

# ── Agent ranking ──
echo "## Agents (by invocation count)"
echo ""
if command -v jq >/dev/null 2>&1; then
  echo "| Agent | Calls | Total duration (s) | Avg duration (s) |"
  echo "|---|---|---|---|"
  jq -rs '
    map(select(
      .event == "post"
      and .agent != null
      and .agent != "Bash"
      and .agent != "unknown"
    ))
    | group_by(.agent)
    | map({
        agent: .[0].agent,
        calls: length,
        total_duration: ((map(.duration // 0) | add)),
        avg_duration: ((map(.duration // 0) | add) / length | floor)
      })
    | sort_by(-.calls)
    | .[]
    | "| `\(.agent)` | \(.calls) | \(.total_duration) | \(.avg_duration) |"
  ' "$LOG"
  echo ""
fi

# ── Bash ranking ──
BASH_LOG="$PROJ/.claude/logs/bash.jsonl"
if [ -f "$BASH_LOG" ] && command -v jq >/dev/null 2>&1; then
  TOTAL_BASH=$(grep -c '"event":"post"' "$BASH_LOG" 2>/dev/null || echo 0)
  if [ "$TOTAL_BASH" -gt 0 ]; then
    echo "## Bash (top 10 commands by frequency)"
    echo ""
    echo "| Command prefix | Count |"
    echo "|---|---|"
    jq -rs 'map(select(.tool=="Bash" and .event=="post" and .cmd != null)) | map(.cmd | split(" ")[0:3] | join(" ")) | group_by(.) | map({c: .[0], n: length}) | sort_by(-.n) | .[0:10] | .[] | "| `\(.c)` | \(.n) |"' "$BASH_LOG"
    echo ""
  fi
fi

# ── Git activity ──
if [ -d "$PROJ/.git" ]; then
  cd "$PROJ"
  CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "?")
  RECENT_COMMITS=$(git log --since="24 hours ago" --pretty=format:'%h %s' 2>/dev/null | head -10 || true)
  MODIFIED_NOW=$(git status --short 2>/dev/null | head -8 | sed 's/^/  /' || true)

  echo "## Git activity"
  echo ""
  echo "- **Branch**: \`$CURRENT_BRANCH\`"
  if [ -n "$RECENT_COMMITS" ]; then
    echo "- **Commits last 24h**:"
    echo ""
    echo "$RECENT_COMMITS" | sed 's/^/  - /'
    echo ""
  fi
  if [ -n "$MODIFIED_NOW" ]; then
    echo "- **Currently modified** (working tree):"
    echo ""
    echo "$MODIFIED_NOW"
    echo ""
  fi
fi

# ── ROI estimate ──
if command -v jq >/dev/null 2>&1; then
  AGENT_TOKENS=$(jq -rs 'map(select(.event=="post" and .agent != "Bash") | .duration // 0) | add // 0' "$LOG" 2>/dev/null)
  if [ "$AGENT_TOKENS" -gt 0 ]; then
    # Heuristic: agents speeding up dev by 3-5x median
    # We can't measure real ROI here, just signal investment
    TOTAL_TIME_MIN=$((AGENT_TOKENS / 60))
    cat <<EOF
## ROI signal

Agents collectively spent **${AGENT_TOKENS}s (~${TOTAL_TIME_MIN}min) of compute** on your behalf this session.
That work would typically take 3-5× the time if done manually without specialist agents.

EOF
  fi
fi

cat <<'EOF'
## Recommended follow-up

- Run `bash bin/flow-viewer.sh` for an ASCII gantt of agent timing.
- Run `bash bin/compress.sh` for a token-efficient digest.
- If this session crossed a one-way door, run `/wrap-up` and accept the auto-ADR proposal.
EOF
