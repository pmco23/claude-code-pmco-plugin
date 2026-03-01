#!/usr/bin/env bash
# PostToolUse hook — warns Claude when context window is running low.
# Reads the bridge file written by hooks/statusline.js.

set -euo pipefail

# Portable JSON helpers — prefer jq, fall back to python3
_json_stdin_field() {
  local field="$1"
  if command -v jq >/dev/null 2>&1; then
    jq -r ".${field} // empty" 2>/dev/null || true
  elif command -v python3 >/dev/null 2>&1; then
    python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('${field}',''))" 2>/dev/null || true
  fi
}

_json_file_field() {
  local file="$1" field="$2" default="${3:-0}"
  if command -v jq >/dev/null 2>&1; then
    jq -r ".${field} // ${default}" "$file" 2>/dev/null || echo "$default"
  elif command -v python3 >/dev/null 2>&1; then
    python3 -c "import json; d=json.load(open('${file}')); print(d.get('${field}',${default}))" 2>/dev/null || echo "$default"
  else
    echo "$default"
  fi
}

# Parse session_id from the PostToolUse JSON payload on stdin
INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | _json_stdin_field "session_id")

[[ -z "$SESSION_ID" ]] && exit 0

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
