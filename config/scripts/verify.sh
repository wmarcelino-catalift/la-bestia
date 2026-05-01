#!/usr/bin/env bash
# Verify the Bestia setup: deps, files, hooks, structure.
# Run after install or after pulling updates.

set -u

PASS=0
FAIL=0
WARN=0

check() {
  local label="$1"
  local cond="$2"
  if eval "$cond"; then
    echo "  ✅ $label"
    PASS=$((PASS+1))
  else
    echo "  ❌ $label"
    FAIL=$((FAIL+1))
  fi
}

warn() {
  local label="$1"
  local cond="$2"
  if eval "$cond"; then
    echo "  ✅ $label"
    PASS=$((PASS+1))
  else
    echo "  ⚠️  $label (opcional pero recomendado)"
    WARN=$((WARN+1))
  fi
}

echo "=== OS dependencies ==="
check "jq instalado"        "command -v jq >/dev/null"
check "git instalado"       "command -v git >/dev/null"
warn  "ccusage instalado"   "command -v ccusage >/dev/null"
warn  "gh (GitHub CLI)"     "command -v gh >/dev/null"
warn  "prettier (npx)"      "command -v npx >/dev/null"
warn  "ruff (Python fmt)"   "command -v ruff >/dev/null"

echo ""
echo "=== Global structure (~/.claude/) ==="
check "CLAUDE.md"           "[ -f ~/.claude/CLAUDE.md ]"
check "settings.json"       "[ -f ~/.claude/settings.json ]"
check "agents/ (6 files)"   "[ \$(ls ~/.claude/agents/*.md 2>/dev/null | wc -l) -ge 6 ]"
check "skills/ (3 dirs)"    "[ \$(ls -d ~/.claude/skills/*/ 2>/dev/null | wc -l) -ge 3 ]"
check "commands/ (4 files)" "[ \$(ls ~/.claude/commands/*.md 2>/dev/null | wc -l) -ge 4 ]"
check "hooks/ (5 .sh)"      "[ \$(ls ~/.claude/hooks/*.sh 2>/dev/null | wc -l) -ge 5 ]"
check "hooks executable"    "[ -x ~/.claude/hooks/block-secrets.sh ]"
check "scripts/statusline"  "[ -x ~/.claude/scripts/statusline.sh ]"
check "scripts/flow-diagram" "[ -x ~/.claude/scripts/flow-diagram.sh ]"
check "logs/ dir"           "[ -d ~/.claude/logs ]"
check "agent-memory/ dir"   "[ -d ~/.claude/agent-memory ]"

echo ""
echo "=== Vault Obsidian (~/Obsidian/claude-brain/) ==="
check "vault exists"        "[ -d ~/Obsidian/claude-brain ]"
check "permanent/patterns"  "[ -d ~/Obsidian/claude-brain/permanent/patterns ]"
check "permanent/decisions" "[ -d ~/Obsidian/claude-brain/permanent/decisions ]"
check "permanent/gotchas"   "[ -d ~/Obsidian/claude-brain/permanent/gotchas ]"
check "projects/"           "[ -d ~/Obsidian/claude-brain/projects ]"
check "inbox/"              "[ -d ~/Obsidian/claude-brain/inbox ]"

echo ""
echo "=== JSON syntax ==="
if command -v jq >/dev/null; then
  check "settings.json valid JSON" "jq empty ~/.claude/settings.json 2>/dev/null"
fi

echo ""
echo "=== Hook smoke test ==="
# block-secrets.sh should refuse a fake secret
RESULT=$(CLAUDE_TOOL_INPUT='{"file_path":"/tmp/test","content":"AKIAIOSFODNN7EXAMPLE"}' bash ~/.claude/hooks/block-secrets.sh 2>&1; echo "exit=$?")
if echo "$RESULT" | grep -q "exit=2"; then
  echo "  ✅ block-secrets blocks AWS-like keys"
  PASS=$((PASS+1))
else
  echo "  ❌ block-secrets did not block (got: $RESULT)"
  FAIL=$((FAIL+1))
fi

echo ""
echo "=== Summary ==="
echo "  Pass: $PASS  Fail: $FAIL  Warn: $WARN"
[ $FAIL -eq 0 ] && echo "  → Bestia ready 🐺" || echo "  → Fix failures above"
exit $FAIL
