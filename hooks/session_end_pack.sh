#!/usr/bin/env bash
# session_end_pack.sh
# SessionEnd hook: packs the codebase into three targeted Repomix snapshots
# (code, docs, full) so the next session's /qa has fresh snapshots with a
# refreshed packedAt timestamp.
#
# Skips silently if:
#   - repomix is not installed
#   - no .pipeline/ directory exists (no active pipeline project)
#   - CLAUDE.md contains "session-end-pack: disabled"

command -v repomix >/dev/null 2>&1 || exit 0

# Check for opt-out in CLAUDE.md (walk up to find it)
check_opt_out() {
  local dir="$PWD"
  while [ "$dir" != "/" ]; do
    if [ -f "$dir/CLAUDE.md" ]; then
      grep -qiE '^session-end-pack:\s*disabled' "$dir/CLAUDE.md" 2>/dev/null && return 0
      return 1
    fi
    dir=$(dirname "$dir")
  done
  return 1
}
check_opt_out && exit 0

# Walk up from cwd to find .pipeline/ directory (consistent with pipeline_gate.sh)
find_project_root() {
  local dir="$PWD"
  while [ "$dir" != "/" ]; do
    if [ -d "$dir/.pipeline" ]; then
      echo "$dir"
      return 0
    fi
    dir=$(dirname "$dir")
  done
  return 1
}

PROJECT_ROOT=$(find_project_root) || exit 0
PIPELINE_DIR="$PROJECT_ROOT/.pipeline"

# Generate three snapshot variants
# Code snapshot — source code only
repomix --compress --remove-empty-lines --no-file-summary --include-diffs \
  --ignore "**/*.md,**/*.mdx,**/*.rst,**/*.txt,docs/**,doc/**,*.config.*,*.json,*.yaml,*.yml,*.toml,*.lock,*.svg,*.png,*.jpg,*.gif,*.ico" \
  --output "$PIPELINE_DIR/repomix-code.xml" "$PROJECT_ROOT" 2>/dev/null

# Docs snapshot — documentation files only
repomix --remove-empty-lines --no-file-summary --no-directory-structure \
  --include "**/*.md,**/*.mdx,**/*.rst,**/*.txt,docs/**,doc/**,README*,CHANGELOG*,CONTRIBUTING*,LICENSE*" \
  --output "$PIPELINE_DIR/repomix-docs.xml" "$PROJECT_ROOT" 2>/dev/null

# Full snapshot — entire codebase
repomix --compress --remove-empty-lines \
  --output "$PIPELINE_DIR/repomix-full.xml" "$PROJECT_ROOT" 2>/dev/null

# At least one snapshot must succeed
if [ ! -f "$PIPELINE_DIR/repomix-code.xml" ] && [ ! -f "$PIPELINE_DIR/repomix-docs.xml" ] && [ ! -f "$PIPELINE_DIR/repomix-full.xml" ]; then
  exit 0
fi

NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

if command -v python3 >/dev/null 2>&1; then
  python3 - "$PIPELINE_DIR" "$PROJECT_ROOT" <<'PYEOF'
import json, os, sys
from datetime import datetime, timezone

pipeline_dir = sys.argv[1]
project_root = sys.argv[2]
pack_file = os.path.join(pipeline_dir, "repomix-pack.json")

now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

snapshots = {}
for variant in ("code", "docs", "full"):
    fpath = os.path.join(pipeline_dir, f"repomix-{variant}.xml")
    if os.path.isfile(fpath):
        entry = {"filePath": fpath}
        try:
            entry["fileSize"] = os.path.getsize(fpath)
        except Exception:
            pass
        snapshots[variant] = entry

data = {
    "packedAt": now,
    "source": project_root,
    "snapshots": snapshots
}

with open(pack_file, "w") as f:
    json.dump(data, f, indent=2)
PYEOF

elif command -v jq >/dev/null 2>&1; then
  # Build snapshots JSON with jq
  SNAPSHOTS="{}"
  for variant in code docs full; do
    fpath="$PIPELINE_DIR/repomix-${variant}.xml"
    if [ -f "$fpath" ]; then
      fsize=$(wc -c < "$fpath" 2>/dev/null | tr -d ' ')
      SNAPSHOTS=$(echo "$SNAPSHOTS" | jq --arg v "$variant" --arg fp "$fpath" --argjson fs "${fsize:-0}" \
        '. + {($v): {"filePath": $fp, "fileSize": $fs}}')
    fi
  done
  jq -n --arg t "$NOW" --arg src "$PROJECT_ROOT" --argjson snaps "$SNAPSHOTS" \
    '{"packedAt": $t, "source": $src, "snapshots": $snaps}' \
    > "$PIPELINE_DIR/repomix-pack.json" 2>/dev/null || true
fi

exit 0
