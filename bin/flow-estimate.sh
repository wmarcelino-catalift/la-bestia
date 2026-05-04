#!/usr/bin/env bash
# bin/flow-estimate.sh — pre-/flow cost estimator.
# Classifies prompt size + touches (heuristic), emits estimated tokens + $.
#
# Usage:
#   bash bin/flow-estimate.sh "<prompt text>"
#   echo "<prompt>" | bash bin/flow-estimate.sh -
#
# Heuristic only — actual cost depends on agent verbosity + iterations.
# Prices: Opus $15/$75 per MTok, Sonnet $3/$15, Haiku $1/$5.

set -euo pipefail

PROMPT="${1:-}"
[ -z "$PROMPT" ] && {
  cat <<'USAGE' >&2
usage: bash bin/flow-estimate.sh "<prompt text>"
       echo "<prompt>" | bash bin/flow-estimate.sh -

env:
  FLOW_MODEL_OPUS_IN=15      Opus input $/MTok (default 15)
  FLOW_MODEL_OPUS_OUT=75     Opus output $/MTok (default 75)
  FLOW_MODEL_SONNET_IN=3     Sonnet input $/MTok (default 3)
  FLOW_MODEL_SONNET_OUT=15   Sonnet output $/MTok (default 15)
USAGE
  exit 2
}

[ "$PROMPT" = "-" ] && PROMPT=$(cat)

P=$(echo "$PROMPT" | tr '[:upper:]' '[:lower:]')
WORDS=$(echo "$PROMPT" | wc -w | tr -d ' ')

# ── Size heuristic ───────────────────────────────────────────────────────────
# Small:  prompt < 30 words, no "build/construir/implement"
# Medium: 30-150 words, mentions "build/feature/CLI/module"
# Large:  > 150 words OR mentions "system/platform/end-to-end"

SIZE="Small"
if [ "$WORDS" -gt 150 ]; then
  SIZE="Large"
elif [ "$WORDS" -gt 30 ]; then
  SIZE="Medium"
fi

# Override Small → Medium if prompt mentions build/feature work
if [ "$SIZE" = "Small" ] && echo "$P" | grep -qE 'construir|implement|build|crear cli|nuevo feature|feature nuevo'; then
  SIZE="Medium"
fi

# Override Medium → Large for system-scale work
if [ "$SIZE" = "Medium" ] && echo "$P" | grep -qE 'sistema|platform|microservice|end-to-end|migration|rewrite|architecture'; then
  SIZE="Large"
fi

# ── Touches detection (multi-select) ─────────────────────────────────────────
TOUCHES=()
echo "$P" | grep -qE 'auth|login|password|token|payment|pago|secret|owasp|pii' && TOUCHES+=("Auth/Security")
echo "$P" | grep -qE 'schema|migration|database|postgres|mysql|firestore|supabase|rls|index|query' && TOUCHES+=("Data")
echo "$P" | grep -qE 'cli|command line|terminal|--help|subcommand' && TOUCHES+=("CLI/UX")
echo "$P" | grep -qE 'ui|frontend|component|button|modal|screen|design system|wcag|a11y' && TOUCHES+=("UI/UX")
echo "$P" | grep -qE 'mobile|react native|expo|ios|android|flatlist' && TOUCHES+=("Mobile")
echo "$P" | grep -qE 'deploy|ci|cd|github actions|pipeline|docker|kubernetes|infra' && TOUCHES+=("DevOps")
echo "$P" | grep -qE 'docs|readme|changelog|documentation|tutorial|api docs' && TOUCHES+=("Docs")
echo "$P" | grep -qE 'api|endpoint|public api|rest|graphql' && TOUCHES+=("Public API")
[ ${#TOUCHES[@]} -eq 0 ] && TOUCHES+=("None detected")

TOUCHES_STR=$(IFS=', '; echo "${TOUCHES[*]}")

# ── Phase fan-out estimation ─────────────────────────────────────────────────
# Per-phase agent count + token budget per agent (input+output combined).
# Numbers are observed median from real /flow runs.

case "$SIZE" in
  Small)
    PHASE_AGENTS_1=0   # skip Discover for Small
    PHASE_AGENTS_2=1   # @architect only
    PHASE_AGENTS_3=2   # test-engineer + code-reviewer
    PHASE_AGENTS_4=2   # code-reviewer + tech-writer
    AVG_AGENT_TOKENS=4000
    ;;
  Medium)
    PHASE_AGENTS_1=3   # strategist + architect + mentor (or skip mentor)
    PHASE_AGENTS_2=3   # architect + 2 domain (data/designer/security/devops)
    PHASE_AGENTS_3=2   # test-engineer + code-reviewer
    PHASE_AGENTS_4=4   # code-reviewer + security + optimizer + tech-writer
    AVG_AGENT_TOKENS=6500
    ;;
  Large)
    PHASE_AGENTS_1=4   # strategist + architect + mentor + security/data
    PHASE_AGENTS_2=5   # architect + 4 domain
    PHASE_AGENTS_3=3   # test-engineer + code-reviewer + optimizer
    PHASE_AGENTS_4=5   # code-reviewer + security + optimizer + tech-writer + mentor
    AVG_AGENT_TOKENS=9000
    ;;
esac

# Add @security if Touches contains Auth/Security/Data
if printf '%s\n' "${TOUCHES[@]}" | grep -qE 'Auth/Security|Data|Public API'; then
  PHASE_AGENTS_1=$((PHASE_AGENTS_1 + 1))
  PHASE_AGENTS_2=$((PHASE_AGENTS_2 + 1))
fi

# ── Cost calculation (Opus for Discover/Define/parts of Develop, Sonnet for Deliver) ──
OPUS_IN="${FLOW_MODEL_OPUS_IN:-15}"
OPUS_OUT="${FLOW_MODEL_OPUS_OUT:-75}"
SONNET_IN="${FLOW_MODEL_SONNET_IN:-3}"
SONNET_OUT="${FLOW_MODEL_SONNET_OUT:-15}"

# Assume 70% input / 30% output split per agent
agent_cost() {
  local model="$1" agents="$2" tokens="$3"
  local total_tok=$((agents * tokens))
  local in_tok=$((total_tok * 70 / 100))
  local out_tok=$((total_tok * 30 / 100))
  local in_price out_price cost
  case "$model" in
    opus)   in_price="$OPUS_IN";   out_price="$OPUS_OUT" ;;
    sonnet) in_price="$SONNET_IN"; out_price="$SONNET_OUT" ;;
  esac
  # Cost in cents (avoid floating point); divide later.
  cost=$(( (in_tok * in_price + out_tok * out_price) / 1000 ))
  echo "$total_tok $cost"
}

read -r P1_TOK P1_CENTS <<< "$(agent_cost opus   "$PHASE_AGENTS_1" "$AVG_AGENT_TOKENS")"
read -r P2_TOK P2_CENTS <<< "$(agent_cost opus   "$PHASE_AGENTS_2" "$AVG_AGENT_TOKENS")"
read -r P3_TOK P3_CENTS <<< "$(agent_cost sonnet "$PHASE_AGENTS_3" "$AVG_AGENT_TOKENS")"
read -r P4_TOK P4_CENTS <<< "$(agent_cost sonnet "$PHASE_AGENTS_4" "$AVG_AGENT_TOKENS")"

TOTAL_TOK=$((P1_TOK + P2_TOK + P3_TOK + P4_TOK))
TOTAL_CENTS=$((P1_CENTS + P2_CENTS + P3_CENTS + P4_CENTS))

# Vs Claude solo (no agents) — assume 3.5x token spend, all Opus
SOLO_TOK=$((TOTAL_TOK * 7 / 2))
SOLO_IN=$((SOLO_TOK * 70 / 100))
SOLO_OUT=$((SOLO_TOK * 30 / 100))
SOLO_CENTS=$(( (SOLO_IN * OPUS_IN + SOLO_OUT * OPUS_OUT) / 1000 ))

SAVINGS_PCT=$(( (SOLO_CENTS - TOTAL_CENTS) * 100 / SOLO_CENTS ))

# ── Format helpers ───────────────────────────────────────────────────────────
fmt_tokens() {
  local n=$1
  if [ "$n" -ge 1000 ]; then printf '%.1fk' "$(echo "$n / 1000" | awk '{printf "%.1f", $1/1000}' <<<"$n")"
  else echo "$n"
  fi
}

# Cents → $X.XX
fmt_dollars() {
  local cents=$1
  printf '$%d.%02d' "$((cents / 100))" "$((cents % 100))"
}

# ── Output ───────────────────────────────────────────────────────────────────
cat <<EOF
Estimate for prompt ($WORDS words):

  Size:    $SIZE
  Touches: $TOUCHES_STR

Phase fan-out and cost:

  Phase                                  Agents  Tokens   Cost
  ─────────────────────────────────────────────────────────────
EOF

p1_skipped=""
[ "$PHASE_AGENTS_1" -eq 0 ] && p1_skipped="(skipped — Small)"

printf "  Phase 1 — Discover (Opus parallel)     %s  %s  %s %s\n" \
  "$PHASE_AGENTS_1" "$(fmt_tokens "$P1_TOK")" "$(fmt_dollars "$P1_CENTS")" "$p1_skipped"

printf "  Phase 2 — Define (Opus parallel)       %s  %s  %s\n" \
  "$PHASE_AGENTS_2" "$(fmt_tokens "$P2_TOK")" "$(fmt_dollars "$P2_CENTS")"

printf "  Phase 3 — Develop (Sonnet sequential)  %s  %s  %s\n" \
  "$PHASE_AGENTS_3" "$(fmt_tokens "$P3_TOK")" "$(fmt_dollars "$P3_CENTS")"

printf "  Phase 4 — Deliver (Sonnet parallel)    %s  %s  %s\n" \
  "$PHASE_AGENTS_4" "$(fmt_tokens "$P4_TOK")" "$(fmt_dollars "$P4_CENTS")"

cat <<EOF
  ─────────────────────────────────────────────────────────────
  Total estimated:                              $(fmt_tokens "$TOTAL_TOK")  $(fmt_dollars "$TOTAL_CENTS")

Comparison:
  Vs Claude solo (no agents):                   $(fmt_tokens "$SOLO_TOK")  $(fmt_dollars "$SOLO_CENTS")
  Estimated savings:                            ${SAVINGS_PCT}%

Heuristic — actual cost varies ±30% by agent verbosity, iterations,
and operator decisions at HALTs. Use as decision aid, not a contract.
EOF
