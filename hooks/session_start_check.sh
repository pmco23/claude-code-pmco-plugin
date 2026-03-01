#!/usr/bin/env bash
# session_start_check.sh
# SessionStart hook: warns about missing tools this plugin depends on.
# Missing tools degrade (but do not break) the pipeline — hooks fail open.

MISSING=()

command -v jq      >/dev/null 2>&1 || MISSING+=("jq      — JSON parsing in hooks falls back to python3")
command -v python3 >/dev/null 2>&1 || MISSING+=("python3 — JSON parsing fallback in hooks")
command -v repomix >/dev/null 2>&1 || MISSING+=("repomix — required for /pack and /qa codebase snapshots")
command -v codex   >/dev/null 2>&1 || MISSING+=("codex   — required for Codex MCP server")

if [ ${#MISSING[@]} -gt 0 ]; then
  echo "⚠ claude-agents-custom: missing tools detected:" >&2
  for item in "${MISSING[@]}"; do
    echo "    • $item" >&2
  done
  echo "  Install missing tools; see README for setup instructions." >&2
fi

exit 0
