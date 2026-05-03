#!/usr/bin/env bash
# La Bestia v0.3 — install.sh
# Instala la configuración CTO senior de Claude Code (global o project-local).
# Safe to re-run (idempotente).

set -e

MODE="${1:-global}"  # global | project
if [ "$MODE" = "project" ]; then
  CLAUDE_DIR="${2:-.claude}"
  echo "=== La Bestia v0.3 — Project-local install in $CLAUDE_DIR ==="
else
  CLAUDE_DIR="$HOME/.claude"
  echo "=== La Bestia v0.3 — Global install in $CLAUDE_DIR ==="
fi

# Backup
if [ -d "$CLAUDE_DIR" ] && [ "$(ls -A "$CLAUDE_DIR" 2>/dev/null)" ]; then
  BACKUP="${CLAUDE_DIR}/_backup_$(date +%Y%m%d_%H%M%S)"
  echo "→ Backing up to $BACKUP"
  cp -r "$CLAUDE_DIR" "$BACKUP"
fi

# Directory structure
mkdir -p \
  "$CLAUDE_DIR/agents" \
  "$CLAUDE_DIR/hooks" \
  "$CLAUDE_DIR/scripts" \
  "$CLAUDE_DIR/commands" \
  "$CLAUDE_DIR/skills/cto-thinking-system" \
  "$CLAUDE_DIR/skills/ship-it" \
  "$CLAUDE_DIR/skills/token-saver" \
  "$CLAUDE_DIR/logs/sessions" \
  "$CLAUDE_DIR/vault" \
  "$CLAUDE_DIR/agent-memory/architect" \
  "$CLAUDE_DIR/agent-memory/cto-strategist" \
  "$CLAUDE_DIR/agent-memory/pm" \
  "$CLAUDE_DIR/agent-memory/debugger" \
  "$CLAUDE_DIR/agent-memory/test-engineer" \
  "$CLAUDE_DIR/agent-memory/code-reviewer" \
  "$CLAUDE_DIR/agent-memory/security-auditor" \
  "$CLAUDE_DIR/agent-memory/mobile-reviewer" \
  "$CLAUDE_DIR/agent-memory/devops" \
  "$CLAUDE_DIR/agent-memory/ux-reviewer" \
  "$CLAUDE_DIR/agent-memory/content-manager" \
  "$CLAUDE_DIR/agent-memory/data-engineer"

# Copy agent-memory templates (don't overwrite if populated)
for agent_dir in config/agent-memory/*/; do
  agent=$(basename "$agent_dir")
  target="$CLAUDE_DIR/agent-memory/$agent/MEMORY.md"
  if [ ! -f "$target" ]; then
    cp "$agent_dir/MEMORY.md" "$target"
  fi
done

# Agents (12)
echo "→ Installing 12 agents..."
cp config/agents/*.md "$CLAUDE_DIR/agents/"

# Hooks (5)
echo "→ Installing hooks..."
cp config/hooks/*.sh "$CLAUDE_DIR/hooks/"
chmod +x "$CLAUDE_DIR/hooks/"*.sh

# Scripts
echo "→ Installing scripts..."
cp config/scripts/*.sh "$CLAUDE_DIR/scripts/"
chmod +x "$CLAUDE_DIR/scripts/"*.sh

# Commands (11)
echo "→ Installing commands..."
cp config/commands/*.md "$CLAUDE_DIR/commands/"

# Skills (3)
echo "→ Installing skills..."
cp -r config/skills/cto-thinking-system "$CLAUDE_DIR/skills/"
cp -r config/skills/ship-it "$CLAUDE_DIR/skills/"
cp -r config/skills/token-saver "$CLAUDE_DIR/skills/"

# CLAUDE.md (global only — project has its own)
if [ "$MODE" = "global" ]; then
  echo "→ Installing global CLAUDE.md..."
  cp config/CLAUDE.md "$CLAUDE_DIR/CLAUDE.md"
fi

# settings.json
if [ ! -f "$CLAUDE_DIR/settings.json" ]; then
  echo "→ Installing settings.json..."
  cp config/settings.example.json "$CLAUDE_DIR/settings.json"
  echo "  ⚠ Edit settings.json — set GOOGLE_APPLICATION_CREDENTIALS if needed."
else
  echo "  ⚠ settings.json already exists — not overwriting."
fi

# .claudeignore (project only)
if [ "$MODE" = "project" ]; then
  PROJ_ROOT=$(dirname "$CLAUDE_DIR")
  if [ ! -f "$PROJ_ROOT/.claudeignore" ]; then
    cp config/.claudeignore.example "$PROJ_ROOT/.claudeignore"
    echo "→ Installed .claudeignore"
  fi
  # Memory dirs
  mkdir -p "$PROJ_ROOT/memory/decisions"
  if [ ! -f "$PROJ_ROOT/memory/hot-context.md" ]; then
    cp memory/hot-context.md "$PROJ_ROOT/memory/hot-context.md"
    echo "→ Installed memory/hot-context.md template — fill in your project details."
  fi
fi

# MCP servers (optional)
echo ""
echo "→ Registering MCP servers (optional)..."
claude mcp add vault --scope user -- npx -y @modelcontextprotocol/server-filesystem "$HOME/Obsidian/claude-brain" 2>/dev/null && echo "  ✓ vault MCP" || echo "  ⚠ vault MCP skipped"
claude mcp add memory --scope user -- npx -y @modelcontextprotocol/server-memory 2>/dev/null && echo "  ✓ memory MCP" || echo "  ⚠ memory MCP skipped"

# Verify
echo ""
echo "→ Verifying..."
if [ -f "$CLAUDE_DIR/scripts/verify.sh" ]; then
  CLAUDE_PROJECT_DIR="$(dirname "$CLAUDE_DIR")" bash "$CLAUDE_DIR/scripts/verify.sh" 2>/dev/null | tail -3
fi

echo ""
echo "=== Done! La Bestia v0.3 installed ==="
echo ""
echo "Next steps:"
echo "  1. Edit $CLAUDE_DIR/settings.json (model, permissions)"
echo "  2. Run: claude (in any project)"
echo "  3. Test: /agents"
echo ""
echo "Windows users: run bestia.ps1 from PowerShell for the 3-pane layout."
