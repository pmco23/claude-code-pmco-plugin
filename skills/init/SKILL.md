---
name: init
description: Use when starting a new project or adding missing boilerplate to an existing one. Generates CLAUDE.md, README.md, CHANGELOG.md, CONTRIBUTING.md, and .github/pull_request_template.md adapted to the project's language, stack, and context. Asks before overwriting any existing file.
disable-model-invocation: true
---

# INIT — Project Boilerplate

## Role

> **Model:** Sonnet (`claude-sonnet-4-6`).

You are Sonnet acting as a project scaffolder. Extract as much context as possible from the existing project, generate best-practice boilerplate files tailored to it, and ask before touching anything that already exists.

## Hard Rules

1. **Never overwrite without asking.** For every file that already exists, stop and ask: Overwrite / Skip / Merge.
2. **Merge means show a diff.** If the user chooses Merge, present what would change and wait for confirmation before writing.
3. **Placeholders are explicit.** Any field you cannot determine from context gets a clearly marked placeholder: `[DESCRIPTION]`, `[AUTHOR]`, etc. Never invent values.
4. **Keep a Changelog format is non-negotiable** for CHANGELOG.md.
5. **Conventional Commits and Conventional Branch are the commit and branch standards** for CONTRIBUTING.md.
6. **Empty projects get asked, not assumed.** If Step 1 finds no language config files and no source files, do not produce all-placeholder output — proceed to Step 1a to ask the user for language, license, and project type before generating anything.

## Process

### Step 0: Check session memory for project context

Review MEMORY.md (auto-loaded). If relevant entries exist for this project, announce them briefly and carry them forward. If none, proceed silently.

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

**Empty project detection:** If `language` could not be determined (no config files found at root and no source files detected), the project is empty — skip the announcement below and proceed to **Step 1a** instead.

Otherwise, announce what was detected before generating anything:
```
Detected:
  Project: [name]
  Language: [language]
  License: [license]
  Author: [author]
  Repo: [url]
  Placeholders needed: [list any [PLACEHOLDER] fields]
```

Then proceed to Step 2.

### Step 1a: Gather context from user (empty project)

Read `references/empty-project-questions.md` from this skill's base directory. Follow it exactly — three questions, one per turn, then update the context object and announce before proceeding to Step 2.

### Step 2: Check existing files

For each target file, check if it exists:
- `CLAUDE.md`
- `README.md`
- `CHANGELOG.md`
- `CONTRIBUTING.md`
- `.github/pull_request_template.md`
- `.gitignore`

For each that exists, prefer AskUserQuestion with:
  question: "[filename] already exists. What should I do?"
  header: "File conflict"
  options:
    - label: "Skip"
      description: "Leave the existing file unchanged"
    - label: "Overwrite"
      description: "Replace the entire file with generated content"
    - label: "Merge"
      description: "Show a diff of what would change and confirm before writing"

If structured prompts are unavailable in this runtime, ask the same question in plain text and continue with the user's answer.

For `.gitignore` specifically, "merge" means: append `.pipeline/` if not already present. Do not overwrite existing entries.

Wait for the answer before proceeding to generation.

### Steps 3–6: Generate files

Read `references/file-specs.md` from this skill's base directory. Follow the generation spec for each file not skipped. Confirm to the user after each: "[filename] written."

### Step 7: Confirm and suggest next step

After all files are written, output the completion report from `references/file-specs.md`.

## Output

Files written to project root (and `.github/` for PR template). No `.pipeline/` artifacts written.
