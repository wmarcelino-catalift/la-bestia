#!/usr/bin/env bash
# La Bestia v1.0 — install.sh
# Idempotent. Safe to re-run. Backs up existing config before overwriting.
#
# Usage:
#   bash install.sh                       # interactive (asks global vs project)
#   bash install.sh global                # install to ~/.claude/
#   bash install.sh project [path]        # install to <path>/.claude/ (default: ./.claude)
#   bash install.sh --check               # verify-only mode (no writes)
#
# Does NOT register any MCP servers. See mcp/README.md for opt-in templates.

set -euo pipefail

VERSION="1.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# ── arg parsing ──────────────────────────────────────────────────────────────
MODE=""
PROJ_PATH=""
CHECK_ONLY=0

if [ $# -eq 0 ]; then
  echo "=== La Bestia v$VERSION installer ==="
  echo ""
  echo "Where do you want to install?"
  echo "  1) global  → ~/.claude/      (one-time, all projects)"
  echo "  2) project → ./.claude/      (per-repo)"
  echo "  3) check   → verify only, no changes"
  read -rp "[1/2/3]: " choice
  case "$choice" in
    1) MODE="global" ;;
    2) MODE="project"; PROJ_PATH="${PWD}/.claude" ;;
    3) CHECK_ONLY=1; MODE="global" ;;
    *) echo "aborted." >&2; exit 1 ;;
  esac
else
  case "${1:-}" in
    global)   MODE="global" ;;
    project)  MODE="project"; PROJ_PATH="${2:-./.claude}"; PROJ_PATH="$(cd "$(dirname "$PROJ_PATH")" && pwd)/$(basename "$PROJ_PATH")" ;;
    --check)  CHECK_ONLY=1; MODE="global" ;;
    -h|--help)
      sed -n '2,15p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
fi

# ── target dir ───────────────────────────────────────────────────────────────
if [ "$MODE" = "global" ]; then
  TARGET="$HOME/.claude"
else
  TARGET="$PROJ_PATH"
fi
echo "→ target: $TARGET"

# ── check-only mode ──────────────────────────────────────────────────────────
if [ "$CHECK_ONLY" -eq 1 ]; then
  if [ -f "$TARGET/scripts/verify.sh" ]; then
    bash "$TARGET/scripts/verify.sh"
    exit $?
  else
    echo "✗ verify.sh not found at $TARGET — install first."
    exit 1
  fi
fi

# ── deps preflight ───────────────────────────────────────────────────────────
need_cmd() { command -v "$1" >/dev/null 2>&1 || { echo "✗ missing: $1 (install it and re-run)" >&2; return 1; }; }

echo "→ preflight..."
need_cmd git || exit 1
need_cmd bash || exit 1
command -v jq >/dev/null 2>&1 || echo "  ⚠ jq not found — hooks will degrade gracefully but you'll get less detail. Install: brew install jq | apt install jq"

# ── backup ───────────────────────────────────────────────────────────────────
if [ -d "$TARGET" ] && [ -n "$(ls -A "$TARGET" 2>/dev/null)" ]; then
  BACKUP="${TARGET}/_backup_$(date +%Y%m%d_%H%M%S)"
  echo "→ backing up existing config to $BACKUP"
  mkdir -p "$BACKUP"
  for d in agents skills commands hooks scripts; do
    [ -d "$TARGET/$d" ] && cp -r "$TARGET/$d" "$BACKUP/" 2>/dev/null || true
  done
  [ -f "$TARGET/settings.json" ] && cp "$TARGET/settings.json" "$BACKUP/" 2>/dev/null || true
  [ -f "$TARGET/CLAUDE.md" ] && cp "$TARGET/CLAUDE.md" "$BACKUP/" 2>/dev/null || true
fi

# ── directories ──────────────────────────────────────────────────────────────
mkdir -p \
  "$TARGET/agents" \
  "$TARGET/skills" \
  "$TARGET/commands" \
  "$TARGET/hooks" \
  "$TARGET/scripts" \
  "$TARGET/logs/sessions" \
  "$TARGET/agent-memory"

# ── copy components ──────────────────────────────────────────────────────────
echo "→ installing agents..."
cp config/agents/*.md "$TARGET/agents/"
# Strip the template (not an agent)
rm -f "$TARGET/agents/_TEMPLATE.md"

echo "→ installing skills..."
for skill_dir in config/skills/*/; do
  skill_name=$(basename "$skill_dir")
  [ "$skill_name" = "_TEMPLATE" ] && continue
  mkdir -p "$TARGET/skills/$skill_name"
  cp -r "$skill_dir"* "$TARGET/skills/$skill_name/" 2>/dev/null || true
done

echo "→ installing commands..."
cp config/commands/*.md "$TARGET/commands/"
rm -f "$TARGET/commands/_TEMPLATE.md"

echo "→ installing hooks..."
cp config/hooks/*.sh "$TARGET/hooks/"
chmod +x "$TARGET/hooks/"*.sh

echo "→ installing scripts..."
cp config/scripts/*.sh "$TARGET/scripts/"
chmod +x "$TARGET/scripts/"*.sh

# ── settings.json ────────────────────────────────────────────────────────────
if [ ! -f "$TARGET/settings.json" ]; then
  echo "→ installing settings.json..."
  cp config/settings.example.json "$TARGET/settings.json"
else
  echo "  ⚠ settings.json already exists — not overwriting (your custom settings are preserved)"
fi

# ── CLAUDE.md (global only) ──────────────────────────────────────────────────
if [ "$MODE" = "global" ]; then
  echo "→ installing global CLAUDE.md..."
  cp config/CLAUDE.md "$TARGET/CLAUDE.md"
fi

# ── agent-memory templates (don't overwrite operator memory) ─────────────────
for f in "$TARGET/agents"/*.md; do
  agent=$(basename "$f" .md)
  mem_dir="$TARGET/agent-memory/$agent"
  mkdir -p "$mem_dir"
  if [ ! -f "$mem_dir/MEMORY.md" ]; then
    cat > "$mem_dir/MEMORY.md" <<EOF
# $agent — agent memory

> Persistent notes across sessions. Updated by the agent itself when consequential.

## Patterns learned
- (empty — populated during real sessions)

## Decisions context
- (empty)

## Gotchas
- (empty)
EOF
  fi
done

# ── project-only: memory + .claudeignore ─────────────────────────────────────
if [ "$MODE" = "project" ]; then
  PROJ_ROOT="$(dirname "$TARGET")"
  mkdir -p "$PROJ_ROOT/memory/decisions" "$PROJ_ROOT/memory/patterns" "$PROJ_ROOT/memory/templates"
  [ -f "memory/templates/adr.md" ] && cp memory/templates/adr.md "$PROJ_ROOT/memory/templates/" 2>/dev/null || true
  [ -f "memory/templates/pattern.md" ] && cp memory/templates/pattern.md "$PROJ_ROOT/memory/templates/" 2>/dev/null || true
  if [ ! -f "$PROJ_ROOT/memory/hot-context.md" ]; then
    cp memory/hot-context.md "$PROJ_ROOT/memory/hot-context.md"
    echo "  ✓ memory/hot-context.md (template — fill in for your project)"
  fi
  if [ ! -f "$PROJ_ROOT/memory/decisions/README.md" ] && [ -f memory/decisions/README.md ]; then
    cp memory/decisions/README.md "$PROJ_ROOT/memory/decisions/README.md"
  fi
  if [ ! -f "$PROJ_ROOT/.claudeignore" ] && [ -f config/.claudeignore.example ]; then
    cp config/.claudeignore.example "$PROJ_ROOT/.claudeignore"
    echo "  ✓ .claudeignore"
  fi
fi

# ── verify ───────────────────────────────────────────────────────────────────
echo ""
echo "→ verifying..."
if [ -f "$TARGET/scripts/verify.sh" ]; then
  CLAUDE_PROJECT_DIR="$([ "$MODE" = "project" ] && dirname "$TARGET")" \
    bash "$TARGET/scripts/verify.sh" || {
      echo ""
      echo "⚠ verification reported failures. The install completed but something is off."
      exit 1
    }
fi

echo ""
echo "=== ✅ La Bestia v$VERSION installed ($MODE mode) ==="
echo ""
echo "Next steps:"
echo "  1. Inspect $TARGET/settings.json — adjust permissions to your taste."
echo "  2. (Optional) Wire MCP servers — see la-bestia/mcp/README.md."
echo "  3. Run \`claude\` in any project. Try /agents, /cto-review, /ship-it."
echo ""
echo "Migrating from v0.x? See CHANGELOG.md → [1.0.0] → Migration."
