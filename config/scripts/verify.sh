#!/usr/bin/env bash
# Verify project-local Bestia setup.
set -u

PROJ="${CLAUDE_PROJECT_DIR:-$(pwd)}"
PASS=0
FAIL=0
WARN=0

check() {
  local label="$1" cond="$2"
  if eval "$cond"; then echo "  ✅ $label"; PASS=$((PASS+1)); else echo "  ❌ $label"; FAIL=$((FAIL+1)); fi
}
warn() {
  local label="$1" cond="$2"
  if eval "$cond"; then echo "  ✅ $label"; PASS=$((PASS+1)); else echo "  ⚠️  $label (opcional)"; WARN=$((WARN+1)); fi
}

echo "=== OS deps ==="
check "git instalado"     "command -v git >/dev/null"
warn  "jq instalado"      "command -v jq >/dev/null"
warn  "gh GitHub CLI"     "command -v gh >/dev/null"
warn  "npx (prettier)"    "command -v npx >/dev/null"

echo ""
echo "=== Project structure ($PROJ/.claude/) ==="
check "CLAUDE.md (root)"      "[ -f \"$PROJ/CLAUDE.md\" ]"
check "settings.json"         "[ -f \"$PROJ/.claude/settings.json\" ]"
check "agents/ (>=7)"         "[ \$(ls \"$PROJ/.claude/agents\"/*.md 2>/dev/null | wc -l) -ge 7 ]"
check "skills/ (>=3)"         "[ \$(ls -d \"$PROJ/.claude/skills\"/*/ 2>/dev/null | wc -l) -ge 3 ]"
check "commands/ (>=4)"       "[ \$(ls \"$PROJ/.claude/commands\"/*.md 2>/dev/null | wc -l) -ge 4 ]"
check "hooks/ (>=5)"          "[ \$(ls \"$PROJ/.claude/hooks\"/*.sh 2>/dev/null | wc -l) -ge 5 ]"
check "scripts/ (>=4)"        "[ \$(ls \"$PROJ/.claude/scripts\"/*.sh 2>/dev/null | wc -l) -ge 4 ]"
check "logs/ dir"             "[ -d \"$PROJ/.claude/logs\" ]"
check "agent-memory/ (6)"     "[ \$(ls -d \"$PROJ/.claude/agent-memory\"/*/ 2>/dev/null | wc -l) -ge 6 ]"
check "vault/ stub"           "[ -f \"$PROJ/.claude/vault/HOT.md\" ]"
check "memory/hot-context"    "[ -f \"$PROJ/memory/hot-context.md\" ]"
check ".claudeignore"         "[ -f \"$PROJ/.claudeignore\" ]"
check "devops agent"          "[ -f \"$PROJ/.claude/agents/devops.md\" ]"

echo ""
echo "=== JSON syntax ==="
if command -v jq >/dev/null; then
  check "settings.json valid" "jq empty \"$PROJ/.claude/settings.json\" 2>/dev/null"
fi

echo ""
echo "=== Hook smoke test ==="
RESULT=$(CLAUDE_TOOL_INPUT='{"file_path":"/tmp/test","content":"AKIAIOSFODNN7EXAMPLE"}' bash "$PROJ/.claude/hooks/block-secrets.sh" 2>&1; echo "exit=$?")
if echo "$RESULT" | grep -q "exit=2"; then
  echo "  ✅ block-secrets blocks AWS-like keys"; PASS=$((PASS+1))
else
  echo "  ❌ block-secrets did not block (got: $RESULT)"; FAIL=$((FAIL+1))
fi

echo ""
echo "=== Summary ==="
echo "  Pass: $PASS  Fail: $FAIL  Warn: $WARN"
[ $FAIL -eq 0 ] && echo "  → Bestia (project) ready 🐺" || echo "  → Fix failures above"
exit $FAIL
