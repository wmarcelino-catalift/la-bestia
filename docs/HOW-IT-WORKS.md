# How La Bestia works (runtime walkthrough)

> Operational reference for v1.0.
> For quickstart → [`../README.md`](../README.md). For system design → [`../ARCHITECTURE.md`](../ARCHITECTURE.md). For decisions → [`../memory/decisions/`](../memory/decisions/).

---

## Index

1. [What loads when you run `claude`](#1-what-loads-when-you-run-claude)
2. [How a prompt becomes work](#2-how-a-prompt-becomes-work)
3. [Where state lives (and where it doesn't)](#3-where-state-lives-and-where-it-doesnt)
4. [Observing what's happening](#4-observing-whats-happening)
5. [What's deterministic vs probabilistic](#5-whats-deterministic-vs-probabilistic)
6. [Recommended slash-commands & flows](#6-recommended-slash-commands--flows)
7. [Troubleshooting](#7-troubleshooting)

---

## 1. What loads when you run `claude`

```
claude   ──▶ reads ~/.claude/CLAUDE.md (constitution)
              reads ~/.claude/settings.json (model, hooks, permissions)
              reads <repo>/CLAUDE.md if present (project override)
              fires SessionStart hook → inject-context.sh
                  └─ injects <repo>/memory/hot-context.md + git status
              registers all 18 agents (lazy load — body fetched on @mention)
              registers all 11 commands (markdown recipes)
              registers all 3 skills (frontmatter eager, body lazy)
              statusline.sh polls ~/.claude/logs/agents.jsonl every render
```

There is no daemon, no background service, no continuous watcher. Hooks run only on the events Claude Code emits.

---

## 2. How a prompt becomes work

```
You type:  "revisa la arquitectura del módulo X"
              │
              ▼
UserPromptSubmit hook → route-prompt.sh
              │  matches keyword "arquitectura" → suggests @architect
              ▼
Principal Claude reads:
  • CLAUDE.md (constitution → 5 questions filter)
  • prompt
  • route-prompt suggestion
              │
              ▼
Decision: delegate to architect agent (matches description, plan-mode if complex)
              │
              ▼
PreToolUse Task → track-agent.sh writes pre-event to agents.jsonl
              │
              ▼
Architect runs in isolated context:
  1. Reads memory/hot-context.md (cheap)
  2. Reads relevant memory/decisions/<NNNN>-*.md (ADRs)
  3. Reads ~/.claude/agent-memory/architect/MEMORY.md (own learnings)
  4. Only THEN reads source code (3-layer rule)
  5. Produces ADR-shaped output, suggests chains (@cto-strategist if business decision, etc.)
              │
              ▼
PostToolUse Task → track-agent.sh writes post-event with duration
              │
              ▼
Principal synthesizes architect's summary, presents to you.
```

The principal never sees the architect's full reasoning — only the summary. That's by design (token efficiency + role separation).

---

## 3. Where state lives (and where it doesn't)

### Lives in your repo (committed, durable, project-scoped)

| Path                                  | Purpose                                     |
| ------------------------------------- | ------------------------------------------- |
| `<repo>/CLAUDE.md`                    | Project-level overrides to the constitution |
| `<repo>/memory/hot-context.md`        | ≤ 200 tokens, read every session            |
| `<repo>/memory/decisions/<NNNN>-*.md` | ADRs (one-way doors)                        |
| `<repo>/memory/patterns/<slug>.md`    | Reusable solutions for this repo            |
| `<repo>/.claudeignore`                | What Claude Code skips when reading         |

### Lives globally (not committed, cross-project)

| Path                                       | Purpose                            |
| ------------------------------------------ | ---------------------------------- |
| `~/.claude/CLAUDE.md`                      | Global constitution                |
| `~/.claude/settings.json`                  | Model, hooks, permissions          |
| `~/.claude/agents/*.md`                    | The 18 agent prompts               |
| `~/.claude/skills/<name>/SKILL.md`         | The 3 skills                       |
| `~/.claude/commands/*.md`                  | The 11 slash commands              |
| `~/.claude/hooks/*.sh`                     | Deterministic event handlers       |
| `~/.claude/scripts/*.sh`                   | Operator-invoked utilities         |
| `~/.claude/agent-memory/<agent>/MEMORY.md` | Per-agent learnings, cross-session |

### Lives in the project's runtime dir (gitignored)

| Path                                              | Purpose                                   |
| ------------------------------------------------- | ----------------------------------------- |
| `<project>/.claude/logs/agents.jsonl`             | Audit log — agent invocations + durations |
| `<project>/.claude/logs/bash.jsonl`               | Audit log — bash commands                 |
| `<project>/.claude/logs/sessions/session-<ts>.md` | Per-session summary (Stop hook)           |
| `<project>/.claude/logs/.agent_start_<name>`      | Transient timing markers                  |

### Does NOT exist (anymore)

- ~~`~/Obsidian/claude-brain/`~~ — vault concept removed in v1.0 (ADR-0002).
- ~~`<project>/.claude/vault/HOT.md`~~ — same.
- ~~`live-activity.jsonl`~~ — merged into `agents.jsonl`.

---

## 4. Observing what's happening

### Statusline (always visible)

```
🐺 La Bestia · opus · ⚡architect · last: code-reviewer 12s (32s ago) · $1.42
```

Reads from `agents.jsonl` (last post-event) and `ccusage` (today's $).
If you see `· ⚡<name>` it means an agent is currently mid-run (started but not yet completed).

### Audit log

```bash
tail -f <project>/.claude/logs/agents.jsonl | jq .
```

Each line: `{ts, epoch, event, tool, agent, desc, duration}`.
Validated by `schemas/log-event.schema.json`. No prompt bodies (only descriptions/commands) — by design, for privacy.

### Cost

```bash
ccusage daily    # today
ccusage          # all-time
```

Integrated into the statusline already (the `$1.42` you see).

### Session summaries

After each `claude` session ends, the Stop hook writes `<project>/.claude/logs/sessions/session-<ts>.md` with: branch, uncommitted-count, agents used (last 24h, ranked), files modified.

---

## 5. What's deterministic vs probabilistic

| Layer                                     | Deterministic?    | Notes                                                                                                                  |
| ----------------------------------------- | ----------------- | ---------------------------------------------------------------------------------------------------------------------- |
| Hooks (block-secrets, route-prompt, etc.) | **yes**           | Bash scripts. Tested with `bats`. They cannot hallucinate.                                                             |
| Permissions (allow/deny in settings.json) | **yes**           | Claude Code enforces these gates.                                                                                      |
| Schema validation (CI)                    | **yes**           | JSON Schema + ajv.                                                                                                     |
| Agent dispatch                            | **probabilistic** | The principal decides which agent to call based on prompt + agent descriptions. The route-prompt hook only _suggests_. |
| Agent output                              | **probabilistic** | LLM. Use evals (`evals/`) for regression detection, not for absolute correctness.                                      |
| Tool selection within an agent            | **constrained**   | Agent's frontmatter `tools:` is a closed set. The agent cannot use other tools.                                        |

**Rule of thumb**: anything in bash/JSON Schema is deterministic. Anything in markdown agent prompts is probabilistic. Don't put load-bearing logic in agent bodies — put it in hooks.

---

## 6. Recommended slash-commands & flows

### Daily

```
/agents                              # remind yourself who's available
/cto-review                          # CTO senior review of current change
/ship-it                             # pre-merge gates → commit → PR description
/wrap-up                             # close session, draft memory update
```

### When stuck

```
/deep-debug "<bug description>"      # auto-switch to Opus + debugger agent
/parallel-research "<question>"      # 3-5 agents fan-out across dimensions
/bug-hunt                            # 3 agents per layer (UI/Service/Data)
```

### Pre-merge

```
/pr-preflight                        # git state, ahead/behind, secrets scan
/ship-it                             # tests + linter + secrets + review chain
```

### Operator-only (bash, not slash)

```bash
bash ~/.claude/scripts/verify.sh                # health check
bash ~/.claude/scripts/sync-to-bestia.sh        # push live changes back to la-bestia repo
ccusage daily                                   # cost
```

---

## 7. Troubleshooting

### Hook didn't fire

- `cat ~/.claude/settings.json | jq '.hooks'` — is it registered?
- `bash ~/.claude/hooks/<name>.sh` — does it run standalone?
- Hooks need shell tools they declare. Missing `jq`? They degrade, but to less helpful output.

### `block-secrets` blocked a legitimate write

- Read the stderr — which pattern matched?
- For `.env*`-named files: rename to something unambiguous (e.g., `config.example.json`) and copy contents.
- For content-pattern matches: review the content — most "false positives" are real near-misses.
- If the regex is genuinely wrong: open an issue with the false-positive case; we add a `bats` test and refine.

### Statusline missing agent / cost info

- `agents.jsonl` not yet populated → first agent run will populate it.
- `ccusage` not installed → cost segment is silently omitted. Install with `npm i -g ccusage`.

### Verify reports failures

- Run `bash ~/.claude/scripts/verify.sh` — it tells you which checks failed.
- Most common cause: stale v0.x leftovers (vault dir, `live-update.sh`). Solution: `bash install.sh global` re-runs idempotently and cleans them via the install backup.

### Hook is slow (> 200ms)

- That's a CI warning surface. File an issue with the hook name.
- Workaround: temporarily mark the hook async in your local `settings.json` (`"async": true`).

### Want to add a new agent / hook / skill

- See [`../CONTRIBUTING.md`](../CONTRIBUTING.md) — full checklists per surface.
