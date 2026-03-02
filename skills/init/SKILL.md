---
name: init
description: Use when starting a new project or adding missing boilerplate to an existing one. Generates README.md, CHANGELOG.md, CONTRIBUTING.md, and .github/pull_request_template.md adapted to the project's language, stack, and context. Asks before overwriting any existing file.
---

# INIT — Project Boilerplate

## Role

> **Model:** Sonnet (`claude-sonnet-4-6`). If running on Haiku, output quality may be reduced for tasks requiring judgment.

You are Sonnet acting as a project scaffolder. Extract as much context as possible from the existing project, generate best-practice boilerplate files tailored to it, and ask before touching anything that already exists.

## Hard Rules

1. **Never overwrite without asking.** For every file that already exists, stop and ask: Overwrite / Skip / Merge.
2. **Merge means show a diff.** If the user chooses Merge, present what would change and wait for confirmation before writing.
3. **Placeholders are explicit.** Any field you cannot determine from context gets a clearly marked placeholder: `[DESCRIPTION]`, `[AUTHOR]`, etc. Never invent values.
4. **Keep a Changelog format is non-negotiable** for CHANGELOG.md.
5. **Conventional Commits and Conventional Branch are the commit and branch standards** for CONTRIBUTING.md.

## Process

### Step 0: Search past conversations for project context

Call `mcp__plugin_episodic-memory_episodic-memory__search` with the project name (use the current directory name as the query).

Use `mode: "both"` and `limit: 3`.

**If relevant results are found**, display them visibly before proceeding:

```
Checking past conversations for context on this project...

Found N relevant conversation(s):
  · [YYYY-MM-DD · project-name] "snippet..."

Carrying these forward into project scaffolding.
```

**If no relevant results**, proceed silently to Step 1 with no output.

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

### Steps 3–6: Generate files

For each file not skipped, generate content appropriate for the detected project. Apply these non-negotiable constraints:

**README.md:**
- Sections: project name, description, installation (language-appropriate command), usage, contributing, license
- Installation command must match detected language (npm install / go get / pip install / dotnet restore / [INSTALL_COMMAND])
- Use `[PLACEHOLDER]` for any field that cannot be detected from project context — never invent values

**CHANGELOG.md:**
- Must follow [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format exactly
- Must follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html)
- Include `## [Unreleased]` section and an initial `## [0.1.0] - [today]` entry with `### Added\n- Initial release`

**CONTRIBUTING.md:**
- Branching: [Conventional Branch](https://conventional-branch.github.io/) — `<type>/<short-description>`, types: feat/feature/fix/bugfix/hotfix/chore/release
- Commits: [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) — `<type>[scope]: <description>`
- PR process: branch from main, PR against main, fill PR template, request review
- Development setup: adapt to detected language/stack, or use `[SETUP_STEPS]` placeholder

**.github/pull_request_template.md:**
- Sections: Description, Type of Change (checklist), Testing (checklist), Verification Evidence, Checklist (branch name, commit format, CHANGELOG, docs)
- Type of Change checkboxes: Bug fix, New feature, Breaking change, Documentation, Refactor, Chore
- Testing checkboxes: Tests added/updated, All tests pass, Manual testing

Generate each file, write it, confirm to the user: "[filename] written."

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
