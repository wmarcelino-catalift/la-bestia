# memory/lessons/

> **Append-only loop**: each non-trivial bug, surprise, or workaround that
> happens twice gets a lesson note here. The harness reads from these to
> avoid repeating itself across sessions.

## Why this exists

ADRs (`memory/decisions/`) capture **decisions**: deliberate, forward-looking, often architectural.
Patterns (`memory/patterns/`) capture **reusable solutions**: code-shaped, generalizable.
**Lessons** capture **learnings from incidents and friction**: backward-looking, behavioral, project-specific.

The three are complementary — none of them substitute for the others.

## When to write a lesson

Trigger on any of these:

| Signal                                          | Lesson worthy?                                    |
| ----------------------------------------------- | ------------------------------------------------- |
| Bug fix that took > 30 min                      | Yes — capture the root cause + the symptom, both. |
| Same workaround applied twice                   | Yes — promote to lesson. Third time → pattern.    |
| Surprising behavior of a tool / library / agent | Yes — document the gotcha.                        |
| Test was flaky and the fix wasn't obvious       | Yes — root cause + how to detect it next time.    |
| Trivial typo / one-shot config tweak            | No — leave it in commit history.                  |
| Architectural decision                          | No — write an ADR instead.                        |
| Generalizable code shape                        | No — write a pattern instead.                     |

## Filename convention

```
YYYY-MM-DD-<slug>.md
```

Examples:

- `2026-05-04-flaky-test-process-leak.md`
- `2026-05-04-pnpm-workspace-resolution.md`
- `2026-05-05-react-effect-stale-closure.md`

## Template

See [`../templates/lesson-template.md`](../templates/lesson-template.md).
Skeleton:

```markdown
# <One-line title — what surprised you>

- **Date**: YYYY-MM-DD
- **Context**: <one paragraph — what were you doing>
- **Symptom**: <what did you see>
- **Root cause**: <what was actually wrong>
- **Fix**: <minimal change that worked>
- **Detection next time**: <how would you catch this earlier>
- **Tags**: <comma-separated, e.g. flaky-test, race, typescript>
```

## How the harness uses lessons

- `restore-context.sh` lists the 5 most recent lessons on session resume / compact.
- `@debugger`, `@code-reviewer`, `@test-engineer` read the lessons index before starting non-trivial work (3-layer rule).
- The `lessons-loop` skill prompts you to write one when a debugging session > 30 min closes.

## Promotion path

```
incident
   ↓
  lesson  (memory/lessons/)
   ↓ (if reusable code shape)
  pattern (memory/patterns/)
   ↓ (if architectural decision)
   ADR    (memory/decisions/)
```

Lessons are the cheapest layer — no review gate, just write.
Patterns and ADRs require more rigor.
