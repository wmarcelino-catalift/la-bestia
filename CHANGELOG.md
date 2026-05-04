# Changelog

All notable changes to this project are documented here.
Format follows [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/).
This project adheres to [Semantic Versioning 2.0.0](https://semver.org/).

## [Unreleased]

## [3.0.0] — 2026-05-04

Smart routing, rich context at session start, project bootstrap wizard. **No breaking changes.** All additive. See [ADR-0004](./memory/decisions/0004-v3.0-context-and-routing.md).

### Added

- **Intent Map** in `config/CLAUDE.md` (§6.1) — 16 intent → agent/skill/command mappings. Principal consults this BEFORE keyword routing. Faster + more accurate dispatch.
- **`/onboard-project` command** (`config/commands/onboard-project.md`) + **`bin/onboard.sh` wizard** — detect stack, scaffold `memory/{hot-context,decisions,patterns,templates}/`, create `.claudeignore` + project-level `CLAUDE.md`. Idempotent (never overwrites). 10 bats tests covering idempotency, stack detection, no-overwrite invariants.
- **`tests/scripts/onboard.bats`** — 10 cases.
- **`memory/decisions/0004-v3.0-context-and-routing.md`** — full ADR.

### Changed

- **`config/hooks/inject-context.sh`** — enriched SessionStart context. Now injects:
  - Stack auto-detection from manifest files (15 stacks: Node.js / TypeScript / Python / Go / Rust / Ruby / PHP / JVM / Expo / Docker / Terraform / Firebase / Supabase / Vercel / Netlify).
  - Git richness: branch · uncommitted · ahead-of-upstream · last commit · modified files (top 8) · recent 5 commits.
  - `$ today` from ccusage.
  - Top-3 agents from last 24h (from `agents.jsonl`).
  - Project `memory/hot-context.md` (preserved).
- **`config/scripts/statusline.sh`** — adds:
  - Per-day + per-week `$` (`$X.XXd/$Y.YYw`).
  - Budget alert prefixes: `⚠` at $20/day, `🚨` at $50/day.
  - Context window % indicator with `/compact` hint at ≥ 70%.
- **`config/skills/token-saver/SKILL.md` v2.0.0** — threshold raised 60% → 70%. New heuristics for budget alerts (`⚠ $X today` → switch to haiku for exploration).
- **`config/CLAUDE.md`** — bumped header to v3.0.
- **`tests/hooks/inject-context.bats`** — expanded from 5 to 11 cases (stack detection coverage for 5 stacks + project basename in header + absent-stack guard).

### Migration from v2.1

No action required. All changes are additive:

- Existing operators get richer SessionStart automatically (re-run `bash install.sh global` to copy refactored hook + scripts).
- New operators benefit from `/onboard-project` immediately.
- token-saver threshold change (60→70%) is a heuristic tuning; no operator action needed.

To take advantage of `/onboard-project` in an existing project, run it inside the project — it will detect what's already there and skip those files.

## [2.1.0] — 2026-05-04

Visibility additions, no breaking changes. Stays aligned with [ADR-0002](./memory/decisions/0002-v1.0-refactor.md) — no UI surfaces, terminal text only.

### Added

- `bin/flow-viewer.sh` — render an ASCII gantt chart of a session from `agents.jsonl`. Read-only, idempotent. Honors `FLOW_VIEWER_WIDTH` env var. Stdin support (`-`).
- `tests/scripts/flow-viewer.bats` — 10 cases covering single/multi-row, empty input, stdin, env var, bad path, agent filtering.
- `tests/run.sh` and CI now also run `tests/scripts/`.
- Phase banners in `flow-feature` skill (v1.1.0): mandatory stdout text between phases of `/flow`. No emoji banners, no UI.

### Changed

- `config/commands/status.md` — rewritten to remove dead references to `dashboard.sh` (deleted in v1.0) and `live-activity.jsonl` (consolidated in v1.1). Now produces a single-screen status: active agents, last 5 post-events, today's `ccusage` cost, git state. Read-only with no side effects.
- `config/skills/flow-feature/SKILL.md` bumped to 1.1.0 (phase banners section added).
- `tests/run.sh` — `shellcheck` target now also lints `bin/*.sh`.
- `.github/workflows/ci.yml` — `bats` job now runs both `tests/hooks/` and `tests/scripts/`.

### Migration from v2.0

- No action required. All changes are additive.
- To opt into wider gantt charts: `FLOW_VIEWER_WIDTH=80 bash bin/flow-viewer.sh ~/.claude/logs/agents.jsonl`.
- `/status` now works correctly (previously referenced deleted scripts).

## [2.0.0] — 2026-05-03

Major consolidation. **18 agents → 12 archetype-grounded agents.** New `/flow` orchestration. Project-agnostic. See [ADR-0003](./memory/decisions/0003-v2.0-agent-consolidation.md).

### Added

- `config/agents/strategist.md` — Bezos PR-FAQ + Christensen JTBD + Eric Ries lean + Munger inversion (replaces cto-strategist + business-analyst + pm).
- `config/agents/security.md` — Schneier + Mudge + STRIDE + OWASP ASVS + NIST Zero-Trust (replaces security-auditor + security-reviewer).
- `config/agents/designer.md` — Don Norman + Apple HIG + Material 3 + WCAG 2.2 + Inclusive Design (replaces uiux + ux-reviewer).
- `config/skills/flow-feature/SKILL.md` — orchestration skill: Discover → Define → Develop → Deliver with parallel fan-out per phase + Plan-Apply ritual between phases.
- `config/commands/flow.md` — `/flow "<feature>"` activator for the flow-feature skill.
- `memory/decisions/0003-v2.0-agent-consolidation.md` — full ADR for this release.

### Changed

- **BREAKING**: 9 agents removed (see Removed), 3 new merged agents added, 9 existing agents refactored with 20+ years archetype framing + frontier-knowledge sections + anti-patterns.
- All 12 agents now reference real-world archetypes (Werner Vogels for architect, Linus + Carmack for code-reviewer, Brendan Gregg for optimizer, Kent Beck for test-engineer, etc.).
- All 12 agents have explicit `## Anti-patterns this agent rejects` and `## Frontier knowledge (top-tier practice 2026)` sections.
- All 12 agents have explicit `## Chains` for inter-agent delegation.
- `config/hooks/route-prompt.sh` — keyword routing rewritten for the new 12-agent set; cleaner regex; bilingual (ES/EN) preserved.
- `config/CLAUDE.md` — constitution v2.0 (12 agents, /flow canonical, archetype framing).

### Removed

- **BREAKING**: `cto-strategist`, `business-analyst`, `pm` → folded into `strategist`.
- **BREAKING**: `security-auditor`, `security-reviewer` → folded into `security`.
- **BREAKING**: `uiux`, `ux-reviewer` → folded into `designer`.
- **BREAKING**: `mobile-reviewer` → folded into `code-reviewer` (mobile specialty section in body).
- **BREAKING**: `content-manager` — was Catalift-specific (Firestore content, recetas, WhatsApp). Project-leak; deleted from global. Operators can replicate as project-local agent in their own `<repo>/.claude/agents/`.

### Migration from v1.x

1. `bash install.sh global` (or `make install`) — backs up live, replaces obsolete agents.
2. Optional: merge old agent-memory into new files. Examples:
   ```bash
   # If you had notes from cto-strategist + business-analyst + pm, consolidate:
   cat ~/.claude/agent-memory/{cto-strategist,business-analyst,pm}/MEMORY.md \
     > ~/.claude/agent-memory/strategist/MEMORY.md.merged
   # Review the merged file, then move into place:
   mv ~/.claude/agent-memory/strategist/MEMORY.md.merged \
      ~/.claude/agent-memory/strategist/MEMORY.md
   # Same pattern for security-auditor + security-reviewer → security,
   # and uiux + ux-reviewer → designer.
   ```
3. Old agent-memory directories (`cto-strategist/`, etc.) are NOT auto-deleted (operator-private data). Remove manually if desired.
4. If you used `content-manager` for project-specific content updates: re-create as `<repo>/.claude/agents/<your-name>.md` in your project. The harness no longer ships it globally.
5. Run `bash ~/.claude/scripts/verify.sh` — should report 12 agents, 4 skills (cto-thinking-system, flow-feature, ship-it, token-saver), 5 hooks, 3 scripts.

## [1.1.0] — 2026-05-03

### Added

- `Makefile` — standard targets (`install`, `test`, `lint`, `verify`, `check`, `clean`, `release-prep`, `agents-table`). `make check` mirrors the full CI gate locally.
- `.claude-plugin/plugin.json` — Claude Code plugin manifest (preparatory; not yet published to a marketplace).
- `bin/compress.sh` — token-thrifty session digest. Reads agents.jsonl / bash.jsonl and produces a markdown summary (agents ranked, bash command frequencies). Supports stdin (`-`).
- `tests/hooks/log-agents.bats` — 11 cases: pre/post timing, duration computation, bash-only-post semantics, jq-degraded mode, JSON validity.
- `tests/hooks/log-session.bats` — 6 cases: summary file shape, agents.jsonl ingestion, no-vault assertion, all.log append.
- CI gates: `no-vault-leftovers` (rejects re-introduced Obsidian paths), `conventional-commit` (PR title shape), `changelog-gate` (enforces CHANGELOG updates on `feat/fix/refactor/perf` PRs), plugin manifest JSON validation.

### Changed

- **BREAKING (telemetry)**: consolidated `track-agent.sh` into `log-agents.sh`. The single hook now handles both `PreToolUse Task` and `PostToolUse Task|Bash`, computes duration via `.agent_start_<name>` markers, and is the only producer of `agents.jsonl` / `bash.jsonl`. Migration: re-run `bash install.sh global` to update `~/.claude/settings.json` hook bindings.
- `config/settings.example.json` — added `PreToolUse Task` binding for `log-agents.sh pre`; `PostToolUse Task|Bash` now passes `post` argument explicitly.

### Removed

- `config/hooks/track-agent.sh` — duplicate of `log-agents.sh` Task semantics, never wired in `settings.example.json`. Its timing logic is now in `log-agents.sh`.

### Migration from v1.0

1. `bash install.sh global` (or `make install`) — backs up your live `~/.claude/`, drops `track-agent.sh`, updates settings hook bindings.
2. If you had custom `settings.json` referencing `track-agent.sh`: replace with two bindings — `PreToolUse Task` calling `log-agents.sh pre` and `PostToolUse Task|Bash` calling `log-agents.sh post`.
3. Run `bash ~/.claude/scripts/verify.sh` — should report all pass with 5 hooks (down from 6).

## [1.0.0] — 2026-05-03

### Added

- `ARCHITECTURE.md` — system design document (single source of truth for "how it works").
- `CHANGELOG.md`, `CONTRIBUTING.md`, `SECURITY.md` — governance baseline.
- `schemas/` — JSON Schema definitions for `agent` frontmatter, `skill` frontmatter, `settings.json`, and JSONL log events. Used in CI to reject drift.
- `tests/` — `bats` scaffold. First test: `tests/hooks/block-secrets.bats` covering filename and content patterns.
- `.github/workflows/ci.yml` — hard gates (shellcheck, bats, schema validation), soft gates (markdown lint).
- `.github/PULL_REQUEST_TEMPLATE.md`, `.github/CODEOWNERS`.
- `evals/` — snapshot eval framework. Example: `evals/agents/architect/canonical.md`.
- `mcp/` — operator-curated MCP integration templates (GitHub, Postgres, Linear, Sentry, Slack). Zero MCPs are installed by default.
- `memory/templates/` — `adr.md` and `pattern.md` to standardize memory writes.
- Component templates: `config/agents/_TEMPLATE.md`, `config/skills/_TEMPLATE/SKILL.md`, `config/commands/_TEMPLATE.md`.

### Changed

- **BREAKING**: removed all Obsidian-vault dependencies. Memory now lives strictly in `<repo>/memory/` (project-scoped) and `~/.claude/agent-memory/` (global per-agent). Migration: copy any `~/Obsidian/claude-brain/` content you still need into `<repo>/memory/patterns/`.
- **BREAKING**: agent frontmatter now validated against `schemas/agent.schema.json`. Tools are a closed enum. The 6 newer agents (`business-analyst`, `mentor`, `optimizer`, `security-reviewer`, `tech-writer`, `uiux`) gain `Write` permission to align with the rest.
- **BREAKING**: hooks must pass `bats` tests in CI. `track-agent.sh` no longer writes to `live-activity.jsonl` (deleted along with `live-update.sh`).
- `settings.example.json` is now a strict template: production-grade allow/deny lists, `effortLevel: high`, `model: opusplan`, no `OBSIDIAN_VAULT` env, no `live-update` hook wiring.
- `inject-context.sh` reads only `<repo>/memory/hot-context.md` + git status. No vault.
- `statusline.sh` reads `agents.jsonl` (single source) instead of the now-deleted `live-activity.jsonl`.
- `install.sh` is now interactive, idempotent, validates schemas after install, and does **not** auto-register any MCP servers.
- `verify.sh` checks for the new structure (no vault, schemas present, tests directory present).
- `README.md` rewritten for v1.0.

### Removed

- `config/scripts/dashboard.sh` (terminal UI dashboard) — visualization, not a system surface.
- `config/scripts/flow-diagram.sh` (UI flow renderer) — same rationale.
- `config/scripts/live-update.sh` (Obsidian live-session writer) — Obsidian dependency.
- `config/scripts/curate-hot.sh` (vault HOT.md rotation) — vault concept removed.
- `config/skills/graphify/` (HTML knowledge graph generator) — UI artifact.
- `LEVANTAMIENTO.md` — replaced by `ARCHITECTURE.md` + this `CHANGELOG.md`.

### Migration from v0.4

1. `bash install.sh global` (idempotent; backs up your live `~/.claude/` first).
2. Move any custom content from `~/Obsidian/claude-brain/` into `<repo>/memory/patterns/`.
3. Remove `OBSIDIAN_VAULT` from your `~/.claude/settings.json` `env` block.
4. Remove `live-update.sh` hook bindings from your `~/.claude/settings.json` `hooks` block (look for `bash ~/.claude/scripts/live-update.sh`).
5. Run `bash ~/.claude/scripts/verify.sh` — should report all pass.

## [0.4.0] — 2026-05-03

### Added

- 6 agents: `business-analyst`, `mentor`, `optimizer`, `security-reviewer`, `tech-writer`, `uiux`.
- 1 skill: `graphify`.
- `LEVANTAMIENTO.md` documenting drift between live and repo.

### Changed

- `settings.example.json` merged: env vars + denies (from repo) + practical allow-list (from live).
- README counts updated: 18 agents, 4 skills, 11 commands, 6 hooks, 7 scripts.

## [0.3.0] — 2026-05-03

### Added

- Inter-agent memory templates under `~/.claude/agent-memory/<agent>/MEMORY.md`.
- Bilingual (ES/EN) routing keywords in `route-prompt.sh`.

### Changed

- 12 agents total (added `pm`, `data-engineer`).
- All agents get explicit CONTEXT + CHAIN + MEMORY execution steps.

## [0.2.0] — 2026-05-03

### Added

- 11 slash commands: `/agents`, `/bug-hunt`, `/content-update`, `/cto-review`, `/deep-debug`, `/mobile-audit`, `/parallel-research`, `/pr-preflight`, `/ship-it`, `/status`, `/wrap-up`.
- ES + EN routing keywords.

## [0.1.0] — 2026-05-01

### Added

- Initial 6 agents: `architect`, `code-reviewer`, `cto-strategist`, `debugger`, `security-auditor`, `test-engineer`.
- 5 hooks: `block-secrets`, `inject-context`, `log-agents`, `log-session`, `route-prompt`.
- 3 skills: `cto-thinking-system`, `ship-it`, `token-saver`.
- Constitution `CLAUDE.md` with the 5 questions + 10 principles.

[Unreleased]: https://github.com/wmarcelino-catalift/la-bestia/compare/v3.0.0...HEAD
[3.0.0]: https://github.com/wmarcelino-catalift/la-bestia/compare/v2.1.0...v3.0.0
[2.1.0]: https://github.com/wmarcelino-catalift/la-bestia/compare/v2.0.0...v2.1.0
[2.0.0]: https://github.com/wmarcelino-catalift/la-bestia/compare/v1.1.0...v2.0.0
[1.1.0]: https://github.com/wmarcelino-catalift/la-bestia/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/wmarcelino-catalift/la-bestia/compare/v0.4.0...v1.0.0
[0.4.0]: https://github.com/wmarcelino-catalift/la-bestia/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/wmarcelino-catalift/la-bestia/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/wmarcelino-catalift/la-bestia/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/wmarcelino-catalift/la-bestia/releases/tag/v0.1.0
