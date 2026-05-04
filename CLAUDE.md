# La Bestia — workspace CLAUDE.md

> This is the **project-level** CLAUDE.md for the la-bestia repository itself.
> The harness's **global** constitution (the one operators install into `~/.claude/`) lives at [`config/CLAUDE.md`](./config/CLAUDE.md).

## State

- **Version**: 4.1.0 (2026-05-04, published on GitHub at v4.1.0)
- **Inventory**: 15 agents (12 core + 3 specialists: `python-pro`, `typescript-pro`, `react-pro`) · 4 skills · 14 commands · 8 hooks · 3 scripts · 6 bin utilities (`compress`, `flow-viewer`, `onboard`, `flow-estimate`, `session-analyze`, `agent-memory-compact`, `parallelism-check`, `latency-report`).
- **Routing**: Intent Map in `config/CLAUDE.md` §6.1 — 19 intent → agent/skill/command mappings (16 core + 3 specialist). Smart routing supersedes keyword matching. SCAN MODE for surgical edits.
- **Orchestration**: `/flow` command activates `flow-feature` skill (Discover → Define → Develop → Deliver pipeline with parallel fan-out + Plan-Apply ritual). `/plan-flow` runs Phases 1–2 only (~50% cost).
- **Onboarding**: `/onboard-project` command bootstraps a project's `memory/` + `CLAUDE.md` + `.claudeignore` from manifest detection (15 stacks).
- **GitHub workflow**: `/issue` (list/create/triage via `gh`), `/pr-create` (auto Conventional-Commits PR title + body).
- **CI**: shellcheck + bats + schema validation + no-vault-leftovers + conventional-commit + CHANGELOG gate + install smoke (`.github/workflows/ci.yml`).
- **Tests**: `bats tests/hooks/` (8/8 hooks, 70+ cases incl. 22-case route-prompt) + `tests/scripts/` (compress, flow-viewer, onboard).
- **Quality measurement**: `make test-quality` runs route-prompt bats + parallelism-check + latency-report against live `~/.claude/logs/agents.jsonl`.
- **Build**: `Makefile` (run `make help`).
- **Plugin manifest**: `.claude-plugin/plugin.json` v4.1.0 — ready for marketplace publish.
- **License**: MIT (`LICENSE`).
- **Memory**: project-local in `memory/{hot-context,decisions,patterns,templates}`. Per-agent in `~/.claude/agent-memory/<agent>/`. No external vault.
- **ADRs**: 5 — `0001-bestia-v0.1` (superseded), `0002-v1.0-refactor` (no UI/vault), `0003-v2.0-agent-consolidation` (12 agents), `0004-v3.0-context-and-routing` (Intent Map), `0005-specialist-agents` (3 language specialists).

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
