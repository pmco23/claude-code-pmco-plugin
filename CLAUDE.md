# Project Conventions

Language: Bash (hooks), Markdown (skills/references/docs), JavaScript (statusline), JSON (config)
Test command: `bash hooks/test-gate.sh`
Lint command: none
Build command: none

Style config: hooks follow POSIX-compatible bash (`set -euo pipefail`). Skills follow the SKILL.md format defined in the plugin spec.

## Project structure

- `skills/<name>/SKILL.md` — skill definitions (loaded by Claude Code on invocation)
- `skills/<name>/references/` — progressive-disclosure content loaded by skills at specific steps
- `hooks/` — UserPromptSubmit/PreToolUse/PostToolUse/PreCompact/SessionStart/SessionEnd bash hooks
- `hooks/lib/` — sourceable shared libraries (no shebang, not executable)
- `hooks/test-gate.sh` — gate test suite (run before every commit)
- `.claude-plugin/plugin.json` — plugin manifest (version source of truth)
- `.claude-plugin/marketplace.json` — local dev marketplace manifest
- `docs/guides/` — user-facing documentation

## Editing rules

- Keep SKILL.md files concise. Extract inline templates, checklists, and procedures to `references/` for progressive disclosure.
- Never put skills, hooks, or other components inside `.claude-plugin/` — that directory contains only manifests.
- All hooks must be executable (`chmod +x`) and use `#!/usr/bin/env bash`.
- Run `bash hooks/test-gate.sh` after any change to hooks or gate logic. All tests must pass.
- Version is tracked in both `plugin.json` and `marketplace.json` — always bump both.

# Git Conventions

Branching: Conventional Branch — `<type>/<short-description>` (feat, fix, hotfix, chore, release)
Commits: Conventional Commits — `<type>[scope][!]: <description>` (feat, fix, docs, refactor, test, chore, ci, build, perf)
Merge strategy: squash-merge to main
Protected branches: never push directly to main or master — use a PR

# Plugin Configuration (claude-developer-toolbox)
# Uncomment a flag to enable it.
# tdd: disabled
# session-end-pack: disabled
