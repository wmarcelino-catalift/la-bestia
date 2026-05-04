# <one-line title — what surprised you>

- **Date**: YYYY-MM-DD
- **Author**: <agent name or operator>
- **Tags**: <comma-separated, e.g. flaky-test, race, typescript>

## Context

<one paragraph — what were you doing when this came up>

## Symptom

<exactly what you saw — error message, behavior, log line>

```text
<paste the actual symptom: stack trace / error / failing assertion>
```

## Investigation

<bullets — what you tried, what worked, what didn't>

- ...
- ...

## Root cause

<the underlying issue — not the symptom>

## Fix

<minimal change that worked>

```diff
- <bad line>
+ <good line>
```

## Detection next time

<how would a future agent / human catch this earlier>

- Lint rule? Test? Hook? Pattern in `memory/patterns/`?

## Related

- ADRs: <links if any>
- Patterns: <links if any>
- Lessons: <prior lessons that this updates or extends>
