# Installation

## Step 1: Add the development marketplace

```bash
claude
/plugin marketplace add ~/claude-agents-custom
```

## Step 2: Install the plugin

```
/plugin install claude-agents-custom@local-dev
```

## Step 3: Restart Claude Code

Quit and reopen. The skills will appear in the skill list and the gate hook will be active.

## Step 4: Verify installation

```bash
# In a Claude Code session:
/brief
```

You should see the brief skill start a Q&A session. If the gate hook is active, trying `/design` before running `/brief` will show a block message.

## Statusline Setup

The statusline hook shows model, current task, pipeline phase, directory, and context usage in the Claude Code status bar.

Add this to `~/.claude/settings.json` (one-time global setup):

```json
"statusline": {
  "command": "node ~/claude-agents-custom/hooks/statusline.js"
}
```

> **Note:** Replace `~/claude-agents-custom` with your actual install path. Run `/plugin list` in a Claude Code session to see the installed path.

Restart Claude Code. The statusline will appear immediately.

**Example output:**

```
claude-sonnet-4-6 │ Implementing auth │ plan ready │ my-project ████░░░░░░ 42%
```

The context bar turns yellow above 63%, orange above 81%, and red-blinking with 💀 above 95%. A PostToolUse hook also injects context warnings directly into Claude's context when thresholds are exceeded.

## Reinstalling after changes

```bash
/plugin uninstall claude-agents-custom@local-dev
/plugin install claude-agents-custom@local-dev
# Restart Claude Code
```
