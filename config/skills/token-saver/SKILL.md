---
name: token-saver
description: "Active token-saving tactics: model routing (opusplan/haiku for exploration), diff-output, /compact at breakpoints, .claudeignore, 3-layer memory rule. Auto-activate when context >60% full, when reading >5 files, or when prompt mentions 'optimizar', 'caro', 'ahorrar', 'tokens'."
---

# Token Saver — Tácticas activas

Lista por ROI real. Aplicá en orden cuando el contexto crece.

## 1. Routing de modelos (mayor ROI)

```
/model opusplan     # default — Opus plan + Sonnet exec. -60-80% vs todo Opus.
/model opus         # solo bug que no cede + decisión arquitectónica
/model sonnet       # ejecución default
/model haiku        # transformaciones repetitivas en muchos archivos
```

Subagents declarativos:
- `model: claude-opus-4-7` → cto-strategist, architect, debugger
- `model: claude-sonnet-4-6` → test-engineer, code-reviewer, security-auditor
- `model: claude-haiku-4-5` → repo-explorer, memory-curator, file-fetcher

## 2. Subagents Haiku para exploración

5x más barato que Sonnet, suficiente para reads/greps.
Cuando vas a leer >10 archivos para entender un repo: spawn subagent Haiku con la pregunta concreta. Devuelve summary, no dump de archivos.

## 3. Diff-output, no archivo completo

Cuando edites un archivo grande, usá Edit (envía solo el diff) en vez de Write (envía el archivo entero).
Costo: 5-20% del rewrite.

## 4. /compact proactivo

Breakpoints lógicos para `/compact`:
- Después de un research extenso, antes de empezar a implementar
- Después de un debug largo, antes de escribir el fix
- Al cambiar de feature/módulo dentro de la misma sesión

```
/compact preserve: decisiones arquitectónicas, errores resueltos + cómo, comandos shell exactos que funcionaron, archivos modificados.
        resume aggressively: exploración fallida, búsquedas, intentos descartados.
```

## 5. .claudeignore estricto

```
node_modules/
.git/
dist/
build/
.next/
.expo/
.nuxt/
coverage/
*.log
*.lock
package-lock.json
yarn.lock
pnpm-lock.yaml
poetry.lock
Cargo.lock
target/
__pycache__/
*.pyc
.venv/
venv/
.DS_Store
.env*
*.pem
*.key
```

## 6. Env vars de ahorro

```bash
export DISABLE_NON_ESSENTIAL_MODEL_CALLS=1
export CLAUDE_CODE_MAX_OUTPUT_TOKENS=8000
```

## 7. Regla de 3 capas en consultas a memoria

Antes de leer código fuente:
1. `memory/hot-context.md` (~200 tok)
2. `memory/decisions/` o `<vault>/projects/<repo>/index.md`
3. Recién entonces grep/read del código

Esto ahorra hasta 10x en sesiones documentadas.

## 8. Hook route-prompt

El hook UserPromptSubmit detecta keywords y sugiere subagent ANTES de que la exploración entre al contexto principal.

## 9. /clear entre tareas no relacionadas

Contexto stale gasta tokens en cada turno. Si pasaste de "debug auth bug" a "diseñar feature notifications" → `/clear`.

## 10. Pedir output compacto

Cuando pidas algo a Claude, indicá formato:
- "responde en una tabla"
- "máx 200 palabras"
- "solo bullet points"
- "diff format"

## Heurística rápida

| Síntoma | Acción |
|---|---|
| Contexto >60% | `/compact` con instrucciones |
| Vas a leer >10 archivos | Spawn subagent Haiku |
| Tarea distinta a la previa | `/clear` |
| Decisión cara/irreversible | Plan mode (Opus) |
| Refactor masivo idéntico en N archivos | Switch a Haiku |
| Bug que no cede | Switch a Opus + debugger agent |

## Métricas

```bash
ccusage             # daily summary
ccusage blocks --live   # TUI en vivo durante sesión
ccusage daily       # histórico
```

Baseline pre-bestia → meta: **<50% tokens por sesión** post-bestia.
