# ADR-0005 — La Bestia v4.0: introduce 3 specialist agents (python-pro, typescript-pro, react-pro)

**Status:** accepted
**Date:** 2026-05-04
**Deciders:** wmarcelino-catalift
**Tags:** agents | specialists | language-depth
**Builds on:** ADR-0003 (12-agent core)

## Context

By v3.1, la-bestia had 12 archetype-grounded core agents. The `code-reviewer` is a generalist with mobile specialty folded in. Real operator usage shows two distinct review needs:

1. **Generalist review** — SOLID, complexity, naming, patterns. The current `@code-reviewer` covers this.
2. **Language-deep review** — idiom adherence (PEP 8, ESLint TS strict, React anti-patterns), framework conventions (FastAPI Depends, Next App Router), ecosystem currency (Python uv vs poetry, React Compiler vs useMemo).

The generalist agent does the second poorly — its prompt can't fit deep idiom for 5 languages. Operators end up writing "review my Python with focus on PEP 8 and FastAPI" hints, which is exactly what specialist agents solve.

Other harnesses (wshobson/agents, claude-octopus) ship 5-15 language specialists. We resisted in v2.0 (consolidation push) but real usage validates the gap.

## Options considered

1. **Status quo (12 core)** — generalist code-reviewer + operator-provided language hints in prompts.
2. **Add 3 specialists** (python-pro, typescript-pro, react-pro) — top stacks for la-bestia operators.
3. **Add 8+ specialists** (python, ts, react, go, rust, ruby, java, sql, devops-aws, devops-gcp).
4. **Per-project specialists** — operators add their own in `<repo>/.claude/agents/`.

## Tradeoffs

| Dimension          | Weight | Opt 1 (12 core)    | Opt 2 (12 + 3)                 | Opt 3 (12 + 8)             | Opt 4 (per-project)             |
| ------------------ | ------ | ------------------ | ------------------------------ | -------------------------- | ------------------------------- |
| Idiom depth        | 3      | low                | high (top 3 stacks)            | high (broad)               | high but operator-curated       |
| Eager-load tokens  | 2      | 12 × ~75 = 900     | 15 × ~75 = 1125                | 20 × ~75 = 1500            | unchanged global                |
| Maintenance burden | 2      | 12 files           | 15 files                       | 20 files                   | 12 files (per-proj added)       |
| Routing clarity    | 2      | "code-reviewer"    | "code-reviewer or python-pro?" | proliferating choices      | unclear without per-project doc |
| Operator UX        | 3      | hint-heavy prompts | clean `@python-pro`            | analysis-paralysis         | requires setup per project      |
| Future agents      | 2      | additions need ADR | precedent set                  | precedent set + bloat risk | flexible                        |

## Decision

**Option 2: add 3 specialists for the most-used stacks among la-bestia operators.**

The three are chosen because they are:

- **Highest stack-population** — Node/TS, Python, React dominate modern web/data work.
- **Most idiom-heavy** — each has strong opinions on "the right way" that a generalist agent flattens.
- **Stable archetypes available** — Hejlsberg/Rosenwasser for TS, Hettinger/Cannon for Python, Abramov/Markbåge for React give us the same archetype-grounding quality bar as the 12 core.

### Specialist contract (different from core)

| Aspect                 | Core agents (12)                          | Specialist agents (3)                                |
| ---------------------- | ----------------------------------------- | ---------------------------------------------------- |
| Activation             | broad (Intent Map keyword match)          | narrow (specific language/stack mention)             |
| Auto-invoke in `/flow` | yes (Discover/Define phases)              | no — only on direct mention or `code-reviewer` chain |
| Prompt size            | ~200 lines                                | ~150 lines                                           |
| Frontier section       | "general practice 2026"                   | "stack-specific 2026"                                |
| Replaces a core agent? | NO — complements `@code-reviewer`         |
| Memory file            | `~/.claude/agent-memory/<name>/MEMORY.md` | same                                                 |

### Routing rules (added to Intent Map §6.1)

```
| "Python idiom / typing / packaging" / .py / pyproject | python-pro |
| "TypeScript strict / branded / Effect" / .ts / .tsx + non-React | typescript-pro |
| "React perf / RSC / Suspense" / .tsx + React | react-pro |
```

The principal Claude prefers the specialist when the prompt explicitly mentions the language/framework. Otherwise the generalist `@code-reviewer` runs (which has mobile and SOLID specialties).

### Final inventory

- **15 agents total** (12 core + 3 specialists)
- 3 strategy + 2 delivery + 3 quality + 4 domain + 3 specialist
- Eager-load: ~1.1k tokens of frontmatter at session start (vs 900 in v3.1)

## Consequences

**Positive**

- Operators stop hint-engineering ("review my Python with PEP 8 focus") — the specialist embodies that.
- Idiom adherence rises measurably — specialist prompts include framework-specific anti-patterns generalists can't fit.
- Path opened for future specialists if real demand emerges (rust-pro, go-pro) — but each requires its own ADR per principle #2 (YAGNI).

**Negative / accepted costs**

- Eager-load tokens up ~25% (900 → 1125). Net cost ~$0.01 per session (negligible).
- Routing decision a bit more complex: operator might wonder "code-reviewer or python-pro?". Mitigated by Intent Map rows that prefer specialist when language is mentioned, and by AGENTS.md cheat sheet.
- Maintenance: 3 more agent files to keep current with stack evolution. Frontier section dates faster than core agents.

**Neutral / to monitor**

- If after 3 months any specialist sees < 5 invocations/month, demote to project-local (`<repo>/.claude/agents/`) per ADR-0003 spirit (project-agnostic core).
- If a 4th specialist (e.g., rust-pro) is requested 3+ times by different projects, consider adding with new ADR.

## Failure modes

1. **Specialist drift from idiom updates.** Python 3.13 free-threading changes some advice; React 19 makes useMemo less needed. Mitigation: each agent's "Frontier knowledge" section is dated 2026; review annually.
2. **Routing collisions** (e.g., a Python script with TypeScript HTTP types). Mitigation: principal applies "most specific intent" rule from §6.1.
3. **Operator confusion** (when to use core vs specialist). Mitigation: AGENTS.md cheat sheet + Intent Map rows make rules explicit.

## Reversibility

- **Two-way door**: removing specialists is a `git revert` + `bash install.sh global`. No operator-data lock-in (memory files persist locally; operator decides to delete).

## Related

- ADR-0003 (12-agent consolidation) — this builds on, doesn't supersede.
- `AGENTS.md` (root) — operator-facing cheat sheet for picking between core and specialist.
- `config/CLAUDE.md` §6.1 — Intent Map rows added.
