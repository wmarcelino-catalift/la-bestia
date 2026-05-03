#!/usr/bin/env bash
# PostToolUse: Task|Bash. Append JSONL events to .claude/logs/.
# Project-local: writes under ${CLAUDE_PROJECT_DIR}/.claude/logs/.

set -u

PROJ="${CLAUDE_PROJECT_DIR:-$(pwd)}"
LOG_DIR="$PROJ/.claude/logs"
mkdir -p "$LOG_DIR"

INPUT="${CLAUDE_TOOL_INPUT:-}"
TOOL="${CLAUDE_TOOL_NAME:-unknown}"
SESSION="${CLAUDE_SESSION_ID:-unknown}"
TS=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
CWD=$(pwd)

if ! command -v jq >/dev/null 2>&1; then
  # No jq → write a minimal line and exit.
  echo "{\"ts\":\"$TS\",\"session\":\"$SESSION\",\"tool\":\"$TOOL\",\"cwd\":\"$CWD\",\"note\":\"jq missing\"}" >> "$LOG_DIR/agents.jsonl"
  exit 0
fi

case "$TOOL" in
  Task|Agent)
    SUBAGENT=$(echo "$INPUT" | jq -r '.subagent_type // .agent_type // "unknown"' 2>/dev/null)
    DESC=$(echo "$INPUT" | jq -r '.description // ""' 2>/dev/null | head -c 200)
    echo "{\"ts\":\"$TS\",\"session\":\"$SESSION\",\"event\":\"agent\",\"agent\":\"$SUBAGENT\",\"desc\":$(echo "$DESC" | jq -Rs .),\"cwd\":\"$CWD\"}" >> "$LOG_DIR/agents.jsonl"
    ;;
  Bash)
    CMD=$(echo "$INPUT" | jq -r '.command // ""' 2>/dev/null | head -c 200)
    echo "{\"ts\":\"$TS\",\"session\":\"$SESSION\",\"event\":\"bash\",\"cmd\":$(echo "$CMD" | jq -Rs .),\"cwd\":\"$CWD\"}" >> "$LOG_DIR/bash.jsonl"
    ;;
esac

exit 0
