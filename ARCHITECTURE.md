# ARCHITECTURE — La Bestia v1.0

> System design document. Source of truth for "how it works" and "why".
> Audience: contributors. For users → [README.md](./README.md). For decisions → [`memory/decisions/`](./memory/decisions/).

---

## 1. Mission and non-goals

**Mission.** Provide a deterministic, testable, MCP-ready harness for Claude Code that turns a single developer (or small team) into a CTO-grade operator. Optimized for reliability, cost discipline, and reasoning depth — not for visual polish.

**Non-goals.**

- Web UI, dashboards, knowledge-graph viewers, or any rendered output beyond terminal text.
- External vault dependencies (Obsidian, Notion, Roam). All memory is repo-local or `~/.claude/`-local.
- Replacing Claude Code's native features. We extend, never re-implement.
- SaaS / multi-tenant. This is a single-operator harness.
- "Smart" autoformat, "smart" anything that is not deterministic.

---

## 2. System layers

```
┌──────────────────────────────────────────────────────────────────┐
│  L7  Operator       (you, the human)                              │
├──────────────────────────────────────────────────────────────────┤
│  L6  Constitution   CLAUDE.md (5 questions, 10 principles)        │
├──────────────────────────────────────────────────────────────────┤
│  L5  Routing        UserPromptSubmit hook → suggests agent        │
├──────────────────────────────────────────────────────────────────┤
│  L4  Agents         18 specialized prompt-personas (Read/Write…)  │
│      Skills         4 progressive-disclosure capabilities         │
│      Commands       11 slash recipes                              │
├──────────────────────────────────────────────────────────────────┤
│  L3  Safety         block-secrets hook · permission allow/deny    │
├──────────────────────────────────────────────────────────────────┤
│  L2  Memory         repo/memory/* + ~/.claude/agent-memory/*      │
├──────────────────────────────────────────────────────────────────┤
│  L1  Telemetry      JSONL logs (agents, bash, sessions)           │
├──────────────────────────────────────────────────────────────────┤
│  L0  MCP            integrations (GitHub, Postgres, Linear, …)    │
└──────────────────────────────────────────────────────────────────┘
```

Each layer has a single responsibility and is independently testable.

---

## 3. Component contracts

### 3.1 Agents (`config/agents/*.md`)

Each agent file MUST have YAML frontmatter validating against [`schemas/agent.schema.json`](./schemas/agent.schema.json):

```yaml
---
name: architect # kebab-case, unique
description: "Use PROACTIVELY for…" # 1-2 sentences, used by routing
tools: [Read, Write, Glob, Grep, Bash]
model: claude-opus-4-7 # or claude-sonnet-4-6, claude-haiku-4-5
---
```

Body MUST contain these sections in order:

1. `# <NAME>` — H1 with the agent name
2. Personality paragraph (3-5 sentences, mentions a real-world archetype)
3. `## Execution` — numbered steps the agent runs every invocation
4. `## Output contract` — what the agent returns (structure, severity tags)
5. `## Memory writes` — declares which files the agent persists to under `~/.claude/agent-memory/<name>/`
6. `## Chains` — agents this one delegates to (named via `@agent-name`)

The agent MUST NOT use tools not declared in its frontmatter.

### 3.2 Skills (`config/skills/<name>/SKILL.md`)

Frontmatter validating against [`schemas/skill.schema.json`](./schemas/skill.schema.json):

```yaml
---
name: ship-it
version: 1.2.0 # SemVer
description: "Pre-merge quality gates…"
triggers: [commit, PR, merge, ship]
---
```

Body: short metadata (≤ ~100 tokens visible). Full recipe lives below the metadata and is loaded only when triggered (progressive disclosure).

### 3.3 Commands (`config/commands/*.md`)

Markdown recipes for slash commands. Composable: a command MAY invoke other commands. MUST be idempotent — running twice has the same effect as running once. MUST NOT cause side effects without an explicit `## Apply` section gated by user confirmation.

### 3.4 Hooks (`config/hooks/*.sh`)

Bash scripts triggered by Claude Code events. Each MUST:

- Pass `shellcheck` clean (`SC2034`/`SC2154` allowed only when justified inline).
- Have at least one `bats` test in `tests/hooks/`.
- Complete in **< 200ms p99** on a warm shell (measured by `tests/perf/`).
- Use exit codes per [Claude Code spec](https://docs.claude.com/claude-code/hooks): `0` = allow/no-op, `2` = block.
- Read input from `$CLAUDE_TOOL_INPUT` (env var). Never `eval`.
- Write nothing to user-visible stdout for `0` exits (only stderr for `2` blocks).

### 3.5 Scripts (`config/scripts/*.sh`)

Operator-invoked utilities, not auto-triggered. MUST be idempotent. MUST exit non-zero on any failure (`set -euo pipefail`).

### 3.6 Settings (`config/settings.example.json`)

Validates against [`schemas/settings.schema.json`](./schemas/settings.schema.json), itself a strict subset of Claude Code's settings shape. CI rejects any drift.

---

## 4. Memory architecture

Four explicit layers, no external vaults:

| Layer           | Path                                       | Scope                              | Token budget   | Update cadence                            |
| --------------- | ------------------------------------------ | ---------------------------------- | -------------- | ----------------------------------------- |
| L1 hot-context  | `<repo>/memory/hot-context.md`             | per-project                        | ≤ 200 tok      | every session via `/wrap-up`              |
| L2 ADRs         | `<repo>/memory/decisions/<NNNN>-<slug>.md` | per-project, immutable once merged | unlimited      | one per one-way-door                      |
| L3 patterns     | `<repo>/memory/patterns/<slug>.md`         | per-project                        | ≤ 500 tok each | as discovered                             |
| L4 agent-memory | `~/.claude/agent-memory/<agent>/MEMORY.md` | per-agent, cross-project           | ≤ 1k tok each  | the agent writes after consequential runs |

**Resolution order in agent prompts** (cheapest first):

1. L1 hot-context
2. L2 most recent ADR + L3 patterns matched by keyword
3. L4 agent's own memory
4. Source code

If layers 1–3 answer the question, the agent MUST NOT read source code. This is enforced by the agent prompt template, not the harness.

Templates live in [`memory/templates/`](./memory/templates/).

---

## 5. Safety model

### 5.1 Threat model (high level)

See [SECURITY.md](./SECURITY.md) for full STRIDE. Top three risks:

| Risk                                                              | Mitigation                                                                                                  |
| ----------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| Accidental secret commit                                          | `block-secrets.sh` hook + permission `deny` for `Write(**/.env)` etc.                                       |
| Destructive bash (rm -rf, push --force to main)                   | Permission `deny` patterns + `PreToolUse Bash` hook regex                                                   |
| Prompt injection from observed content (web pages, file contents) | Constitutional safety rules (in CLAUDE.md) + user-confirmation required for any externally-suggested action |

### 5.2 Defense in depth

1. **Permission allowlist** in settings — first gate.
2. **Permission denylist** — second gate (always wins over allow).
3. **PreToolUse hooks** — programmable third gate (regex).
4. **PostToolUse formatter** — no security role; cosmetic only.
5. **Audit log** — every tool call appended to `agents.jsonl` / `bash.jsonl` for incident review.

### 5.3 Out of scope

- Filesystem sandbox (relies on OS).
- Network egress controls (relies on OS / corporate proxy).
- Secret scanning of _existing_ repo content (use `gitleaks`, not us).

---

## 6. Telemetry

Three append-only JSONL streams in `~/.claude/logs/` (or `<repo>/.claude/logs/` for project-local installs):

| Stream                     | Schema                                         | Used by                 |
| -------------------------- | ---------------------------------------------- | ----------------------- |
| `agents.jsonl`             | `{ts, session, event, agent, desc, duration?}` | `/status`, eval reports |
| `bash.jsonl`               | `{ts, session, event, cmd, cwd}`               | incident review         |
| `sessions/session-<ts>.md` | markdown summary                               | `/wrap-up`              |

No PII fields by design. Logs MUST NOT contain prompt bodies, only descriptions/commands. Cost telemetry comes from `ccusage` (separate tool, integrated via `statusline.sh`).

---

## 7. MCP integration (L0)

The harness ships **zero** MCP servers wired by default — that is a deliberate one-way door. Operators choose which MCP servers to register based on their stack. See [`mcp/README.md`](./mcp/README.md) for templates covering the most common cases (GitHub, Postgres, Linear, Sentry, Slack).

Rationale: a hardcoded MCP set leaks operator context (e.g., a Linear org slug) into the public repo and creates supply-chain risk for users who don't need those integrations.

---

## 8. Evals

`evals/` contains a tiny snapshot-eval framework. Each agent has `evals/agents/<name>/canonical.md` with 3-5 fixed prompts and human-curated golden outputs. `evals/run.sh` runs them against the current Claude version and produces a diff report. Diffs are reviewed manually — we do not auto-pass on string equality (LLM outputs vary).

CI runs evals as a non-blocking signal (PRs can merge with eval drift, but the drift is surfaced for review).

---

## 9. CI/CD

GitHub Actions workflows in `.github/workflows/`:

| Workflow    | Trigger         | Gates                                                                          |
| ----------- | --------------- | ------------------------------------------------------------------------------ |
| `ci.yml`    | PR + push main  | shellcheck (hard), bats (hard), schema validation (hard), markdown lint (soft) |
| `evals.yml` | manual dispatch | runs `evals/run.sh`, posts diff report                                         |

Hard gates block merge. Soft gates produce warnings only.

Releases are tagged `v<MAJOR>.<MINOR>.<PATCH>` per SemVer. `CHANGELOG.md` follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

---

## 10. Versioning policy

The harness as a whole has a SemVer version. Component-level breaking changes:

| Change                                                             | Bump          |
| ------------------------------------------------------------------ | ------------- |
| Add new agent / skill / command                                    | minor         |
| Modify hook signature, agent frontmatter shape, or settings schema | major         |
| Bug fix in a hook or script                                        | patch         |
| Doc-only update                                                    | none (no tag) |

Breaking changes ship with a migration guide section in CHANGELOG and an entry in `memory/decisions/`.

---

## 11. Performance budgets

| Surface                            | p99 budget | Measured by             |
| ---------------------------------- | ---------- | ----------------------- |
| Any hook                           | 200 ms     | `tests/perf/` (TODO)    |
| `inject-context.sh` (SessionStart) | 500 ms     | same                    |
| `statusline.sh`                    | 100 ms     | observed (`time` in CI) |
| `verify.sh` full run               | 5 s        | observed                |

Exceeding budget is a CI warning. Repeated exceedance opens an issue.

---

## 12. Failure modes (designed for)

| Failure                                 | Behavior                                                                                        |
| --------------------------------------- | ----------------------------------------------------------------------------------------------- |
| `jq` not installed                      | Hooks degrade gracefully, write minimal log entry, do not block                                 |
| `git` not in repo                       | `inject-context` skips git block, continues                                                     |
| `~/.claude/agent-memory/<x>/` missing   | Agent creates on first write, no error                                                          |
| Hook regex bug blocks legitimate writes | Operator escapes via `--allow` flag (TODO) or `git commit --no-verify` (audited via bash.jsonl) |
| Claude model deprecated                 | Frontmatter pin produces error → operator updates (no silent fallback)                          |

---

## 13. Operating principles (the 10, applied to harness itself)

| #   | Principle        | How the harness honors it                                                                                          |
| --- | ---------------- | ------------------------------------------------------------------------------------------------------------------ |
| 1   | TDD              | Every hook has a `bats` test that ran red before the hook existed                                                  |
| 2   | YAGNI            | We deleted `dashboard.sh`, `flow-diagram.sh`, `graphify` skill, vault rotation. They were not earning their tokens |
| 3   | DRY              | Shared helpers in `config/scripts/_lib.sh` (TODO when we have ≥3 duplicates)                                       |
| 4   | Fail loud        | Hooks exit 2 with stderr message. No silent block                                                                  |
| 5   | Idempotent       | Every script and hook re-runnable safely                                                                           |
| 6   | Secrets in env   | `block-secrets` hook + permission denies                                                                           |
| 7   | Reversible       | All "destructive" commands require operator confirm. No `--force` automation                                       |
| 8   | Logs as contract | JSONL schemas in [`schemas/`](./schemas/)                                                                          |
| 9   | Boring tech      | bash + jq + bats + GitHub Actions. No bespoke runtime                                                              |
| 10  | Observability    | Three log streams + statusline + ccusage integration                                                               |

---

## 14. Open questions / TODOs (tracked in issues, not here)

- Performance test harness (`tests/perf/`) — currently absent.
- Cross-platform CI (Linux + macOS + Windows Git Bash). Currently Linux only.
- Multi-operator install (team-shared `~/.claude/`) — explicitly out of scope today.
- ADR template enforcement (linter for `memory/decisions/`).
- Eval golden-set bootstrapping for the 6 newer agents (business-analyst, mentor, optimizer, security-reviewer, tech-writer, uiux).
