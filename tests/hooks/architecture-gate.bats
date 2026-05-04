#!/usr/bin/env bats
# Tests for config/hooks/architecture-gate.sh

setup() {
  HOOK="$BATS_TEST_DIRNAME/../../config/hooks/architecture-gate.sh"
  [ -f "$HOOK" ] || skip "hook not found: $HOOK"
  TMPD="$(mktemp -d)"
  cd "$TMPD"
  git init -q -b main
  git config user.email "test@example.com"
  git config user.name "Test"
  echo "initial" > README.md
  git add README.md
  git commit -q -m "initial"
}

teardown() {
  [ -n "${TMPD:-}" ] && rm -rf "$TMPD"
}

@test "non-commit command → silent exit 0" {
  CLAUDE_TOOL_INPUT='{"command":"ls"}'
  run env CLAUDE_TOOL_INPUT="$CLAUDE_TOOL_INPUT" bash "$HOOK"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "single-file commit in same directory → silent" {
  echo "x" > foo.txt
  git add foo.txt
  CLAUDE_TOOL_INPUT='{"command":"git commit -m foo"}'
  run env CLAUDE_TOOL_INPUT="$CLAUDE_TOOL_INPUT" bash "$HOOK"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "commit touching 4+ directories → emits warning" {
  mkdir -p src/a src/b src/c src/d
  echo x > src/a/x.ts
  echo x > src/b/y.ts
  echo x > src/c/z.ts
  echo x > src/d/w.ts
  git add -A
  CLAUDE_TOOL_INPUT='{"command":"git commit -m sweeping"}'
  run env CLAUDE_TOOL_INPUT="$CLAUDE_TOOL_INPUT" bash "$HOOK"
  [ "$status" -eq 0 ]   # advisory by default, doesn't block
  [[ "$output" == *"architecture-gate"* ]]
  [[ "$output" == *"directories"* ]]
}

@test "commit with new top-level dir → emits warning" {
  mkdir -p new-domain/sub
  echo x > new-domain/sub/file.ts
  git add -A
  CLAUDE_TOOL_INPUT='{"command":"git commit -m new-domain"}'
  run env CLAUDE_TOOL_INPUT="$CLAUDE_TOOL_INPUT" bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"architecture-gate"* ]]
}

@test "commit with schema file → emits warning" {
  mkdir -p prisma
  echo "model x {}" > prisma/schema.prisma
  git add -A
  CLAUDE_TOOL_INPUT='{"command":"git commit -m schema"}'
  run env CLAUDE_TOOL_INPUT="$CLAUDE_TOOL_INPUT" bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"architecture-gate"* ]]
}

@test "commit that includes an ADR → silent (gate satisfied)" {
  mkdir -p memory/decisions
  echo "# ADR-0001" > memory/decisions/0001-x.md
  mkdir -p src/a src/b src/c src/d
  echo x > src/a/x.ts
  echo x > src/b/y.ts
  echo x > src/c/z.ts
  echo x > src/d/w.ts
  git add -A
  CLAUDE_TOOL_INPUT='{"command":"git commit -m with-adr"}'
  run env CLAUDE_TOOL_INPUT="$CLAUDE_TOOL_INPUT" bash "$HOOK"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "ARCHITECTURE_GATE_HARD=1 blocks commit (exit 2)" {
  mkdir -p src/a src/b src/c src/d
  echo x > src/a/x.ts
  echo x > src/b/y.ts
  echo x > src/c/z.ts
  echo x > src/d/w.ts
  git add -A
  CLAUDE_TOOL_INPUT='{"command":"git commit -m sweep"}'
  run env CLAUDE_TOOL_INPUT="$CLAUDE_TOOL_INPUT" ARCHITECTURE_GATE_HARD=1 bash "$HOOK"
  [ "$status" -eq 2 ]
  [[ "$output" == *"BLOCKED"* ]]
}
