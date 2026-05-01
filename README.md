# 🐺 LA BESTIA — Claude Code Setup

> Sistema de pensamiento CTO senior, multi-agente, con memoria visual, ahorro de tokens.
> Local. Bajo tu control. Sin lock-in.

**Versión**: v0.1 (2026-05-01)

📖 **Referencia operativa completa**: [`docs/HOW-IT-WORKS.md`](docs/HOW-IT-WORKS.md) — vault, persistencia, observabilidad, troubleshooting, lifecycle.

---

## Quickstart (3 pasos)

### 1. Verificar instalación
```bash
bash ~/.claude/scripts/verify.sh
```
Debe terminar con `Bestia ready 🐺`. Cualquier ❌ → fixear antes de seguir.

### 2. Instalar deps opcionales
```bash
npm i -g ccusage              # baseline de tokens y costo en vivo
brew install jq               # ya debería estar
brew install gh               # GitHub CLI para /ship-it
```

### 3. Primera sesión
```bash
cd <cualquier-repo>
claude
```

Al iniciar, deberías ver:
- Statusline con `🐺 <repo> [<branch>] | <model> | $X today | last: <agent>`
- El hook `inject-context.sh` corre y muestra `HOT.md` + git status
- Todo prompt pasa por `route-prompt.sh` que sugiere subagent

---

## Comandos

### Built-in
- `/model opusplan` — modo híbrido (Opus plan + Sonnet exec). **Default recomendado.**
- `/model opus` — para bugs duros y refactors cross-module
- `/model sonnet` — ejecución normal
- `/model haiku` — transformaciones masivas
- `/compact` — compactar contexto en breakpoints lógicos
- `/clear` — entre tareas no relacionadas

### Custom (de la bestia)
- `/cto-review` — review CTO senior con las 5 preguntas + 10 principios
- `/parallel-research <topic>` — fan-out 3-5 subagents en paralelo
- `/ship-it` — quality gates + commit + PR
- `/deep-debug <bug>` — switch a Opus + debugger agent

---

## Subagents (6 core)

| Agent | Modelo | Cuándo se invoca |
|---|---|---|
| `cto-strategist` | opus | Decisiones de producto/negocio, working-backwards, build-vs-buy |
| `architect` | opus | ADRs, diseño de sistemas, decisiones cross-module |
| `test-engineer` | sonnet | Implementador default con TDD |
| `code-reviewer` | sonnet | Review post-cambio |
| `security-auditor` | sonnet | OWASP, auth, payments, supply chain |
| `debugger` | opus | Root-cause cuando un bug no cede en 2 intentos |

El hook `route-prompt.sh` sugiere cuál usar según keywords del prompt.

---

## Skills (progressive disclosure)

| Skill | Auto-trigger |
|---|---|
| `cto-thinking-system` | "decisión", "diseño", "arquitectura", "estrategia" |
| `ship-it` | "commit", "PR", "merge", "ship", "deploy" |
| `token-saver` | Contexto >60%, exploración masiva, "optimizar" |

Solo metadata (~100 tok) cargada siempre. Cuerpo (<5k tok) on-demand.

---

## Hooks (deterministas)

| Hook | Evento | Qué hace |
|---|---|---|
| `block-secrets.sh` | PreToolUse Write/Edit | Bloquea `.env`/`.pem`/`.key`/credentials + content matching `sk-ant-*`/`AKIA*`/`BEGIN PRIVATE KEY` |
| `inject-context.sh` | SessionStart | Inyecta `HOT.md` + project hot-context + git status |
| `route-prompt.sh` | UserPromptSubmit | Sugiere subagent según keywords |
| `log-agents.sh` | PostToolUse Task/Bash | JSONL line para flow-diagram |
| `log-session.sh` | Stop | Placeholder en vault inbox |

---

## Visualización del flujo de agents

### Statusline en vivo
Bottom de Claude Code muestra: `🐺 repo [branch] | model | $today | last: agent`

### ccusage TUI (terminal)
```bash
ccusage blocks --live    # dashboard de tokens/costo en vivo
ccusage daily            # histórico diario
```

### Mermaid flow diagram
Después de una sesión:
```bash
bash ~/.claude/scripts/flow-diagram.sh           # imprime mermaid
bash ~/.claude/scripts/flow-diagram.sh --save    # guarda al vault inbox
```

Abrí el archivo en Obsidian o GitHub — renderiza el grafo de invocaciones de agents.

---

## Vault Obsidian (memoria visual)

Path: `~/Obsidian/claude-brain/`

```
HOT.md                    # últimos 7 días — inyectado al inicio de sesión
INDEX.md                  # mapa global del vault
CLAUDE.md                 # instrucciones para Claude (vault-side)
permanent/
  patterns/               # 1 idea por nota, atomic
  decisions/              # ADRs cross-project
  gotchas/                # bugs raros, quirks de libs
projects/<slug>/          # 1 dir por proyecto
inbox/                    # captura sin curar
templates/                # Zettelkasten templates
```

**Regla de 3 capas para consulta**:
1. `HOT.md`
2. `projects/<repo>/index.md`
3. Solo entonces leer código fuente

Instalá Obsidian (gratis): https://obsidian.md/ → Open folder as vault → seleccioná `~/Obsidian/claude-brain/`.

---

## Estrategia de modelos (decisión #1 de costo)

| Modelo | Precio in/out por MTok | Cuándo |
|---|---|---|
| Opus 4.7 | $15 / $75 | Plan mode, decisiones arquitectónicas, debug complejo |
| Sonnet 4.6 | $3 / $15 | Ejecución default |
| Haiku 4.5 | ~$1 / $5 | Subagents de exploración, file reads, greps |

**Default**: `/model opusplan`. 60-80% menos costo vs todo Opus.

---

## Métricas que dicen "funciona"

- `ccusage daily` muestra <50% tokens por sesión vs baseline pre-bestia
- Salís de sesiones con commits, no con TODOs
- No reescribís las mismas instrucciones de tu stack 3 veces por semana
- Subagents te ahorran abrir 10+ archivos en el contexto principal
- Tu vault crece con notas curadas, no basura

---

## Troubleshooting

### Hook no corre
```bash
ls -la ~/.claude/hooks/         # ¿executable bit?
bash ~/.claude/scripts/verify.sh
```

### Agent no se invoca
- ¿Frontmatter `description` tiene las keywords correctas?
- Forzá: `Use the <agent-name> agent to ...`

### Tokens disparados
```bash
ccusage blocks --live           # ver en vivo
/compact preserve: ... resume: ...
/model haiku                    # si es exploración
```

### settings.json roto
```bash
jq empty ~/.claude/settings.json    # debe no decir nada
```

---

## Roadmap (cuándo subir a v0.2)

| Disparador | Acción |
|---|---|
| Reescribís misma instrucción 3x/semana | Crear skill nuevo |
| Sesión >100k tokens típica | Spawn subagent Haiku |
| 5+ repos activos | Instalar MCP de Obsidian |
| Auth/payments en producción | security-auditor mandatorio + deny push main |
| 3+ workers con dependencies cruzadas | Activar Agent Teams (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`) |

---

## Backup

Todo el setup anterior: `_archive/2026-05-01-pre-bestia/` (160 KB). Restore:
```bash
cp -R _archive/2026-05-01-pre-bestia/global/* ~/.claude/
```
