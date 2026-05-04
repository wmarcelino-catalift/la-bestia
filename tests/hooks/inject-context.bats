#!/usr/bin/env bats
# Tests for config/hooks/inject-context.sh (v3.0)
# Verifies: session header, stack auto-detection, git richness, memory injection.

setup() {
  HOOK="$BATS_TEST_DIRNAME/../../config/hooks/inject-context.sh"
  [ -f "$HOOK" ] || skip "hook not found: $HOOK"
  TMPD="$(mktemp -d)"
}

teardown() {
  [ -n "${TMPD:-}" ] && rm -rf "$TMPD"
}

@test "outputs session header even with no git, no memory" {
  cd "$TMPD"
  run bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"## Session"* ]]
}

@test "session header includes project basename" {
  PROJ_NAME="my-acme-app"
  WORK="$TMPD/$PROJ_NAME"
  mkdir -p "$WORK"
  cd "$WORK"
  run env CLAUDE_PROJECT_DIR="$WORK" bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"$PROJ_NAME"* ]]
}

@test "no Obsidian / vault references in output" {
  cd "$TMPD"
  run bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" != *"Obsidian"* ]]
  [[ "$output" != *"vault"* ]]
  [[ "$output" != *"HOT.md"* ]]
}

@test "includes project hot-context.md when present" {
  cd "$TMPD"
  mkdir -p memory
  echo "## Proyecto Test" > memory/hot-context.md
  echo "- canary line" >> memory/hot-context.md
  run env CLAUDE_PROJECT_DIR="$TMPD" bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"canary line"* ]]
}

@test "skips git block when not in a repo" {
  cd "$TMPD"
  run bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"no git repo"* ]]
}

# ── Stack auto-detection ─────────────────────────────────────────────────────

@test "detects Node.js stack from package.json" {
  cd "$TMPD"
  echo '{"name":"foo"}' > package.json
  run env CLAUDE_PROJECT_DIR="$TMPD" bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Node.js"* ]]
}

@test "detects TypeScript on top of Node.js" {
  cd "$TMPD"
  echo '{"name":"foo"}' > package.json
  echo '{}' > tsconfig.json
  run env CLAUDE_PROJECT_DIR="$TMPD" bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Node.js"* ]]
  [[ "$output" == *"TypeScript"* ]]
}

@test "detects Python stack from pyproject.toml" {
  cd "$TMPD"
  echo "[project]" > pyproject.toml
  run env CLAUDE_PROJECT_DIR="$TMPD" bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Python"* ]]
}

@test "detects Rust stack from Cargo.toml" {
  cd "$TMPD"
  echo "[package]" > Cargo.toml
  run env CLAUDE_PROJECT_DIR="$TMPD" bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Rust"* ]]
}

@test "detects Go stack from go.mod" {
  cd "$TMPD"
  echo "module foo" > go.mod
  run env CLAUDE_PROJECT_DIR="$TMPD" bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Go"* ]]
}

@test "stack line absent when nothing detected" {
  cd "$TMPD"
  run bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" != *"**stack**"* ]]
}

# ── Performance ──────────────────────────────────────────────────────────────

@test "completes under 1 second on a no-op invocation" {
  cd "$TMPD"
  start=$(date +%s%N)
  run bash "$HOOK"
  end=$(date +%s%N)
  elapsed_ms=$(( (end - start) / 1000000 ))
  [ "$status" -eq 0 ]
  [ "$elapsed_ms" -lt 1000 ]
}
