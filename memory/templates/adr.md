# ADR-NNNN — <one-sentence title>

> Replace `NNNN` with a zero-padded sequence number. Replace `<title>` with a short noun phrase, kebab-cased in the filename.

**Status:** proposed | accepted | superseded by ADR-XXXX
**Date:** YYYY-MM-DD
**Deciders:** @owner, @reviewer
**Tags:** architecture | data | security | process

## Context

What is the situation that forces a decision? Be concrete:

- Numbers (latency, throughput, cost, team size).
- Constraints (deadline, dependency, regulation).
- What we already tried and why it didn't suffice.

A reader 6 months from now should be able to answer "why was this on the table at all?" from this section alone.

## Options considered

1. **Option A — <name>** — one-sentence summary.
2. **Option B — <name>** — one-sentence summary.
3. **Option C — <name>** — one-sentence summary.

(Always 2-4 options. One is "do nothing / status quo". If you only see one, you haven't thought hard enough.)

## Tradeoffs

| Dimension              | Weight | A   | B   | C   |
| ---------------------- | ------ | --- | --- | --- |
| Operational complexity | 3      |     |     |     |
| Cost (monthly)         | 2      |     |     |     |
| Failure recovery       | 3      |     |     |     |
| Time to ship           | 2      |     |     |     |
| Vendor lock-in         | 2      |     |     |     |

(Weights reflect what matters NOW, not in some hypothetical future.)

## Decision

Chosen option: **<A | B | C>**.

One paragraph stating the choice and the dominant reason. If a 6-month-future reader asked you "why?" this paragraph answers it without further context.

## Consequences

**Positive**

- ...

**Negative / accepted costs**

- ...

**Neutral / to monitor**

- Metric to watch: ... (threshold: ...)
- If the metric crosses the threshold → revisit this ADR.

## Failure modes

Top 3-5 ways this decision can fail. For each: detection signal + mitigation.

1. **Failure:** ... — **Detect:** ... — **Mitigate:** ...
2. **Failure:** ... — **Detect:** ... — **Mitigate:** ...

## Reversibility

- [ ] Two-way door (cheap to undo)
- [ ] One-way door (irreversible at scale, requires deliberate review here)

If one-way door: what's the off-ramp if we discover this was wrong?

## Related

- Supersedes: (ADR-XXXX) — if any.
- Superseded by: — (filled in if/when this ADR is replaced).
- Related patterns: `memory/patterns/<slug>.md`
