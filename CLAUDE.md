# La Bestia — workspace CLAUDE.md

> This is the **project-level** CLAUDE.md for the la-bestia repository itself.
> The harness's **global** constitution (the one operators install into `~/.claude/`) lives at [`config/CLAUDE.md`](./config/CLAUDE.md).

## State

- **Version**: 1.1.0 (2026-05-03)
- **Inventory**: 18 agents · 3 skills · 11 commands · 5 hooks · 3 scripts · 1 bin utility (`compress`).
- **CI**: shellcheck + bats + schema validation + no-vault-leftovers + conventional-commit + CHANGELOG gate + install smoke (`.github/workflows/ci.yml`).
- **Tests**: `bats tests/hooks/` covering `block-secrets`, `inject-context`, `route-prompt`, `log-agents`, `log-session` (5/5 hooks).
- **Build**: `Makefile` (run `make help`).
- **Plugin manifest**: `.claude-plugin/plugin.json` — preparatory for future marketplace publish.
- **Memory**: project-local in `memory/{hot-context,decisions,patterns}`. No external vault.

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
