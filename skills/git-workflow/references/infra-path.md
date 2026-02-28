# Infra Path (Three-Environment)

**Sources:**
- Commit format: https://www.conventionalcommits.org/en/v1.0.0/
- Branch naming: https://conventional-branch.github.io/

This guide establishes workflows for infrastructure repositories using promoted environments.

## Branch Naming

Pattern: `<prefix>/<short-description>`

Approved prefixes: `feat`, `feature`, `fix`, `bugfix`, `hotfix`, `chore`, `release`

Requirements: lowercase only, hyphens only, no underscores, no spaces, max ~50 chars.

## Commit Format

Pattern: `<type>[scope][!]: <description>`

Valid types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `ci`, `build`, `perf`

Indicate breaking changes with `!` before the colon.

## Promotion Flow

Changes must progress through environments in a fixed sequence:

```
development → preproduction → main
```

Never skip environments. Submit separate pull requests for each promotion step. Each PR must document the target environment and include verification evidence specific to that environment.

## Hotfix Flow

1. Apply fix to `main` via branch and PR
2. Back-merge into `preproduction` via separate PR
3. Back-merge into `development` via separate PR

Escalate conflicts during back-merging — do not auto-resolve.

## PR Requirements

- Title: clarifies intent and target environment
- Body: must include validation evidence specific to that environment
