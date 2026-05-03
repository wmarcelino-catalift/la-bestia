---
description: "Lista todos los agentes disponibles, sus triggers y cómo invocarlos."
---

# /agents

## Agentes disponibles (12)

| Agent              | Modelo     | Cuándo                                                     | Invocar con                  |
| ------------------ | ---------- | ---------------------------------------------------------- | ---------------------------- |
| `architect`        | Opus 4.7   | Arquitectura, ADRs, diseño cross-module, tech selection    | `@architect <pregunta>`      |
| `cto-strategist`   | Opus 4.7   | Producto, negocio, build vs buy, RICE, roadmap             | `@cto-strategist <pregunta>` |
| `pm`               | Opus 4.7   | Sprint planning, backlog, OKRs, user stories, release plan | `@pm <feature>`              |
| `debugger`         | Opus 4.7   | Bug que no cede en 2 intentos, crash, stack trace          | `@debugger <error>`          |
| `test-engineer`    | Sonnet 4.6 | Implementar features con TDD, coverage, red-green-refactor | `@test-engineer <feature>`   |
| `code-reviewer`    | Sonnet 4.6 | Review post-cambio, SOLID, correctness, cognitive load     | `@code-reviewer`             |
| `security-auditor` | Sonnet 4.6 | Auth, payments, secrets, OWASP — obligatorio pre-merge     | `@security-auditor`          |
| `mobile-reviewer`  | Sonnet 4.6 | Pantallas RN/Expo, re-renders, FlatList, memory leaks      | `@mobile-reviewer`           |
| `devops`           | Sonnet 4.6 | EAS builds, Firebase deploy, CI/CD, emuladores             | `@devops <tarea>`            |
| `ux-reviewer`      | Sonnet 4.6 | UX, brand Alanis Fit, modals, empty/loading states         | `@ux-reviewer`               |
| `content-manager`  | Sonnet 4.6 | Firestore content: meal plans, ejercicios, creator config  | `@content-manager`           |
| `data-engineer`    | Sonnet 4.6 | Schema design, queries, migrations, Firestore/Supabase     | `@data-engineer`             |

## Teams

| Team         | Líder              | Cuándo activar                                  |
| ------------ | ------------------ | ----------------------------------------------- |
| **STRATEGY** | `cto-strategist`   | Nueva feature, roadmap, decisión arquitectónica |
| **DELIVERY** | `test-engineer`    | Implementación, PR, código nuevo                |
| **SAFETY**   | `security-auditor` | Pre-merge, auth/payments, deploy                |
| **DOMAIN**   | (por contexto)     | Firestore content, UX, data layer               |

## Dispatch automático

El routing se hace por keywords en el prompt (ES + EN) + reglas de CLAUDE.md.
No necesitás escribir `@agent` explícitamente — el principal lo decide.

Para forzar un agente específico: `@architect diseñá el schema para X`

## Agentes en paralelo

Para tareas con dimensiones independientes:

```
/parallel-research cómo mejorar el sistema de caché de videos
/mobile-audit pantalla de workout
/bug-hunt crash en start-workout
```

## Inter-agent memory

Los agentes leen y escriben `agent-memory/<name>/MEMORY.md`.
Flujo principal: architect → test-engineer → code-reviewer → security-auditor

## Ver actividad reciente

```bash
tail -f .claude/logs/live-activity.jsonl | jq -r '"[\(.ts[11:19])] \(.event) \(.agent)"'
```
