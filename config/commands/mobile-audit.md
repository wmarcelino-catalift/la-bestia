---
description: "Auditoría completa de un feature/pantalla: RN performance + security + tests + UX. 4 agentes en paralelo."
argument-hint: "<feature o pantalla>"
---

# /mobile-audit $ARGUMENTS

Auditando: **$ARGUMENTS**

Dispatchá estos 4 agentes EN UN SOLO MENSAJE:

## Agent 1 — RN Performance (mobile-reviewer, sonnet)

```
Auditá "$ARGUMENTS" — React Native performance.
Repo: catalift-app/frontend. Stack: RN + Expo + TypeScript.
Buscá: re-renders, FlatList vs ScrollView, StyleSheet inline, memory leaks, listeners sin cleanup.
```

## Agent 2 — Security (security-auditor, sonnet)

```
Auditá "$ARGUMENTS" — OWASP mobile.
Buscá: AsyncStorage con datos sensibles, deep links sin validar,
Supabase service_role en cliente, Firebase rules abiertas, SecureStore usage.
```

## Agent 3 — Test coverage (test-engineer, sonnet)

```
Auditá "$ARGUMENTS" — gaps de test coverage.
Stack: Jest + React Native Testing Library + jest-expo.
Identificá: happy path sin test, edge cases, mocks faltantes Firebase/Supabase.
```

## Agent 4 — UX / Brand (ux-reviewer, sonnet)

```
Auditá "$ARGUMENTS" — Alanis Fit brand y UX.
Verificá: loading/empty/error states, idioma es/en, THEME colors,
pill buttons, touch targets 44pt, textos empoderadores.
```

## Output

```
## Mobile Audit: $ARGUMENTS

### 🔴 Blockers
### 🟠 Majors
### 🟡 Mejoras

| Check | Estado |
|---|---|
| RN Performance | PASS / WARN / FAIL |
| Security | PASS / WARN / FAIL |
| Test coverage | X% |
| Brand compliance | PASS / WARN / FAIL |

### Veredicto: READY | FIX FIRST | BLOCK
```
