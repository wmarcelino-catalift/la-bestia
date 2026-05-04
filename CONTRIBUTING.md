# Contributing to La Bestia

> The harness extends Claude Code, it does not replace it. Contributions that grow the surface beyond the [non-goals](./ARCHITECTURE.md#1-mission-and-non-goals) will be closed.

---

## Quick map of what lives where

| Want to add…                  | Edit                                                                  | Schema                         | Test                                    |
| ----------------------------- | --------------------------------------------------------------------- | ------------------------------ | --------------------------------------- |
| New agent                     | `config/agents/<name>.md`                                             | `schemas/agent.schema.json`    | `evals/agents/<name>/canonical.md`      |
| New skill                     | `config/skills/<name>/SKILL.md`                                       | `schemas/skill.schema.json`    | (none required, optional smoke test)    |
| New slash command             | `config/commands/<name>.md`                                           | (none)                         | manual smoke + doc the recipe           |
| New hook                      | `config/hooks/<name>.sh` + register in `config/settings.example.json` | `schemas/settings.schema.json` | **MANDATORY** `tests/hooks/<name>.bats` |
| New script (operator-invoked) | `config/scripts/<name>.sh`                                            | (none)                         | smoke test in `tests/scripts/`          |
| Memory template               | `memory/templates/<name>.md`                                          | (none)                         | (none)                                  |

Templates: `config/agents/_TEMPLATE.md`, `config/skills/_TEMPLATE/SKILL.md`, `config/commands/_TEMPLATE.md`. Copy and edit.

---

## Local dev loop

```bash
# 0. Clone and install dev deps
git clone https://github.com/wmarcelino-catalift/la-bestia.git
cd la-bestia
# Required: bash, jq, shellcheck, bats. Optional: ajv-cli for schema validation.

# 1. Make your change
$EDITOR config/agents/my-new-agent.md

# 2. Validate schemas locally
bash tests/run.sh schemas

# 3. Run hook tests
bash tests/run.sh hooks

# 4. Lint shell
shellcheck config/hooks/*.sh config/scripts/*.sh

# 5. Smoke install into a throwaway dir
bash install.sh project /tmp/bestia-smoke

# 6. Commit (Conventional Commits — enforced)
git commit -m "feat(agents): add my-new-agent"
```

CI runs the same validations. Anything that passes locally should pass in CI.

---

## Conventional Commits

Required format: `<type>(<scope>): <subject>`

| Type       | Use when                                      |
| ---------- | --------------------------------------------- |
| `feat`     | New agent, command, hook, skill, schema field |
| `fix`      | Bug fix in hook/script/agent prompt           |
| `refactor` | Restructure without behavior change           |
| `chore`    | Tooling, deps, CI plumbing                    |
| `docs`     | README / ARCHITECTURE / agent doc only        |
| `test`     | Tests added / changed                         |
| `perf`     | Performance fix in a hook/script              |

Scopes commonly used: `agents`, `hooks`, `skills`, `commands`, `scripts`, `schemas`, `evals`, `mcp`, `ci`, `install`, `repo` (umbrella).

The **subject** describes the change concretely. Banned subjects: `update code`, `fix stuff`, `add feature`, `wip`. PRs with banned subjects are auto-rejected by CI.

Breaking changes append `!` and explain in the body:

```
feat(agents)!: change frontmatter to require `model` field

BREAKING CHANGE: agents without `model:` will fail schema validation.
Run `bash tests/run.sh schemas` to find offenders.
```

---

## Branches

| Prefix      | Use                |
| ----------- | ------------------ |
| `feat/`     | New capability     |
| `fix/`      | Bug fix            |
| `refactor/` | No behavior change |
| `chore/`    | Plumbing           |
| `docs/`     | Doc only           |
| `test/`     | Test only          |

PR title MUST mirror the conventional commit. Squash-merge default; the merge commit becomes the changelog entry.

---

## Adding a new agent — full checklist

1. Copy `config/agents/_TEMPLATE.md` → `config/agents/<name>.md`.
2. Fill frontmatter (kebab-case `name`, `description` starts with "Use PROACTIVELY for"; declare `tools` and `model`).
3. Body: Personality (3-5 sentences) → `## Execution` numbered → `## Output contract` → `## Memory writes` → `## Chains`.
4. Add ADR in `memory/decisions/<NNNN>-<slug>.md` if the agent represents a new responsibility area not covered by existing agents.
5. Add `evals/agents/<name>/canonical.md` with at least 3 prompt+golden pairs.
6. Update `config/hooks/route-prompt.sh` with the keyword(s) that should route to this agent.
7. Update agent table in `README.md` and `ARCHITECTURE.md`.
8. CHANGELOG entry under `[Unreleased] → ### Added`.

CI gates: schema validation passes, route-prompt regex compiles, no duplicate `name`.

---

## Adding a new hook — full checklist

1. Copy an existing hook as starting point (e.g., `block-secrets.sh`).
2. Read input from `$CLAUDE_TOOL_INPUT`. Never `eval`.
3. Exit codes: `0` allow, `2` block. No other codes.
4. **Write `tests/hooks/<name>.bats`** with at least: 1 happy-path test, 1 block test, 1 graceful-degradation test (no `jq` available).
5. Register the hook in `config/settings.example.json` under `hooks.<event>`.
6. `shellcheck` clean.
7. p99 < 200ms (measured locally with `time bash config/hooks/<name>.sh < fixture.json`).
8. CHANGELOG entry.

---

## Reviews — what reviewers check

- Schema validation passes (CI hard gate).
- `bats` tests pass and **failed before the change** (TDD). Reviewer asks for the red-test commit if not obvious.
- No new tools added to `schemas/agent.schema.json` enum without ADR.
- No vault / Obsidian / external-memory references reintroduced.
- No UI surfaces (HTML, dashboards, image generators).
- Performance budget honored (manual time check on hooks).

Reviewers MUST cite `ARCHITECTURE.md` sections when rejecting on architectural grounds. "Doesn't fit the harness" without a citation is not a valid review.

---

## Releasing

1. PR titled `release: v<X.Y.Z>` from `main` to `main` (release-prep branch).
2. Update `CHANGELOG.md` `[Unreleased]` → `[X.Y.Z] — YYYY-MM-DD`.
3. Update README version row.
4. Merge → tag `v<X.Y.Z>` → push tag.
5. GitHub release notes = the CHANGELOG section verbatim.

No automated release. The release manager is human.
