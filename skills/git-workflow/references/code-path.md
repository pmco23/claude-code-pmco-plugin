# Code Path (Trunk-Based)

This guide establishes standards for trunk-based development workflows using `main` as the primary branch.

## Branch Naming

Pattern: `<prefix>/<short-description>`

Approved prefixes: `feat`, `feature`, `fix`, `bugfix`, `hotfix`, `chore`, `release`

Requirements: lowercase only, hyphens only, no underscores, no spaces, max ~50 chars.

Example: `feat/add-login-page`

## Commit Format

Pattern: `<type>[scope][!]: <description>`

Valid types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `ci`, `build`, `perf`

Indicate breaking changes with `!` before the colon.

Example: `feat!: remove legacy API`

## Merge Strategy

Prefer squash-merge to `main`. Maintain short-lived feature branches (ideally under 2 days). When using GitHub CLI, apply `--merge-method squash` where possible.

## PR Standards

- Title: conveys the intended change
- Description: must include verification evidence (test outputs, screenshots, or equivalent)
