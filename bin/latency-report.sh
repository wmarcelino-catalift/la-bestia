#!/usr/bin/env bash
# bin/latency-report.sh — p50/p95 latency per agent from agents.jsonl.
# Compares against per-tier budgets, emits status (✓/⚠/✗).
#
# Budgets (default — env-overridable):
#   Opus agents (architect, debugger, mentor, strategist):
#     p50 < 60s, p95 < 180s
#   Sonnet agents (everyone else):
#     p50 < 30s, p95 < 90s
#   SCAN MODE invocations:
#     p50 < 15s, p95 < 30s
#
# Usage:
#   bash bin/latency-report.sh                       # current project, table
#   bash bin/latency-report.sh /path/agents.jsonl    # specific file
#   bash bin/latency-report.sh --json                # JSON for CI
#   bash bin/latency-report.sh --strict              # exit 1 if any agent over budget

set -euo pipefail

JSON_OUT=0
STRICT=0
LOG=""

for arg in "$@"; do
  case "$arg" in
    --json) JSON_OUT=1 ;;
    --strict) STRICT=1 ;;
    *) LOG="$arg" ;;
  esac
done

if [ -z "$LOG" ]; then
  PROJ="${CLAUDE_PROJECT_DIR:-$(pwd)}"
  LOG="$PROJ/.claude/logs/agents.jsonl"
fi

[ -f "$LOG" ] || { echo "✗ not found: $LOG" >&2; exit 1; }

if ! command -v jq >/dev/null 2>&1; then
  echo "✗ jq required" >&2
  exit 1
fi

# Budget thresholds (overridable)
OPUS_P50="${LATENCY_OPUS_P50:-60}"
OPUS_P95="${LATENCY_OPUS_P95:-180}"
SONNET_P50="${LATENCY_SONNET_P50:-30}"
SONNET_P95="${LATENCY_SONNET_P95:-90}"

# Opus agents (per ADR-0003 / model assignments)
OPUS_AGENTS="strategist architect mentor debugger"

# ── Compute p50/p95 per agent ────────────────────────────────────────────────
STATS=$(jq -rs '
  map(select(.event == "post" and .agent != null and .agent != "Bash" and .agent != "unknown" and .duration != null and .duration > 0))
  | group_by(.agent)
  | map(. as $g
        | (.[0].agent) as $agent
        | (length) as $n
        | (sort_by(.duration) | map(.duration)) as $durs
        | {
            agent: $agent,
            n: $n,
            p50: ($durs[($n / 2 | floor)] // 0),
            p95: ($durs[($n * 95 / 100 | floor)] // ($durs | last // 0)),
            total: ($durs | add // 0)
          })
  | sort_by(-.n)
  | .[]
  | "\(.agent)\t\(.n)\t\(.p50)\t\(.p95)\t\(.total)"
' "$LOG" 2>/dev/null || true)

[ -z "$STATS" ] && {
  echo "(no agent post-events with duration in $LOG)"
  exit 0
}

# ── Verdict per agent ────────────────────────────────────────────────────────
VERDICTS=""
HARD_FAIL=0
while IFS=$'\t' read -r agent n p50 p95 total; do
  # Determine budget
  if echo "$OPUS_AGENTS" | grep -qw "$agent"; then
    budget_p50="$OPUS_P50"
    budget_p95="$OPUS_P95"
    tier="opus"
  else
    budget_p50="$SONNET_P50"
    budget_p95="$SONNET_P95"
    tier="sonnet"
  fi

  # Compare
  status="✓"
  if [ "$p95" -gt "$budget_p95" ]; then
    status="✗"
    HARD_FAIL=1
  elif [ "$p50" -gt "$budget_p50" ]; then
    status="⚠"
  fi

  VERDICTS="${VERDICTS}${agent}\t${tier}\t${n}\t${p50}\t${p95}\t${budget_p50}\t${budget_p95}\t${status}\t${total}\n"
done <<< "$STATS"

# Trim trailing newline
VERDICTS=$(printf '%b' "$VERDICTS" | sed '/^$/d')

# ── Output ──
if [ "$JSON_OUT" -eq 1 ]; then
  echo "$VERDICTS" | jq -Rs '
    split("\n") | map(select(length > 0)) | map(split("\t") | {
      agent: .[0],
      tier: .[1],
      n: (.[2] | tonumber),
      p50: (.[3] | tonumber),
      p95: (.[4] | tonumber),
      budget_p50: (.[5] | tonumber),
      budget_p95: (.[6] | tonumber),
      status: .[7],
      total_seconds: (.[8] | tonumber)
    }) as $rows
    | {
        agents: ($rows | length),
        over_budget: ($rows | map(select(.status == "✗")) | length),
        warning: ($rows | map(select(.status == "⚠")) | length),
        ok: ($rows | map(select(.status == "✓")) | length),
        details: $rows
      }
  '
else
  echo "# Latency report — $LOG"
  echo ""
  echo "Budgets: opus p50<${OPUS_P50}s p95<${OPUS_P95}s · sonnet p50<${SONNET_P50}s p95<${SONNET_P95}s"
  echo ""
  printf "%-18s | %-7s | %-4s | %-5s | %-5s | %-9s | %-9s | %-7s\n" \
    "Agent" "Tier" "n" "p50" "p95" "budget p50" "budget p95" "Status"
  echo "-------------------|---------|------|-------|-------|-----------|-----------|--------"
  printf '%b' "$VERDICTS" | while IFS=$'\t' read -r agent tier n p50 p95 b50 b95 status total; do
    printf "%-18s | %-7s | %-4s | %-5ss | %-5ss | %-9ss | %-9ss | %-7s\n" \
      "$agent" "$tier" "$n" "$p50" "$p95" "$b50" "$b95" "$status"
  done
  echo ""
  if [ "$HARD_FAIL" -eq 1 ]; then
    echo "✗ One or more agents exceeded p95 budget."
    echo "  Fix: review agent prompts in config/agents/ — verbose agents = slow agents."
    echo "  Often: trim 'Frontier knowledge' section, tighten 'Output contract'."
  fi
fi

[ "$STRICT" -eq 1 ] && [ "$HARD_FAIL" -eq 1 ] && exit 1
exit 0
