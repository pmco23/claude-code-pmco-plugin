#!/usr/bin/env bash
# pipeline-gate.sh
# Enforces quality gates for the development pipeline.
# Reads PreToolUse JSON from stdin; blocks if required .pipeline/ artifact is missing.

set -euo pipefail

HOOKS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HOOKS_DIR/lib/find-project.sh"
source "$HOOKS_DIR/lib/json-helpers.sh"

INPUT=$(cat)

# Extract skill name from tool_input.skill
SKILL=$(echo "$INPUT" | _json_stdin_field "tool_input.skill")

# Not a skill invocation or parse failed — allow
if [ -z "$SKILL" ]; then
  exit 0
fi

PIPELINE_DIR=$(find_pipeline_dir)

block() {
  local message="$1"
  echo "$message"
  exit 2
}

# Stale artifact warning — check if source files are newer than the gating artifact.
# Warns but never blocks. Only fires for gated pipeline skills.
warn_if_stale() {
  local artifact="$1"
  local skill_name="$2"
  local prereq_name="$3"
  [ -f "$artifact" ] || return 0
  # Find source files newer than the artifact (depth-limited, common extensions, excludes noise)
  local stale_count
  stale_count=$(find "$(dirname "$PIPELINE_DIR")" \
    -maxdepth 3 \
    \( -name .pipeline -o -name .git -o -name node_modules -o -name __pycache__ -o -name vendor -o -name dist -o -name build \) -prune \
    -o -type f \( -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.jsx' -o -name '*.go' -o -name '*.py' -o -name '*.cs' -o -name '*.rs' -o -name '*.java' \) \
    -newer "$artifact" -print 2>/dev/null | head -5 | wc -l)
  if [ "$stale_count" -gt 0 ]; then
    echo "⚠ Source files changed since $prereq_name was written. Consider re-running /$prereq_name if requirements shifted."
  fi
}

case "$SKILL" in
  "quick")
    # Pipeline-aware but never blocked — warn if a pipeline is active
    if [ -f "$PIPELINE_DIR/build.complete" ]; then
      echo "Pipeline at QA phase — /quick will not affect pipeline artifacts."
    elif [ -f "$PIPELINE_DIR/plan.md" ]; then
      echo "⚠ Build in progress — /quick may conflict with active builders if touching the same files."
    elif [ -f "$PIPELINE_DIR/design.approved" ]; then
      echo "Pipeline at planning phase — no active build in progress."
    elif [ -f "$PIPELINE_DIR/design.md" ]; then
      echo "Pipeline at design/review phase — no code has been written yet."
    elif [ -f "$PIPELINE_DIR/brief.md" ]; then
      echo "Pipeline at brief phase — no code has been written yet."
    fi
    exit 0
    ;;
  "design")
    [ -f "$PIPELINE_DIR/brief.md" ] || block "No brief found. Run /brief first to crystallize requirements into a brief."
    warn_if_stale "$PIPELINE_DIR/brief.md" "design" "brief"
    ;;
  "review")
    [ -f "$PIPELINE_DIR/design.md" ] || block "No design doc found. Run /design first."
    warn_if_stale "$PIPELINE_DIR/design.md" "review" "design"
    ;;
  "plan")
    [ -f "$PIPELINE_DIR/design.approved" ] || block "Design not approved. Run /review and iterate until all findings resolve."
    warn_if_stale "$PIPELINE_DIR/design.approved" "plan" "review"
    ;;
  "build"|"drift-check")
    [ -f "$PIPELINE_DIR/plan.md" ] || block "No execution plan found. Run /plan first."
    warn_if_stale "$PIPELINE_DIR/plan.md" "build" "plan"
    ;;
  "cleanup"|"frontend-audit"|"backend-audit"|"doc-audit"|"security-review"|"qa")
    [ -f "$PIPELINE_DIR/build.complete" ] || block "Build not complete. Run /build first, then ensure /drift-check passes."
    ;;
esac

exit 0
