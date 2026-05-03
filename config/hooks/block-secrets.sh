#!/usr/bin/env bash
# PreToolUse: Write|Edit|MultiEdit
# Blocks writes to secret files AND content matching known secret patterns.
# Exit 2 = block. Exit 0 = allow.

set -u

INPUT="${CLAUDE_TOOL_INPUT:-}"
[ -z "$INPUT" ] && exit 0

if command -v jq >/dev/null 2>&1; then
  FILE=$(echo "$INPUT" | jq -r '.file_path // .new_path // ""' 2>/dev/null)
  # MultiEdit fix: scan content + all edits[].new_string
  CONTENT=$(echo "$INPUT" | jq -r '(.content // .new_string // "") + " " + ([.edits[]?.new_string // ""] | join(" "))' 2>/dev/null)
else
  FILE=$(echo "$INPUT" | grep -oE '"file_path"\s*:\s*"[^"]*"' | head -1 | sed -E 's/.*"file_path"\s*:\s*"([^"]*)".*/\1/')
  CONTENT="$INPUT"
fi

# 1. Block by filename
BASENAME=$(basename "$FILE" 2>/dev/null)
if echo "$BASENAME" | grep -qE '^\.env($|\.)|\.(pem|key|p12|pfx|crt|cer)$|^credentials.*\.json$|^service-account.*\.json$|^firebase-adminsdk.*\.json$|^gcp-.*\.json$|^.*-(key|secret|credentials)\.json$|^id_(rsa|ed25519|ecdsa)|^\.npmrc$|^\.pypirc$'; then
  echo "BLOCKED: refusing to write secret file: $FILE" >&2
  exit 2
fi

# 2. Block by content patterns
if [ -n "$CONTENT" ]; then
  if echo "$CONTENT" | grep -qE 'sk-ant-[a-zA-Z0-9_-]{20,}|sk-proj-[a-zA-Z0-9_-]{20,}|sk_live_[a-zA-Z0-9]{20,}|pk_live_[a-zA-Z0-9]{20,}|AKIA[A-Z0-9]{16}|ASIA[A-Z0-9]{16}|AIza[a-zA-Z0-9_-]{35}|-----BEGIN (RSA |EC |DSA |OPENSSH |PGP )?PRIVATE KEY-----|ghp_[a-zA-Z0-9]{36}|github_pat_[a-zA-Z0-9_]{82}'; then
    echo "BLOCKED: content contains a known secret pattern" >&2
    exit 2
  fi
fi

exit 0
