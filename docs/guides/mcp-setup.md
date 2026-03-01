# MCP Setup

MCP registration for all three servers is handled automatically by the plugin. You only need to install the binaries and (for Grafana) set environment variables.

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

## Grafana MCP

### Install uv

```bash
# macOS / Linux
brew install uv
# or
pip install uv
```

### Set environment variables

Add these to your shell profile (`.bashrc`, `.zshrc`, etc.):

```bash
export GRAFANA_URL=http://localhost:3000
export GRAFANA_SERVICE_ACCOUNT_TOKEN=<your-token>
```

Restart Claude Code after setting the variables so the MCP server picks them up.

### Troubleshooting — Grafana server not connecting

If `uvx` is not on PATH in non-interactive shells, fix by using the absolute path:

```bash
# Find the path
which uvx

# Edit ~/.claude/settings.json — replace "command": "uvx" with the absolute path
# under the mcpServers entry for your plugin installation path
```

If the MCP server starts but tools return auth errors, verify `GRAFANA_SERVICE_ACCOUNT_TOKEN` is exported (not just set) and that the token has the required Grafana permissions.
