# CI broken silently for 6 versions — colon-space in inline `run:` rejected the workflow

- **Date**: 2026-05-04
- **Author**: claude (during v4.2.0/v4.2.1/v4.2.2 ship)
- **Tags**: ci, github-actions, yaml, silent-failure, debt-discovery

## Context

After shipping v4.2.0 with 4 ecosystem-gap closures, the user asked "did it work?". I checked GitHub Actions and found every CI run since v3.0 had `conclusion: failure`, `duration: 0s`, `total_jobs: 0`.

## Symptom

```text
$ gh run list --limit 5
completed	failure	feat: v4.2.1 ...   ci    main    push   25342465876   0s   ...
completed	failure	feat: v4.2.0 ...   ci    main    push   25341178242   0s   ...
completed	failure	feat: v4.1.0 ...   ci    main    push   25330185957   0s   ...
[every release since v3.0 — same pattern]

$ gh run view <ID>
X This run likely failed because of a workflow file issue.
```

`actions/runs/<ID>/jobs` returned `total_count: 0`. The workflow file was being parsed but generating zero jobs.

## Investigation

- ✓ ruled out: action version pins (`ludeeus/action-shellcheck@2.0.0` exists)
- ✓ ruled out: GitHub Actions disabled (`enabled: true`)
- ✓ ruled out: billing/quota (public repo, free tier)
- ✓ ruled out: BOM / encoding (clean UTF-8)
- ✗ found via local `js-yaml` parse:
  ```
  YAML parse error at line 38 col 115
  Reason: bad indentation of a mapping entry
  ```

Line 38:

```yaml
run: node -e "JSON.parse(require('fs').readFileSync('.claude-plugin/plugin.json','utf8')); console.log('ok: .claude-plugin/plugin.json')"
```

The string `'ok: .claude-plugin/plugin.json'` contains `: ` (colon-space) which YAML treats as a mapping separator inside a flow scalar. Since the `run:` value wasn't itself quoted with YAML's quoting (single-quoted scalar or `|`/`>` block), YAML parsed `node -e "...console.log('ok` as the value, then expected a key after `:` and got the rest.

## Root cause

YAML 1.1 / 1.2 spec: in a flow scalar, `: ` (colon then whitespace) ends the value and starts a new mapping key. Bash command strings that include shell quoting are NOT automatically YAML-safe.

GitHub Actions parses the workflow against its own schema and **silently rejects malformed workflows**, generating a `failure` run with 0 jobs instead of an error message. The UI hint "workflow file issue" is the only signal — and it doesn't even point at the line.

## Fix

```diff
- run: node -e "JSON.parse(require('fs').readFileSync('.claude-plugin/plugin.json','utf8')); console.log('ok: .claude-plugin/plugin.json')"
+ run: |
+   node -e "JSON.parse(require('fs').readFileSync('.claude-plugin/plugin.json','utf8')); console.log('ok plugin.json')"
```

The `|` block scalar passes the whole following indented block through verbatim. Also dropped the `: ` from the success message for safety.

Once this landed, the CI fired for the first time in 5 versions and surfaced **9 latent bugs** in production hooks/scripts (route-prompt's Intent Map regressions, architecture-gate's miscounted directories, etc.). All fixed in v4.2.2.

## Detection next time

Three independent signals would have caught this earlier:

1. **Pre-merge YAML lint**: add to `.github/workflows/ci.yml` itself — paradox aside, a separate `pre-receive` hook or local pre-commit running `yamllint .github/workflows/*.yml`.
2. **Watch run duration**: any CI run completing in `<5s` should be alerting — there's no real CI that takes <5s.
3. **Watch `total_jobs`**: a run with `0` jobs and `failure` conclusion means workflow rejected, not "all tests pass". Add to operator's status dashboard.

Lesson for hooks generally: **silence is not success**. If a hook / CI / job runs in suspiciously little time and produces no output, the most likely cause is that it never actually ran.

## Related

- ADR: [`memory/decisions/0006-v4.2-resilience-loops.md`](../decisions/0006-v4.2-resilience-loops.md) — the v4.2.x release this was discovered during.
- Pattern (future): consider adding `memory/patterns/yaml-safe-run-commands.md` if this pattern recurs in CI work.
- Skill: [`config/skills/lessons-loop/SKILL.md`](../../config/skills/lessons-loop/SKILL.md) — this lesson is the first canonical use of that skill.
