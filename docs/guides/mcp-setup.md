# MCP Setup

MCP registration for Repomix is handled automatically by the plugin. You only need to install the binary.

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
