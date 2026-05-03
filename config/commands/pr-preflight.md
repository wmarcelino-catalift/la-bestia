---
description: "Pre-flight antes de crear PR: git state, ahead/behind, TypeScript, secrets, draft description."
argument-hint: "[base-branch]"
---

# /pr-preflight $ARGUMENTS

Base branch: $ARGUMENTS (default: `main`)

## Checks

### 1. Git state

```bash
git fetch origin ${ARGUMENTS:-main}
git log origin/${ARGUMENTS:-main}..HEAD --oneline
git log HEAD..origin/${ARGUMENTS:-main} --oneline | wc -l
git status --short
```

**Si ahead=0**: nada que mergear. **Si behind>50**: rebase recomendado. **Si no hay common ancestor**: branch creado desde ZIP — crear branch limpio desde main.

### 2. TypeScript

```bash
cd frontend && npx tsc --noEmit 2>&1 | head -30
```

### 3. Secrets

```bash
git diff origin/${ARGUMENTS:-main}...HEAD -- . | grep -E "sk-ant-|sk_live_|AKIA[A-Z0-9]{16}|service_role"
```

Matches → **BLOCK**.

### 4. Diff summary

```bash
git diff --stat origin/${ARGUMENTS:-main}...HEAD | tail -5
```

## Output

```
## PR Pre-flight — {branch} → {base}

| Check | Estado |
|---|---|
| Commits ahead | X |
| Commits behind | X |
| TypeScript | PASS / FAIL |
| Secrets | CLEAN / FOUND |
| Common ancestor | YES / NO |

### Verdict: READY | FIX FIRST | BLOCK

### PR draft
[título + body basado en los commits]
```
