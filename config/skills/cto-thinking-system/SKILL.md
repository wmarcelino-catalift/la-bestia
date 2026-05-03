---
name: cto-thinking-system
description: "Apply the CTO senior thinking framework: 5 mandatory questions filter + builder/buy decision matrix + one-way door identification. Auto-activate when prompt contains 'decisión', 'diseño', 'arquitectura', 'estrategia', 'producto', 'feature nuevo', 'comprar vs construir', 'roadmap', 'priorizar'."
---

# CTO Thinking System

Framework de pensamiento crítico aplicado a CADA decisión no-trivial.

## El filtro de las 5 preguntas (obligatorio)

Antes de proponer una solución no-trivial, respondé internamente:

1. **Outcome de negocio** — ¿Qué desbloquea esto? (no la tarea, el efecto. Métrica medible.)
2. **Simplicidad HOY** — ¿Es la opción más simple que resuelve el problema ahora? (YAGNI > clever)
3. **Escala 10x** — ¿Qué se rompe en 6 meses si crece 10x? (debt vs leverage)
4. **Blast radius 3am** — ¿Qué pasa si esto falla en producción a las 3am? (idempotencia, rollback, observabilidad)
5. **One-way door** — ¿Qué decisiones acá son irreversibles? (→ ADR + validación humana)

Si una está borrosa: **UNA** pregunta de calibración al humano. Después ejecutás con `[ASSUMPTION]` etiquetadas.

## Two-way vs One-way doors

| Tipo    | Característica                                          | Acción                      |
| ------- | ------------------------------------------------------- | --------------------------- |
| Two-way | Revertible <1 día, sin penalty                          | Ship and learn              |
| One-way | Cambio de DB, API pública, vendor lock, schema breaking | STOP → ADR → validar humano |

## Build vs Buy vs Hybrid

Default: **buy** para commodity, **build** para tu moat.

| Situación                           | Default                             |
| ----------------------------------- | ----------------------------------- |
| Auth, pagos, email, observability   | Buy (Auth0, Clerk, Stripe, Datadog) |
| Tu diferenciador                    | Build                               |
| Time-to-value crítico, equipo chico | Buy                                 |
| Compliance/soberanía de datos       | Build o self-hosted                 |
| Volumen >100k MAU                   | Re-evaluar: maybe build a wrapper   |

Matriz scoring (cuando no es obvio):

| Dim (peso)               | Build | Buy | Hybrid |
| ------------------------ | ----- | --- | ------ |
| Time-to-value (25%)      |       |     |        |
| Costo 12m (20%)          |       |     |        |
| Fit funcional (15%)      |       |     |        |
| Lock-in risk (15%)       |       |     |        |
| Maintenance burden (15%) |       |     |        |
| Strategic moat (10%)     |       |     |        |

## RICE prioritization

```
Score = (Reach × Impact × Confidence) ÷ Effort

Reach: usuarios afectados/mes
Impact: 3 (massive), 2 (high), 1 (medium), 0.5 (low), 0.25 (minimal)
Confidence: % (100% high evidence, 80% medium, 50% low)
Effort: person-months
```

## Working Backwards (Bezos)

1. Escribí el comunicado de lanzamiento ANTES del código.
2. Si no es emocionante, el feature no vale la pena.
3. Si es ambiguo, no entendés el problema.
4. PR-FAQ obligatorio para features nuevos:
   - Headline (1 línea cliente)
   - Problem
   - Solution
   - FAQ: ¿por qué ahora? ¿por qué nosotros? ¿qué NO va a hacer?

## Anti-patterns

- "Lo necesitamos para escalar" sin métrica concreta del escalar
- Construir el platform antes que el product
- Comparar 1 opción contra status quo (siempre 3+)
- Decidir sin one-way doors identificados
- "Puedo hacerlo en un weekend" sin estimar maintenance
