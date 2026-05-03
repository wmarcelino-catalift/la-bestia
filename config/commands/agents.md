---
description: "Lista todos los agentes disponibles, sus triggers y cómo invocarlos."
---

# /agents

## Agentes disponibles

| Agent              | Modelo     | Cuándo usarlo                                                   | Invocar con                  |
| ------------------ | ---------- | --------------------------------------------------------------- | ---------------------------- |
| `architect`        | Opus 4.7   | Arquitectura, ADRs, diseño de sistemas, decisiones cross-module | `@architect <pregunta>`      |
| `cto-strategist`   | Opus 4.7   | Producto, negocio, build vs buy, roadmap, RICE                  | `@cto-strategist <pregunta>` |
| `debugger`         | Opus 4.7   | Bug que no cede en 2 intentos, crash, stack trace               | `@debugger <error>`          |
| `devops`           | Sonnet 4.6 | EAS builds, Firebase deploy, CI/CD, emuladores                  | `@devops <tarea>`            |
| `code-reviewer`    | Sonnet 4.6 | Review post-cambio, calidad, SOLID                              | `@code-reviewer`             |
| `security-auditor` | Sonnet 4.6 | Auth, payments, secrets, OWASP — obligatorio antes de merge     | `@security-auditor`          |
| `test-engineer`    | Sonnet 4.6 | Implementar features con TDD, coverage                          | `@test-engineer <feature>`   |

## Routing automático

El hook `route-prompt.sh` detecta keywords y sugiere el agent correcto.
Verás: `[LA BESTIA] → Escribí @agent <pregunta> para delegarlo`

## Agentes en paralelo

Para tareas con dimensiones independientes usá `/parallel-research`:

```
/parallel-research cómo mejorar el sistema de caché de videos
```

Esto despacha 3-5 subagents simultáneos y sintetiza los resultados.

## Shells internas

Los "N shells" que ves en el statusline del CLI son procesos bash internos de Claude
(reads, greps, commands). No son tus terminales — son invisibles y se limpian solos.

## Ver agentes recientes

El statusline `🐺 La Bestia · debugger,devops` muestra los últimos agentes usados en la sesión.
