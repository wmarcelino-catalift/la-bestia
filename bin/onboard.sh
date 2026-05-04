#!/usr/bin/env bash
# bin/onboard.sh — bootstrap la-bestia for the current project (idempotent).
# Detects stack, scaffolds memory/, .claudeignore, project CLAUDE.md.
# NEVER overwrites existing files.

set -euo pipefail

PROJ="${CLAUDE_PROJECT_DIR:-$(pwd)}"
LA_BESTIA_HOME="${LA_BESTIA_HOME:-}"

# Find la-bestia repo (for templates) — try common locations.
if [ -z "$LA_BESTIA_HOME" ]; then
  for CANDIDATE in \
    "$HOME/.claude/_la-bestia-source" \
    "$HOME/code/la-bestia" \
    "$HOME/projects/la-bestia" \
    "$HOME/dev/la-bestia"; do
    if [ -f "$CANDIDATE/memory/templates/adr.md" ]; then
      LA_BESTIA_HOME="$CANDIDATE"
      break
    fi
  done
fi

# Header
echo "=== /onboard-project — la-bestia bootstrap ==="
echo "  project root: $PROJ"
[ -n "$LA_BESTIA_HOME" ] && echo "  templates:    $LA_BESTIA_HOME"
echo ""

# ── Detect stack ─────────────────────────────────────────────────────────────
STACK_PARTS=()
[ -f "$PROJ/package.json" ] && STACK_PARTS+=("Node.js")
[ -f "$PROJ/tsconfig.json" ] && STACK_PARTS+=("TypeScript")
{ [ -f "$PROJ/pyproject.toml" ] || [ -f "$PROJ/requirements.txt" ] || [ -f "$PROJ/setup.py" ]; } && STACK_PARTS+=("Python")
[ -f "$PROJ/go.mod" ] && STACK_PARTS+=("Go")
[ -f "$PROJ/Cargo.toml" ] && STACK_PARTS+=("Rust")
[ -f "$PROJ/Gemfile" ] && STACK_PARTS+=("Ruby")
[ -f "$PROJ/composer.json" ] && STACK_PARTS+=("PHP")
{ [ -f "$PROJ/pom.xml" ] || [ -f "$PROJ/build.gradle" ] || [ -f "$PROJ/build.gradle.kts" ]; } && STACK_PARTS+=("JVM")
[ -f "$PROJ/app.json" ] && STACK_PARTS+=("Expo")
[ -f "$PROJ/Dockerfile" ] && STACK_PARTS+=("Docker")
[ -f "$PROJ/main.tf" ] && STACK_PARTS+=("Terraform")
[ -f "$PROJ/firebase.json" ] && STACK_PARTS+=("Firebase")
[ -f "$PROJ/supabase/config.toml" ] && STACK_PARTS+=("Supabase")
[ -f "$PROJ/vercel.json" ] && STACK_PARTS+=("Vercel")

if [ ${#STACK_PARTS[@]} -gt 0 ]; then
  STACK_STR=$(IFS=' + '; echo "${STACK_PARTS[*]}")
else
  STACK_STR="(none detected — fill manually)"
fi

# Project name from package.json or directory name
PROJ_NAME="$(basename "$PROJ")"
if [ -f "$PROJ/package.json" ] && command -v jq >/dev/null 2>&1; then
  PKG_NAME=$(jq -r '.name // empty' "$PROJ/package.json" 2>/dev/null)
  [ -n "$PKG_NAME" ] && PROJ_NAME="$PKG_NAME"
fi

# ── Git state ────────────────────────────────────────────────────────────────
BRANCH="(no git)"
LAST_COMMIT="(no git)"
if git -C "$PROJ" rev-parse --git-dir >/dev/null 2>&1; then
  BRANCH=$(git -C "$PROJ" branch --show-current 2>/dev/null || echo "detached")
  LAST_COMMIT=$(git -C "$PROJ" log -1 --pretty=format:'%h %s' 2>/dev/null || echo "(empty repo)")
fi

# ── Test framework detection ─────────────────────────────────────────────────
TEST_FRAMEWORK=""
[ -f "$PROJ/vitest.config.ts" ] || [ -f "$PROJ/vitest.config.js" ] && TEST_FRAMEWORK="Vitest"
[ -f "$PROJ/jest.config.js" ] || [ -f "$PROJ/jest.config.ts" ] && TEST_FRAMEWORK="${TEST_FRAMEWORK:+$TEST_FRAMEWORK + }Jest"
[ -d "$PROJ/__tests__" ] && [ -z "$TEST_FRAMEWORK" ] && TEST_FRAMEWORK="Jest (assumed)"
[ -f "$PROJ/pytest.ini" ] || [ -f "$PROJ/pyproject.toml" ] && grep -q "\[tool.pytest" "$PROJ/pyproject.toml" 2>/dev/null && TEST_FRAMEWORK="${TEST_FRAMEWORK:+$TEST_FRAMEWORK + }pytest"
[ -d "$PROJ/.github/workflows" ] && CI_PRESENT="GitHub Actions" || CI_PRESENT="(none)"

# ── What exists already ──────────────────────────────────────────────────────
HAS_HOT_CONTEXT="no"
HAS_DECISIONS="no"
HAS_PATTERNS="no"
HAS_CLAUDEIGNORE="no"
HAS_PROJECT_CLAUDE_MD="no"
[ -f "$PROJ/memory/hot-context.md" ] && HAS_HOT_CONTEXT="yes"
[ -d "$PROJ/memory/decisions" ] && HAS_DECISIONS="yes"
[ -d "$PROJ/memory/patterns" ] && HAS_PATTERNS="yes"
[ -f "$PROJ/.claudeignore" ] && HAS_CLAUDEIGNORE="yes"
[ -f "$PROJ/CLAUDE.md" ] && HAS_PROJECT_CLAUDE_MD="yes"

# ── Print detection report ───────────────────────────────────────────────────
echo "## Detection report"
echo ""
echo "  Project name:     $PROJ_NAME"
echo "  Stack:            $STACK_STR"
echo "  Branch:           $BRANCH"
echo "  Last commit:      $LAST_COMMIT"
[ -n "$TEST_FRAMEWORK" ] && echo "  Tests:            $TEST_FRAMEWORK"
echo "  CI:               $CI_PRESENT"
echo ""
echo "## Existing la-bestia files"
echo "  memory/hot-context.md:     $HAS_HOT_CONTEXT"
echo "  memory/decisions/:         $HAS_DECISIONS"
echo "  memory/patterns/:          $HAS_PATTERNS"
echo "  .claudeignore:             $HAS_CLAUDEIGNORE"
echo "  CLAUDE.md (project-level): $HAS_PROJECT_CLAUDE_MD"
echo ""

# ── Create what's missing (additive only) ────────────────────────────────────
CHANGES=0

# memory/ subdirectories
mkdir -p "$PROJ/memory/decisions" "$PROJ/memory/patterns" "$PROJ/memory/templates"

# memory/hot-context.md (only if missing)
if [ "$HAS_HOT_CONTEXT" = "no" ]; then
  cat > "$PROJ/memory/hot-context.md" <<EOF
# hot-context.md — $PROJ_NAME

> Read FIRST every session. Keep ≤ 200 tokens. Update via \`/wrap-up\`.

## Project
- **App:** $PROJ_NAME
- **Stack:** $STACK_STR
- **Stage:** [pre-launch | production | maintenance]   ← OPERATOR FILLS

## Current focus
- [what you're working on this week]   ← OPERATOR FILLS

## Recent decisions
- $(date +%Y-%m-%d): bootstrapped la-bestia via /onboard-project

## Pending
- [ ] [add a real pending item here]   ← OPERATOR FILLS

## Gotchas
- [non-obvious thing the next session must know]   ← OPERATOR FILLS
EOF
  echo "  ✓ created memory/hot-context.md (draft — fill OPERATOR FILLS)"
  CHANGES=$((CHANGES + 1))
fi

# memory/templates/adr.md and pattern.md (copy from la-bestia source if available)
if [ -n "$LA_BESTIA_HOME" ]; then
  for tpl in adr pattern; do
    SRC="$LA_BESTIA_HOME/memory/templates/$tpl.md"
    DST="$PROJ/memory/templates/$tpl.md"
    if [ -f "$SRC" ] && [ ! -f "$DST" ]; then
      cp "$SRC" "$DST"
      echo "  ✓ created memory/templates/$tpl.md"
      CHANGES=$((CHANGES + 1))
    fi
  done
fi

# .claudeignore (only if missing)
if [ "$HAS_CLAUDEIGNORE" = "no" ]; then
  cat > "$PROJ/.claudeignore" <<'EOF'
# .claudeignore — paths Claude Code skips when reading
node_modules/
.git/
dist/
build/
.next/
.nuxt/
.expo/
.svelte-kit/
out/
coverage/
.coverage/
*.log
*.lock
package-lock.json
yarn.lock
pnpm-lock.yaml
poetry.lock
Cargo.lock
target/
__pycache__/
*.pyc
.venv/
venv/
.DS_Store
.env*
*.pem
*.key
*.p12
*.pfx
.idea/
.vscode/settings.json
EOF
  echo "  ✓ created .claudeignore"
  CHANGES=$((CHANGES + 1))
fi

# CLAUDE.md project-level stub (only if missing)
if [ "$HAS_PROJECT_CLAUDE_MD" = "no" ]; then
  cat > "$PROJ/CLAUDE.md" <<EOF
# CLAUDE.md — $PROJ_NAME (project-level overrides)

> This file overrides ~/.claude/CLAUDE.md (the global la-bestia constitution).
> Use it for **project-specific** rules: stack idioms, must-not-do, deployment quirks.

## Stack
$STACK_STR

## Project rules
- (add project-specific rules here — e.g., "never call DB directly from route handlers")

## Deployment
- (add deploy-specific notes — e.g., "rollback via Vercel dashboard, not CLI")

## Domain glossary
- (add domain terms operators must know — e.g., "Tenant = a paying B2B customer")

## See also
- \`memory/hot-context.md\` for current state
- \`memory/decisions/\` for ADRs
- \`memory/patterns/\` for reusable solutions for this repo
EOF
  echo "  ✓ created CLAUDE.md (project-level stub)"
  CHANGES=$((CHANGES + 1))
fi

# memory/decisions/README.md (only if missing)
if [ ! -f "$PROJ/memory/decisions/README.md" ]; then
  cat > "$PROJ/memory/decisions/README.md" <<'EOF'
# memory/decisions — Architecture Decision Records

> One-way-door decisions for this project. Format: `<NNNN>-<kebab-slug>.md`.
> Template: `memory/templates/adr.md`.

## Index

| # | Title | Status | Date |
|---|-------|--------|------|
| — | (no ADRs yet) | — | — |
EOF
  echo "  ✓ created memory/decisions/README.md"
  CHANGES=$((CHANGES + 1))
fi

# memory/patterns/README.md (only if missing)
if [ ! -f "$PROJ/memory/patterns/README.md" ]; then
  cat > "$PROJ/memory/patterns/README.md" <<'EOF'
# memory/patterns — Reusable recipes

> Solutions discovered in this project that are worth recording.
> Format: `<slug>.md`. Template: `memory/templates/pattern.md`.

## When to add a pattern
- The same shape of problem appeared 3+ times in this repo.
- The fix is non-obvious and slow to re-derive.
- A future session can save material time by reading instead of re-discovering.

## Index
| Slug | One-line summary |
|------|------------------|
| (none yet) | — |
EOF
  echo "  ✓ created memory/patterns/README.md"
  CHANGES=$((CHANGES + 1))
fi

echo ""

if [ "$CHANGES" -eq 0 ]; then
  echo "✅ already onboarded — no changes."
else
  echo "✅ onboarded — $CHANGES file(s) created."
fi

echo ""
echo "## Next steps"
echo "  [ ] Edit memory/hot-context.md — fill the OPERATOR FILLS slots"
echo "  [ ] Edit CLAUDE.md (project-level) — add project rules + glossary"
echo "  [ ] Run /wrap-up at end of next session to populate Pending"
echo "  [ ] If you have one-way doors planned, draft ADR-0001 from memory/templates/adr.md"
echo "  [ ] Verify install: bash ~/.claude/scripts/verify.sh"
