#!/usr/bin/env bash
# PreToolUse: Write|Edit|MultiEdit
# Blocks writes to secret files AND blocks content matching known secret patterns.
# Exit 2 = block. Exit 0 = allow.

set -u

INPUT="${CLAUDE_TOOL_INPUT:-}"
[ -z "$INPUT" ] && exit 0

FILE=$(echo "$INPUT" | jq -r '.file_path // .new_path // ""' 2>/dev/null)
CONTENT=$(echo "$INPUT" | jq -r '.content // .new_string // ""' 2>/dev/null)

# 1. Block by filename
BASENAME=$(basename "$FILE" 2>/dev/null)
if echo "$BASENAME" | grep -qE '^\.env($|\.)|\.(pem|key|p12|pfx|crt|cer)$|^credentials.*\.json$|^service-account.*\.json$|^firebase-adminsdk.*\.json$|^id_(rsa|ed25519|ecdsa)|^\.npmrc$|^\.pypirc$'; then
  echo "BLOCKED: refusing to write secret file: $FILE" >&2
  exit 2
fi

# 2. Block by content patterns (Anthropic, OpenAI, Stripe, AWS, GCP, private keys)
if [ -n "$CONTENT" ]; then
  if echo "$CONTENT" | grep -qE 'sk-ant-[a-zA-Z0-9_-]{20,}|sk-proj-[a-zA-Z0-9_-]{20,}|sk_live_[a-zA-Z0-9]{20,}|pk_live_[a-zA-Z0-9]{20,}|AKIA[A-Z0-9]{16}|ASIA[A-Z0-9]{16}|AIza[a-zA-Z0-9_-]{35}|-----BEGIN (RSA |EC |DSA |OPENSSH |PGP )?PRIVATE KEY-----|ghp_[a-zA-Z0-9]{36}|github_pat_[a-zA-Z0-9_]{82}'; then
    echo "BLOCKED: content contains a known secret pattern (Anthropic/OpenAI/Stripe/AWS/GCP/SSH/GitHub key)" >&2
    exit 2
  fi
fi

exit 0
