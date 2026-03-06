#!/usr/bin/env bash
set -euo pipefail
# session-start-check.sh
# SessionStart hook: warns about missing tools this plugin depends on.
# Missing tools degrade (but do not break) the pipeline — hooks fail open.

MISSING=()

command -v jq      >/dev/null 2>&1 || MISSING+=("jq      — JSON parsing in hooks falls back to python3")
command -v python3 >/dev/null 2>&1 || MISSING+=("python3 — JSON parsing fallback in hooks")
command -v repomix >/dev/null 2>&1 || MISSING+=("repomix — required for /pack and /qa codebase snapshots")

# Keep statusline symlink current — settings.json always points to ~/.claude/statusline.js
# and this symlink ensures it resolves to the plugin's actual location regardless of where
# the plugin is installed. Only create/update the symlink if:
#   - no statusline.js exists yet, OR
#   - the existing file is already a symlink pointing to a claude-developer-toolbox statusline
# This avoids silently overwriting a user's custom statusline or another plugin's statusline.
STATUSLINE_TARGET="${HOME}/.claude/statusline.js"
PLUGIN_STATUSLINE="${CLAUDE_PLUGIN_ROOT}/hooks/statusline.js"
if [ ! -e "$STATUSLINE_TARGET" ]; then
  ln -sf "$PLUGIN_STATUSLINE" "$STATUSLINE_TARGET" 2>/dev/null || true
elif [ -L "$STATUSLINE_TARGET" ]; then
  CURRENT_TARGET=$(readlink "$STATUSLINE_TARGET" 2>/dev/null || true)
  case "$CURRENT_TARGET" in
    *claude-developer-toolbox*)
      ln -sf "$PLUGIN_STATUSLINE" "$STATUSLINE_TARGET" 2>/dev/null || true
      ;;
    *)
      # Another plugin or custom statusline — do not overwrite
      ;;
  esac
fi

if [ ${#MISSING[@]} -gt 0 ]; then
  echo "⚠ claude-developer-toolbox: missing tools detected:" >&2
  for item in "${MISSING[@]}"; do
    echo "    • $item" >&2
  done
  echo "  Install missing tools; see README for setup instructions." >&2
fi

exit 0
