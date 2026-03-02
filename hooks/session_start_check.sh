#!/usr/bin/env bash
# session_start_check.sh
# SessionStart hook: warns about missing tools this plugin depends on.
# Missing tools degrade (but do not break) the pipeline — hooks fail open.

MISSING=()

command -v jq      >/dev/null 2>&1 || MISSING+=("jq      — JSON parsing in hooks falls back to python3")
command -v python3 >/dev/null 2>&1 || MISSING+=("python3 — JSON parsing fallback in hooks")
command -v repomix >/dev/null 2>&1 || MISSING+=("repomix — required for /pack and /qa codebase snapshots")
command -v codex   >/dev/null 2>&1 || MISSING+=("codex   — required for Codex MCP server")
EPISODIC_CHECK=$(ls "$HOME/.claude/plugins/cache/superpowers-marketplace/episodic-memory/"*/cli/episodic-memory.js 2>/dev/null | sort -V | tail -1)
[ -n "$EPISODIC_CHECK" ] && [ -f "$EPISODIC_CHECK" ] || MISSING+=("episodic-memory plugin — required for session context injection (install via superpowers marketplace)")

if [ ${#MISSING[@]} -gt 0 ]; then
  echo "⚠ claude-agents-custom: missing tools detected:" >&2
  for item in "${MISSING[@]}"; do
    echo "    • $item" >&2
  done
  echo "  Install missing tools; see README for setup instructions." >&2
fi

# --- Episodic memory: sync last session and inject recent context into MEMORY.md ---

# Resolve the installed version dynamically (version-agnostic)
EPISODIC_BIN=$(ls "$HOME/.claude/plugins/cache/superpowers-marketplace/episodic-memory/"*/cli/episodic-memory.js 2>/dev/null | sort -V | tail -1)

if [ -z "$EPISODIC_BIN" ] || [ ! -f "$EPISODIC_BIN" ]; then
  echo "⚠ claude-agents-custom: episodic-memory not found — skipping session context injection" >&2
else
  # Sync last session into index (silent)
  node "$EPISODIC_BIN" sync >/dev/null 2>&1

  # Search recent activity across all projects (last 7 days)
  AFTER_DATE=$(date -d '7 days ago' +%Y-%m-%d 2>/dev/null || date -v-7d +%Y-%m-%d 2>/dev/null)
  SEARCH_OUTPUT=$(node "$EPISODIC_BIN" search "recent work" --limit 3 --after "$AFTER_DATE" 2>/dev/null \
    | grep -v "^Loading\|^Embedding\|^   Lines\|^$" \
    | sed 's/ - [-0-9]*% match//')

  if [ -n "$SEARCH_OUTPUT" ]; then
    # Compute MEMORY.md path from current working directory
    ENCODED=$(echo "$PWD" | sed 's|^/||; s|/|-|g')
    MEMORY_DIR="$HOME/.claude/projects/-${ENCODED}/memory"
    MEMORY_FILE="$MEMORY_DIR/MEMORY.md"

    mkdir -p "$MEMORY_DIR"

    TODAY=$(date +%Y-%m-%d)
    NEW_BLOCK="<!-- session-context-start -->
## Recent Activity (auto-updated at session start — ${TODAY})

${SEARCH_OUTPUT}
<!-- session-context-end -->"

    if [ -f "$MEMORY_FILE" ] && grep -q "<!-- session-context-start -->" "$MEMORY_FILE"; then
      # Replace existing block between sentinels
      python3 -c "
import sys, re
content = open('$MEMORY_FILE').read()
new_block = '''$NEW_BLOCK'''
result = re.sub(
  r'<!-- session-context-start -->.*?<!-- session-context-end -->',
  new_block,
  content,
  flags=re.DOTALL
)
open('$MEMORY_FILE', 'w').write(result)
"
    elif [ -f "$MEMORY_FILE" ]; then
      # Append to existing file
      printf '\n%s\n' "$NEW_BLOCK" >> "$MEMORY_FILE"
    else
      # Create new file
      printf '%s\n' "$NEW_BLOCK" > "$MEMORY_FILE"
    fi
  fi
fi

exit 0
