# La Bestia — workspace CLAUDE.md

> This is the **project-level** CLAUDE.md for the la-bestia repository itself.
> The harness's **global** constitution (the one operators install into `~/.claude/`) lives at [`config/CLAUDE.md`](./config/CLAUDE.md).

## State

- **Version**: 4.2.1 (2026-05-04 — v4.2.0 + `frontend-design` skill anti-mediocre UI guard-rail)
- **Inventory**: 15 agents (12 core + 3 specialists: `python-pro`, `typescript-pro`, `react-pro`) · 7 skills · 15 commands · 9 hooks · 3 scripts · 9 bin utilities (`compress`, `flow-viewer`, `onboard`, `flow-estimate`, `session-analyze`, `agent-memory-compact`, `parallelism-check`, `latency-report`, `worktree-add`, `worktree-remove`, `worktree-list`).
- **Routing**: Intent Map in `config/CLAUDE.md` §6.1 — 19 intent → agent/skill/command mappings. Smart routing supersedes keyword matching. SCAN MODE for surgical edits. Confidence tagging (§6.2) on Strategy/Quality/Specialist outputs.
- **Orchestration**: `/flow` command activates `flow-feature` skill (Discover → Define → Develop → Deliver pipeline with parallel fan-out + Plan-Apply ritual). `/plan-flow` runs Phases 1–2 only (~50% cost). `/flow-worktree <slug>` corre `/flow` adentro de un worktree aislado para paralelismo real.
- **Onboarding**: `/onboard-project` command bootstraps a project's `memory/` + `CLAUDE.md` + `.claudeignore` from manifest detection (15 stacks).
- **GitHub workflow**: `/issue` (list/create/triage via `gh`), `/pr-create` (auto Conventional-Commits PR title + body).
- **Anti-compaction-loss (v4.2)**: `restore-context.sh` hook fires on SessionStart with source ∈ {compact, resume} — re-inyecta hot-context full + índices de ADRs/patterns/lessons + últimos 8 commits.
- **Lessons loop (v4.2)**: `memory/lessons/` append-only + `lessons-loop` skill. Promotion path: incident → lesson → pattern → ADR.
- **Worktree paralelismo (v4.2)**: `worktree-flow` skill + `/flow-worktree` command + `bin/worktree-{add,remove,list}.sh`. Múltiples features en paralelo sin polución del checkout.
- **CI**: shellcheck + bats + schema validation + no-vault-leftovers + conventional-commit + CHANGELOG gate + install smoke (`.github/workflows/ci.yml`).
- **Tests**: `bats tests/hooks/` (9/9 hooks, 85+ cases incl. 22-case route-prompt + 14-case restore-context) + `tests/scripts/` (compress, flow-viewer, onboard).
- **Quality measurement**: `make test-quality` runs route-prompt bats + parallelism-check + latency-report against live `~/.claude/logs/agents.jsonl`.
- **Build**: `Makefile` (run `make help`).
- **Plugin manifest**: `.claude-plugin/plugin.json` v4.2.0 — ready for marketplace publish.
- **License**: MIT (`LICENSE`).
- **Memory**: 5-layer — project-local in `memory/{hot-context,decisions,patterns,lessons,templates}`. Per-agent in `~/.claude/agent-memory/<agent>/`. No external vault.
- **ADRs**: 6 — `0001-bestia-v0.1` (superseded), `0002-v1.0-refactor` (no UI/vault), `0003-v2.0-agent-consolidation` (12 agents), `0004-v3.0-context-and-routing` (Intent Map), `0005-specialist-agents` (3 language specialists), `0006-v4.2-resilience-loops` (anti-compaction + lessons + worktree + confidence).

## How to evolve the harness

1. Edit files under `config/` (agents, hooks, skills, commands, scripts).
2. Add/update tests in `tests/` for any hook or script change.
3. Update schemas in `schemas/` if you change frontmatter shape.
4. CHANGELOG entry under `[Unreleased]`.
5. PR with the `.github/PULL_REQUEST_TEMPLATE.md` checklist filled.
6. Once merged, run `bash install.sh global` on operator machines to deploy.

## Live ↔ repo sync

- The repo is the source of truth. CI runs against it.
- Operator machines run `~/.claude/<…>` (deployed copy of `config/<…>`).
- To propose changes from a live experiment back to the repo: `bash ~/.claude/scripts/sync-to-bestia.sh` opens a PR.

## Rules for this workspace

- Never bypass CI. If a PR is failing, fix the failure, don't merge around it.
- Every breaking change to schemas/hooks/commands ships an ADR in `memory/decisions/` and a CHANGELOG migration block.
- No new Obsidian / vault / external-memory references. ADR-0002 closed that door.
- No new UI surfaces (HTML, dashboards, image generators). ADR-0002 closed that door too.

## See also

- [`README.md`](./README.md) — operator-facing entry point.
- [`ARCHITECTURE.md`](./ARCHITECTURE.md) — system design.
- [`CONTRIBUTING.md`](./CONTRIBUTING.md) — dev loop and recipes.
- [`memory/decisions/`](./memory/decisions/) — ADRs.
