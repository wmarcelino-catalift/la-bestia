# Eval — `debugger`

Snapshot evaluation for the `debugger` agent. Run via `bash evals/run.sh debugger`.

## How this works

Each canonical entry has:
1. **Prompt** — exact text the operator would send.
2. **Setup** — repo state / files / fixtures the agent assumes.
3. **Expected shape** — required sections, severity tags, key terms.
4. **Anti-shape** — things that MUST NOT appear (drift markers).

The eval is **soft signal** in CI (informational, not blocking). LLM outputs vary; we look at semantic drift, not byte-equality.

## Status

This file is a **scaffold**. Backfill the 3-5 canonical prompts during the first real session that uses this agent. Capture the actual output as the golden, then prune to essentials.

## Canonical 1 — (TODO: backfill)

**Prompt:**

```
(operator prompt that should trigger @debugger)
```

**Setup:**

- (repo state, fixture files, git branch)

**Expected shape:**

- Section `## <name>` present
- Severity tags 🔴/🟠/🟡/🟢 if reviewer-style agent
- Output contract sections per `config/agents/debugger.md`

**Anti-shape:**

- No "I'll need more context" without specific clarification
- No code blocks without language hints
- No references to deleted agents (cto-strategist, security-auditor, etc.)

## Canonical 2 — (TODO)

## Canonical 3 — (TODO)

## Versioning

| Version | Date | Change |
|---|---|---|
| 0.1.0 | 2026-05-04 | Scaffold created (canonicals are TODO). |
