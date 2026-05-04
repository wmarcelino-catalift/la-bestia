#!/usr/bin/env bash
# evals/run.sh — emit an evals report you can compare against canonical.md.
# Headless invocation of `claude -p` is on the roadmap; for now this prints
# the prompts and the canonical for side-by-side review.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

TARGET="${1:-all}"
TS=$(date -u +'%Y-%m-%dT%H-%M-%SZ')
REPORT_DIR="evals/_reports"
mkdir -p "$REPORT_DIR"

run_one() {
  local agent="$1"
  local canon="evals/agents/$agent/canonical.md"
  local out="$REPORT_DIR/${agent}-${TS}.md"

  if [ ! -f "$canon" ]; then
    echo "  ⚠ no canonical for $agent (expected: $canon)" >&2
    return 1
  fi

  {
    echo "# Eval report: $agent"
    echo ""
    echo "**Generated:** $TS"
    echo "**Canonical:** $canon"
    echo ""
    echo "## How to use"
    echo ""
    echo "1. For each prompt below, paste into Claude Code (use the \`@$agent\` agent)."
    echo "2. Compare the actual output against the **Golden** block."
    echo "3. Note drift in this file under each prompt."
    echo ""
    echo "---"
    echo ""
    cat "$canon"
  } > "$out"

  echo "  ✓ $out"
}

if [ "$TARGET" = "all" ]; then
  for d in evals/agents/*/; do
    agent=$(basename "$d")
    run_one "$agent" || true
  done
else
  run_one "$TARGET"
fi

echo ""
echo "Reports written to $REPORT_DIR/"
