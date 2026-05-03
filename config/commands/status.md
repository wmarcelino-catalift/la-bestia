---
description: "Snapshot del estado actual: agentes activos, actividad reciente, costo de tokens, git state."
---

# /status

Ejecutá el dashboard y mostrá el estado actual de la sesión.

## Output inmediato

```bash
bash .claude/scripts/dashboard.sh
```

## Para monitoreo en tiempo real (terminal separada)

```bash
# Opción A — watch cada 2 segundos
watch -n 2 'bash .claude/scripts/dashboard.sh'

# Opción B — stream del live log
tail -f .claude/logs/live-activity.jsonl | jq -r '"[\(.ts | split("T")[1] | split("Z")[0])] \(.event) \(.agent) \(if .duration then "\(.duration)s" else "" end)"'
```

## Logs disponibles

| Archivo                            | Contenido                                  |
| ---------------------------------- | ------------------------------------------ |
| `.claude/logs/agents.jsonl`        | Historial de todos los agents llamados     |
| `.claude/logs/live-activity.jsonl` | Actividad en tiempo real (pre/post events) |
| `.claude/logs/sessions/`           | Resumen de cada sesión                     |
