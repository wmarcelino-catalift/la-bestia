---
description: "Cierra la sesión con un resumen estructurado. Actualiza hot-context.md y vault/HOT.md con pendientes, implementado y acciones externas."
---

# /wrap-up

Generá un resumen de esta sesión y actualizá la memoria del proyecto.

## Pasos

1. **REVISAR** la conversación reciente:
   - ¿Qué se implementó y se commiteó?
   - ¿Qué se investigó pero no se terminó?
   - ¿Qué requiere acción fuera del código (Firestore, App Store, contenido)?

2. **CLASIFICAR** en 3 buckets:
   - ✅ **Implementado** — en código, commiteado
   - ⏳ **Pendiente** — identificado pero no iniciado o en progreso
   - ⚠️ **Acción externa** — Firestore, App Store, diseño, contenido

3. **ACTUALIZAR** `memory/hot-context.md`:
   - Sección `## Pendientes` — reemplazar con lista actualizada
   - Sección `## Último commit` — hash más reciente (`git log -1 --oneline`)

4. **ACTUALIZAR** `.claude/vault/HOT.md`:
   - Agregar entrada en `## Última semana` con fecha ISO y 1-line summary

5. **OUTPUT** el resumen al usuario.

## Formato de output

```
## Wrap-up — {YYYY-MM-DD}

### ✅ Implementado esta sesión
- [lista con archivo/commit si aplica]

### ⏳ Pendiente (próxima sesión)
- [lista ordenada por prioridad]

### ⚠️ Requiere acción externa
- [lista con responsable si se sabe]

### 📁 Archivos modificados clave
- [lista de los más importantes]
```
