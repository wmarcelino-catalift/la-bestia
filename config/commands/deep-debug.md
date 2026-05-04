---
description: "Bug que no cede en 2 intentos. Switch implícito a Opus + dispatch debugger agent con análisis 5-whys y root-cause-no-symptom."
argument-hint: "<bug description>"
---

# /deep-debug $ARGUMENTS

Caso para esto: ya intentaste 2 veces, el bug persiste, los síntomas no encajan.

## Pasos

1. Si no estás en Opus, recomendá: `/model opus` para esta sesión.
2. Dispatch @debugger con el contexto completo:
   - Síntoma exacto + stack trace
   - Pasos para reproducir
   - Lo que YA probaste (importante — no repitas)
   - Diff de commits recientes en archivos sospechosos
3. El debugger aplica:
   - Bisect (capa, path, data)
   - Hipótesis testable en UNA frase
   - Test mínimo para validar/falsear
   - Fix en root cause, NO en síntoma
   - 5-whys chain documentada
   - Scan del codebase por mismo anti-pattern
4. Si el debugger no resuelve en 1 ciclo → escalá a humano con todo lo aprendido.

## Output

```
## Deep Debug: $ARGUMENTS

### Hipótesis testable
"El bug está en X porque Y"

### Cómo se valida/falsifica
[test mínimo o log]

### 5-Whys
1. WHY: [síntoma]
2. WHY: [...]
3. WHY: [...]
4. WHY: [...]
5. WHY: [root cause sistémico] ← FIX HERE

### Fix aplicado
[archivo:línea + diff]

### Verificación
- [x] Caso fallando ahora pasa
- [x] Tests existentes verdes
- [x] Regression test añadido

### Mismo anti-pattern detectado en
- [otros archivos a fixear]

### Lección para memory
[Promovida a `memory/patterns/<slug>.md` (project-local) o a `~/.claude/agent-memory/debugger/MEMORY.md` (cross-session) si es no-trivial]
```
