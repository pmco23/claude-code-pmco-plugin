# Trunk-Based Workflow Reference

## Branch Naming

Conventional Branch spec: https://conventional-branch.github.io/

Pattern: `<type>/<short-description>`

Types: `feat`, `feature`, `fix`, `bugfix`, `hotfix`, `chore`, `release`

Rules: lowercase, hyphens only, no underscores or spaces, max ~50 chars.

Examples: `feat/add-login-page`, `fix/null-pointer-crash`, `chore/update-deps`

## Commit Format

Conventional Commits spec: https://www.conventionalcommits.org/en/v1.0.0/

Pattern: `<type>[optional scope]: <description>`

Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `ci`, `build`, `perf`

Breaking changes: add `!` before the colon — e.g. `feat!: remove legacy API`

Examples:
- `feat: add user authentication`
- `fix(auth): handle token expiry correctly`
- `docs: update installation instructions`

## PR Strategy

- Branch from: `main`
- Merge target: `main`
- One PR per logical change
- PR title must follow commit format

## Protected Branches

Direct push is blocked on:
- `main`
- `master`

Use a PR for all changes to protected branches.

## Promotion Flow

```
feature branch → PR review → merge to main
```
