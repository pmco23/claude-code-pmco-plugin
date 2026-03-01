# Statusline Hook Design

**Date:** 2026-02-28
**Goal:** Add a Claude Code statusline hook adapted from GSD, showing model, current task, pipeline phase, directory, and context usage.

## Source

Adapted from: https://github.com/gsd-build/get-shit-done/blob/main/hooks/gsd-statusline.js

Strips: GSD update-available check.
Adds: pipeline phase detection from `.pipeline/` artifacts.

## Output Format

```
claude-sonnet-4-6 │ Exploring codebase │ plan ready │ my-project ████░░░░░░ 42%
[model dim]         [task bold, if any]  [phase dim]   [dir dim]  [ctx bar colored]
```

Segments separated by ` │ `. Task segment omitted when no todo is `in_progress`. Phase segment omitted when no `.pipeline/` directory exists in `cwd`.

## Pipeline Phase Detection

Checked in order against `{cwd}/.pipeline/`:

| Artifact present | Label |
|---|---|
| `build.complete` | `qa ready` |
| `plan.md` | `plan ready` |
| `design.approved` | `design approved` |
| `design.md` | `design` |
| `brief.md` | `brief` |
| nothing | *(segment omitted)* |

## Context Bar

10-segment block progress bar. Real usage scaled: 80% real = 100% displayed (matching Claude Code's 80% compaction limit).

Color thresholds (scaled %):
- < 63%: green
- 63–80%: yellow
- 81–95%: orange (`\x1b[38;5;208m`)
- > 95%: red blinking (`\x1b[5;31m`) with 💀

## Files

| File | Description |
|---|---|
| `hooks/statusline.js` | Node.js statusline script |
| `hooks/context-monitor.sh` | Bash PostToolUse hook — reads bridge file, warns Claude when context is high |
| `hooks/hooks.json` | Add `PostToolUse` matcher for `context-monitor.sh` |
| `README.md` | Add statusline setup section |

## Context Bridge

`statusline.js` writes to `/tmp/claude-ctx-{session_id}.json`:

```json
{
  "session_id": "...",
  "remaining_percentage": ...,
  "used_pct": ...,
  "timestamp": ...
}
```

`context-monitor.sh` reads this file on every PostToolUse event and prints a warning if thresholds are exceeded:

| Scaled usage | Output |
|---|---|
| < 63% | Silent |
| 63–80% | `⚠ Context at X% — consider /compact soon` |
| 81–95% | `⚠ Context at X% — /compact recommended` |
| > 95% | `💀 Context critical (X%) — /compact now` |

## Registration

**Statusline** — user adds once to `~/.claude/settings.json`:

```json
"statusline": {
  "command": "node ~/claude-agents-custom/hooks/statusline.js"
}
```

**Context monitor** — automatic via `hooks/hooks.json` `PostToolUse` entry (same mechanism as `pipeline_gate.sh`).

## Constraints

- Node.js required for `statusline.js` (v22 confirmed available)
- `context-monitor.sh` must be `chmod +x`
- Silent fail on all file-system errors — never break the statusline
- Bridge file is best-effort; missing bridge = no context warnings, not an error
