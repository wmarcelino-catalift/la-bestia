# Security Policy

## Reporting a vulnerability

Please do **not** open public GitHub issues for security findings. Email the maintainer at the address in the repo's GitHub profile, or use a private vulnerability report (`Security` tab → `Report a vulnerability`).

Acknowledgement target: 72 hours. Fix-or-mitigation target: 14 days for high severity, 30 days for medium, best-effort for low.

The harness ships zero secrets, so the realistic blast radius of a vulnerability here is **operator's machine**, not a fleet. We size our response accordingly.

---

## Threat model (STRIDE summary)

| Threat                     | Vector                                                         | Mitigation                                                                                                                                     |
| -------------------------- | -------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| **S**poofing               | Prompt-injected content claims "the user authorized X"         | Constitution requires user confirmation in chat; observed content cannot grant authorization. See `~/.claude/CLAUDE.md`.                       |
| **T**ampering              | Malicious PR adds a hook that exfiltrates `~/.aws/credentials` | CI runs `shellcheck` + `bats`; reviewers required for hook changes; CODEOWNERS enforces.                                                       |
| **R**epudiation            | Agent makes destructive change, operator denies authorizing it | Audit log: every Bash and Task tool call appended to `agents.jsonl` / `bash.jsonl` with timestamps.                                            |
| **I**nformation disclosure | Hook accidentally logs `.env` contents                         | `block-secrets.sh` prevents writes; logs only command/desc, never tool input bodies. JSONL schema enforces.                                    |
| **D**enial of service      | Hook with bad regex blocks all writes                          | Per-hook p99 budget < 200ms; bats test for graceful no-op when input absent. Operator escape: temporarily move `config/hooks/<name>.sh` aside. |
| **E**levation of privilege | Hook escalates to root via `sudo`                              | Permission `deny` for `sudo *` patterns; hooks MUST NOT call sudo (CI lint TODO).                                                              |

---

## Scope

In scope:

- The hooks and scripts in `config/`.
- The schemas and CI workflows.
- The `install.sh` installer.
- Default `config/settings.example.json` shipped with releases.

Out of scope:

- Vulnerabilities in Claude Code itself (report to Anthropic).
- Vulnerabilities in user-customized `~/.claude/settings.json` (operator-owned).
- Vulnerabilities in third-party MCP servers the operator chooses to install.
- Vulnerabilities arising from agent prompts that produce insecure code (the harness is a prompt library, not a code-quality guarantee). Report code-review failures as bugs, not security issues.

---

## Hardening checklist for operators

When you install this harness on a new machine, verify:

- [ ] `~/.claude/settings.json` `permissions.deny` contains the destructive bash patterns (`rm -rf /`, `git push --force*`, `DROP TABLE*`, etc.). The shipped example does.
- [ ] `Write(**/.env)` and `Edit(**/.env)` are in `permissions.deny`.
- [ ] `config/hooks/block-secrets.sh` is registered in `hooks.PreToolUse` for `Write|Edit|MultiEdit`.
- [ ] You have NOT added `chmod 777 *` or `curl * | bash` to `permissions.allow` (CI rejects these on the example).
- [ ] You reviewed any third-party MCP servers you installed. The harness does not install MCPs by default.
- [ ] Your shell history does not contain operator-pasted secrets (`history -c` after pasting).

---

## Known limitations

| Limitation                                               | Why                                                   | Workaround                                                                                                                                                                                                               |
| -------------------------------------------------------- | ----------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `block-secrets.sh` regex is best-effort                  | Regex cannot detect every secret format ever invented | Run `gitleaks` or `trufflehog` in your repo's pre-commit. The hook is layered defense, not the only one.                                                                                                                 |
| Hooks run with the operator's full shell privileges      | Claude Code design, not a harness choice              | Run the agent in a low-privilege user / container if your threat model demands it.                                                                                                                                       |
| `~/.claude/agent-memory/<agent>/MEMORY.md` is plain text | Designed for grep-ability                             | Do not store credentials there. The block-secrets hook does not scan memory writes (it scans the Write/Edit tool calls; memory writes happen via Write). It actually does scan, but rotation/redaction is not automated. |
| No code-signing of hooks                                 | Out of scope for a single-operator harness            | Verify checksums of release artifacts manually if you care.                                                                                                                                                              |

---

## Disclosure timeline targets

| Severity | Acknowledge | Fix or mitigate | Public disclosure     |
| -------- | ----------- | --------------- | --------------------- |
| Critical | 24h         | 7d              | 14d after fix shipped |
| High     | 72h         | 14d             | 30d after fix shipped |
| Medium   | 7d          | 30d             | 60d after fix shipped |
| Low      | 30d         | best effort     | with next release     |

Coordinated disclosure is preferred. Credit (or anonymous) is given in the CHANGELOG.
