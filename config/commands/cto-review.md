---
description: "Senior CTO review del cambio actual o decisión propuesta. Aplica el filtro de las 5 preguntas + 10 principios. Detecta one-way doors."
---

# /cto-review

Aplicá el sistema de pensamiento CTO senior al contexto actual.

## Pasos

1. Activá el skill `cto-thinking-system` (auto si las keywords están en el prompt).
2. Leé el contexto: `git diff` si hay cambios, o el prompt del usuario si es decisión propuesta.
3. Pasá el filtro de las 5 preguntas:
   - Outcome de negocio
   - Simplicidad HOY (YAGNI)
   - Escala 10x en 6 meses
   - Blast radius 3am
   - One-way doors
4. Verificá los 10 principios contra el cambio.
5. Si detectás one-way door → STOP, recomendá ADR + validación humana.
6. Si necesitás más profundidad: dispatch @cto-strategist (opus) para PR-FAQ + RICE + build-vs-buy.
7. Si toca arquitectura: dispatch @architect (opus) en paralelo.

## Output

```
## CTO Review

### 5 preguntas
1. Outcome: [respuesta]
2. Simplicidad: [respuesta]
3. Escala 10x: [respuesta]
4. Blast radius: [respuesta]
5. One-way doors: [lista o "ninguno"]

### Principios vulnerados
- [si alguno, listar con cita al código]

### Veredicto
[GO | GO con condiciones | STOP — necesita ADR | STOP — refactor antes]

### Acciones recomendadas
- [pasos concretos en orden]
```
