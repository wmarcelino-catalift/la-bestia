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
