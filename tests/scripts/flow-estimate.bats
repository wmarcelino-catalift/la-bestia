#!/usr/bin/env bats
# Tests for bin/flow-estimate.sh — pre-/flow cost estimator.

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../../bin/flow-estimate.sh"
  [ -f "$SCRIPT" ] || skip "script not found: $SCRIPT"
}

@test "exits 2 with no input" {
  run bash "$SCRIPT"
  [ "$status" -eq 2 ]
  [[ "$output" == *"usage:"* ]]
}

@test "classifies short prompt as Small" {
  run bash "$SCRIPT" "fix typo in README"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Size:    Small"* ]]
}

@test "classifies build-feature prompt as Medium" {
  run bash "$SCRIPT" "construir un CLI llamado devlog con 6 subcommands para tracking diario"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Size:    Medium"* ]]
}

@test "classifies system-scale prompt as Large" {
  long="rewrite the entire authentication system to migrate from JWT to passkeys end-to-end across all microservices including the user-service, auth-service, gateway, and mobile clients with full test coverage migration plan rollback strategy and observability dashboards plus monitoring alerts and runbooks for production"
  run bash "$SCRIPT" "$long"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Size:    Large"* ]]
}

@test "detects Auth/Security touch from auth keywords" {
  run bash "$SCRIPT" "agregá login con OAuth y password reset"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Auth/Security"* ]]
}

@test "detects Data touch from schema keyword" {
  run bash "$SCRIPT" "modificá el schema de Postgres para agregar índice"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Data"* ]]
}

@test "detects CLI/UX touch from cli keyword" {
  run bash "$SCRIPT" "construir CLI con subcommand para listar entries"
  [ "$status" -eq 0 ]
  [[ "$output" == *"CLI/UX"* ]]
}

@test "detects multiple touches in compound prompt" {
  run bash "$SCRIPT" "construir CLI que lea de Postgres con auth y deploy a CI con docs"
  [ "$status" -eq 0 ]
  [[ "$output" == *"CLI/UX"* ]]
  [[ "$output" == *"Data"* ]]
  [[ "$output" == *"Auth/Security"* ]]
  [[ "$output" == *"DevOps"* ]]
  [[ "$output" == *"Docs"* ]]
}

@test "produces phase breakdown for Medium size" {
  run bash "$SCRIPT" "construir un CLI con 6 subcommands"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Phase 1"* ]]
  [[ "$output" == *"Phase 2"* ]]
  [[ "$output" == *"Phase 3"* ]]
  [[ "$output" == *"Phase 4"* ]]
  [[ "$output" == *"Total estimated"* ]]
}

@test "computes savings vs Claude solo" {
  run bash "$SCRIPT" "construir un CLI"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Vs Claude solo"* ]]
  [[ "$output" == *"savings"* ]]
}

@test "reads from stdin when arg is '-'" {
  run bash -c "echo 'construir un CLI con auth' | bash '$SCRIPT' -"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Auth/Security"* ]]
}

@test "Small skip indicator for Phase 1" {
  run bash "$SCRIPT" "fix typo"
  [ "$status" -eq 0 ]
  [[ "$output" == *"skipped — Small"* ]]
}
