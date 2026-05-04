#!/usr/bin/env bash
# agent-memory-compact.sh — keep ~/.claude/agent-memory/<agent>/MEMORY.md from
# growing unbounded. Identifies files larger than threshold and produces a
# compaction-ready markdown that the operator (or @mentor) can review.
#
# We do NOT auto-rewrite files (operator's data, requires consent).
# We produce a report + a "candidates" file. Operator approves and applies.
#
# Usage:
#   bash bin/agent-memory-compact.sh                  # report all agents
#   bash bin/agent-memory-compact.sh <agent-name>     # report one agent
#
# Configurable:
#   COMPACT_THRESHOLD_KB=8     compact when MEMORY.md > N KB (default 8)
#   COMPACT_OUTPUT_DIR=...     where to write candidates (default: same dir as MEMORY.md)

set -euo pipefail

THRESHOLD_KB="${COMPACT_THRESHOLD_KB:-8}"
TARGET_AGENT="${1:-}"

MEMORY_ROOT="$HOME/.claude/agent-memory"
[ -d "$MEMORY_ROOT" ] || { echo "(no agent-memory directory at $MEMORY_ROOT)"; exit 0; }

# ── Collect candidates ──
CANDIDATES=()
TOTAL_KB=0

for agent_dir in "$MEMORY_ROOT"/*/; do
  agent=$(basename "$agent_dir")
  [ -n "$TARGET_AGENT" ] && [ "$agent" != "$TARGET_AGENT" ] && continue

  mem_file="$agent_dir/MEMORY.md"
  [ -f "$mem_file" ] || continue

  size_bytes=$(stat -c '%s' "$mem_file" 2>/dev/null || stat -f '%z' "$mem_file" 2>/dev/null || echo 0)
  size_kb=$((size_bytes / 1024))
  TOTAL_KB=$((TOTAL_KB + size_kb))

  if [ "$size_kb" -ge "$THRESHOLD_KB" ]; then
    CANDIDATES+=("$agent:$size_kb:$mem_file")
  fi
done

# ── Report ──
echo "# agent-memory compaction report"
echo ""
echo "> Generated $(date -u +'%Y-%m-%dT%H:%M:%SZ') · threshold ${THRESHOLD_KB}KB"
echo ""

if [ ${#CANDIDATES[@]} -eq 0 ]; then
  echo "✅ No agent-memory file exceeds ${THRESHOLD_KB}KB."
  echo "Total memory across all agents: ${TOTAL_KB}KB."
  exit 0
fi

echo "## Candidates for compaction (>${THRESHOLD_KB}KB)"
echo ""
echo "| Agent | Size | Action |"
echo "|---|---|---|"
for entry in "${CANDIDATES[@]}"; do
  IFS=':' read -r agent size_kb mem_file <<< "$entry"
  echo "| \`$agent\` | ${size_kb}KB | review \`$mem_file\` |"
done
echo ""
echo "## How to compact"
echo ""
cat <<'EOF'
For each candidate:

1. Open the MEMORY.md and read it. Identify what's still useful vs stale.
2. Inside Claude, ask: `@mentor compact ~/.claude/agent-memory/<agent>/MEMORY.md`
   The mentor agent applies pre-mortem heuristic to keep only what would
   prevent future mistakes.
3. Approve the compacted version, save it back.

OR manual rule of thumb:

- **Keep**: patterns observed 3+ times, decisions with rationale, gotchas with detection signal.
- **Drop**: one-off observations, redundant examples, dead-code references, duplicates.

After compaction, run `bash bin/agent-memory-compact.sh` again to confirm.
EOF
echo ""
echo "Total memory across all agents: ${TOTAL_KB}KB."
