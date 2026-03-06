# Troubleshooting

## "No brief found. Run /brief first"

You tried to run `/design` without a brief. Run `/brief` first.

## "Design not approved. Run /review and iterate until all findings resolve."

You tried to run `/plan` without going through `/review`. Run `/review` and iterate until the review loop resolves.

## Gate is not firing (hook not active)

1. Verify the plugin is installed: in Claude Code, run `/plugin list` and confirm `claude-developer-toolbox@pmco23-tools` appears.
2. Restart Claude Code — hooks are loaded at startup.
3. Check that `hooks/pipeline-gate.sh` is executable: `ls -la ~/claude-developer-toolbox/hooks/`
4. Check `hooks/hooks.json` is valid: `python3 -m json.tool ~/claude-developer-toolbox/hooks/hooks.json`

## Resetting pipeline state

```bash
# Full reset
rm -rf .pipeline/

# Partial reset — see docs/guides/workflows.md#resetting-to-a-prior-phase
```

## Verifying gate logic

Run `hooks/test-gate.sh` to confirm all pipeline gate rules are working correctly:

```bash
bash ~/claude-developer-toolbox/hooks/test-gate.sh
```

Expected: `Results: 52 passed, 0 failed`

## Plugin not loading after changes

```bash
/plugin uninstall claude-developer-toolbox@pmco23-tools
/plugin install claude-developer-toolbox@pmco23-tools
# Restart Claude Code
```
