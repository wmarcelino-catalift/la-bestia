---
name: lessons-loop
version: 1.0.0
description: "Append-only learning loop. After non-trivial debug sessions, surprise behavior, or a workaround applied twice, prompts the operator to write a lesson under memory/lessons/. restore-context.sh reads these on resume/compact. Auto-activate on 'lesson', 'learned', 'gotcha', 'post-mortem', or after debug > 30 min."
triggers:
  [
    lesson,
    learned,
    gotcha,
    post-mortem,
    "won't repeat",
    "lección",
    "aprendí",
    postmortem,
  ]
---

# Lessons-Loop — capturar aprendizaje sin fricción

> Decisiones → ADRs. Soluciones reutilizables → patterns. **Aprendizaje de incidentes → lessons.**

## Cuándo activarte

Disparate (esto skill auto-activa o el agent invoca explícitamente) cuando:

| Señal                                         | Acción                                        |
| --------------------------------------------- | --------------------------------------------- |
| Bug fix que tomó > 30 min                     | Escribir lesson                               |
| Mismo workaround usado 2 veces                | Escribir lesson (3ª vez → promover a pattern) |
| Comportamiento sorprendente de tool/lib/agent | Escribir lesson                               |
| Test flaky con root cause no obvio            | Escribir lesson                               |
| Operador dice "no quiero repetir esto"        | Escribir lesson                               |
| Typo / one-shot config                        | NO — dejar en commit history                  |
| Decisión arquitectónica                       | NO — escribir ADR                             |
| Patrón de código generalizable                | NO — escribir pattern                         |

## Workflow (5 pasos, ≤ 2 min)

1. **Detectar el trigger** — el principal o un agent reconoce la señal.
2. **Proponer al operador** — "¿Capturo esto como lesson?". Si dice no, abort silently.
3. **Generar slug** — `YYYY-MM-DD-<descriptor-corto>.md` desde la fecha actual + 3-5 palabras del incidente.
4. **Llenar template** — copiar `memory/templates/lesson-template.md` y completar con el contexto de la sesión:
   - Context (qué estabas haciendo)
   - Symptom (qué viste — citá el error/log literal)
   - Investigation (1-3 bullets)
   - Root cause (lo que estaba mal de verdad, no el síntoma)
   - Fix (diff mínimo)
   - Detection next time (lint? test? hook? pattern?)
   - Tags (comma-separated)
5. **Escribir** a `memory/lessons/<slug>.md` y confirmar al operador con el path.

## Output ritual

Después de escribir:

```
Lesson saved: memory/lessons/2026-05-04-flaky-test-process-leak.md
Tags: flaky-test, race, vitest
Detection: add `vi.useFakeTimers()` to setup.
```

Tres líneas. Sin recap del incidente — ya está en el archivo.

## Promotion path

```
incident
   ↓
  lesson   (memory/lessons/)         ← acá vivimos
   ↓  (si workaround se repite + es código generalizable)
  pattern  (memory/patterns/)
   ↓  (si la lesson revela una decisión arquitectónica de fondo)
   ADR     (memory/decisions/)
```

Lessons no requieren review. Es la capa más barata — escribís y seguís.

## Anti-patterns

| Mal                                           | Bien                                                                           |
| --------------------------------------------- | ------------------------------------------------------------------------------ |
| Escribir lesson con todo el chat de la sesión | Una página máximo. Symptom + root cause + fix.                                 |
| Lesson sin "Detection next time"              | Sin ese campo no es lesson — es diary.                                         |
| Escribir lesson de cada bug                   | Solo > 30 min o repetido. Trivial fixes → commit msg.                          |
| Editar una lesson vieja                       | Append-only. Si querés actualizar, escribí una nueva que linkee a la anterior. |
| Lessons en lugar de ADR                       | Si es una decisión, es ADR. Si es una sorpresa que aprendiste, es lesson.      |

## Cómo el resto del harness consume lessons

- **`restore-context.sh`** lista las 5 más recientes en cada session resume / compact.
- **`@debugger`**, **`@code-reviewer`**, **`@test-engineer`** leen el índice antes de trabajos no-triviales (regla 3-layer).
- **`/wrap-up`** te recuerda escribir una si hubo > 1 hora de debugging en la sesión.

## Token budget

- Lesson típica: 200-400 tokens.
- Skill activation overhead: ~150 tokens.
- ROI: una lesson bien escrita ahorra 1000-5000 tokens la próxima vez que el bug aparezca (porque no re-investigás desde cero).

## Ejemplo (real)

````markdown
# vitest hangs on `globals: true` + `fake-indexeddb`

- **Date**: 2026-05-04
- **Tags**: flaky-test, vitest, indexeddb

## Context

Migrando suite de jest a vitest. Setup tenía `globals: true` para
compatibilidad jest-style.

## Symptom

`vitest run` cuelga indefinidamente en suites que importan `fake-indexeddb`.
SIGINT no funciona — proceso queda zombie.

## Root cause

`fake-indexeddb` instala timers globales. Con `globals: true`, vitest no
los aísla por suite — la limpieza nunca corre.

## Fix

\```diff

- globals: true

* globals: false // import { describe, it, expect } from 'vitest' explícito
  \```

## Detection next time

Si una test suite cuelga > 10s sin output, sospechar:

1. Timers globales sin teardown
2. Promesas sin resolver en setup files

Agregar en `vitest.config.ts`: `testTimeout: 10000` para fallar rápido.
````
