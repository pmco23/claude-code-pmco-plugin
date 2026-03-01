# Design: Bundle Repomix and Codex MCP Servers into Plugin

**Date:** 2026-03-01
**Feature:** Declare Repomix and Codex as plugin MCP servers so registration is automatic on install

## Context

Both Repomix and Codex currently require two manual steps: install the binary (`npm install -g`) and register the MCP server (`claude mcp add --scope user ...`). The plugin can eliminate the second step entirely by declaring MCP servers in `plugin.json` — Claude Code registers them automatically when the plugin is installed.

## Design

### Change 1: Add `mcpServers` to `.claude-plugin/plugin.json`

```json
"mcpServers": {
  "codex": {
    "command": "codex",
    "args": ["mcp-server"]
  },
  "repomix": {
    "command": "repomix",
    "args": ["--mcp"]
  }
}
```

Both servers use the globally installed binary (no local files). Users still need the binaries installed — the plugin handles registration only.

### Change 2: Simplify Codex MCP Setup section in README

Remove the "Register the MCP server" step and the "Verify" step. Keep:
- **Install step** — `npm install -g @openai/codex`
- **Troubleshooting** — nvm PATH issue with absolute path fix

### Change 3: Simplify Repomix MCP Setup section in README

Remove the "Register the MCP server" step and the "Verify" step. Keep:
- **Install step** — `npm install -g repomix`
- **Troubleshooting** — (if any; mirror Codex pattern)

Add a note to both sections: "MCP registration is handled automatically by the plugin."

## Files Affected

- `.claude-plugin/plugin.json` — add `mcpServers` block
- `README.md` — simplify both MCP setup sections
