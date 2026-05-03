#!/usr/bin/env bash
# sync-to-bestia.sh — Full sync of .claude/ config → la-bestia repo.
# Maps: .claude/{agents,commands,hooks,scripts,skills} → config/
# Also syncs: install.sh, README.md, .claudeignore, agent-memory templates.
# Usage: bash .claude/scripts/sync-to-bestia.sh [push|dry]

set -euo pipefail

PROJ="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
CLAUDE_DIR="$PROJ/.claude"
REMOTE_URL="https://github.com/wmarcelino-catalift/la-bestia.git"
TMP_DIR=$(mktemp -d)
PUSH="${1:-ask}"

cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

echo "=== sync-to-bestia ==="
echo "Source: $CLAUDE_DIR"
echo "Target: $REMOTE_URL"
echo ""

echo "→ Cloning la-bestia..."
git clone --depth=1 "$REMOTE_URL" "$TMP_DIR/la-bestia" -q
cd "$TMP_DIR/la-bestia"

BRANCH="sync/catalift-$(date +%Y%m%d-%H%M%S)"
git checkout -b "$BRANCH" -q

# ── 1. Core config: agents, commands, hooks, scripts, skills ─────────────────
for dir in agents commands hooks scripts; do
  SRC="$CLAUDE_DIR/$dir"
  DST="config/$dir"
  if [ -d "$SRC" ]; then
    mkdir -p "$DST"
    cp "$SRC"/* "$DST/" 2>/dev/null || true
    echo "  ✓ $dir"
  fi
done

for skill_dir in "$CLAUDE_DIR/skills"/*/; do
  skill_name=$(basename "$skill_dir")
  skill_file="$skill_dir/SKILL.md"
  if [ -f "$skill_file" ]; then
    mkdir -p "config/skills/$skill_name"
    cp "$skill_file" "config/skills/$skill_name/SKILL.md"
  fi
done
echo "  ✓ skills"

# ── 2. .claudeignore template ─────────────────────────────────────────────────
if [ -f "$PROJ/.claudeignore" ]; then
  cp "$PROJ/.claudeignore" "config/.claudeignore.example"
  echo "  ✓ .claudeignore.example"
fi

# ── 3. Agent-memory templates (empty structured, for all 12 agents) ───────────
AGENTS=(architect cto-strategist pm debugger test-engineer code-reviewer \
        security-auditor mobile-reviewer devops ux-reviewer content-manager data-engineer)

for agent in "${AGENTS[@]}"; do
  mkdir -p "config/agent-memory/$agent"
  # Only write template if file doesn't exist or is the empty "(vacio)" version
  TARGET="config/agent-memory/$agent/MEMORY.md"
  if [ ! -f "$TARGET" ] || grep -q "(vacio)" "$TARGET" 2>/dev/null; then
    cat > "$TARGET" <<EOF
# ${agent} — agent memory

> Notas persistentes cross-sesión. Actualizar con hallazgos importantes.

## Patterns aprendidos

- (vacío — se popula durante sesiones reales)

## Decisiones contextuales

- (vacío)

## Gotchas

- (vacío)
EOF
  fi
done
echo "  ✓ agent-memory templates (12)"

# ── 4. Memory templates ────────────────────────────────────────────────────────
mkdir -p "memory"
if [ ! -f "memory/hot-context.md" ]; then
  cat > "memory/hot-context.md" <<'EOF'
# hot-context.md — [PROJECT NAME]
# Leer PRIMERO en cada sesión. ~200 tokens. Actualizar con /wrap-up.

## Proyecto
- **App**: [nombre] — [descripción]
- **Version**: [version]
- **Stack**: [stack principal]

## Stack
- **Frontend**: [framework]
- **Backend**: [servicios]
- **Builds**: [CI/CD]

## Decisiones recientes
- [fecha]: [decisión]

## Pendientes
- [ ] [tarea pendiente]

## Gotchas
- [gotcha conocido]
EOF
  echo "  ✓ memory/hot-context.md template"
fi

mkdir -p "memory/decisions"
if [ ! -f "memory/decisions/README.md" ]; then
  cat > "memory/decisions/README.md" <<'EOF'
# memory/decisions — Architecture Decision Records

Decisiones one-way door del proyecto. Formato: ADR-NNNN-titulo.md

## Índice
- (vacío — crear ADR-001 con la primera decisión irreversible del proyecto)
EOF
  echo "  ✓ memory/decisions/README.md"
fi

# ── 5. install.sh ─────────────────────────────────────────────────────────────
cat > "install.sh" <<'INSTALL'
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
INSTALL
chmod +x install.sh
echo "  ✓ install.sh (v0.3)"

# ── 6. README.md ──────────────────────────────────────────────────────────────
cat > "README.md" <<'README'
# 🐺 LA BESTIA — Claude Code Setup v0.3

> Sistema CTO senior multi-agente para Claude Code.
> 12 agentes especializados · 11 comandos · 5 hooks · 3 skills · memoria cross-sesión.
> Local. Bajo tu control. Sin lock-in.

---

## Qué incluye

| Componente | Cantidad | Ejemplos |
|---|---|---|
| **Agentes** | 12 | architect, cto-strategist, pm, debugger, test-engineer, security-auditor... |
| **Comandos** | 11 | `/ship-it`, `/bug-hunt`, `/mobile-audit`, `/parallel-research`, `/cto-review`... |
| **Hooks** | 5 | block-secrets, inject-context, track-agent, log-agents, log-session |
| **Skills** | 3 | cto-thinking-system, ship-it, token-saver |
| **Memoria** | cross-sesión | agent-memory/ + memory/hot-context.md + memory/decisions/ |

## Teams de agentes

| Team | Líder | Cuándo |
|---|---|---|
| **STRATEGY** | `cto-strategist` | Nueva feature, roadmap, decisión arquitectónica |
| **DELIVERY** | `test-engineer` | Implementación, PR, código nuevo |
| **SAFETY** | `security-auditor` | Pre-merge, auth/payments, deploy |
| **DOMAIN** | (por contexto) | Firestore content, UX, data layer |

---

## Instalación

### Global (una vez, todos los proyectos)
```bash
git clone https://github.com/wmarcelino-catalift/la-bestia.git
cd la-bestia
bash install.sh global
```

### Project-local (por repo)
```bash
cd mi-proyecto
git clone https://github.com/wmarcelino-catalift/la-bestia.git /tmp/la-bestia
bash /tmp/la-bestia/install.sh project .claude
```

### Windows (PowerShell)
```powershell
git clone https://github.com/wmarcelino-catalift/la-bestia.git
cd la-bestia
& "C:\Program Files\Git\bin\bash.exe" -c "bash install.sh global"
```

---

## Quickstart

```bash
cd cualquier-repo
claude

# En la sesión:
/agents          # ver todos los agentes disponibles
/cto-review      # review CTO del código actual
/ship-it         # quality gates pre-merge
/bug-hunt        # debug paralelo 3 capas
```

---

## Cómo funciona el routing

```
Prompt (ES o EN)
    ↓
Principal Claude lee CLAUDE.md + agent descriptions (nativo Claude Code)
    ↓
Dispatch al agente correcto (o paralelo si hay varios)
    ↓
Agentes leen agent-memory/ → ejecutan → escriben hallazgos
    ↓
Principal sintetiza → respuesta
```

---

## Requisitos

- Claude Code CLI instalado
- `jq` instalado (`brew install jq` / `apt install jq`)
- `gh` instalado (opcional, para `/ship-it` con GitHub)
- Git Bash en Windows (para hooks bash)

---

## Estructura del repo

```
config/
  agents/          12 agentes especializados
  commands/        11 slash commands
  hooks/           5 hooks deterministas
  scripts/         utilidades (verify, sync, statusline...)
  skills/          3 skills con auto-trigger
  agent-memory/    templates vacíos (se pueblan durante sesiones)
  .claudeignore.example
  settings.example.json
  CLAUDE.md        constitución global CTO
memory/
  hot-context.md   template de contexto del proyecto
  decisions/       plantilla para ADRs
install.sh
```

---

## Versiones

| Versión | Agentes | Fecha |
|---|---|---|
| v0.3 | 12 agentes, inter-agent memory, bilingual routing | 2026-05-03 |
| v0.2 | 10 agentes, 11 comandos, routing ES/EN | 2026-05-03 |
| v0.1 | 6 agentes, hooks básicos | 2026-05-01 |
README
echo "  ✓ README.md (v0.3, 12 agents)"

# ── Check for changes ─────────────────────────────────────────────────────────
if git diff --quiet && git diff --cached --quiet && [ -z "$(git ls-files --others --exclude-standard)" ]; then
  echo ""
  echo "✅ La-bestia already up to date."
  exit 0
fi

echo ""
echo "=== Changes to push ==="
git add -A
git diff --cached --stat
echo ""

if [ "$PUSH" = "dry" ]; then
  echo "Dry run — not pushing."
  exit 0
fi

git commit -m "sync(catalift): v0.3 — 12 agents, inter-agent memory, full install

- 12 agents (added pm, data-engineer)
- All agents with CONTEXT + CHAIN + MEMORY steps
- agent-memory templates for all 12 agents
- Updated install.sh (global + project-local modes)
- .claudeignore.example template
- memory/hot-context.md + decisions/ templates
- README.md v0.3
- hook fixes: MultiEdit bypass, JSONL encoding, git timeouts

$(git diff --cached --stat | tail -1)" -q

echo "→ Pushing $BRANCH to la-bestia..."
git push origin "$BRANCH" -q
echo ""
echo "✅ Done! Open PR: https://github.com/wmarcelino-catalift/la-bestia/compare/$BRANCH"
