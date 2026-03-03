#!/usr/bin/env bash
# compact-prep.sh
# PreCompact hook: outputs current pipeline state so it is preserved in the compact summary.

PIPELINE_DIR=".pipeline"

if [ ! -d "$PIPELINE_DIR" ]; then
  exit 0
fi

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

# Repomix pack (may expire — note for Claude)
if [ -f "$PIPELINE_DIR/repomix-pack.json" ]; then
  outputId=$(python3 - "$PIPELINE_DIR/repomix-pack.json" <<'PYEOF' 2>/dev/null
import json, sys
try:
    d = json.load(open(sys.argv[1]))
    print(d.get("outputId", ""))
except Exception:
    pass
PYEOF
)
  [ -n "$outputId" ] && echo "Repomix outputId: $outputId (verify age before reuse)"
fi

exit 0
