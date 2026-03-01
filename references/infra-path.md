# Three-Environment Workflow Reference

## Branch Naming

Conventional Branch spec: https://conventional-branch.github.io/

Pattern: `<type>/<short-description>`

Types: `feat`, `feature`, `fix`, `bugfix`, `hotfix`, `chore`, `release`

Rules: lowercase, hyphens only, no underscores or spaces, max ~50 chars.

Examples: `feat/add-login-page`, `fix/null-pointer-crash`

## Commit Format

Conventional Commits spec: https://www.conventionalcommits.org/en/v1.0.0/

Pattern: `<type>[optional scope]: <description>`

Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `ci`, `build`, `perf`

Breaking changes: add `!` before the colon — e.g. `feat!: remove legacy API`

## PR Strategy

- Branch from: `development` (never directly from `preproduction` or `main`)
- Merge target: `development`
- Promotion is strictly sequential — never skip an environment
- Each promotion requires a PR and review

## Protected Branches

Direct push is blocked on all of:
- `main`
- `master`
- `development`
- `preproduction`

## Promotion Flow

```
feature branch → PR → development → PR → preproduction → PR → main
```

If the promotion path for a branch is unclear, escalate — do not guess.
