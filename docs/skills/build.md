# /build — Parallel Build

**Gate:** `.pipeline/plan.md` must exist
**Writes:** `.pipeline/build.complete` (after /drift-check passes)
**Models:** Opus (lead) + `task-builder` agent (Sonnet, per task group)
**Flags:** `--parallel` | `--sequential`

Lead Opus coordinates and unblocks. Never writes implementation code. Runs /drift-check post-build. Writes `build.complete` only when /drift-check passes.

## Usage

```
/build --parallel     # Sonnets in independent agents, own context each
/build --sequential   # Task groups executed one at a time, current session
/build                # Prompts you to choose
```
