#!/usr/bin/env bash
# cwd-changed.sh — detect when operator switches projects mid-session.
# If new cwd has no memory/hot-context.md, suggests `/onboard-project`.
#
# Hook event: PreToolUse Bash with matcher pattern '^cd ' (best-effort).
# Cheap: < 50ms. No network, no writes (only reads + stdout suggestion).

set -u

PROJ="${CLAUDE_PROJECT_DIR:-$(pwd)}"
INPUT="${CLAUDE_TOOL_INPUT:-}"

# Extract target dir from `cd <path>` if applicable.
TARGET=""
if command -v jq >/dev/null 2>&1 && [ -n "$INPUT" ]; then
  CMD=$(echo "$INPUT" | jq -r '.command // ""' 2>/dev/null)
  # Match `cd "/path/with spaces"` or `cd /path/no/spaces` or `cd path/relative`
  if [[ "$CMD" =~ ^[[:space:]]*cd[[:space:]]+\"([^\"]+)\" ]]; then
    TARGET="${BASH_REMATCH[1]}"
  elif [[ "$CMD" =~ ^[[:space:]]*cd[[:space:]]+([^\&\|\;]+) ]]; then
    TARGET="${BASH_REMATCH[1]// /}"
  fi
fi

[ -z "$TARGET" ] && exit 0

# Resolve absolute path (best effort; don't fail on missing dirs).
if [[ "$TARGET" != /* ]] && [[ "$TARGET" != ~* ]]; then
  TARGET="$PROJ/$TARGET"
fi
TARGET=$(cd "$TARGET" 2>/dev/null && pwd) || exit 0

# Skip if cd-ing inside same project root (subdirectory move, not switch).
if [ -d "$PROJ/memory" ] && [[ "$TARGET" == "$PROJ"* ]]; then
  exit 0
fi

# We're switching to a new project. Check its readiness.
if [ -d "$TARGET/.git" ] || [ -f "$TARGET/package.json" ] || [ -f "$TARGET/Cargo.toml" ] || [ -f "$TARGET/go.mod" ] || [ -f "$TARGET/pyproject.toml" ]; then
  if [ ! -f "$TARGET/memory/hot-context.md" ] && [ ! -f "$TARGET/CLAUDE.md" ]; then
    echo "[LA BESTIA] Detected project switch to $(basename "$TARGET"). No la-bestia memory yet."
    echo "[LA BESTIA] Suggestion: run \`/onboard-project\` to bootstrap memory/, .claudeignore, and CLAUDE.md."
  fi
fi

exit 0
