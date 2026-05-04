#!/usr/bin/env bats
# Tests for config/hooks/cwd-changed.sh

setup() {
  HOOK="$BATS_TEST_DIRNAME/../../config/hooks/cwd-changed.sh"
  [ -f "$HOOK" ] || skip "hook not found: $HOOK"
  TMPD="$(mktemp -d)"
}

teardown() {
  [ -n "${TMPD:-}" ] && rm -rf "$TMPD"
}

@test "no input → silent exit 0" {
  unset CLAUDE_TOOL_INPUT
  run bash "$HOOK"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "non-cd command → silent exit 0" {
  CLAUDE_TOOL_INPUT='{"command":"ls -la"}'
  run env CLAUDE_TOOL_INPUT="$CLAUDE_TOOL_INPUT" bash "$HOOK"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "cd into non-existent path → silent exit 0" {
  CLAUDE_TOOL_INPUT='{"command":"cd /tmp/does-not-exist-12345"}'
  run env CLAUDE_TOOL_INPUT="$CLAUDE_TOOL_INPUT" bash "$HOOK"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "cd into a project with manifest but no memory → suggests onboard-project" {
  mkdir -p "$TMPD/new-project"
  echo '{"name":"foo"}' > "$TMPD/new-project/package.json"
  CLAUDE_TOOL_INPUT="{\"command\":\"cd $TMPD/new-project\"}"
  run env CLAUDE_PROJECT_DIR="$TMPD" CLAUDE_TOOL_INPUT="$CLAUDE_TOOL_INPUT" bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"onboard-project"* ]]
}

@test "cd into project that already has memory/ → silent" {
  mkdir -p "$TMPD/onboarded/memory"
  echo "x" > "$TMPD/onboarded/memory/hot-context.md"
  echo '{"name":"foo"}' > "$TMPD/onboarded/package.json"
  CLAUDE_TOOL_INPUT="{\"command\":\"cd $TMPD/onboarded\"}"
  run env CLAUDE_PROJECT_DIR="$TMPD" CLAUDE_TOOL_INPUT="$CLAUDE_TOOL_INPUT" bash "$HOOK"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "cd into a directory without manifest → silent" {
  mkdir -p "$TMPD/random-folder"
  CLAUDE_TOOL_INPUT="{\"command\":\"cd $TMPD/random-folder\"}"
  run env CLAUDE_PROJECT_DIR="$TMPD" CLAUDE_TOOL_INPUT="$CLAUDE_TOOL_INPUT" bash "$HOOK"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}
