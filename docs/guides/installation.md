# Installation

## Prerequisites

### Required

**Context7** — provides live library documentation grounding used by `/design` and `/review`. Install once globally:

```
/plugin install context7@claude-plugins-official
```

### Recommended

**`repomix`** — required for `/pack` and `/qa` codebase snapshots. Install via npm:

```bash
npm install -g repomix
```

**`jq`** — used by the gate hook and context monitor for JSON parsing. Falls back to `python3` if absent, but `jq` is faster and more reliable:

```bash
# macOS
brew install jq

# Debian/Ubuntu
apt install jq
```

`python3` — fallback if `jq` is absent. Almost universally available; no install step needed.

> The plugin's SessionStart hook will warn at startup about any missing tools it detects. Missing tools degrade specific features — they do not break the pipeline.

---

## Step 0: Add the marketplace

Inside a Claude Code session:

```
/plugin marketplace add pmco23/claude-developer-toolbox
```

For local development, clone the repo first and add it by path instead:

```bash
git clone https://github.com/pmco23/claude-developer-toolbox.git ~/claude-developer-toolbox
```

```
/plugin marketplace add ~/claude-developer-toolbox
```

## Step 1: Install the plugin

```
/plugin install claude-developer-toolbox@pmco23-tools
```

## Step 3: Restart Claude Code

Quit and reopen. The skills will appear in the skill list and the gate hook will be active.

## Step 4: Verify installation

```bash
# In a Claude Code session:
/brief
```

You should see the brief skill start a Q&A session. If the gate hook is active, trying `/design` before running `/brief` will show a block message.

Core workflow and safety skills are explicit slash-command entrypoints. If you
describe work in natural language and Claude does not auto-enter `/brief`,
`/build`, or `/qa`, that is expected — run the slash command directly.

If the current runtime does not expose structured picker prompts, interactive
skills fall back to plain-text questions with the same choices.

## Statusline Setup

The statusline shows model, current task, pipeline phase, directory, and context usage in the Claude Code status bar.

Add this to `~/.claude/settings.json` (one-time global setup):

```json
"statusLine": {
  "type": "command",
  "command": "node ~/.claude/statusline.js"
}
```

The `SessionStart` hook automatically creates and maintains a symlink at
`~/.claude/statusline.js` pointing to the plugin's script only when:
- no `~/.claude/statusline.js` exists yet, or
- the existing file is already a symlink managed by this plugin

This safeguard prevents the plugin from overwriting a custom statusline or
another plugin's statusline.

To create the symlink immediately without waiting for the first session start, run once:

```bash
ln -sf /path/to/plugin/hooks/statusline.js ~/.claude/statusline.js
```

If you already have a custom statusline and want this plugin to take over,
replace it manually with the symlink above.

Restart Claude Code. The statusline will appear immediately.

**Example output:**

```
claude-sonnet-4-6 │ Implementing auth │ plan ready │ my-project ████░░░░░░ 42%
```

The context bar turns yellow above 63%, orange above 81%, and red-blinking with 💀 above 95%. A PostToolUse hook also injects context warnings directly into Claude's context when thresholds are exceeded.

## Reinstalling after changes

```bash
/plugin uninstall claude-developer-toolbox@pmco23-tools
/plugin install claude-developer-toolbox@pmco23-tools
# Restart Claude Code
```
