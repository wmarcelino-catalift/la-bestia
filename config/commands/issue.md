---
description: "Create / list / triage GitHub issues using gh CLI. Wraps issue management with la-bestia agents for triage."
argument-hint: "create|list|triage [args]"
---

# /issue $ARGUMENTS

GitHub issue management via `gh` CLI. Three subcommands.

## Plan (read-only)

The principal parses `$ARGUMENTS` and routes to one of:

### `/issue list [filter]`

Run:

```bash
gh issue list --state open --limit 30
```

Then apply Intent Map: if operator asks for triage, dispatch `@strategist` to RICE-rank the open issues.

### `/issue create "<title>" [--label X --assignee Y]`

Create new issue with the given title. Body comes from a structured template:

```markdown
## Context

(operator describes the problem)

## Acceptance criteria

(testable bullets — what does "done" look like?)

## Estimated impact

RICE: Reach × Impact × Confidence / Effort = ?

## Related

- Recent ADR / pattern / file
```

The principal asks for these via `AskUserQuestion` if not provided in `$ARGUMENTS`.

Then:

```bash
gh issue create --title "<title>" --body "$BODY" --label "$LABELS"
```

### `/issue triage <number>`

Read the issue body + comments, then:

1. Dispatch `@strategist` for RICE scoring + JTBD alignment
2. Dispatch `@architect` if it's a system-design topic
3. Dispatch `@security` if it touches auth/payments/PII
4. Sythesize → propose label assignments (e.g., `priority:p1`, `type:bug`)
5. Apply labels via `gh issue edit <num> --add-label`

## Apply (gated)

For `create` and `triage` (which mutate GitHub state), the principal MUST confirm with the operator before executing the `gh` command. Format:

```
About to create issue:
  Title: <title>
  Labels: <labels>
  Body: <preview, first 200 chars>...

Confirm? [yes / edit / cancel]
```

## Idempotency

- `list` is read-only, fully idempotent.
- `create` is NOT idempotent (creates new issue each call). Don't auto-loop.
- `triage` reads + edits. Repeat with same input → same labels, no duplicates.

## Requirements

- `gh` CLI installed and authenticated (`gh auth status`)
- Run inside a git repo with a `gh`-recognized origin

If `gh` not available, the command exits with a clear instruction:

```
✗ gh CLI not installed. Install:
  macOS:   brew install gh
  Linux:   apt install gh / dnf install gh
  Windows: scoop install gh / winget install GitHub.cli
```

## Chains

- `@strategist` for triage RICE scoring
- `@architect` for design-question issues
- `@security` for auth/payments/PII issues
- `/parallel-research` for issues that need cross-team perspective
