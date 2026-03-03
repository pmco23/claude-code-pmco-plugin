# Workflows

Two workflow paths are available. Everything else in the plugin supports one of these two paths.

## Which path?

| Situation | Path |
|-----------|------|
| Small feature, bug fix, typo, config tweak — you know exactly what to change | **Fast Track** (`/quick`) |
| New feature, design-sensitive change, anything that warrants a design doc | **Pipeline** (`/brief → /qa`) |
| Not sure | Start with **Pipeline** — you can abandon it after `/brief` if it turns out to be simple |

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
5. Offers a structured yes/no prompt to run a lightweight audit: LSP diagnostics, security spot-check, test reminder

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

---

## Mode Flags

`/build` and `/qa` both accept `--parallel` or `--sequential`. If neither flag is provided, a structured selection prompt appears — no typing required, just pick from the options.

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

## Always-Available Skills

These run independently of any pipeline state — no gate, no artifacts required.

| Skill | When to use |
|-------|-------------|
| `/status` | Any time — shows pipeline state and next step; with no active pipeline, shows available workflow choices |
| `/init` | New project or missing boilerplate — generates README, CHANGELOG, CONTRIBUTING, .gitignore |
| `/git-workflow` | Before branch creation, first push, PR open/merge, or destructive git op (force-push, reset --hard) |
| `/pack` | Before `/qa` or `/quick --deep` to snapshot the codebase |
| `/plugin-architecture` | When deciding whether to use a skill vs agent in a plugin you're building |
| `/drift-check` | After `/build` — verify implementation matches the approved design; also run standalone at any time (standalone shows a structured source/target selection prompt) |
| `/quick` | Fast-track implementation (see above) |
| `/test` | Any time — run the project test suite; supports file/pattern scoping; auto-detects jest, vitest, go test, pytest, dotnet test, cargo test; also invoked by `/cleanup` after dead-code removal |
| `/release` | After `/qa` passes — bump version in config files, rename `[Unreleased]` in CHANGELOG, create commit and tag locally; never pushes |
| `/rollback` | After a completed build — delete created files, restore modified files, reset `build.complete`; requires `build.complete` |

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
/release
# Choose patch / minor / major
# Shows full preview (version bump, CHANGELOG diff, commit, tag)
# Confirm → applies locally; then: git push && git push --tags
```
