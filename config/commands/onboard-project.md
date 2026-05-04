---
description: "Bootstrap la-bestia for the current project: scan repo, fill memory/hot-context.md, suggest first ADR, detect stack."
argument-hint: "(no args)"
---

# /onboard-project

Bootstraps la-bestia in the current project. Idempotent — safe to re-run.

## Plan (read-only)

1. Detect stack from manifest files (`package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, etc.).
2. Read git: branch, recent 10 commits, modified files, ahead/behind upstream.
3. Sample top-level directories (`src/`, `apps/`, `services/`, `packages/`).
4. Count tests, lint config, CI presence.
5. Check for existing `<repo>/CLAUDE.md`, `<repo>/memory/`, `<repo>/.claudeignore`.

Produce a draft of `memory/hot-context.md`:

```markdown
# hot-context.md — <project name>

## Project

- **App:** <detected name>
- **Stack:** <detected stack>
- **Stage:** [pre-launch | production | maintenance] ← OPERATOR FILLS

## Current focus

- <inferred from recent commits + branch name>

## Recent decisions

- <YYYY-MM-DD>: <one-liner per recent ADR if any>

## Pending

- [ ] <inferred from TODOs + branch name>

## Gotchas

- <inferred from .gitignore secrets, CI gotchas, etc>
```

## Apply (gated on operator confirmation)

If the operator confirms with `yes`:

1. Run `bash bin/onboard.sh` to write the files:
   - Create `<repo>/memory/{decisions,patterns,templates}/` if missing.
   - Write `<repo>/memory/hot-context.md` (only if missing — never overwrite).
   - Write `<repo>/.claudeignore` from template (only if missing).
   - Write `<repo>/CLAUDE.md` stub for project-level overrides (only if missing).
   - Suggest `memory/decisions/0001-<slug>.md` based on the most recent significant commit.

2. Print a "next steps" checklist:
   - Edit `memory/hot-context.md` to fill the `[OPERATOR FILLS]` slots.
   - Read `memory/templates/adr.md` for the ADR template.
   - Run `bash ~/.claude/scripts/verify.sh` to confirm install.

## Idempotency

Re-runs DO NOT overwrite existing files. They detect what exists and skip.
Safe to run on a project that's been onboarded before — no-op effectively.

## When NOT to use

- Projects already onboarded with hot-context.md filled — re-running is a no-op, but `/wrap-up` is the right tool to update.
- Mid-session — onboarding is a one-time setup, not a per-session ritual.

## Output

```
## Onboard report — <project name>

### Detected
- Stack: Node.js + TypeScript + Postgres + Vercel
- Branch: main · 3 commits ahead · last: a3f5e2 fix bug
- Tests: 247 (Vitest detected) · CI: GitHub Actions
- Existing memory: none

### Created
- memory/hot-context.md (draft — fill `[OPERATOR FILLS]`)
- memory/decisions/ (empty)
- memory/patterns/ (empty)
- .claudeignore (from template)
- CLAUDE.md (project-level stub)

### Suggested first ADR
Based on commit "a3f5e2 fix auth flow", consider:
  memory/decisions/0001-auth-flow.md

### Next steps
[ ] Edit memory/hot-context.md
[ ] Run /wrap-up at end of next session to populate Pending
[ ] If you have one-way doors planned, draft an ADR
```

## Chains

`(none)` — this is operational, not analytic.
