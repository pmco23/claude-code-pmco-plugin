# Troubleshooting

## "No brief found. Run /brief first"

You tried to run `/design` without a brief. Run `/brief` first.

## "Design not approved. Run /review and iterate until all findings resolve."

You tried to run `/plan` without going through `/review`. Run `/review` and iterate until the review loop resolves.

## "Claude didn't auto-run /brief, /build, or another workflow skill"

That is expected for the stateful slash workflows in this plugin. Core pipeline
and safety skills set `disable-model-invocation: true` so they only start when
you run the slash command explicitly.

Examples:
- `/brief`
- `/build`
- `/qa`
- `/git-workflow`
- `/rollback`

Run the command directly to enter the workflow.

## "I expected a picker, but Claude asked a plain-text question"

The current runtime does not expose structured prompts. The skills are designed
to fail soft: answer the question inline and the workflow will continue with the
same logic.

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

Run `hooks/test-gate.sh` to confirm the gate and hook JSON outputs are working correctly:

```bash
bash ~/claude-developer-toolbox/hooks/test-gate.sh
```

Expected: `Results: 62 passed, 0 failed`

## Statusline symlink did not update

The `SessionStart` hook will not overwrite a custom statusline or another
plugin's statusline. It only creates or refreshes `~/.claude/statusline.js`
when the file is missing or already points to `claude-developer-toolbox`.

If you want this plugin's statusline, replace it manually:

```bash
ln -sf /path/to/claude-developer-toolbox/hooks/statusline.js ~/.claude/statusline.js
```

## "Rollback blocked" safety checks

`/rollback` now stops rather than guessing when the worktree is unsafe.

Common causes:
- unrelated dirty files exist outside the selected rollback scope
- a modified file is not tracked by git
- a plan-derived path escapes the project root or targets a protected file

Fix the reported condition, then re-run `/rollback`.

## Plugin not loading after changes

```bash
/plugin uninstall claude-developer-toolbox@pmco23-tools
/plugin install claude-developer-toolbox@pmco23-tools
# Restart Claude Code
```
