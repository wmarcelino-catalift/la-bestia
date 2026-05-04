# AGENTS.md

> Quick-reference of every agent in this harness. Companion to [`config/CLAUDE.md`](./config/CLAUDE.md) (constitution). Claude Code reads `AGENTS.md` as a convention; this file is the single page an operator can grep when wondering "which agent for X?".

## How to invoke

```
@<agent-name> "<your prompt>"
```

Or let the [Intent Map](./config/CLAUDE.md#61-intent--agent-map-smart-routing--read-this-before-keyword-matching) auto-route — write in natural language and the principal Claude picks the agent for you.

For surgical edits, append `[SCAN MODE]` to your prompt — agents return ≤200 tokens, severity-tagged or `✓ scan clean`, no alternatives proposed.

---

## The 12 core agents

| Tier         | Agent           | Model  | One-liner                                                                             |
| ------------ | --------------- | ------ | ------------------------------------------------------------------------------------- |
| **Strategy** | `strategist`    | opus   | Bezos PR-FAQ + Christensen JTBD + Eric Ries lean. RICE, build-vs-buy, OKRs.           |
| **Strategy** | `architect`     | opus   | Werner Vogels + Kleppmann + Sam Newman. ADRs, system design, tradeoff matrices.       |
| **Strategy** | `mentor`        | opus   | Munger inversion + Andy Grove + Annie Duke. Pre-mortem, 9-lens stress test.           |
| **Delivery** | `test-engineer` | sonnet | Kent Beck TDD + Michael Feathers. Default implementer with red-green-refactor.        |
| **Delivery** | `debugger`      | opus   | Brian Kernighan + John Allspaw + Charity Majors. Root cause via 5-whys, bisection.    |
| **Quality**  | `code-reviewer` | sonnet | Linus Torvalds + John Carmack. Severity tags, cognitive complexity, mobile specialty. |
| **Quality**  | `security`      | sonnet | Bruce Schneier + Mudge + STRIDE + OWASP ASVS. Threat models, auth/payments/PII.       |
| **Quality**  | `optimizer`     | sonnet | Brendan Gregg (USE/flames) + Sarah Drasner + Knuth. Profiling, Web Vitals.            |
| **Domain**   | `devops`        | sonnet | Kelsey Hightower + Charity Majors + Google SRE. CI/CD, IaC, SLOs, observability.      |
| **Domain**   | `data-engineer` | sonnet | Maxime Beauchemin + Kleppmann + dbt. Schemas, EXPLAIN ANALYZE, ETL, vector stores.    |
| **Domain**   | `tech-writer`   | sonnet | Daniele Procida (Diátaxis) + Stripe API style. READMEs, ADRs, runbooks.               |
| **Domain**   | `designer`      | sonnet | Don Norman + Apple HIG + Material 3 + WCAG 2.2. Design systems, accessibility.        |

## Specialist agents (v4.0+)

Optional language-specific specialists for deep code expertise. Loaded only when the operator's prompt explicitly mentions the language or stack.

| Agent            | Model  | When                                                                                                       |
| ---------------- | ------ | ---------------------------------------------------------------------------------------------------------- |
| `python-pro`     | sonnet | Python idiomatic code, type hints, async/await, packaging (pyproject), pytest, Hettinger-style readability |
| `typescript-pro` | sonnet | TypeScript strict mode, branded types, Effect/Result, type-driven design                                   |
| `react-pro`      | sonnet | React 18+/19, Server Components, Suspense, performance (memo/profiler), Abramov idioms                     |

**Total: 15 agents.** The 12 core handle 95% of requests. Specialists kick in when prompted directly (`@python-pro`) or when the principal detects deep language work that benefits from focused archetype.

---

## Cheat sheet — pick the right agent in 5 seconds

| You're about to say...                       | Agent that wakes up                               |
| -------------------------------------------- | ------------------------------------------------- |
| "should we use X or Y?"                      | `@strategist` (+ `@mentor` for one-way doors)     |
| "design the system / write an ADR"           | `@architect`                                      |
| "review my plan adversarially"               | `@mentor`                                         |
| "implement this with TDD"                    | `@test-engineer`                                  |
| "this bug doesn't make sense"                | `@debugger` (or `/deep-debug` after 2 attempts)   |
| "review my PR / diff"                        | `@code-reviewer` (+ `@security` if auth/payments) |
| "is this safe?"                              | `@security`                                       |
| "make it faster / profile this"              | `@optimizer`                                      |
| "deploy / CI / IaC"                          | `@devops`                                         |
| "schema / migration / slow query"            | `@data-engineer`                                  |
| "write README / API docs / runbook"          | `@tech-writer`                                    |
| "design system / accessibility / UX"         | `@designer`                                       |
| "Python idiom / typing / packaging"          | `@python-pro`                                     |
| "TypeScript strict types / Effect / branded" | `@typescript-pro`                                 |
| "React perf / RSC / Suspense"                | `@react-pro`                                      |

---

## Composing agents

Most prompts auto-dispatch one or two agents. For multi-phase work, use orchestration commands:

| Command                           | Effect                                                                                  |
| --------------------------------- | --------------------------------------------------------------------------------------- |
| `/flow "<feature>"`               | Discover → Define → Develop → Deliver pipeline. 4 phases × 2-5 agents in parallel each. |
| `/parallel-research "<question>"` | 3-5 agents fan-out for independent dimensions.                                          |
| `/bug-hunt`                       | 3 agents per layer (UI / Service / Data) for cross-layer bugs.                          |
| `/cto-review`                     | Senior CTO review with the 5 questions + 10 principles.                                 |
| `/ship-it`                        | Pre-merge gates (`@code-reviewer` + `@security` + tests + linter + commit).             |
| `/mobile-audit "<feature>"`       | RN/Expo perf + security + tests + UX (4 agents parallel).                               |

---

## SCAN MODE — surgical edits

For one-line / one-property changes, append `[SCAN MODE]` so the agent returns a fast severity-tagged check instead of a full review:

```
@designer [SCAN MODE]
I just changed Button.tsx line 42 from #1a1a1a to #000.
Diff: <diff>
Scan only this diff.
```

Cost: ~$0.05 per scan vs ~$0.30 normal.

---

## Memory each agent reads/writes

Each agent reads (in order) on every invocation:

1. `<repo>/memory/hot-context.md` (≤ 200 tokens, current state)
2. Relevant `<repo>/memory/decisions/<NNNN>-*.md` (ADRs)
3. `<repo>/memory/patterns/*.md` (project recipes)
4. `~/.claude/agent-memory/<agent>/MEMORY.md` (per-agent learnings, cross-project)
5. Source code (only if 1-4 don't answer)

Agents write back to **(4)** when they learn something consequential. The 3-layer rule (hot-context → ADRs/patterns → source) saves up to **10× tokens** per session vs reading code greedily.

---

## Don't see what you need?

- **Add a new core agent** → see [`CONTRIBUTING.md`](./CONTRIBUTING.md) → "Adding a new agent — full checklist". Requires ADR.
- **Add a project-local agent** → put it in `<repo>/.claude/agents/<name>.md`. Lives only in that project, no global pollution.
- **Activate an MCP server for an integration** → see [`mcp/README.md`](./mcp/README.md). Examples: GitHub, Linear, Postgres, Sentry, Slack.

---

## See also

- [`config/CLAUDE.md`](./config/CLAUDE.md) — full constitution (5 questions, 10 principles, Intent Map, SCAN MODE protocol)
- [`docs/QUICKSTART.md`](./docs/QUICKSTART.md) — 60-second setup guide
- [`docs/HOW-IT-WORKS.md`](./docs/HOW-IT-WORKS.md) — runtime walkthrough
- [`memory/decisions/`](./memory/decisions/) — ADRs explaining design decisions
