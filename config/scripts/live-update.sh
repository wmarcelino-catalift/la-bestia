#!/usr/bin/env bash
# live-update.sh — writes near-real-time agent/tool activity to vault
# Called from PreToolUse (Task) and PostToolUse (Task, Bash, Write, Edit)
# Args: $1 = event type (pre|post), $2 = tool name

VAULT="$HOME/Obsidian/claude-brain"
LIVE_FILE="$VAULT/live/session.md"
LOG_FILE="$HOME/.claude/logs/live-activity.jsonl"
mkdir -p "$VAULT/live" "$(dirname "$LOG_FILE")"

EVENT="${1:-post}"
TOOL="${2:-unknown}"
TS=$(date '+%H:%M:%S')
DATE=$(date '+%Y-%m-%d')
CWD=$(pwd)
PROJECT=$(basename "$CWD")

# Parse tool input from env
INPUT=$(echo "${CLAUDE_TOOL_INPUT:-{}}" | jq -r '
  if .description then .description
  elif .command then (.command | split("\n")[0] | .[0:80])
  elif .file_path then .file_path
  elif .prompt then (.prompt | .[0:80])
  else "—"
  end' 2>/dev/null || echo "—")

# Emoji + label per tool
case "$TOOL" in
  Task)        ICON="🤖"; LABEL="Agent" ;;
  Bash)        ICON="⚡"; LABEL="Bash" ;;
  Edit|Write)  ICON="📝"; LABEL="File" ;;
  Read|Glob)   ICON="🔍"; LABEL="Read" ;;
  *)           ICON="🔧"; LABEL="$TOOL" ;;
esac

# Status per event
if [ "$EVENT" = "pre" ]; then
  STATUS="starting…"
  ICON_STATUS="🔵"
else
  STATUS="done"
  ICON_STATUS="✅"
fi

# Append to JSONL log
echo "{\"ts\":\"$TS\",\"event\":\"$EVENT\",\"tool\":\"$TOOL\",\"input\":\"$INPUT\",\"project\":\"$PROJECT\"}" >> "$LOG_FILE"

# Build rolling last-10 lines from log
LAST10=$(tail -20 "$LOG_FILE" | jq -r \
  '"| " + .ts + " | " + (if .tool == "Task" then "🤖 Agent" elif .tool == "Bash" then "⚡ Bash" elif (.tool == "Edit" or .tool == "Write") then "📝 " + .tool else "🔧 " + .tool end) + " | " + .input' \
  2>/dev/null | tail -10 | tac)

# Current action line
if [ "$EVENT" = "pre" ] && [ "$TOOL" = "Task" ]; then
  CURRENT="**${ICON_STATUS} Ahora:** \`$(echo "$INPUT" | head -c 60)\` — iniciando…"
elif [ "$EVENT" = "pre" ]; then
  CURRENT="**${ICON_STATUS} Ahora:** ${ICON} \`$(echo "$INPUT" | head -c 60)\`"
else
  CURRENT="**${ICON_STATUS} Último:** ${ICON} ${LABEL} — \`$(echo "$INPUT" | head -c 60)\` — done"
fi

# Session start time (first entry in log for today)
SESSION_START=$(grep "\"ts\"" "$LOG_FILE" 2>/dev/null | head -1 | jq -r '.ts' 2>/dev/null || echo "$TS")
TOTAL_AGENTS=$(grep '"tool":"Task"' "$LOG_FILE" 2>/dev/null | wc -l | tr -d ' ')
TOTAL_TOOLS=$(wc -l < "$LOG_FILE" 2>/dev/null | tr -d ' ')

# Write atomically
TEMP=$(mktemp)
cat > "$TEMP" <<EOF
---
updated: $(date -u +'%Y-%m-%dT%H:%M:%SZ')
project: $PROJECT
type: live-session
---

# ⚡ LIVE — $PROJECT · $TS

$CURRENT

---

## Últimos movimientos

| Hora | Tool | Descripción |
|---|---|---|
$LAST10

---

## Stats · sesión desde $SESSION_START
- 🤖 Agentes invocados: **$TOTAL_AGENTS**
- 🔧 Tool calls totales: **$TOTAL_TOOLS**
- 📁 Proyecto: \`$PROJECT\`
- 📂 Path: \`$CWD\`

---
*Auto-actualizado por La Bestia · [[INDEX]]*
EOF

mv "$TEMP" "$LIVE_FILE"
