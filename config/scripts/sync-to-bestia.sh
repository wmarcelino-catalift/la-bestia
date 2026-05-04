#!/usr/bin/env bash
# sync-to-bestia.sh — push local ~/.claude/ changes back into the la-bestia repo as a PR.
# Usage:
#   bash sync-to-bestia.sh              # interactive (asks before pushing)
#   bash sync-to-bestia.sh push         # push without asking
#   bash sync-to-bestia.sh dry          # show what would change, do not push
#
# Maps:
#   ~/.claude/{agents,commands,hooks,scripts,skills} → config/{...}
#   ~/.claude/agent-memory/<name>/MEMORY.md is NOT synced (operator-private).

set -euo pipefail

CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
REMOTE_URL="${LA_BESTIA_REMOTE:-https://github.com/wmarcelino-catalift/la-bestia.git}"
PUSH_MODE="${1:-ask}"

TMP_DIR=$(mktemp -d)
cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

echo "=== sync-to-bestia ==="
echo "  source: $CLAUDE_DIR"
echo "  remote: $REMOTE_URL"
echo "  mode:   $PUSH_MODE"
echo ""

if [ ! -d "$CLAUDE_DIR/agents" ]; then
  echo "✗ $CLAUDE_DIR/agents missing — is la-bestia installed globally?" >&2
  exit 1
fi

echo "→ cloning la-bestia main..."
git clone --depth=1 "$REMOTE_URL" "$TMP_DIR/la-bestia" -q
cd "$TMP_DIR/la-bestia"

BRANCH="sync/$(date +%Y%m%d-%H%M%S)"
git checkout -b "$BRANCH" -q

echo "→ syncing config/ from live..."
for dir in agents commands hooks scripts; do
  SRC="$CLAUDE_DIR/$dir"
  DST="config/$dir"
  if [ -d "$SRC" ]; then
    mkdir -p "$DST"
    # Copy only files; do not delete repo-only files (templates etc.)
    cp "$SRC"/*.md "$DST/" 2>/dev/null || true
    cp "$SRC"/*.sh "$DST/" 2>/dev/null || true
    echo "  ✓ $dir"
  fi
done

# Skills (per-folder)
for skill_dir in "$CLAUDE_DIR/skills"/*/; do
  skill_name=$(basename "$skill_dir")
  [ "$skill_name" = "_TEMPLATE" ] && continue
  if [ -f "$skill_dir/SKILL.md" ]; then
    mkdir -p "config/skills/$skill_name"
    cp "$skill_dir/SKILL.md" "config/skills/$skill_name/SKILL.md"
  fi
done
echo "  ✓ skills"

# Anything to push?
if git diff --quiet && git diff --cached --quiet && [ -z "$(git ls-files --others --exclude-standard)" ]; then
  echo ""
  echo "✅ no changes — la-bestia already in sync with live"
  exit 0
fi

echo ""
echo "=== changes to push ==="
git add -A
git diff --cached --stat
echo ""

if [ "$PUSH_MODE" = "dry" ]; then
  echo "(dry mode — not pushing)"
  exit 0
fi

if [ "$PUSH_MODE" = "ask" ]; then
  read -rp "Create branch '$BRANCH' and open a PR? [y/N] " ans
  case "$ans" in y|Y|yes) ;; *) echo "aborted."; exit 0 ;; esac
fi

git commit -m "sync: live → repo $(date +%Y-%m-%d)

$(git diff --cached --stat | tail -1)" -q
git push origin "$BRANCH" -q

echo ""
echo "✅ pushed $BRANCH"
echo "→ open PR: ${REMOTE_URL%.git}/compare/$BRANCH"
