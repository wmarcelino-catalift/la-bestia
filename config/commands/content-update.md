---
description: "Updates de contenido en Firestore: meal plans, recetas, ejercicios, creator config, fotos. Delega a @content-manager."
argument-hint: "<descripción del cambio>"
---

# /content-update $ARGUMENTS

Cambio: **$ARGUMENTS**

Delegá a `@content-manager` con el contexto completo del cambio.

## Quick reference — Colecciones

| Qué actualizar        | Colección                 | Campo                  |
| --------------------- | ------------------------- | ---------------------- |
| WhatsApp URL          | `creators/alanis_sanchez` | `communityWhatsappUrl` |
| Feature flags         | `creators/alanis_sanchez` | `featureFlags`         |
| Foto de receta        | `meals/{mealId}`          | `imageUrl` (HTTPS)     |
| Foto de ejercicio     | `exercises/{exerciseId}`  | `thumbnailUrl`         |
| Video de ejercicio    | `exercises/{exerciseId}`  | `videoUrl`             |
| Ingrediente de receta | `meals/{mealId}`          | array `ingredients`    |
| Plan alimenticio      | `meal_plans/{planId}`     | estructura anidada     |

## Reglas críticas

- `exerciseId` NUNCA cambiar — rompe historial de workouts
- Siempre actualizar `es` y `en` en campos traducibles
- URLs de imágenes: HTTPS obligatorio (iOS bloquea HTTP)
- Siempre incluir `updatedAt`
- Testear en desarrollo antes de producción

## Firebase de producción

```bash
firebase deploy --account wmarcelino@catalift.studio
```
