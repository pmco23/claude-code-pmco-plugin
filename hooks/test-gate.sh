#!/usr/bin/env bash
# Tests pipeline-gate.sh and related hook JSON outputs against supported hook payloads.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GATE="$SCRIPT_DIR/pipeline-gate.sh"
GUARD="$SCRIPT_DIR/convention-guard.sh"
MONITOR="$SCRIPT_DIR/context-monitor.sh"
COMPACT="$SCRIPT_DIR/compact-prep.sh"
PASS=0
FAIL=0

run_gate() {
  local prompt="$1"
  local test_dir="$2"
  printf '{"prompt":"%s"}\n' "$prompt" | PIPELINE_TEST_DIR="$test_dir" bash "$GATE"
}

expect_block_reason() {
  local prompt="$1"
  local test_dir="$2"
  local expected_fragment="$3"
  local desc="$4"
  local output
  output=$(run_gate "$prompt" "$test_dir")
  if echo "$output" | grep -q '"decision":"block"' && echo "$output" | grep -q "$expected_fragment"; then
    echo "PASS: $desc"
    PASS=$((PASS+1))
  else
    echo "FAIL: $desc — expected block reason '$expected_fragment', got: '$output'"
    FAIL=$((FAIL+1))
  fi
}

expect_allow() {
  local prompt="$1"
  local test_dir="$2"
  local desc="$3"
  local output
  output=$(run_gate "$prompt" "$test_dir")
  if echo "$output" | grep -q '"decision":"block"'; then
    echo "FAIL: $desc — expected allow, got block: '$output'"
    FAIL=$((FAIL+1))
  else
    echo "PASS: $desc"
    PASS=$((PASS+1))
  fi
}

check_output_contains() {
  local output="$1"
  local expected_fragment="$2"
  local desc="$3"
  if echo "$output" | grep -q "$expected_fragment"; then
    echo "PASS: $desc"
    PASS=$((PASS+1))
  else
    echo "FAIL: $desc — expected '$expected_fragment' in output, got: '$output'"
    FAIL=$((FAIL+1))
  fi
}

expect_empty_output() {
  local output="$1"
  local desc="$2"
  if [ -z "$output" ]; then
    echo "PASS: $desc"
    PASS=$((PASS+1))
  else
    echo "FAIL: $desc — expected empty output, got: '$output'"
    FAIL=$((FAIL+1))
  fi
}

run_guard() {
  local file_path="$1"
  printf '{"tool_input":{"file_path":"%s"}}\n' "$file_path" | bash "$GUARD"
}

# Setup temp dirs
NO_PIPELINE=$(mktemp -d)
HAS_BRIEF=$(mktemp -d)    && mkdir -p "$HAS_BRIEF/.pipeline"    && touch "$HAS_BRIEF/.pipeline/brief.md"
HAS_DESIGN=$(mktemp -d)   && mkdir -p "$HAS_DESIGN/.pipeline"   && touch "$HAS_DESIGN/.pipeline/design.md"
HAS_APPROVED=$(mktemp -d) && mkdir -p "$HAS_APPROVED/.pipeline" && touch "$HAS_APPROVED/.pipeline/design.approved"
HAS_PLAN=$(mktemp -d)     && mkdir -p "$HAS_PLAN/.pipeline"     && touch "$HAS_PLAN/.pipeline/plan.md"
HAS_BUILD=$(mktemp -d)    && mkdir -p "$HAS_BUILD/.pipeline"    && touch "$HAS_BUILD/.pipeline/build.complete"

# /brief — always allowed
expect_allow "/brief" "$NO_PIPELINE" "/brief with no .pipeline: allow"
expect_allow "/brief" "$HAS_BRIEF"   "/brief with brief: allow"

# /design gate
expect_block_reason "/design" "$NO_PIPELINE" "No brief found" "/design with no .pipeline: block"
expect_allow "/design" "$HAS_BRIEF"   "/design with brief: allow"

# /review gate
expect_block_reason "/review" "$NO_PIPELINE" "No design doc found" "/review with no .pipeline: block"
expect_block_reason "/review" "$HAS_BRIEF"   "No design doc found" "/review with only brief: block"
expect_allow "/review" "$HAS_DESIGN"  "/review with design.md: allow"

# /plan gate
expect_block_reason "/plan" "$NO_PIPELINE" "Design not approved" "/plan with no .pipeline: block"
expect_block_reason "/plan" "$HAS_DESIGN" "Design not approved" "/plan with design.md but no approval: block"
expect_allow "/plan" "$HAS_APPROVED" "/plan with design.approved: allow"

# /build gate
expect_block_reason "/build" "$NO_PIPELINE" "No execution plan found" "/build with no .pipeline: block"
expect_block_reason "/build" "$HAS_APPROVED" "No execution plan found" "/build without plan: block"
expect_allow "/build" "$HAS_PLAN" "/build with plan.md: allow"

# /drift-check gate
expect_block_reason "/drift-check" "$NO_PIPELINE" "No execution plan found" "/drift-check without plan: block"
expect_allow "/drift-check" "$HAS_PLAN" "/drift-check with plan.md: allow"

# QA skills gate
for skill in qa cleanup frontend-audit backend-audit doc-audit security-review; do
  expect_block_reason "/$skill" "$NO_PIPELINE" "Build not complete" "/$skill without build.complete: block"
  expect_block_reason "/$skill" "$HAS_PLAN" "Build not complete" "/$skill with only plan (no build): block"
  expect_allow "/$skill" "$HAS_BUILD" "/$skill with build.complete: allow"
done

# /quick — always allowed, but emits warning when pipeline is active
expect_allow "/quick" "$NO_PIPELINE" "/quick with no pipeline: allow (no warning)"
expect_allow "/quick" "$HAS_BRIEF" "/quick at brief phase: allow (warn)"
expect_allow "/quick" "$HAS_DESIGN" "/quick at design phase: allow (warn)"
expect_allow "/quick" "$HAS_APPROVED" "/quick at planning phase: allow (warn)"
expect_allow "/quick" "$HAS_PLAN" "/quick with build in progress: allow (warn)"
expect_allow "/quick" "$HAS_BUILD" "/quick at QA phase: allow (warn)"

check_warning() {
  local test_dir="$1"
  local expected_fragment="$2"
  local desc="$3"
  local output
  output=$(run_gate "/quick" "$test_dir")
  check_output_contains "$output" "$expected_fragment" "$desc"
}

check_warning "$HAS_PLAN" "Build in progress" "/quick warns about active build"
check_warning "$HAS_BUILD" "QA phase" "/quick warns at QA phase"
check_warning "$HAS_APPROVED" "planning phase" "/quick warns at planning phase"
check_warning "$HAS_DESIGN" "design/review" "/quick warns at design/review phase"
check_warning "$HAS_BRIEF" "brief phase" "/quick warns at brief phase"

# /pack — always allowed (no gate)
expect_allow "/pack" "$NO_PIPELINE" "/pack with no pipeline: allow"
expect_allow "/pack" "$HAS_BRIEF" "/pack at brief phase: allow"
expect_allow "/pack" "$HAS_BUILD" "/pack at QA phase: allow"

# /test, /rollback, /reset — always allowed (self-gated internally)
expect_allow "/test" "$NO_PIPELINE" "/test with no pipeline: allow"
expect_allow "/rollback" "$NO_PIPELINE" "/rollback with no pipeline: allow"
expect_allow "/reset" "$NO_PIPELINE" "/reset with no pipeline: allow"
expect_allow "/reset" "$HAS_BUILD" "/reset at QA phase: allow"

# Non-slash prompt — ignored
empty_output=$(run_gate "summarize the repo" "$HAS_BUILD")
expect_empty_output "$empty_output" "non-slash prompt is ignored"

# convention-guard JSON
guard_output=$(run_guard "/tmp/x/.claude-plugin/foo.txt")
check_output_contains "$guard_output" '"permissionDecision":"deny"' "convention-guard denies non-manifest writes"
check_output_contains "$guard_output" 'Only manifests' "convention-guard deny reason included"

guard_output=$(run_guard "/tmp/x/.claude-plugin/plugin.json")
check_output_contains "$guard_output" 'systemMessage' "convention-guard emits version sync reminder"
check_output_contains "$guard_output" 'bump both' "convention-guard version sync reminder text"

guard_output=$(run_guard "/tmp/x/hooks/test.sh")
check_output_contains "$guard_output" 'systemMessage' "convention-guard emits hook reminder"
check_output_contains "$guard_output" 'test-gate.sh' "convention-guard hook reminder text"

# context-monitor JSON additionalContext
SESSION_ID="deadbeef-dead-beef-dead-beefdeadbeef"
BRIDGE_FILE="/tmp/claude-ctx-${SESSION_ID}.json"
printf '{"used_pct":96,"timestamp":%s}\n' "$(date +%s)" > "$BRIDGE_FILE"
monitor_output=$(printf '{"session_id":"%s"}\n' "$SESSION_ID" | bash "$MONITOR")
check_output_contains "$monitor_output" 'Context critical' "context-monitor emits additionalContext when threshold exceeded"
printf '{"used_pct":96,"timestamp":0}\n' > "$BRIDGE_FILE"
monitor_output=$(printf '{"session_id":"%s"}\n' "$SESSION_ID" | bash "$MONITOR")
expect_empty_output "$monitor_output" "context-monitor skips stale bridge files"
rm -f "$BRIDGE_FILE"

# compact-prep JSON additionalContext
compact_dir=$(mktemp -d)
mkdir -p "$compact_dir/.pipeline"
touch "$compact_dir/.pipeline/brief.md" "$compact_dir/.pipeline/design.md" "$compact_dir/.pipeline/plan.md"
printf 'abc' > "$compact_dir/.pipeline/repomix-code.xml"
compact_output=$(PIPELINE_TEST_DIR="$compact_dir" bash "$COMPACT")
check_output_contains "$compact_output" 'Artifacts present:' "compact-prep emits pipeline artifact summary"
check_output_contains "$compact_output" 'build-ready' "compact-prep emits stage summary"
rm -rf "$compact_dir"

# Cleanup
rm -rf "$NO_PIPELINE" "$HAS_BRIEF" "$HAS_DESIGN" "$HAS_APPROVED" "$HAS_PLAN" "$HAS_BUILD"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
