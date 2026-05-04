#!/usr/bin/env bats
# Tests for config/hooks/restore-context.sh (v4.2)
# Verifies: source discrimination, content injection, anti-compaction-loss.

setup() {
  HOOK="$BATS_TEST_DIRNAME/../../config/hooks/restore-context.sh"
  [ -f "$HOOK" ] || skip "hook not found: $HOOK"
  TMPD="$(mktemp -d)"
}

teardown() {
  [ -n "${TMPD:-}" ] && rm -rf "$TMPD"
}

# ── Source discrimination ────────────────────────────────────────────────────

@test "exits silently on startup source (lets inject-context handle it)" {
  cd "$TMPD"
  run env CLAUDE_SESSION_SOURCE="startup" CLAUDE_PROJECT_DIR="$TMPD" bash "$HOOK"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "exits silently when source is empty" {
  cd "$TMPD"
  run env CLAUDE_PROJECT_DIR="$TMPD" bash "$HOOK"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "fires on compact source" {
  cd "$TMPD"
  run env CLAUDE_SESSION_SOURCE="compact" CLAUDE_PROJECT_DIR="$TMPD" bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"[restore-context]"* ]]
  [[ "$output" == *"compact"* ]]
}

@test "fires on resume source" {
  cd "$TMPD"
  run env CLAUDE_SESSION_SOURCE="resume" CLAUDE_PROJECT_DIR="$TMPD" bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"[restore-context]"* ]]
  [[ "$output" == *"resume"* ]]
}

# ── Content injection ────────────────────────────────────────────────────────

@test "injects hot-context.md content when present" {
  cd "$TMPD"
  mkdir -p memory
  echo "# canary-hot-context-line" > memory/hot-context.md
  run env CLAUDE_SESSION_SOURCE="compact" CLAUDE_PROJECT_DIR="$TMPD" bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"canary-hot-context-line"* ]]
}

@test "lists ADRs from memory/decisions/" {
  cd "$TMPD"
  mkdir -p memory/decisions
  echo "# ADR-0001 — canary-decision" > memory/decisions/0001-canary.md
  run env CLAUDE_SESSION_SOURCE="compact" CLAUDE_PROJECT_DIR="$TMPD" bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"0001-canary.md"* ]]
  [[ "$output" == *"canary-decision"* ]]
}

@test "lists patterns from memory/patterns/" {
  cd "$TMPD"
  mkdir -p memory/patterns
  echo "# canary-pattern-title" > memory/patterns/idempotent-handlers.md
  run env CLAUDE_SESSION_SOURCE="compact" CLAUDE_PROJECT_DIR="$TMPD" bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"idempotent-handlers.md"* ]]
  [[ "$output" == *"canary-pattern-title"* ]]
}

@test "lists lessons from memory/lessons/ when present (v4.2)" {
  cd "$TMPD"
  mkdir -p memory/lessons
  echo "# canary-lesson-title" > memory/lessons/2026-05-04-flaky-test.md
  run env CLAUDE_SESSION_SOURCE="compact" CLAUDE_PROJECT_DIR="$TMPD" bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"2026-05-04-flaky-test.md"* ]]
  [[ "$output" == *"canary-lesson-title"* ]]
}

@test "skips lessons section when memory/lessons/ does not exist" {
  cd "$TMPD"
  run env CLAUDE_SESSION_SOURCE="compact" CLAUDE_PROJECT_DIR="$TMPD" bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" != *"#### Lessons"* ]]
}

# ── Footer + safety ──────────────────────────────────────────────────────────

@test "footer mentions ADRs / patterns / lessons as source of truth" {
  cd "$TMPD"
  run env CLAUDE_SESSION_SOURCE="resume" CLAUDE_PROJECT_DIR="$TMPD" bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"source of truth"* ]]
}

@test "no Obsidian / vault references in output" {
  cd "$TMPD"
  mkdir -p memory
  echo "# hot" > memory/hot-context.md
  run env CLAUDE_SESSION_SOURCE="compact" CLAUDE_PROJECT_DIR="$TMPD" bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" != *"Obsidian"* ]]
  [[ "$output" != *"vault"* ]]
}

# ── Performance ──────────────────────────────────────────────────────────────

@test "completes under 500ms on a non-fire path (startup)" {
  cd "$TMPD"
  start=$(date +%s%N)
  run env CLAUDE_SESSION_SOURCE="startup" CLAUDE_PROJECT_DIR="$TMPD" bash "$HOOK"
  end=$(date +%s%N)
  elapsed_ms=$(( (end - start) / 1000000 ))
  [ "$status" -eq 0 ]
  [ "$elapsed_ms" -lt 500 ]
}

@test "completes under 1 second on a fire path (compact, empty memory)" {
  cd "$TMPD"
  start=$(date +%s%N)
  run env CLAUDE_SESSION_SOURCE="compact" CLAUDE_PROJECT_DIR="$TMPD" bash "$HOOK"
  end=$(date +%s%N)
  elapsed_ms=$(( (end - start) / 1000000 ))
  [ "$status" -eq 0 ]
  [ "$elapsed_ms" -lt 1000 ]
}
