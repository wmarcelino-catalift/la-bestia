#!/usr/bin/env bats
# Tests for config/hooks/route-prompt.sh
# Verifies routing keyword → agent suggestion mapping.

setup() {
  HOOK="$BATS_TEST_DIRNAME/../../config/hooks/route-prompt.sh"
  [ -f "$HOOK" ] || skip "hook not found: $HOOK"
}

@test "routes 'arquitectura' → architect" {
  run env CLAUDE_USER_PROMPT="¿Cuál es la arquitectura ideal para X?" bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"architect"* ]]
}

@test "routes 'auth login' → security-auditor" {
  run env CLAUDE_USER_PROMPT="Revisa el flujo de auth y login" bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"security-auditor"* ]]
}

@test "routes 'no funciona el bug' → debugger" {
  run env CLAUDE_USER_PROMPT="bug que no funciona" bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"debugger"* ]]
}

@test "routes 'ship it commit' → ship-it skill" {
  run env CLAUDE_USER_PROMPT="ship it, ya está listo el commit" bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"ship-it"* ]]
}

@test "no prompt → exit 0, no output" {
  unset CLAUDE_USER_PROMPT
  run bash "$HOOK"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "unmatched prompt → exit 0, no suggestion" {
  run env CLAUDE_USER_PROMPT="random unmatched text foo bar" bash "$HOOK"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}
