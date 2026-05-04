#!/usr/bin/env bash
# notify.sh — fire terminal bell + optional desktop notification when an agent
# finishes a long-running task (>2min by default).
#
# Hook event: PostToolUse Task. Reads duration from CLAUDE_TOOL_INPUT or
# computes from .agent_start_<name> markers maintained by log-agents.sh.
#
# Configurable via:
#   NOTIFY_THRESHOLD_SECONDS=120  (default 120 = 2min)
#   NOTIFY_DESKTOP=1              (1 = also use OS notification, default 0)
#
# OS-specific notification commands (if NOTIFY_DESKTOP=1):
#   macOS:   osascript -e 'display notification ...'
#   Linux:   notify-send (libnotify)
#   Windows: msg / PowerShell BurntToast (best-effort)

set -u

THRESHOLD="${NOTIFY_THRESHOLD_SECONDS:-120}"
DESKTOP="${NOTIFY_DESKTOP:-0}"

# Get tool name + input
TOOL="${CLAUDE_TOOL_NAME:-}"
INPUT="${CLAUDE_TOOL_INPUT:-{}}"

# Only act on Task post-events (when an agent completes)
[ "$TOOL" != "Task" ] && exit 0

# Try to get duration from input or .agent_start_*
DURATION=0
if command -v jq >/dev/null 2>&1; then
  DURATION=$(echo "$INPUT" | jq -r '.duration // 0' 2>/dev/null)
fi
[ "$DURATION" -lt "$THRESHOLD" ] && exit 0

# Get agent name for notification body
AGENT="agent"
if command -v jq >/dev/null 2>&1; then
  AGENT=$(echo "$INPUT" | jq -r '.subagent_type // .agent_type // "agent"' 2>/dev/null)
fi

MSG="La Bestia · ${AGENT} completed in ${DURATION}s"

# 1. Always: terminal bell
printf '\a' 2>/dev/null

# 2. Optional: desktop notification
if [ "$DESKTOP" = "1" ]; then
  case "$(uname -s 2>/dev/null)" in
    Darwin)
      osascript -e "display notification \"$MSG\" with title \"La Bestia\" sound name \"Glass\"" 2>/dev/null
      ;;
    Linux)
      command -v notify-send >/dev/null 2>&1 && notify-send "La Bestia" "$MSG" 2>/dev/null
      ;;
    MINGW*|MSYS*|CYGWIN*)
      # Windows: try BurntToast via PowerShell, fallback to msg
      command -v powershell.exe >/dev/null 2>&1 && \
        powershell.exe -Command "[System.Console]::Beep(800,200)" 2>/dev/null
      ;;
  esac
fi

exit 0
