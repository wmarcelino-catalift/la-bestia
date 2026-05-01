#!/usr/bin/env bash
# La Bestia — install.sh
# Sets up the full CTO senior Claude Code config globally.
# Safe to re-run (idempotent).

set -e
CLAUDE_DIR="$HOME/.claude"
VAULT="${OBSIDIAN_VAULT:-$HOME/Obsidian/claude-brain}"

echo "=== La Bestia v0.1 — Installing ==="
echo "Claude dir: $CLAUDE_DIR"
echo "Vault:      $VAULT"
echo ""

# 1. Backup existing config
if [ -d "$CLAUDE_DIR" ] && [ "$(ls -A $CLAUDE_DIR)" ]; then
  BACKUP="$CLAUDE_DIR/_backup_$(date +%Y%m%d_%H%M%S)"
  echo "→ Backing up existing ~/.claude/ to $BACKUP"
  cp -r "$CLAUDE_DIR" "$BACKUP"
fi

# 2. Create directory structure
mkdir -p \
  "$CLAUDE_DIR/agents" \
  "$CLAUDE_DIR/hooks" \
  "$CLAUDE_DIR/scripts" \
  "$CLAUDE_DIR/commands" \
  "$CLAUDE_DIR/skills/cto-thinking-system" \
  "$CLAUDE_DIR/skills/ship-it" \
  "$CLAUDE_DIR/skills/token-saver" \
  "$CLAUDE_DIR/agent-memory/architect" \
  "$CLAUDE_DIR/agent-memory/code-reviewer" \
  "$CLAUDE_DIR/agent-memory/debugger" \
  "$CLAUDE_DIR/logs/sessions"

# 3. Copy config files
echo "→ Installing agents..."
cp config/agents/*.md "$CLAUDE_DIR/agents/"

echo "→ Installing hooks..."
cp config/hooks/*.sh "$CLAUDE_DIR/hooks/"
chmod +x "$CLAUDE_DIR/hooks/"*.sh

echo "→ Installing scripts..."
cp config/scripts/*.sh "$CLAUDE_DIR/scripts/"
chmod +x "$CLAUDE_DIR/scripts/"*.sh

echo "→ Installing commands..."
cp config/commands/*.md "$CLAUDE_DIR/commands/"

echo "→ Installing skills..."
cp config/skills/cto-thinking-system/SKILL.md "$CLAUDE_DIR/skills/cto-thinking-system/"
cp config/skills/ship-it/SKILL.md "$CLAUDE_DIR/skills/ship-it/"
cp config/skills/token-saver/SKILL.md "$CLAUDE_DIR/skills/token-saver/"

echo "→ Installing CLAUDE.md..."
cp config/CLAUDE.md "$CLAUDE_DIR/CLAUDE.md"

# 4. Install settings.json if not exists
if [ ! -f "$CLAUDE_DIR/settings.json" ]; then
  echo "→ Installing settings.json..."
  cp config/settings.example.json "$CLAUDE_DIR/settings.json"
else
  echo "⚠ settings.json already exists — not overwriting. See config/settings.example.json."
fi

# 5. Set up Obsidian vault structure
echo "→ Setting up Obsidian vault at $VAULT..."
mkdir -p \
  "$VAULT/people" \
  "$VAULT/systems" \
  "$VAULT/projects" \
  "$VAULT/permanent/decisions" \
  "$VAULT/permanent/patterns" \
  "$VAULT/permanent/gotchas" \
  "$VAULT/inbox" \
  "$VAULT/live" \
  "$VAULT/templates"

# Copy vault templates if they don't exist
if [ ! -f "$VAULT/HOT.md" ]; then
  cp vault/HOT.md "$VAULT/HOT.md" 2>/dev/null || cat > "$VAULT/HOT.md" <<'EOF'
# HOT — Cross-project recent context

> Últimos 7 días. Auto-rotado al cerrar sesión por curate-hot.sh.
> Inyectado al inicio de cada sesión por inject-context.sh.

## Última semana
- (vacío)

## Decisiones recientes
- Modelo default: `/model opusplan`

## Pendientes cross-project
- [ ] Primera sesión con La Bestia
EOF
fi

if [ ! -f "$VAULT/INDEX.md" ]; then
  cat > "$VAULT/INDEX.md" <<'EOF'
# INDEX — Mapa del vault

## People
- [[Wilser]] (o tu nombre)

## Systems
- [[LaBestia]]

## Projects
- (agregar proyectos aquí)
EOF
fi

# 6. Register MCP servers
echo "→ Registering MCP servers..."
claude mcp add vault --scope user -- npx -y @modelcontextprotocol/server-filesystem "$VAULT" 2>/dev/null && echo "  ✓ vault MCP" || echo "  ⚠ vault MCP (already exists or failed)"
claude mcp add memory --scope user -- npx -y @modelcontextprotocol/server-memory 2>/dev/null && echo "  ✓ memory MCP" || echo "  ⚠ memory MCP (already exists or failed)"

# 7. Verify
echo ""
echo "→ Running verify..."
bash "$CLAUDE_DIR/scripts/verify.sh" 2>/dev/null | tail -5

echo ""
echo "=== Done! ==="
echo ""
echo "Next steps:"
echo "  1. Edit ~/.claude/CLAUDE.md with your identity/preferences"
echo "  2. Set OBSIDIAN_VAULT in ~/.zshrc if different from $VAULT"
echo "  3. Run: claude (in any project)"
echo "  4. Test: bash ~/.claude/scripts/verify.sh"
