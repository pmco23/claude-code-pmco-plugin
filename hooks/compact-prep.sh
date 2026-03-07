#!/usr/bin/env bash
# compact-prep.sh
# PreCompact hook: injects current pipeline state as additional context so it
# is preserved in the compact summary.

set -euo pipefail

HOOKS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HOOKS_DIR/lib/find-project.sh"
source "$HOOKS_DIR/lib/json-helpers.sh"

PIPELINE_DIR=$(find_pipeline_dir_strict) || exit 0

# Collect present artifacts
artifacts=()
for f in brief.md design.md design.approved plan.md build.complete; do
  [ -f "$PIPELINE_DIR/$f" ] && artifacts+=("$f")
done

if [ ${#artifacts[@]} -eq 0 ]; then
  exit 0
fi

# Current stage
stage=""
if [ -f "$PIPELINE_DIR/build.complete" ]; then
  stage="post-build"
elif [ -f "$PIPELINE_DIR/plan.md" ]; then
  stage="build-ready"
elif [ -f "$PIPELINE_DIR/design.approved" ]; then
  stage="plan-ready"
elif [ -f "$PIPELINE_DIR/design.md" ]; then
  stage="review"
elif [ -f "$PIPELINE_DIR/brief.md" ]; then
  stage="design-ready"
fi

# Repomix snapshots
snap_info=""
for variant in code docs full; do
  fpath="$PIPELINE_DIR/repomix-${variant}.xml"
  if [ -f "$fpath" ]; then
    fsize=$(wc -c < "$fpath" 2>/dev/null | tr -d ' ')
    fsize_kb=$(( (fsize + 512) / 1024 ))
    snap_info="${snap_info:+$snap_info, }${variant} (${fsize_kb}KB)"
  fi
done

message=$(printf '=== Pipeline State ===\nArtifacts present: %s\nStage: %s' "${artifacts[*]}" "$stage")
if [ -n "$snap_info" ]; then
  message=$(printf '%s\nRepomix snapshots: %s (verify age before reuse)' "$message" "$snap_info")
fi

_emit_additional_context "PreCompact" "$message"

exit 0
