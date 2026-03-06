#!/usr/bin/env bash
# compact-prep.sh
# PreCompact hook: outputs current pipeline state so it is preserved in the compact summary.

HOOKS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HOOKS_DIR/lib/find-project.sh"

PIPELINE_DIR=$(find_pipeline_dir_strict) || exit 0

# Collect present artifacts
artifacts=()
for f in brief.md design.md design.approved plan.md build.complete; do
  [ -f "$PIPELINE_DIR/$f" ] && artifacts+=("$f")
done

if [ ${#artifacts[@]} -eq 0 ]; then
  exit 0
fi

echo "=== Pipeline State ==="
echo "Artifacts present: ${artifacts[*]}"

# Current stage
if   [ -f "$PIPELINE_DIR/build.complete" ]; then echo "Stage: post-build"
elif [ -f "$PIPELINE_DIR/plan.md" ];         then echo "Stage: build-ready"
elif [ -f "$PIPELINE_DIR/design.approved" ]; then echo "Stage: plan-ready"
elif [ -f "$PIPELINE_DIR/design.md" ];       then echo "Stage: review"
elif [ -f "$PIPELINE_DIR/brief.md" ];        then echo "Stage: design-ready"
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
if [ -n "$snap_info" ]; then
  echo "Repomix snapshots: $snap_info (verify age before reuse)"
fi

exit 0
