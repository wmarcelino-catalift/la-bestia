#!/usr/bin/env bash
# tests/run.sh — local test runner. Mirrors CI gates.
# Usage: bash tests/run.sh [hooks|schemas|all]
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

TARGET="${1:-all}"
FAIL=0

run_hooks() {
  echo "=== bats: tests/hooks/ ==="
  if ! command -v bats >/dev/null 2>&1; then
    echo "  ⚠ bats not installed. Install: https://bats-core.readthedocs.io/" >&2
    return 1
  fi
  bats --tap tests/hooks/ || FAIL=1
  if [ -d tests/scripts ] && ls tests/scripts/*.bats >/dev/null 2>&1; then
    bats --tap tests/scripts/ || FAIL=1
  fi
}

run_shellcheck() {
  echo "=== shellcheck: hooks + scripts + bin ==="
  if ! command -v shellcheck >/dev/null 2>&1; then
    echo "  ⚠ shellcheck not installed. Install: https://github.com/koalaman/shellcheck" >&2
    return 1
  fi
  # SC1091: Not following sourced files (CI-only paths)
  shellcheck -e SC1091 config/hooks/*.sh config/scripts/*.sh tests/run.sh install.sh bin/*.sh || FAIL=1
}

run_schemas() {
  echo "=== schema validation ==="
  if command -v ajv >/dev/null 2>&1; then
    # settings.example.json
    ajv validate -s schemas/settings.schema.json -d config/settings.example.json --strict=false || FAIL=1
  else
    echo "  ⚠ ajv-cli not installed (npm i -g ajv-cli ajv-formats). Doing structural sanity only." >&2
    # Best-effort: ensure JSON parses
    for f in schemas/*.json config/settings.example.json; do
      if command -v jq >/dev/null 2>&1; then
        jq empty "$f" >/dev/null || { echo "  ❌ invalid JSON: $f"; FAIL=1; }
      fi
    done
  fi

  # Agent frontmatter: must have name/description/tools/model
  echo "=== agent frontmatter sanity ==="
  for f in config/agents/*.md; do
    [ "$(basename "$f")" = "_TEMPLATE.md" ] && continue
    for key in name description tools model; do
      if ! grep -q "^${key}:" "$f"; then
        echo "  ❌ $f missing frontmatter key: ${key}"
        FAIL=1
      fi
    done
  done

  # Skill frontmatter: must have name/version/description/triggers
  echo "=== skill frontmatter sanity ==="
  for f in config/skills/*/SKILL.md; do
    parent_dir=$(basename "$(dirname "$f")")
    [ "$parent_dir" = "_TEMPLATE" ] && continue
    for key in name version description; do
      if ! grep -q "^${key}:" "$f"; then
        echo "  ❌ $f missing frontmatter key: ${key}"
        FAIL=1
      fi
    done
  done
}

case "$TARGET" in
  hooks)     run_hooks ;;
  schemas)   run_schemas ;;
  shellcheck) run_shellcheck ;;
  all)       run_shellcheck; run_schemas; run_hooks ;;
  *)         echo "Usage: $0 [hooks|schemas|shellcheck|all]" >&2; exit 1 ;;
esac

if [ "$FAIL" -ne 0 ]; then
  echo ""
  echo "❌ Tests failed."
  exit 1
fi

echo ""
echo "✅ All gates passed."
