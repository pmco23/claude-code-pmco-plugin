# Init Skill Design

**Date:** 2026-02-28
**Status:** Approved

---

## Purpose

A `/init` skill that scaffolds project boilerplate files — README.md, CHANGELOG.md, CONTRIBUTING.md, and .github/pull_request_template.md — adapted to the current project's context.

---

## Skill

- **Name:** `/init`
- **Gate:** None — always available
- **Model:** Sonnet
- **Platform:** GitHub (PR template at `.github/pull_request_template.md`)

---

## Context Extraction

| Signal | Source | Fallback |
|--------|--------|---------|
| Project name | `package.json` name, `go.mod` module, `*.csproj` AssemblyName | directory name |
| Description | `package.json` description, first README paragraph | `[DESCRIPTION]` |
| Language/stack | file extensions, `package.json`, `go.mod`, `requirements.txt`, `*.csproj` | `[LANGUAGE]` |
| License | `LICENSE` file, `package.json` license | `[LICENSE]` |
| Repo URL | `.git/config` remote origin | `[REPO_URL]` |
| Author/org | `git config user.name`, `package.json` author | `[AUTHOR]` |

---

## File Content Standards

- **README.md** — title, description, installation, usage, contributing, license
- **CHANGELOG.md** — Keep a Changelog format (https://keepachangelog.com/en/1.1.0/)
- **CONTRIBUTING.md** — setup, branching (Conventional Branch), commits (Conventional Commits), PR process, code of conduct
- **`.github/pull_request_template.md`** — description, type of change checkboxes, testing checklist, verification evidence

---

## Existing File Behavior

Ask per file: Overwrite / Skip / Merge (merge shows diff and asks for confirmation).
