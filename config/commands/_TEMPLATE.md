# /<command-name>

> One-line summary. Triggered by `/<command-name>` in a Claude Code session.

## When to run

Concrete: what state of the world makes this command appropriate?

## Inputs

- `$ARGUMENTS` — `<expected shape>` (or "none").
- Implicit context: git branch, recent commits, modified files.

## Plan (read-only)

1. Inspect: <what files / git state / log streams to read>.
2. Analyze: <what to compute>.
3. Produce: <markdown structure of the output>.

A `Plan` section MUST be read-only. Side effects belong below.

## Apply (gated)

If the operator confirms with explicit "yes" / "go" / equivalent, then:

1. <side effect 1>.
2. <side effect 2>.

Otherwise, halt and surface the plan.

## Idempotency

Running this command twice with identical inputs MUST produce identical output (same plan, same applied state). If a step is non-idempotent, document why and provide an `--undo` path.

## Chains

- `@<agent>` when `<condition>`.
