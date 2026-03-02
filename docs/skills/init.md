# /init — Project Boilerplate

**Gate:** None (always available)
**Writes:** `README.md`, `CHANGELOG.md`, `CONTRIBUTING.md`, `.github/pull_request_template.md`
**Model:** Sonnet

Scaffolds best-practice project boilerplate adapted to the current project. Extracts context from `package.json`, `go.mod`, `requirements.txt`, `*.csproj`, `.git/config`, and existing files. Falls back to clearly marked placeholders (`[DESCRIPTION]`, `[AUTHOR]`, etc.) for anything it can't detect.

Asks before touching any file that already exists: **Overwrite / Skip / Merge**. Merge shows a diff before writing.

## Usage

```
/init
```

## Past context

Before scaffolding, `/init` searches past conversations for the project name using `episodic-memory`. Found results are displayed visibly and carried forward.

## Generated files

| File | Standard |
|------|---------|
| `README.md` | Title, description, install (language-aware), usage, contributing, license |
| `CHANGELOG.md` | [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format |
| `CONTRIBUTING.md` | Branching ([Conventional Branch](https://conventional-branch.github.io/)), commits ([Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)), PR process |
| `.github/pull_request_template.md` | Type of change, testing checklist, verification evidence, spec compliance checklist |
