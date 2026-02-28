#!/usr/bin/env bash
# Tests the pipeline gate logic against all gate scenarios.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GATE="$SCRIPT_DIR/pipeline_gate.sh"
PASS=0
FAIL=0

run_gate() {
  local skill="$1"
  local test_dir="$2"
  echo "{\"tool_input\":{\"skill\":\"$skill\"}}" | PIPELINE_TEST_DIR="$test_dir" bash "$GATE" > /dev/null 2>&1
  return $?
}

expect_block() {
  local skill="$1"
  local test_dir="$2"
  local desc="$3"
  if run_gate "$skill" "$test_dir"; then
    echo "FAIL: $desc — expected block, got allow"
    FAIL=$((FAIL+1))
  else
    echo "PASS: $desc"
    PASS=$((PASS+1))
  fi
}

expect_allow() {
  local skill="$1"
  local test_dir="$2"
  local desc="$3"
  if run_gate "$skill" "$test_dir"; then
    echo "PASS: $desc"
    PASS=$((PASS+1))
  else
    echo "FAIL: $desc — expected allow, got block"
    FAIL=$((FAIL+1))
  fi
}

# Setup temp dirs
NO_PIPELINE=$(mktemp -d)
HAS_BRIEF=$(mktemp -d)    && mkdir -p "$HAS_BRIEF/.pipeline"    && touch "$HAS_BRIEF/.pipeline/brief.md"
HAS_DESIGN=$(mktemp -d)   && mkdir -p "$HAS_DESIGN/.pipeline"   && touch "$HAS_DESIGN/.pipeline/design.md"
HAS_APPROVED=$(mktemp -d) && mkdir -p "$HAS_APPROVED/.pipeline" && touch "$HAS_APPROVED/.pipeline/design.approved"
HAS_PLAN=$(mktemp -d)     && mkdir -p "$HAS_PLAN/.pipeline"     && touch "$HAS_PLAN/.pipeline/plan.md"
HAS_BUILD=$(mktemp -d)    && mkdir -p "$HAS_BUILD/.pipeline"    && touch "$HAS_BUILD/.pipeline/build.complete"

# /arm — always allowed
expect_allow "arm" "$NO_PIPELINE" "/arm with no .pipeline: allow"
expect_allow "arm" "$HAS_BRIEF"   "/arm with brief: allow"

# /design gate
expect_block "design" "$NO_PIPELINE" "/design with no .pipeline: block"
expect_allow "design" "$HAS_BRIEF"   "/design with brief: allow"

# /ar gate
expect_block "ar" "$NO_PIPELINE" "/ar with no .pipeline: block"
expect_block "ar" "$HAS_BRIEF"   "/ar with only brief: block"
expect_allow "ar" "$HAS_DESIGN"  "/ar with design.md: allow"

# /plan gate
expect_block "plan" "$NO_PIPELINE"  "/plan with no .pipeline: block"
expect_block "plan" "$HAS_DESIGN"   "/plan with design.md but no approval: block"
expect_allow "plan" "$HAS_APPROVED" "/plan with design.approved: allow"

# /build gate
expect_block "build" "$NO_PIPELINE" "/build with no .pipeline: block"
expect_block "build" "$HAS_APPROVED" "/build without plan: block"
expect_allow "build" "$HAS_PLAN"    "/build with plan.md: allow"

# /pmatch gate
expect_block "pmatch" "$NO_PIPELINE" "/pmatch without plan: block"
expect_allow "pmatch" "$HAS_PLAN"    "/pmatch with plan.md: allow"

# QA skills gate
for skill in qa denoise qf qb qd security-review; do
  expect_block "$skill" "$NO_PIPELINE" "/$skill without build.complete: block"
  expect_block "$skill" "$HAS_PLAN"    "/$skill with only plan (no build): block"
  expect_allow "$skill" "$HAS_BUILD"   "/$skill with build.complete: allow"
done

# /quick — always allowed, but emits warning when pipeline is active
expect_allow "quick" "$NO_PIPELINE" "/quick with no pipeline: allow (no warning)"
expect_allow "quick" "$HAS_BRIEF"   "/quick at brief phase: allow (warn)"
expect_allow "quick" "$HAS_DESIGN"  "/quick at design phase: allow (warn)"
expect_allow "quick" "$HAS_APPROVED" "/quick at planning phase: allow (warn)"
expect_allow "quick" "$HAS_PLAN"    "/quick with build in progress: allow (warn)"
expect_allow "quick" "$HAS_BUILD"   "/quick at QA phase: allow (warn)"

# Verify /quick warning content
run_gate_output() {
  local skill="$1"
  local test_dir="$2"
  echo "{\"tool_input\":{\"skill\":\"$skill\"}}" | PIPELINE_TEST_DIR="$test_dir" bash "$GATE" 2>/dev/null
}

check_warning() {
  local test_dir="$1"
  local expected_fragment="$2"
  local desc="$3"
  local output
  output=$(run_gate_output "quick" "$test_dir")
  if echo "$output" | grep -q "$expected_fragment"; then
    echo "PASS: $desc"
    PASS=$((PASS+1))
  else
    echo "FAIL: $desc — expected '$expected_fragment' in output, got: '$output'"
    FAIL=$((FAIL+1))
  fi
}

check_warning "$HAS_PLAN"    "Build in progress"  "/quick warns about active build"
check_warning "$HAS_BUILD"   "QA phase"           "/quick warns at QA phase"
check_warning "$HAS_APPROVED" "planning phase"    "/quick warns at planning phase"
check_warning "$HAS_DESIGN"  "design/review"      "/quick warns at design/review phase"
check_warning "$HAS_BRIEF"   "brief phase"        "/quick warns at brief phase"

# Cleanup
rm -rf "$NO_PIPELINE" "$HAS_BRIEF" "$HAS_DESIGN" "$HAS_APPROVED" "$HAS_PLAN" "$HAS_BUILD"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
