#!/usr/bin/env bats
# Tests for bin/onboard.sh — project bootstrap wizard.
# Verifies: idempotency, stack detection, no-overwrite of existing files.

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../../bin/onboard.sh"
  REPO_ROOT="$BATS_TEST_DIRNAME/../.."
  [ -f "$SCRIPT" ] || skip "script not found: $SCRIPT"
  TMPD="$(mktemp -d)"
  export CLAUDE_PROJECT_DIR="$TMPD"
  export LA_BESTIA_HOME="$REPO_ROOT"
}

teardown() {
  [ -n "${TMPD:-}" ] && rm -rf "$TMPD"
}

@test "creates memory/, .claudeignore, CLAUDE.md on a fresh project" {
  echo '{"name":"foo"}' > "$TMPD/package.json"
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [ -f "$TMPD/memory/hot-context.md" ]
  [ -f "$TMPD/.claudeignore" ]
  [ -f "$TMPD/CLAUDE.md" ]
  [ -d "$TMPD/memory/decisions" ]
  [ -d "$TMPD/memory/patterns" ]
}

@test "idempotent: re-runs do not change anything" {
  echo '{"name":"foo"}' > "$TMPD/package.json"
  bash "$SCRIPT" >/dev/null 2>&1
  HASH1=$(find "$TMPD" -type f -not -path "*/.git/*" | xargs md5sum | sort | md5sum)
  bash "$SCRIPT" >/dev/null 2>&1
  HASH2=$(find "$TMPD" -type f -not -path "*/.git/*" | xargs md5sum | sort | md5sum)
  [ "$HASH1" = "$HASH2" ]
}

@test "does NOT overwrite an existing memory/hot-context.md" {
  echo '{"name":"foo"}' > "$TMPD/package.json"
  mkdir -p "$TMPD/memory"
  echo "MY CUSTOM HOT CONTEXT" > "$TMPD/memory/hot-context.md"
  bash "$SCRIPT" >/dev/null 2>&1
  grep -q "MY CUSTOM HOT CONTEXT" "$TMPD/memory/hot-context.md"
}

@test "does NOT overwrite existing CLAUDE.md" {
  echo '{"name":"foo"}' > "$TMPD/package.json"
  echo "MY CUSTOM PROJECT CLAUDE.md" > "$TMPD/CLAUDE.md"
  bash "$SCRIPT" >/dev/null 2>&1
  grep -q "MY CUSTOM PROJECT CLAUDE.md" "$TMPD/CLAUDE.md"
}

@test "detects Node.js + TypeScript stack" {
  echo '{"name":"foo"}' > "$TMPD/package.json"
  echo '{}' > "$TMPD/tsconfig.json"
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Node.js"* ]]
  [[ "$output" == *"TypeScript"* ]]
}

@test "detects Python stack" {
  echo "[project]" > "$TMPD/pyproject.toml"
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Python"* ]]
}

@test "detects Rust stack" {
  echo "[package]" > "$TMPD/Cargo.toml"
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Rust"* ]]
}

@test "detects Go stack" {
  echo "module foo" > "$TMPD/go.mod"
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Go"* ]]
}

@test "uses package.json name when available" {
  echo '{"name":"acme-product"}' > "$TMPD/package.json"
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  if command -v jq >/dev/null 2>&1; then
    [[ "$output" == *"acme-product"* ]]
  fi
}

@test "reports zero changes on a fully onboarded project" {
  echo '{"name":"foo"}' > "$TMPD/package.json"
  bash "$SCRIPT" >/dev/null 2>&1
  run bash "$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"already onboarded"* ]]
}
