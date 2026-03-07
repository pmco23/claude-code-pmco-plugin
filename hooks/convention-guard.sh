#!/usr/bin/env bash
# convention-guard.sh
# PreToolUse hook on Write|Edit: enforces project conventions.
#
# Rules:
#   1. Block writes to .claude-plugin/ that are not manifests
#   2. Remind about chmod +x and test-gate for hooks/*.sh
#   3. Remind about version sync for plugin.json edits

set -euo pipefail

HOOKS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HOOKS_DIR/lib/json-helpers.sh"

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | _json_stdin_field "tool_input.file_path")

# No file path — allow
[ -z "$FILE_PATH" ] && exit 0

case "$FILE_PATH" in
  */.claude-plugin/plugin.json|*/.claude-plugin/marketplace.json)
    # Rule 3: version sync reminder
    _emit_system_message "Remember: version is tracked in both plugin.json and marketplace.json — bump both."
    exit 0
    ;;
  */.claude-plugin/*)
    # Rule 1: block non-manifest writes
    _emit_pretool_permission "deny" "Only manifests (plugin.json, marketplace.json) belong in .claude-plugin/. Put skills, hooks, and other components in their own directories."
    exit 0
    ;;
  */hooks/*.sh)
    # Rule 2: chmod and test-gate reminder
    _emit_system_message "Remember: hooks must be executable (chmod +x), have #!/usr/bin/env bash shebang, and pass test-gate.sh."
    exit 0
    ;;
esac

exit 0
