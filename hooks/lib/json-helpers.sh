# hooks/lib/json-helpers.sh — sourceable, no shebang
# Shared JSON parsing: prefer jq, fall back to python3.

# _json_stdin_field <dotted.path> — reads JSON from stdin, returns field value
_json_stdin_field() {
  local field="$1"
  if command -v jq >/dev/null 2>&1; then
    jq -r ".${field} // empty" 2>/dev/null || true
  elif command -v python3 >/dev/null 2>&1; then
    python3 -c '
import json, sys
field = sys.argv[1]
try:
    d = json.load(sys.stdin)
    parts = field.split(".")
    val = d
    for p in parts:
        if isinstance(val, dict):
            val = val.get(p, "")
        else:
            val = ""
            break
    print(val if val != "" else "")
except Exception:
    print("")
' "$field" 2>/dev/null || true
  else
    echo ""
  fi
}

# _json_file_field <file> <field> [default] — reads field from JSON file
_json_file_field() {
  local file="$1" field="$2" default="${3:-0}"
  if command -v jq >/dev/null 2>&1; then
    jq -r --arg d "$default" ".${field} // \$d" "$file" 2>/dev/null || echo "$default"
  elif command -v python3 >/dev/null 2>&1; then
    python3 - "$file" "$field" "$default" <<'PYEOF' 2>/dev/null || echo "$default"
import json, sys
file, field, default = sys.argv[1], sys.argv[2], sys.argv[3]
try:
    d = json.load(open(file))
    parts = field.split(".")
    val = d
    for p in parts:
        if isinstance(val, dict):
            val = val.get(p, default)
        else:
            val = default
            break
    print(val)
except Exception:
    print(default)
PYEOF
  else
    echo "$default"
  fi
}

# _json_quote <value> — emits a JSON-quoted string
_json_quote() {
  local value="$1"
  if command -v jq >/dev/null 2>&1; then
    jq -Rn --arg v "$value" '$v'
  elif command -v python3 >/dev/null 2>&1; then
    python3 -c 'import json, sys; print(json.dumps(sys.argv[1]))' "$value"
  else
    local escaped
    escaped=$(printf '%s' "$value" | sed 's/\\/\\\\/g; s/"/\\"/g')
    printf '"%s"' "$escaped"
  fi
}

# _emit_block_decision <reason> — emits a UserPromptSubmit block decision
_emit_block_decision() {
  local reason="$1"
  printf '{"decision":"block","reason":%s}\n' "$(_json_quote "$reason")"
}

# _emit_system_message <message> — emits a hook system message
_emit_system_message() {
  local message="$1"
  printf '{"systemMessage":%s}\n' "$(_json_quote "$message")"
}

# _emit_additional_context <event> <context> — emits context for the given hook event
_emit_additional_context() {
  local event="$1"
  local context="$2"
  printf '{"hookSpecificOutput":{"hookEventName":%s,"additionalContext":%s}}\n' \
    "$(_json_quote "$event")" \
    "$(_json_quote "$context")"
}

# _emit_pretool_permission <decision> <reason> — emits a PreToolUse permission decision
_emit_pretool_permission() {
  local decision="$1"
  local reason="$2"
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":%s,"permissionDecisionReason":%s}}\n' \
    "$(_json_quote "$decision")" \
    "$(_json_quote "$reason")"
}
