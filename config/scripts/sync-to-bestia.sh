#!/usr/bin/env bash
# sync-to-bestia.sh
# Syncs .claude/ config files → la-bestia repo (config/ structure).
# Maps: .claude/{agents,commands,hooks,scripts,skills} → config/{agents,commands,hooks,scripts,skills}
# Excludes: agent-memory/, vault/, logs/, settings.json (project-specific).

set -euo pipefail

PROJ="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
CLAUDE_DIR="$PROJ/.claude"
REMOTE_URL="https://github.com/wmarcelino-catalift/la-bestia.git"
TMP_DIR=$(mktemp -d)
PUSH="${1:-ask}"   # "push" to auto-push, "dry" for dry run, "ask" (default)

cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

echo "=== sync-to-bestia ==="
echo "Source: $CLAUDE_DIR"
echo "Target: $REMOTE_URL"
echo ""

# Clone la-bestia (shallow)
echo "→ Cloning la-bestia..."
git clone --depth=1 "$REMOTE_URL" "$TMP_DIR/la-bestia" -q
cd "$TMP_DIR/la-bestia"

# Create branch for the sync
BRANCH="sync/catalift-$(date +%Y%m%d-%H%M%S)"
git checkout -b "$BRANCH" -q

# Sync files: .claude/X → config/X
DIRS=(agents commands hooks scripts)
for dir in "${DIRS[@]}"; do
  SRC="$CLAUDE_DIR/$dir"
  DST="config/$dir"
  if [ -d "$SRC" ]; then
    mkdir -p "$DST"
    cp "$SRC"/* "$DST/" 2>/dev/null || true
    echo "  ✓ $dir"
  fi
done

# Sync skills (nested: skills/NAME/SKILL.md)
if [ -d "$CLAUDE_DIR/skills" ]; then
  for skill_dir in "$CLAUDE_DIR/skills"/*/; do
    skill_name=$(basename "$skill_dir")
    skill_file="$skill_dir/SKILL.md"
    if [ -f "$skill_file" ]; then
      mkdir -p "config/skills/$skill_name"
      cp "$skill_file" "config/skills/$skill_name/SKILL.md"
      echo "  ✓ skills/$skill_name"
    fi
  done
fi

# Check if there are actual changes
if git diff --quiet && git diff --cached --quiet && [ -z "$(git ls-files --others --exclude-standard)" ]; then
  echo ""
  echo "✅ La-bestia already up to date. Nothing to sync."
  exit 0
fi

# Show summary of changes
echo ""
echo "=== Changes to push ==="
git add -A
git diff --cached --stat
echo ""

if [ "$PUSH" = "dry" ]; then
  echo "Dry run — not pushing."
  exit 0
fi

# Commit
COMMIT_MSG="sync(catalift): agent overhaul + new files from catalift-app

$(git diff --cached --stat | tail -1)"

git commit -m "$COMMIT_MSG" -q
echo "→ Committed: $COMMIT_MSG"
echo ""

if [ "$PUSH" = "push" ]; then
  echo "→ Pushing $BRANCH to la-bestia..."
  git push origin "$BRANCH" -q
  echo ""
  echo "✅ Done! Open PR: $REMOTE_URL/compare/$BRANCH"
else
  echo "Run with 'push' arg to push: bash .claude/scripts/sync-to-bestia.sh push"
fi
