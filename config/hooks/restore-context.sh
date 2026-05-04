#!/usr/bin/env bash
# restore-context.sh — anti-compaction-loss recovery (v4.2).
#
# Hook event: SessionStart with source ∈ {compact, resume}.
# On startup the regular inject-context.sh runs; this hook is the supplement
# that fires only when Claude Code resumes a compacted or paused session.
#
# What it injects (all reads, no writes):
#   1. Full hot-context.md (vs inject-context's first 40 lines)
#   2. ADR index (filenames + first H1)
#   3. Patterns index (filenames + first H1)
#   4. Lessons index (filenames + first H1, if memory/lessons/ exists)
#   5. Last 8 commits (vs inject-context's 5)
#
# Performance budget: < 400ms p99. No network. jq optional.
# Idempotent and deterministic.

set -u

PROJ="${CLAUDE_PROJECT_DIR:-$(pwd)}"

# ── Detect SessionStart source from stdin JSON ───────────────────────────────
# Claude Code passes a JSON payload on stdin for SessionStart hooks with a
# `source` field. Values: "startup", "resume", "compact".
SOURCE=""
if [ ! -t 0 ]; then
  STDIN=$(cat 2>/dev/null || echo "")
  if [ -n "$STDIN" ] && command -v jq >/dev/null 2>&1; then
    SOURCE=$(echo "$STDIN" | jq -r '.source // empty' 2>/dev/null)
  fi
fi

# Manual override for tests / unsupported runtimes.
SOURCE="${CLAUDE_SESSION_SOURCE:-$SOURCE}"

# Fire only on compact or resume. On startup, inject-context.sh has it covered.
case "$SOURCE" in
  compact|resume) ;;
  *) exit 0 ;;
esac

# ── Header banner ────────────────────────────────────────────────────────────
echo ""
echo "### [restore-context] $SOURCE detected — re-injecting persistent memory"
echo ""

# ── 1. Full hot-context (not truncated) ──────────────────────────────────────
HOT="$PROJ/memory/hot-context.md"
if [ -f "$HOT" ]; then
  echo "#### hot-context.md"
  cat "$HOT"
  echo ""
fi

# ── 2. ADR index ─────────────────────────────────────────────────────────────
ADR_DIR="$PROJ/memory/decisions"
if [ -d "$ADR_DIR" ]; then
  echo "#### ADRs (memory/decisions/)"
  for f in "$ADR_DIR"/[0-9]*.md; do
    [ -f "$f" ] || continue
    BASENAME=$(basename "$f")
    TITLE=$(grep -m1 '^# ' "$f" 2>/dev/null | sed 's/^# //')
    echo "- \`$BASENAME\` — $TITLE"
  done
  echo ""
fi

# ── 3. Patterns index ────────────────────────────────────────────────────────
PAT_DIR="$PROJ/memory/patterns"
if [ -d "$PAT_DIR" ]; then
  PAT_FILES=$(ls "$PAT_DIR"/*.md 2>/dev/null | grep -v README || true)
  if [ -n "$PAT_FILES" ]; then
    echo "#### Patterns (memory/patterns/)"
    for f in $PAT_FILES; do
      BASENAME=$(basename "$f")
      TITLE=$(grep -m1 '^# ' "$f" 2>/dev/null | sed 's/^# //')
      echo "- \`$BASENAME\` — $TITLE"
    done
    echo ""
  fi
fi

# ── 4. Lessons index (v4.2 lessons-loop) ─────────────────────────────────────
LESSON_DIR="$PROJ/memory/lessons"
if [ -d "$LESSON_DIR" ]; then
  LESSON_FILES=$(ls "$LESSON_DIR"/*.md 2>/dev/null | grep -v README || true)
  if [ -n "$LESSON_FILES" ]; then
    echo "#### Lessons (memory/lessons/) — last 5"
    # shellcheck disable=SC2012
    ls -t "$LESSON_DIR"/*.md 2>/dev/null | grep -v README | head -5 | while read -r f; do
      BASENAME=$(basename "$f")
      TITLE=$(grep -m1 '^# ' "$f" 2>/dev/null | sed 's/^# //')
      echo "- \`$BASENAME\` — $TITLE"
    done
    echo ""
  fi
fi

# ── 5. Recent commits (last 8) ───────────────────────────────────────────────
if timeout 5 git -C "$PROJ" rev-parse --git-dir >/dev/null 2>&1; then
  RECENT=$(timeout 3 git -C "$PROJ" log -8 --pretty=format:'%h %s' 2>/dev/null)
  if [ -n "$RECENT" ]; then
    echo "#### Recent commits (last 8)"
    echo "$RECENT" | sed 's/^/- /'
    echo ""
  fi
fi

# ── Footer ───────────────────────────────────────────────────────────────────
echo "_Tip: continue from where you left off. ADRs / patterns / lessons are the source of truth._"
echo ""

exit 0
