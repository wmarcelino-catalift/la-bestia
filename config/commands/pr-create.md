---
description: "Create a GitHub PR from current branch with auto-generated title (Conventional Commits) + body (test plan + summary). Wraps gh CLI."
argument-hint: "[--draft] [--base main]"
---

# /pr-create $ARGUMENTS

Create a PR from the current branch. Generates Conventional-Commit title + structured body automatically from git log + diff.

## Plan (read-only)

1. **Preflight check** — fail loud if any of:
   - Not in a git repo
   - On default branch (main / master / develop)
   - Working tree dirty (uncommitted changes)
   - Branch has zero commits ahead of base
   - `gh` CLI not installed or not authenticated

2. **Auto-generate title** from the most recent commit message on this branch:
   - If it follows Conventional Commits (`feat:`, `fix:`, `refactor:` etc.): use as-is
   - Else: dispatch `@tech-writer` to propose 3 title options

3. **Auto-generate body** with sections:

   ```markdown
   ## Summary

   (1-3 bullets distilled from the commits on this branch)

   ## What changed

   (file count + categories — code/tests/docs/config)

   ## Test plan

   - [ ] (auto-generated from changed test files)
   - [ ] (manual smoke checklist if applicable)

   ## Out of scope

   (explicit non-goals — what this PR does NOT touch)

   ## Related

   - ADR: <link if a new one was created>
   - Issue: <auto-link if branch name has #N>
   ```

4. **Run `/ship-it` quality gates** internally before opening PR:
   - shellcheck / lint / type-check pass
   - Tests pass
   - No secrets in diff (block-secrets-style scan)
   - CHANGELOG updated if `feat`/`fix`/`refactor`/`perf`

5. **Show preview** to operator with full title + body + base branch + draft flag.

## Apply (gated on operator confirmation)

Operator confirms → execute:

```bash
gh pr create \
  --title "$TITLE" \
  --body "$BODY" \
  --base "$BASE" \
  ${DRAFT_FLAG}
```

Default `--base main`. `--draft` adds `--draft`.

## Output

```
## PR created

  URL: https://github.com/<org>/<repo>/pull/<num>
  Title: feat(scope): description
  Base: main
  Draft: yes / no

  Test plan auto-generated:
  - [ ] tests/<file>.bats — new cases for X
  - [ ] manual: run flow on a sample project

  Next: paste URL into your PR tracker / notify reviewers
```

If quality gates failed, the principal halts before opening:

```
🔴 Quality gates failed — PR creation blocked

  - shellcheck: 2 errors in config/hooks/X.sh
  - tests: 1 case failing in tests/scripts/Y.bats

Fix or override (--force-after-failure)?
```

## Idempotency

- Re-running `/pr-create` on the same branch produces the same title + body (deterministic from git log).
- If a PR already exists for this branch, it errors clearly: `gh pr create` returns non-zero.
- Operator can use `gh pr edit <num>` to update an existing PR — out of scope here.

## Chains

- `@tech-writer` for title polish if commits are vague
- `@code-reviewer` for body's "what changed" summary if diff is complex
- `/ship-it` skill auto-activates for the quality gates step

## Requirements

- `gh` CLI authenticated
- At least one commit on the current branch ahead of base
- Working tree clean (or operator confirms `--allow-dirty`)
