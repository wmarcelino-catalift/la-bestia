#!/usr/bin/env bash
# architecture-gate.sh — pre-commit / pre-merge hook that flags structural changes
# requiring an ADR. Inspired by claude-octopus's discipline-gates.
#
# Hook event: PreToolUse Bash with matcher pattern '^git commit'
# (best-effort regex on the bash command).
#
# Detects:
# - Cross-module changes (>3 directories touched in staged diff)
# - New top-level directories
# - Renames/deletes of >5 files
# - Schema/migration changes
# - Public API surface changes (exports, types, route definitions)
#
# When triggered: emits a 🟡 warning to stderr but DOES NOT block.
# This is advisory — operator decides. Set ARCHITECTURE_GATE_HARD=1 to make it
# block (exit 2) instead of warn.

set -u

INPUT="${CLAUDE_TOOL_INPUT:-}"
HARD="${ARCHITECTURE_GATE_HARD:-0}"

# Only react to `git commit` commands
if command -v jq >/dev/null 2>&1; then
  CMD=$(echo "$INPUT" | jq -r '.command // ""' 2>/dev/null)
else
  CMD="$INPUT"
fi
echo "$CMD" | grep -qE '^[[:space:]]*git commit' || exit 0

# Get staged diff stats
if ! git rev-parse --git-dir >/dev/null 2>&1; then
  exit 0
fi

STAGED_FILES=$(git diff --cached --name-only 2>/dev/null)
[ -z "$STAGED_FILES" ] && exit 0

# ── Heuristic 1: cross-module change ──
# Count unique parent directories. dirname-style: "a/b/c.ts" → "a/b".
# Files at root contribute "." Many distinct parent dirs ⇒ wide change.
DIRS=$(echo "$STAGED_FILES" | awk -F/ '{
  if (NF == 1) print ".";
  else { OFS="/"; $NF=""; sub("/$",""); print }
}' | sort -u | wc -l | tr -d ' ')

# ── Heuristic 2: new top-level directories ──
NEW_TOP_DIRS=$(echo "$STAGED_FILES" | awk -F/ 'NF>1 {print $1}' | sort -u | while read -r d; do
  [ -d "$d" ] || continue
  # Check if directory existed in HEAD
  git ls-tree HEAD --name-only -- "$d" 2>/dev/null | grep -q . || echo "$d"
done | wc -l | tr -d ' ')

# ── Heuristic 3: many renames/deletes ──
# NOTE: `grep -c PATTERN || echo 0` yields "0\n0" on no-match (grep prints "0",
# then `|| echo 0` appends another). Use `{ ... || true; }` and tolerate empty.
RENAMES=$(git diff --cached --name-status 2>/dev/null | grep -cE '^[RD]' 2>/dev/null || true)
RENAMES=${RENAMES:-0}

# ── Heuristic 4: schema / migration changes ──
SCHEMA_HITS=$(echo "$STAGED_FILES" | grep -cE 'migration|schema|\.sql$|prisma\/|\.proto$|openapi\.(yml|yaml|json)' 2>/dev/null || true)
SCHEMA_HITS=${SCHEMA_HITS:-0}

# ── Heuristic 5: public API surface ──
# (very rough — counts changes in files matching common public-API names)
API_HITS=$(echo "$STAGED_FILES" | grep -cE 'api\/|routes\/|pages\/api|server\/|controllers\/|handlers\/|public\/types' 2>/dev/null || true)
API_HITS=${API_HITS:-0}

# ── Decide ──
WARN_REASONS=()
[ "$DIRS" -ge 4 ]          && WARN_REASONS+=("touches $DIRS directories")
[ "$NEW_TOP_DIRS" -ge 1 ]  && WARN_REASONS+=("introduces $NEW_TOP_DIRS new top-level dir(s)")
[ "$RENAMES" -ge 5 ]       && WARN_REASONS+=("$RENAMES files renamed/deleted")
[ "$SCHEMA_HITS" -ge 1 ]   && WARN_REASONS+=("schema/migration touched ($SCHEMA_HITS file(s))")
[ "$API_HITS" -ge 3 ]      && WARN_REASONS+=("public API surface touched ($API_HITS file(s))")

[ ${#WARN_REASONS[@]} -eq 0 ] && exit 0

# ── Check if an ADR was added ──
ADR_ADDED=$(echo "$STAGED_FILES" | grep -cE 'memory/decisions/.*\.md$' 2>/dev/null || true)
ADR_ADDED=${ADR_ADDED:-0}
if [ "$ADR_ADDED" -ge 1 ]; then
  # Operator added an ADR — gate passes silently.
  exit 0
fi

# ── Emit warning (or block if HARD) ──
{
  echo ""
  echo "🟡 [architecture-gate] structural change detected:"
  for reason in "${WARN_REASONS[@]}"; do
    echo "   · $reason"
  done
  echo ""
  echo "   No ADR found in this commit's staged files."
  echo ""
  echo "   Consider:"
  echo "     1. cp memory/templates/adr.md memory/decisions/<NNNN>-<slug>.md"
  echo "     2. Document the one-way door, then \`git add\` it before commit."
  echo ""
  if [ "$HARD" = "1" ]; then
    echo "🔴 BLOCKED (ARCHITECTURE_GATE_HARD=1). Add ADR or unset this env var."
  else
    echo "   This is advisory. Set ARCHITECTURE_GATE_HARD=1 to block instead."
  fi
} >&2

if [ "$HARD" = "1" ]; then
  exit 2
fi
exit 0
