# Troubleshooting

## "No brief found. Run /brief first"

You tried to run `/design` without a brief. Run `/brief` first.

## "Design not approved. Run /review and iterate until all findings resolve."

You tried to run `/plan` without going through `/review`. Run `/review` and iterate until the review loop resolves.

## Gate is not firing (hook not active)

1. Verify the plugin is installed: in Claude Code, run `/plugin list` and confirm `claude-developer-toolbox@local-dev` appears.
2. Restart Claude Code — hooks are loaded at startup.
3. Check that `hooks/pipeline_gate.sh` is executable: `ls -la ~/claude-developer-toolbox/hooks/`
4. Check `hooks/hooks.json` is valid: `python3 -m json.tool ~/claude-developer-toolbox/hooks/hooks.json`

## Codex MCP not connecting

1. Run `which codex` — if not found, install with `npm install -g @openai/codex`.
2. Run `claude` and check the startup output for MCP connection errors.
3. If installed via nvm, replace `"command": "codex"` with the absolute path in `~/.claude/settings.json` (see [Codex MCP setup](mcp-setup.md#codex-mcp)).

## Resetting pipeline state

```bash
# Full reset
rm -rf .pipeline/

# Partial reset — see docs/guides/workflows.md#resetting-to-a-prior-phase
```

## Verifying gate logic

Run `hooks/test_gate.sh` to confirm all pipeline gate rules are working correctly:

```bash
bash ~/claude-developer-toolbox/hooks/test_gate.sh
```

Expected: `Results: 49 passed, 0 failed`

## Plugin not loading after changes

```bash
/plugin uninstall claude-developer-toolbox@local-dev
/plugin install claude-developer-toolbox@local-dev
# Restart Claude Code
```
