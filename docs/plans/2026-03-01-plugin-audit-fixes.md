# Plugin Audit Fixes Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix all bugs found in the deep plugin audit and add all required/optional improvements across hooks, documentation, testing, and plugin metadata.

**Architecture:** Five independent tasks with no shared files — all can run in parallel. Each task touches a distinct set of files: hook scripts, README, plugin manifest, test suite, gitignore.

**Tech Stack:** Bash, Node.js (statusline), Markdown (README), JSON (plugin.json)

---

### Task 1: Fix hook portability — jq-first fallback for python3 JSON parsing

**Files:**
- Modify: `hooks/pipeline_gate.sh`
- Modify: `hooks/context-monitor.sh`

**Context:** Both hook scripts use `python3 -c "import json..."` to parse JSON payloads. If python3 is absent, `pipeline_gate.sh` silently allows all skills through (the gate becomes non-functional with no warning). `context-monitor.sh` silently outputs nothing. The fix adds a `jq`-first path that falls back to python3, and if neither is available, degrades gracefully with a logged warning.

**Step 1: Read hooks/pipeline_gate.sh**

Read `hooks/pipeline_gate.sh` in full.

**Step 2: Replace the python3-only block in pipeline_gate.sh**

Find this exact block:

```bash
SKILL=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    skill = d.get('tool_input', {}).get('skill', '')
    print(skill)
except Exception:
    print('')
" 2>/dev/null || echo "")
```

Replace with:

```bash
# Extract skill name — prefer jq, fall back to python3
if command -v jq >/dev/null 2>&1; then
  SKILL=$(echo "$INPUT" | jq -r '.tool_input.skill // empty' 2>/dev/null || echo "")
elif command -v python3 >/dev/null 2>&1; then
  SKILL=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    skill = d.get('tool_input', {}).get('skill', '')
    print(skill)
except Exception:
    print('')
" 2>/dev/null || echo "")
else
  # Neither jq nor python3 available — fail open with warning
  echo "pipeline_gate: jq and python3 unavailable, gate disabled" >&2
  exit 0
fi
```

**Step 3: Read hooks/context-monitor.sh**

Read `hooks/context-monitor.sh` in full.

**Step 4: Add helper functions and replace all three python3 calls in context-monitor.sh**

After the `set -euo pipefail` line, insert this helper block:

```bash
# Portable JSON helpers — prefer jq, fall back to python3
_json_stdin_field() {
  local field="$1"
  if command -v jq >/dev/null 2>&1; then
    jq -r ".${field} // empty" 2>/dev/null || true
  elif command -v python3 >/dev/null 2>&1; then
    python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('${field}',''))" 2>/dev/null || true
  fi
}

_json_file_field() {
  local file="$1" field="$2" default="${3:-0}"
  if command -v jq >/dev/null 2>&1; then
    jq -r ".${field} // ${default}" "$file" 2>/dev/null || echo "$default"
  elif command -v python3 >/dev/null 2>&1; then
    python3 -c "import json; d=json.load(open('${file}')); print(d.get('${field}',${default}))" 2>/dev/null || echo "$default"
  else
    echo "$default"
  fi
}
```

Then replace the three python3 call sites:

Replace:
```bash
SESSION_ID=$(echo "$INPUT" | python3 -c \
  "import json,sys; d=json.load(sys.stdin); print(d.get('session_id',''))" \
  2>/dev/null || true)
```
With:
```bash
SESSION_ID=$(echo "$INPUT" | _json_stdin_field "session_id")
```

Replace:
```bash
USED_PCT=$(python3 -c \
  "import json; d=json.load(open('${BRIDGE_FILE}')); print(d.get('used_pct',0))" \
  2>/dev/null || echo "0")
```
With:
```bash
USED_PCT=$(_json_file_field "$BRIDGE_FILE" "used_pct" "0")
```

Replace:
```bash
TIMESTAMP=$(python3 -c \
  "import json; d=json.load(open('${BRIDGE_FILE}')); print(d.get('timestamp',0))" \
  2>/dev/null || echo "0")
```
With:
```bash
TIMESTAMP=$(_json_file_field "$BRIDGE_FILE" "timestamp" "0")
```

**Step 5: Verify gate tests still pass**

```bash
bash hooks/test_gate.sh
```

Expected: `Results: 44 passed, 0 failed`

**Step 6: Commit**

```bash
git add hooks/pipeline_gate.sh hooks/context-monitor.sh
git commit -m "fix: add jq-first fallback for python3 JSON parsing in gate and context-monitor hooks"
```

---

### Task 2: README comprehensive update

**Files:**
- Modify: `README.md`

**Context:** Eight distinct edits required — all in one task to avoid conflicts: (1) add Repomix to Optional prerequisites table, (2) add Repomix MCP Setup section, (3) add statusline path portability note, (4) add /pack to pipeline diagram, (5) add /pack command reference, (6) add /plugin-architecture command reference, (7) add repomix-pack.json to .pipeline/ state table, (8) add test_gate.sh to Troubleshooting.

**Step 1: Read README.md in full**

Read `README.md` completely before editing.

**Step 2: Add Repomix row to Optional prerequisites table**

Find:
```
| C# LSP | Symbol resolution for .NET projects | `/plugin install csharp-lsp@claude-plugins-official` |
```

Add a new row immediately after it:
```
| Repomix MCP | Token-efficient codebase packing for `/pack`, `/qa`, `/plan`, `/brief` | See [Repomix MCP setup](#repomix-mcp-setup) |
```

**Step 3: Add Repomix MCP Setup section before Statusline Setup**

Find `## Statusline Setup` and insert this complete section immediately before it:

```markdown
## Repomix MCP Setup

Install Repomix and register it as an MCP server for token-efficient codebase packing.

**1. Install Repomix**

```bash
npm install -g repomix
```

**2. Register the MCP server (user scope — available across all projects)**

```bash
claude mcp add --scope user repomix -- repomix --mcp
```

Restart Claude Code to pick up the new server.

**3. Verify**

Run `/pack` in any project directory. If Repomix MCP is connected, it packs the codebase and writes `.pipeline/repomix-pack.json`. If not connected, `/pack` will fail — `/qa`, `/plan`, and `/brief` fall back to native file tools automatically.

---

```

**Step 4: Add statusline path portability note**

Find the statusline JSON block ending with `}` after `"command": "node ~/claude-agents-custom/hooks/statusline.js"`. Add a note immediately after the closing code fence of the JSON block:

```markdown
> **Note:** Replace `~/claude-agents-custom` with your actual install path. Run `/plugin list` in a Claude Code session to see the installed path.
```

**Step 5: Add /pack to the pipeline diagram**

Find:
```
 ├─ /status                  # inspect current pipeline phase — always available
 │
```

Replace with:
```
 ├─ /status                  # inspect current pipeline phase — always available
 ├─ /pack [path]             # Repomix snapshot — run before /qa for token efficiency
 │
```

**Step 6: Add /pack command reference section**

Find `### /status — Pipeline State Check` section. Insert the following section immediately after the entire /status section (after its closing `---` separator):

```markdown
### /pack — Repomix Codebase Snapshot

**Gate:** None (always available — requires Repomix MCP)
**Writes:** `.pipeline/repomix-pack.json`
**Model:** inherits from calling context

Packs the local codebase using Repomix MCP and stores the outputId in `.pipeline/repomix-pack.json`. Run before `/qa` to share one compressed pack across all five audit agents (~70% token reduction via Tree-sitter compression). `/qa` automatically uses the stored pack if it is less than 1 hour old.

```
/pack              # pack current working directory
/pack src/         # pack a subdirectory
```

If Repomix MCP is not installed, this skill will fail. Other skills (`/qa`, `/plan`, `/brief`) fall back to native file tools when no pack is available.

---

```

**Step 7: Add /plugin-architecture command reference section**

Find `### /git-workflow — Git Discipline` section. Insert the following section immediately after the entire /git-workflow section (after its closing `---` separator):

```markdown
### /plugin-architecture — Plugin Architecture Guide

**Gate:** None (always available)
**Writes:** nothing
**Model:** inherits from calling context

Decision guide for when to use skills vs agents in Claude Code plugin development. Covers the fitness criterion (self-contained + read-only + verbose output), the thin wrapper and split patterns, agent frontmatter format, composition rules, and anti-patterns. Run when designing a new plugin component or evaluating whether an existing skill should become an agent.

```
/plugin-architecture
```

---

```

**Step 8: Add repomix-pack.json to .pipeline/ state directory section**

Find:
```
└── build.complete    # written by /build after /drift-check passes
```

Replace with:
```
├── build.complete    # written by /build after /drift-check passes
└── repomix-pack.json # written by /pack or auto-generated by /qa preamble
```

**Step 9: Add test_gate.sh entry to Troubleshooting**

Find `### Plugin not loading after changes`. Insert the following section immediately before it:

```markdown
### Verifying gate logic

Run `hooks/test_gate.sh` to confirm all pipeline gate rules are working correctly:

```bash
bash ~/claude-agents-custom/hooks/test_gate.sh
```

Expected: `Results: 49 passed, 0 failed`

---

```

**Step 10: Verify README**

Read `README.md` and confirm all 8 changes are present.

**Step 11: Commit**

```bash
git add README.md
git commit -m "docs: add Repomix prerequisites and setup, /pack and /plugin-architecture command reference, gate test docs"
```

---

### Task 3: Bump plugin.json version and create CHANGELOG.md

**Files:**
- Modify: `.claude-plugin/plugin.json`
- Create: `CHANGELOG.md`

**Context:** plugin.json is still at 1.0.0 despite three significant improvement rounds. Version scheme: 1.1.0 = initial hook/doc fixes, 1.2.0 = Repomix integration, 1.3.0 = this audit improvements batch. CHANGELOG.md uses Keep a Changelog format.

**Step 1: Read .claude-plugin/plugin.json**

Read `.claude-plugin/plugin.json`.

**Step 2: Bump version to 1.3.0**

Replace:
```json
  "version": "1.0.0",
```
With:
```json
  "version": "1.3.0",
```

**Step 3: Create CHANGELOG.md**

Create `CHANGELOG.md` at the repo root:

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.3.0] - 2026-03-01

### Added
- `/pack` skill — Repomix codebase snapshot with `.pipeline/repomix-pack.json` state
- `/plugin-architecture` skill — agents vs skills decision guide
- `docs/guides/agents-vs-skills.md` — full evaluation table and composition patterns
- Model advisories on Opus-targeted skills (`/brief`, `/design`, `/plan`, `/build`, `/drift-check`)
- Repomix MCP integration: `/qa` preamble, `/plan` Step 2, `/brief` Step 1, 5 audit skills
- CHANGELOG.md (this file)
- `.gitignore`

### Fixed
- PostToolUse hook matcher narrowed from `"*"` to `"Bash|Agent|Task"` (was firing on every tool call)
- Codex MCP verification step in README corrected (`/status` does not list tools)
- `/quick` LSP diagnostics wording fixed — cannot distinguish new from pre-existing issues
- `/plan` Step 2 now uses `pack_codebase` for accurate file-tree grounding
- `statusline.js` pipeline phase detection now walks up directories (mirrors `pipeline_gate.sh`)
- `pipeline_gate.sh` and `context-monitor.sh` now prefer `jq`, fall back to `python3`
- README prerequisites updated to include Repomix MCP
- Statusline setup section now notes path portability

## [1.0.0] - 2026-01-15

### Added
- Initial release: quality-gated development pipeline (`/brief` → `/design` → `/review` → `/plan` → `/build` → `/qa`)
- `pipeline_gate.sh` PreToolUse hook enforcing phase progression with `.pipeline/` walk-up search
- `statusline.js` showing model, task, pipeline phase, directory, and context usage
- `context-monitor.sh` injecting context warnings at 63%, 81%, and 95% thresholds
- `/quick` fast-track implementation with optional lightweight audit
- `/init` project boilerplate scaffolding (README, CHANGELOG, CONTRIBUTING, PR template)
- `/git-workflow` for branching discipline (code-path and infra-path variants)
- `/drift-check` for design-to-build verification (Sonnet + Codex + Opus lead)
- `/status` pipeline state reporter
- Language support matrix: TypeScript, Go, Python, C# LSP integrations
- `hooks/test_gate.sh` — gate scenario regression tests
```

**Step 4: Verify**

Read `.claude-plugin/plugin.json` — confirm `"version": "1.3.0"`.
Read `CHANGELOG.md` lines 1-10 — confirm Keep a Changelog header and `[1.3.0]` section.

**Step 5: Commit**

```bash
git add .claude-plugin/plugin.json CHANGELOG.md
git commit -m "chore: bump version to 1.3.0 and add CHANGELOG.md"
```

---

### Task 4: Extend test_gate.sh — coverage for /pack and /plugin-architecture

**Files:**
- Modify: `hooks/test_gate.sh`

**Context:** Two new always-allowed skills (`/pack`, `/plugin-architecture`) have no gate tests. Both have no prerequisites. After this task the test suite will report `49 passed` (was 44).

**Step 1: Read hooks/test_gate.sh lines 118-127**

Read the end of `hooks/test_gate.sh` to confirm the exact text before the Cleanup block.

**Step 2: Insert test cases before the Cleanup block**

Find:
```bash
# Cleanup
rm -rf "$NO_PIPELINE" "$HAS_BRIEF" "$HAS_DESIGN" "$HAS_APPROVED" "$HAS_PLAN" "$HAS_BUILD"
```

Insert immediately before it:

```bash
# /pack — always allowed (no gate; Repomix MCP required at runtime but not enforced by gate)
expect_allow "pack" "$NO_PIPELINE" "/pack with no pipeline: allow"
expect_allow "pack" "$HAS_BRIEF"   "/pack at brief phase: allow"
expect_allow "pack" "$HAS_BUILD"   "/pack at QA phase: allow"

# /plugin-architecture — always allowed (meta-skill, no pipeline dependency)
expect_allow "plugin-architecture" "$NO_PIPELINE" "/plugin-architecture with no pipeline: allow"
expect_allow "plugin-architecture" "$HAS_BUILD"   "/plugin-architecture at QA phase: allow"

```

**Step 3: Run the updated test suite**

```bash
bash hooks/test_gate.sh
```

Expected: `Results: 49 passed, 0 failed`

**Step 4: Commit**

```bash
git add hooks/test_gate.sh
git commit -m "test: add gate coverage for /pack and /plugin-architecture (44 → 49 tests)"
```

---

### Task 5: Add .gitignore

**Files:**
- Create: `.gitignore`

**Context:** The README recommends adding `.pipeline/` to `.gitignore` but the repo has no `.gitignore`. Add standard Node.js and OS ignores too since the repo contains `statusline.js`.

**Step 1: Verify .gitignore does not already exist**

```bash
ls .gitignore 2>/dev/null && echo "exists" || echo "not found"
```

**Step 2: Create .gitignore**

Create `.gitignore`:

```gitignore
# Pipeline artifacts — not committed by default (see README)
.pipeline/

# Node.js
node_modules/
npm-debug.log*

# OS
.DS_Store
Thumbs.db
```

**Step 3: Commit**

```bash
git add .gitignore
git commit -m "chore: add .gitignore with .pipeline/, node_modules, OS entries"
```

---

## Parallelism

All 5 tasks touch distinct files — zero conflicts, run all simultaneously:

| Task | Files touched |
|------|--------------|
| 1 | `hooks/pipeline_gate.sh`, `hooks/context-monitor.sh` |
| 2 | `README.md` |
| 3 | `.claude-plugin/plugin.json`, `CHANGELOG.md` (new) |
| 4 | `hooks/test_gate.sh` |
| 5 | `.gitignore` (new) |

## Final Verification (after all tasks)

```bash
# Gate tests must pass with new count
bash hooks/test_gate.sh
# Expected: Results: 49 passed, 0 failed

# JSON must be valid
python3 -m json.tool .claude-plugin/plugin.json
python3 -m json.tool hooks/hooks.json
```
