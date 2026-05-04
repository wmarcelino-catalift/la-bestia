---
description: "Full feature pipeline (Discover → Define → Develop → Deliver) with the right agents at each phase. Parallel within phases, Plan-Apply ritual between phases. Activates the flow-feature skill."
argument-hint: "<feature description>"
---

# /flow $ARGUMENTS

Activates the **flow-feature** skill. Use this when building a non-trivial feature end-to-end.

The skill orchestrates 12 specialized agents through 4 phases (Double Diamond), parallelizing within each phase and halting at phase boundaries for your approval.

## When to use

- Feature touches 2+ surfaces (UI + backend + data, or auth + payments + UI).
- Anything labeled Medium or Large complexity.
- Anything you'd want a senior team's full review on (strategist + architect + security + designer + reviewer).

## When NOT to use

- Trivial change (typo, rename, single-file edit) → just edit it.
- Pure debugging → `/deep-debug "<bug>"`.
- Pure research → `/parallel-research "<question>"`.
- Already-implemented code, ready to ship → `/ship-it`.

## What it does (in one diagram)

```
You: /flow "build OAuth + RBAC for B2B accounts"
        │
        ▼
Triage (1 question): Size + Touches → routing keys
        │
        ▼
Phase 1 — DISCOVER (parallel)
  @strategist · @mentor · @architect · @security
  Synthesize → ▶ HALT for operator: proceed/refine/stop
        ▼
Phase 2 — DEFINE (parallel, gated by Touches)
  @architect (always) + @data-engineer + @security + @designer + @devops
  Synthesize → ADR draft → ▶ HALT
        ▼
Phase 3 — DEVELOP (sequential — TDD)
  @test-engineer red → ▶ HALT (tests red for right reason?)
  @test-engineer green
  @code-reviewer mid-review (Medium/Large)
  @test-engineer refactor
        ▼
Phase 4 — DELIVER (parallel)
  @code-reviewer · @security · @optimizer · @tech-writer · @mentor
  Aggregate findings → CHANGELOG + ADR → ready for /ship-it
        ▼
Output ready for /ship-it
```

## Plan-Apply ritual

Between phases, the principal Claude pauses. You see:

- A **synthesis** of what just happened.
- Specific findings (severity-tagged).
- A choice: `proceed / revise / stop`.

Nothing irreversible happens without your `proceed`. The discipline IS the value.

## Idempotency

Re-running `/flow` on the same feature with the same triage answers produces the same plan. Phase 3 (Develop) is gated by your branch's git state — re-running won't re-implement what's already committed.

## Cost note

`/flow` is more expensive than direct agent calls because of parallel fan-out. Typical costs:

- Small (skip Discover): ~3-5 agent invocations.
- Medium: ~8-12 agent invocations across all phases.
- Large: ~15-20 agent invocations.

The `token-saver` skill auto-activates when context > 60% to mitigate.

## Output

Final output is a synthesis ready to feed into `/ship-it`. You'll have:

- ADR drafted in `memory/decisions/<NNNN>-<slug>.md`.
- Tests + implementation committed (in your branch).
- CHANGELOG entry under `[Unreleased]`.
- Severity-tagged findings list (any 🔴 was looped back to Develop).

## Chains

The skill chains agents internally per phase. You don't pick agents — the skill does, based on your Triage answers.

---

## Quick reference

| Use                                      | Instead of                                               |
| ---------------------------------------- | -------------------------------------------------------- |
| `/flow "<feature>"`                      | typing 4 separate commands or 12 separate `@agent` calls |
| `/flow "<small feature>"` (size = Small) | direct `@architect` + `@test-engineer`                   |
| `/flow "<bug investigation>"`            | `/deep-debug` (correct tool for debugging)               |
| `/flow "<research question>"`            | `/parallel-research` (correct tool for research)         |
