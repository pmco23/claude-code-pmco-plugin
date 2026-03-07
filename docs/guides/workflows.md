# Workflows

Two workflow paths are available. Everything else in the plugin supports one of these two paths.

## Which path?

| Situation | Path |
|-----------|------|
| Small feature, bug fix, typo, config tweak — you know exactly what to change | **Fast Track** (`/quick`) |
| New feature, design-sensitive change, anything that warrants a design doc | **Pipeline** (`/brief → /qa`) |
| Not sure | Start with **Pipeline** — you can abandon it after `/brief` if it turns out to be simple |

## Invocation Behavior

Several stateful workflows are explicit slash-command entrypoints and do not
auto-load from natural-language prompts. Run these directly when you want them:

`/brief`, `/design`, `/review`, `/plan`, `/build`, `/qa`, `/init`,
`/git-workflow`, `/reset`, `/rollback`, `/status`

These skills set `disable-model-invocation: true` to avoid accidental phase
transitions or destructive operations.

Interactive skills prefer structured prompts when the runtime supports them. If
your runtime does not expose picker-style prompts, the same workflow continues
with a plain-text question instead.

---

## Fast Track

```text
/quick [task description]     Sonnet implements directly — no artifacts
/quick --deep [task]          Escalate to Opus for trickier problems
/quick                        Prompts you for task description
```

**What it does:**
1. Parses your task, clarifies if ambiguous (one question max)
2. Reads only the relevant files — not the whole codebase
3. Implements the change following existing patterns
4. Self-reviews the diff before handing back
5. Offers a structured yes/no prompt to run a lightweight audit when supported by the runtime, otherwise falls back to a plain-text yes/no question: LSP diagnostics, security spot-check, test reminder

**What it does NOT do:**
- Write `.pipeline/` artifacts — ever
- Invoke the full QA pipeline
- Refactor surrounding code unless asked

**When NOT to use Fast Track:**
- The change requires a design decision with non-obvious trade-offs
- Multiple systems are affected
- The change is large enough that a plan would prevent rework

---

## Pipeline

A quality-gated sequence. Each phase writes an artifact. The gate hook blocks forward progress until the required artifact exists.

```text
/brief    →  .pipeline/brief.md         requirements crystallization (Opus)
/design   →  .pipeline/design.md        first-principles design (Opus + Context7)
/review   →  .pipeline/design.approved  adversarial review (strategic-critic + code-critic in parallel)
/plan     →  .pipeline/plan.md          atomic execution plan (Opus)
/build    →  .pipeline/build.complete   coordinated build (Opus lead + Sonnet builders)
/qa                                     post-build audits (parallel or sequential)
```

### The .pipeline/ directory

Each pipeline phase writes a state artifact to `.pipeline/` in your project root. This is how the hook knows where you are in the pipeline.

```
.pipeline/
├── brief.md          # written by /brief
├── design.md         # written by /design
├── design.approved   # written by /review when review loop resolves
├── plan.md           # written by /plan
├── build.complete    # written by /build after /drift-check passes
└── repomix-pack.json # written by /pack; /qa invokes /pack when missing or stale
```

**The `.pipeline/` directory is not committed to git by default.** Add it to `.gitignore`:

```
.pipeline/
```

Or commit it if you want a paper trail of your pipeline state.

### What each phase produces

| Phase | Output | Purpose |
|-------|--------|---------|
| `/brief` | `brief.md` | Requirements, constraints, non-goals, success criteria — the contract |
| `/design` | `design.md` | Architecture, component breakdown, library decisions, testing strategy |
| `/review` | `design.approved` | Adversarial findings addressed; design hardened before any code |
| `/plan` | `plan.md` | Exact file paths, code patterns, test cases, acceptance criteria per task group |
| `/build` | `build.complete` | Implementation complete and drift-verified against the plan; task groups tracked in the task list — survives context compaction |
| `/qa` | (none) | Dead code, frontend/backend/doc/security audits — run after `/build` completes; use `--parallel` for speed or `--sequential` for interactive mode |

### Resetting to a prior phase

```bash
# Start over completely
rm -rf .pipeline/

# Redo from /design (keep brief)
rm .pipeline/design.md .pipeline/design.approved .pipeline/plan.md .pipeline/build.complete

# Redo from /review (keep design)
rm .pipeline/design.approved .pipeline/plan.md .pipeline/build.complete

# Redo from /plan (keep approved design)
rm .pipeline/plan.md .pipeline/build.complete

# Redo from /build (keep plan)
rm .pipeline/build.complete
```

### Between-Phase Context Management

> **Tip:** After each pipeline phase completes, run `/compact` before starting the next.
> The PreCompact hook saves all `.pipeline/` state, so nothing is lost — `/compact` only trims
> the conversation context, not your artifacts.
>
> For large codebases or long sessions, starting a **fresh Claude Code session** per phase is
> equally valid. Because `.pipeline/` artifacts persist on disk, the gate hook reads them on the
> next session start and the pipeline picks up exactly where you left off.

---

## Mode Flags

`/build` and `/qa` both accept `--parallel` or `--sequential`. If neither flag is provided, the skill prefers a structured selection prompt when supported by the runtime; otherwise it falls back to a plain-text mode question.

### When to use --parallel

Use `--parallel` when:
- Task groups in the plan have no file conflicts between them
- The plan explicitly flags groups as "safe for parallel"
- You want fastest wall-clock time and don't need to debug mid-build

Use `/qa --parallel` when:
- You want all audits in one shot
- The audits are independent (they always are — different concerns)

### When to use --sequential

Use `--sequential` when:
- Task groups have dependencies (one must complete before another can start)
- You want to review and potentially intervene between tasks
- Debugging a previous build that failed mid-way

Use `/qa --sequential` when:
- You want to review each audit's output before running the next
- One audit's output informs what to fix before running the next

---

## TDD

TDD enforcement is built into the pipeline. When you run `/plan`, every task group is structured test-first by default:

- **Task N.1** — named test cases with assertions (must fail before N.2 begins)
- **Task N.2** — minimal production code to make the tests pass
- **Task N.3** — verify all tests green, then refactor

When `/build` dispatches `task-builder`, the agent enforces the **Iron Law**: no production code for a behaviour until a failing test for that behaviour has been written and run. Each named test case goes through the full Red-Green-Refactor cycle before the next one starts.

### Opting out per project

Some projects legitimately cannot follow TDD — a legacy codebase with no test harness, a config-only repository, or a throwaway spike. Add one line to the project's `CLAUDE.md`:

```
tdd: disabled
```

**What changes:**

| | TDD enabled (default) | TDD disabled |
|---|---|---|
| `/plan` task ordering | N.1 = write tests, N.2 = implement, N.3 = verify+refactor | N.1 = implement, N.2 = write tests, N.3 = verify |
| Plan header | `**TDD:** enabled` | `**TDD:** disabled` |
| `task-builder` Step 3 | Red-Green-Refactor cycle per test case | Implement directly, then write tests |
| Iron Law | Enforced — blocker if test runner unavailable | Suspended |
| Tests required | Yes — all named test cases must pass | Yes — all named test cases must pass |

Tests are always required to pass at the end of a task group, regardless of TDD mode. Disabling TDD changes *when* tests are written (after implementation instead of before), not *whether* they are written.

**Best practice:** document the reason alongside the flag in `CLAUDE.md`:

```
tdd: disabled
# Reason: no test harness yet; tracked in issue #42
```

Remove the line to re-enable TDD enforcement for that project. The setting is per-project — other projects are unaffected.

---

## Always-Available Skills

These run independently of any pipeline state — no gate, no artifacts required.

| Skill | When to use |
|-------|-------------|
| `/status` | Any time — shows pipeline state and next step; with no active pipeline, shows available workflow choices |
| `/init` | New project or missing boilerplate — generates CLAUDE.md (with git conventions), README, CHANGELOG, CONTRIBUTING, .gitignore |
| `/git-workflow` | Before any destructive git operation (force-push, reset --hard, branch -D, or rebasing published commits) — routine commits and branches are governed by CLAUDE.md |
| `/pack` | Before `/qa` or `/quick --deep` to snapshot the codebase |
| `/drift-check` | After `/build` — verify implementation matches the approved design; also run standalone at any time (standalone prefers a structured source/target prompt and falls back to plain text if needed) |
| `/quick` | Fast-track implementation (see above) |
| `/test` | Any time — run the project test suite; supports file/pattern scoping; auto-detects jest, vitest, go test, pytest, dotnet test, cargo test; also invoked by `/cleanup` after dead-code removal |
| `/rollback` | After a completed build — validate plan-derived paths, back up selected files, delete created files, restore modified files safely, reset `build.complete`; requires `build.complete` |

### Git Commands

| Command | When to use |
|---------|-------------|
| `/commit` | After making changes — stages files and creates a conventional commit |
| `/push` | After committing — pushes current branch to remote |
| `/commit-push-pr` | When ready for review — commit + push + open PR in one shot |
| `/sync` | Before starting work or when behind upstream — fetch + rebase |
| `/clean-branches` | Maintenance — remove stale local branches after PRs are merged |
| `/release patch\|minor\|major` | After `/qa` passes — full end-to-end release (version bump, changelog, commit, tag, push, GitHub release) |

---

## How Agents Work

Five named agents exist in the `agents/` directory: `strategic-critic`, `drift-verifier`, `task-builder`, `code-critic`, and `path-verifier`. No external MCP tools are required for adversarial review — all critics run as Claude subagents. You never invoke agents directly — skills dispatch them automatically:

- `/review` dispatches `strategic-critic` (Opus) and `code-critic` (Sonnet) in parallel
- `/drift-check` dispatches `drift-verifier` (Sonnet) and `path-verifier` (Sonnet) in parallel
- `/build` dispatches `task-builder` (Sonnet) per task group, then `drift-verifier` (Sonnet) post-build

The agents enforce model routing (`model: opus` / `model: sonnet`) at the runtime level rather than by prompt instruction alone. This is an implementation detail — for workflow purposes, just run the skill.

---

## Language Support

Diagnostics use a three-tier fallback in `/cleanup`, `/frontend-audit`, and `/backend-audit`:

1. **VS Code IDE integration** (`mcp__ide__getDiagnostics`) — real-time diagnostics for all open files; authoritative when available
2. **LSP tool plugin** — language-specific symbol analysis; authoritative for its language
3. **Heuristic grep** — static pattern matching; always available, least precise

The table below shows what each tier adds per skill:

| Tier | /cleanup | /frontend-audit | /backend-audit | /review | /build | /security-review |
|------|---------|-----------------|----------------|---------|--------|-----------------|
| VS Code IDE | Authoritative errors/warnings | Authoritative errors/warnings | Authoritative errors/warnings | — | — | — |
| TypeScript LSP | Definitive unused symbols | Type-aware audit | Type errors | Type-grounded critique | Accurate refactoring | Taint analysis |
| Go LSP | Definitive unused symbols | — | Unused imports, diagnostics | Code-grounded critique | Accurate refactoring | Taint analysis |
| Python LSP | Definitive unused imports | — | Type annotation gaps | Code-grounded critique | Accurate refactoring | Taint analysis |
| C# LSP | Definitive unused usings | — | Nullable warnings, naming | Code-grounded critique | Accurate refactoring | Taint analysis |
| Heuristic | Grep-pattern dead code | Pattern-based violations | Pattern-based violations | — | — | Pattern-based |

Each absent tier reduces precision, not availability.

---

## End-to-End Example

Starting a new API endpoint feature:

```bash
# 1. Start a Claude Code session in your project directory
cd ~/my-project
claude

# 2. Crystallize your idea
/brief
# Opus asks: What does this endpoint do? → answer
# Opus asks: What's the input/output shape? → answer
# ... Q&A continues ...
# Brief written to .pipeline/brief.md

# 3. Design it
/design
# Opus reads brief, calls Context7 for your framework's docs
# Opus classifies constraints, reconstructs optimal approach
# Iterates until you say "looks good"
# Design written to .pipeline/design.md

# 4. Stress-test the design
/review
# strategic-critic (Opus) and code-critic (Sonnet) in parallel
# Lead deduplicates, runs cost/benefit on each finding
# You review the report, iterate until resolved
# .pipeline/design.approved written

# 5. Plan the build
/plan
# Opus writes an execution doc with exact file paths and test cases
# Plan written to .pipeline/plan.md

# 6. Build it
/build --parallel
# Sonnets build in parallel, Opus coordinates
# drift-verifier agent runs post-build
# .pipeline/build.complete written

# 7. Clean and audit
/qa --parallel
# All QA skills run simultaneously
# Review findings, fix what's flagged

# 8. Verify tests pass (optional but recommended before release)
/test
# Auto-detects runner; reports pass/fail counts
# Offers to invoke /quick on failures

# 9. Cut the release
/release minor
# Version bump, changelog, commit, tag, push, GitHub release — all in one shot
```
