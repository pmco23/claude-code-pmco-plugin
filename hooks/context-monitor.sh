#!/usr/bin/env bash
# PostToolUse hook — warns Claude when context window is running low.
# Reads the bridge file written by hooks/statusline.js.

set -euo pipefail

HOOKS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HOOKS_DIR/lib/json-helpers.sh"

# Parse session_id from the PostToolUse JSON payload on stdin
INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | _json_stdin_field "session_id")

[[ -z "$SESSION_ID" ]] && exit 0
# Validate UUID format (hex + dashes) before using in file path
[[ ! "$SESSION_ID" =~ ^[0-9a-f-]+$ ]] && exit 0

BRIDGE_FILE="/tmp/claude-ctx-${SESSION_ID}.json"
[[ ! -f "$BRIDGE_FILE" ]] && exit 0

USED_PCT=$(_json_file_field "$BRIDGE_FILE" "used_pct" "0")

TIMESTAMP=$(_json_file_field "$BRIDGE_FILE" "timestamp" "0")

NOW=$(date +%s)
AGE=$(( NOW - TIMESTAMP ))

# Only warn if bridge file is fresh (updated within last 60 seconds)
(( AGE > 60 )) && exit 0

if (( USED_PCT >= 95 )); then
  echo "💀 Context critical (${USED_PCT}%) — /compact now"
elif (( USED_PCT >= 81 )); then
  echo "⚠ Context at ${USED_PCT}% — /compact recommended"
elif (( USED_PCT >= 63 )); then
  echo "⚠ Context at ${USED_PCT}% — consider /compact soon"
fi

exit 0
