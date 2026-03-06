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
