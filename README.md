# La Bestia — Claude Code harness · v4.2

> A deterministic, tested, MCP-ready harness for Claude Code.
> **15 archetype-grounded agents** (12 core + 3 language specialists, 20+ years framing each) · 15 commands incl. `/flow` + `/flow-worktree` · 9 hooks · 6 skills · 5-layer memory with append-only lessons · confidence tagging · anti-compaction-loss restore · project-agnostic · zero external vault dependencies.

[![ci](https://img.shields.io/badge/ci-shellcheck%20%2B%20bats%20%2B%20schemas-blue)](.github/workflows/ci.yml)
[![license](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![claude code](https://img.shields.io/badge/runs%20on-claude%20code-orange)](https://claude.com/claude-code)

---

## What you get

| Surface                      | Count | Notes                                                                                                                                                    |
| ---------------------------- | ----- | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Agents                       | 15    | 12 core (Vogels, Linus, Gregg, Schneier, Beck, Norman…) + 3 specialists (python-pro, typescript-pro, react-pro). Schema-validated.                       |
| Skills                       | 7     | `cto-thinking-system`, `flow-feature`, `ship-it`, `token-saver`, `lessons-loop`, `worktree-flow`, `frontend-design`                                      |
| Slash commands               | 15    | Includes `/flow`, `/flow-worktree`, `/plan-flow`, `/onboard-project`, `/issue`, `/pr-create`                                                             |
| Hooks                        | 9     | block-secrets, inject-context, **restore-context** (anti-compaction-loss), route-prompt, log-agents, log-session, cwd-changed, notify, architecture-gate |
| Memory layers                | 5     | `<repo>/memory/{hot-context,decisions,patterns,lessons}` + `~/.claude/agent-memory/<agent>/`                                                             |
| Confidence tagging           | ✓     | Strategy / Quality / Specialist tiers tag every non-trivial output `high\|medium\|low` + why                                                             |
| MCP servers wired by default | **0** | Operator opts in — see [`mcp/README.md`](./mcp/README.md)                                                                                                |
| External vault dependencies  | **0** | No Obsidian, no Notion, no anything                                                                                                                      |
| Project-specific assumptions | **0** | Genuinely project-agnostic. Drop into any codebase.                                                                                                      |
| UI surfaces                  | **0** | Terminal text only                                                                                                                                       |

---

## Quickstart

```bash
git clone https://github.com/wmarcelino-catalift/la-bestia.git
cd la-bestia
bash install.sh global             # interactive; installs to ~/.claude/

# verify
bash ~/.claude/scripts/verify.sh

# inside any project
claude
> /agents       # list all 12 agents
> /flow "<feature>"  # Discover → Define → Develop → Deliver pipeline
> /cto-review   # senior CTO review of current change
> /ship-it      # pre-merge quality gates
```

Project-scoped install: `bash install.sh project ./.claude` from inside a repo.
Windows operators: run from Git Bash; PowerShell is not supported.

---

## Architecture in one diagram

```
┌──────────────────────────────────────────────────────────────────┐
│  L7  Operator       (you)                                         │
│  L6  Constitution   config/CLAUDE.md (5 questions, 10 principles) │
│  L5  Routing        UserPromptSubmit hook → suggests agent        │
│  L4  Agents · Skills · Commands                                   │
│  L3  Safety         block-secrets hook · permission allow/deny    │
│  L2  Memory         repo/memory + ~/.claude/agent-memory          │
│  L1  Telemetry      JSONL logs · ccusage cost integration         │
│  L0  MCP            integrations (operator opt-in)                │
└──────────────────────────────────────────────────────────────────┘
```

Full spec: [`ARCHITECTURE.md`](./ARCHITECTURE.md).

---

## Agent teams

| Team     | Lead(s)                                              | When                                                                       |
| -------- | ---------------------------------------------------- | -------------------------------------------------------------------------- |
| Strategy | `strategist`, `architect`, `mentor`                  | New feature, roadmap, build-vs-buy, ADRs, pre-mortem, one-way-door reviews |
| Delivery | `test-engineer`, `debugger`                          | TDD implementation, root-cause analysis on bugs                            |
| Quality  | `code-reviewer`, `security`, `optimizer`             | Post-change review, OWASP/threat models, performance + Web Vitals          |
| Domain   | `devops`, `data-engineer`, `tech-writer`, `designer` | CI/CD + IaC, schemas + queries, docs (Diátaxis), design systems + a11y     |

---

## Production-grade by default

This harness ships with the foundation we'd expect from a real engineering org:

- **CI gates**: shellcheck, bats, JSON Schema validation on every PR (`.github/workflows/ci.yml`).
- **Tests**: `bats` test suite for hooks (`tests/hooks/*.bats`); run with `bash tests/run.sh`.
- **Schemas**: agent, skill, settings, log-event JSON Schemas in `schemas/`.
- **Evals**: snapshot eval framework in `evals/` for regression detection on agent outputs.
- **Governance**: `CHANGELOG.md` (Keep a Changelog), `CONTRIBUTING.md`, `SECURITY.md`, `CODEOWNERS`.
- **Templates**: `_TEMPLATE.md` for agents, skills, commands; `memory/templates/` for ADRs and patterns.

If you've worked in shops with these things, this should feel familiar. If you haven't, [`CONTRIBUTING.md`](./CONTRIBUTING.md) walks the new-agent / new-hook recipes step by step.

---

## Memory model (in 30 seconds)

1. **`<repo>/memory/hot-context.md`** — read at session start. ≤ 200 tokens.
2. **`<repo>/memory/decisions/`** — ADRs (one-way doors).
3. **`<repo>/memory/patterns/`** — reusable solutions for this repo.
4. **`<repo>/memory/lessons/`** _(v4.2)_ — append-only incident learnings. Promotion: incident → lesson → pattern → ADR.
5. **`~/.claude/agent-memory/<agent>/MEMORY.md`** — per-agent, cross-session.

`restore-context.sh` re-injects layers 1-4 on session resume / compact. No Obsidian. No external sync. No vendor lock-in.

---

## MCP — operator opt-in

The harness installs zero MCP servers. Patterns for the common ones live in [`mcp/README.md`](./mcp/README.md):

```bash
claude mcp add github --scope user --env GITHUB_PERSONAL_ACCESS_TOKEN="$GITHUB_PAT" -- \
  npx -y @modelcontextprotocol/server-github
```

GitHub · Postgres · Linear · Sentry · Slack · Filesystem — wire what you need, leave the rest.

---

## Documentation map

- [`ARCHITECTURE.md`](./ARCHITECTURE.md) — system design, layer contracts, performance budgets
- [`CHANGELOG.md`](./CHANGELOG.md) — version history (Keep a Changelog)
- [`CONTRIBUTING.md`](./CONTRIBUTING.md) — dev loop, commit format, recipes for new agents/hooks
- [`SECURITY.md`](./SECURITY.md) — threat model, reporting, hardening checklist
- [`docs/HOW-IT-WORKS.md`](./docs/HOW-IT-WORKS.md) — runtime walkthrough of a session
- [`mcp/README.md`](./mcp/README.md) — MCP integration templates
- [`evals/README.md`](./evals/README.md) — eval framework
- [`memory/decisions/`](./memory/decisions/) — ADRs for the harness itself

---

## Versions

| Version   | Headline                                                                                                                                                                                                                                                                                 | Date           |
| --------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------- |
| **4.2.1** | **Adds `frontend-design` skill — anti-mediocre UI guard-rail (token discovery, identity check, full state coverage). Closes last gap from v4.2 ecosystem analysis.**                                                                                                                    | **2026-05-04** |
| 4.2.0     | Resilience & learning loops: `restore-context.sh` (anti-compaction-loss), `memory/lessons/` + `lessons-loop` skill, `worktree-flow` skill + `/flow-worktree` + 3 worktree bins, confidence tagging anti-hallucination layer.                                                            | 2026-05-04     |
| 4.1.0     | Quality measurement pack: `bin/parallelism-check.sh`, `bin/latency-report.sh`, route-prompt.bats extended to 22 cases (16 Tier B canonical), `make test-quality` target.                                                                                                                 | 2026-05-04     |
| 4.0.0     | Combined v3.2+v3.3+v4.0: 3 specialist agents (python-pro, typescript-pro, react-pro), 3 new hooks (cwd-changed, notify, architecture-gate), 2 new bin utilities (session-analyze, agent-memory-compact), 3 new commands (/issue, /pr-create, /plan-flow), AGENTS.md root file. ADR-0005. | 2026-05-04     |
| 3.1.0     | Efficiency + analysis pack: `bin/flow-estimate.sh`, synthesis compression, Phase 2 deduplication, per-phase cost, auto-ADR detection, SCAN MODE for surgical edits.                                                                                                                      | 2026-05-04     |
| 3.0.1     | Patch: install.sh now copies `bin/` (was missing). Added `tests/scripts/compress.bats`. New `docs/QUICKSTART.md`. Updated `docs/HOW-IT-WORKS.md` to v3.0 features. verify.sh checks `bin/`.                                                                                              | 2026-05-04     |
| 3.0.0     | Smart routing (Intent Map in CLAUDE.md), rich SessionStart context (15-stack auto-detect + git richness + cost + last-24h agents), `/onboard-project` bootstrap wizard, statusline budget alerts. ~20-30% token savings vs v2.1.                                                         | 2026-05-04     |
| 2.1.0     | `bin/flow-viewer.sh` ASCII gantt of sessions, mandatory phase banners in `/flow`, `/status` rewritten (was broken since v1.0), CI runs `tests/scripts/`. No UI surfaces — text only.                                                                                                     | 2026-05-04     |
| 2.0.0     | 18 → 12 archetype-grounded agents (Vogels, Linus, Gregg, Schneier, Beck, Norman…). New `/flow` Discover→Define→Develop→Deliver pipeline. Project-agnostic.                                                                                                                               | 2026-05-03     |
| 1.1.0     | Hook consolidation (track-agent → log-agents), Makefile, plugin manifest, `bin/compress.sh`, +CI gates.                                                                                                                                                                                  | 2026-05-03     |
| 1.0.0     | Foundation: tests, CI, schemas, evals, MCP-first. Removed Obsidian, dashboard, flow-diagram, graphify.                                                                                                                                                                                   | 2026-05-03     |
| 0.4.0     | +6 agents, +1 skill (graphify), levantamiento doc                                                                                                                                                                                                                                        | 2026-05-03     |
| 0.3.0     | Inter-agent memory templates, bilingual routing                                                                                                                                                                                                                                          | 2026-05-03     |
| 0.2.0     | 11 slash commands, ES/EN routing                                                                                                                                                                                                                                                         | 2026-05-03     |
| 0.1.0     | 6 agents, 5 hooks, 3 skills                                                                                                                                                                                                                                                              | 2026-05-01     |

Migration from v0.x: see [`CHANGELOG.md`](./CHANGELOG.md) → `[1.0.0]` → Migration.

---

## License

MIT. See [`LICENSE`](./LICENSE).
