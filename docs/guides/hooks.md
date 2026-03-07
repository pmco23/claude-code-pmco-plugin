# Hooks Reference

This plugin registers six command hooks. Each one is passive infrastructure — none require user
action. They run automatically as Claude Code fires lifecycle events.

---

## SessionStart — `session-start-check.sh`

**When it fires:** Once, at the start of every Claude Code session.

**What it does:** Checks that the three external tools the plugin depends on are installed.
If any are missing it prints a warning to stderr and lists which tools are absent. The session
starts regardless — hooks fail open.

It also keeps `~/.claude/statusline.js` aligned with this plugin's `hooks/statusline.js`,
but only when no statusline exists yet or the current file is already a symlink managed by this
plugin. It will not overwrite a custom statusline or another plugin's statusline.

**Tools checked:**

| Tool | Used by |
|------|---------|
| `jq` | JSON parsing in `pipeline-gate.sh` and `context-monitor.sh` (primary) |
| `python3` | JSON parsing fallback when `jq` is absent |
| `repomix` | `/pack` and `/qa` codebase snapshots |

**Fail-open:** Missing tools degrade specific features but never block the session.

---

## UserPromptSubmit — `pipeline-gate.sh`

**When it fires:** Before Claude processes a submitted prompt.

**What it does:** Enforces the phase ordering of the development pipeline for slash-command
skills. It reads the submitted prompt, extracts the first slash command, walks up the directory
tree to find the nearest `.pipeline/` directory, and checks whether the required artifact for
that skill exists. If the artifact is missing, it returns a JSON block decision with the exact
next step. If the command is `/quick` or a gating artifact looks stale, it injects
`additionalContext` so Claude can surface the warning in its reply.

**Gate table:**

| Skill invoked | Required artifact | Block message |
|---------------|-------------------|---------------|
| `/design` | `.pipeline/brief.md` | Run `/brief` first |
| `/review` | `.pipeline/design.md` | Run `/design` first |
| `/plan` | `.pipeline/design.approved` | Run `/review` until all findings resolve |
| `/build`, `/drift-check` | `.pipeline/plan.md` | Run `/plan` first |
| `/cleanup`, `/frontend-audit`, `/backend-audit`, `/doc-audit`, `/security-review`, `/qa` | `.pipeline/build.complete` | Run `/build` then `/drift-check` first |
| `/quick` | — | Never blocked; warns if a pipeline is active |

Slash commands not in this table (e.g. `/status`, `/pack`, `/init`, `/git-workflow`) are always
allowed. Non-slash prompts are ignored. Commands (`/commit`, `/push`, `/commit-push-pr`,
`/sync`, `/clean-branches`, `/release`) also bypass the gate because `pipeline-gate.sh`
explicitly ignores them.

**Walk-up search:** The gate searches from the current directory upward, so it works correctly
from any subdirectory of a project.

---

## PreToolUse — `convention-guard.sh`

**When it fires:** Before every `Write` or `Edit` tool call.

**What it does:** Enforces project conventions by inspecting the target file path:

| Rule | Trigger | Action | Message |
|------|---------|--------|---------|
| `.claude-plugin/` guard | Write/Edit to `.claude-plugin/*` (non-manifest) | `permissionDecision: "deny"` | Only manifests belong in `.claude-plugin/` |
| Hook chmod reminder | Write/Edit to `hooks/*.sh` | `systemMessage` reminder | Remember: `chmod +x`, correct shebang, run `test-gate.sh` |
| Version sync reminder | Write/Edit to `.claude-plugin/plugin.json` or `marketplace.json` | `systemMessage` reminder | Also bump the paired manifest version |

Returns supported JSON:
- `permissionDecision: "deny"` for blocked writes into `.claude-plugin/`
- `systemMessage` reminders for hook script edits and manifest version sync

---

## PostToolUse — `context-monitor.sh`

**When it fires:** After every tool call.

**What it does:** Reads a bridge file written by `statusline.js` at
`/tmp/claude-ctx-<session_id>.json` and injects a context warning via JSON `additionalContext`
if the context window is running low. The bridge file is ignored if it is more than 60 seconds
old (stale statusline data is silently skipped).

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

**What it does:** Injects the current pipeline state as JSON `additionalContext` so the
compacted summary preserves it. Without this, compaction could discard awareness of which
pipeline phase is active and which artifacts exist.

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
the `timeout` command is absent). If at least one snapshot succeeds, it writes a
`repomix-pack.json` manifest with the available variants, timestamps, and file sizes.

**Skip conditions:** exits silently when:
- `repomix` is not installed
- no active `.pipeline/` project is found
- `CLAUDE.md` contains `session-end-pack: disabled`

**Opt-out:** Add `session-end-pack: disabled` to your project's CLAUDE.md.

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
| `_json_quote <value>` | string | Emit a safely quoted JSON string |
| `_emit_block_decision <reason>` | string | Emit a `UserPromptSubmit` block decision |
| `_emit_system_message <message>` | string | Emit a hook `systemMessage` |
| `_emit_additional_context <event> <context>` | strings | Emit hook `additionalContext` |
| `_emit_pretool_permission <decision> <reason>` | strings | Emit `PreToolUse` permission control |

Prefers `jq`, falls back to `python3`. Supports nested fields via dot notation.

---

## Summary

| Hook | Event | Type | Scope |
|------|-------|------|-------|
| `session-start-check.sh` | `SessionStart` | command | Warns on missing tools and maintains a plugin-managed statusline symlink |
| `pipeline-gate.sh` | `UserPromptSubmit` | command | Enforces pipeline phase order for slash commands |
| `convention-guard.sh` | `PreToolUse` (Write\|Edit) | command | Enforces project conventions |
| `context-monitor.sh` | `PostToolUse` | command | Warns on high context usage |
| `compact-prep.sh` | `PreCompact` | command | Preserves pipeline state across compaction |
| `session-end-pack.sh` | `SessionEnd` | command | Generates Repomix snapshots |
