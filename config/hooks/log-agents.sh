#!/usr/bin/env bash
# PostToolUse: Task (subagent invocations) AND Bash (audit trail)
# Appends one JSON line per event to ~/.claude/logs/agents.jsonl
# Used by scripts/flow-diagram.sh to render Mermaid flow.

set -u

LOG_DIR="$HOME/.claude/logs"
mkdir -p "$LOG_DIR"

INPUT="${CLAUDE_TOOL_INPUT:-}"
TOOL="${CLAUDE_TOOL_NAME:-unknown}"
SESSION="${CLAUDE_SESSION_ID:-unknown}"
TS=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
CWD=$(pwd)

# Extract relevant fields by tool type
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
