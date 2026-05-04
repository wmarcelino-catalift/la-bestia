# QUICKSTART — La Bestia in 60 seconds

> First time using la-bestia? Start here. Total install + first useful action: ~3 minutes.

## TL;DR

```bash
# 1. Install once on this machine (~30 seconds)
git clone https://github.com/wmarcelino-catalift/la-bestia.git ~/code/la-bestia
cd ~/code/la-bestia && bash install.sh global

# 2. Bootstrap any project (~30 seconds)
cd /path/to/your/project
claude
> /onboard-project       # creates memory/, CLAUDE.md, .claudeignore

# 3. Use it
> /flow "build the auth flow"
```

That's it. The rest of this doc is explanation.

---

## What La Bestia does

It turns each Claude Code session into a **simulated team of 12 senior engineers**, each with:

- A real-world archetype (Werner Vogels, Linus Torvalds, Brendan Gregg, Bruce Schneier, Kent Beck, Don Norman, etc.)
- 20+ years of expertise framing
- Frontier-knowledge of 2026 best practices
- Anti-patterns they explicitly reject
- Memory that persists across sessions

When you write a prompt, the system reads an **Intent Map** in the constitution and dispatches the right agent (or several in parallel) — you don't manually pick.

---

## The 5 things you'll do daily

| Action                     | Command                               |
| -------------------------- | ------------------------------------- |
| Open Claude in any project | `claude` (in the project directory)   |
| Bootstrap a new project    | `/onboard-project` (once per project) |
| Build a feature end-to-end | `/flow "<feature description>"`       |
| Review a change            | `/cto-review`                         |
| Close a session cleanly    | `/wrap-up`                            |

The first time you use a feature, run `/agents` to see all 12 specialists, and read the **Intent Map** in `~/.claude/CLAUDE.md` §6.1 to understand routing.

---

## The 3 layers you control

```
1. Global config       ~/.claude/                  ← installed once via install.sh
   ├── CLAUDE.md       Constitution (5 questions + 10 principles + Intent Map)
   ├── settings.json   Model, hooks, permissions
   ├── agents/         12 archetype-grounded agents
   ├── skills/         4 progressive-disclosure skills
   ├── commands/       12 slash commands
   ├── hooks/          5 deterministic hooks
   ├── scripts/        3 operator utilities (statusline, verify, sync)
   ├── bin/            3 CLI utilities (compress, flow-viewer, onboard)
   └── agent-memory/   Per-agent memory across all your projects

2. Project memory      <repo>/memory/              ← created by /onboard-project
   ├── hot-context.md  ≤200-token state of THIS project
   ├── decisions/      ADRs (one-way doors)
   ├── patterns/       Recipes you discovered for THIS repo
   └── templates/      ADR + pattern templates

3. Project rules       <repo>/CLAUDE.md            ← project-level overrides
                       project rules + glossary + stack-specific quirks
```

The principal Claude reads layers 1 + 2 + 3 every session and decides which agent to call.

---

## What happens when you open `claude` in a project

```
1. Claude Code reads ~/.claude/CLAUDE.md (constitution)
2. Reads ~/.claude/settings.json (model, hooks)
3. Reads <repo>/CLAUDE.md if present (project rules — overrides global)
4. Fires SessionStart hook → inject-context.sh
   → Detects 15 stacks (Node.js, Python, Go, Rust, Expo, Docker, Terraform, etc.)
   → Injects git state (branch, uncommitted, recent commits, modified files)
   → Injects $today + last-24h top agents + project hot-context.md
5. Registers all 12 agents (lazy — body fetched on @mention)
6. Statusline polls agents.jsonl every render
7. You see a prompt — start typing
```

You don't see the SessionStart output in your terminal — it goes to Claude's context. To verify it loaded, ask: `qué sabés de este proyecto?` Claude should know your stack, branch, and hot-context.

---

## Your first feature with `/flow`

```
> /flow "build a waitlist signup form"
```

The system:

1. **Triage** — asks ONE question (Size + Touches).
2. **Phase 1 — DISCOVER** (parallel): dispatches `@strategist` + `@mentor` + `@architect` + (`@security` if it touches auth).
3. **HALT** — synthesizes findings, asks you `proceed / refine / stop`.
4. **Phase 2 — DEFINE** (parallel): `@architect` + `@data-engineer` (if data) + `@designer` (if UI) + `@security` (if sensitive).
5. **HALT** — produces ADR draft, awaits approval.
6. **Phase 3 — DEVELOP** (sequential TDD): `@test-engineer` writes failing tests → minimal code → `@code-reviewer` mid-stream review.
7. **Phase 4 — DELIVER** (parallel): `@code-reviewer` + `@security` + `@optimizer` + `@tech-writer`.
8. Outputs ready for `/ship-it`.

Total: 1 prompt from you. ~12-16 agent invocations across 4 phases. You only intervene at HALTs.

---

## Key cost-saving habits

| Habit                                                   | Saving                                                                  |
| ------------------------------------------------------- | ----------------------------------------------------------------------- |
| Run `/onboard-project` and fill `memory/hot-context.md` | 5-10× less code-reading per session (3-layer rule kicks in)             |
| Use `/wrap-up` at end of session                        | Persists pending work — next session resumes faster                     |
| Watch the statusline `$X.XXd/$Y.YYw`                    | See cost in real time. `⚠` at $20/day, `🚨` at $50/day                  |
| `/compact` when ctx ≥ 70%                               | Drops failed exploration, keeps decisions. ~30% saving on long sessions |
| `/clear` when switching tasks                           | Stale context costs every turn                                          |

---

## Health check

```bash
bash ~/.claude/scripts/verify.sh
```

Should report `✅ La Bestia v1.0 ready · 12 agents · 4 skills · 11 commands · 5 hooks · 3 bin`.

If anything fails, re-run `bash install.sh global` from the la-bestia repo (idempotent, backs up first).

---

## What NOT to do

| Don't                                           | Reason                                                                                        |
| ----------------------------------------------- | --------------------------------------------------------------------------------------------- |
| Edit `~/.claude/agents/*.md` directly           | Edit `<repo>/config/agents/<name>.md` in the la-bestia source, then `bash install.sh global`. |
| Edit `~/.claude/settings.json` for hook changes | Edit `config/settings.example.json` in source, then re-install.                               |
| Put project-specific stuff in global            | Use `<repo>/CLAUDE.md` for project rules.                                                     |
| Skip `/onboard-project` on a new repo           | The 3-layer memory rule won't engage — you lose 5-10× token savings.                          |
| Run `claude` as `root` / Administrator          | Hooks run with operator privileges; principle of least privilege.                             |

---

## Where to go next

- [`README.md`](../README.md) — full feature list
- [`ARCHITECTURE.md`](../ARCHITECTURE.md) — system design (read if you want to extend it)
- [`HOW-IT-WORKS.md`](./HOW-IT-WORKS.md) — runtime walkthrough of a session
- [`CONTRIBUTING.md`](../CONTRIBUTING.md) — how to add a new agent / hook / skill
- [`memory/decisions/`](../memory/decisions/) — ADRs explaining why the harness is the way it is

---

## Common confusions

**"Where does it install?"** → `~/.claude/` on your machine (Claude Code convention, not our choice).

**"Do I have to migrate?"** → No. Global lives in `~/.claude/`. Project memory in `<repo>/memory/`. They're separate.

**"Do agents talk to each other?"** → Through the principal Claude only. No background daemons, no event loop between turns.

**"Why don't I see the SessionStart hook output?"** → It goes to Claude's context, not your terminal. Ask `qué sabés del proyecto?` to verify Claude received it.

**"Multi-machine setup?"** → Clone la-bestia + `bash install.sh global` on each machine. Project memory follows the repo via git.

---

Done. Start with step 1 of the TL;DR above.
