# ADR 0001 — Bestia v0.1

**Date**: 2026-05-01
**Status**: Accepted
**Supersedes**: previous global+project setup (archived)

## Context

El plan original "La Bestia" tenía 15 subagents + 7 skills + 7 commands + Agent Teams + Obsidian MCP + cron memory-curator. Análisis CTO determinó:

1. 15 agents desde día 1 contradice el propio anti-pattern del plan ("30+ = parálisis").
2. Pricing Opus 4.7 en el plan ($5/$25) era incorrecto — real es $15/$75.
3. "Agent Teams peer-to-peer" exagera capability — Claude Code no tiene messaging real entre teammates.
4. "Watchdog continuous review" no existe nativo — los subagents son fire-and-forget.
5. "memory-curator vía cron" requiere OS cron + `claude -p` headless, no es nativo.

## Decision

Ejecutar **v0.1 podada al 40%** del plan original:

- **6 agents** (no 15): cto-strategist, architect, test-engineer, code-reviewer, security-auditor, debugger.
- **3 skills**: cto-thinking-system, ship-it, token-saver.
- **4 commands**: /cto-review, /parallel-research, /ship-it, /deep-debug.
- **5 hooks**: block-secrets (file + content), inject-context, route-prompt, log-agents, log-session.
- **Vault Obsidian**: estructura de carpetas + templates. SIN MCP día 1.
- **Statusline custom** + **flow-diagram script** (Mermaid desde JSONL).
- **verify.sh** para health-check del setup.
- Modelo default: `opusplan` (Opus plan + Sonnet exec).

## Consequences

### Positivo
- Setup ejecutable en una sesión, no en 3 días.
- Cada componente tiene un caso de uso claro y medible.
- Cero feature inventada (todo es Claude Code real).
- Hook `block-secrets` cubre por filename Y contenido (era el gap más serio).
- Visualización de agents via JSONL → Mermaid (ROI alto, costo bajo).

### Negativo
- Falta cobertura para roles que el plan tenía: reliability-engineer, performance-optimizer, refactorer, data-architect, frontend-specialist, devops-engineer, memory-curator, repo-explorer.
- Sin Agent Teams. Sin MCP de Obsidian. Sin cron.
- Vault no se actualiza automáticamente — manual hasta que `memory-curator` se setupee.

### Validation triggers
- Reescribís la misma instrucción 3x/semana → crear skill nuevo.
- Sesión > 100k tokens → spawn subagent Haiku para exploración.
- Tarea con dependencias entre 3+ workers → activar Agent Teams.
- 5+ repos activos → instalar MCP de Obsidian.
- Auth/payments en cliente corporativo → security-auditor mandatorio + deny push origin main.

## Backup
`_archive/2026-05-01-pre-bestia/` (160 KB).
