#!/usr/bin/env bash
# bin/flow-viewer.sh — render an ASCII gantt chart of a session from agents.jsonl.
#
# Usage:
#   bash bin/flow-viewer.sh <jsonl-file>            # to stdout
#   tail -200 ~/.claude/logs/agents.jsonl | bash bin/flow-viewer.sh -
#
# Output: per-agent timeline bars + per-agent totals. Read-only. Idempotent.

set -eo pipefail

INPUT="${1:-}"
WIDTH="${FLOW_VIEWER_WIDTH:-40}"

if [ -z "$INPUT" ]; then
  cat <<'USAGE' >&2
usage: bash bin/flow-viewer.sh <jsonl-file | ->
  jsonl-file: path to agents.jsonl
  -          : read from stdin
env:
  FLOW_VIEWER_WIDTH=N   bar width in chars (default 40)
USAGE
  exit 2
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "✗ jq required" >&2
  exit 1
fi

TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT

if [ "$INPUT" = "-" ]; then
  cat > "$TMP"
else
  [ -f "$INPUT" ] || { echo "✗ not found: $INPUT" >&2; exit 1; }
  cp "$INPUT" "$TMP"
fi

# Filter post-events with real agent + epoch + duration. Output: agent\tepoch\tduration
ROWS=$(jq -rs '
  map(select(
    .event == "post"
    and .agent != null
    and .agent != "Bash"
    and .agent != "unknown"
    and .epoch != null
    and .duration != null
    and .duration > 0
  ))
  | sort_by(.epoch)
  | map([.agent, .epoch, .duration])
  | .[]
  | @tsv
' "$TMP" 2>/dev/null || true)

if [ -z "$ROWS" ]; then
  echo "(no agent post-events with duration found in input)"
  exit 0
fi

# All rendering done in awk (top-level functions for BWK-awk compatibility).
echo "$ROWS" | awk -F'\t' -v WIDTH="$WIDTH" '
function fmt_dur(s) {
  if (s < 60)   return sprintf("%ds", s)
  if (s < 3600) return sprintf("%dm %02ds", int(s/60), s%60)
  return sprintf("%dh %dm", int(s/3600), int((s%3600)/60))
}
function repeat(n, ch,    out, i) {
  out = ""
  for (i = 0; i < n; i++) out = out ch
  return out
}
{
  agent[NR] = $1
  epoch[NR] = $2 + 0
  dur[NR]   = $3 + 0
  if (NR == 1 || epoch[NR] < first) first = epoch[NR]
  end_t = epoch[NR] + dur[NR]
  if (end_t > last) last = end_t
  if (length($1) > name_w) name_w = length($1)
  uniq[$1] = 1
}
END {
  if (name_w < 8) name_w = 8
  total = (last - first); if (total < 1) total = 1

  uniq_count = 0
  for (a in uniq) uniq_count++

  printf "Session — %s · %d invocations · %d unique agents · width=%d\n\n", \
    fmt_dur(total), NR, uniq_count, WIDTH

  printf "%-*s | Timeline%s | duration\n", name_w, "Agent", repeat(WIDTH - 8, " ")
  printf "%s\n", repeat(name_w + WIDTH + 14, "-")

  for (i = 1; i <= NR; i++) {
    start_off = int((epoch[i] - first) * WIDTH / total)
    bar_len   = int(dur[i] * WIDTH / total)
    if (bar_len < 1) bar_len = 1
    end_off = start_off + bar_len
    if (end_off > WIDTH) end_off = WIDTH
    bar_actual = end_off - start_off
    if (bar_actual < 0) bar_actual = 0
    post_len = WIDTH - end_off
    if (post_len < 0) post_len = 0

    pre  = repeat(start_off, ".")
    bar  = repeat(bar_actual, "#")
    post = repeat(post_len, ".")
    printf "%-*s | %s%s%s | %s\n", name_w, agent[i], pre, bar, post, fmt_dur(dur[i])
  }

  print ""
  print "Totals (per agent):"
  for (i = 1; i <= NR; i++) {
    t_total[agent[i]] += dur[i]
    t_count[agent[i]] += 1
  }
  # Build sortable lines: prefix with zero-padded total for sort.
  n = 0
  for (a in t_total) {
    lines[n] = sprintf("%010d\t  %-*s  %d invocation(s)  %ds total", t_total[a], name_w, a, t_count[a], t_total[a])
    n++
  }
  # Selection sort descending by prefix.
  for (i = 0; i < n; i++) {
    for (j = i + 1; j < n; j++) {
      if (lines[i] < lines[j]) {
        tmp = lines[i]; lines[i] = lines[j]; lines[j] = tmp
      }
    }
  }
  for (i = 0; i < n; i++) {
    sub(/^[0-9]+\t/, "", lines[i])
    print lines[i]
  }
}
'
