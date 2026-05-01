---
description: "Dispatch 3-5 subagents en paralelo para investigar dimensiones independientes del problema. Síntesis al final por el principal. 3x throughput vs serial."
argument-hint: "<topic>"
---

# /parallel-research $ARGUMENTS

Investigá $ARGUMENTS en paralelo desde múltiples ángulos.

## Patrón fan-out

1. Identificá 3-5 dimensiones INDEPENDIENTES del problema (sin dependencias entre sí, si no, no hay paralelismo real).
2. Spawneá UN mensaje con N llamadas paralelas a Agent (subagent_type por ángulo).
3. Cada subagent devuelve un summary acotado.
4. El principal sintetiza un único reporte.

## Ejemplos de fan-out típicos

### Para "agregar feature X a un repo"
- Agent 1 (architect, opus): patterns existentes en el codebase relacionados
- Agent 2 (security-auditor, sonnet): superficie de ataque del nuevo feature
- Agent 3 (test-engineer, sonnet): qué tests existentes hay que tocar
- Agent 4 (researcher → general-purpose, haiku): comparativa de libs externas

### Para "auditar repo nuevo"
- Agent 1 (general, haiku): mapa de carpetas + entrypoints
- Agent 2 (general, haiku): dependencies + versiones obsoletas
- Agent 3 (security-auditor, sonnet): grep de secretos + OWASP smell
- Agent 4 (architect, opus): patrones arquitectónicos detectados
- Agent 5 (general, haiku): test coverage actual

### Para "decidir entre 3 frameworks"
- Agent 1 (general, sonnet): docs oficial + features
- Agent 2 (general, sonnet): community size, maintenance, last release
- Agent 3 (general, sonnet): casos reales de adopción y abandono

## Output

```
## Research: $ARGUMENTS

### Síntesis
[3-5 bullets unificados]

### Por dimensión
**[Dim 1]**: [findings, fuente: agent-X]
**[Dim 2]**: ...

### Conflictos / contradicciones
[Si dos agentes reportan distinto, explicitar]

### Próximo paso recomendado
[Una acción concreta]
```
