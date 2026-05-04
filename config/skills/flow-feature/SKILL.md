---
name: flow-feature
version: 1.1.0
description: "Orchestrate a non-trivial feature end-to-end: Discover → Define → Develop → Deliver. Parallel fan-out within phases, Plan-Apply ritual between phases. Auto-trigger on 'flow', 'pipeline', 'full feature', 'double diamond', 'build feature'."
triggers:
  [
    flow,
    pipeline,
    "full feature",
    "double diamond",
    "build feature",
    "from scratch",
  ]
---

# Skill: flow-feature

> **Loaded on trigger.** When this skill is active, the principal Claude becomes an orchestra conductor — it dispatches agents in parallel within each phase, halts at phase boundaries for operator approval, and synthesizes per-phase outputs.

## Mission

Take a non-trivial feature request and run it through a disciplined four-phase pipeline (Double Diamond), parallelizing where independent and gating between phases. The principal does **not** implement directly during this skill — it orchestrates.

## When to use

- Feature with multiple components (UI + backend + data + ops).
- Anything touching auth, payments, regulated data.
- Anything the operator labels "Medium" or "Large" complexity.
- Anything that would benefit from 2-4 specialist perspectives in parallel.

## When NOT to use

- Trivial change (typo, rename, single-file edit) — just edit.
- Pure debugging — use `/deep-debug` or `@debugger` directly.
- Pure research with no implementation — use `/parallel-research`.
- Shipping already-implemented code — use `/ship-it`.

---

## Phase banners (mandatory)

The principal MUST print a phase banner at the start of each phase, before dispatching agents. This keeps the operator oriented during long pipelines.

Banner format (stdout text, **not** a UI artifact):

```
═══════════════════════════════════════════════════════
  PHASE <n>/4 — <NAME> · <mode> (<m> agents)
═══════════════════════════════════════════════════════
  → @<agent-1>
  → @<agent-2>
  ...

  [synthesizing...]
```

Where `<mode>` is `parallel fan-out` or `sequential (TDD)`.

Between phases, print a halt banner asking for operator approval:

```
───────────────────────────────────────────────────────
  PHASE <n> COMPLETE · awaiting operator decision
───────────────────────────────────────────────────────
  Synthesis above. Choose: [proceed / refine / stop]
```

This is plain text — no emoji banners, no HTML, no HUD. Aligned with ADR-0002 (no UI).

---

## Phase 0 — Triage (60 seconds)

The principal MUST run this first. Use `AskUserQuestion` (single multi-select question) to capture:

```
Q: What is the scope and surface area of "<feature>"?

  Size:
    [ ] Small  — single component, single team, <1 day work
    [ ] Medium — 2-4 components, multiple files, <1 week work
    [ ] Large  — system-level, multiple subsystems, ≥1 week work

  Touches (multi-select):
    [ ] Auth / identity
    [ ] Payments / financial
    [ ] PII / regulated data (GDPR, HIPAA, PCI)
    [ ] Public API
    [ ] Data schema / migrations
    [ ] UI / UX surfaces
    [ ] Mobile (RN / Expo / native)
    [ ] Infrastructure / deploy / CI
    [ ] None of the above
```

Use the answers as routing keys for phases 1-4 (which agents to dispatch).

**Skip rules**:

- `Small`: skip Phase 1 (Discover); start at Phase 2 with `@architect` only.
- `Medium`: full pipeline, 2-3 agents per parallel phase.
- `Large`: full pipeline, 3-5 agents per parallel phase, **mandatory `@mentor`** in Discover and Deliver.

---

## Phase 1 — DISCOVER (parallel)

**Goal**: validate the bet before designing. RICE / JTBD / pre-mortem.

Dispatch in **ONE message with multiple Task tool calls** (true parallel):

| Always        | When                                           |
| ------------- | ---------------------------------------------- |
| `@strategist` | always (RICE, JTBD, working-backwards PR-FAQ)  |
| `@mentor`     | size = Large (pre-mortem + 9-lens stress test) |
| `@architect`  | Touches contains "Public API" or "Data schema" |
| `@security`   | Touches contains "Auth", "Payments", or "PII"  |

After fan-out completes, the principal:

1. **Synthesizes** — produce a `## Discover summary` with:
   - The bet (what we're wagering, expected value).
   - Top 3 risks from the pre-mortem.
   - Recommended scope (fully-loaded vs MVP).
2. **Halts** — ask the operator: `Proceed to Define? [yes / refine / stop]`.
3. **Apply** only after explicit operator confirmation.

---

## Phase 2 — DEFINE (parallel)

**Goal**: produce ADR + design docs ready for implementation.

Dispatch (gated by Touches answers):

| Agent            | When                                                                       |
| ---------------- | -------------------------------------------------------------------------- |
| `@architect`     | always (ADR draft, system design, options matrix)                          |
| `@data-engineer` | Touches contains "Data schema"                                             |
| `@security`      | Touches contains "Auth", "Payments", "PII", or "Public API" (threat model) |
| `@designer`      | Touches contains "UI / UX surfaces" or "Mobile"                            |
| `@devops`        | Touches contains "Infrastructure / deploy / CI"                            |

Principal then:

1. **Synthesizes** — produce a `## Define summary` with:
   - ADR draft (ready to drop into `memory/decisions/<NNNN>-<slug>.md`).
   - Cross-agent contradictions (if architect says X and security says Y, surface and resolve).
   - Open questions still requiring research.
2. **Halts** — `Proceed to Develop? [yes / revise / stop]`.

If revising: re-run only the agents whose output the operator wants changed. Keep what's stable.

---

## Phase 3 — DEVELOP (sequential — TDD requires order)

**Goal**: implement with red-green-refactor discipline.

This phase is **sequential**, not parallel — TDD's order is the value.

```
Step 1 — Red:    @test-engineer "write failing tests for <feature> per the ADR"
                 ↓
                 Principal halts: "Tests are red for the right reason. Proceed? [yes / iterate]"
                 ↓
Step 2 — Green:  @test-engineer "minimal code to pass"
                 ↓
Step 3 — Mid-review (size = Medium or Large only):
                 @code-reviewer "review the diff so far; severity tags"
                 ↓
                 If 🔴 found: loop back to test-engineer with the findings.
                 ↓
Step 4 — Refactor: @test-engineer "refactor under green"
```

Principal halts after each green-cycle for operator confirmation when the change touches > 5 files.

---

## Phase 4 — DELIVER (parallel)

**Goal**: review, document, ship-ready.

Dispatch in **ONE message** (true parallel):

| Agent            | When                                                     |
| ---------------- | -------------------------------------------------------- |
| `@code-reviewer` | always (final review with severity tags)                 |
| `@security`      | Touches contains "Auth", "Payments", "PII", "Public API" |
| `@optimizer`     | size = Large OR Touches contains "Public API" / hot path |
| `@tech-writer`   | always (README + CHANGELOG + ADR finalization)           |
| `@mentor`        | size = Large (final disagree-and-commit pass)            |

Principal then:

1. **Aggregates** — produce a `## Deliver summary` with:
   - Findings ordered by severity (🔴 first).
   - All blocker findings → loop back to Phase 3.
   - CHANGELOG entry draft.
   - ADR ready to commit.
2. **Hand-off** — output should be ready to paste into `/ship-it` for the merge ritual.

---

## Output contract

The skill always produces these sections, in order:

```
## Triage
- Size: [...]
- Touches: [...]

## Phase 1 — Discover
- Agents dispatched: [...]
- Summary: [...]
- Operator decision: [proceed / refine / stop]

## Phase 2 — Define
- Agents dispatched: [...]
- ADR draft: [link or inline]
- Contradictions resolved: [...]
- Operator decision: [...]

## Phase 3 — Develop
- Tests added: [files]
- Implementation: [files]
- Mid-review findings (if any): [...]

## Phase 4 — Deliver
- Findings (severity-ordered): [...]
- CHANGELOG draft: [...]
- ADR finalized: [...]
- Ready for /ship-it: yes / no
```

---

## Anti-patterns this skill rejects

- Skipping the triage to "save time" (you'll skip Phase 1 incorrectly and miss a 🔴).
- Dispatching all 12 agents on a Small change (cost waste, signal dilution).
- Not halting between phases (the discipline IS the value).
- Implementing directly in the principal context instead of dispatching to `@test-engineer`.
- Ignoring contradictions between specialists in Phase 2 (they need explicit resolution, not "we'll figure it out").
- Skipping Phase 4 because "the tests pass" (tests passing ≠ shippable).

---

## Parallelism semantics (important)

When this skill says "dispatch in ONE message", it means:

```
The principal sends a SINGLE assistant message containing N Task tool calls.
Claude Code's runtime executes them concurrently.
Each subagent runs in an isolated context (does not see siblings' output).
The principal receives all N summaries and synthesizes.
```

This is real parallelism (typically 2-3x faster than serial dispatch). It is also more expensive in tokens — each parallel agent loads its context independently. The token-saver skill auto-loads if context > 60% to mitigate.

---

## Cost discipline

The skill activates `token-saver` automatically when:

- Phase 4 fan-out includes 4+ agents.
- Total session context > 60%.

Cost is logged via the standard `agents.jsonl` audit log; statusline shows `$` per session.

---

## Versioning

| Version | Date       | Change                                                                                |
| ------- | ---------- | ------------------------------------------------------------------------------------- |
| 1.1.0   | 2026-05-04 | Mandatory phase banners (stdout text, no UI) for operator orientation.                |
| 1.0.0   | 2026-05-03 | Initial release with v2.0 agent set (12 agents) and Plan-Apply ritual between phases. |
