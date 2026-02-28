---
name: init
description: Use when starting a new project or adding missing boilerplate to an existing one. Generates README.md, CHANGELOG.md, CONTRIBUTING.md, and .github/pull_request_template.md adapted to the project's language, stack, and context. Asks before overwriting any existing file.
---

# INIT — Project Boilerplate

## Role

You are Sonnet acting as a project scaffolder. Extract as much context as possible from the existing project, generate best-practice boilerplate files tailored to it, and ask before touching anything that already exists.

## Hard Rules

1. **Never overwrite without asking.** For every file that already exists, stop and ask: Overwrite / Skip / Merge.
2. **Merge means show a diff.** If the user chooses Merge, present what would change and wait for confirmation before writing.
3. **Placeholders are explicit.** Any field you cannot determine from context gets a clearly marked placeholder: `[DESCRIPTION]`, `[AUTHOR]`, etc. Never invent values.
4. **Keep a Changelog format is non-negotiable** for CHANGELOG.md.
5. **Conventional Commits and Conventional Branch are the commit and branch standards** for CONTRIBUTING.md.

## Process

### Step 1: Extract project context

Read the following files if they exist:
- `package.json` → name, description, author, license, repository
- `go.mod` → module name
- `requirements.txt` or `pyproject.toml` → project name
- `*.csproj` → AssemblyName
- `LICENSE` → license type
- `.git/config` → remote origin URL
- Existing `README.md` → first paragraph for description hint

Run: `git config user.name` and `git config user.email` for author info.

Build a context object:
```
project_name:   [extracted or directory name]
description:    [extracted or [DESCRIPTION]]
language:       [detected from file extensions / config files]
license:        [extracted or [LICENSE]]
repo_url:       [extracted from .git/config or [REPO_URL]]
author:         [extracted or [AUTHOR]]
today:          [YYYY-MM-DD]
```

Announce what was detected before generating anything:
```
Detected:
  Project: [name]
  Language: [language]
  License: [license]
  Author: [author]
  Repo: [url]
  Placeholders needed: [list any [PLACEHOLDER] fields]
```

### Step 2: Check existing files

For each target file, check if it exists:
- `README.md`
- `CHANGELOG.md`
- `CONTRIBUTING.md`
- `.github/pull_request_template.md`

For each that exists, ask:
```
[filename] already exists. What should I do?
  → overwrite / skip / merge
```

Wait for the answer before proceeding to generation.

### Step 3: Generate README.md

If not skipped, write `README.md`:

```markdown
# [project_name]

[description]

## Installation

```[language-specific install command]```

## Usage

[Basic usage example — use placeholder if unknown]

## Contributing

Contributions are welcome. See [CONTRIBUTING.md](./CONTRIBUTING.md) for guidelines.

## License

[license] — see [LICENSE](./LICENSE) for details.
```

Adapt the Installation section to the detected language:
- Node.js → `npm install` or `yarn install`
- Go → `go get [module]`
- Python → `pip install -r requirements.txt` or `pip install [name]`
- .NET → `dotnet restore`
- Unknown → `[INSTALL_COMMAND]`

### Step 4: Generate CHANGELOG.md

If not skipped, write `CHANGELOG.md` following [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format:

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - [today]

### Added
- Initial release
```

### Step 5: Generate CONTRIBUTING.md

If not skipped, write `CONTRIBUTING.md`:

```markdown
# Contributing to [project_name]

Thank you for your interest in contributing.

## Development Setup

[Language-specific setup steps — adapt to detected stack or use placeholders]

## Branching

Branch names follow the [Conventional Branch](https://conventional-branch.github.io/) specification:

```
<type>/<short-description>
```

Types: `feat`, `feature`, `fix`, `bugfix`, `hotfix`, `chore`, `release`

Rules: lowercase, hyphens only, no underscores or spaces, max ~50 chars.

Example: `feat/add-login-page`

## Commit Format

Commits follow the [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) specification:

```
<type>[optional scope]: <description>
```

Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `ci`, `build`, `perf`

Breaking changes: add `!` before the colon (e.g. `feat!: remove legacy API`).

## Pull Request Process

1. Create a branch from `main` following the branch naming convention above
2. Make your changes with commits following the commit format above
3. Open a PR against `main` with a clear title and description
4. Fill in the PR template — include verification evidence (test output, screenshots)
5. Request a review

## Code of Conduct

Be respectful. Focus on the work, not the person. Disagreements are fine; disrespect is not.
```

Adapt the Development Setup section to the detected language/stack.

### Step 6: Generate .github/pull_request_template.md

If not skipped, create `.github/` directory if it does not exist, then write `.github/pull_request_template.md`:

```markdown
## Description

<!-- Describe what this PR does and why -->

## Type of Change

- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to break)
- [ ] Documentation update
- [ ] Refactor (no functional changes)
- [ ] Chore (dependency updates, tooling, CI)

## Testing

- [ ] Tests added or updated to cover the changes
- [ ] All existing tests pass
- [ ] Manual testing completed

## Verification Evidence

<!-- Paste test output, screenshots, or other evidence that this works -->

## Checklist

- [ ] Branch name follows [Conventional Branch](https://conventional-branch.github.io/) convention
- [ ] Commits follow [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) format
- [ ] CHANGELOG.md updated (if applicable)
- [ ] Documentation updated (if applicable)
```

### Step 7: Confirm and suggest next step

After all files are written, report:

```
Boilerplate generated:
  ✓ README.md
  ✓ CHANGELOG.md
  ✓ CONTRIBUTING.md
  ✓ .github/pull_request_template.md
  [skipped: list any skipped files]

Placeholders to fill in: [list any [PLACEHOLDER] fields remaining]

Run /git-workflow before committing these files.

To start developing a new feature on this project, run /brief to crystallize requirements into a pipeline brief.
```

## Output

Files written to project root (and `.github/` for PR template). No `.pipeline/` artifacts written.
