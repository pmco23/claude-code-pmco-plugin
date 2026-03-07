#!/usr/bin/env bash
# pipeline-gate.sh
# Enforces quality gates for slash-command pipeline entrypoints.
# Reads UserPromptSubmit JSON from stdin and blocks if a required .pipeline/
# artifact is missing.

set -euo pipefail

HOOKS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HOOKS_DIR/lib/find-project.sh"
source "$HOOKS_DIR/lib/json-helpers.sh"

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | _json_stdin_field "prompt")

# Non-slash prompt or parse failure — allow silently.
if [ -z "$PROMPT" ]; then
  exit 0
fi

PROMPT=$(printf '%s' "$PROMPT" | sed 's/^[[:space:]]*//')
read -r COMMAND _ <<<"$PROMPT"
if [[ "$COMMAND" != /* ]]; then
  exit 0
fi

SKILL="${COMMAND#/}"
PIPELINE_DIR=$(find_pipeline_dir)
MESSAGES=()

block() {
  local message="$1"
  _emit_block_decision "$message"
  exit 0
}

# Stale artifact warning — check if source files are newer than the gating artifact.
# Warns but never blocks. Only fires for gated pipeline skills.
warn_if_stale() {
  local artifact="$1"
  local prereq_name="$2"
  [ -f "$artifact" ] || return 0

  local stale_count
  stale_count=$(find "$(dirname "$PIPELINE_DIR")" \
    -maxdepth 3 \
    \( -name .pipeline -o -name .git -o -name node_modules -o -name __pycache__ -o -name vendor -o -name dist -o -name build \) -prune \
    -o -type f \( -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.jsx' -o -name '*.go' -o -name '*.py' -o -name '*.cs' -o -name '*.rs' -o -name '*.java' \) \
    -newer "$artifact" -print 2>/dev/null | head -5 | wc -l)

  if [ "$stale_count" -gt 0 ]; then
    printf 'Source files changed since /%s wrote its artifact. Consider re-running /%s if requirements shifted.' \
      "$prereq_name" \
      "$prereq_name"
  fi
}

case "$SKILL" in
  "quick")
    if [ -f "$PIPELINE_DIR/build.complete" ]; then
      MESSAGES+=("Pipeline at QA phase — /quick will not affect pipeline artifacts.")
    elif [ -f "$PIPELINE_DIR/plan.md" ]; then
      MESSAGES+=("Build in progress — /quick may conflict with active builders if touching the same files.")
    elif [ -f "$PIPELINE_DIR/design.approved" ]; then
      MESSAGES+=("Pipeline at planning phase — no active build in progress.")
    elif [ -f "$PIPELINE_DIR/design.md" ]; then
      MESSAGES+=("Pipeline at design/review phase — no code has been written yet.")
    elif [ -f "$PIPELINE_DIR/brief.md" ]; then
      MESSAGES+=("Pipeline at brief phase — no code has been written yet.")
    fi
    ;;
  "design")
    [ -f "$PIPELINE_DIR/brief.md" ] || block "No brief found. Run /brief first to crystallize requirements into a brief."
    stale_message=$(warn_if_stale "$PIPELINE_DIR/brief.md" "brief" || true)
    [ -n "$stale_message" ] && MESSAGES+=("$stale_message")
    ;;
  "review")
    [ -f "$PIPELINE_DIR/design.md" ] || block "No design doc found. Run /design first."
    stale_message=$(warn_if_stale "$PIPELINE_DIR/design.md" "design" || true)
    [ -n "$stale_message" ] && MESSAGES+=("$stale_message")
    ;;
  "plan")
    [ -f "$PIPELINE_DIR/design.approved" ] || block "Design not approved. Run /review and iterate until all findings resolve."
    stale_message=$(warn_if_stale "$PIPELINE_DIR/design.approved" "review" || true)
    [ -n "$stale_message" ] && MESSAGES+=("$stale_message")
    ;;
  "build"|"drift-check")
    [ -f "$PIPELINE_DIR/plan.md" ] || block "No execution plan found. Run /plan first."
    stale_message=$(warn_if_stale "$PIPELINE_DIR/plan.md" "plan" || true)
    [ -n "$stale_message" ] && MESSAGES+=("$stale_message")
    ;;
  "cleanup"|"frontend-audit"|"backend-audit"|"doc-audit"|"security-review"|"qa")
    [ -f "$PIPELINE_DIR/build.complete" ] || block "Build not complete. Run /build first, then ensure /drift-check passes."
    ;;
esac

if [ ${#MESSAGES[@]} -gt 0 ]; then
  _emit_additional_context "UserPromptSubmit" "$(printf '%s\n' "${MESSAGES[@]}")"
fi

exit 0
