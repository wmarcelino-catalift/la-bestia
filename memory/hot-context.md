# Project hot-context — catalift-app

> 200 tokens max. Lo que cualquier sesión necesita saber antes de leer código.

## Stack

- React Native / Expo (mobile-first)
- Firebase (Firestore DB + Cloud Functions + Storage)
- Supabase (auth + DB) — usado en paralelo con Firebase
- Resend (email)

## Branch actual

`wilser-video-cache-and-modals` — features de cache de video y modales.

## Multi-creator pattern

La app soporta múltiples creators. El creator activo se selecciona con `EXPO_PUBLIC_CREATOR_ID`.

| Creator | ID | EAS profiles |
|---|---|---|
| CataLift (default) | *(sin var)* | development, preview, production |
| Alanis Sánchez | `alanis_sanchez` | alanis-development, alanis-preview, alanis-production, alanis-simulator |

Para correr localmente con un creator específico:
```bash
# PowerShell
$env:EXPO_PUBLIC_CREATOR_ID="alanis_sanchez"; npx expo start --lan
```

Firebase account de producción: `wmarcelino@catalift.studio`

## Reglas críticas

- No tocar `~/.claude/` global desde acá — config es project-local en `.claude/`.
- Branches: `feat/`, `fix/`, `refactor/`. Nunca commit a `main` directo.
- Auth/payments → security-auditor agent obligatorio antes de mergear.

## Último commit

`a10a844` — Workout complete: drop local formatVolume, reuse shared helper from unitService

## Pendientes

- (agregar acá lo que esté in-flight)
