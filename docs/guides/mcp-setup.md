# MCP Setup

MCP registration for both servers is handled automatically by the plugin. You only need to install the binaries.

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
