# MCP Setup

MCP registration for Codex and Repomix is handled automatically by the plugin. You only need to install the binaries.

## Episodic Memory Plugin

Episodic Memory is a separate plugin from the superpowers marketplace. It is not an MCP server — it is a Claude Code plugin that provides an MCP tool (`episodic-memory__search`) and a CLI used by the SessionStart hook.

### What it enables

- **Session start**: automatically syncs your last session and injects a "Recent Activity" block into MEMORY.md
- **`/brief` Step 0**: searches past conversations for the feature topic before Q&A
- **`/init` Step 0**: searches past conversations for project context before scaffolding

All three degrade gracefully if the plugin is absent — `/brief` and `/init` skip Step 0, and the session hook prints a warning but does not block.

### Install

```bash
# In a Claude Code session:
/plugin marketplace add superpowers-marketplace
/plugin install episodic-memory@superpowers-marketplace
```

Restart Claude Code after installing.

### Troubleshooting

If the session hook warns `episodic-memory not found` after installation, confirm the plugin installed correctly:

```bash
ls ~/.claude/plugins/cache/superpowers-marketplace/episodic-memory/
```

You should see a versioned directory (e.g., `1.0.0/`). If the directory is missing, reinstall the plugin.

## Codex MCP

### Install Codex CLI

```bash
npm install -g @openai/codex
```

### Troubleshooting — Codex server not connecting

If Codex was installed via nvm, the `codex` binary may not be on PATH in non-interactive shells. Fix by using the absolute path:

```bash
# Find the path
which codex

# Edit ~/.claude/settings.json — replace "command": "codex" with the absolute path
# under the mcpServers entry for your plugin installation path
```

## Repomix MCP

### Install Repomix

```bash
npm install -g repomix
```

### Troubleshooting — Repomix server not connecting

If Repomix was installed via nvm, the `repomix` binary may not be on PATH in non-interactive shells. Fix by using the absolute path:

```bash
# Find the path
which repomix

# Edit ~/.claude/settings.json — replace "command": "repomix" with the absolute path
# under the mcpServers entry for your plugin installation path
```
