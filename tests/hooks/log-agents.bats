#!/usr/bin/env bats
# Tests for config/hooks/log-agents.sh (v1.1 consolidated)
# Covers: Task pre/post with timing, Bash post only, jq-absent fallback.

setup() {
  HOOK="$BATS_TEST_DIRNAME/../../config/hooks/log-agents.sh"
  [ -f "$HOOK" ] || skip "hook not found: $HOOK"
  TMPD="$(mktemp -d)"
  mkdir -p "$TMPD/.claude/logs"
  export CLAUDE_PROJECT_DIR="$TMPD"
}

teardown() {
  [ -n "${TMPD:-}" ] && rm -rf "$TMPD"
}

# ── Task: pre + post emit, post computes duration ─────────────────────────────

@test "Task pre event writes agents.jsonl entry with event=pre" {
  CLAUDE_TOOL_INPUT='{"subagent_type":"architect","description":"design"}'
  CLAUDE_TOOL_NAME=Task run env CLAUDE_TOOL_NAME=Task CLAUDE_TOOL_INPUT="$CLAUDE_TOOL_INPUT" bash "$HOOK" pre
  [ "$status" -eq 0 ]
  [ -f "$TMPD/.claude/logs/agents.jsonl" ]
  grep -q '"event":"pre"' "$TMPD/.claude/logs/agents.jsonl"
  grep -q '"agent":"architect"' "$TMPD/.claude/logs/agents.jsonl"
  [ -f "$TMPD/.claude/logs/.agent_start_architect" ]
}

@test "Task post event computes duration when matching pre exists" {
  CLAUDE_TOOL_INPUT='{"subagent_type":"architect","description":"design"}'
  env CLAUDE_TOOL_NAME=Task CLAUDE_TOOL_INPUT="$CLAUDE_TOOL_INPUT" bash "$HOOK" pre
  sleep 1
  run env CLAUDE_TOOL_NAME=Task CLAUDE_TOOL_INPUT="$CLAUDE_TOOL_INPUT" bash "$HOOK" post
  [ "$status" -eq 0 ]
  # The post entry should have a numeric duration > 0
  POST_LINE=$(grep '"event":"post"' "$TMPD/.claude/logs/agents.jsonl" | tail -1)
  [ -n "$POST_LINE" ]
  echo "$POST_LINE" | grep -qE '"duration":[1-9][0-9]*'
  # Pre marker is removed after post fires
  [ ! -f "$TMPD/.claude/logs/.agent_start_architect" ]
}

@test "Task post without prior pre emits duration=null" {
  CLAUDE_TOOL_INPUT='{"subagent_type":"debugger","description":"orphan post"}'
  run env CLAUDE_TOOL_NAME=Task CLAUDE_TOOL_INPUT="$CLAUDE_TOOL_INPUT" bash "$HOOK" post
  [ "$status" -eq 0 ]
  grep -q '"agent":"debugger"' "$TMPD/.claude/logs/agents.jsonl"
  grep -q '"duration":null' "$TMPD/.claude/logs/agents.jsonl"
}

@test "Task pre/post for two agents tracks them independently" {
  env CLAUDE_TOOL_NAME=Task CLAUDE_TOOL_INPUT='{"subagent_type":"architect","description":"a"}' bash "$HOOK" pre
  env CLAUDE_TOOL_NAME=Task CLAUDE_TOOL_INPUT='{"subagent_type":"debugger","description":"b"}' bash "$HOOK" pre
  [ -f "$TMPD/.claude/logs/.agent_start_architect" ]
  [ -f "$TMPD/.claude/logs/.agent_start_debugger" ]
  env CLAUDE_TOOL_NAME=Task CLAUDE_TOOL_INPUT='{"subagent_type":"architect","description":"a"}' bash "$HOOK" post
  [ ! -f "$TMPD/.claude/logs/.agent_start_architect" ]
  [ -f "$TMPD/.claude/logs/.agent_start_debugger" ]
}

# ── Bash: only post emits ─────────────────────────────────────────────────────

@test "Bash pre is a no-op (does not write)" {
  CLAUDE_TOOL_INPUT='{"command":"ls -la"}'
  env CLAUDE_TOOL_NAME=Bash CLAUDE_TOOL_INPUT="$CLAUDE_TOOL_INPUT" bash "$HOOK" pre
  [ ! -f "$TMPD/.claude/logs/bash.jsonl" ]
}

@test "Bash post writes bash.jsonl" {
  CLAUDE_TOOL_INPUT='{"command":"git status"}'
  run env CLAUDE_TOOL_NAME=Bash CLAUDE_TOOL_INPUT="$CLAUDE_TOOL_INPUT" bash "$HOOK" post
  [ "$status" -eq 0 ]
  [ -f "$TMPD/.claude/logs/bash.jsonl" ]
  grep -q '"cmd":"git status"' "$TMPD/.claude/logs/bash.jsonl"
}

@test "Bash post truncates long commands at 200 chars" {
  long=$(printf 'echo %.0s' {1..100})
  CLAUDE_TOOL_INPUT="{\"command\":\"$long\"}"
  env CLAUDE_TOOL_NAME=Bash CLAUDE_TOOL_INPUT="$CLAUDE_TOOL_INPUT" bash "$HOOK" post
  CMD_LEN=$(grep -oE '"cmd":"[^"]+"' "$TMPD/.claude/logs/bash.jsonl" | head -1 | wc -c)
  # 200 chars + JSON wrapping (approx 210 cap)
  [ "$CMD_LEN" -lt 250 ]
}

# ── No-jq fallback ────────────────────────────────────────────────────────────

@test "writes minimal entry when jq is missing (degraded mode)" {
  # Simulate jq missing while keeping coreutils accessible. PATH="" wouldn't
  # work — the hook also needs mkdir/date/cat (external) before the jq check.
  fake_path=$(mktemp -d)
  for tool in mkdir date cat tr head printf; do
    src=$(command -v "$tool")
    [ -n "$src" ] && ln -sf "$src" "$fake_path/$tool"
  done
  run env PATH="$fake_path" CLAUDE_TOOL_NAME=Task CLAUDE_TOOL_INPUT='{"subagent_type":"x"}' bash "$HOOK" post
  [ "$status" -eq 0 ]
  rm -rf "$fake_path"
  grep -q '"note":"jq missing"' "$TMPD/.claude/logs/agents.jsonl"
}

# ── Schema-shape sanity ───────────────────────────────────────────────────────

@test "Task entries are valid single-line JSON" {
  env CLAUDE_TOOL_NAME=Task CLAUDE_TOOL_INPUT='{"subagent_type":"x","description":"y"}' bash "$HOOK" post
  while IFS= read -r line; do
    echo "$line" | jq empty
  done < "$TMPD/.claude/logs/agents.jsonl"
}

@test "Bash entries are valid single-line JSON" {
  env CLAUDE_TOOL_NAME=Bash CLAUDE_TOOL_INPUT='{"command":"ls"}' bash "$HOOK" post
  while IFS= read -r line; do
    echo "$line" | jq empty
  done < "$TMPD/.claude/logs/bash.jsonl"
}
