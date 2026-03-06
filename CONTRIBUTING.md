# Contributing

## Branching

Follow [Conventional Branch](https://conventional-branch.github.io/) — `<type>/<short-description>`.

Valid types: `feat`, `fix`, `chore`, `docs`, `refactor`, `release`

Examples: `feat/session-end-hook`, `fix/version-mismatch`, `docs/contributing-guide`

## Commits

Follow [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) — `<type>[scope]: <description>`.

Examples:
- `feat: add compact-prep hook`
- `fix: bump plugin.json version to 2.0.2`
- `docs: add CHANGELOG link to README`
- `chore: context-window optimization trim`

## Development Setup

```bash
# Clone
git clone https://github.com/pmco23/claude-developer-toolbox.git
cd claude-developer-toolbox

# Register as local plugin
# In a Claude Code session:
/plugin marketplace add ./
/plugin install claude-developer-toolbox@pmco23-tools
```

Restart Claude Code after install.

## Testing

Run the pipeline gate regression suite before any PR:

```bash
bash hooks/test-gate.sh
```

Expected: `Results: 52 passed, 0 failed`

## Pull Request Process

1. Branch from `main`
2. Make your changes
3. Run `bash hooks/test-gate.sh` — all 52 scenarios must pass
4. Update `CHANGELOG.md` under `## [Unreleased]`
5. Open PR against `main`

## Releases

Use the `/release` command inside Claude Code to cut releases. It bumps `plugin.json`, updates CHANGELOG, commits, and tags. Never push tags manually.
