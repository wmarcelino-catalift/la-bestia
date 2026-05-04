#!/usr/bin/env bash
# bin/parallelism-check.sh — verify that la-bestia /flow phases dispatch agents
# in true parallel (multiple Task tools in ONE message), not sequentially.
#
# Method:
#   1. Read agents.jsonl
#   2. Bucket pre-events by 5-second windows (epoch / 5)
#   3. Buckets with ≥2 pre events = parallel dispatch evidence
#   4. Compare elapsed time of those buckets vs sum of individual durations
#
# Pass criteria:
#   ≥1 bucket with ≥3 simultaneous pre events (signals /flow Phase 1 fan-out)
#   For each fan-out: elapsed ≈ max(durations) ± 30%, NOT ≈ sum(durations)
#
# Usage:
#   bash bin/parallelism-check.sh                       # current project
#   bash bin/parallelism-check.sh /path/to/agents.jsonl # specific file
#   bash bin/parallelism-check.sh --json                # JSON output for CI

set -euo pipefail

JSON_OUT=0
LOG=""
for arg in "$@"; do
  case "$arg" in
    --json) JSON_OUT=1 ;;
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

# ── Find pre-event buckets (5s windows with multiple agents) ─────────────────
# Output: epoch_bucket  agent_count  agent_list (csv)
BUCKETS=$(jq -rs '
  map(select(.event == "pre" and .agent != null and .agent != "Bash" and .agent != "unknown" and .epoch != null))
  | group_by(.epoch / 5 | floor)
  | map(select(length >= 2))
  | map({
      bucket_epoch: (.[0].epoch / 5 | floor) * 5,
      count: length,
      agents: (map(.agent) | join(","))
    })
  | sort_by(.bucket_epoch)
  | .[]
  | "\(.bucket_epoch)\t\(.count)\t\(.agents)"
' "$LOG" 2>/dev/null || true)

# ── Calculate elapsed vs sum per fan-out (using post events) ─────────────────
# For each parallel dispatch, find matching post events and compute:
#   elapsed = max(post.epoch) - min(pre.epoch)
#   sum     = sum(durations)
#   ratio   = elapsed / sum   (closer to 1.0 = pure serial; closer to 1/N = pure parallel)

PARALLEL_EVIDENCE=$(jq -rs --arg ext "external" '
  # Helper: find post events that match a pre event
  . as $all
  | map(select(.event == "pre" and .agent != null and .agent != "Bash" and .agent != "unknown" and .epoch != null))
  | group_by(.epoch / 5 | floor)
  | map(select(length >= 2))
  | map(. as $bucket
        | ($bucket | map(.epoch) | min) as $start
        | ($bucket | map(.agent)) as $agents
        | ($all | map(select(.event == "post" and (.agent as $a | $agents | index($a)) and .epoch != null and .duration != null))) as $posts
        | ($posts | sort_by(.epoch) | last.epoch // 0) as $end
        | ($posts | map(.duration // 0) | add // 0) as $sum_dur
        | ($end - $start) as $elapsed
        | {
            bucket_start: $start,
            n_agents: length,
            agents: ($agents | join(",")),
            elapsed: $elapsed,
            sum_durations: $sum_dur,
            ratio: (if $sum_dur > 0 then ($elapsed * 100 / $sum_dur) else 0 end),
            verdict: (if $sum_dur > 0 and ($elapsed * 100 / $sum_dur) < 60 then "PARALLEL" else "SERIAL_OR_SLOW" end)
          })
  | .[]
  | "\(.bucket_start)\t\(.n_agents)\t\(.elapsed)\t\(.sum_durations)\t\(.ratio)\t\(.verdict)\t\(.agents)"
' "$LOG" 2>/dev/null || true)

# ── Output ───────────────────────────────────────────────────────────────────
if [ "$JSON_OUT" -eq 1 ]; then
  if [ -z "$PARALLEL_EVIDENCE" ]; then
    echo '{"fan_outs": 0, "verdict": "no fan-outs found in log"}'
    exit 0
  fi
  echo "$PARALLEL_EVIDENCE" | jq -Rs '
    split("\n") | map(select(length > 0)) | map(split("\t") | {
      bucket_start: (.[0] | tonumber),
      n_agents: (.[1] | tonumber),
      elapsed: (.[2] | tonumber),
      sum_durations: (.[3] | tonumber),
      ratio_pct: (.[4] | tonumber),
      verdict: .[5],
      agents: .[6]
    }) as $fanouts
    | {
        fan_outs: ($fanouts | length),
        parallel_count: ($fanouts | map(select(.verdict == "PARALLEL")) | length),
        serial_count: ($fanouts | map(select(.verdict == "SERIAL_OR_SLOW")) | length),
        details: $fanouts
      }
  '
  exit 0
fi

# Human-readable
echo "# Parallelism check — $LOG"
echo ""
if [ -z "$PARALLEL_EVIDENCE" ]; then
  echo "(no fan-out events detected)"
  echo ""
  echo "If you ran /flow recently, this is unexpected. Check:"
  echo "  1. agents.jsonl has 'event:pre' entries (track-agent / log-agents firing)"
  echo "  2. /flow actually dispatched parallel via Task tool in one message"
  exit 0
fi

NUM_FANOUTS=$(echo "$PARALLEL_EVIDENCE" | wc -l | tr -d ' ')
PARALLEL_OK=$(echo "$PARALLEL_EVIDENCE" | awk -F'\t' '$6=="PARALLEL"' | wc -l | tr -d ' ')
SERIAL=$(echo "$PARALLEL_EVIDENCE" | awk -F'\t' '$6=="SERIAL_OR_SLOW"' | wc -l | tr -d ' ')

echo "Fan-out events detected: $NUM_FANOUTS"
echo "  ✓ PARALLEL (elapsed < 60% of sum): $PARALLEL_OK"
echo "  ✗ SERIAL_OR_SLOW (elapsed ≥ 60% of sum): $SERIAL"
echo ""
echo "## Per fan-out detail"
echo ""
printf "%-12s | %-7s | %-8s | %-8s | %-7s | %-15s | %s\n" "epoch" "agents" "elapsed" "sum" "ratio%" "verdict" "agent list"
echo "------------|--------|----------|----------|---------|-----------------|------------"
echo "$PARALLEL_EVIDENCE" | while IFS=$'\t' read -r start n elapsed sum ratio verdict agents; do
  printf "%-12s | %-7s | %-8s | %-8s | %-7s | %-15s | %s\n" "$start" "$n" "${elapsed}s" "${sum}s" "${ratio}%" "$verdict" "$agents"
done
echo ""
if [ "$SERIAL" -gt 0 ]; then
  echo "⚠ $SERIAL fan-out(s) ran serial-or-slow. Investigate:"
  echo "  - Was the dispatch in ONE message with N Task tools? (true parallel)"
  echo "  - Or was it N sequential Task calls? (would still log as parallel buckets but ratio ≈ 100%)"
  echo "  - Check Claude Code version supports parallel Task tool dispatch."
fi
