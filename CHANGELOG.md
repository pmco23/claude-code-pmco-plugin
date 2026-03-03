# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.0.1] - 2026-03-03

### Fixed

- `hooks/hooks.json`: wrapped all event handlers under a top-level `hooks` key to match the updated plugin loader schema (`"expected": "record", "path": ["hooks"]`)

## [2.0.0] - 2026-03-03

### Added

- Per-project TDD opt-out: add `tdd: disabled` to the project's `CLAUDE.md` to disable
  TDD enforcement pipeline-wide; `/plan` switches to implementation-first task ordering and
  writes `**TDD:** disabled` in the plan header; `task-builder` skips the Iron Law and
  Red-Green-Refactor cycle; documented in `skills/tdd/SKILL.md` Valid Exceptions
- `skills/tdd/SKILL.md` — standalone TDD skill: Iron Law ("write the test, watch it fail, write minimal code to pass"), Red-Green-Refactor cycle with numbered steps, when TDD applies (new features, bug fixes, refactoring, behaviour changes), valid exceptions (throwaway prototypes, generated code, config files, pure UI layout); references `testing-anti-patterns.md`
- `skills/tdd/references/testing-anti-patterns.md` — five TDD anti-patterns ported from obra/superpowers: testing mock behaviour instead of real behaviour, test-only methods polluting production code, mocking without understanding the dependency chain, incomplete mocks with missing fields, integration tests added after implementation

### Changed

- `agents/task-builder.md`: added "Apply the TDD skill process for all implementation work" directive at top of agent body; added IRON LAW as first Hard Constraint ("do not write production code for a behaviour until you have written a failing test for that behaviour and run it and seen it fail; if the test runner is unavailable, document as a blocker"); Step 3 restructured to enforce Red-Green-Refactor with explicit Bash test runs — 3a RED (write test), 3b RUN (confirm FAIL), 3c GREEN (write minimal code), 3d RUN (confirm PASS), 3e REFACTOR (improve structure, tests stay green), 3f (repeat per named test case)
- `skills/plan/SKILL.md`: added Hard Rule 6 ("TDD task ordering — every task group lists tests before implementation: Task N.1 = named test cases with assertions, Task N.2 = minimal production code to pass them, Task N.3 = verify green + refactor; never list implementation before tests"); task group template in Step 5 reordered so Task N.1 = write tests (with named test cases table and RED gate note), Task N.2 = implement (minimal code), Task N.3 = verify and refactor; Hard Rule 6 and Step 5 template updated with `tdd: disabled` conditional branches; Step 1 extended to check `CLAUDE.md` for `tdd: disabled`; plan header template gains `**TDD:** [enabled | disabled]` field
- `agents/task-builder.md`: TDD directive conditioned on plan header (`unless **TDD:** disabled`); Step 1 extended to note the `**TDD:**` field; Step 3 split into enabled branch (Red-Green-Refactor cycle) and disabled branch (implement directly, write tests after); Iron Law constraint conditioned with `(unless the plan header declares TDD: disabled)`
- `docs/guides/workflows.md`: added `## TDD` section documenting default test-first task ordering, the Iron Law, the `tdd: disabled` opt-out, a comparison table of what changes vs stays constant between modes, and best-practice guidance for documenting the reason in `CLAUDE.md`
- `docs/guides/installation.md`: added `## Prerequisites` section (Context7 required; repomix, jq recommended with install commands; SessionStart hook warning note); added `## Step 0` for cloning the plugin directory before the marketplace commands
- `README.md`: Quick Install updated to show full sequence (clone → Context7 → repomix → register plugin); `/tdd` added to the Skills table

## [1.9.0] - 2026-03-03

### Added

- `Stop` event hook in `hooks/hooks.json`: prompt-based hook that asks Claude to update `## Current Focus` in MEMORY.md at meaningful session end; fires for all projects, all users
- `## Current Focus` MEMORY.md convention: 2–3 sentence overwrite-each-session section for current in-flight state, next step, pending decision; section is created by Claude on first use
- `docs/guides/hooks.md`: new reference guide — describes all five hooks (SessionStart, PreToolUse, PostToolUse, PreCompact, Stop), when each fires, what it does, and its behaviour at the edges (fail-open, silent exit, thresholds)
- `agents/code-critic.md` — new Sonnet agent for `/review` Agent 2; reads the existing codebase to surface interface incompatibilities, pattern violations, naming conflicts, dependency gaps, and type mismatches; tools restricted to `Read, Grep, Glob`
- `agents/path-verifier.md` — new Sonnet agent for `/drift-check` Agent 2; mechanically verifies that every file path and symbol name mentioned in the source document physically exists (EXISTS/MISSING only, no semantic analysis); tools: `Read, Grep, Glob, Bash`

### Changed

- `/brief` Step 1: removed one-off `mcp__repomix__pack_codebase` call; replaced with native `Glob("**/*", depth ≤ 3)` + primary config-file read — equivalent project-structure grounding with no MCP dependency; outputId was always discarded
- `/design` Step 1: same — removed one-off `mcp__repomix__pack_codebase` call; replaced with `Glob` + primary config-file read
- `/plan` Step 2: removed `mcp__repomix__pack_codebase` call and its fallback clause; the existing fallback (Glob + primary config-file read) is now the sole path — no Repomix dependency for planning
- `/qa` Repomix Preamble: delegated pack acquisition to the `/pack` skill instead of calling `mcp__repomix__pack_codebase` directly and writing `.pipeline/repomix-pack.json` inline; `/pack` is now the single owner of packing logic and the JSON schema
- `/review` description and Hard Rule 1: replaced Codex MCP call with `code-critic` agent invocation — "Agent 2 via Codex MCP" → "Agent 2 via the `code-critic` agent"; Codex fallback removed from Hard Rule 1 entirely
- `/review` Step 2: replaced `mcp__codex__codex` call block with `code-critic` agent invocation
- `/review` Step 3: "Once both agents return (Task tool returns... `mcp__codex__codex` returns...)" → "Once both agents return their results"
- `/drift-check` description: "Dispatches Sonnet and Codex in parallel" → "Dispatches drift-verifier (Sonnet) and path-verifier (Sonnet) in parallel"
- `/drift-check` Step 2: replaced `mcp__codex__codex` call block and inline prompt with `path-verifier` agent invocation; added explanation of the complementary roles (drift-verifier: semantic claims; path-verifier: structural existence)
- `/drift-check` Step 3: "Once both agents return (Task tool... `mcp__codex__codex`...)" → "Once both agents return their results"
- `docs/guides/workflows.md` How Agents Work: "Three named agents" → "Five named agents"; updated dispatch list to include `code-critic` and `path-verifier`; all Codex MCP references removed
- `plugin.json`: removed `codex` from `mcpServers` — Repomix is the only remaining MCP server

### Fixed

- `skills/review/SKILL.md` Role: stale "Codex (code-grounded)" → "code-critic (code-grounded)" — the Role narrative was not updated when the Codex → code-critic migration landed
- `docs/guides/workflows.md` pipeline table: stale "Opus + Codex in parallel" → "strategic-critic + code-critic in parallel" for the `/review` row
- `docs/guides/workflows.md` end-to-end example Step 4: stale "# Opus and Codex critique in parallel" → "# strategic-critic (Opus) and code-critic (Sonnet) in parallel"
- `agents/code-critic.md` and `agents/path-verifier.md`: `model: claude-sonnet-4-6` normalised to `model: sonnet` — aligns with the `sonnet`/`opus` short-alias convention used by the three older agents
- `hooks/session_start_check.sh`: removed stale `codex` check — Codex was removed in v1.8.0 but the startup warning persisted
- `hooks/hooks.json` Stop hook prompt: clarified MEMORY.md creation — previous wording ("add it at the bottom") was ambiguous when the file didn't exist yet; now explicit: create the file if missing, add the section if the file exists but lacks it, overwrite the section if it's present

### Removed

- Codex MCP dependency removed entirely — replaced by Claude Sonnet subagents (`code-critic`, `path-verifier`); eliminates OpenAI API key requirement, npm install step, and PATH resolution issues
- `docs/guides/mcp-setup.md`: Codex MCP setup section removed — only Repomix MCP documentation remains
- `README.md`: Codex CLI removed from Required prerequisites table; MCP Setup guide description updated to reflect Repomix-only scope
- `docs/guides/troubleshooting.md`: "Codex MCP not connecting" troubleshooting section removed

## [1.8.0] - 2026-03-03

### Added

- `docs/guides/workflows.md`: Always-Available Skills table expanded with `/test`, `/release`, `/rollback`; End-to-End Example extended with steps 8 (`/test`) and 9 (`/release`); How Agents Work updated to show `/build` dispatches `drift-verifier` post-build; stale `# /drift-check runs post-build` comment corrected; Mode Flags section notes that omitting flags triggers a structured selection prompt; Language Support table expanded with VS Code IDE and Heuristic rows
- `docs/guides/agents-vs-skills.md`: skill count updated from 18 to 21; `/test`, `/release`, `/rollback` rows added to fitness-criterion evaluation table; Fitness Criterion #2 updated from "Read-only" to "Scoped writes" to match `plugin-architecture` SKILL.md; Pattern 4 example annotation updated accordingly
- `docs/guides/troubleshooting.md`: expected test gate count updated from 49 to 52
- `/test` skill — runs the project test suite; auto-detects jest, vitest, go test, pytest, dotnet test, cargo test; supports file/pattern scoping; offers to invoke `/quick` on failures
- `/release` skill — cuts a new release: bumps version in config files, renames `## [Unreleased]` to `## [X.Y.Z]` in CHANGELOG.md, creates a release commit and git tag locally; shows full preview before writing; never pushes
- `/rollback` skill — undoes a completed build by deleting created files and restoring modified files via `git checkout --`; requires per-group confirmation; removes `.pipeline/build.complete`; never removes planning artifacts
- `agents/strategic-critic.md`: `tools:` field added — restricts to `Read, Grep, Glob, WebSearch` and Context7 tools; prevents unintended write access
- `agents/drift-verifier.md`: `tools:` field added — restricts to `Read, Grep, Glob, Bash`; read-only verification scope enforced
- `/git-workflow` Step 1.5: new step between project-type detection and workflow-reference load — reads current git state, identifies the requested operation (branch creation, push, PR open, PR merge, destructive op), and gathers required parameters before applying safety gates
- `hooks/compact-prep.sh`: new PreCompact hook — outputs current `.pipeline/` stage and artifact list before `/compact` so pipeline state is preserved in the compacted summary; registered in `hooks.json` under `PreCompact`
- `README.md`: VS Code IDE Integration added to Optional prerequisites table as primary diagnostics tier; three-tier fallback description (VS Code IDE → LSP → heuristic grep) replaces single-line LSP footnote
- `AskUserQuestion` structured prompts at all 7 decision points: `/build` mode selection, `/build` partial-build resume, `/qa` mode selection, `/cleanup` confirmation, `/review` action, `/quick` audit offer, `/drift-check` source/target selection — replaces freetext prompts with radio-button UI
- `TaskCreate`/`TaskUpdate`/`TaskList` integration in `/build`: one task per task group created at Step 1, `TaskList` checked before file-based detection in Step 0, tasks marked `in_progress`/`completed` as groups are dispatched and verified in Steps 2A and 2B
- `mcp__ide__getDiagnostics` as the primary diagnostics tier in `/cleanup`, `/frontend-audit`, and `/backend-audit` — tried before LSP tool plugins; quality tier announcement updated to three levels: IDE active → LSP active → heuristic

### Changed

- `/cleanup`: added `## Hard Rules` section (frontmatter → Role → **Hard Rules** → Process); constraints previously buried in Role and Process steps are now declared before the steps that enforce them
- `/cleanup` Step 5: renamed to "Verify no regressions"; delegated runner detection and execution to the `/test` skill process — removes inline runner commands (`npm test`, `go test ./...`, etc.); `/test`'s fallback AskUserQuestion and failure handling are inherited automatically
- `/build`: `## Lead Rules` section moved before `## Process` and renamed `## Hard Rules` — constraints now declared before the steps that enforce them; Hard Rule 2 expanded to name the dispatch tool (`task-builder` agent)
- `/build` H1 title: changed from `# BUILD — Parallel Build` to `# BUILD` — was incorrect for sequential mode users
- `/build` Step 1: TaskCreate is now conditional — calls `TaskList` first and only creates tasks for groups without an existing `Task Group [N]` entry; prevents duplicate task creation on resume
- `/build` Step 2A (parallel mode): added retry/escalation path — after 3 consecutive failures on the same task group, escalate to the user instead of looping; mirrors the existing Step 2B sequential-mode behavior
- `/build` Step 2B: retry limit added — after 3 consecutive failures on the same acceptance criteria, escalates to user instead of looping indefinitely
- `/build` Step 3: inline drift-check prompt replaced with `drift-verifier` agent invocation; eliminates prompt duplication and ensures the step benefits from future agent improvements
- `/build` Step 4: added retry limit to drift remediation loop — after 2 consecutive drift-verifier failures on the same claim, escalate to user; previously the loop had no exit condition other than pass
- `/build` Step 4 and description: replaced `/drift-check` (skill name) with `drift-verifier` (agent name) — three inconsistent names for the same mechanism unified; Step 5 updated to match
- `/review` Step 2: removed duplicated Codex fallback statement — fallback is canonical in Hard Rule 1; Step 2 now references Hard Rule 1 instead of re-stating it with slightly different semantics
- `/review` Hard Rule #1 and Step 2: Note placement instruction (`**Note:** Codex MCP unavailable...`) removed from dispatch step; moved to Step 3 with a conditional insertion instruction after the `**Design:**` line in the report template
- `/review` Hard Rule 5: replaced "no remaining findings warrant mitigation" with "all MUST FIX findings are resolved — SHOULD FIX findings may be accepted via Override" — aligns with the cost/benefit matrix thresholds
- `/review` Step 3: added "Context7 ground" sub-step — lead now calls `resolve_library_id` + `query_docs` for any library cited in a finding before accepting it; satisfies Hard Rule 2's grounding requirement in the Process
- `/review` Step 3 Fact-check: added codebase-relevance check — for findings claiming naming conflicts or pattern inconsistency, lead uses Grep/Glob to verify before accepting; satisfies Hard Rule 4's "relevant to the actual codebase" clause
- `/review` Step 4 Override path: replaced ambiguous "re-evaluate" with explicit routing — re-presents updated report; if all MUST FIX resolved, proceeds to Approve; otherwise awaits further action
- `/review` Step 4 Approve path: updated description to match revised Hard Rule 5 exit condition
- `/doc-audit`: added Step 4 README freshness check — flags stale installation commands, unfilled `[PLACEHOLDER]` markers, and references to removed features; skips silently if no README exists; output section updated to note README findings
- `/frontend-audit` Step 3: accessibility checklist added — checks interactive element labels, image `alt` attributes, heading hierarchy, and focus trap patterns
- `/backend-audit` Step 2: Rust LSP tier added to quality tier announcement — `🟢 Rust LSP active` branch inserted before the heuristic fallback
- `/init` Step 2: file-conflict prompts converted from freetext to `AskUserQuestion` (Skip / Overwrite / Merge)
- `/plugin-architecture` fitness criterion #2: changed from "Read-only" to "Scoped writes" — corrects the incorrect rule that blocked `task-builder` (which writes files within a defined scope); Split Pattern description updated to "Agent: analysis only (or scoped writes)"
- `/quick` Step 6: `AskUserQuestion` block moved outside the report template code fence — was being read as literal text to print instead of as a tool call instruction
- `/security-review` A06: `cargo audit --json` added to the automated scanning block for Rust projects; unavailability message example added for Rust
- `/status`: pipeline report section now ends with `AskUserQuestion` to launch the next pipeline step directly from the status report

### Fixed

- `README.md`: added `/test`, `/release`, `/rollback` to the Skills table — three newly added skills were missing from the table
- `hooks/test_gate.sh`: added `expect_allow` coverage for `/test`, `/release`, `/rollback` — gate regression suite now runs 52 scenarios (up from 49)
- `hooks/context-monitor.sh`: added explicit `exit 0` at end of script — best practice for hook scripts under `set -euo pipefail`
- `skills/git-workflow/references/`: removed stale directory — `code-path.md` and `infra-path.md` were already inlined into `SKILL.md` and unreachable at runtime; eliminates maintenance trap
- `/git-workflow` Step 2 referenced `references/code-path.md` and `references/infra-path.md` relative to CWD — both files are unreachable in user projects; content inlined directly into `SKILL.md` (Code Path trunk-based rules and Infra Path three-environment rules); `## Output` section updated to remove stale file path references
- `hooks/hooks.json` structural issue — events were nested under a `"hooks"` wrapper key instead of at the top level; commands now use `${CLAUDE_PLUGIN_ROOT}` with correct quoting
- `/design` Step 3: Context7 fallback not implemented — Hard Rule #1 stated the fallback but Step 3 had no fallback branch; inserted paragraph directing the model to skip the Context7 call sequence and flag the Library Decisions row as "Docs not verified — Context7 unavailable"
- `/review` Step 2: Codex unavailability fallback was only in Hard Rules, not at the dispatch step — moved fallback instruction block to the top of Step 2 so a reader following the process encounters it before dispatching
- `/review` Step 4 `update design` bullet: confirmation prompt was vague ("wait for user to confirm each change") — replaced with explicit `"Apply this change? (yes / skip)"` prompt and added instruction to return to Step 2 after all confirmed changes are applied
- `/qa` PASS criteria defined only at end of each mode section — inserted `## PASS Criteria` section before `## Mode Selection` so the success bar is visible before mode is chosen
- `/qa` Repomix Preamble schema reference was an indirect cross-reference ("same fields as the `/pack` skill") with no inline definition — replaced parenthetical with a 6-field inline bullet list (`outputId`, `source`, `packedAt`, `fileCount`, `tokensBefore`, `tokensAfter`)
- `/qa` sequential-mode "fix first" prompts were ambiguous — appended `— then re-run /qa to verify before continuing` to all 4 sequential-mode continuation prompts
- `/plan` Step 6 cross-file conflict check was aspirational with no procedure — replaced single-sentence body with a 5-step numbered procedure (collect file paths → build conflict map → check parallel-safe status → resolve with sequential or split → re-verify map); named `## Conflict Resolution` as a required output section in `.pipeline/plan.md`

### Removed

- `episodic-memory` plugin dependency removed entirely — session context is now handled by native Claude Code MEMORY.md (auto-loaded each session); no external plugin required
- `hooks/session_start_check.sh`: episodic-memory binary check, `sync` call, project-scoped search, and MEMORY.md sentinel-block injection removed
- `docs/guides/mcp-setup.md`: Episodic Memory Plugin section removed
- `README.md`: Episodic Memory row removed from Optional prerequisites table

## [1.7.1] - 2026-03-02

### Fixed

- `episodic-memory` plugin requirement was undocumented — added to README Optional prerequisites table, added setup section to `docs/guides/mcp-setup.md`, and added graceful fallback note to `/brief` Step 0 and `/init` Step 0

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
