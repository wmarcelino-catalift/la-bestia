#!/usr/bin/env bats
# Tests for config/hooks/log-session.sh (Stop hook).
# Covers: writes session summary, reads agents.jsonl, no vault references.

setup() {
  HOOK="$BATS_TEST_DIRNAME/../../config/hooks/log-session.sh"
  [ -f "$HOOK" ] || skip "hook not found: $HOOK"
  TMPD="$(mktemp -d)"
  export CLAUDE_PROJECT_DIR="$TMPD"
  cd "$TMPD"
}

teardown() {
  [ -n "${TMPD:-}" ] && rm -rf "$TMPD"
}

@test "writes a session summary file under logs/sessions/" {
  run bash "$HOOK"
  [ "$status" -eq 0 ]
  ls "$TMPD/.claude/logs/sessions/" | grep -qE '^session-[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{4}\.md$'
}

@test "summary contains branch, uncommitted, last commit fields" {
  bash "$HOOK"
  FILE=$(ls "$TMPD/.claude/logs/sessions/"session-*.md | tail -1)
  grep -q '\*\*branch\*\*' "$FILE"
  grep -q '\*\*uncommitted\*\*' "$FILE"
  grep -q '\*\*last\*\*' "$FILE"
}

@test "summary section 'Agents used' is present even with no log" {
  bash "$HOOK"
  FILE=$(ls "$TMPD/.claude/logs/sessions/"session-*.md | tail -1)
  grep -q '## Agents used' "$FILE"
  grep -q 'none recorded' "$FILE"
}

@test "summary surfaces agents from agents.jsonl when present" {
  mkdir -p "$TMPD/.claude/logs"
  EPOCH=$(date +%s)
  cat > "$TMPD/.claude/logs/agents.jsonl" <<EOF
{"ts":"2026-05-03T22:00:00Z","epoch":$EPOCH,"event":"post","tool":"Task","agent":"architect","desc":"x","duration":5}
{"ts":"2026-05-03T22:01:00Z","epoch":$EPOCH,"event":"post","tool":"Task","agent":"architect","desc":"y","duration":3}
{"ts":"2026-05-03T22:02:00Z","epoch":$EPOCH,"event":"post","tool":"Task","agent":"debugger","desc":"z","duration":1}
EOF
  bash "$HOOK"
  FILE=$(ls "$TMPD/.claude/logs/sessions/"session-*.md | tail -1)
  grep -q 'architect' "$FILE"
  grep -q 'debugger' "$FILE"
}

@test "no Obsidian / vault references in output" {
  bash "$HOOK"
  FILE=$(ls "$TMPD/.claude/logs/sessions/"session-*.md | tail -1)
  ! grep -q -i 'obsidian' "$FILE"
  ! grep -q 'vault/' "$FILE"
  ! grep -q 'claude-brain' "$FILE"
}

@test "appends one line to all.log per invocation" {
  bash "$HOOK"
  bash "$HOOK"
  LINES=$(wc -l < "$TMPD/.claude/logs/sessions/all.log")
  [ "$LINES" -ge 2 ]
}
