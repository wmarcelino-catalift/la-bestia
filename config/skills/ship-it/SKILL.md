---
name: ship-it
version: 2.0.0
description: "Pre-merge quality gates: tests pass, linter clean, no secrets, migrations reversibles, conventional commit, code-reviewer + security-auditor approved. Auto-activate when prompt contains 'commit', 'PR', 'merge', 'ship', 'deploy', 'pull request', 'push'."
triggers: [commit, PR, merge, ship, deploy, "pull request", push]
---

# Ship It — Quality Gates

Antes de cada commit/push/merge a una rama protegida, esta checklist es obligatoria.
Si UNA falla → STOP. No commit hasta resolver.

## Pre-flight checklist

```
[ ] 1. Tests pasan (unit + integration relevantes)
[ ] 2. Linter limpio (eslint/ruff/mypy/clippy según stack)
[ ] 3. Type checker limpio (tsc/mypy/pyright)
[ ] 4. Sin secretos hardcoded (grep + hook ya bloqueó writes a .env)
[ ] 5. Migración tiene up Y down probados (si aplica)
[ ] 6. Conventional commit message (feat|fix|refactor|chore|docs|test(scope): desc)
[ ] 7. code-reviewer agent: sin BLOCKERS
[ ] 8. Si tocó auth/payments/PII → security-auditor: APPROVE
[ ] 9. Si va a producción → reliability check (las 5 SRE preguntas)
[ ] 10. Diff size sane (<500 LOC idealmente; si más, justificar)
```

## Comandos por stack

### Node/TS

```bash
npm test && npm run lint && npx tsc --noEmit
grep -rEn "sk-ant-|sk_live_|AKIA[A-Z0-9]{16}|BEGIN PRIVATE KEY" src/ && exit 1 || echo "no secrets"
```

### Python

```bash
ruff check . && mypy . && pytest
grep -rEn "sk-ant-|sk_live_|AKIA[A-Z0-9]{16}|BEGIN PRIVATE KEY" . && exit 1 || echo "no secrets"
```

### Go

```bash
go vet ./... && go test ./... && golangci-lint run
```

### Rust

```bash
cargo clippy -- -D warnings && cargo test
```

## Commit message format

```
<type>(<scope>): <description>

[optional body explaining WHY, not what]

[optional footer: BREAKING CHANGE, Refs #123, Co-Authored-By]
```

Tipos válidos: `feat`, `fix`, `refactor`, `chore`, `docs`, `test`, `perf`, `style`, `build`, `ci`.

Ejemplos buenos:

```
feat(auth): add JWT refresh rotation with 7-day expiry
fix(api): prevent N+1 query by eager loading user.posts
refactor(db): extract connection pooling to shared config
```

Ejemplos a rechazar:

```
fix: update code        ← qué code, qué fix
feat: add feature       ← cuál feature
chore: stuff            ← stuff no es informativo
WIP                     ← never to a protected branch
```

## PR description template

```
## What
[1-3 bullets de qué cambia]

## Why
[Por qué es necesario. Link a issue/ADR si aplica.]

## How
[Approach técnico, decisiones clave]

## Test plan
- [ ] Caso happy path
- [ ] Edge case X
- [ ] Regression de Y

## Risk
[LOW | MEDIUM | HIGH] — [una frase]

## Rollback
[Comando o pasos exactos]
```

## Anti-patterns

- `git commit -m "fix"` (sin scope ni descripción real)
- Commit con tests rojos "voy a fixearlo en el siguiente"
- Squash merge sin conventional commit final
- PR de >2000 LOC sin justificación
- `--no-verify` para saltearse hooks
