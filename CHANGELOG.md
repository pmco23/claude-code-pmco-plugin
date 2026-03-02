# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.7.0] - 2026-03-02

### Added

- `docs/guides/workflows.md` — Fast Track vs Pipeline decision guide; explains named workflow paths, always-available skills (including `/drift-check`), and how agents work (internal, not user-invocable)
- `agents/strategic-critic.md` — named Opus agent for `/review` Agent 1; `model: opus` is now enforced at runtime, not advisory
- `agents/drift-verifier.md` — named Sonnet agent for `/drift-check` Agent 1; `model: sonnet` enforced at runtime
- `agents/task-builder.md` — named Sonnet agent for `/build` task group execution; tools restricted to implementation tools only (no Agent)

### Removed

- `docs/plans/` directory — all plans were completed historical artifacts; implemented state is recorded in CHANGELOG
- `docs/skills/` directory — skill reference docs removed; skills are self-documenting via their SKILL.md files
- `docs/guides/walkthrough.md` — content merged into `docs/guides/workflows.md`

### Changed

- `agents/task-builder.md`: added test-running step (Step 4) between implementation and acceptance criteria check — language-specific commands for Node.js, Go, Python, .NET; blocks completion on failing tests
- `/build` Step 3: removed "Invoke the `drift-check` skill" (agents cannot invoke skills by name); replaced with embedded drift verification prompt defining EXISTS/MISSING/PARTIAL/CONTRADICTED statuses
- `/doc-audit`: removed Steps 2-3 (README accuracy and API doc accuracy checks — heuristic, unreliable); retained only CHANGELOG checks; updated report format and description accordingly
- `/plan` Step 2: `pack_codebase` changed from `compress: false, topFilesLength: 20` to `compress: true, topFilesLength: 30` — prevents context overflow on large codebases; more top files for better planning coverage
- `/qa` skill invocation language: replaced "Invoke the X skill" phrasing in all 5 parallel agent prompts and 5 sequential mode steps with "Follow the X skill process:" and richer self-contained task descriptions — agents cannot resolve skill names by invocation
- `/review` Step 5: added Hard Rule 6 — when updating the design doc, present each proposed change as old → new text and wait for explicit user confirmation before applying; no wholesale section rewrites
- `/security-review` A06 (Vulnerable Dependencies): changed from "flag for manual review" to tooling-first approach — runs `npm audit` / `govulncheck` / `pip-audit` / `dotnet list package --vulnerable` before falling back to informational note
- `/backend-audit` Step 1: language detection replaced with four-stage fallback (read `.pipeline/brief.md` → check root-level config files → LSP hint → announce "language unknown") — consistent with `/cleanup` detection; eliminates fragile per-extension heuristic
- Model warning notes removed from all skills — model routing is now enforced at runtime via named agents; advisory notes in skill bodies were redundant and cluttered prompts (`/brief`, `/design`, `/review`, `/plan`, `/drift-check`, `/quick`, `/init`, `/git-workflow`, `/qa`, `/frontend-audit`, `/plugin-architecture`, `/backend-audit`, `/doc-audit`, `/security-review`)
- Boilerplate endings removed from `/cleanup` and `/frontend-audit` — generic "use /quick to address" closing lines added no value; reports already contain actionable findings
- `/status` cold-start output: removed broken `workflows.md` file link — skill runs in user's project directory where no such file exists; link was always a dead reference
- `/brief` Step 1: `pack_codebase` call changed from `compress: false` to `compress: true` — brief only needs file-tree orientation and top-file names, not full uncompressed content; reduces token cost on large codebases
- `/cleanup` Step 1: added four-stage language detection with fallback — reads `.pipeline/brief.md` first; if absent, checks root-level config files (`package.json`, `go.mod`, `pyproject.toml`, etc.); then LSP tool availability as a hint; announces "language unknown" as a last resort so the skill remains usable standalone
- `/git-workflow` Step 1: replaced single-tier "any file anywhere" detection with two-tier detection — Tier 1 checks root-level language config files (`package.json`, `go.mod`, etc.) and root-level infra config (`*.tf`, `Chart.yaml`, etc.) for a definitive answer before falling back to repo-wide heuristic scan; eliminates false-positive "ambiguous" prompts on monorepos that have an IaC subdirectory alongside application code
- `/quick` Step 5: removed dead "invoke git-workflow" instruction (nested skill invocation doesn't work and git-workflow is not required for routine commits); replaced with a user-facing reminder in the Step 6 report scoped to when git-workflow actually applies (branch creation, first push, PR)
- `/build` Step 4: updated stale "Re-dispatch that task group's Sonnet agent" to "Re-invoke the `task-builder` agent"
- `/review` Agent 1 dispatch: replaced inline Task tool prompt with `strategic-critic` agent invocation
- `/drift-check` Agent 1 dispatch: replaced inline Task tool prompt with `drift-verifier` agent invocation; Codex (Agent 2) call now inlines its prompt directly instead of referencing Agent 1 block
- `/build` parallel and sequential modes: replaced Task tool builder dispatch with `task-builder` agent invocations
- `/status` cold-start output: when no pipeline is active, now shows named workflow paths (Fast Track / Pipeline), always-available skills, and a link to `workflows.md` — replaces bare "No pipeline active in this directory tree" message
- `/status` frontmatter description updated to reflect the new cold-start guidance behavior
- `docs/skills/status.md`: description updated; two example blocks added (cold-start and mid-task)
- `README.md`: Workflows guide added as first entry in the Guides table
- `docs/guides/workflows.md` expanded to include all walkthrough content: `.pipeline/` directory reference, mode flags (`--parallel`/`--sequential`), language support matrix, and end-to-end example
- `README.md` skills table: links to `docs/skills/` removed; skill names now plain text
- `README.md` guides table: Walkthrough entry removed; Workflows description updated to reflect merged content
- `README.md` pipeline diagram: `/git-workflow` comment corrected — no longer claims it is invoked by `/build` or `/quick`
- `docs/guides/troubleshooting.md`: stale `walkthrough.md` reference updated to `workflows.md#resetting-to-a-prior-phase`

### Fixed

- `session_start_check.sh` episodic search query changed from generic `"recent work"` to `"$(basename "$PWD")"` — project-scoped query returns relevant results instead of noise across all projects
- `session_start_check.sh` episodic output filtering replaced negative grep (fragile, breaks on new CLI progress lines) with positive grep matching only result headers and snippet lines — resilient to episodic-memory CLI output format changes; sed extended to handle decimal match percentages
- `/review` Codex unavailability fallback: removed stale "Agent 2 prompt below" reference (prompt lives in the Step 2 Codex block); fallback now dispatches a Task tool agent using the same code-grounded Codex prompt with an independent subagent context; note updated from "both critics are Opus instances" (wrong) to "Agent 2 ran as Sonnet subagent (code-grounded critique)"
- `/drift-check` Codex unavailability fallback: replaced "invoke drift-verifier again" (identical second run adds tokens without independent perspective) with a structural path/symbol verification agent — complement to drift-verifier's semantic claim analysis
- `/init` now generates `.gitignore` with `.pipeline/` entry (or appends to existing); prevents users from accidentally committing pipeline artifacts to version control
- `/design` Step 1: added `pack_codebase` call (`compress: true`, `topFilesLength: 20`) for existing codebases — architect now has the same codebase grounding as the requirements analyst (`/brief`) and planner (`/plan`)
- `approval_policy` → `approval-policy` in `/review` and `/drift-check` Codex MCP calls — incorrect parameter name caused the approval policy to be silently ignored
- Shell injection in `session_start_check.sh` — `$NEW_BLOCK` content (from episodic search results) was interpolated directly into a `python3 -c` string; replaced with tmpfile + heredoc approach
- `session_start_check.sh` episodic memory sync now runs with `timeout 5s` to prevent blocking session start on slow or large histories
- README stale `/grafana` skill reference removed (skill was moved to `claude-sre-custom` in v1.6.0)
- README MCP Setup guide description updated from "Codex, Repomix, and Grafana MCP configuration" to "Codex and Repomix MCP configuration"
- `docs/guides/mcp-setup.md` stale Grafana MCP section removed; opening line updated from "all three servers" to "both servers"
- `docs/skills/git-workflow.md` stale "referenced in /build and /quick" note replaced — neither skill invokes /git-workflow automatically any more; note now accurately describes the manual invocation trigger points
- `docs/skills/init.md` updated — `.gitignore` added to Writes list and Generated files table
- `docs/skills/design.md` Tools used updated — Repomix added (pack_codebase call added in this release)
- `docs/guides/agents-vs-skills.md` skill count updated from 16 to 18; `/pack` and `/plugin-architecture` rows added to the evaluation table

## [1.6.0] - 2026-03-02

### Removed

- `/grafana` skill and `mcp-grafana` MCP server — moved to `claude-sre-custom` plugin

### Added

- SessionStart hook now syncs episodic memory and injects a "Recent Activity" block into `MEMORY.md` at the start of every session
- `/brief` Step 0: searches past conversations for the stated feature/topic and displays results before Q&A
- `/init` Step 0: searches past conversations for the project name and displays results before scaffolding

## [1.5.0] - 2026-03-01

### Added

- Model reference blocks (`> **Model:** ...`) added to all 19 skills — Opus for complex reasoning (`/review`), Sonnet for medium complexity (`/qa`, `/quick`, `/init`, `/backend-audit`, `/frontend-audit`, `/doc-audit`, `/security-review`, `/git-workflow`, `/grafana`, `/plugin-architecture`), Haiku for mechanical tasks (`/status`, `/pack`, `/cleanup`)
- `## Role` sections added to `/qa` and `/plugin-architecture` (previously missing)

### Changed

- `docs/skills/` model fields updated from `"inherits from calling context"` to explicit model IDs for all 19 skills

## [1.4.0] - 2026-03-01

### Added

- `/grafana` skill — Grafana SRE toolbox with ReAct loop for dashboards, Prometheus/Loki queries, alerting, Sift, log search, and panel rendering
- `mcp-grafana` bundled MCP server — registration automatic on plugin install; requires `uv`/`uvx` and `GRAFANA_URL`/`GRAFANA_SERVICE_ACCOUNT_TOKEN`
- `/status` now shows file age for all 5 pipeline artifacts and a `repomix-pack` row with token stats and staleness indicator (⚠ when ≥ 1 hour old)
- `plugin.json` declares `codex` and `repomix` as bundled MCP servers — registration is automatic on plugin install
- `docs/guides/` — mcp-setup, installation, walkthrough, troubleshooting
- `docs/skills/` — reference pages for all 19 skills

### Fixed

- `pipeline_gate.sh` and `context-monitor.sh` portability: jq-first JSON parsing with python3 fallback and explicit stderr warning when neither is available
- README Codex and Repomix MCP setup sections simplified — manual `claude mcp add` step removed

### Changed

- README slimmed from ~640 lines to ~100 lines — all detail moved to `docs/guides/` and `docs/skills/`

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
