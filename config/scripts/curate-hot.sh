#!/usr/bin/env bash
# Rotate HOT.md: archive entries older than 7 days to vault/permanent/archive.md
# Safe to run multiple times (idempotent).

VAULT="$HOME/Obsidian/claude-brain"
HOT="$VAULT/HOT.md"
ARCHIVE="$VAULT/permanent/archive-hot.md"

[ ! -f "$HOT" ] && exit 0

mkdir -p "$VAULT/permanent"

TODAY=$(date +%Y-%m-%d)
CUTOFF=$(date -v-7d +%Y-%m-%d 2>/dev/null || date -d '7 days ago' +%Y-%m-%d 2>/dev/null)

# Extract lines with dates older than cutoff and move them to archive
# Format expected: "- **YYYY-MM-DD**: ..."
ARCHIVED=0
TEMP=$(mktemp)

while IFS= read -r line; do
  if echo "$line" | grep -qE '^\- \*\*([0-9]{4}-[0-9]{2}-[0-9]{2})\*\*:'; then
    LINE_DATE=$(echo "$line" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -1)
    if [[ "$LINE_DATE" < "$CUTOFF" ]]; then
      echo "$line" >> "$ARCHIVE"
      ARCHIVED=$((ARCHIVED + 1))
      continue
    fi
  fi
  echo "$line" >> "$TEMP"
done < "$HOT"

if [ "$ARCHIVED" -gt 0 ]; then
  mv "$TEMP" "$HOT"
  echo "[curate-hot] Archived $ARCHIVED old entries to $ARCHIVE"
else
  rm "$TEMP"
  echo "[curate-hot] Nothing to archive (all entries within 7 days)"
fi
