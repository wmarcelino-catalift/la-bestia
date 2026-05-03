---
description: "Fan-out paralelo de 3 agentes por capas (UI, Service, Data) para encontrar root cause. 3x más rápido que investigación serial."
argument-hint: "<síntoma del bug>"
---

# /bug-hunt $ARGUMENTS

Investigando: **$ARGUMENTS**

Dispatchá estos 3 agentes EN UN SOLO MENSAJE (paralelos):

## Agent 1 — UI Layer (debugger, opus)

```
Investiga "$ARGUMENTS" en la capa de UI.
Busca en: frontend/app/app/*, frontend/app/app/_components/*
Enfocate en: estado React, props, navegación, renders condicionales, hooks.
Retorná: archivo:línea + código relevante + hipótesis.
```

## Agent 2 — Service Layer (debugger, opus)

```
Investiga "$ARGUMENTS" en la capa de servicios.
Busca en: frontend/services/workout/*, frontend/services/core/*
Enfocate en: lógica de negocio, transformaciones, async flows, cache.
Retorná: archivo:línea + código relevante + hipótesis.
```

## Agent 3 — Data Layer (debugger, opus)

```
Investiga "$ARGUMENTS" en la capa de datos.
Busca en: firestoreService.ts, workoutSession.ts, cacheService.ts
Enfocate en: queries Firestore, AsyncStorage, datos stale.
Retorná: archivo:línea + código relevante + hipótesis.
```

## Síntesis

1. Cruzar hallazgos — ¿dónde coinciden?
2. Root cause en 1 frase
3. Fix mínimo (diff)
4. Confianza BAJA → dispatch @debugger con 5-whys

## Output

```
## Bug Hunt: $ARGUMENTS

**UI**: archivo:LN — descripción
**Service**: archivo:LN — descripción
**Data**: archivo:LN — descripción

### Root cause: [1 frase]
### Fix: [diff o descripción]
### Confianza: ALTA | MEDIA | BAJA
```
