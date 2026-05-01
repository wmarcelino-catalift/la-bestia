---
description: "Quality gates pre-merge: tests + linter + secrets check + review chain. Si todo pasa, conventional commit + PR description."
---

# /ship-it

Activá el skill `ship-it` y ejecutá la quality gate completa.

## Pasos secuenciales (no paralelos — orden importa)

1. **Estado** — `git status` + `git diff --stat` para entender el scope.
2. **Tests** — correr la suite relevante para los archivos cambiados (no toda si no es necesario).
3. **Linter + type checker** — según el stack.
4. **Secret scan** — grep por patterns conocidos en el diff.
5. **Migration check** — si hay migration nueva, ¿tiene `down`?
6. **Review chain**:
   - Dispatch @code-reviewer en el diff completo.
   - Si tocó auth/payments/PII → dispatch @security-auditor.
   - Si va a producción → checklist de las 5 preguntas SRE.
7. **Si TODO pasa**:
   - Generar conventional commit message.
   - Crear branch si estás en main.
   - `git add` específico (no `git add .`).
   - `git commit` con HEREDOC.
   - Si el usuario lo pide: `git push` + `gh pr create` con description.
8. **Si ALGO falla**:
   - STOP. Mostrar exactamente qué falló y por qué.
   - Sugerir el fix más chico.
   - NO commitear hasta resolver.

## Output

```
## Ship-it Report

### Pre-flight checks
[ ] Tests: [PASS / FAIL detalles]
[ ] Linter: [PASS / FAIL]
[ ] Type check: [PASS / FAIL]
[ ] Secrets: [CLEAN / FOUND]
[ ] Migration reversible: [N/A / PASS / FAIL]

### Review chain
- code-reviewer: [APPROVE / CHANGES / BLOCK]
- security-auditor: [N/A / APPROVE / CHANGES / BLOCK]

### Veredicto
[SHIP IT 🚀 / BLOCKED]

### Si shipping:
**Commit**: `<type>(<scope>): <desc>`
**Branch**: `<branch>`
**PR description**: [generada]
```
