# LA BESTIA — Setup workspace

> Lab personal de Claude Code. Toda la config viva en `~/.claude/` (global).
> Acá se prototipa antes de mover a global, y se documentan decisiones.

## Estado
Setup v0.1 — Ejecutado 2026-05-01.
- 6 agents core, 3 skills, 5 hooks, 4 commands.
- Vault Obsidian en `~/Obsidian/claude-brain/` (sin MCP por ahora).
- Backup pre-bestia en `_archive/2026-05-01-pre-bestia/`.

## Ver README.md de la raíz para quickstart.

## Workflow para evolucionar la bestia
1. Editar archivos acá.
2. Probar en sesión real durante 1 semana.
3. Si funciona → mover a `~/.claude/`.
4. Documentar en `memory/decisions/NNNN-titulo.md`.

## Reglas
- Nunca tocar `~/.claude/` directamente sin backup en `_archive/`.
- Cada cambio destructivo → ADR.
- `/onboard`-style commands viven en este repo solo si son específicos del meta-config.
