# hot-context.md — La Bestia (workspace)

> Read FIRST every session. Keep ≤ 200 tokens. Update via `/wrap-up`.

## Project

- **Repo:** la-bestia — Claude Code harness (agents, hooks, skills, commands).
- **Stage:** v1.0 — production-grade refactor (tests, CI, schemas, evals, MCP-first).
- **Stack:** bash + jq + bats + GitHub Actions. No runtime, no SaaS.

## Current focus

- Ship v1.0: deleted UI/vault, added tests/CI/schemas/evals/governance docs.
- Live `~/.claude/` syncing to repo via `install.sh` (operator-driven, no auto-deploy).

## Recent decisions

- 2026-05-03: v1.0 — see [ADR-0002](decisions/0002-v1.0-refactor.md). Removed Obsidian, dashboard, flow-diagram, graphify.
- 2026-05-01: v0.1 setup — see [ADR-0001](decisions/0001-bestia-v0.1.md) (superseded by 0002).

## Pending

- [ ] Backfill `evals/agents/<name>/canonical.md` for 17 remaining agents (architect done).
- [ ] Backfill `tests/hooks/<name>.bats` for `log-agents`, `log-session`, `track-agent`.
- [ ] Performance test harness `tests/perf/` with p99 budget enforcement.

## Gotchas

- Windows OneDrive sync can lock dirs during rapid `mv` — use `cp` + `rm -rf` instead.
- Prettier hook reformats markdown tables on every Write; expected, harmless.
