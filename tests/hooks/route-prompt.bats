#!/usr/bin/env bats
# Tests for config/hooks/route-prompt.sh
# Verifies routing keyword → agent suggestion mapping.
# v4.1: extended to 16 Tier B canonical cases (1 per Intent Map row).

setup() {
  HOOK="$BATS_TEST_DIRNAME/../../config/hooks/route-prompt.sh"
  [ -f "$HOOK" ] || skip "hook not found: $HOOK"
}

# Helper: assert routing for a prompt
route_to() {
  local prompt="$1" expected="$2"
  run env CLAUDE_USER_PROMPT="$prompt" bash "$HOOK"
  [ "$status" -eq 0 ]
  [[ "$output" == *"$expected"* ]]
}

# ── Tier B canonical Intent Map cases ────────────────────────────────────────

@test "B1: 'arquitectura' → architect" {
  route_to "Cuál es la arquitectura ideal para el módulo de pagos?" "architect"
}

@test "B2: 'auth login' → security" {
  route_to "Revisá el flujo de auth y login" "security"
}

@test "B3: 'bug no funciona' → debugger" {
  route_to "bug que no funciona en producción" "debugger"
}

@test "B4: 'should I use X or Y' → strategist" {
  route_to "decisión: should I use Postgres or MongoDB?" "strategist"
}

@test "B5: 'review' → code-reviewer" {
  route_to "review mi PR" "code-reviewer"
}

@test "B6: 'safe / OWASP' → security" {
  route_to "este endpoint es safe contra OWASP top 10?" "security"
}

@test "B7: 'slow / performance' → optimizer" {
  route_to "el endpoint está slow, performance issue" "optimizer"
}

@test "B8: 'deploy / CI' → devops" {
  route_to "cómo deploy esto a Vercel con github actions" "devops"
}

@test "B9: 'schema / migration' → data-engineer" {
  route_to "agregá un índice a la query lenta y schema migration" "data-engineer"
}

@test "B10: 'docs / README' → tech-writer" {
  route_to "escribí el README con changelog" "tech-writer"
}

@test "B11: 'design system / UX' → designer" {
  route_to "diseñá el design system con WCAG accessibility" "designer"
}

@test "B12: 'flow / pipeline' → flow skill" {
  route_to "construir un flow pipeline para feature nueva" "flow"
}

@test "B13: 'TDD / test' → test-engineer" {
  route_to "implementá esto con TDD desde el primer test" "test-engineer"
}

@test "B14: 'commit / merge / ship' → ship-it skill" {
  route_to "voy a hacer commit y push" "ship-it"
}

@test "B15: 'pre-mortem / second opinion' → mentor" {
  route_to "necesito un pre-mortem de mi plan" "mentor"
}

@test "B16: 'idea / strategy / roadmap' → strategist" {
  route_to "hay una idea para una feature nueva, priorizar en roadmap" "strategist"
}

# ── Edge cases ───────────────────────────────────────────────────────────────

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

@test "case-insensitive matching (uppercase)" {
  route_to "ARQUITECTURA del sistema" "architect"
}

@test "Spanish + English mixed prompt" {
  route_to "Help me with the arquitectura please" "architect"
}
