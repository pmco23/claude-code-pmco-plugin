# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.3.0] - 2026-03-01

### Added

- `/pack` skill — Repomix codebase snapshot with `.pipeline/repomix-pack.json` state
- `/plugin-architecture` skill — agents vs skills decision guide
- `docs/guides/agents-vs-skills.md` — full evaluation table and composition patterns
- Model advisories on Opus-targeted skills (`/brief`, `/design`, `/plan`, `/build`, `/drift-check`)
- Repomix MCP integration: `/qa` preamble, `/plan` Step 2, `/brief` Step 1, 5 audit skills
- CHANGELOG.md (this file)
- `.gitignore`

### Fixed

- PostToolUse hook matcher narrowed from `"*"` to `"Bash|Agent|Task"` (was firing on every tool call)
- Codex MCP verification step in README corrected (`/status` does not list tools)
- `/quick` LSP diagnostics wording fixed — cannot distinguish new from pre-existing issues
- `/plan` Step 2 now uses `pack_codebase` for accurate file-tree grounding
- `statusline.js` pipeline phase detection now walks up directories (mirrors `pipeline_gate.sh`)
- `pipeline_gate.sh` and `context-monitor.sh` now prefer `jq`, fall back to `python3`
- README prerequisites updated to include Repomix MCP
- Statusline setup section now notes path portability

## [1.0.0] - 2026-02-28

### Added

- Initial release: quality-gated development pipeline (`/brief` → `/design` → `/review` → `/plan` → `/build` → `/qa`)
- `pipeline_gate.sh` PreToolUse hook enforcing phase progression with `.pipeline/` walk-up search
- `statusline.js` showing model, task, pipeline phase, directory, and context usage
- `context-monitor.sh` injecting context warnings at 63%, 81%, and 95% thresholds
- `/quick` fast-track implementation with optional lightweight audit
- `/init` project boilerplate scaffolding (README, CHANGELOG, CONTRIBUTING, PR template)
- `/git-workflow` for branching discipline (code-path and infra-path variants)
- `/drift-check` for design-to-build verification (Sonnet + Codex + Opus lead)
- `/status` pipeline state reporter
- Language support matrix: TypeScript, Go, Python, C# LSP integrations
- `hooks/test_gate.sh` — gate scenario regression tests
