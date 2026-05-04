#!/usr/bin/env bash
# verify.sh — health check for a v1.0 install (global or project).
# Returns 0 if all hard checks pass; non-zero count of failures otherwise.
set -u

# Detect mode: global (~/.claude) or project (./.claude)
if [ -n "${CLAUDE_PROJECT_DIR:-}" ]; then
  ROOT="$CLAUDE_PROJECT_DIR"
  CDIR="$ROOT/.claude"
  MODE="project"
else
  CDIR="$HOME/.claude"
  ROOT="$(dirname "$CDIR")"
  MODE="global"
fi

PASS=0
FAIL=0
WARN=0

check() {
  local label="$1" cond="$2"
  if eval "$cond"; then echo "  ✓ $label"; PASS=$((PASS+1)); else echo "  ✗ $label"; FAIL=$((FAIL+1)); fi
}
warn() {
  local label="$1" cond="$2"
  if eval "$cond"; then echo "  ✓ $label"; PASS=$((PASS+1)); else echo "  ⚠ $label (optional)"; WARN=$((WARN+1)); fi
}

echo "=== verify.sh — La Bestia v1.0 ($MODE mode, root: $CDIR) ==="
echo ""

echo "[OS deps]"
check "git installed"           "command -v git >/dev/null"
check "bash >= 4"               "[ \"\${BASH_VERSINFO[0]:-0}\" -ge 4 ] || [ \"\${BASH_VERSINFO[0]:-0}\" -ge 3 ]"
warn  "jq installed"            "command -v jq >/dev/null"
warn  "shellcheck (dev)"        "command -v shellcheck >/dev/null"
warn  "bats (dev)"              "command -v bats >/dev/null"
warn  "gh GitHub CLI"           "command -v gh >/dev/null"

echo ""
echo "[Structure: $CDIR]"
check "agents/ (>= 18)"         "[ \$(ls \"$CDIR/agents\"/*.md 2>/dev/null | wc -l) -ge 18 ]"
check "skills/ (>= 3)"          "[ \$(ls -d \"$CDIR/skills\"/*/ 2>/dev/null | wc -l) -ge 3 ]"
check "commands/ (>= 11)"       "[ \$(ls \"$CDIR/commands\"/*.md 2>/dev/null | wc -l) -ge 11 ]"
check "hooks/ (>= 6)"           "[ \$(ls \"$CDIR/hooks\"/*.sh 2>/dev/null | wc -l) -ge 6 ]"
check "scripts/ (>= 3)"         "[ \$(ls \"$CDIR/scripts\"/*.sh 2>/dev/null | wc -l) -ge 3 ]"
check "settings.json"           "[ -f \"$CDIR/settings.json\" ]"
check "logs/ dir"               "[ -d \"$CDIR/logs\" ] || mkdir -p \"$CDIR/logs\""

echo ""
echo "[Forbidden v0.x leftovers]"
check "no live-update.sh"       "[ ! -f \"$CDIR/scripts/live-update.sh\" ]"
check "no curate-hot.sh"        "[ ! -f \"$CDIR/scripts/curate-hot.sh\" ]"
check "no dashboard.sh"         "[ ! -f \"$CDIR/scripts/dashboard.sh\" ]"
check "no flow-diagram.sh"      "[ ! -f \"$CDIR/scripts/flow-diagram.sh\" ]"
check "no graphify skill"       "[ ! -d \"$CDIR/skills/graphify\" ]"
check "no vault dir"            "[ ! -d \"$CDIR/vault\" ]"
check "no OBSIDIAN_VAULT in settings" "! grep -q OBSIDIAN_VAULT \"$CDIR/settings.json\" 2>/dev/null"

if [ "$MODE" = "project" ]; then
  echo ""
  echo "[Project memory: $ROOT]"
  check "memory/hot-context.md" "[ -f \"$ROOT/memory/hot-context.md\" ]"
  check "memory/decisions/"     "[ -d \"$ROOT/memory/decisions\" ]"
  warn  "memory/patterns/"      "[ -d \"$ROOT/memory/patterns\" ]"
fi

echo ""
echo "[JSON syntax]"
if command -v jq >/dev/null; then
  check "settings.json valid"   "jq empty \"$CDIR/settings.json\" 2>/dev/null"
fi

echo ""
echo "[Hook smoke test — block-secrets]"
HOOK="$CDIR/hooks/block-secrets.sh"
if [ -f "$HOOK" ]; then
  RESULT=$(CLAUDE_TOOL_INPUT='{"file_path":"/tmp/test.ts","content":"AKIA0123456789ABCDEF"}' bash "$HOOK" 2>&1; echo "exit=$?")
  if echo "$RESULT" | grep -q "exit=2"; then
    echo "  ✓ block-secrets blocks AWS-like keys"; PASS=$((PASS+1))
  else
    echo "  ✗ block-secrets did not block (got: $RESULT)"; FAIL=$((FAIL+1))
  fi
else
  echo "  ✗ hook missing: $HOOK"; FAIL=$((FAIL+1))
fi

echo ""
echo "[Summary]"
echo "  pass: $PASS  fail: $FAIL  warn: $WARN"
if [ $FAIL -eq 0 ]; then
  echo "  → ✅ La Bestia v1.0 ready"
else
  echo "  → ❌ Fix failures above. Run: bash install.sh $MODE"
fi
exit $FAIL
