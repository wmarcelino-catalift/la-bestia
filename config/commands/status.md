---
description: "Session snapshot: active agents, recent activity, today's token cost, git state. Read-only — no side effects."
---

# /status

Print a single-screen status of the current Claude Code session.

## Plan (read-only)

The principal Claude reads four sources and renders a compact table:

1. `~/.claude/logs/.agent_start_*` markers → which agents are mid-run RIGHT NOW.
2. `<project>/.claude/logs/agents.jsonl` (or `~/.claude/logs/agents.jsonl`) → last 5 post-events.
3. `ccusage daily --json` (if installed) → today's spend.
4. `git status --short` + `git log -1 --oneline` → branch, uncommitted, last commit.

## Output format

```
🐺 La Bestia — session status

  Active now (live):     architect (running 12s)
  Last 5 agents:
    1. test-engineer · 42s · 1m ago
    2. code-reviewer · 18s · 4m ago
    3. architect     · 88s · 6m ago
    4. security      · 31s · 12m ago
    5. strategist    · 65s · 22m ago

  Cost today (ccusage):  $1.84
  Branch:                main · 3 uncommitted · last: a3f5e2 fix bug
  Logs:                  .claude/logs/agents.jsonl (1,247 events)
```

If a source is unavailable (e.g., ccusage not installed, no git repo), the line is omitted gracefully — never errors out.

## Implementation hints

The principal can compose this with bash one-liners; no new script required:

```bash
# Active agents
ls "$PROJ/.claude/logs/.agent_start_"* 2>/dev/null | sed 's/.*\.agent_start_//' | tr '\n' ',' | sed 's/,$//'

# Last 5 post events
tail -200 "$PROJ/.claude/logs/agents.jsonl" 2>/dev/null | \
  jq -r 'select(.event=="post" and .agent!="Bash" and .agent!="unknown") | "\(.agent)\t\(.duration)s\t\(.epoch)"' | \
  tail -5

# Cost today
ccusage daily --json 2>/dev/null | jq -r '.totals.totalCost // empty'

# Git
git status --short 2>/dev/null | wc -l
git log -1 --oneline 2>/dev/null
```

## Apply (none)

`/status` has no side effects. It does not write to memory, does not commit, does not invoke other agents.

## When NOT to use

- Mid-flow inside a `/flow` invocation — the skill itself prints phase banners.
- For post-mortem of a long session — use `bash bin/flow-viewer.sh ~/.claude/logs/agents.jsonl` instead (timeline gantt view).

## Chains

`(none)` — this is purely a read-out.
