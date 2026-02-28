#!/usr/bin/env bash
# pipeline_gate.sh
# Enforces quality gates for the development pipeline.
# Reads PreToolUse JSON from stdin; blocks if required .pipeline/ artifact is missing.

set -euo pipefail

INPUT=$(cat)

# Extract skill name from JSON payload
SKILL=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    skill = d.get('tool_input', {}).get('skill', '')
    print(skill)
except Exception:
    print('')
" 2>/dev/null || echo "")

# Not a skill invocation or parse failed — allow
if [ -z "$SKILL" ]; then
  exit 0
fi

# Walk up from cwd to find .pipeline/ directory
find_pipeline_dir() {
  # Allow test override
  if [ -n "${PIPELINE_TEST_DIR:-}" ]; then
    echo "${PIPELINE_TEST_DIR}/.pipeline"
    return 0
  fi
  local dir="$PWD"
  while [ "$dir" != "/" ]; do
    if [ -d "$dir/.pipeline" ]; then
      echo "$dir/.pipeline"
      return 0
    fi
    dir=$(dirname "$dir")
  done
  echo "$PWD/.pipeline"
}

PIPELINE_DIR=$(find_pipeline_dir)

block() {
  local message="$1"
  echo "$message"
  exit 2
}

case "$SKILL" in
  "design")
    [ -f "$PIPELINE_DIR/brief.md" ] || block "No brief found. Run /arm first to crystallize requirements into a brief."
    ;;
  "ar")
    [ -f "$PIPELINE_DIR/design.md" ] || block "No design doc found. Run /design first."
    ;;
  "plan")
    [ -f "$PIPELINE_DIR/design.approved" ] || block "Design not approved. Run /ar and iterate until all findings resolve."
    ;;
  "build"|"pmatch")
    [ -f "$PIPELINE_DIR/plan.md" ] || block "No execution plan found. Run /plan first."
    ;;
  "denoise"|"qf"|"qb"|"qd"|"security-review"|"qa")
    [ -f "$PIPELINE_DIR/build.complete" ] || block "Build not complete. Run /build first, then ensure /pmatch passes."
    ;;
esac

exit 0
