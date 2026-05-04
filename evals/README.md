# Evals

> Snapshot evals for the agents shipped in `config/agents/`.
> Goal: detect prompt regressions, not score absolute quality.

---

## Why snapshot evals

LLM outputs vary across temperatures, model versions, and time. Strict equality is the wrong gate. We use **human-curated golden outputs** (what we'd be happy to see) and produce a diff for review. CI surfaces the diff but does not block merge — drift is information, not failure.

This is the same pattern Anthropic, OpenAI, and most production teams use internally: prompt-regression tests run as a _signal_, not a gate.

---

## Layout

```
evals/
  README.md              ← this file
  run.sh                 ← runner. Usage: bash evals/run.sh [agent|all]
  agents/
    architect/
      canonical.md       ← prompts + golden outputs
    cto-strategist/
      canonical.md
    ...                  ← one folder per agent eval
  _reports/              ← gitignored. CI uploads as artifact.
```

Each `canonical.md` follows this format:

```markdown
# Eval: <agent-name>

## P1 — Title of test prompt

**Prompt:**
```

<the user prompt that drives the agent>
```

**Golden (human-curated, what we'd love to see):**

```
<expected shape — section headings, severity tags, decision-frame >
```

**Acceptance criteria:**

- [ ] Output has H1 with agent name
- [ ] Output uses severity tags 🔴🟠🟡 if there is a finding
- [ ] Output ends with `## Chains` listing next agents to consult, or "(none)"

````

---

## Running locally

```bash
# All agents
bash evals/run.sh

# One agent
bash evals/run.sh architect

# Output:
#   evals/_reports/architect-2026-05-03T17-22-00.md
````

The runner currently emits the prompts in a format you can paste into Claude Code manually and compare against `canonical.md`. Automated invocation via `claude -p` is on the roadmap (requires headless mode + cost considerations).

---

## What we eval

- **Output shape**: does the agent produce the section headers it promised?
- **Tool discipline**: does it stay within its declared `tools:` set?
- **Memory writes**: does it persist to the right `~/.claude/agent-memory/<name>/MEMORY.md` paths?
- **Chains**: does it suggest the right next-agent when handoff is appropriate?

We do **not** eval:

- Absolute correctness of advice (subjective; reviewer territory).
- Token cost (handled by `ccusage` integration).
- Style/tone (handled by the agent prompt itself).

---

## Adding an eval for a new agent

1. `mkdir evals/agents/<name>/`
2. `cp evals/agents/architect/canonical.md evals/agents/<name>/canonical.md`
3. Replace prompts and golden outputs.
4. Run `bash evals/run.sh <name>` and review the produced report.
5. Iterate until the golden matches what you'd ship.

Acceptance: at least 3 prompts per agent. Cover happy path, edge case, and a prompt that should trigger a chain to another agent.
