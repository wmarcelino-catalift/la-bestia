#!/usr/bin/env bash
# live-update.sh — near-real-time agent/tool activity to vault
# $1 = event (pre|post). Tool name read from $CLAUDE_TOOL_NAME env var.

VAULT="$HOME/Obsidian/claude-brain"
LIVE_FILE="$VAULT/live/session.md"
LOG_FILE="$HOME/.claude/logs/live-activity.jsonl"
mkdir -p "$VAULT/live" "$(dirname "$LOG_FILE")"

EVENT="${1:-post}"
TOOL="${CLAUDE_TOOL_NAME:-unknown}"   # read from env, not from args
TS=$(date '+%H:%M:%S')
CWD=$(pwd)
PROJECT=$(basename "$CWD")

# Parse what Claude is doing from tool input
INPUT=$(echo "${CLAUDE_TOOL_INPUT:-{}}" | jq -r '
  (.description // .command // .file_path // .prompt // .query // "—")
  | gsub("\n"; " ")
  | if length > 70 then .[0:70] + "…" else . end
' 2>/dev/null)
[ -z "$INPUT" ] && INPUT="—"
# For file paths, show only the filename
case "$TOOL" in
  Read|Edit|Write) INPUT=$(echo "$INPUT" | awk -F/ '{print $NF}') ;;
esac

# Emoji per tool
case "$TOOL" in
  Task)              ICON="🤖"; LABEL="Agent" ;;
  Bash)              ICON="⚡"; LABEL="Bash" ;;
  Edit|Write)        ICON="📝"; LABEL="$TOOL" ;;
  Read|Glob|Grep)    ICON="🔍"; LABEL="$TOOL" ;;
  WebFetch|WebSearch) ICON="🌐"; LABEL="Web" ;;
  *)                 ICON="🔧"; LABEL="$TOOL" ;;
esac

# Status
if [ "$EVENT" = "pre" ]; then
  ICON_STATUS="🔵"
  if [ "$TOOL" = "Task" ]; then
    CURRENT="**🔵 Ahora:** 🤖 Agent — \`${INPUT}\` — iniciando…"
  else
    CURRENT="**🔵 Ahora:** ${ICON} ${LABEL} — \`${INPUT}\`"
  fi
else
  ICON_STATUS="✅"
  CURRENT="**✅ Último:** ${ICON} ${LABEL} — \`${INPUT}\`"
fi

# Append to JSONL log (escape input for JSON)
INPUT_ESC=$(echo "$INPUT" | sed 's/"/\\"/g' | tr -d '\n')
echo "{\"ts\":\"$TS\",\"event\":\"$EVENT\",\"tool\":\"$TOOL\",\"label\":\"$LABEL\",\"icon\":\"$ICON\",\"input\":\"$INPUT_ESC\",\"project\":\"$PROJECT\"}" >> "$LOG_FILE"

# Build table from last 12 log entries (macOS compatible — no tac)
LAST12=$(tail -12 "$LOG_FILE" | jq -r \
  '"| " + .ts + " | " + .icon + " " + .label + " | " + .input' \
  2>/dev/null | tail -r 2>/dev/null || tail -12 "$LOG_FILE" | jq -r \
  '"| " + .ts + " | " + .icon + " " + .label + " | " + .input' \
  2>/dev/null)

# Stats
SESSION_START=$(head -1 "$LOG_FILE" 2>/dev/null | jq -r '.ts' 2>/dev/null || echo "$TS")
TOTAL_AGENTS=$(grep -c '"tool":"Task"' "$LOG_FILE" 2>/dev/null || echo 0)
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
$LAST12

---

## Stats · desde $SESSION_START
- 🤖 Agentes: **$TOTAL_AGENTS**
- 🔧 Tool calls: **$TOTAL_TOOLS**
- 📁 Proyecto: \`$PROJECT\`
- 📂 \`$CWD\`

*[[INDEX]] · La Bestia*
EOF

mv "$TEMP" "$LIVE_FILE"
