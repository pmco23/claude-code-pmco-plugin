# Hooks Reference

This plugin registers six event hooks. Each one is passive infrastructure — none require user
action. They run automatically as Claude Code fires lifecycle events.

---

## SessionStart — `session-start-check.sh`

**When it fires:** Once, at the start of every Claude Code session.

**What it does:** Checks that the three external tools the plugin depends on are installed.
If any are missing it prints a warning to stderr and lists which tools are absent. The session
starts regardless — hooks fail open.

**Tools checked:**

| Tool | Used by |
|------|---------|
| `jq` | JSON parsing in `pipeline-gate.sh` and `context-monitor.sh` (primary) |
| `python3` | JSON parsing fallback when `jq` is absent |
| `repomix` | `/pack` and `/qa` codebase snapshots |

**Fail-open:** Missing tools degrade specific features but never block the session.

---

## PreToolUse — `pipeline-gate.sh`

**When it fires:** Before every `Skill` tool call.

**What it does:** Enforces the phase ordering of the development pipeline. It reads the skill
name from the tool-call payload, walks up the directory tree to find the nearest `.pipeline/`
directory, and checks whether the required artifact for that skill exists. If the artifact is
missing, it exits with code `2` (block) and tells Claude what to run first.

**Gate table:**

| Skill invoked | Required artifact | Block message |
|---------------|-------------------|---------------|
| `/design` | `.pipeline/brief.md` | Run `/brief` first |
| `/review` | `.pipeline/design.md` | Run `/design` first |
| `/plan` | `.pipeline/design.approved` | Run `/review` until all findings resolve |
| `/build`, `/drift-check` | `.pipeline/plan.md` | Run `/plan` first |
| `/cleanup`, `/frontend-audit`, `/backend-audit`, `/doc-audit`, `/security-review`, `/qa` | `.pipeline/build.complete` | Run `/build` then `/drift-check` first |
| `/quick` | — | Never blocked; warns if a pipeline is active |

Skills not in this table (e.g. `/status`, `/pack`, `/init`, `/git-workflow`) are always allowed. Commands (`/commit`, `/push`, `/commit-push-pr`, `/sync`, `/clean-branches`, `/release`) bypass the gate entirely — they are not skills and do not trigger `PreToolUse` on `Skill`.

**Walk-up search:** The gate searches from the current directory upward, so it works correctly
from any subdirectory of a project.

---

## PreToolUse — `convention-guard.sh`

**When it fires:** Before every `Write` or `Edit` tool call.

**What it does:** Enforces project conventions by inspecting the target file path:

| Rule | Trigger | Action | Message |
|------|---------|--------|---------|
| `.claude-plugin/` guard | Write/Edit to `.claude-plugin/*` (non-manifest) | **deny** (exit 2) | Only manifests belong in .claude-plugin/ |
| Hook chmod reminder | Write/Edit to `hooks/*.sh` | **allow** + context | Remember: chmod +x, correct shebang, run test-gate.sh |
| Version sync reminder | Write/Edit to `.claude-plugin/plugin.json` | **allow** + context | Also bump version in marketplace.json |

Outputs `hookSpecificOutput` JSON for Claude Code to display.

---

## PostToolUse — `context-monitor.sh`

**When it fires:** After every tool call.

**What it does:** Reads a bridge file written by `statusline.js` at
`/tmp/claude-ctx-<session_id>.json` and injects a context warning into Claude's output if the
context window is running low. The bridge file is ignored if it is more than 60 seconds old
(stale statusline data is silently skipped).

**Warning thresholds:**

| Usage | Message |
|-------|---------|
| ≥ 95% | `💀 Context critical — /compact now` |
| ≥ 81% | `⚠ Context at N% — /compact recommended` |
| ≥ 63% | `⚠ Context at N% — consider /compact soon` |

Below 63% the hook exits silently.

---

## PreCompact — `compact-prep.sh`

**When it fires:** Before Claude Code compacts the conversation.

**What it does:** Prints the current pipeline state to Claude's context so the compacted
summary preserves it. Without this, compaction could discard awareness of which pipeline
phase is active and which artifacts exist.

**Output (example):**

```
=== Pipeline State ===
Artifacts present: brief.md design.md design.approved plan.md
Stage: build-ready
Repomix snapshots: code (45KB), docs (13KB), full (98KB) (verify age before reuse)
```

If no `.pipeline/` directory exists, or the directory is empty, the hook exits silently.

---

## SessionEnd — `session-end-pack.sh`

**When it fires:** When a Claude Code session ends.

**What it does:** Generates three targeted Repomix snapshots (code, docs, full) into the
`.pipeline/` directory. Each `repomix` call is guarded by a 60-second timeout (fail-open if
the `timeout` command is absent). Writes a `repomix-pack.json` manifest with timestamps and
file sizes.

**Opt-out:** Add `session-end-pack: disabled` to your project's CLAUDE.md.

---

## SessionEnd — prompt hook

**When it fires:** When the main Claude agent considers stopping (end of a turn or session).

**What it does:** Injects a conditional prompt that asks Claude to update the
`## Current Focus` section of `MEMORY.md`. Claude self-evaluates whether the session was
substantive. If it was, it overwrites the section with 2–3 sentences covering what is in
flight, the next concrete step, and any key pending decision. If the session was trivial
(read-only exploration, Q&A only, no changes made), the hook is effectively silent.

**MEMORY.md handling:**

| State | Action |
|-------|--------|
| `MEMORY.md` does not exist | Create it |
| File exists, `## Current Focus` section absent | Add section at the bottom |
| File exists, section present | Overwrite the section |

This is a `type: "prompt"` hook — no shell script is involved. Claude performs the write
directly using its file-editing tools.

---

## Shared Libraries — `hooks/lib/`

Hooks share common logic via two sourceable library files in `hooks/lib/`. These files have no
shebang and are not executable — they are loaded with `source`.

### `hooks/lib/find-project.sh`

| Function | Returns | Failure |
|----------|---------|---------|
| `find_pipeline_dir` | `.pipeline` dir | Falls back to `$PWD/.pipeline` |
| `find_pipeline_dir_strict` | `.pipeline` dir | Returns 1 |
| `find_project_root` | Parent of `.pipeline` | Returns 1 |
| `find_file_up <name>` | File path | Returns 1 |

All functions respect `PIPELINE_TEST_DIR` for test compatibility.

### `hooks/lib/json-helpers.sh`

| Function | Input | Purpose |
|----------|-------|---------|
| `_json_stdin_field <dotted.path>` | stdin | Extract field from JSON on stdin |
| `_json_file_field <file> <field> [default]` | file | Extract field from JSON file |

Prefers `jq`, falls back to `python3`. Supports nested fields via dot notation.

---

## Summary

| Hook | Event | Type | Scope |
|------|-------|------|-------|
| `session-start-check.sh` | `SessionStart` | command | Warns on missing tools |
| `pipeline-gate.sh` | `PreToolUse` (Skill) | command | Enforces pipeline phase order |
| `convention-guard.sh` | `PreToolUse` (Write\|Edit) | command | Enforces project conventions |
| `context-monitor.sh` | `PostToolUse` | command | Warns on high context usage |
| `compact-prep.sh` | `PreCompact` | command | Preserves pipeline state across compaction |
| `session-end-pack.sh` | `SessionEnd` | command | Generates Repomix snapshots |
| *(prompt)* | `SessionEnd` | prompt | Updates MEMORY.md Current Focus |
