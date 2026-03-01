# Statusline Hook Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a Claude Code statusline hook showing model, current task, pipeline phase, directory, and context bar — adapted from the GSD statusline hook.

**Architecture:** Four independent files: `statusline.js` (Node.js display script), `context-monitor.sh` (Bash PostToolUse hook that warns Claude when context is high), `hooks.json` update to register the monitor, and a README section for one-time user setup of the statusline command.

**Tech Stack:** Node.js v22 (statusline), Bash + Python3 (context monitor), JSON (hooks config)

---

### Task 1: Create `hooks/statusline.js`

**Files:**
- Create: `hooks/statusline.js`

**Step 1: Write the script**

Create `hooks/statusline.js` with this exact content:

```javascript
#!/usr/bin/env node
// Claude Code Statusline — claude-agents-custom edition
// Shows: model | current task | pipeline phase | directory | context usage
// Adapted from https://github.com/gsd-build/get-shit-done/blob/main/hooks/gsd-statusline.js

const fs = require('fs');
const path = require('path');
const os = require('os');

let input = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => input += chunk);
process.stdin.on('end', () => {
  try {
    const data = JSON.parse(input);
    const model = data.model?.display_name || 'Claude';
    const dir = data.workspace?.current_dir || process.cwd();
    const session = data.session_id || '';
    const remaining = data.context_window?.remaining_percentage;

    // Context window display (scaled: 80% real usage = 100% displayed)
    let ctx = '';
    if (remaining != null) {
      const rem = Math.round(remaining);
      const rawUsed = Math.max(0, Math.min(100, 100 - rem));
      const used = Math.min(100, Math.round((rawUsed / 80) * 100));

      // Write bridge file for context-monitor.sh
      if (session) {
        try {
          const bridgePath = path.join(os.tmpdir(), `claude-ctx-${session}.json`);
          fs.writeFileSync(bridgePath, JSON.stringify({
            session_id: session,
            remaining_percentage: remaining,
            used_pct: used,
            timestamp: Math.floor(Date.now() / 1000)
          }));
        } catch (e) {
          // Silent fail — bridge is best-effort
        }
      }

      // Progress bar (10 segments)
      const filled = Math.floor(used / 10);
      const bar = '█'.repeat(filled) + '░'.repeat(10 - filled);

      if (used < 63) {
        ctx = ` \x1b[32m${bar} ${used}%\x1b[0m`;
      } else if (used < 81) {
        ctx = ` \x1b[33m${bar} ${used}%\x1b[0m`;
      } else if (used < 95) {
        ctx = ` \x1b[38;5;208m${bar} ${used}%\x1b[0m`;
      } else {
        ctx = ` \x1b[5;31m\u{1F480} ${bar} ${used}%\x1b[0m`;
      }
    }

    // Current in-progress task from todos
    let task = '';
    const todosDir = path.join(os.homedir(), '.claude', 'todos');
    if (session && fs.existsSync(todosDir)) {
      try {
        const files = fs.readdirSync(todosDir)
          .filter(f => f.startsWith(session) && f.includes('-agent-') && f.endsWith('.json'))
          .map(f => ({ name: f, mtime: fs.statSync(path.join(todosDir, f)).mtime }))
          .sort((a, b) => b.mtime - a.mtime);

        if (files.length > 0) {
          const todos = JSON.parse(fs.readFileSync(path.join(todosDir, files[0].name), 'utf8'));
          const inProgress = todos.find(t => t.status === 'in_progress');
          if (inProgress) task = inProgress.activeForm || '';
        }
      } catch (e) {
        // Silent fail
      }
    }

    // Pipeline phase from .pipeline/ artifacts in cwd
    let phase = '';
    const pipelineDir = path.join(dir, '.pipeline');
    try {
      if (fs.existsSync(path.join(pipelineDir, 'build.complete'))) {
        phase = 'qa ready';
      } else if (fs.existsSync(path.join(pipelineDir, 'plan.md'))) {
        phase = 'plan ready';
      } else if (fs.existsSync(path.join(pipelineDir, 'design.approved'))) {
        phase = 'design approved';
      } else if (fs.existsSync(path.join(pipelineDir, 'design.md'))) {
        phase = 'design';
      } else if (fs.existsSync(path.join(pipelineDir, 'brief.md'))) {
        phase = 'brief';
      }
    } catch (e) {
      // Silent fail
    }

    // Assemble segments
    const parts = [`\x1b[2m${model}\x1b[0m`];
    if (task)  parts.push(`\x1b[1m${task}\x1b[0m`);
    if (phase) parts.push(`\x1b[2m${phase}\x1b[0m`);
    parts.push(`\x1b[2m${path.basename(dir)}\x1b[0m`);

    process.stdout.write(parts.join(' \u2502 ') + ctx);
  } catch (e) {
    // Silent fail — never break the statusline
  }
});
```

**Step 2: Verify the script produces output**

```bash
echo '{"model":{"display_name":"claude-sonnet-4-6"},"workspace":{"current_dir":"/tmp/test"},"session_id":"abc123","context_window":{"remaining_percentage":60}}' \
  | node hooks/statusline.js
```

Expected: a single line like `claude-sonnet-4-6 │ /tmp/test ████░░░░░░ 50%` (colors visible in terminal, no trailing newline, no error).

**Step 3: Verify pipeline phase appears**

```bash
mkdir -p /tmp/test-pipeline/.pipeline
touch /tmp/test-pipeline/.pipeline/plan.md

echo '{"model":{"display_name":"claude-sonnet-4-6"},"workspace":{"current_dir":"/tmp/test-pipeline"},"session_id":"abc123","context_window":{"remaining_percentage":60}}' \
  | node hooks/statusline.js
```

Expected: output contains `plan ready`.

**Step 4: Clean up test dirs**

```bash
rm -rf /tmp/test-pipeline
```

**Step 5: Commit**

```bash
git add hooks/statusline.js
git commit -m "feat: add statusline hook with pipeline phase and context bridge"
```

---

### Task 2: Create `hooks/context-monitor.sh`

**Files:**
- Create: `hooks/context-monitor.sh`

**Step 1: Write the script**

Create `hooks/context-monitor.sh` with this exact content:

```bash
#!/usr/bin/env bash
# PostToolUse hook — warns Claude when context window is running low.
# Reads the bridge file written by hooks/statusline.js.

set -euo pipefail

# Parse session_id from the PostToolUse JSON payload on stdin
INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | python3 -c \
  "import json,sys; d=json.load(sys.stdin); print(d.get('session_id',''))" \
  2>/dev/null || true)

[[ -z "$SESSION_ID" ]] && exit 0

BRIDGE_FILE="/tmp/claude-ctx-${SESSION_ID}.json"
[[ ! -f "$BRIDGE_FILE" ]] && exit 0

USED_PCT=$(python3 -c \
  "import json; d=json.load(open('${BRIDGE_FILE}')); print(d.get('used_pct',0))" \
  2>/dev/null || echo "0")

TIMESTAMP=$(python3 -c \
  "import json; d=json.load(open('${BRIDGE_FILE}')); print(d.get('timestamp',0))" \
  2>/dev/null || echo "0")

NOW=$(date +%s)
AGE=$(( NOW - TIMESTAMP ))

# Only warn if bridge file is fresh (updated within last 60 seconds)
(( AGE > 60 )) && exit 0

if (( USED_PCT >= 95 )); then
  echo "💀 Context critical (${USED_PCT}%) — /compact now"
elif (( USED_PCT >= 81 )); then
  echo "⚠ Context at ${USED_PCT}% — /compact recommended"
elif (( USED_PCT >= 63 )); then
  echo "⚠ Context at ${USED_PCT}% — consider /compact soon"
fi
```

**Step 2: Make it executable**

```bash
chmod +x hooks/context-monitor.sh
```

**Step 3: Verify with a mock bridge file**

```bash
# Write a fresh bridge file simulating 85% context used
python3 -c "
import json, time
print(json.dumps({'session_id':'test999','used_pct':85,'remaining_percentage':15,'timestamp':int(time.time())}))
" > /tmp/claude-ctx-test999.json

# Simulate a PostToolUse payload
echo '{"session_id":"test999","tool_name":"Read"}' | bash hooks/context-monitor.sh
```

Expected output: `⚠ Context at 85% — /compact recommended`

**Step 4: Verify silence below threshold**

```bash
python3 -c "
import json, time
print(json.dumps({'session_id':'test999','used_pct':40,'remaining_percentage':60,'timestamp':int(time.time())}))
" > /tmp/claude-ctx-test999.json

echo '{"session_id":"test999","tool_name":"Read"}' | bash hooks/context-monitor.sh
```

Expected: no output (exit 0).

**Step 5: Clean up**

```bash
rm -f /tmp/claude-ctx-test999.json
```

**Step 6: Commit**

```bash
git add hooks/context-monitor.sh
git commit -m "feat: add context-monitor PostToolUse hook"
```

---

### Task 3: Register context-monitor in `hooks/hooks.json`

**Files:**
- Modify: `hooks/hooks.json`

**Step 1: Read the current file**

Read `hooks/hooks.json`. Confirm it has only a `PreToolUse` entry.

**Step 2: Add the PostToolUse entry**

Replace the entire file with:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Skill",
        "hooks": [
          {
            "type": "command",
            "command": "\"${CLAUDE_PLUGIN_ROOT}/hooks/pipeline_gate.sh\""
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "\"${CLAUDE_PLUGIN_ROOT}/hooks/context-monitor.sh\""
          }
        ]
      }
    ]
  }
}
```

**Step 3: Verify JSON is valid**

```bash
python3 -m json.tool hooks/hooks.json > /dev/null && echo "valid JSON"
```

Expected: `valid JSON`

**Step 4: Commit**

```bash
git add hooks/hooks.json
git commit -m "feat: register context-monitor as PostToolUse hook"
```

---

### Task 4: Update README.md — Statusline Setup section

**Files:**
- Modify: `README.md`

**Step 1: Add Statusline Setup section**

Find the `## Installation` section in README.md. Insert a new `## Statusline Setup` section immediately after the Prerequisites section and before the Installation section. Add this content:

```markdown
## Statusline Setup

The statusline hook shows model, current task, pipeline phase, directory, and context usage in the Claude Code status bar.

Add this to `~/.claude/settings.json` (one-time global setup):

```json
"statusline": {
  "command": "node ~/claude-agents-custom/hooks/statusline.js"
}
```

Restart Claude Code. The statusline will appear immediately.

**Example output:**

```
claude-sonnet-4-6 │ Implementing auth │ plan ready │ my-project ████░░░░░░ 42%
```

The context bar turns yellow above 63%, orange above 81%, and red-blinking with 💀 above 95%. A PostToolUse hook also injects context warnings directly into Claude's context when thresholds are exceeded.
```

**Step 2: Verify the section was added correctly**

Read the README around the `## Prerequisites` and `## Installation` sections and confirm `## Statusline Setup` appears between them.

**Step 3: Commit**

```bash
git add README.md
git commit -m "docs: add Statusline Setup section to README"
```
