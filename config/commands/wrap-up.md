---
description: "Closes the session with a structured summary. Updates memory/hot-context.md with what was implemented, what's pending, and external actions."
---

# /wrap-up

Generate a session summary and update project memory.

## Plan (read-only)

1. **REVIEW** the recent conversation:
   - What was implemented and committed?
   - What was investigated but not finished?
   - What requires action outside the code (config systems, app stores, content, third parties)?

2. **CLASSIFY** into 3 buckets:
   - ✅ **Implemented** — in code, committed
   - ⏳ **Pending** — identified but not started or in progress
   - ⚠️ **External action** — outside the codebase

3. **DETECT one-way doors** (auto-ADR proposal, v3.1):
   The principal scans the session for language matching:
   - "lockean" / "locked" / "irreversible"
   - "one-way door"
   - "from now on we" / "decidimos usar"
   - "schema change" / "migration" / "API breaking"
   - "stack: <choice>" / "elegimos <X>"

   For each match, propose an ADR draft using `memory/templates/adr.md`:

   ```
   Detected one-way door in this session:
     "<quoted phrase from conversation>"

   Suggested ADR: memory/decisions/<NNNN>-<slug>.md

   Should I draft the ADR now? [yes / no / later]
   ```

   On `yes`: principal generates the ADR file from template + session context. Operator reviews + accepts before save.

4. **DRAFT** the update for `memory/hot-context.md` (do not write yet):
   - `## Pending` — replace with updated list
   - `## Recent decisions` — append today's date with one-line decisions (link to ADRs proposed in step 3)
   - Keep total file ≤ 200 tokens (truncate older entries to ADRs).

## Apply (gated on operator confirmation)

Only after the operator confirms the draft above:

1. Write the new `memory/hot-context.md`.
2. If any decision was a one-way door, prompt the operator to create an ADR with: `cp memory/templates/adr.md memory/decisions/<NNNN>-<slug>.md`.

## Output format

```
## Wrap-up — YYYY-MM-DD

### ✅ Implemented this session
- [list with file/commit if applicable]

### ⏳ Pending (next session)
- [list ordered by priority]

### ⚠️ Requires external action
- [list with owner if known]

### 📁 Key files modified
- [list of the most important]

### 📝 Proposed memory update
[draft of the hot-context.md replacement — operator approves or edits]
```

## Idempotency

Running `/wrap-up` twice in the same session produces the same plan (same draft). Apply step is gated, so re-running without confirmation is safe.

## Chains

- `@cto-strategist` if any pending item is a one-way-door decision.
