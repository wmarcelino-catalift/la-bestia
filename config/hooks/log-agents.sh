#!/usr/bin/env bash
# PreToolUse Task + PostToolUse Task|Bash — single source of truth for telemetry.
# Replaces the old track-agent.sh (deleted in v1.1; the timing logic is now here).
#
# Streams (project-local, under ${CLAUDE_PROJECT_DIR}/.claude/logs/):
#   agents.jsonl   — Task events (pre + post with duration)
#   bash.jsonl     — Bash post events
#
# Schema: schemas/log-event.schema.json
# Performance budget: < 100ms p99.
#
# Argument: $1 = "pre" or "post" (default: "post" for back-compat with old wirings).

set -u

PROJ="${CLAUDE_PROJECT_DIR:-$(pwd)}"
LOG_DIR="$PROJ/.claude/logs"
mkdir -p "$LOG_DIR"

INPUT="${CLAUDE_TOOL_INPUT:-}"
TOOL="${CLAUDE_TOOL_NAME:-unknown}"
SESSION="${CLAUDE_SESSION_ID:-unknown}"
EVENT="${1:-post}"
TS=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
EPOCH=$(date +%s)
CWD=$(pwd)

# Degrade: no jq → minimal entry, no timing.
if ! command -v jq >/dev/null 2>&1; then
  echo "{\"ts\":\"$TS\",\"epoch\":$EPOCH,\"session\":\"$SESSION\",\"event\":\"$EVENT\",\"tool\":\"$TOOL\",\"note\":\"jq missing\"}" >> "$LOG_DIR/agents.jsonl"
  exit 0
fi

case "$TOOL" in
  Task|Agent)
    AGENT=$(echo "$INPUT" | jq -r '.subagent_type // .agent_type // "unknown"' 2>/dev/null)
    DESC=$(echo "$INPUT" | jq -r '.description // .prompt // ""' 2>/dev/null | tr -d '\n\r' | head -c 200)
    DESC_JSON=$(printf '%s' "$DESC" | jq -Rs .)
    START_FILE="$LOG_DIR/.agent_start_${AGENT}"

    DURATION="null"
    if [ "$EVENT" = "pre" ]; then
      echo "$EPOCH" > "$START_FILE"
    elif [ "$EVENT" = "post" ] && [ -f "$START_FILE" ]; then
      START=$(cat "$START_FILE" 2>/dev/null)
      [ -n "$START" ] && DURATION=$((EPOCH - START))
      rm -f "$START_FILE"
    fi

    echo "{\"ts\":\"$TS\",\"epoch\":$EPOCH,\"session\":\"$SESSION\",\"event\":\"$EVENT\",\"tool\":\"$TOOL\",\"agent\":\"$AGENT\",\"desc\":${DESC_JSON},\"duration\":${DURATION},\"cwd\":\"$CWD\"}" >> "$LOG_DIR/agents.jsonl"
    ;;
  Bash)
    # Only log post for Bash. Pre would just duplicate.
    [ "$EVENT" != "post" ] && exit 0
    CMD=$(echo "$INPUT" | jq -r '.command // ""' 2>/dev/null | tr -d '\n\r' | head -c 200)
    CMD_JSON=$(printf '%s' "$CMD" | jq -Rs .)
    echo "{\"ts\":\"$TS\",\"epoch\":$EPOCH,\"session\":\"$SESSION\",\"event\":\"$EVENT\",\"tool\":\"$TOOL\",\"cmd\":${CMD_JSON},\"cwd\":\"$CWD\"}" >> "$LOG_DIR/bash.jsonl"
    ;;
esac

exit 0
