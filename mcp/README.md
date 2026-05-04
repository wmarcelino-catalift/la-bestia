# MCP integration templates

> The harness ships **zero** MCP servers wired by default. Operators choose what to connect based on their stack.

---

## Why no defaults

A hardcoded MCP set:

1. Leaks operator context (org slugs, project ids) into the public repo.
2. Creates supply-chain risk for users who don't need those integrations.
3. Locks the harness into specific vendors when alternatives may suit better.

So we ship the **patterns** for the most common integrations and let you opt in.

See [Anthropic's MCP docs](https://modelcontextprotocol.io/) for protocol details and the [official server registry](https://github.com/modelcontextprotocol/servers) for prebuilt servers.

---

## Adding an MCP server (one command)

```bash
# Pattern — adjust the server name and args.
claude mcp add <name> --scope user -- npx -y <package> [server-args...]

# Verify
claude mcp list
```

`--scope user` registers it in your personal `~/.claude/`. Use `--scope project` for repo-local.

---

## Templates

### GitHub (read PRs, issues, search code)

```bash
claude mcp add github --scope user --env GITHUB_PERSONAL_ACCESS_TOKEN="$GITHUB_PAT" -- \
  npx -y @modelcontextprotocol/server-github
```

Token: create at <https://github.com/settings/tokens>. Scopes: `repo` (private repos), `read:org` if you need org context.

### Postgres (introspect schema, run read-only queries)

```bash
claude mcp add postgres --scope user -- \
  npx -y @modelcontextprotocol/server-postgres "postgresql://user:pass@host:5432/db?sslmode=require"
```

Use a **read-only** role. Never paste production credentials in commands; use `~/.pgpass` or env vars.

### Linear (issues, projects)

```bash
claude mcp add linear --scope user --env LINEAR_API_KEY="$LINEAR_API_KEY" -- \
  npx -y @modelcontextprotocol/server-linear
```

Token: <https://linear.app/settings/api>. Personal API key, not a workspace key.

### Sentry (incidents, error grouping)

```bash
claude mcp add sentry --scope user --env SENTRY_AUTH_TOKEN="$SENTRY_AUTH_TOKEN" -- \
  npx -y @modelcontextprotocol/server-sentry
```

### Slack (messages, channels — limited write)

```bash
claude mcp add slack --scope user --env SLACK_BOT_TOKEN="$SLACK_BOT_TOKEN" -- \
  npx -y @modelcontextprotocol/server-slack
```

Bot scopes: `channels:read`, `chat:write`, `users:read`. Avoid `chat:write.public` unless you really want it.

### Filesystem (sandboxed local fs)

```bash
claude mcp add fs --scope user -- \
  npx -y @modelcontextprotocol/server-filesystem "$HOME/work/projects"
```

**Whitelist a single directory.** Never `$HOME` or `/`.

---

## Operator hardening checklist

- [ ] Each MCP server uses a **least-privilege** token (read-only when possible).
- [ ] Tokens live in your shell env or a secret manager, not in the `claude mcp add` command verbatim. Use `--env VAR="$VAR"` form.
- [ ] You ran `claude mcp list` and recognize every server.
- [ ] You removed any MCP added "to test" that you don't actively use.
- [ ] For Postgres: confirmed the user is read-only (`SELECT current_user`).
- [ ] For GitHub: token scope is the minimum required.

---

## Removing an MCP server

```bash
claude mcp remove <name>
claude mcp list   # verify
```

---

## Troubleshooting

| Symptom                           | Likely cause                                                                      |
| --------------------------------- | --------------------------------------------------------------------------------- |
| "MCP server not found"            | Package name wrong or `npx` cache stale (`npm cache clean --force`).              |
| Authentication errors             | Token scope insufficient or expired.                                              |
| Server hangs                      | Some MCP servers spawn long-running processes. Check `claude mcp list` for state. |
| Duplicate entries after re-adding | `claude mcp remove <name>` first, then re-add.                                    |
