#!/usr/bin/env bash
# SessionStart hook (v3.0) — rich context injection.
# Reads only: stack manifests, git state, project memory, recent log activity.
# No external dependencies (jq optional). No vault.
#
# Performance budget: < 500ms p99.

set -u

PROJ="${CLAUDE_PROJECT_DIR:-$(pwd)}"
CWD=$(pwd)

# ── Header ───────────────────────────────────────────────────────────────────
echo "## Session $(date '+%Y-%m-%d %H:%M') · $(basename "$PROJ")"

# ── Stack auto-detection (cheap manifest checks) ─────────────────────────────
STACK_PARTS=()
[ -f "$PROJ/package.json" ] && STACK_PARTS+=("Node.js")
[ -f "$PROJ/tsconfig.json" ] && STACK_PARTS+=("TypeScript")
[ -f "$PROJ/pyproject.toml" ] || [ -f "$PROJ/requirements.txt" ] || [ -f "$PROJ/setup.py" ] && STACK_PARTS+=("Python")
[ -f "$PROJ/go.mod" ] && STACK_PARTS+=("Go")
[ -f "$PROJ/Cargo.toml" ] && STACK_PARTS+=("Rust")
[ -f "$PROJ/Gemfile" ] && STACK_PARTS+=("Ruby")
[ -f "$PROJ/composer.json" ] && STACK_PARTS+=("PHP")
[ -f "$PROJ/pom.xml" ] || [ -f "$PROJ/build.gradle" ] || [ -f "$PROJ/build.gradle.kts" ] && STACK_PARTS+=("JVM")
[ -f "$PROJ/app.json" ] && STACK_PARTS+=("Expo")
[ -f "$PROJ/Dockerfile" ] && STACK_PARTS+=("Docker")
[ -d "$PROJ/.terraform" ] || [ -f "$PROJ/main.tf" ] && STACK_PARTS+=("Terraform")
[ -f "$PROJ/firebase.json" ] && STACK_PARTS+=("Firebase")
[ -f "$PROJ/supabase/config.toml" ] && STACK_PARTS+=("Supabase")
[ -f "$PROJ/vercel.json" ] && STACK_PARTS+=("Vercel")
[ -f "$PROJ/netlify.toml" ] && STACK_PARTS+=("Netlify")

if [ ${#STACK_PARTS[@]} -gt 0 ]; then
  STACK_STR=$(IFS=' + '; echo "${STACK_PARTS[*]}")
  echo "**stack**: $STACK_STR"
fi

# ── Git state (rich) ─────────────────────────────────────────────────────────
if timeout 5 git rev-parse --git-dir >/dev/null 2>&1; then
  BRANCH=$(timeout 3 git branch --show-current 2>/dev/null || echo "detached")
  UNCOMMITTED=$(timeout 3 git status --short 2>/dev/null | wc -l | tr -d ' ')
  LAST=$(timeout 3 git log -1 --pretty=format:'%h %s' 2>/dev/null)
  AHEAD=$(timeout 3 git rev-list --count "@{upstream}..HEAD" 2>/dev/null || echo "?")
  BEHIND=$(timeout 3 git rev-list --count "HEAD..@{upstream}" 2>/dev/null || echo "?")
  echo "**git**: $BRANCH · $UNCOMMITTED uncommitted · ahead $AHEAD · last: $LAST"

  # Modified files in working tree (top 8)
  MODIFIED=$(timeout 3 git status --short 2>/dev/null | head -8 | awk '{print $2}' | tr '\n' ' ')
  if [ -n "$MODIFIED" ]; then
    echo "**modified**: $MODIFIED"
  fi

  # Recent commits (last 5, one-line)
  RECENT=$(timeout 3 git log -5 --pretty=format:'%h %s' 2>/dev/null)
  if [ -n "$RECENT" ]; then
    echo ""
    echo "### Recent commits"
    echo "$RECENT" | sed 's/^/- /'
  fi
else
  echo "**git**: no git repo"
fi

# ── Cost (ccusage) ───────────────────────────────────────────────────────────
if command -v ccusage >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
  TODAY=$(ccusage daily --json 2>/dev/null | jq -r '.totals.totalCost // empty' 2>/dev/null)
  if [ -n "$TODAY" ]; then
    echo ""
    echo "**\$ today**: \$$TODAY"
  fi
fi

# ── Last session recap (top agents from previous session) ────────────────────
LOG="$PROJ/.claude/logs/agents.jsonl"
if [ -f "$LOG" ] && command -v jq >/dev/null 2>&1; then
  # Top 3 agents from last 24h (excluding current session signal)
  CUTOFF=$(($(date +%s) - 86400))
  TOP_AGENTS=$(tail -500 "$LOG" 2>/dev/null | \
    jq -r "select(.epoch != null and .epoch > $CUTOFF and .event == \"post\" and .agent != null and .agent != \"unknown\" and .agent != \"Bash\") | .agent" 2>/dev/null | \
    sort | uniq -c | sort -rn | head -3 | awk '{print $2 " (" $1 "×)"}' | tr '\n' ' ')
  if [ -n "$TOP_AGENTS" ]; then
    echo "**last 24h agents**: $TOP_AGENTS"
  fi
fi

# ── Project hot-context (the most useful per-session signal) ─────────────────
if [ -f "$PROJ/memory/hot-context.md" ]; then
  echo ""
  echo "### Project hot-context"
  head -40 "$PROJ/memory/hot-context.md"
fi

echo ""
exit 0
