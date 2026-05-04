---
description: "Full mobile-feature audit: RN/Expo or native performance + security + test coverage + UX/a11y. 4 agents in parallel."
argument-hint: "<feature or screen>"
---

# /mobile-audit $ARGUMENTS

Auditing: **$ARGUMENTS**

Dispatch these 4 agents IN ONE MESSAGE (true parallel):

## Agent 1 — Mobile performance (`@code-reviewer`, sonnet)

```
Audit "$ARGUMENTS" — mobile performance specialty.
Stack: React Native / Expo / native (auto-detect from repo).
Look for: re-renders, FlatList vs ScrollView with .map, inline StyleSheet,
memory leaks (subscriptions/timers without cleanup), heavy bundles,
non-modular imports of large libs, image perf (resize, cachePolicy).
```

## Agent 2 — Security (`@security`, sonnet)

```
Audit "$ARGUMENTS" — OWASP Mobile Top 10.
Look for: AsyncStorage / Keychain misuse for sensitive data, deep-link
validation gaps, secrets shipped to client (service_role keys, API keys),
permissive backend rules (Firebase rules, RLS), insecure WebView config,
missing certificate pinning where relevant, biometric fallback risks.
```

## Agent 3 — Test coverage (`@test-engineer`, sonnet)

```
Audit "$ARGUMENTS" — test coverage gaps.
Stack: detect from repo (Jest, Vitest, Maestro, Detox).
Identify: happy paths without tests, edge cases (empty/error states),
missing fixture for async/network code, fragile snapshot tests,
missing component contract tests.
```

## Agent 4 — UX / accessibility (`@designer`, sonnet)

```
Audit "$ARGUMENTS" — UX + WCAG 2.2 AA + mobile design system.
Verify: loading / empty / error / offline states, design-token compliance,
touch targets ≥44pt (Apple HIG) or 48pt (Material), keyboard navigation,
focus rings, color contrast (4.5:1 normal, 3:1 large/UI),
prefers-reduced-motion respect, RTL readiness, screen-reader labels
(accessibilityLabel + accessibilityRole), reading order matches DOM.
```

## Output

```
## Mobile Audit: $ARGUMENTS

### 🔴 Blockers
### 🟠 Major
### 🟡 Minor

| Check | Status |
|---|---|
| Performance | PASS / WARN / FAIL |
| Security | PASS / WARN / FAIL |
| Test coverage | X% (target: ≥80% lines, ≥70% branches) |
| UX / a11y | PASS / WARN / FAIL |

### Verdict: READY | FIX FIRST | BLOCK
```

## Idempotency

Re-running on the same feature with no code changes produces the same audit. Side-effect free (read-only inspection).

## Chains

- `@architect` if findings reveal a structural issue (state management, navigation hierarchy).
- `@optimizer` if performance findings are detailed enough to need a profile.
- `@strategist` if UX gaps suggest the feature scope itself is wrong.
